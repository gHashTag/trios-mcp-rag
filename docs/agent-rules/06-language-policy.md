# 06 — Language Policy

## Current preference

- **Public repository artefacts**: English only.
  This includes `README.md`, `AGENTS.md`, `CLAUDE.md`, files under
  `docs/`, code comments, commit messages, PR titles and descriptions,
  release notes, the generated brochure / article / PDF intended for
  public distribution, and any text rendered into shipped artefacts.

- **Maintainer chat**: may be Russian.
  Conversational chat between the agent and the maintainer can be in
  Russian when the maintainer initiates in Russian. This does not
  change what is written to the repository.

## Why the split

Public artefacts have a broader audience than chat. A future
collaborator, reviewer, or RAG ingestion run cannot be assumed to read
Russian. Chat is a private channel where Russian is faster and more
natural for the maintainer.

## Operational rules for agents

1. **Default to English when writing files** in this repo. This
   includes generated Markdown that becomes a public PDF.
2. **Do not auto-translate the maintainer's Russian chat into the
   repo.** If the maintainer says (in Russian) "add a note about X",
   add the note in English unless they explicitly ask for Russian.
3. **If the maintainer pastes Russian text intended for the public
   PDF**, ask whether to translate or to keep bilingual. Do not assume.
4. **If a file in the repo currently mixes English and Russian**,
   treat it as drift (unless it is an intentionally bilingual
   document). Flag it; do not silently normalise either direction
   without confirmation.
5. **The brochure QA language scan** (rule 05 §5) enforces this rule
   for generated PDFs.

## Override

The maintainer can override this for a specific artefact ("make this
brochure bilingual", "the Russian-language version goes under
`docs/ru/`"). Such overrides are per-artefact and do not change the
default.
