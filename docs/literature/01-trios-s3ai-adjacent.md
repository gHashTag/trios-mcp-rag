## Track 1 — TRIOS / S³AI / GOLDEN BRIDGE and Adjacent Literature

### References

No peer-reviewed publication was found on arXiv, ACL Anthology, NeurIPS
Proceedings, EMNLP, SIGIR, VLDB, OpenReview, or Google Scholar that uses
the exact terms **"TRIOS"**, **"S³AI"** (self-supervised symbolic AI /
S-cubed AI), or **"GOLDEN BRIDGE"** as an AI/ML framework name authored by
`gHashTag` or any co-authors. The live PhD SSOT dashboard at
[trios-production.up.railway.app](https://trios-production.up.railway.app)
confirms the project is a practitioner compendium (88 chapters as of
2026-05-06) rather than a conference-submitted paper.

The closest adjacent literature — covering neuro-symbolic AI,
self-supervised reasoning, knowledge-grounded LLMs, and AI compendium /
textbook generation — is listed below.

1. **Wan et al. (2024) — "Towards Cognitive AI Systems: a Survey and
   Prospective on Neuro-Symbolic AI"**
   [arXiv:2401.01040](https://arxiv.org/abs/2401.01040).
   Comprehensive survey of neural + symbolic + probabilistic fusion; frames
   the motivations that the TRIOS compendium shares.

2. **Platzer (2024) — "Intersymbolic AI: Interlinking Symbolic AI and
   Subsymbolic AI"**
   [arXiv:2406.11563](https://arxiv.org/abs/2406.11563) / IJCAI 2024.
   Defines a principled taxonomy for systems that move between symbolic
   meaning and neural effect — directly relevant to "S³AI" framing.

3. **Renkhoff et al. (2024) — "A Survey on Verification and Validation,
   Testing and Evaluations of Neurosymbolic AI"**
   [arXiv:2401.03188](https://arxiv.org/abs/2401.03188), IEEE Trans. AI.
   Reviews how symbolic components can be used to *test and validate* neural
   predictions — the V&V layer that TRIOS's claim-status framing aspires to.

4. **Wang et al. (2025) — "Imperative Learning: A Self-supervised
   Neuro-Symbolic Learning Framework for Robot Autonomy"**
   [arXiv:2406.16087](https://arxiv.org/abs/2406.16087).
   Introduces a bilevel optimisation framing: neural module, symbolic
   reasoning engine, memory system — a structural parallel to TRIOS's
   Postgres SSOT + Rust renderer + LLM agent triad.

5. **Liu et al. (2025) — "SymAgent: A Neural-Symbolic Self-Learning Agent
   Framework for Complex Reasoning over Knowledge Graphs"**
   [arXiv:2502.03283](https://arxiv.org/abs/2502.03283).
   Demonstrates self-learning from KG-structured memory — a pattern
   applicable to the compendium's chapter-as-node retrieval model.

6. **Disi-UNIBO NeSy Survey (IJCAI 2025) — "Neuro-Symbolic Artificial
   Intelligence: A Task-Directed Survey"**
   [IJCAI 2025 Proceedings](https://www.ijcai.org/proceedings/2025/1157.pdf).
   Provides a task-oriented NeSy taxonomy and a public reproducibility
   index for each surveyed work — a model for TRIOS's own validation
   commitments.

7. **Honda & Hagiwara (2025) — "Context-dependent neuro-symbolic AI through
   self-supervised learning with large language models"**
   [doi:10.1016/j.neucom.2025.131269](https://linkinghub.elsevier.com/retrieve/pii/S0925231225019411),
   Neurocomputing. Explores SSL for neuro-symbolic context binding.

8. **Wan et al. (2024) — Workload Characterization of Neuro-Symbolic AI**
   [ISPASS 2024](https://zishenwan.github.io/publication/ISPASS24_NSAI.pdf).
   Profiles hardware bottlenecks; underscores why a Rust-native pipeline
   (rather than Python) matters for scalable symbolic document rendering.

### Synthesis

No published paper exists under the TRIOS / S³AI / GOLDEN BRIDGE name.
The project is best understood as a **practitioner knowledge compendium** —
analogous in ambition to an AI textbook generation system — whose closest
academic neighbours are neuro-symbolic AI (NeSy) surveys, knowledge-grounded
LLM pipelines, and self-learning agent frameworks over structured memory.

The NeSy literature consistently distinguishes three capability layers that
map onto the repo's own architecture: (1) a neural perception / generation
layer (the LLM and retrieval agents), (2) a symbolic reasoning / storage
layer (Postgres SSOT, chapter schema), and (3) a memory or indexing layer
(the MCP server exposing structured context). Critically, the V&V literature
(Renkhoff et al.) shows that *symbolic components are the primary mechanism
for testing neural outputs*, which grounds the repo's claim-status framing:
rather than treating LLM outputs as self-validating, the system routes every
empirical assertion through an explicit epistemic label with a declared
falsification path.

The absence of peer-reviewed publications under the TRIOS brand is itself a
data point that should be encoded in the rule files: until external
peer-review or reproduction exists, all TRIOS-specific algorithmic claims
must carry **Open conjecture** status at minimum. Prize and Nobel mentions
(referenced in `04-claim-status.md`) are particularly dangerous precisely
because no validated publication yet exists to support them.

### Recommendations

1. **Add to `04-claim-status.md`** a "publication anchor" field to each
   claim record: if no arXiv / ACL / NeurIPS / IJCAI DOI is attached, the
   maximum allowed status is **Open conjecture** regardless of narrative
   framing. Agents must refuse to upgrade status without a resolvable DOI or
   institutional preprint URL.

2. **Add to `trios-phd-canon.md`** a "NeSy positioning note": state
   explicitly that TRIOS S³AI is a practitioner NeSy compendium and link to
   the Wan et al. (2024) [arXiv:2401.01040](https://arxiv.org/abs/2401.01040)
   survey as the canonical adjacent-literature anchor. This lets agents
   answer "what is S³AI?" with grounded adjacent citations rather than
   fabricated ones.

3. **Amend `04-claim-status.md`**: add a rule that no claim may be labelled
   **Verified** unless it cites an external replication or systematic review.
   Internal consistency checks (pipeline runs, QA checklists) upgrade a
   claim to **Empirical fit** at most.

4. **Add to `00-canonical-pipeline.md`**: a "literature provenance" block in
   the chapter front-matter schema (a `refs:` YAML array in the Postgres
   row). Agents generating new chapters must populate at least one adjacent
   external citation from a recognised venue (arXiv, ACL, NeurIPS, VLDB,
   IJCAI) before the chapter can reach **Empirical fit** status.

5. **Add to `trios-phd-canon.md`**: a standing instruction that if a search
   for "TRIOS", "S³AI", or "GOLDEN BRIDGE" across arXiv / Semantic Scholar
   returns zero results, the agent must state this plainly and pivot to
   adjacent NeSy / knowledge-grounded LLM literature — never fabricate a
   match.

---

