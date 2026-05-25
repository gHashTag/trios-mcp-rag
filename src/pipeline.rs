//! SSOT -> Markdown -> pandoc (LaTeX) -> tectonic -> PDF pipeline.
//!
//! Canonical Trios PhD build path. Reads chapters from a PostgreSQL SSOT
//! (`ssot_brochure.chapters` or `ssot.chapters`) using a connection string
//! taken from the environment, renders an ordered Markdown bundle, then
//! shells out to `pandoc` and `tectonic` to produce a PDF.
//!
//! Hard constraints:
//!   - No writes to the database.
//!   - No secrets are read from disk or printed; connection strings come
//!     from environment variables chosen by name only.
//!   - No Python / ReportLab substitute is permitted; pandoc + tectonic is
//!     the only supported renderer (per R1/CROWN).

use anyhow::{anyhow, Context, Result};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::process::Command;

/// One ordered chapter from the SSOT.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Chapter {
    pub slug: String,
    pub kind: String,
    pub order_key: i32,
    pub title: String,
    pub body_md: String,
    pub illustration_url: Option<String>,
    /// Secondary (orphan) images recovered from ssot_brochure.assets whose
    /// brochure-img index falls between this chapter's hero and the next.
    /// These are tracked for future anchored rendering, but are not emitted
    /// automatically because orphan image appendices create image-train pages.
    #[serde(default)]
    pub secondary_images: Vec<String>,
}

/// Configuration for one build.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildConfig {
    /// Name of the environment variable holding the Postgres DSN.
    /// Defaults to `DATABASE_URL`; `RAILWAY_SSOT_URL` is also recognised.
    pub database_url_env: String,
    /// SSOT schema-qualified chapters table. Defaults to
    /// `ssot_brochure.chapters` (this repo's convention); `ssot.chapters`
    /// is the broader trios convention and is also accepted.
    pub chapters_table: String,
    /// Output directory for the final PDF.
    pub out_dir: PathBuf,
    /// Working directory for intermediate artefacts (markdown, tex).
    pub build_dir: PathBuf,
    /// Optional pandoc LaTeX template path.
    pub template: Option<PathBuf>,
    /// Optional pandoc Lua filter path (e.g. `force-fullwidth-hero.lua`).
    pub lua_filter: Option<PathBuf>,
    /// Repo root used to resolve relative template / filter paths and to
    /// locate `docs/phd/` if a caller wants the canonical layout.
    pub repo_root: PathBuf,
    /// Dry-run / check mode: validate env, dependencies, paths, and table
    /// access. Do not produce the final PDF.
    pub dry_run: bool,
    /// Optional cap on chapter count, for test builds.
    pub limit: Option<usize>,
    /// Output PDF filename (under `out_dir`). Defaults to `main.pdf`.
    pub pdf_name: String,
    /// Book mode: add TOC, part dividers, and chapter-level LaTeX structure.
    pub book_mode: bool,
}

impl Default for BuildConfig {
    fn default() -> Self {
        let repo_root = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
        Self {
            database_url_env: "DATABASE_URL".into(),
            chapters_table: "ssot_brochure.chapters".into(),
            out_dir: repo_root.join("generated").join("out"),
            build_dir: repo_root.join("generated").join("build"),
            template: None,
            lua_filter: None,
            repo_root,
            dry_run: false,
            limit: None,
            pdf_name: "main.pdf".into(),
            book_mode: true,
        }
    }
}

/// Outcome of `check()` or a successful build.
#[derive(Debug, Serialize)]
pub struct BuildReport {
    pub dry_run: bool,
    pub database_url_env: String,
    pub database_url_present: bool,
    pub chapters_table: String,
    pub chapter_count: Option<usize>,
    pub pandoc_available: bool,
    pub tectonic_available: bool,
    pub template_ok: Option<bool>,
    pub lua_filter_ok: Option<bool>,
    pub markdown_path: Option<PathBuf>,
    pub tex_path: Option<PathBuf>,
    pub pdf_path: Option<PathBuf>,
    pub notes: Vec<String>,
    pub book_mode: bool,
}

/// Resolve the DSN strictly from the environment.
///
/// Tries the configured env var name first, then falls back to
/// `RAILWAY_SSOT_URL`. The string itself is never logged or returned —
/// callers only learn whether it is present.
pub fn resolve_dsn(cfg: &BuildConfig) -> Result<String> {
    if let Ok(v) = std::env::var(&cfg.database_url_env) {
        if !v.is_empty() {
            return Ok(v);
        }
    }
    if let Ok(v) = std::env::var("RAILWAY_SSOT_URL") {
        if !v.is_empty() {
            return Ok(v);
        }
    }
    Err(anyhow!(
        "no DSN in environment: set ${} (or $RAILWAY_SSOT_URL)",
        cfg.database_url_env
    ))
}

/// Validate that a schema-qualified identifier looks safe enough to splice
/// into a SQL statement. The SSOT table is a config value, not user input,
/// but we still refuse anything that isn't a plain dotted identifier.
pub fn validate_table_ident(t: &str) -> Result<()> {
    if t.is_empty() {
        return Err(anyhow!("chapters_table is empty"));
    }
    for part in t.split('.') {
        if part.is_empty() {
            return Err(anyhow!("chapters_table has empty segment: {}", t));
        }
        if !part.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') {
            return Err(anyhow!(
                "chapters_table segment {:?} is not a plain identifier",
                part
            ));
        }
    }
    Ok(())
}

/// Remove a leading `# Title` line from a chapter body so that when the
/// chapter is merged as a subsection the duplicate heading does not create
/// an unwanted H1 inside the host chapter.
fn strip_leading_h1(body: &str) -> String {
    let trimmed = body.trim_start();
    if trimmed.starts_with("# ") {
        if let Some(idx) = trimmed.find('\n') {
            trimmed[idx + 1..].trim_start().to_string()
        } else {
            String::new()
        }
    } else {
        trimmed.to_string()
    }
}

