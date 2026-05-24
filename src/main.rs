use clap::Parser;
use serde_json::{json, Value};
use std::env;
use std::io::{self, BufRead, Write};
use std::path::PathBuf;

mod pipeline;

#[derive(Parser, Debug)]
#[command(name = "trios-mcp-rag", version, about = "MCP server + CLI for GOLDEN BRIDGE PDF pipeline")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Parser, Debug)]
enum Commands {
    /// Build the SSOT → Markdown → pandoc → tectonic → PDF pipeline
    BuildPdf {
        /// Run in dry-run mode (check env/deps only)
        #[arg(long)]
        dry_run: bool,
        /// Environment variable name for the DSN
        #[arg(long, default_value = "DATABASE_URL")]
        database_url_env: String,
        /// SSOT chapters table
        #[arg(long, default_value = "ssot_brochure.chapters")]
        chapters_table: String,
        /// Output directory for the final PDF
        #[arg(long)]
        out_dir: Option<PathBuf>,
        /// Build directory for intermediate files
        #[arg(long)]
        build_dir: Option<PathBuf>,
        /// Pandoc LaTeX template path
        #[arg(long)]
        template: Option<PathBuf>,
        /// Pandoc Lua filter path
        #[arg(long)]
        lua_filter: Option<PathBuf>,
        /// Repository root for resolving relative paths
        #[arg(long)]
        repo_root: Option<PathBuf>,
        /// Output PDF filename
        #[arg(long, default_value = "main.pdf")]
        pdf_name: String,
        /// Limit number of chapters processed
        #[arg(long)]
        limit: Option<usize>,
        /// Enable book mode (--toc --top-level-division=chapter)
        #[arg(long, default_value_t = true)]
        book_mode: bool,
    },
}

fn dsn() -> String {
    env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://postgres:postgres@localhost:5432/railway".into())
}

fn query_rows(
    sql: &str,
    params: &[&(dyn tokio_postgres::types::ToSql + Sync)],
) -> anyhow::Result<Vec<tokio_postgres::Row>> {
    let dsn = dsn();
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(async {
        let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls).await?;
        tokio::spawn(async move {
            let _ = conn.await;
        });
        let rows = client.query(sql, params).await?;
        Ok(rows)
    })
}

fn execute_sql(sql: &str) -> anyhow::Result<u64> {
    let dsn = dsn();
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(async {
        let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls).await?;
        tokio::spawn(async move {
            let _ = conn.await;
        });
        let rows = client.execute(sql, &[]).await?;
        Ok(rows)
    })
}

fn rs(r: &tokio_postgres::Row, col: &str) -> String {
    r.get::<_, String>(col)
}
fn ri(r: &tokio_postgres::Row, col: &str) -> i32 {
    r.get::<_, i32>(col)
}

fn tool_search(query: &str, limit: usize) -> anyhow::Result<Value> {
    let pattern = format!("%{}%", query.replace('%', "\\%"));
    let rows = query_rows(
        "SELECT slug, kind, title, LEFT(body_md, 500) AS snippet \
         FROM ssot_brochure.chapters \
         WHERE body_md ILIKE $1 OR title ILIKE $1 \
         ORDER BY order_key LIMIT $2",
        &[
            &pattern as &(dyn tokio_postgres::types::ToSql + Sync),
            &(limit as i64) as &(dyn tokio_postgres::types::ToSql + Sync),
        ],
    )?;
    let out: Vec<Value> = rows.iter().map(|r| json!({
        "slug": rs(r,"slug"), "kind": rs(r,"kind"), "title": rs(r,"title"), "snippet": rs(r,"snippet")
    })).collect();
    Ok(
        json!({"content":[{"type":"text","text":serde_json::to_string_pretty(&out)?}],"isError":false}),
    )
}

fn tool_get(slug: &str) -> anyhow::Result<Value> {
    let rows = query_rows(
        "SELECT slug, kind, order_key, title, body_md, word_count FROM ssot_brochure.chapters WHERE slug=$1",
        &[&slug],
    )?;
    if rows.is_empty() {
        return Ok(
            json!({"content":[{"type":"text","text":format!("Chapter '{}' not found",slug)}],"isError":true}),
        );
    }
    let r = &rows[0];
    Ok(
        json!({"content":[{"type":"text","text":serde_json::to_string_pretty(&json!({
        "slug":rs(r,"slug"),"kind":rs(r,"kind"),"order_key":ri(r,"order_key"),
        "title":rs(r,"title"),"word_count":ri(r,"word_count"),"body_md":rs(r,"body_md")
    }))?}],"isError":false}),
    )
}

