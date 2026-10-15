# Psychopatz Asset Harness — Progress Ledger

> **New UI/asset follow-up (2026-10-15; source-observed):** Main HEAD `0a86b2e` now includes `tools/asset_harness/simulator_cli.py`, `simulator_gui.py` and a 10-device offline simulator. They are **implemented**, but the current simulated hardware lacks a universal visible Back and event-driven rotary/PTT/LED parts, and game Lua still uses three-button v1 mappings. The new [Radio OS Interaction v2 plan](../radio_os/CORE_RADIO_OS_INTERACTION_V2.md), [art spec](../radio_os/CORE_RADIO_OS_DEVICE_ART_SPEC_V2.md) and [I0–I9 ledger](../radio_os/CORE_RADIO_OS_INTERACTION_PROGRESS.md) own this follow-up. Historic H checkpoints below are kept as evidence and must not be restarted as blank tasks. No art produced by this docs update.


**Updated:** 2026-10-15. **Status:** H0–H6 and H8 offline pipeline complete with synthetic fixtures. H7 is blocked on authentic art/native acceptance; H9 is optional and pending capability review. No production artwork was replaced or approved.

## Immediate next task: commit/push the verified offline phases

Read `ASSET_HARNESS_AGENT_RUNBOOK.md`, `ASSET_HARNESS_CONTRACT.md`, `ASSET_HARNESS_ROADMAP.md`; re-audit current HEAD across Core (and consumers only for compatibility). Inspect *actual code*, not just README:

- `tools/profiler/profiler_cli.py`, `profiler_core.py`, `bridge/client.py`, `bridge/transport.py`, tests and `docs/profiler.md`
- `tools/radio_os/`, `tests/radio_os/`, Core Radio OS manifests and actual `common/media/ui/psychopatz/radio` PNGs
- `docs/preview-framework.md`, `Preview/PC_PreviewSnapshot.lua`, `docs/bridge-capabilities.md`
- `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md`

The H0 audit and implementation checkpoints are recorded below. Runtime promotion remains gated on source approval and native acceptance.

## Verified baseline from the planning review

- Core main HEAD at planning: `834220758bc7b588de629fd8131855102f823997`; refresh HEAD on every agent run.
- Existing Python profiler CLI returns bounded JSON, has tests and supports `bridge status|ping|capabilities`.
- Existing optional local external bridge has validated explicit capabilities and separate opt-in configuration; this does **not** establish an asset-harness-specific live capability.
- Existing radio Python atlas builders and alpha/compositor smokes exist; active manifest still uses v1 six-walkie atlas, not individual device v2.
- Core's reusable game images are under `Contents/mods/PsychopatzCore/common/media/ui/`; six legacy radio atlases remain active.
- Original 11 generated concept PNG binaries have **not been verified as Git-tracked**, and concept art should not be treated as approved/faithful game-device art.
- Python Flask UI, standalone asset CLI, image-region command suite and production export are **proposed only**.
- Native PZ GUI, HAM/manpack correctness and profiler verification are **pending**. PZ Headless Harness prohibited.

## H phase status

| Phase | Source | Unit | Image | CLI | Export | Native |
|---|---|---|---|---|---|---|
| H0 | **NEXT** | pending | pending | pending | N/A | N/A |
| H1–H3 | not started | pending | pending | pending | N/A | N/A |
| H4–H5 | not started | pending | pending | pending | N/A | N/A |
| H6 | not started | pending | pending | pending | pending | pending |
| H7 | not started | pending | pending | pending | pending | pending |
| H8 | not started | pending | pending | pending | pending | pending |
| H9 | not started | pending | pending | pending | pending | pending |

## Agent update format (append per checkpoint)

```text
Date / HEAD:
Phase completed / next:
Ownership and changed files:
Reused code vs new modules:
Commands actually run and test results:
JSON preview / PNG artifact paths + SHA-256:
Source/master provenance and approval state:
Native SP / Native MP / profiler: verified or pending:
Git commit SHA / push state:
Blockers / exact next action:
```