/// Merge consecutive short chapters (< 30 lines of body) into their
/// neighbours.  The `book` class inserts a `\clearpage` before every
/// `\chapter`, so each stub that is only a title + a paragraph wastes nearly
/// a full page.  By prepending short stubs to the next chapter (or appending
/// to the previous when there is no next) we turn them into `##` sections
/// inside a larger chapter, eliminating the forced page break.
///
/// A merged-in chapter’s hero image is downgraded to `{.secondary}` so it
/// does not create a chapter-opener hero on its own page.
fn merge_short_chapters(ordered: Vec<&Chapter>) -> Vec<Chapter> {
    let mut merged: Vec<Chapter> = Vec::new();
    let mut i = 0;
    while i < ordered.len() {
        let current = ordered[i].clone();
        let lines = current.body_md.lines().count();
        let is_appendix_like = current.kind.starts_with("appx")
            || current.kind == "hardware_addendum"
            || current.kind == "paper3";
        // Short appendix-like chapter with a successor → prepend into the next chapter.
        if is_appendix_like && lines < 30 && i + 1 < ordered.len() {
            let mut next = ordered[i + 1].clone();
            let subsection = format!(
                "\n\n## {}\n\n{}",
                current.title,
                strip_leading_h1(&current.body_md)
            );
            next.body_md = format!("{}\n{}", next.body_md.trim_end(), subsection);
            if let Some(img) = &current.illustration_url {
                next.body_md.push_str(&format!(
                    "\n\n![{}](img/{}){{.secondary}}\n\n",
                    current.title, img
                ));
            }
            next.secondary_images.extend(current.secondary_images.clone());
            merged.push(next);
            i += 2;
            continue;
        }
        // Short appendix-like chapter at the end (or after a merge gap) → append to previous.
        if is_appendix_like && lines < 30 && !merged.is_empty() {
            let prev = merged.last_mut().unwrap();
            let subsection = format!(
                "\n\n## {}\n\n{}",
                current.title,
                strip_leading_h1(&current.body_md)
            );
            prev.body_md.push_str(&subsection);
            if let Some(img) = &current.illustration_url {
                prev.body_md.push_str(&format!(
                    "\n\n![{}](img/{}){{.secondary}}\n\n",
                    current.title, img
                ));
            }
            prev.secondary_images.extend(current.secondary_images.clone());
            i += 1;
            continue;
        }
        merged.push(current);
        i += 1;
    }
    merged
}

/// Render an ordered chapter list into a single Markdown document.
///
/// Chapters are emitted in `order_key` ascending order. Each chapter is
/// preceded by an HTML comment marker carrying its slug, then an `H1`
/// with the title, then its `body_md` verbatim. The marker lets the Lua
/// filter target individual chapters later.
pub fn render_markdown(chapters: &[Chapter]) -> String {
    let mut ordered: Vec<&Chapter> = chapters.iter().collect();
    // Logical book order: frontmatter → paper1 → paper2 → paper3 →
    // hardware_addendum → all appendices. Within each block, preserve
    // the SSOT order_key and then slug.
    let kind_rank = |k: &str| -> u8 {
        match k {
            "frontmatter" => 0,
            "paper1" => 1,
            "paper2" => 2,
            "paper3" => 3,
            "hardware_addendum" => 4,
            k if k.starts_with("appx") => 5,
            _ => 6,
        }
    };
    ordered.sort_by(|a, b| {
        kind_rank(&a.kind).cmp(&kind_rank(&b.kind))
            .then_with(|| a.order_key.cmp(&b.order_key))
            .then_with(|| a.slug.cmp(&b.slug))
    });
    let merged = merge_short_chapters(ordered);
    let mut out = String::new();
    for (i, ch) in merged.iter().enumerate() {
        if i > 0 {
            out.push_str("\n\n");
        }
        out.push_str(&format!("<!-- chapter: {} -->\n", ch.slug));
        let body = ch.body_md.trim_start();
        if body.starts_with("# ") {
            // Split after the first H1, insert hero between heading and body
            let mut parts = body.splitn(2, '\n');
            let h1 = parts.next().unwrap_or("");
            let rest = parts.next().unwrap_or("").trim_start();
            out.push_str(h1);
            out.push_str("\n\n");
            if let Some(img) = &ch.illustration_url {
                out.push_str(&format!("![{}](img/{}){{.hero}}\n\n", ch.title, img));
            }
            if !rest.is_empty() {
                out.push_str(rest);
            }
        } else {
            out.push_str(&format!("# {}\n\n", ch.title));
            if let Some(img) = &ch.illustration_url {
                out.push_str(&format!("![{}](img/{}){{.hero}}\n\n", ch.title, img));
            }
            out.push_str(ch.body_md.trim_end());
        }
        // Do not auto-append `secondary_images` here. The RAG image-placement
        // contract requires every image to be anchored to a substantive
        // heading/body block; appending orphan assets at chapter end creates
        // low-context image pages and violates TRIOS_PHD_NO_IMAGE_TRAIN.
        out.push('\n');
    }
    let out = inline_short_references(&out);
    normalize_markdown_tables(&out)
}