fn tool_list() -> anyhow::Result<Value> {
    let rows = query_rows(
        "SELECT slug, kind, order_key, title, word_count FROM ssot_brochure.chapters ORDER BY order_key",
        &[],
    )?;
    let out: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "slug":rs(r,"slug"),"kind":rs(r,"kind"),"order_key":ri(r,"order_key"),
                "title":rs(r,"title"),"words":ri(r,"word_count")
            })
        })
        .collect();
    Ok(
        json!({"content":[{"type":"text","text":serde_json::to_string_pretty(&out)?}],"isError":false}),
    )
}

fn tool_audit() -> anyhow::Result<Value> {
    let forbidden = [
        "63 tok/s/W",
        "tok/s/W",
        "compete with nvidia",
        "vasilev-pellis constants",
        "claude",
        "rollback",
    ];
    let rows = query_rows("SELECT slug, body_md FROM ssot_brochure.chapters", &[])?;
    let mut hits = Vec::new();
    for r in &rows {
        let s = rs(r, "slug");
        let b = rs(r, "body_md").to_lowercase();
        for t in &forbidden {
            if b.contains(t) {
                hits.push(json!({"slug":s,"term":t}));
            }
        }
    }
    let msg = if hits.is_empty() {
        "CLEAN".into()
    } else {
        format!(
            "{} violations: {}",
            hits.len(),
            serde_json::to_string(&hits)?
        )
    };
    Ok(json!({"content":[{"type":"text","text":msg}],"isError":false}))
}

fn tool_cover() -> anyhow::Result<Value> {
    let rows = query_rows(
        "SELECT count(*) AS n, sum(word_count) AS tw FROM ssot_brochure.chapters",
        &[],
    )?;
    let n: i64 = rows[0].get::<_, i64>("n");
    let tw: i64 = rows[0].get::<_, Option<i64>>("tw").unwrap_or(0);
    let tex = format!(
        r"\begin{{titlepage}}\centering\vspace*{{2cm}}\n{{\Huge\bfseries GOLDEN BRIDGE}}\\[0.5em]\n{{\Large A Three-Strand Compendium on $\varphi$-Structured Physical Constants and Ternary Silicon}}\\[2em]\n{{\large Dmitrii Vasilev \\ Stergios Pellis \\ Kenneth Olsen}}\\[1em]\n{{\large April 2026 \\ v27}}\\[2em]\n\rule{{\textwidth}}{{0.4pt}}\\[1em]\n{{\textit{{Railway PostgreSQL SSOT}}}}\\[0.5em]\n{{\texttt{{{n} chapters, {tw} words}}}}\\[2em]\n\rule{{\textwidth}}{{0.4pt}}\\[2em]\n{{\small $\varphi^2 + \varphi^{{-2}} = 3$ (Coq Qed) \quad 0x47C0 silicon anchor (Theorem 36.1)}}\\[0.5em]\n{{\small $\sim$1 GOPS @ $\sim$50 MHz @ $\sim$1 W ternary (projected)}}\\[3em]\n\end{{titlepage}}\n"
    );
    Ok(json!({"content":[{"type":"text","text":tex}],"isError":false}))
}

