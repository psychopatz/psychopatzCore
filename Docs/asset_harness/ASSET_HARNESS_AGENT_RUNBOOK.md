# Asset Harness — Unattended Codex/Luna Runbook

> **2026-10-16 updated scope:** For the live next task, read [RADIO_VISUAL_HARNESS_RECOVERY.md](RADIO_VISUAL_HARNESS_RECOVERY.md) FIRST, then [RADIO_MODULAR_ASSET_PRODUCTION.md](RADIO_MODULAR_ASSET_PRODUCTION.md). Its AH-R0–AH-R6 phase plan and canonical `Contents/mods/PsychopatzCore/common/media/ui/Radio/` paths take priority over the historical scaffold-start instructions below. This goal may improve the **existing offline Asset Harness and its tests only**, with per-device reviewed art; it must not change gameplay/runtime Lua, active PNGs, or execute `export apply`. Do not restart completed H0–H6/H8 milestones. Historical text below is retained as earlier workflow evidence.

## Required reading

**For the active radio goal, read first:** `Docs/asset_harness/RADIO_VISUAL_HARNESS_RECOVERY.md` (simulator/visual loop/PNG publication). Then read `Docs/asset_harness/RADIO_MODULAR_ASSET_PRODUCTION.md` for fidelity, all ten models and scope.
1. `Docs/asset_harness/ASSET_HARNESS_CONTRACT.md` — machine interface, security, persistence, compositor, export requirements.
2. `Docs/asset_harness/ASSET_HARNESS_ROADMAP.md` — H0–H9 order/gates.
3. `Docs/asset_harness/ASSET_HARNESS_PROGRESS.md` — next chunk and verified vs pending.
4. `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md` — art/vanilla mapping/family ownership.
5. `docs/profiler.md`, `tools/profiler/README.md` and `tools/profiler/profiler_cli.py` — existing LLM CLI and optional bridge reference.
6. `docs/preview-framework.md`, `tools/radio_os/` and `tests/radio_os/` — actual snapshot and asset pipeline.
7. Recheck actual repo HEAD/worktree and test suites before edits.

## ACTIVE radio execution — unified visual harness, then real PZ PNGs

**Read FIRST:** [RADIO_VISUAL_HARNESS_RECOVERY.md](RADIO_VISUAL_HARNESS_RECOVERY.md) (VH1–VH4). Then [RADIO_MODULAR_ASSET_PRODUCTION.md](RADIO_MODULAR_ASSET_PRODUCTION.md) for per-device image fidelity and final canonical filesystem. Prior "W5 one-control first" wording is **fulfilled historical work**: commits `c272542` and `5523220` already created candidate W5 imagery and review PNGs.

**New first deliverable:** Fix the actual `./run.sh` Tk simulator so it loads and previews the existing W5 modular project and its separate pristine/worn chassis; project LCD and hitboxes must land on the actual hardware. Bind pointer-down/up/move, wheel and PTT so physical states are visible. The CLI and GUI must show **the same** actual composition and source-to-idle image, not the static catalog source while the agent audits JSON. Capture/view an actual GUI screenshot or matched CLI PNG; correct pixels/hitboxes iteratively.

**Publication after visual correction:** Promote **new** reviewed/inspectable modular PNGs and portable paths to `Contents/mods/PsychopatzCore/common/media/ui/Radio/{WalkieTalkie,Ham,ManPack}/<model>/`, commit those real PNG files and do not overwrite existing flat sources. Scratch masks and intermediate previews may remain gitignored; the **actual component/chassis PNGs required to reproduce** the authored model may not live *only* in ignored workspace. `proposed` still means not artist-approved and **not** activated in-game.

**Quota rule:** no audit-only, repeated hash-only, placeholder JSON, unrelated profiler test, or one-off device script milestone. Gate work by visible simulator behavior and pixel output. Focused regression checks as support; keep automatic safety tests. After W5, continue all other nine individual radios. Runtime Lua modifications and in-game acceptance remain a separate goal.

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
