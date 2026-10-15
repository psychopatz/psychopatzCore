# Codex /goal — Radio Assets: Visual Pilot First (Harness Only)

This short goal is a pointer, not the implementation spec. Read [Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md](Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md), especially **CURRENT EXECUTION CORRECTION — VISUAL ART FIRST**, then the [Agent Runbook](Docs/asset_harness/ASSET_HARNESS_AGENT_RUNBOOK.md) and latest progress ledger.

~~~text
/goal

In psychopatz/psychopatzCore continue the EXISTING Asset Harness radio-modular goal using Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md as the authoritative specification. Read its "CURRENT EXECUTION CORRECTION — VISUAL ART FIRST" section FIRST, then the runbook/progress. Recheck current HEAD/worktree and preserve all existing work; do not restart already-implemented AH-R0/R1/R2/R3/R4 tooling.

The immediate deliverable is a REAL, visually inspected WalkieTalkie5 (US Army) one-control vertical slice, not another blocked status report: view the actual Base.WalkieTalkie5.png, isolate one real control with a precise editable mask, produce its transparent face PNG, author a locally reconstructed empty socket/chassis candidate, make believable Idle and Pressed PNG states, compose and visually inspect native-size/game-size previews, and write an actual source-vs-composite diff with reconstruction-region explanation. Use the current mask/modular/render/simulator CLI as the authoring loop. Store reproducible staging work in tools/asset_harness/ and commit a curated set of inspectable preview PNGs under tools/asset_harness/review/radio/walkie_5/.

Fix the evidence state machine and tests: single-canvas/flattened source and existing-source provenance are NOT unconditional permanent blockers; stale `blocked == 10`, `after: null` and missing-art assertions apply only when image layers truly do not exist. Preserve meaningful pixel/alpha, mask, socket, anchor, artistic-review and immutability gates. SHA-256 is a cheap source-safety check, not an output milestone. No more commits devoted only to per-device blocked JSON, copied sources, hash reports, acceptance checklists or unrelated test reruns.

After the one-control pilot, complete W5 components and separately authored Chassis/Pristine.png and Chassis/Worn.png; then advance individually to the other devices with actual visual feedback and per-model geometry. Preserve original hardware design, art style, labels, colors and silhouettes. If pixel reconstruction is genuinely impossible with available tools, show the actual attempted region/artifact, exact limitation and targeted manual step; do not globally block every radio just because sources are flattened.

STRICT SCOPE: only Asset Harness code, focused tests, developer manifests/docs, staged images and approved NEW modular PNGs in Contents/mods/PsychopatzCore/common/media/ui/Radio/. NEVER overwrite original device PNGs; DO NOT edit runtime Lua, gameplay, live renderers/registries, old DTA image pipelines, other mods or saves; DO NOT run production export apply or PZ Headless Harness. Future live renderer clean cutover is a separate goal.

Work unattended in small visual-production checkpoints; inspect every changed PNG and fix visible defects. Do focused tests after each actual art edit; full suites at integration checkpoints. Commit only scoped verified code and reviewable images; update Docs/asset_harness/ASSET_HARNESS_PROGRESS.md with exact visual outputs and honest proposed/blocked/verified status. The NEXT progress report must include actual new/changed pilot artwork and what was seen on inspection, not only tests/hashes.

Begin the W5 one-control art slice now.
~~~
