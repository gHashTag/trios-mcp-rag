# 04 — Scientific Claim-Status Discipline

The compendium mixes mathematics, physics, philosophy, and applied AI.
Readers and reviewers will (rightly) push back on undifferentiated
claims. Agents must label every non-trivial empirical or theoretical
statement with one of the following statuses.

## The five statuses

1. **Verified**
   - Reproduced under independently checkable conditions (peer-reviewed
     publication, independently re-run experiment, formal proof
     machine-checked or carefully reviewed).
   - Use this status sparingly. "I ran it once on my laptop" is not
     Verified.

2. **Empirical fit**
   - The model / formula matches observed data within stated error
     bars, but causation, mechanism, or generalisation has not been
     established.
   - Always include the dataset, the metric, and the residual /
     uncertainty. "Fits well" without numbers is not Empirical fit.

3. **Open conjecture**
   - A precise, falsifiable statement that the authors believe is
     true but have not proved or empirically established.
   - Must include the conditions under which it would be considered
     falsified.

4. **High-risk / falsified**
   - Either: a claim known to contradict accepted evidence; or a
     prediction that, if it fails, sinks a substantial part of the
     surrounding framework.
   - Surface this status explicitly rather than burying it.

5. **Retracted / unverified**
   - Previously stated as stronger than warranted, now downgraded.
   - Keep the retraction visible; do not silently delete the original
     claim.

## What agents must do

- When adding a claim to any chapter, brochure, README, or PDF caption,
  attach a status. If the status is unclear, default to **Open
  conjecture** and ask the user.
- When summarising chapters for a reader (search results, abstracts,
  excerpts), preserve the status. Do not flatten "Open conjecture into
  "result" or "discovery".
- When you find existing material that lacks a status, propose adding
  one in a flagged PR comment; do not silently relabel.

## No prize claims as deliverables

The compendium is **not** to be presented as a Nobel-prize / Fields-
medal / Turing-award candidate, nor are individual claims to be
described as prize-worthy in agent-generated text.

The only acceptable framing is **as an external long-term validation
standard**:

> "If the open conjectures in chapters X and Y were independently
> verified and reproduced over a multi-decade timescale, that level of
> external validation is what historically tracks with major
> recognition. The work has not been so validated."

That is a statement about the bar for recognition, not a forecast of
recognition. Anything stronger is hype.

## Language to avoid in agent output

- "breakthrough", "revolutionary", "paradigm-shifting", "world-first"
- "proves", "settles", "definitively shows" (unless Verified and you
  can cite the proof)
- "Nobel-worthy", "prize-winning", "deserves the Fields medal"
- "this changes everything"

These are marketing words. The compendium's audience is technical;
marketing words actively reduce credibility.

## Language to prefer

- "Verified: …"
- "Empirical fit (n=…, residual …): …"
- "Open conjecture, falsifiable by …: …"
- "High-risk prediction: …"
- "Previously claimed as X; now downgraded to Y because …"