/// Collapse short `## References` / `### References` subsections (with one
/// to three bullets) into a single inline paragraph at the end of the body.
/// LaTeX would otherwise float the orphan bullets onto a near-empty page;
/// inlining them removes the ghost page without losing the citations.
fn inline_short_references(md: &str) -> String {
    let lines: Vec<&str> = md.lines().collect();
    let mut out: Vec<String> = Vec::with_capacity(lines.len());
    let mut i = 0;
    while i < lines.len() {
        let l = lines[i];
        let is_ref_header = l.trim_start_matches('#').trim_start().to_lowercase().contains("references")
            && (l.starts_with("## ") || l.starts_with("### "));
        if !is_ref_header {
            out.push(l.to_string());
            i += 1;
            continue;
        }
        // Look-ahead: collect bullet items until next heading / chapter / EOF
        let mut j = i + 1;
        // skip blanks
        while j < lines.len() && lines[j].trim().is_empty() {
            j += 1;
        }
        let mut bullets: Vec<String> = Vec::new();
        while j < lines.len() {
            let t = lines[j];
            let tt = t.trim_start();
            if tt.starts_with("- ") || tt.starts_with("* ") {
                bullets.push(tt[2..].trim().to_string());
                j += 1;
            } else if t.trim().is_empty() {
                j += 1;
            } else {
                break;
            }
        }
        if bullets.len() >= 1 && bullets.len() <= 3 {
            // Inline. Skip the original block (header + bullets).
            out.push(String::new()); // separator paragraph break
            out.push(format!("**References:** {}", bullets.join("; ")));
            i = j;
        } else {
            // Keep the section as-is.
            out.push(l.to_string());
            i += 1;
        }
    }
    out.join("\n")
}

fn normalize_markdown_tables(md: &str) -> String {
    let lines: Vec<&str> = md.lines().collect();
    let mut out = Vec::with_capacity(lines.len());
    let mut i = 0;

    while i < lines.len() {
        if is_pipe_row(lines[i]) && i + 1 < lines.len() && is_table_delimiter(lines[i + 1]) {
            let expected_cols = split_pipe_cells(lines[i]).len();
            out.push(lines[i].to_string());
            out.push(lines[i + 1].to_string());
            i += 2;

            while i < lines.len() && is_pipe_row(lines[i]) {
                out.push(normalize_pipe_table_row(lines[i], expected_cols));
                i += 1;
            }
        } else {
            out.push(lines[i].to_string());
            i += 1;
        }
    }

    let mut normalized = out.join("\n");
    if md.ends_with('\n') {
        normalized.push('\n');
    }
    normalized
}

fn is_pipe_row(line: &str) -> bool {
    let trimmed = line.trim_start();
    trimmed.starts_with('|') && trimmed[1..].contains('|')
}

fn is_table_delimiter(line: &str) -> bool {
    if !is_pipe_row(line) {
        return false;
    }
    let cells = split_pipe_cells(line);
    !cells.is_empty()
        && cells.iter().all(|cell| {
            let t = cell.trim();
            t.len() >= 3 && t.chars().all(|c| c == '-' || c == ':')
        })
}

fn split_pipe_cells(line: &str) -> Vec<String> {
    let mut inner = line.trim();
    if inner.starts_with('|') {
        inner = &inner[1..];
    }
    if inner.ends_with('|') && !inner.ends_with("\\|") {
        inner = &inner[..inner.len() - 1];
    }

    let mut cells = Vec::new();
    let mut current = String::new();
    let mut escaped = false;
    for ch in inner.chars() {
        if ch == '|' && !escaped {
            cells.push(current);
            current = String::new();
        } else {
            current.push(ch);
        }
        escaped = ch == '\\' && !escaped;
        if ch != '\\' {
            escaped = false;
        }
    }
    cells.push(current);
    cells
}

fn normalize_pipe_table_row(line: &str, expected_cols: usize) -> String {
    let mut cells = split_pipe_cells(line);
    if expected_cols >= 3 && cells.len() > expected_cols {
        let tail_cols = expected_cols - 2;
        let middle_end = cells.len().saturating_sub(tail_cols);
        let mut repaired = Vec::with_capacity(expected_cols);
        repaired.push(cells[0].clone());
        repaired.push(cells[1..middle_end].join("|"));
        repaired.extend(cells[middle_end..].iter().cloned());
        cells = repaired;
    }

    let normalized: Vec<String> = cells
        .iter()
        .map(|cell| normalize_table_cell(cell))
        .collect();
    format!("| {} |", normalized.join(" | "))
}

fn normalize_table_cell(cell: &str) -> String {
    let trimmed = cell.trim();
    let spaced = if looks_formula_like(trimmed) {
        space_formula_operators(trimmed)
    } else {
        trimmed.to_string()
    };
    spaced.replace('|', "\\|")
}

fn looks_formula_like(text: &str) -> bool {
    if text.contains("://") || text.contains('@') {
        return false;
    }
    let has_math_symbol = text.chars().any(|c| {
        matches!(
            c,
            '\u{03b1}' // alpha
                | '\u{03b3}' // gamma
                | '\u{03b4}' // delta
                | '\u{03b8}' // theta
                | '\u{03bc}' // mu
                | '\u{03c0}' // pi
                | '\u{03c6}' // phi
                | '\u{03c9}' // omega
                | '\u{03a9}' // Omega
                | '\u{221a}' // square root
                | '\u{211d}' // R
                | '\u{2124}' // Z
                | '\u{2070}'..='\u{2079}' // superscript digits
                | '\u{207b}' // superscript minus
                | '\u{2080}'..='\u{2089}' // subscript digits
        )
    });
    let has_operator = text.chars().any(|c| {
        matches!(
            c,
            '=' | '+' | '/' | '<' | '>' | '\u{2212}' | '\u{00b7}' | '\u{00d7}'
                | '\u{2248}' | '\u{2264}' | '\u{2265}'
        )
    });
    has_math_symbol && has_operator
}