No implementation success claims in this documentation-only commit. Do not regenerate, overwrite or mark approved radio skins without real input art and verification.

## H0 audit / H1–H3 implementation checkpoint

Current phase matrix:

| Phase | Status | Evidence |
|---|---|---|
| H0 | complete | source audit, coverage check, architecture scan, baseline tests |
| H1 | complete | CLI discovery, JSON envelopes, project persistence, stable errors |
| H2 | complete | PNG inspection, alpha components, manual regions, lossless slices |
| H3 | complete | anchored Pillow compositor, LCD sandwich, debug render, deterministic PNGs |
| H4–H5 | complete | animation, diff, variants, bounded batch, and validation gates |
| H6 | complete | approved staged/apply/verify export gate on synthetic fixtures |
| H7 | blocked | authentic art and native SP/MP acceptance remain external gates |
| H8 | complete | synthetic family/workflow coverage for walkie, HAM, and manpack |
| H9 | pending | optional bridge/native capability review |

Date / HEAD: 2026-10-15 / `d2705f88baabf80d145f37277e0e3cbab906ad50` (pre-harness working tree)

Phase completed / next: H0 source audit plus H1–H3 offline vertical slice / H4 animation, cosmetic variants, batch persistence, and H6 export verification.

Ownership and changed files: new `tools/asset_harness/` package and tests only at this checkpoint; existing profiler, bridge, radio Lua, atlases, and untracked radio PNGs were not modified. The tracked architecture report was refreshed by the required audit tool and is not a runtime dependency.

Reused code vs new modules: profiler CLI patterns (argparse, bounded JSON, read-only errors), profiler core separation (platform-neutral data and file IO), bridge bounded-payload/path discipline, radio Pillow source/alpha checks, and existing radio compositor geometry were audited as reference patterns. The new harness has no Tk, psutil, bridge, PZ runtime, browser, Flask, or headless-harness dependency.

Commands actually run and test results:

- `python3 -m unittest discover -s tools/profiler/tests -q` — 52 passed.
- `python3 tests/radio_os/psychopatz_radio_os_compositor_smoke.py` — PASS; six legacy shells, four resolutions.
- `python3 tests/refactor_binding_smoke.py` — PASS; no changed Lua files.
- `lua tests/radio_os/psychopatz_radio_os_action_smoke.lua` — PASS.
- `lua tests/radio_os/psychopatz_radio_os_registry_smoke.lua` — PASS.
- `lua tests/radio_os/psychopatz_radio_os_window_smoke.lua` — PASS.
- `lua tests/radio_os/psychopatz_radio_manifest_smoke.lua` — pre-existing failure: default `DTA_Walkie_Manifest.lua` path is absent; the current manifest is `PsychopatzRadioManifest.lua`.
- `PYTHONPATH=tools python3 -m unittest discover -s tools/asset_harness/tests -q` — 8 passed.
- `python3 tools/asset_harness/cli.py doctor --format json` — bounded JSON, Pillow 10.2.0, GUI-free.

Verified reuse/new-work matrix: `tools/profiler/profiler_cli.py` already provides bounded read-only snapshot commands but its error envelope is profiler-specific; `profiler_core.py` owns process/snapshot/report logic and must not be imported into image operations; `bridge/client.py` and `bridge/transport.py` provide bounded 16-slot optional IPC but are deferred to H9; `PC_PreviewSnapshot.lua` accepts primitive frozen observations and does not produce PNG screenshots; `PsychopatzRadioManifest.lua` remains a v1 six-walkie 256x432 atlas with three fixed controls; `PsychopatzRadioOSWindow_Renderer.lua` already owns matte -> content -> stencil -> shell -> controls ordering; `tools/radio_os/` remains compatibility/reference code rather than a replacement target.

