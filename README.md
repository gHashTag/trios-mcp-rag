# trios-mcp-rag

**MCP server** (Model Context Protocol) providing RAG (Retrieval-Augmented Generation) access to the **GOLDEN BRIDGE** chapter database hosted on Railway PostgreSQL.

Exposes 5 tools that let AI agents (Claude Code, Cursor, Windsurf, opencode, etc.) search, read, and audit 80+ chapters of the Trinity S³AI compendium.

## Tools

| Tool | Description |
|------|-------------|
| `search_chapters` | Full-text search across all chapters (`ILIKE` on title + body) |
| `get_chapter` | Fetch full chapter content by slug |
| `list_chapters` | List all chapter slugs with metadata (kind, order, word count) |
| `forbidden_audit` | Scan all chapters for policy violations / prohibited terms |
| `build_cover` | Generate LaTeX titlepage for the compendium |

## Prerequisites

- **Rust** 1.75+ (`rustup`)
- **PostgreSQL** with the `ssot_brochure.chapters` table populated

## Install

### Option A: Build from source

```bash
git clone https://github.com/gHashTag/trios-mcp-rag.git
cd trios-mcp-rag
cargo build --release
```

The binary will be at `target/release/trios-mcp-rag`.

### Option B: Install with cargo

```bash
cargo install --git https://github.com/gHashTag/trios-mcp-rag.git
```

## Configuration

### Environment variable

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |

Example:
```bash
export DATABASE_URL="postgresql://user:password@host:5432/dbname"
```

### Database schema

The server expects a `ssot_brochure.chapters` table with columns:

```sql
CREATE TABLE ssot_brochure.chapters (
    slug        TEXT PRIMARY KEY,
    kind        TEXT NOT NULL,
    order_key   INT NOT NULL,
    title       TEXT NOT NULL,
    body_md     TEXT NOT NULL,
    word_count  INT NOT NULL DEFAULT 0
);
```

## Connection guides

### Claude Code (claude.ai/code)

Add to your `.claude/settings.json`:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "trios-mcp-rag",
      "args": [],
      "env": {
        "DATABASE_URL": "postgresql://user:password@host:5432/dbname"
      }
    }
  }
}
```

Or use the absolute path to the binary:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "/path/to/trios-mcp-rag",
      "args": [],
      "env": {
        "DATABASE_URL": "postgresql://user:password@host:5432/dbname"
      }
    }
  }
}
```

### Claude Desktop

Add to `claude_desktop_config.json`:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "/path/to/trios-mcp-rag",
      "args": [],
      "env": {
        "DATABASE_URL": "postgresql://user:password@host:5432/dbname"
      }
    }
  }
}
```

### Cursor IDE

1. Open **Settings → MCP**
2. Click **Add new MCP server**
3. Configure:

| Field | Value |
|-------|-------|
| Name | `trios-rag` |
| Type | `stdio` |
| Command | `/path/to/trios-mcp-rag` |
| Env | `DATABASE_URL=postgresql://user:password@host:5432/dbname` |

Or add to `.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "trios-mcp-rag",
      "env": {
        "DATABASE_URL": "postgresql://user:password@host:5432/dbname"
      }
    }
  }
}
```

### Windsurf

Add to `~/.windsurf/settings/mcp.json`:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "trios-mcp-rag",
      "env": {
        "DATABASE_URL": "postgresql://user:password@host:5432/dbname"
      }
    }
  }
}
```

### opencode

Add to `.opencode/opencode.json` or `opencode.json` in your project root:

```json
{
  "mcp": {
    "trios-rag": {
      "type": "stdio",
      "cmd": "trios-mcp-rag",
      "env": {
        "DATABASE_URL": "postgresql://user:password@host:5432/dbname"
      }
    }
  }
}
```

### Any MCP client (generic)

This server uses the **stdio** transport (JSON-RPC 2.0 over stdin/stdout). It is compatible with any client that supports the MCP protocol specification `2024-11-05`.

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | DATABASE_URL=... trios-mcp-rag
```

### Docker

```bash
docker build -t trios-mcp-rag .

# Run as MCP server
docker run -i --rm \
  -e DATABASE_URL="postgresql://user:password@host:5432/dbname" \
  trios-mcp-rag
```

Then point your MCP client at the Docker command:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "DATABASE_URL=postgresql://user:password@host:5432/dbname", "trios-mcp-rag"]
    }
  }
}
```

## Usage examples

Once connected, your AI agent can use the tools:

```
User: Search for chapters about golden ratio in physics
Agent: [calls search_chapters(query="golden ratio physics")]
→ Returns matching chapters with snippets

User: What chapters exist?
Agent: [calls list_chapters()]
→ Returns all 80+ chapters with metadata

User: Get the full text of chapter "ch-01-introduction"
Agent: [calls get_chapter(slug="ch-01-introduction")]
→ Returns full chapter content in Markdown

User: Check for policy violations
Agent: [calls forbidden_audit()]
→ Returns "CLEAN" or lists violations
```

## Architecture

```
AI Agent (Claude/Cursor/opencode)
    │
    │  stdio (JSON-RPC 2.0)
    ▼
trios-mcp-rag
    │
    │  tokio-postgres
    ▼
PostgreSQL (ssot_brochure.chapters)
    │
    ├── 80+ chapters
    ├── Full-text search (ILIKE)
    └── Policy audit (forbidden terms)
```

The server speaks MCP protocol over stdio — each line is a JSON-RPC request, each response is a single JSON line. This is the standard transport for MCP servers.

## Railway deployment

If you host your PostgreSQL on Railway:

1. Create a PostgreSQL service in your Railway project
2. Note the connection string from the **Variables** tab
3. Set `DATABASE_URL` to the internal connection string (uses `DATABASE_URL` auto-provisioned variable)

For the chapter data, run the ingest pipeline from the main [trios](https://github.com/gHashTag/trios) repo:

```bash
cargo run -p trios-phd -- ingest-rag-chunks
```

## License

MIT OR Apache-2.0

## Links

- Main repo: [github.com/gHashTag/trios](https://github.com/gHashTag/trios)
- DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
- MCP specification: [modelcontextprotocol.io](https://modelcontextprotocol.io)
