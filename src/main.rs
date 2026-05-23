use serde_json::{json, Value};
use std::env;
use std::io::{self, BufRead, Write};
use std::path::PathBuf;

mod pipeline;

fn dsn() -> String {
    env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://postgres:postgres@localhost:5432/railway".into())
}

fn query_rows(sql: &str, params: &[&(dyn tokio_postgres::types::ToSql + Sync)]) -> anyhow::Result<Vec<tokio_postgres::Row>> {
    let dsn = dsn();
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(async {
        let (client, conn) = tokio_postgres::connect(&dsn, tokio_postgres::NoTls).await?;
        tokio::spawn(async move { let _ = conn.await; });
        let rows = client.query(sql, params).await?;
        Ok(rows)
    })
}

fn rs(r: &tokio_postgres::Row, col: &str) -> String { r.get::<_, String>(col) }
fn ri(r: &tokio_postgres::Row, col: &str) -> i32 { r.get::<_, i32>(col) }

fn tool_search(query: &str, limit: usize) -> anyhow::Result<Value> {
    let pattern = format!("%{}%", query.replace('%', "\\%"));
    let rows = query_rows(
        "SELECT slug, kind, title, LEFT(body_md, 500) AS snippet \
         FROM ssot_brochure.chapters \
         WHERE body_md ILIKE $1 OR title ILIKE $1 \
         ORDER BY order_key LIMIT $2",
        &[&pattern as &(dyn tokio_postgres::types::ToSql + Sync), &(limit as i64) as &(dyn tokio_postgres::types::ToSql + Sync)],
    )?;
    let out: Vec<Value> = rows.iter().map(|r| json!({
        "slug": rs(r,"slug"), "kind": rs(r,"kind"), "title": rs(r,"title"), "snippet": rs(r,"snippet")
    })).collect();
    Ok(json!({"content":[{"type":"text","text":serde_json::to_string_pretty(&out)?}],"isError":false}))
}

fn tool_get(slug: &str) -> anyhow::Result<Value> {
    let rows = query_rows(
        "SELECT slug, kind, order_key, title, body_md, word_count FROM ssot_brochure.chapters WHERE slug=$1",
        &[&slug],
    )?;
    if rows.is_empty() {
        return Ok(json!({"content":[{"type":"text","text":format!("Chapter '{}' not found",slug)}],"isError":true}));
    }
    let r = &rows[0];
    Ok(json!({"content":[{"type":"text","text":serde_json::to_string_pretty(&json!({
        "slug":rs(r,"slug"),"kind":rs(r,"kind"),"order_key":ri(r,"order_key"),
        "title":rs(r,"title"),"word_count":ri(r,"word_count"),"body_md":rs(r,"body_md")
    }))?}],"isError":false}))
}

fn tool_list() -> anyhow::Result<Value> {
    let rows = query_rows(
        "SELECT slug, kind, order_key, title, word_count FROM ssot_brochure.chapters ORDER BY order_key",
        &[],
    )?;
    let out: Vec<Value> = rows.iter().map(|r| json!({
        "slug":rs(r,"slug"),"kind":rs(r,"kind"),"order_key":ri(r,"order_key"),
        "title":rs(r,"title"),"words":ri(r,"word_count")
    })).collect();
    Ok(json!({"content":[{"type":"text","text":serde_json::to_string_pretty(&out)?}],"isError":false}))
}

fn tool_audit() -> anyhow::Result<Value> {
    let forbidden = ["63 tok/s/W","tok/s/W","compete with nvidia","vasilev-pellis constants","claude","rollback"];
    let rows = query_rows("SELECT slug, body_md FROM ssot_brochure.chapters", &[])?;
    let mut hits = Vec::new();
    for r in &rows {
        let s = rs(r,"slug"); let b = rs(r,"body_md").to_lowercase();
        for t in &forbidden { if b.contains(t) { hits.push(json!({"slug":s,"term":t})); } }
    }
    let msg = if hits.is_empty() { "CLEAN".into() } else { format!("{} violations: {}", hits.len(), serde_json::to_string(&hits)?) };
    Ok(json!({"content":[{"type":"text","text":msg}],"isError":false}))
}