Asset/provenance audit: 51 PNG files were found. The tracked legacy shared atlases and 341px compact source remain usable fallback/reference inputs. Ten untracked 1254x1254 files under `common/media/ui/Radio/{Ham,ManPack,WalkieTalkie}` were inspected as unsliced, unapproved concept/reference sheets with no embedded provenance metadata; they are not wired to the renderer or used as export approval. The committed catalog records original concept sheets as `UNREVIEWED`, and no authentic approved individual high-resolution production source was verified. H7 art/native acceptance therefore remains blocked honestly while synthetic tooling work continues.

Implemented CLI/schema surface: `doctor`, `assets list`, `project init|inspect`, `source inspect|register`, `regions detect|set|slice`, `layers set|remove`, `render`, `animation set|render`, `diff`, `validate`, `export plan|apply|verify`, and bounded whitelisted `batch`. Project JSON is schema version 1 with registered source SHA-256/provenance/approval, proposed vs verified regions, device-local layers/anchors/z/clip/state/variant, LCD aperture/backing/content, variable controls, animations, and export destinations. Responses are schema-versioned JSON envelopes with stable diagnostic codes, bounded output, artifact paths, hashes, dimensions, and nonzero failures.

Generated artifacts: synthetic test PNGs are temporary and not committed; no runtime export was applied. Source inspection and render outputs are reproducible from the test suite. Production `common/media/ui` remains unchanged by the harness.

Source/master provenance and approval state: synthetic fixtures are explicitly `synthetic fixture`; the legacy shell atlas is fallback art; concept sheets are unapproved. No claim of vanilla fidelity or native PZ rendering is made.

Native SP / Native MP / profiler: native SP pending; native MP pending; profiler integration not used and pending H9 capability review. The PZ Headless Harness was not used.

Git commit SHA / push state: implementation changes are uncommitted at this checkpoint; no push has been attempted until H4–H6 verification is complete. Existing untracked radio PNGs are preserved untouched.

Blockers / exact next action: authentic approved US Army/high-resolution device art and normal-game acceptance remain external gates. Next implement stronger variant/animation/LCD hitbox checks, batch coverage, and export approval/round-trip tests; then run the complete regression set and commit/push the safe tooling phases.

## H4–H6 / H8 implementation checkpoint

Date / HEAD: 2026-10-15 / `d2705f88baabf80d145f37277e0e3cbab906ad50` (pre-commit working tree)

Phase completed / next: H4 animation, variants, diff, bounded batch, and H5 validation hardening are complete for the offline pipeline. H6 staged/apply/verify export is complete for approved synthetic fixtures. H8 family/workflow coverage is complete with synthetic HAM and manpack projects. H7 remains blocked on authentic approved art and native SP/MP acceptance; H9 remains an optional bridge/native capability review.

Ownership and changed files: added `tools/asset_harness/` CLI, core modules, tests, and README; updated this progress ledger. Existing runtime Lua, legacy atlases, profiler/bridge code, architecture report, and pre-existing untracked radio concept PNGs were not changed or staged.

Implementation evidence: source import preserves original PNG bytes; controls support visual rectangles plus separate hitboxes; validation covers source hashes, alpha-hole LCD geometry, layer ordering/bounds, control overlap, animations, variants, and export safety; diff compares RGB and alpha; export refuses unapproved sources, requires `--approved`, refuses overwrite conflicts, writes atomically, and verifies PNG hashes plus manifest references. Batch accepts only bounded whitelisted argv arrays and performs no shell execution.

Commands actually run and test results:

