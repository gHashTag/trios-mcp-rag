# Rule 08 — MCP Server Registration (Claude Code & peers)

This rule prevents the most common failure mode reported by sibling
agents: "the MCP server is added but my session sees no tools."
Root cause is almost always **scope** or **path**, not the server
itself.

## 08.1 Use `-s user` (global) scope by default

`claude mcp add` defaults to **local scope** — the entry is bound to
the *current project directory* (`~/.claude/projects/<dir-hash>/...`)
and is **invisible** to any agent session whose cwd is anywhere else.

✅ **Always pass `-s user`** when registering `trios-mcp-rag` (and any
peer MCP server in this family). User-scope entries are written to
the user-level config and are visible in *all* projects / sessions —
this matches the contract documented in `README.md` and
`AGENT_WAKEUP.md`.

```bash
claude mcp add trios-mcp-rag -s user -- \
  sh -c 'cd /ABS/PATH/trios-mcp-rag && set -a && . ./.env && exec ./target/release/trios-mcp-rag'
```

Local scope is acceptable **only** when the user explicitly asks for a
project-isolated registration (e.g. testing two builds side-by-side).
Document the choice in the PR description.

## 08.2 Use absolute paths inside the wrapper

A user-scope entry is executed from an **arbitrary cwd** — whichever
directory the user happened to launch Claude Code from. Therefore:

- ❌ `sh -c 'set -a && . ./.env && exec ./target/release/trios-mcp-rag'`
  — fails outside the build folder because `./.env` and
  `./target/...` resolve relative to cwd.
- ✅ `sh -c 'cd /ABS/PATH/trios-mcp-rag && set -a && . ./.env && exec ./target/release/trios-mcp-rag'`
  — the leading `cd` pins the working directory; `.env` and the
  binary resolve deterministically.

The wrapper still keeps the DSN out of Claude Code's config file
(Rule 04 — read-only DSN handling) because the env is sourced at
server-start, not stored.

## 08.3 Never pipe `claude mcp add`

`claude mcp add` prompts for a confirmation; piping (`echo ... |
claude mcp add ...` or running inside a non-interactive heredoc that
closes stdin) **silently swallows the prompt and skips the write**.
The command appears to succeed and `claude mcp list` shows nothing.

✅ Run `claude mcp add` directly in an interactive shell, or use the
explicit non-interactive flag if/when upstream adds one. Do not
suggest piped variants in any documentation, README, or AGENTS file.

## 08.4 Verify before declaring success

After every `add`, the agent must verify:

```bash
claude mcp list                    # entry present, status ✓ Connected
claude mcp get trios-mcp-rag       # Scope: User; Status: ✓ Connected
```

If either check fails, follow the reset procedure (08.5) — do not
issue a second `add` on top of a broken entry.

## 08.5 Reset / clean-up procedure

```bash
claude mcp remove trios-mcp-rag                 # user-scope entry
claude mcp remove trios-mcp-rag --scope local   # any project-local leftover
claude mcp list                                  # confirm clean state
# then re-run the user-scope add command above.
```

Remove **both scopes** before re-registering — a stale local-scope
entry can shadow the correct user-scope one inside its owning
directory.

## 08.6 Restart the host session after registration

MCP servers are launched at **session start**. Agents that called
`add` in the middle of a running Claude Code session will not see the
new tools until the session is restarted. Tell the user explicitly:
*"restart your Claude Code session, then run `claude mcp get
trios-mcp-rag` — Status should be ✓ Connected and the 13 tools
(`search_chapters`, `get_chapter`, `build_pdf`, …) should appear."*

## 08.7 What sibling agents must report on failure

If after following 08.1–08.6 the server is still not visible, the
reporting agent must paste:

1. Output of `claude mcp list`
2. Output of `claude mcp get trios-mcp-rag`
3. The exact `claude mcp add` command used (with DSN/paths
   redacted — env-var names only, per Rule 04)
4. Host + version (`claude --version`)

This is the minimum diagnostic for another agent / the maintainer to
help. Vague "it doesn't work" reports are out of scope.

## 08.8 Same rules apply to `trios-mcp` (wrapper)

The companion `gHashTag/trios-mcp` repository hosts a CLI-wrapper MCP
server (`trios` / `igla` binaries). All of 08.1–08.7 apply verbatim;
substitute the server name and the wrapper script accordingly. The
peer repository's `AGENT_WAKEUP.md` carries the matching `-s user`
command.