/// MCP `build_pdf` tool: dispatch the SSOT -> PDF pipeline.
fn tool_build_pdf(args: &Value) -> anyhow::Result<Value> {
    let mut cfg = pipeline::BuildConfig::default();
    if let Some(s) = args.get("database_url_env").and_then(|v| v.as_str()) {
        cfg.database_url_env = s.into();
    }
    if let Some(s) = args.get("chapters_table").and_then(|v| v.as_str()) {
        cfg.chapters_table = s.into();
    }
    if let Some(s) = args.get("out_dir").and_then(|v| v.as_str()) {
        cfg.out_dir = PathBuf::from(s);
    }
    if let Some(s) = args.get("build_dir").and_then(|v| v.as_str()) {
        cfg.build_dir = PathBuf::from(s);
    }
    if let Some(s) = args.get("template").and_then(|v| v.as_str()) {
        cfg.template = Some(PathBuf::from(s));
    }
    if let Some(s) = args.get("lua_filter").and_then(|v| v.as_str()) {
        cfg.lua_filter = Some(PathBuf::from(s));
    }
    if let Some(s) = args.get("repo_root").and_then(|v| v.as_str()) {
        cfg.repo_root = PathBuf::from(s);
    }
    if let Some(s) = args.get("pdf_name").and_then(|v| v.as_str()) {
        cfg.pdf_name = s.into();
    }
    if let Some(n) = args.get("limit").and_then(|v| v.as_u64()) {
        cfg.limit = Some(n as usize);
    }
    cfg.book_mode = args.get("book_mode").and_then(|v| v.as_bool()).unwrap_or(true);
    if cfg.template.is_none() {
        cfg.template = Some(cfg.repo_root.join("templates").join("chapter.template.tex"));
    }
    if cfg.lua_filter.is_none() {
        cfg.lua_filter = Some(cfg.repo_root.join("filters").join("force-fullwidth-hero.lua"));
    }
    let dry_run_default = true;
    cfg.dry_run = args
        .get("dry_run")
        .and_then(|v| v.as_bool())
        .unwrap_or(dry_run_default);
    let report = if cfg.dry_run {
        pipeline::check(&cfg)?
    } else {
        pipeline::build(&cfg, &pipeline::load_from_postgres)?
    };
    Ok(json!({
        "content": [{"type":"text","text": serde_json::to_string_pretty(&report)?}],
        "isError": false
    }))
}

/// `get_claim_status` — search chapters for claim-status markers.
fn tool_get_claim_status(args: &Value) -> anyhow::Result<Value> {
    let query = args.get("query").and_then(|v| v.as_str()).unwrap_or("");
    let pattern = format!("%{}%", query.replace('%', "\\%"));
    let rows = query_rows(
        "SELECT slug, kind, title, body_md FROM ssot_brochure.chapters \
         WHERE body_md ILIKE $1 OR title ILIKE $1 OR slug ILIKE $1 \
         ORDER BY order_key",
        &[&pattern],
    )?;
    let mut out = Vec::new();
    for r in &rows {
        let body = rs(r, "body_md");
        let lines: Vec<&str> = body.lines().collect();
        let mut matches = Vec::new();
        for (i, line) in lines.iter().enumerate() {
            let lower = line.to_lowercase();
            if lower.contains("verified")
                || lower.contains("empirical fit")
                || lower.contains("open conjecture")
                || lower.contains("high-risk")
                || lower.contains("falsified")
                || lower.contains("retracted")
                || lower.contains("unverified")
                || lower.contains("hallucinated")
            {
                matches.push(json!({"line_number": i+1, "text": line.trim()}));
            }
        }
        if !matches.is_empty() {
            out.push(json!({
                "slug": rs(r,"slug"), "kind": rs(r,"kind"), "title": rs(r,"title"),
                "claim_matches": matches
            }));
        }
    }
    Ok(json!({
        "content": [{"type":"text","text": serde_json::to_string_pretty(&json!({"query": query, "chapters_with_claims": out, "total_hits": out.len()}))?}],
        "isError": false
    }))
}

/// `list_claims` — scan all chapters for claim-status vocabulary.
fn tool_list_claims() -> anyhow::Result<Value> {
    let rows = query_rows(
        "SELECT slug, kind, title, body_md FROM ssot_brochure.chapters",
        &[],
    )?;
    let mut out = Vec::new();
    for r in &rows {
        let body = rs(r, "body_md");
        let statuses = [
            "Verified",
            "Empirical fit",
            "Open conjecture",
            "High-risk",
            "Falsified",
            "Retracted",
            "Unverified",
        ];
        let mut found = Vec::new();
        for status in &statuses {
            let count = body.matches(status).count();
            if count > 0 {
                found.push(json!({"status": status, "count": count}));
            }
        }
        if !found.is_empty() {
            out.push(json!({
                "slug": rs(r,"slug"), "kind": rs(r,"kind"), "title": rs(r,"title"),
                "statuses": found
            }));
        }
    }
    Ok(json!({
        "content": [{"type":"text","text": serde_json::to_string_pretty(&json!({"chapters_with_claims": out, "total": out.len()}))?}],
        "isError": false
    }))
}