/// MCP `list_rag_rules` tool.
///
/// Returns the durable RAG anchors that any agent driving this server
/// must respect before rendering, editing the SSOT-derived artefacts,
/// or shipping a PDF. The anchors are grep-friendly all-caps tokens
/// that resolve into specific docs under `docs/rag/` and
/// `docs/agent-rules/`. Future agents that grep for these tokens
/// should land on the linked files.
///
/// This tool is read-only and contains no secret values.
fn tool_list_rag_rules() -> anyhow::Result<Value> {
    let rules = json!([
        {
            "anchor": "TRIOS_PHD_CANONICAL_PIPELINE",
            "summary": "Rust trios-phd / TRIOS MCP -> Railway/Postgres SSOT (ssot_brochure.chapters or ssot.chapters) -> Markdown -> pandoc (chapter.template.tex, force-fullwidth-hero.lua) -> LaTeX -> tectonic -> PDF. The only supported renderer chain.",
            "see": ["docs/rag/CANONICAL_PIPELINE.md", "docs/agent-rules/00-canonical-pipeline.md", "README.md"]
        },
        {
            "anchor": "TRIOS_PHD_RENDERER_FIRST",
            "summary": "Never edit the rendered PDF. Fix in the SSOT image manifest, then Markdown, then Lua filter, then LaTeX template, then src/pipeline.rs. A PDF patched by hand will be silently regenerated next build.",
            "see": ["docs/rag/CANONICAL_PIPELINE.md", "docs/rag/IMAGE_PLACEMENT.md"]
        },
        {
            "anchor": "TRIOS_PHD_STYLE_LOCK",
            "summary": "Locked visual identity: serif typography, engraved black-and-white S3AI hero panels, standard book margins, large images. No corporate / teal / black covers except for the GOLDEN BRIDGE cover canon. No image trains; soft keep-together, never hard \\clearpage per section.",
            "see": ["docs/rag/CANONICAL_PIPELINE.md", "docs/agent-rules/02-pdf-style.md", "docs/rag/trios-phd-canon.md"]
        },
        {
            "anchor": "TRIOS_PHD_NO_GENERIC_PDF",
            "summary": "No ReportLab / WeasyPrint / wkhtmltopdf / browser-print / online Markdown-to-PDF substitute, even temporarily. Missing pandoc or tectonic is a blocker, not a fallback trigger.",
            "see": ["docs/rag/CANONICAL_PIPELINE.md", "docs/agent-rules/00-canonical-pipeline.md"]
        },
        {
            "anchor": "TRIOS_PHD_SECRET_SAFETY",
            "summary": "Never log, print, commit, or embed DSNs, Railway tokens, passwords, or any Railway-environment value. Reference by env-var name only. See .env.example for the safe placeholder template.",
            "see": ["docs/rag/CANONICAL_PIPELINE.md", "docs/agent-rules/03-safety-railway-postgres.md", ".env.example"]
        },
        {
            "anchor": "TRIOS_PHD_CLAIM_STATUS",
            "summary": "Every empirical / theoretical statement carries one of: Verified, Empirical fit, Open conjecture, High-risk, Retracted. Default Open conjecture if unclear. No prize framing as deliverables.",
            "see": ["docs/rag/CANONICAL_PIPELINE.md", "docs/agent-rules/04-claim-status.md"]
        },
        {
            "anchor": "TRIOS_PHD_COVER_CANON",
            "summary": "GOLDEN BRIDGE front cover: GPT Image 2 fully prompted v1, full-bleed A4 (no crop), black background, gold serif title, white Da Vinci-style formulas/diagrams, three chips PHI / EULER / GAMMA, authors Dmitrii Vasilev . Stergios Pellis . Scott Olsen. Do not crop, do not replace with a programmatic / generic LaTeX-only layout.",
            "see": ["docs/rag/COVER_CANON.md"]
        },
        {
            "anchor": "TRIOS_PHD_NO_IMAGE_TRAIN",
            "summary": "Heroes must be semantically anchored to a substantive heading and body text. No two heroes back-to-back without a real prose buffer. Enforce with a soft keep-together rule, not a hard \\clearpage per section.",
            "see": ["docs/rag/trios-phd-canon.md", "docs/agent-rules/02-pdf-style.md"]
        },
        {
            "anchor": "TRIOS_PHD_IMAGE_PLACEMENT",
            "summary": "SSOT image manifest contract: stable image_id, role, canonical_anchor, priority, caption, source, file_hash, allowed_repeat_policy. Deterministic placement rules; no orphan images.",
            "see": ["docs/rag/IMAGE_PLACEMENT.md", "docs/rag/IMAGE_MANIFEST_SCHEMA.md"]
        },
        {
            "anchor": "TRIOS_PHD_IMAGE_DEDUP",
            "summary": "Duplicate image_id is an error. Duplicate file_hash / source / caption is a warning. Adjacent role repetition is an error. Allowed exceptions: title_page_only, watermark, reference_plate.",
            "see": ["docs/rag/IMAGE_PLACEMENT.md", "docs/rag/PDF_QA_CHECKLIST.md"]
        }
    ]);
    let body = json!({
        "rules": rules,
        "verification": "docs/rag/PIPELINE_VERIFICATION.md",
        "env_template": ".env.example",
        "agents_entrypoint": "AGENTS.md"
    });
    Ok(json!({
        "content":[{"type":"text","text":serde_json::to_string_pretty(&body)?}],
        "isError":false
    }))
}