fn space_formula_operators(text: &str) -> String {
    let mut out = String::with_capacity(text.len() + 8);
    for ch in text.chars() {
        if matches!(
            ch,
            '=' | '+' | '/' | '<' | '>' | '\u{2212}' | '\u{00b7}' | '\u{00d7}'
                | '\u{2248}' | '\u{2264}' | '\u{2265}'
        ) {
            out.push(' ');
            out.push(ch);
            out.push(' ');
        } else {
            out.push(ch);
        }
    }
    out.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn binary_available(name: &str) -> bool {
    Command::new(name)
        .arg("--version")
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
    // `--version` is supported by both pandoc and tectonic.
}

fn ensure_dir(p: &Path) -> Result<()> {
    std::fs::create_dir_all(p).with_context(|| format!("create_dir_all({})", p.display()))
}

fn hex_decode(s: &str) -> Result<Vec<u8>> {
    let s = s.strip_prefix("\\x").unwrap_or(s);
    let mut bytes = Vec::with_capacity(s.len() / 2);
    for i in (0..s.len()).step_by(2) {
        let byte = u8::from_str_radix(&s[i..i + 2], 16)
            .with_context(|| format!("invalid hex at position {}", i))?;
        bytes.push(byte);
    }
    Ok(bytes)
}

fn is_png_valid(path: &std::path::Path) -> bool {
    use std::io::Read;
    let mut file = match std::fs::File::open(path) {
        Ok(f) => f,
        Err(_) => return false,
    };
    let mut magic = [0u8; 8];
    if file.read_exact(&mut magic).is_err() {
        return false;
    }
    &magic == b"\x89PNG\r\n\x1a\n"
}

/// Resolve an optional path relative to `repo_root` if it isn't absolute.
fn resolve_under_root(repo_root: &Path, p: &Option<PathBuf>) -> Option<PathBuf> {
    p.as_ref().map(|raw| {
        if raw.is_absolute() {
            raw.clone()
        } else {
            repo_root.join(raw)
        }
    })
}

/// Loader function signature: given a config, return the ordered chapter
/// list. Abstracted so tests can supply fixtures without a live DB.
pub type ChapterLoader = dyn Fn(&BuildConfig) -> Result<Vec<Chapter>>;

/// Default chapter loader: connects to Postgres using the env-resolved DSN
/// and reads the configured table.
pub fn load_from_postgres(cfg: &BuildConfig) -> Result<Vec<Chapter>> {
    validate_table_ident(&cfg.chapters_table)?;
    let dsn = resolve_dsn(cfg)?;
    let table = cfg.chapters_table.clone();
    let limit = cfg.limit;
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(1)
        .enable_all()
        .build()?;
    rt.block_on(async move {
        let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls)
            .await
            .context("postgres connect")?;
        tokio::spawn(async move {
            let _ = conn.await;
        });
        let mut sql = format!(
            "SELECT slug, kind, order_key, title, body_md, illustration_url \
             FROM {} ORDER BY order_key",
            table
        );
        if let Some(n) = limit {
            sql.push_str(&format!(" LIMIT {}", n as i64));
        }
        let rows = tokio::time::timeout(
        std::time::Duration::from_secs(30),
        client.query(&sql, &[]),
    )
    .await
    .context("query chapters timed out (30s)")?
    .context("query chapters")?;
        let mut chapters: Vec<Chapter> = rows
            .iter()
            .map(|r| Chapter {
                slug: r.get::<_, String>("slug"),
                kind: r.get::<_, String>("kind"),
                order_key: r.get::<_, i32>("order_key"),
                title: r.get::<_, String>("title"),
                body_md: r.get::<_, String>("body_md"),
                illustration_url: r.get::<_, Option<String>>("illustration_url"),
                secondary_images: Vec::new(),
            })
            .collect();

        // Recover orphan brochure-img-pXXX-YYY.png assets that aren't
        // referenced by any chapter's illustration_url, and attach each to
        // the chapter whose hero index immediately precedes it.
        let asset_names: Vec<String> = tokio::time::timeout(
            std::time::Duration::from_secs(30),
            client.query(
                "SELECT name FROM ssot_brochure.assets \
                 WHERE name ~ '^brochure-img-p[0-9]+-[0-9]+\\.png$' \
                 ORDER BY name",
                &[],
            ),
        )
        .await
        .map(|r| r.map(|rows| rows.iter().map(|r| r.get::<_, String>("name")).collect()))
        .unwrap_or_else(|_| Ok(Vec::new()))
        .unwrap_or_default();
        attach_orphan_images(&mut chapters, &asset_names);

        Ok::<_, anyhow::Error>(chapters)
    })
}

/// Parse the `YYY` index from `brochure-img-pXXX-YYY.png`.
fn img_index(name: &str) -> Option<i32> {
    let stem = name.strip_prefix("brochure-img-")?.strip_suffix(".png")?;
    let dash = stem.rfind('-')?;
    stem[dash + 1..].parse().ok()
}

/// Attach orphan assets to chapters by index proximity: each orphan goes to
/// the chapter whose hero index is the largest one less than the orphan's.
pub fn attach_orphan_images(chapters: &mut [Chapter], asset_names: &[String]) {
    let mut used: std::collections::HashSet<String> = std::collections::HashSet::new();
    let mut hero_index: Vec<(i32, usize)> = Vec::new();
    for (i, ch) in chapters.iter().enumerate() {
        if let Some(url) = &ch.illustration_url {
            used.insert(url.clone());
            if let Some(idx) = img_index(url) {
                hero_index.push((idx, i));
            }
        }
    }
    hero_index.sort_by_key(|(idx, _)| *idx);

    // Group orphans by the chapter they would naturally attach to (largest
    // preceding hero index). Then distribute within each group: the first
    // orphan stays with the preceding chapter, subsequent orphans alternate
    // forward to the next chapter to avoid image-train pages where two or
    // more banners would stack on the same chapter.
    use std::collections::HashMap;
    let mut buckets: HashMap<usize, Vec<String>> = HashMap::new();
    for name in asset_names {
        if used.contains(name) {
            continue;
        }
        let Some(idx) = img_index(name) else { continue };
        let pos = hero_index.partition_point(|(hidx, _)| *hidx < idx);
        let owner_ch = if pos == 0 { 0 } else { hero_index[pos - 1].1 };
        buckets.entry(owner_ch).or_default().push(name.clone());
    }

    for (owner_ch, banners) in buckets {
        for (i, name) in banners.into_iter().enumerate() {
            let target = if i == 0 {
                owner_ch
            } else {
                // Push the rest forward to the chapter that follows the
                // preceding hero in document order; clamp to the last.
                let next = chapters
                    .iter()
                    .enumerate()
                    .skip(owner_ch + 1)
                    .find(|(_, c)| c.illustration_url.is_some())
                    .map(|(i, _)| i)
                    .unwrap_or(chapters.len().saturating_sub(1));
                if i == 1 { next } else { owner_ch }
            };
            chapters[target].secondary_images.push(name);
        }
    }
}

