# Psychopatz Asset Harness — Codex /goal

This is the **pasteable agent-first harness goal** for `psychopatz/psychopatzCore`. It supersedes suggestions to build Flask/UI first, but does not delete prior radio asset A0–A8 plans.

```text
/goal

Build the Psychopatz Asset Harness, a reusable OFFLINE, AGENT-FIRST Python CLI/JSON + lossless PNG inspection/render/export tool in psychopatzCore. Its primary user is Luna/Codex/other LLM agents with terminal execution and ability to inspect images, NOT a human drag-and-drop GUI. The first end-to-end use case is assembling production-quality modular Radio OS assets for walkie, HAM and manpack families; it must remain reusable for other PsychopatzCore mod graphics.

Read in order:
1. Docs/asset_harness/ASSET_HARNESS_AGENT_RUNBOOK.md
2. Docs/asset_harness/ASSET_HARNESS_CONTRACT.md
3. Docs/asset_harness/ASSET_HARNESS_ROADMAP.md
4. Docs/asset_harness/ASSET_HARNESS_PROGRESS.md
5. Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md
6. docs/profiler.md and tools/profiler/README.md
7. docs/preview-framework.md and docs/bridge-capabilities.md

Inspect real code and recheck current Git HEAD before editing. Existing profiler_cli.py, profiler_core.py, profiler/bridge, preview snapshots and tools/radio_os generators/tests are your reuse/reference foundation. The profiler CLI already supports LLM-friendly bounded JSON, and the bridge is opt-in: do not rewrite or regress them. Do NOT confuse this asset harness with the broken PZ Headless Harness; absolutely do NOT use/install/repair/investigate PZ Headless Harness.

Implement H0–H9 in the stated order. Begin H0 with a fresh source/code audit, actual tests, source/asset inventory and reusable-interface plan, then implement H1 CLI and JSON response envelopes, H2 non-destructive sprite inspect/detect/manually-set regions, H3 deterministic layer assembler + RGBA preview, H4 LCD masks/physical control hitboxes/animated LED and wear states, H5 resumable projects/batched safe operations/visual diff reports, H6 staged validated Core common/media/ui PNG and versioned Lua skin exports preserving legacy manifest compatibility, H7 authentic US Army walkie pilot, H8 rest of walkies plus verified HAM and manpack, H9 optional explicit-read-only bridge diagnostics and normal-game acceptance.

NO Flask, website, Qt, Tk, browser automation, desktop interaction, running Project Zomboid, GPU or network dependency for the core harness. HTTP/Flask visual editor is strictly optional after agent CLI succeeds, and must reuse same library. Implement as tools/asset_harness/cli.py plus a separately testable Python core (Pillow for images) and offline fixtures. Give machine-readable help, structured stable JSON and error codes, bounded token-aware reports, artifact file paths, exact slice rectangles/masks, pixel/draw-layer diagnostics, idempotent commands and deterministic PNG images; stdout is one JSON result, stderr logs, exit codes meaningful.

A Codex agent should independently run: source inspect -> alpha sprite detect -> exact manual region set -> compose shell and opaque LCD backing -> align buttons/LEDs -> render full-resolution preview/contact sheets at several scales/states -> inspect images -> correct coordinates -> validate alpha coverage/quality -> export plan -> approved safe apply -> verify paths and hashes. Support named LED-off/green/red/amber animations and condition variants without baking dynamic NPC portraits/text/trade screens into art. Preserve independent per-model source detail; never upscale the legacy 341x341 six-radio master as a fake high-res replacement. An image proposal is not an approved vanilla-faithful asset.

All game-loadable art must export only to Contents/mods/PsychopatzCore/common/media/ui/psychopatz/radio/devices/<family>/<model>/ and virtual references media/ui/psychopatz/radio/...; other future Core UI types may use their established common/media/ui subfolder. Intermediate generated images, source projects and test artifacts must be outside runtime media. Never overwrite existing approved or unrelated assets without explicit approved-export opt-in. Use safe paths, hashes, atomic staging, input-size limits, no arbitrary Python/Lua code execution or unsafe pickle. Preserve Hoomans and DynamicTrading business/provider integrations and all six legacy radio atlas fallbacks.

The original 11 concept-sheet binaries have not been verified as committed. Check available sources/provenance; do not assume a supplied generated design faithfully matches the real PZ item icon/model. If approved genuine high-detail art is absent, complete all safe CLI, test and fixture work, report the precise art blocker and request one consolidated visual approval at the actual production-substitution boundary rather than repeatedly asking for permission.

Run Python unit/smoke and relevant existing Core radio Lua tests in each coherent chunk. Log command examples, JSON results, PNG paths/hashes, failure reasons, old-vs-new compatibility, and separate native SP/MP/profiler evidence. User or agent must run normal Project Zomboid for native acceptance, never PZ Headless Harness. A Pillow preview does not prove game rendering.

Operate unattended within safe, scoped coding tasks. Incrementally commit and safely fast-forward push validated changes in the owning psychopatzCore repository. Maintain Docs/asset_harness/ASSET_HARNESS_PROGRESS.md with exact H# state, tests, changed files, commit SHAs, blockers and next action. Preserve unrelated work, game saves, installed mods and user Git edits; no destructive resets/force pushes. Continue independent work when art or native game availability is blocked.

START H0 NOW; proceed automatically through the safe implementation phases rather than asking for routine approvals. Never claim the harness or images are production-ready without the required evidence.
```