- `python3 -m unittest discover -s tools/asset_harness/tests -q` — 12 passed.
- `python3 -m py_compile tools/asset_harness/cli.py tools/asset_harness/core/*.py tools/asset_harness/tests/*.py` — PASS.
- `python3 -m unittest discover -s tests -q` from `tools/profiler` — 52 passed.
- `python3 tests/radio_os/psychopatz_radio_os_compositor_smoke.py` — PASS; six shells and four resolutions.
- `python3 tests/refactor_binding_smoke.py` — PASS.
- Lua action, registry, and window smokes — PASS; the window smoke's intentional compositor error remains contained.
- Lua manifest smoke — pre-existing failure because it expects absent `DTA_Walkie_Manifest.lua`; current manifest is `PsychopatzRadioManifest.lua`.
- Direct CLI flow — project init, source import, region detection/manual region, layer/LCD/control setup, render, validate, animation/contact sheet, diff, batch, and export plan/apply/verify all exercised by tests and synthetic demo.

JSON/PNG evidence: ephemeral legacy-atlas demo render `/tmp/tmp.OFHqIgJsOl/legacy_demo.png`, SHA-256 `309737f8ca5fa083cc05b88414d9b1eb8144f1fb03b9c11692706a862803c954`, 256×432 RGBA. Synthetic fixtures and runtime export outputs are temporary; no production `common/media/ui` asset was written.

Source/master provenance and approval state: legacy atlas input is fallback/reference art; synthetic fixtures are explicitly synthetic; the ten untracked 1254×1254 Ham/ManPack/WalkieTalkie concept sheets remain untouched and unapproved. No vanilla fidelity or native PZ acceptance claim is made.

Native SP / Native MP / profiler: native SP pending; native MP pending; profiler regression suite passes, but the asset harness has no profiler/bridge runtime dependency. PZ Headless Harness was not used.

Git commit SHA / push state: implementation commit `f87bf62` (`feat(asset-harness): add offline agent-first image pipeline`) was pushed to `origin/main` as a clean fast-forward from `d2705f8`. This docs-only follow-up records the final state. Pre-existing untracked PNGs remain untracked.

Blockers / exact next action: review staged file list, commit the offline harness and ledger, fetch/check the owning branch, and push only if the update is a fast-forward. After push, append the resulting commit SHA and push status here in a docs-only checkpoint.

## Post-push verification checkpoint

Date / HEAD: 2026-10-15 / implementation commit `f87bf62` pushed; this ledger checkpoint records the final state.

Final state: the offline agent-first pipeline is available under `tools/asset_harness/` with no runtime art replacement. H7 remains an explicit external gate for authentic approved art and native SP/MP acceptance; H9 remains optional bridge/native capability review.

Exact next action: no further implementation is required for the offline goal. If approved high-resolution source art becomes available, register it with provenance, review it, validate it, and perform a separately reviewed runtime export; do not approve the existing concept sheets.

## Optional GUI launcher checkpoint

Date / HEAD: 2026-10-15 / `ffe92e3` pushed to `origin/main`.

Added `run.sh` at the repository root plus `tools/asset_harness/run.sh` and an optional `tools/asset_harness/gui.py` Tk/Pillow client. The client opens the tracked legacy walkie shell atlas by default, can open PNGs or project JSONs, render and validate projects through the existing core functions, and save a preview only after an explicit file choice. The CLI remains headless and authoritative.

Verification: `python3 -m py_compile tools/asset_harness/gui.py`, both launcher `--help` commands, and a real `timeout 3s ./run.sh --image .../DTA_Walkie_Shells.png` startup smoke passed; the timeout exit `124` confirms the GUI event loop stayed open. `ImageTk` is not required; the viewer uses Tk's native PNG loader from Pillow-generated bytes.

The viewer is only a visual client. It does not approve art, perform runtime export automatically, or establish native Project Zomboid SP/MP acceptance. Existing untracked Ham/ManPack/WalkieTalkie concept PNGs remain untouched and unapproved.

Git commit SHA / push state: `ffe92e3` (`feat(asset-harness): add optional preview GUI launcher`) was pushed as a clean fast-forward from `fa48fc1`. This ledger correction is the only remaining docs change.
