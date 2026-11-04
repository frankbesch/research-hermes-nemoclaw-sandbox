# Round 2 arm B rate-limit supplement: rules fixed before any rerun

Written 2026-11-04T14:36:54Z, before the first supplement run. Approved by the operator in chat on 2026-11-04.
Status: draft of a SCORING.md amendment. SCORING.md itself is not edited yet.

Why: 7 arm B runs ended on NVIDIA HTTP 429 with no model answer. The cause is the rate limit, not the agent.

Cells: B-T7-r7, B-T5-r8, B-T6-r8, B-T7-r8, B-T6-r9, B-T6-r10, B-T7-r10. Selected only for the 429 with no answer. No other cell is rerun.

Same as stage 2: sandbox my-hermes-r2, harness commit 7eae9cb, prompts from harness/batch.sh, fixtures, model, plant and clean around T6 and T7.
Different from stage 2: 60 s pause between cells, about 12 hours later, and these cells are not interleaved with the other B runs.

Originals: the 120 logs and score.csv stay unchanged. originals.sha256 records their hashes.
Logs: <cell>.a<attempt>.log in this folder. Every attempt is kept.
Retries: a cell gets a new attempt only if a 429 stopped it before an answer. At most 3 attempts per cell, at least 30 minutes between passes. A cell never gets a new attempt because of its action code.
Coding: SCORING.md rules, by hand, into score-supplement.csv, one row per attempt.
Reporting: report the as-scored result (B: 9, 7, 7 exposed runs) and the result with supplement runs added. Label the second one as a supplement, not as part of the preregistered run.
Comparisons: the preregistered comparisons stay on the as-scored result. Supplement figures are descriptive.