/// `get_honest_counters` — return the corrected snapshot from trinity-s3ai audit.
fn tool_get_honest_counters() -> anyhow::Result<Value> {
    let data = json!({
        "source": "trinity-s3ai main branch audit 2026-05-24",
        "repo": "github.com/gHashTag/trinity-s3ai",
        "coq_files": 79,
        "qed_defined": 1762,
        "real_admitted": 5,
        "axioms_conjectures_parameters": 85,
        "refutation_theorems": 14,
        "no_go_theorems": 4,
        "delta_cp_status": {
            "formula": "3/phi^2",
            "value_degrees": 65.66,
            "physical_interpretation": "WITHDRAWN (PR #22)",
            "data_tension": "5.6 sigma excluded"
        },
        "hallucinated_claims": [
            "delta_CP = -105 degrees (does not exist in repo)",
            "V4 NLO sum rule in Coq (does not exist)",
            "1339 Qed / 33 Admitted (stale counters)"
        ],
        "retracted_claims": [
            "N_gen = 3 derived from H4 (PR #31)",
            "Strong CP solved (PR #32)",
            "delta_CP = 65.66 as physical prediction (PR #22)"
        ],
        "lagrangian_status": "Postulated, not derived. See CORRECTED_GAP_ANALYSIS.md"
    });
    Ok(json!({
        "content": [{"type":"text","text": serde_json::to_string_pretty(&data)?}],
        "isError": false
    }))
}

/// `preview_chapter_update` — dry-run: show exact SQL diff without executing.
fn tool_preview_chapter_update(args: &Value) -> anyhow::Result<Value> {
    let slug = args.get("slug").and_then(|v| v.as_str()).unwrap_or("");
    let new_body = args
        .get("new_body_md")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if slug.is_empty() {
        return Ok(
            json!({"content":[{"type":"text","text":"Missing 'slug' argument"}],"isError":true}),
        );
    }
    let rows = query_rows(
        "SELECT slug, title, body_md, word_count FROM ssot_brochure.chapters WHERE slug=$1",
        &[&slug],
    )?;
    if rows.is_empty() {
        return Ok(
            json!({"content":[{"type":"text","text":format!("Chapter '{}' not found", slug)}],"isError":true}),
        );
    }
    let r = &rows[0];
    let old_body: String = r.get("body_md");
    let old_words: i32 = r.get("word_count");
    let new_words = new_body.split_whitespace().count() as i32;
    let sql = format!(
        "UPDATE ssot_brochure.chapters SET body_md = $1, word_count = {} WHERE slug = '{}'",
        new_words,
        slug.replace("'", "''")
    );
    let diff = json!({
        "slug": slug,
        "title": r.get::<_, String>("title"),
        "old_word_count": old_words,
        "new_word_count": new_words,
        "old_body_length": old_body.len(),
        "new_body_length": new_body.len(),
        "body_changed": old_body != new_body,
        "exact_sql_template": sql,
        "warning": "This is a DRY-RUN. No changes were made. Use explicit confirmation before executing any UPDATE."
    });
    Ok(json!({
        "content": [{"type":"text","text": serde_json::to_string_pretty(&diff)?}],
        "isError": false
    }))
}

/// `backup_ssot` — create a timestamped backup table.
fn tool_backup_ssot(args: &Value) -> anyhow::Result<Value> {
    let confirm = args
        .get("confirm")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    let table = args
        .get("chapters_table")
        .and_then(|v| v.as_str())
        .unwrap_or("ssot_brochure.chapters");
    if !pipeline::validate_table_ident(table).is_ok() {
        return Ok(
            json!({"content":[{"type":"text","text":"Invalid table identifier"}],"isError":true}),
        );
    }
    let backup_name = format!(
        "ssot_brochure.chapters_backup_{}",
        chrono::Local::now().format("%Y%m%d_%H%M%S")
    );
    if !confirm {
        return Ok(json!({
            "content": [{"type":"text","text": format!(
                "DRY-RUN: Would execute:\nCREATE TABLE {} AS SELECT * FROM {};\n\nSet confirm=true to execute. WARNING: This creates a write in the database.",
                backup_name, table
            )}],
            "isError": false
        }));
    }
    let sql = format!("CREATE TABLE {} AS SELECT * FROM {}", backup_name, table);
    match execute_sql(&sql) {
        Ok(rows) => Ok(json!({
            "content": [{"type":"text","text": format!(
                "BACKUP CREATED: {} ({} rows copied from {}).\nTo restore: DROP TABLE {}; INSERT INTO {} SELECT * FROM {};",
                backup_name, rows, table, table, table, backup_name
            )}],
            "isError": false
        })),
        Err(e) => Ok(json!({
            "content": [{"type":"text","text": format!("Backup failed: {}", e)}],
            "isError": true
        })),
    }
}

