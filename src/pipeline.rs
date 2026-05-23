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
        if !part
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_')
        {
            return Err(anyhow!(
                "chapters_table segment {:?} is not a plain identifier",
                part
            ));
        }
    }
    Ok(())
}

/// Render an ordered chapter list into a single Markdown document.
///
/// Chapters are emitted in `order_key` ascending order. Each chapter is
/// preceded by an HTML comment marker carrying its slug, then an `H1`
/// with the title, then its `body_md` verbatim. The marker lets the Lua
/// filter target individual chapters later.
pub fn render_markdown(chapters: &[Chapter]) -> String {
    let mut ordered: Vec<&Chapter> = chapters.iter().collect();
    ordered.sort_by_key(|c| (c.order_key, c.slug.clone()));
    let mut out = String::new();
    for (i, ch) in ordered.iter().enumerate() {
        if i > 0 {
            out.push_str("\n\n");
        }
        out.push_str(&format!("<!-- chapter: {} -->\n", ch.slug));
        out.push_str(&format!("# {}\n\n", ch.title));
        out.push_str(ch.body_md.trim_end());
        out.push('\n');
    }
    out
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
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(async move {
        let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls)
            .await
            .context("postgres connect")?;
        tokio::spawn(async move {
            let _ = conn.await;
        });
        let mut sql = format!(
            "SELECT slug, kind, order_key, title, body_md \
             FROM {} ORDER BY order_key",
            table
        );
        if let Some(n) = limit {
            sql.push_str(&format!(" LIMIT {}", n as i64));
        }
        let rows = client.query(&sql, &[]).await.context("query chapters")?;
        let chapters: Vec<Chapter> = rows
            .iter()
            .map(|r| Chapter {
                slug: r.get::<_, String>("slug"),
                kind: r.get::<_, String>("kind"),
                order_key: r.get::<_, i32>("order_key"),
                title: r.get::<_, String>("title"),
                body_md: r.get::<_, String>("body_md"),
            })
            .collect();
        Ok::<_, anyhow::Error>(chapters)
    })
}

/// Count chapters without loading bodies. Used by `check()` to verify
/// table access cheaply.
pub fn count_chapters(cfg: &BuildConfig) -> Result<usize> {
    validate_table_ident(&cfg.chapters_table)?;
    let dsn = resolve_dsn(cfg)?;
    let table = cfg.chapters_table.clone();
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(async move {
        let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls)
            .await
            .context("postgres connect")?;
        tokio::spawn(async move {
            let _ = conn.await;
        });
        let sql = format!("SELECT count(*) AS n FROM {}", table);
        let row = client.query_one(&sql, &[]).await.context("count chapters")?;
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

    let chapters = loader(cfg)?;
    if chapters.is_empty() {
        return Err(anyhow!(
            "no chapters returned from {}",
            cfg.chapters_table
        ));
    }
    let md = render_markdown(&chapters);
    let md_path = cfg.build_dir.join("main.md");
    std::fs::write(&md_path, &md).with_context(|| format!("write {}", md_path.display()))?;

    let tex_path = cfg.build_dir.join("main.tex");
    let pdf_path = cfg.out_dir.join(&cfg.pdf_name);

    let template_resolved = resolve_under_root(&cfg.repo_root, &cfg.template);
    let lua_filter_resolved = resolve_under_root(&cfg.repo_root, &cfg.lua_filter);

    let mut pandoc = Command::new("pandoc");
    pandoc.arg(&md_path).arg("-o").arg(&tex_path);
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
    let status = pandoc.status().context("spawn pandoc")?;
    if !status.success() {
        return Err(anyhow!("pandoc failed: exit {:?}", status.code()));
    }

    let status = Command::new("tectonic")
        .arg("-X")
        .arg("compile")
        .arg(&tex_path)
        .arg("--outdir")
        .arg(&cfg.out_dir)
        .status()
        .context("spawn tectonic")?;
    if !status.success() {
        return Err(anyhow!("tectonic failed: exit {:?}", status.code()));
    }

    // tectonic writes `<stem>.pdf` next to the input by default with
    // `--outdir`; rename to the configured filename if needed.
    let tectonic_pdf = cfg.out_dir.join("main.pdf");
    if cfg.pdf_name != "main.pdf" && tectonic_pdf.exists() {
        std::fs::rename(&tectonic_pdf, &pdf_path)
            .with_context(|| format!("rename to {}", pdf_path.display()))?;
    }

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
    })
}

/// Parse CLI args of the form `--key value` / `--flag` into a BuildConfig.
/// Unknown keys produce an error so typos don't silently no-op.
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
                    args.get(i + 1).ok_or_else(|| anyhow!("--out-dir needs a value"))?,
                );
                i += 2;
            }
            "--build-dir" => {
                cfg.build_dir = PathBuf::from(
                    args.get(i + 1).ok_or_else(|| anyhow!("--build-dir needs a value"))?,
                );
                i += 2;
            }
            "--template" => {
                cfg.template = Some(PathBuf::from(
                    args.get(i + 1).ok_or_else(|| anyhow!("--template needs a value"))?,
                ));
                i += 2;
            }
            "--lua-filter" => {
                cfg.lua_filter = Some(PathBuf::from(
                    args.get(i + 1).ok_or_else(|| anyhow!("--lua-filter needs a value"))?,
                ));
                i += 2;
            }
            "--repo-root" => {
                cfg.repo_root = PathBuf::from(
                    args.get(i + 1).ok_or_else(|| anyhow!("--repo-root needs a value"))?,
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
            other => return Err(anyhow!("unknown build-pdf arg: {}", other)),
        }
    }
    Ok(cfg)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ch(order: i32, slug: &str, title: &str, body: &str) -> Chapter {
        Chapter {
            slug: slug.into(),
            kind: "essay".into(),
            order_key: order,
            title: title.into(),
            body_md: body.into(),
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
        let input = vec![
            ch(10, "b", "Bee", "body"),
            ch(10, "a", "Aye", "body"),
        ];
        let md = render_markdown(&input);
        assert!(md.find("Aye").unwrap() < md.find("Bee").unwrap());
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
        std::env::set_var(var, "postgresql://x/y");
        let mut cfg = BuildConfig::default();
        cfg.database_url_env = var.into();
        let v = resolve_dsn(&cfg).unwrap();
        assert_eq!(v, "postgresql://x/y");
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