/// Count chapters without loading bodies. Used by `check()` to verify
/// table access cheaply.
pub fn count_chapters(cfg: &BuildConfig) -> Result<usize> {
    validate_table_ident(&cfg.chapters_table)?;
    let dsn = resolve_dsn(cfg)?;
    let table = cfg.chapters_table.clone();
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(1)
        .enable_all()
        .build()?;
    rt.block_on(async move {
        let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls)
            .await
            .context("postgres connect")?;
        tokio::spawn(async move {
            let _ = conn.await;
        });
        let sql = format!("SELECT count(*) AS n FROM {}", table);
        let row = client
            .query_one(&sql, &[])
            .await
            .context("count chapters")?;
        let n: i64 = row.get::<_, i64>("n");
        Ok::<_, anyhow::Error>(n as usize)
    })
}

/// Dry-run / check mode. Validates everything without producing a PDF.
pub fn check(cfg: &BuildConfig) -> Result<BuildReport> {
    validate_table_ident(&cfg.chapters_table)?;
    let mut notes = Vec::new();
    let database_url_present = std::env::var(&cfg.database_url_env)
        .map(|v| !v.is_empty())
        .unwrap_or(false)
        || std::env::var("RAILWAY_SSOT_URL")
            .map(|v| !v.is_empty())
            .unwrap_or(false);
    if !database_url_present {
        notes.push(format!(
            "no DSN in env (${} / $RAILWAY_SSOT_URL)",
            cfg.database_url_env
        ));
    }
    let pandoc_available = binary_available("pandoc");
    if !pandoc_available {
        notes.push("pandoc binary not on PATH".into());
    }
    let tectonic_available = binary_available("tectonic");
    if !tectonic_available {
        notes.push("tectonic binary not on PATH".into());
    }
    let template_resolved = resolve_under_root(&cfg.repo_root, &cfg.template);
    let template_ok = template_resolved.as_ref().map(|p| {
        let ok = p.is_file();
        if !ok {
            notes.push(format!("template missing: {}", p.display()));
        }
        ok
    });
    let lua_filter_resolved = resolve_under_root(&cfg.repo_root, &cfg.lua_filter);
    let lua_filter_ok = lua_filter_resolved.as_ref().map(|p| {
        let ok = p.is_file();
        if !ok {
            notes.push(format!("lua filter missing: {}", p.display()));
        }
        ok
    });
    let chapter_count = if database_url_present {
        match count_chapters(cfg) {
            Ok(n) => Some(n),
            Err(e) => {
                notes.push(format!("table access failed: {}", e));
                None
            }
        }
    } else {
        None
    };
    Ok(BuildReport {
        dry_run: true,
        database_url_env: cfg.database_url_env.clone(),
        database_url_present,
        chapters_table: cfg.chapters_table.clone(),
        chapter_count,
        pandoc_available,
        tectonic_available,
        template_ok,
        lua_filter_ok,
        markdown_path: None,
        tex_path: None,
        pdf_path: None,
        notes,
        book_mode: cfg.book_mode,
    })
}