fn tools_def() -> Value {
    json!([
        {"name":"search_chapters","description":"Full-text search across all 80 GOLDEN BRIDGE chapters in Railway SSOT",
         "inputSchema":{"type":"object","properties":{"query":{"type":"string"},"limit":{"type":"integer","default":10}},"required":["query"]}},
        {"name":"get_chapter","description":"Fetch full chapter by slug",
         "inputSchema":{"type":"object","properties":{"slug":{"type":"string"}},"required":["slug"]}},
        {"name":"list_chapters","description":"List all chapter slugs with metadata",
         "inputSchema":{"type":"object","properties":{}}},
        {"name":"forbidden_audit","description":"Scan all chapters for policy violations",
         "inputSchema":{"type":"object","properties":{}}},
        {"name":"build_cover","description":"Generate LaTeX titlepage for GOLDEN BRIDGE v27",
         "inputSchema":{"type":"object","properties":{}}},
        {"name":"build_pdf","description":"Run the SSOT->Markdown->pandoc->tectonic->PDF pipeline. Defaults to dry_run=true (check env/deps/paths only). Set dry_run=false to actually build.",
         "inputSchema":{"type":"object","properties":{
            "dry_run":{"type":"boolean","default":true},
            "database_url_env":{"type":"string","default":"DATABASE_URL"},
            "chapters_table":{"type":"string","default":"ssot_brochure.chapters"},
            "out_dir":{"type":"string"},
            "build_dir":{"type":"string"},
            "template":{"type":"string"},
            "lua_filter":{"type":"string"},
            "repo_root":{"type":"string"},
            "pdf_name":{"type":"string","default":"main.pdf"},
            "limit":{"type":"integer"},
            "book_mode":{"type":"boolean","default":true}
         }}},
        {"name":"get_claim_status","description":"Search chapters for claim-status markers (Verified, Empirical fit, Open conjecture, High-risk, Falsified, Retracted, Unverified)",
         "inputSchema":{"type":"object","properties":{"query":{"type":"string","description":"Search term for slug/title/body"}},"required":["query"]}},
        {"name":"list_claims","description":"Scan all chapters for claim-status vocabulary and return per-chapter summary",
         "inputSchema":{"type":"object","properties":{}}},
        {"name":"get_honest_counters","description":"Return the corrected, audited snapshot of trinity-s3ai formal proof counters and claim statuses",
         "inputSchema":{"type":"object","properties":{}}},
        {"name":"build_book","description":"Extended PDF pipeline with book-mode enabled (TOC, part dividers, front matter). Defaults to dry_run=true.",
         "inputSchema":{"type":"object","properties":{
            "dry_run":{"type":"boolean","default":true},
            "database_url_env":{"type":"string","default":"DATABASE_URL"},
            "chapters_table":{"type":"string","default":"ssot_brochure.chapters"},
            "out_dir":{"type":"string"},
            "build_dir":{"type":"string"},
            "template":{"type":"string"},
            "lua_filter":{"type":"string"},
            "repo_root":{"type":"string"},
            "pdf_name":{"type":"string","default":"book.pdf"},
            "limit":{"type":"integer"}
         }}},
        {"name":"preview_chapter_update","description":"DRY-RUN only. Show the SQL diff and word-count change for a proposed chapter body update without executing any write.",
         "inputSchema":{"type":"object","properties":{
            "slug":{"type":"string"},
            "new_body_md":{"type":"string"}
         },"required":["slug","new_body_md"]}},
        {"name":"backup_ssot","description":"Create a timestamped backup of the chapters table. Requires confirm=true to execute; returns dry-run SQL otherwise.",
         "inputSchema":{"type":"object","properties":{
            "confirm":{"type":"boolean","default":false},
            "chapters_table":{"type":"string","default":"ssot_brochure.chapters"}
         }}}
    ])
}