fn tool_cover() -> anyhow::Result<Value> {
    let rows = query_rows("SELECT count(*) AS n, sum(word_count) AS tw FROM ssot_brochure.chapters", &[])?;
    let n: i64 = rows[0].get::<_, i64>("n");
    let tw: i64 = rows[0].get::<_, Option<i64>>("tw").unwrap_or(0);
    let tex = format!(r"\begin{{titlepage}}\centering\vspace*{{2cm}}\n{{\Huge\bfseries GOLDEN BRIDGE}}\\[0.5em]\n{{\Large A Three-Strand Compendium on $\varphi$-Structured Physical Constants and Ternary Silicon}}\\[2em]\n{{\large Dmitrii Vasilev \\ Stergios Pellis \\ Kenneth Olsen}}\\[1em]\n{{\large April 2026 \\ v27}}\\[2em]\n\rule{{\textwidth}}{{0.4pt}}\\[1em]\n{{\\textit{{Railway PostgreSQL SSOT}}}}\\[0.5em]\n{{\\texttt{{{n} chapters, {tw} words}}}}\\[2em]\n\\rule{{\\textwidth}}{{0.4pt}}\\[2em]\n{{\\small $\\varphi^2 + \\varphi^{{-2}} = 3$ (Coq Qed) \\quad 0x47C0 silicon anchor (Theorem 36.1)}}\\[0.5em]\n{{\\small $\\sim$1 GOPS @ $\\sim$50 MHz @ $\\sim$1 W ternary (projected)}}\\[3em]\n\\end{{titlepage}}\n");
    Ok(json!({"content":[{"type":"text","text":tex}],"isError":false}))
}

/// MCP `build_pdf` tool: dispatch the SSOT -> PDF pipeline.
///
/// Arguments mirror the CLI flags; everything is optional. With `dry_run`
/// set (or by default for the MCP tool, since most agents only want to
/// validate), no PDF is produced.
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
        {"name":"list_rag_rules","description":"List the durable RAG anchors (TRIOS_PHD_*) that govern the canonical pipeline, style lock, cover canon, secret safety, and claim-status framing. Read this before rendering, editing chapters, or shipping a PDF.",
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
            "limit":{"type":"integer"}
         }}}
    ])
}