/// Full build. Reads chapters via `loader`, writes markdown into
/// `build_dir`, runs pandoc, then tectonic. Returns paths to the produced
/// artefacts.
pub fn build(cfg: &BuildConfig, loader: &ChapterLoader) -> Result<BuildReport> {
    if cfg.dry_run {
        return check(cfg);
    }
    validate_table_ident(&cfg.chapters_table)?;
    let _dsn_present = resolve_dsn(cfg)?; // returns Err if missing
    let pandoc_available = binary_available("pandoc");
    if !pandoc_available {
        return Err(anyhow!("pandoc not found on PATH"));
    }
    let tectonic_available = binary_available("tectonic");
    if !tectonic_available {
        return Err(anyhow!("tectonic not found on PATH"));
    }
    ensure_dir(&cfg.build_dir)?;
    ensure_dir(&cfg.out_dir)?;

    eprintln!("[build] loading chapters...");
    let chapters = loader(cfg)?;
    if chapters.is_empty() {
        return Err(anyhow!("no chapters returned from {}", cfg.chapters_table));
    }
    eprintln!("[build] loaded {} chapters", chapters.len());

    eprintln!("[build] extracting assets...");
    let img_dir = cfg.build_dir.join("img");
    ensure_dir(&img_dir)?;
    let needed: Vec<&str> = chapters
        .iter()
        .filter_map(|c| c.illustration_url.as_deref())
        .collect();
    let missing: Vec<&str> = needed
        .iter()
        .cloned()
        .filter(|name| {
            let path = img_dir.join(name);
            !path.exists() || !is_png_valid(&path)
        })
        .collect();
    if !missing.is_empty() {
        eprintln!("[build] downloading {} missing assets from Postgres...", missing.len());
        let dsn = resolve_dsn(cfg)?;
        let rt = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(1)
            .enable_all()
            .build()?;
        rt.block_on(async {
            let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls)
                .await
                .context("postgres connect for assets")?;
            tokio::spawn(async move {
                let _ = conn.await;
            });
            let rows = tokio::time::timeout(
                std::time::Duration::from_secs(30),
                client.query(
                    "SELECT name, bytes::text AS bytes_hex FROM ssot_brochure.assets WHERE name = ANY($1)",
                    &[&missing],
                ),
            )
            .await
            .context("query assets timed out (30s)")?
            .context("query assets")?;
            for r in &rows {
                let name: String = r.get("name");
                let hex_str: String = r.get("bytes_hex");
                let bytes = hex_decode(&hex_str)
                    .with_context(|| format!("decode asset {}", name))?;
                let path = img_dir.join(&name);
                std::fs::write(&path, &bytes)
                    .with_context(|| format!("write asset {}", path.display()))?;
            }
            Ok::<_, anyhow::Error>(())
        })?;
    } else {
        eprintln!("[build] all {} assets already present", needed.len());
    }

    eprintln!("[build] rendering markdown...");
    let md = render_markdown(&chapters);
    let md_path = cfg.build_dir.join("main.md");
    std::fs::write(&md_path, &md).with_context(|| format!("write {}", md_path.display()))?;

    eprintln!("[build] running pandoc...");
    let tex_path = cfg.build_dir.join("main.tex");
    let pdf_path = cfg.out_dir.join(&cfg.pdf_name);

    let template_resolved = resolve_under_root(&cfg.repo_root, &cfg.template);
    let lua_filter_resolved = resolve_under_root(&cfg.repo_root, &cfg.lua_filter);

    let mut pandoc = Command::new("pandoc");
    pandoc.arg(&md_path).arg("-o").arg(&tex_path);
    pandoc.arg("--columns=60");
    if let Some(t) = &template_resolved {
        if !t.is_file() {
            return Err(anyhow!("template not found: {}", t.display()));
        }
        pandoc.arg("--template").arg(t);
    }
    if let Some(f) = &lua_filter_resolved {
        if !f.is_file() {
            return Err(anyhow!("lua filter not found: {}", f.display()));
        }
        pandoc.arg("--lua-filter").arg(f);
    }
    if cfg.book_mode {
        pandoc.arg("--toc");
        pandoc.arg("--top-level-division=chapter");
    }
    let status = pandoc.status().context("spawn pandoc")?;
    if !status.success() {
        return Err(anyhow!("pandoc failed: exit {:?}", status.code()));
    }

    // Post-process LaTeX: fix pandoc math-escaping issues where `$` was
    // backslash-escaped because raw_tex inline elements broke delimiter
    // recognition (e.g. `\texttt{...}$` or `$\sim$1`).
    let tex_content = std::fs::read_to_string(&tex_path)
        .with_context(|| format!("read generated tex: {}", tex_path.display()))?;
    let tex_fixed = tex_content
        .replace("\\\\$\\\\sim\\\\$", "\\(\\sim\\)")
        .replace("\\$\\sim\\$", "\\(\\sim\\)")
        .replace("\\\\texttt{0x47C0}\\\\$", "\\texttt{0x47C0}")
        .replace("\\texttt{0x47C0}\\$", "\\texttt{0x47C0}")
        .replace("\\setlength{\\tabcolsep}{4pt}", "\\setlength{\\tabcolsep}{1pt}")
        // Inline √2 and √5 are common math literals (golden ratio, etc.)
        // that pandoc passes through as bare unicode glyphs. Promote them
        // to proper math-mode \sqrt so the radical sign covers the digit.
        .replace("(1+√5)/2", "$(1+\\sqrt{5})/2$")
        .replace("(1-√5)/2", "$(1-\\sqrt{5})/2$")
        .replace("(1−√5)/2", "$(1-\\sqrt{5})/2$")
        .replace("1+√5", "$1+\\sqrt{5}$")
        .replace("1-√5", "$1-\\sqrt{5}$")
        .replace("1−√5", "$1-\\sqrt{5}$")
        .replace("√5/2", "$\\sqrt{5}/2$")
        .replace("√5", "$\\sqrt{5}$")
        .replace("√2", "$\\sqrt{2}$");
    if tex_fixed != tex_content {
        std::fs::write(&tex_path, tex_fixed)
            .with_context(|| format!("write fixed tex: {}", tex_path.display()))?;
    }

    let tectonic_stdout = cfg.build_dir.join("tectonic.stdout.log");
    let tectonic_stderr = cfg.build_dir.join("tectonic.stderr.log");
    eprintln!("[build] running tectonic...");
    let output = Command::new("tectonic")
        .arg("-X")
        .arg("compile")
        .arg(&tex_path)
        .arg("--outdir")
        .arg(&cfg.out_dir)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .output()
        .context("spawn tectonic")?;
    std::fs::write(&tectonic_stdout, &output.stdout).ok();
    std::fs::write(&tectonic_stderr, &output.stderr).ok();
    if !output.status.success() {
        return Err(anyhow!("tectonic failed: exit {:?}", output.status.code()));
    }

    // Optimize PDF images via qpdf if available
    let tectonic_pdf = cfg.out_dir.join("main.pdf");
    if binary_available("qpdf") {
        eprintln!("[build] optimizing PDF images...");
        let opt_pdf = cfg.out_dir.join("main-optimized.pdf");
        let status = Command::new("qpdf")
            .arg("--optimize-images")
            .arg(&tectonic_pdf)
            .arg(&opt_pdf)
            .status();
        if let Ok(st) = status {
            if st.success() && opt_pdf.exists() {
                let _ = std::fs::rename(&opt_pdf, &tectonic_pdf);
            }
        }
    }

    eprintln!("[build] renaming output...");
    // tectonic writes `<stem>.pdf` next to the input by default with
    // `--outdir`; rename to the configured filename if needed.
    if cfg.pdf_name != "main.pdf" && tectonic_pdf.exists() {
        std::fs::rename(&tectonic_pdf, &pdf_path)
            .with_context(|| format!("rename to {}", pdf_path.display()))?;
    }

    // Merge cover.pdf if it exists (produced by a prior build_cover call).
    let cover_pdf = cfg.build_dir.join("cover.pdf");
    if cover_pdf.exists() && binary_available("qpdf") {
        eprintln!("[build] merging cover.pdf...");
        let merged = cfg.out_dir.join("main-merged.pdf");
        let status = Command::new("qpdf")
            .arg("--empty")
            .arg("--pages")
            .arg(&cover_pdf)
            .arg(&pdf_path)
            .arg("--")
            .arg(&merged)
            .status();
        if let Ok(st) = status {
            if st.success() && merged.exists() {
                let _ = std::fs::rename(&merged, &pdf_path);
            }
        }
    }

    eprintln!("[build] done");

    Ok(BuildReport {
        dry_run: false,
        database_url_env: cfg.database_url_env.clone(),
        database_url_present: true,
        chapters_table: cfg.chapters_table.clone(),
        chapter_count: Some(chapters.len()),
        pandoc_available,
        tectonic_available,
        template_ok: template_resolved.as_ref().map(|p| p.is_file()),
        lua_filter_ok: lua_filter_resolved.as_ref().map(|p| p.is_file()),
        markdown_path: Some(md_path),
        tex_path: Some(tex_path),
        pdf_path: Some(pdf_path),
        notes: Vec::new(),
        book_mode: cfg.book_mode,
    })
}