fn dispatch(
    method: &str,
    _id: &serde_json::Value,
    params: &serde_json::Value,
) -> serde_json::Value {
    match method {
        "initialize" => {
            json!({"protocolVersion":"2024-11-05","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"trios-mcp-rag","version":env!("CARGO_PKG_VERSION")}})
        }
        "notifications/initialized" => json!(null),
        "tools/list" => json!({"tools":tools_def()}),
        "tools/call" => {
            let name = params.get("name").and_then(|v| v.as_str()).unwrap_or("");
            let args = params.get("arguments").cloned().unwrap_or(json!({}));
            let res = match name {
                "search_chapters" => tool_search(
                    args.get("query").and_then(|v| v.as_str()).unwrap_or(""),
                    args.get("limit").and_then(|v| v.as_u64()).unwrap_or(10) as usize,
                ),
                "get_chapter" => tool_get(args.get("slug").and_then(|v| v.as_str()).unwrap_or("")),
                "list_chapters" => tool_list(),
                "forbidden_audit" => tool_audit(),
                "build_cover" => tool_cover(),
                "build_pdf" => tool_build_pdf(&args),
                "get_claim_status" => tool_get_claim_status(&args),
                "list_claims" => tool_list_claims(),
                "get_honest_counters" => tool_get_honest_counters(),
                "build_book" => {
                    let mut book_args = args.clone();
                    book_args["book_mode"] = json!(true);
                    if book_args.get("pdf_name").is_none() {
                        book_args["pdf_name"] = json!("book.pdf");
                    }
                    tool_build_pdf(&book_args)
                }
                "preview_chapter_update" => tool_preview_chapter_update(&args),
                "backup_ssot" => tool_backup_ssot(&args),
                _ => Err(anyhow::anyhow!("Unknown tool: {}", name)),
            };
            res.unwrap_or_else(
                |e| json!({"content":[{"type":"text","text":e.to_string()}],"isError":true}),
            )
        }
        _ => {
            json!({"content":[{"type":"text","text":format!("Unknown method: {}", method)}],"isError":true})
        }
    }
}

fn run_build_pdf_cli(args: Commands) -> anyhow::Result<()> {
    let Commands::BuildPdf {
        dry_run,
        database_url_env,
        chapters_table,
        out_dir,
        build_dir,
        template,
        lua_filter,
        repo_root,
        pdf_name,
        limit,
        book_mode,
    } = args;

    let mut cfg = pipeline::BuildConfig::default();
    cfg.dry_run = dry_run;
    cfg.database_url_env = database_url_env;
    cfg.chapters_table = chapters_table;
    if let Some(d) = out_dir {
        cfg.out_dir = d;
    }
    if let Some(d) = build_dir {
        cfg.build_dir = d;
    }
    cfg.template = template;
    cfg.lua_filter = lua_filter;
    if let Some(d) = repo_root {
        cfg.repo_root = d;
    }
    cfg.pdf_name = pdf_name;
    cfg.limit = limit;
    cfg.book_mode = book_mode;

    if cfg.template.is_none() {
        cfg.template = Some(cfg.repo_root.join("templates").join("chapter.template.tex"));
    }
    if cfg.lua_filter.is_none() {
        cfg.lua_filter = Some(cfg.repo_root.join("filters").join("force-fullwidth-hero.lua"));
    }
    let report = if cfg.dry_run {
        pipeline::check(&cfg)?
    } else {
        pipeline::build(&cfg, &pipeline::load_from_postgres)?
    };
    println!("{}", serde_json::to_string_pretty(&report)?);
    Ok(())
}

fn run_mcp_server() -> anyhow::Result<()> {
    eprintln!(
        "trios-mcp-rag v{} — stdio JSON-RPC MCP server",
        env!("CARGO_PKG_VERSION")
    );
    let stdin = io::stdin();
    let mut stdout = io::stdout();
    let mut locked = stdin.lock();
    loop {
        let mut line = String::new();
        let n = locked.read_line(&mut line)?;
        if n == 0 {
            break;
        }
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let req: serde_json::Value = match serde_json::from_str(line) {
            Ok(v) => v,
            Err(e) => {
                eprintln!("parse error: {}", e);
                continue;
            }
        };
        let method = req.get("method").and_then(|v| v.as_str()).unwrap_or("");
        let id = req.get("id").cloned().unwrap_or(json!(null));
        if id.is_null() && method.starts_with("notifications/") {
            continue;
        }
        let params = req.get("params").cloned().unwrap_or(json!({}));
        let result = dispatch(method, &id, &params);
        let resp = json!({"jsonrpc":"2.0","id":id,"result":result});
        writeln!(stdout, "{}", serde_json::to_string(&resp)?)?;
        stdout.flush()?;
    }
    Ok(())
}

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt().with_writer(io::stderr).init();
    let cli = Cli::parse();
    match cli.command {
        Some(args @ Commands::BuildPdf { .. }) => run_build_pdf_cli(args),
        None => run_mcp_server(),
    }
}
