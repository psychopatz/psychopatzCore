# Asset Harness — Unattended Codex/Luna Runbook

> **2026-10-16 scoped radio-asset production:** For modular radio art, first read [RADIO_MODULAR_ASSET_PRODUCTION.md](RADIO_MODULAR_ASSET_PRODUCTION.md). Its AH-R0–AH-R6 phase plan and canonical `Contents/mods/PsychopatzCore/common/media/ui/Radio/` paths take priority over the historical scaffold-start instructions below. This goal may improve the **existing offline Asset Harness and its tests only**, with per-device reviewed art; it must not change gameplay/runtime Lua, active PNGs, or execute `export apply`. Do not restart completed H0–H6/H8 milestones. Historical text below is retained as earlier workflow evidence.

## Required reading

**For this radio-only goal, read first:** `Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md` — source paths, modular chassis/controls, authoring QA and AH-R0–AH-R6 plan.
1. `Docs/asset_harness/ASSET_HARNESS_CONTRACT.md` — machine interface, security, persistence, compositor, export requirements.
2. `Docs/asset_harness/ASSET_HARNESS_ROADMAP.md` — H0–H9 order/gates.
3. `Docs/asset_harness/ASSET_HARNESS_PROGRESS.md` — next chunk and verified vs pending.
4. `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md` — art/vanilla mapping/family ownership.
5. `docs/profiler.md`, `tools/profiler/README.md` and `tools/profiler/profiler_cli.py` — existing LLM CLI and optional bridge reference.
6. `docs/preview-framework.md`, `tools/radio_os/` and `tests/radio_os/` — actual snapshot and asset pipeline.
7. Recheck actual repo HEAD/worktree and test suites before edits.

## Active radio priority — author an actual visual pilot

**Current stage (2026-10-16, after e8ad4d9):** The mask, modular, simulator and LCD contract tooling already exists. Treat audit inventories, immutable SHA evidence, `blocked=10`, placeholder `after: null` reports and copied-source contact sheets as **completed diagnostic groundwork**, not current deliverables. The canonical [radio production contract](RADIO_MODULAR_ASSET_PRODUCTION.md#current-execution-correction--visual-art-first-2026-10-16-audit-of-commits-through-e8ad4d9) gives the precise next chunk.

**Execute the W5 visual vertical slice first:** Inspect the real W5 image, pick one actual easy-to-identify control, author and view its silhouette mask, face, reconstructed socket, idle/pressed states, and rendered idle comparison. Iterate against actual visual preview at native and UI scale; a successful unit test or input SHA does **not** substitute for opening and judging the edited image. Save curated image review output in `tools/asset_harness/review/radio/walkie_5/` for visible GitHub verification, in addition to scratch artifacts.

If the image editing/viewing tool genuinely cannot accomplish one region, provide the precise attempted asset/mask and one localized blocker, not a new global "all sources flattened" gate. Keep W5 status proposed/blocked until actual art review; **do not** mark accepted based on synthetic fixtures. Complete independent W5 `Chassis/Pristine.png` and `Chassis/Worn.png` after the real component path works.

**State-machine/tests correction:** Update stale `blocked == 10` and null-diff expectations to assert blocked when no art exists but allow proposed/verified when real image files, accurate masks, sockets, state transitions and human/agent visual review evidence exist. Remove unconditional source-format/provenance blocker branches; replace with conditional, evidence-backed diagnostics. Do not disable safety gates. Retain SHA checking as an inexpensive immutability assertion, not a repeated deliverable or endless audit task.

**Test cadence:** Focused harness image/mask/render/CLI tests while authoring; broader suites at true integration checkpoints. No unrelated profiler test suite on every edit. No production export, game Lua modification, original texture overwrite, or old DTA fallback build. Report image paths, actual opened-view findings and pixel-diff changes before test counts or hashes.

## Unattended execution

- **Historical generic harness scaffold instructions, not the current radio modular scope:** Start H0 with read-only audit, identify existing implementation before writing new functions, establish baseline tests and CLI user stories. Then proceed H1 onwards in **small deterministic testable chunks**, without stopping for routine approval after a passing chunk.
- Place new developer package at `tools/asset_harness/`, **outside** game-loaded `media/lua`. Retain `tools/radio_os` as a compatibility wrapper or move only when tests and downstream command references are updated.
- Use Python standard library for CLI, JSON, hashes, temporary paths, safety and IO; Pillow for image operations. Reuse concepts/functions where stable, but do not import Tk GUI or pull profiler process-monitoring dependencies into every image operation. No web server as runtime requirement.
- First build the complete vertical slice with genuine/synthetic **test fixtures**: inspect -> select/edit exact regions -> compose -> render -> JSON validate. Add animation & variant states, then export. Fixtures do not count as authentic vanilla artwork.
- Preserve and report missing image binaries and missing reliable item icon/3D art references; no guessing/clone-colors substituted for a real game's device.
- Preserve current game Lua and existing source image bytes during this harness-only goal; **do not rebuild or require the missing DTA atlases**. The old references are runtime-cutover debt, not another fallback texture system. Keep unaffected harness CLI APIs and simulator contracts stable.
- Each meaningful authoring chunk: inspect and refine its real image output, run scoped harness/CLI/alpha tests, and record before/after visuals. Run broad or unrelated regression suites only at appropriate integration milestones; do not run removed-DTA compositor smokes as an art acceptance gate. Commit/push verified scoped progress without force.
- Use image previews to self-correct with CLI commands. Never require the agent to click browser UI, interact with a native Python GUI or access a GPU/display for ordinary tasks.
- Failure handling: emit structured `error.code`/diagnostics with exact source paths, image rectangles and remedial action. Stop a **dangerous specific export**, not unrelated safe phases. Never silently relax integrity checks.
- Permission boundary: routine files/tests/dev artifacts are preauthorized under scoped ownership; editing unrelated user's files, replacing approved production sprites without sign-off, modifying live game saves, or taking privileged/network actions is not. Provide one consolidated user action checklist for any genuine missing input/approval.
- **No PZ Headless Harness** — do not install, repair, configure, inspect or use it. If a normal game isn't operable by agent, mark native SP/MP pending and provide a manual check; do not claim native pass from offline simulations.
- At end of each chunk: summarize H stage, changed files, tests/measurements, artifacts and next step in the ledger; don't overwrite its historical entries. Include relevant git SHA and exact source provenance.

## Optional integration with existing bridge

Profiler bridge client is safe to reuse **only after H0 capability audit and when the game is running under explicit local opt-in**. It is not required for H0–H8. Its request namespaces/allowlists and existing owner-security model must be respected. For first live integration expose at most bounded *read-only* UI geometry/registered texture state/snapshot capabilities, not arbitrary screenshot, Lua evaluation, file writes or merchant actions. Do not add an always-on game listener or 250ms polling for an offline tool.

## Completion evidence categories

`source` (audit) | `unit` (Python/Lua) | `image` (pixel/PNG) | `CLI` (actual subprocess JSON) | `export` (verified staged/apply) | `native_SP` | `native_MP` | `profiler`. A record may say `pending`. Never collapse categories into a generic "passed".