/// Parse CLI args of the form `--key value` / `--flag` into a BuildConfig.
/// Unknown keys produce an error so typos don't silently no-op.
#[allow(dead_code)]
pub fn parse_cli(args: &[String]) -> Result<BuildConfig> {
    let mut cfg = BuildConfig::default();
    let mut i = 0;
    while i < args.len() {
        let a = &args[i];
        match a.as_str() {
            "--dry-run" | "--check" => {
                cfg.dry_run = true;
                i += 1;
            }
            "--database-url-env" => {
                cfg.database_url_env = args
                    .get(i + 1)
                    .ok_or_else(|| anyhow!("--database-url-env needs a value"))?
                    .clone();
                i += 2;
            }
            "--chapters-table" => {
                cfg.chapters_table = args
                    .get(i + 1)
                    .ok_or_else(|| anyhow!("--chapters-table needs a value"))?
                    .clone();
                i += 2;
            }
            "--out-dir" => {
                cfg.out_dir = PathBuf::from(
                    args.get(i + 1)
                        .ok_or_else(|| anyhow!("--out-dir needs a value"))?,
                );
                i += 2;
            }
            "--build-dir" => {
                cfg.build_dir = PathBuf::from(
                    args.get(i + 1)
                        .ok_or_else(|| anyhow!("--build-dir needs a value"))?,
                );
                i += 2;
            }
            "--template" => {
                cfg.template = Some(PathBuf::from(
                    args.get(i + 1)
                        .ok_or_else(|| anyhow!("--template needs a value"))?,
                ));
                i += 2;
            }
            "--lua-filter" => {
                cfg.lua_filter = Some(PathBuf::from(
                    args.get(i + 1)
                        .ok_or_else(|| anyhow!("--lua-filter needs a value"))?,
                ));
                i += 2;
            }
            "--repo-root" => {
                cfg.repo_root = PathBuf::from(
                    args.get(i + 1)
                        .ok_or_else(|| anyhow!("--repo-root needs a value"))?,
                );
                i += 2;
            }
            "--pdf-name" => {
                cfg.pdf_name = args
                    .get(i + 1)
                    .ok_or_else(|| anyhow!("--pdf-name needs a value"))?
                    .clone();
                i += 2;
            }
            "--limit" => {
                let v: usize = args
                    .get(i + 1)
                    .ok_or_else(|| anyhow!("--limit needs a value"))?
                    .parse()
                    .context("--limit must be a non-negative integer")?;
                cfg.limit = Some(v);
                i += 2;
            }
            "--book-mode" => {
                cfg.book_mode = true;
                i += 1;
            }
            other => return Err(anyhow!("unknown build-pdf arg: {}", other)),
        }
    }
    Ok(cfg)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ch(order: i32, slug: &str, title: &str, body: &str) -> Chapter {
        ch_kind("essay", order, slug, title, body)
    }

    fn ch_kind(kind: &str, order: i32, slug: &str, title: &str, body: &str) -> Chapter {
        Chapter {
            slug: slug.into(),
            kind: kind.into(),
            order_key: order,
            title: title.into(),
            body_md: body.into(),
            illustration_url: None,
            secondary_images: Vec::new(),
        }
    }

    #[test]
    fn markdown_orders_by_order_key() {
        let input = vec![
            ch(20, "b", "Beta", "second"),
            ch(10, "a", "Alpha", "first"),
            ch(30, "c", "Gamma", "third"),
        ];
        let md = render_markdown(&input);
        let pa = md.find("Alpha").unwrap();
        let pb = md.find("Beta").unwrap();
        let pc = md.find("Gamma").unwrap();
        assert!(pa < pb && pb < pc, "expected Alpha,Beta,Gamma order");
    }

    #[test]
    fn markdown_breaks_ties_by_slug() {
        let input = vec![ch(10, "b", "Bee", "body"), ch(10, "a", "Aye", "body")];
        let md = render_markdown(&input);
        assert!(md.find("Aye").unwrap() < md.find("Bee").unwrap());
    }

    #[test]
    fn markdown_orders_book_kinds_before_raw_order_key() {
        let input = vec![
            ch_kind("paper1", 10, "paper", "Paper", "body"),
            ch_kind("frontmatter", 99, "front", "Front", "body"),
            ch_kind("appx-a", 1, "appendix", "Appendix", "body"),
        ];
        let md = render_markdown(&input);
        let front = md.find("Front").unwrap();
        let paper = md.find("Paper").unwrap();
        let appendix = md.find("Appendix").unwrap();
        assert!(front < paper && paper < appendix);
    }

    #[test]
    fn markdown_emits_slug_marker_and_h1() {
        let input = vec![ch(1, "intro", "Introduction", "Hello.")];
        let md = render_markdown(&input);
        assert!(md.contains("<!-- chapter: intro -->"));
        assert!(md.contains("# Introduction"));
        assert!(md.contains("Hello."));
    }

    #[test]
    fn markdown_repairs_absolute_value_pipes_in_tables() {
        let body = "\
| # | Identity | Author | Status |
|---|---------|--------|--------|
| A6 | θ_QCD = |φ² + φ⁻² − 3| = 0 | Vasilev | EXACT |
";
        let md = render_markdown(&[ch(1, "table", "Table", body)]);
        assert!(md.contains("θ_QCD = \\|φ² + φ⁻² − 3\\| = 0"));
        assert!(md.contains("| A6 | θ_QCD"));
    }

    #[test]
    fn markdown_adds_break_spaces_to_dense_formula_cells() {
        let body = "\
| ID | Formula |
|----|---------|
| G01 | 360/φ²−2/φ³+(3φ)⁻⁵ |
";
        let md = render_markdown(&[ch(1, "table", "Table", body)]);
        assert!(md.contains("360 / φ² − 2 / φ³ + (3φ)⁻⁵"));
    }

    #[test]
    fn orphan_assets_attach_to_previous_hero_index() {
        let mut chapters = vec![
            Chapter {
                illustration_url: Some("brochure-img-p001-010.png".into()),
                ..ch(10, "a", "A", "body")
            },
            Chapter {
                illustration_url: Some("brochure-img-p002-020.png".into()),
                ..ch(20, "b", "B", "body")
            },
        ];
        let assets = vec![
            "brochure-img-p001-010.png".to_string(),
            "brochure-img-p001-011.png".to_string(),
            "brochure-img-p001-012.png".to_string(),
            "brochure-img-p002-021.png".to_string(),
        ];
        attach_orphan_images(&mut chapters, &assets);
        assert_eq!(
            chapters[0].secondary_images,
            vec!["brochure-img-p001-011.png".to_string()]
        );
        let mut actual1 = chapters[1].secondary_images.clone();
        actual1.sort();
        assert_eq!(
            actual1,
            vec![
                "brochure-img-p001-012.png".to_string(),
                "brochure-img-p002-021.png".to_string()
            ]
        );
    }

    #[test]
    fn validate_table_ident_accepts_schema_qualified() {
        validate_table_ident("ssot_brochure.chapters").unwrap();
        validate_table_ident("ssot.chapters").unwrap();
        validate_table_ident("chapters").unwrap();
    }

    #[test]
    fn validate_table_ident_rejects_garbage() {
        assert!(validate_table_ident("").is_err());
        assert!(validate_table_ident("a;drop").is_err());
        assert!(validate_table_ident("a..b").is_err());
        assert!(validate_table_ident("a.b c").is_err());
        assert!(validate_table_ident("a-b").is_err());
    }

    #[test]
    fn resolve_dsn_returns_value_when_env_set() {
        // Use a unique var name so the test doesn't race with anything else.
        let var = "TRIOS_PDF_PIPELINE_TEST_PRESENT";
        std::env::set_var(var, "test-dsn-value");
        let mut cfg = BuildConfig::default();
        cfg.database_url_env = var.into();
        let v = resolve_dsn(&cfg).unwrap();
        assert_eq!(v, "test-dsn-value");
        std::env::remove_var(var);
    }

    #[test]
    fn parse_cli_round_trip() {
        let args: Vec<String> = [
            "--dry-run",
            "--out-dir",
            "/tmp/out",
            "--build-dir",
            "/tmp/build",
            "--template",
            "templates/chapter.template.tex",
            "--lua-filter",
            "filters/force-fullwidth-hero.lua",
            "--repo-root",
            "/repo",
            "--chapters-table",
            "ssot.chapters",
            "--limit",
            "5",
            "--pdf-name",
            "phd.pdf",
            "--book-mode",
        ]
        .iter()
        .map(|s| s.to_string())
        .collect();
        let cfg = parse_cli(&args).unwrap();
        assert!(cfg.dry_run);
        assert_eq!(cfg.out_dir, PathBuf::from("/tmp/out"));
        assert_eq!(cfg.build_dir, PathBuf::from("/tmp/build"));
        assert_eq!(
            cfg.template,
            Some(PathBuf::from("templates/chapter.template.tex"))
        );
        assert_eq!(
            cfg.lua_filter,
            Some(PathBuf::from("filters/force-fullwidth-hero.lua"))
        );
        assert_eq!(cfg.repo_root, PathBuf::from("/repo"));
        assert_eq!(cfg.chapters_table, "ssot.chapters");
        assert_eq!(cfg.limit, Some(5));
        assert_eq!(cfg.pdf_name, "phd.pdf");
        assert!(cfg.book_mode);
    }

    #[test]
    fn parse_cli_rejects_unknown_flag() {
        let args = vec!["--nope".to_string()];
        assert!(parse_cli(&args).is_err());
    }

    /// `check()` resolves paths and surfaces missing-file notes without
    /// hitting the network. We point it at env vars that are definitely
    /// unset so the Postgres branch is skipped deterministically.
    fn check_isolated(mut cfg: BuildConfig) -> BuildReport {
        cfg.database_url_env = "TRIOS_PIPELINE_TEST_UNSET_VAR_XYZ".into();
        check(&cfg).unwrap()
    }

    #[test]
    fn check_template_missing_is_reported() {
        let mut cfg = BuildConfig::default();
        cfg.repo_root = std::env::temp_dir();
        cfg.template = Some(PathBuf::from("definitely/does/not/exist.tex"));
        let r = check_isolated(cfg);
        assert_eq!(r.template_ok, Some(false));
        assert!(r.notes.iter().any(|n| n.contains("template missing")));
    }

    #[test]
    fn check_lua_filter_missing_is_reported() {
        let mut cfg = BuildConfig::default();
        cfg.repo_root = std::env::temp_dir();
        cfg.lua_filter = Some(PathBuf::from("definitely/missing.lua"));
        let r = check_isolated(cfg);
        assert_eq!(r.lua_filter_ok, Some(false));
        assert!(r.notes.iter().any(|n| n.contains("lua filter missing")));
    }
}