fn dispatch(method: &str, _id: &serde_json::Value, params: &serde_json::Value) -> serde_json::Value {
    match method {
        "initialize" => json!({"protocolVersion":"2024-11-05","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"trios-mcp-rag","version":env!("CARGO_PKG_VERSION")}}),
        "notifications/initialized" => json!(null),
        "tools/list" => json!({"tools":tools_def()}),
        "tools/call" => {
            let name = params.get("name").and_then(|v| v.as_str()).unwrap_or("");
            let args = params.get("arguments").cloned().unwrap_or(json!({}));
            let res = match name {
                "search_chapters" => tool_search(args.get("query").and_then(|v|v.as_str()).unwrap_or(""), args.get("limit").and_then(|v|v.as_u64()).unwrap_or(10) as usize),
                "get_chapter" => tool_get(args.get("slug").and_then(|v|v.as_str()).unwrap_or("")),
                "list_chapters" => tool_list(),
                "forbidden_audit" => tool_audit(),
                "build_cover" => tool_cover(),
                "list_rag_rules" => tool_list_rag_rules(),
                "build_pdf" => tool_build_pdf(&args),
                _ => Err(anyhow::anyhow!("Unknown tool: {}", name)),
            };
            res.unwrap_or_else(|e| json!({"content":[{"type":"text","text":e.to_string()}],"isError":true}))
        }
        _ => json!({"content":[{"type":"text","text":format!("Unknown method: {}", method)}],"isError":true}),
    }
}

fn run_build_pdf_cli(args: &[String]) -> anyhow::Result<()> {
    let cfg = pipeline::parse_cli(args)?;
    let report = if cfg.dry_run {
        pipeline::check(&cfg)?
    } else {
        pipeline::build(&cfg, &pipeline::load_from_postgres)?
    };
    // Print the report to stdout as JSON. Never print the DSN itself.
    println!("{}", serde_json::to_string_pretty(&report)?);
    Ok(())
}

fn run_mcp_server() -> anyhow::Result<()> {
    eprintln!("trios-mcp-rag v{} — stdio JSON-RPC MCP server", env!("CARGO_PKG_VERSION"));
    let stdin = io::stdin();
    let mut stdout = io::stdout();
    let mut locked = stdin.lock();
    loop {
        let mut line = String::new();
        let n = locked.read_line(&mut line)?;
        if n == 0 { break; }
        let line = line.trim();
        if line.is_empty() { continue; }
        let req: serde_json::Value = match serde_json::from_str(line) {
            Ok(v) => v,
            Err(e) => { eprintln!("parse error: {}", e); continue; }
        };
        let method = req.get("method").and_then(|v| v.as_str()).unwrap_or("");
        let id = req.get("id").cloned().unwrap_or(json!(null));
        if id.is_null() && method.starts_with("notifications/") { continue; }
        let params = req.get("params").cloned().unwrap_or(json!({}));
        let result = dispatch(method, &id, &params);
        let resp = json!({"jsonrpc":"2.0","id":id,"result":result});
        writeln!(stdout, "{}", serde_json::to_string(&resp)?)?;
        stdout.flush()?;
    }
    Ok(())
}

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_writer(io::stderr)
        .init();
    let argv: Vec<String> = std::env::args().collect();
    match argv.get(1).map(|s| s.as_str()) {
        Some("build-pdf") => run_build_pdf_cli(&argv[2..]),
        Some("--help") | Some("-h") => {
            eprintln!(
                "trios-mcp-rag v{}\n\n\
                 Default: run as MCP stdio server.\n\n\
                 Subcommands:\n  \
                   build-pdf [--dry-run] [--database-url-env NAME] [--chapters-table T]\n            \
                             [--out-dir D] [--build-dir D] [--template P] [--lua-filter P]\n            \
                             [--repo-root D] [--pdf-name N] [--limit N]\n",
                env!("CARGO_PKG_VERSION")
            );
            Ok(())
        }
        _ => run_mcp_server(),
    }
}
