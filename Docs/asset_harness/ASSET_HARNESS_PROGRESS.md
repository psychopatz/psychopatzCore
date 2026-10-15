# Psychopatz Asset Harness — Progress Ledger

> **ACTIVE NEXT CHUNK (2026-10-16; corrective audit at e8ad4d9): W5 actual visual authoring.** The harness mask, state, compositor, simulator and LCD tooling has already progressed; no newly authored modular radio control/chassis art is tracked yet. **Stop treating blocked=10, after:null, source hashes, and repeated full test runs as deliverables.** Read [the current execution correction](RADIO_MODULAR_ASSET_PRODUCTION.md#current-execution-correction--visual-art-first-2026-10-16-audit-of-commits-through-e8ad4d9), then produce the exact first W5 control face/mask/socket/idle/pressed images, real composite, visual diff and inspected preview in `tools/asset_harness/review/radio/walkie_5/`. Do not wait for external layered master art before attempting a bounded local reconstruction, but do not claim an unreviewed image accepted. Fix hardcoded blocked QA transitions when actual evidence exists. Runtime Lua and original PNGs remain untouched. Prior entries below are historical evidence, NOT standing instructions to run another blockers-only checkpoint.

> **Scoped planning checkpoint (2026-10-16):** The user requested a harness-first modular radio production goal, separate `Chassis/Pristine.png` and `Chassis/Worn.png` per radio, and canonical image output within `Contents/mods/PsychopatzCore/common/media/ui/Radio/`. The detailed implementation/QA contract is [RADIO_MODULAR_ASSET_PRODUCTION.md](RADIO_MODULAR_ASSET_PRODUCTION.md) with AH-R0–AH-R6 phases. **No actual harness code, modular art, runtime Lua, manifests, legacy skins or in-game assets were changed by this documentation checkpoint.** The completed historical H milestones remain intact. Agent should record current HEAD and re-audit before starting AH-R0, then append execution evidence here.


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

## AH-R0–AH-R6 harness implementation checkpoint

Date / implementation HEAD: 2026-10-16 / `6a4cedf` (`feat(asset-harness): add modular radio audit and simulator`), rebased cleanly onto `origin/main` at `20c1759`. Scope is harness-only: `tools/asset_harness/`, its tests/README, developer radio manifests, and ignored review workspace artifacts. No Lua, gameplay, runtime renderer, legacy atlas, save, or canonical source PNG was edited.

Implemented evidence and contracts:

- AH-R0 canonical inventory covers exactly 10 sources under `Contents/mods/PsychopatzCore/common/media/ui/Radio/{WalkieTalkie,Ham,ManPack}`. The literal `Base.HamRadioMakeShift .png` filename is preserved and reported.
- Source layout is conservative: all 10 current sources are `single_canvas`, so clean/worn halves are blocked rather than cropped. `assets audit` reports `blocked=10`, `proposed=0`, `verified=0`, `complete=0`.
- AH-R1 mask registration is lossless and source-space; previews, extracts, forbidden-neighbor contamination, transparent-source coverage, rectangle rejection, provenance, and visual-review gates are implemented.
- AH-R2/R3 modular projects require independent `Chassis/Pristine.png` and `Chassis/Worn.png`, socket masks, anchors, keyed button/PTT/power/LED states, and bounded rotary detents. Identical keyed state bytes and anchor drift fail validation.
- AH-R4 offline simulator supports the catalog’s full immutable source canvases, semantic Back/Home soft hitboxes, Power, PTT pointer down/up/cancel, rotary wheel updates, LEDs, page stack, project-backed modular state selection, and debug metadata. Unauthored clean/worn aliases are explicitly marked `blocked_source_alias`.
- AH-R5 records `KNOWN_WALKIETALKIE4_BAD_CUT_REGRESSION` and `US_ARMY_PILOT_PENDING_SOCKET_AND_MASK_REVIEW`; no inferred pilot sockets or fake states were generated.
- AH-R6 report/manifests include exact source hashes, full-resolution source copies, full-resolution alpha previews, a labeled contact sheet, and per-device blocked source-to-idle diff records with `sha256: null` until reviewed idle layers exist.

Tracked evidence:

- Audit report: `tools/asset_harness/projects/radio/ah-r0-audit.json`, SHA-256 `f7b9ce99c32ddf9a74cd8431692224db6d474d1f67748355030f4d47b88ecb50`.
- Ignored contact sheet: `tools/asset_harness/workspace/radio/ah-r0/source_contact_sheet.png`, SHA-256 `e3b8efcd84b067d42d5260bc8a4ddffbd85618f53901471270bf141f1e554018`.
- Canonical source SHA-256s: W1 `d583b9b5203fa6d6ededd635cd4a5325f146372306f86c9c57dbfda22d2fc8a2`; W2 `8a1f12c4c4ee019a1187da7ed8d7b5ca2bb3363861b15e7f54d64f544bbf842d`; W3 `fb923a82712b830f7bb559d1853d5da5f8994b6ceb85cce098f0b272454dd6ae`; W4 `5811325ca5fe00d04efb464a79c30bda01147e475757a9c4f8b099b50bf535cb`; W5 `2325d192eaf407bdfff634b1bb58e94b45d3b7e7e8f4da3d67bd0c32e1dc4fda`; walkie makeshift `386b23bc354e6c90f0b0a9cec2db58f62885f24e9e68caadec8b0bf5ab5a6b5e`; Ham1 `13b5e274c368b38b27e2f07906b4126378de3d9196fcc4264292f0ba4a084bc6`; Ham2 `2aa74b80ab9bd0fe79adcac44e682a84d88df10c60e653eaa323b0623b57dad7`; Ham makeshift `9a38cc1de21c44d0247f74b91830c679de1cc40c421de35c66bcdde789f33252`; Manpack `5c97028e2200cf7fdfad9b4f7fb99ebae00b82b9603efcfa4346e264d7d61c46`.

Verification:

- `PYTHONPATH=tools python3 -m unittest discover -s tools/asset_harness/tests -q` — 35 passed.
- `python3 -m py_compile tools/asset_harness/cli.py tools/asset_harness/core/*.py tools/asset_harness/simulator/*.py tools/asset_harness/tests/*.py` — passed.
- `python3 -m unittest discover -s tools/profiler/tests -q` — 52 passed.
- `python3 tests/refactor_binding_smoke.py` — passed; no changed Lua files.
- Lua action, registry, and window smokes — passed; the window test contains its intentional compositor failure.
- `python3 tests/radio_os/psychopatz_radio_os_compositor_smoke.py` — pre-existing/out-of-scope failure: missing `Contents/mods/PsychopatzCore/common/media/ui/psychopatz/radio/shells/DTA_Walkie_Shells.png`.
- Lua manifest smoke — pre-existing/out-of-scope failure: missing `DTA_Walkie_Manifest.lua`; current manifest is `PsychopatzRadioManifest.lua`.
- `doctor`, `assets audit --write-manifests --write-artifacts`, and the W4 event scenario — passed; production `export apply` was not run.

Exact next action / blocker: obtain authentic reviewed modular source art (begin with the US Army WalkieTalkie5 pilot), then author and visually verify both chassis conditions, socket masks, independent controls, and alpha/diff evidence. Keep all 10 devices blocked until those gates pass; do not repair W4 with approximate crops and do not apply a production export.

## AH-R1/R3 QA strengthening checkpoint

Date / HEAD: 2026-10-16 / `6871c2a` (`feat(asset-harness): strengthen radio mask and state QA`), pushed as a clean fast-forward after `9924673`.

- Added bounded `masks polygon` source-canvas authoring with atomic writes, strict integer points, source-canvas bounds checks, proposed-by-default status, and conflict refusal. Actual `Base.WalkieTalkie5.png` mask QA rejects a selected transparent exterior pixel with `MASK_SELECTS_TRANSPARENT_SOURCE`.
- A mask/chassis/component cannot become visually verified from a status string alone. Production validation now requires explicit review evidence (`reviewed`, reviewer identity and/or preview/contact-sheet artifacts), independent chassis review records, component review records, and required semantic-component inventory where declared.
- Added rotary `pointer_down`/`pointer_move`/`pointer_up` capture behavior; rotary release no longer synthesizes an extra button click. LED IDs such as `pwr_led`, `rx_led`, and `tx_led` map to the simulator’s power/RX/TX state.
- Added W4 diagnostic artifacts without modifying the source: `walkie_4_bad_cut_regression.png` SHA-256 `5114b811023129a116e631ba1f5c400ff97c507f3d4c9e0f19d038e7f8dab8ca` and `walkie_4_bad_cut_diff.png` SHA-256 `c33ca61290f36db900ca5558fbc9262c50d5f920fe5cead565739d512d01d69e`. The numeric diff reports 1,078,147 changed pixels, 376,529 alpha-changed pixels, and a full-canvas `[0,0,1024,1536]` changed bound for the half-crop regression.
- Regenerated tracked audit/manifests: [ah-r0-audit.json](../../tools/asset_harness/projects/radio/ah-r0-audit.json), SHA-256 `f75780a339c54685b1a94f5cc4405ac362ac1b75b015e46d9b17fe78f3af82a3`; status remains `expected=10, blocked=10, proposed=0, verified=0, complete=0`.
- Verification after this chunk: `PYTHONPATH=tools python3 -m unittest discover -s tools/asset_harness/tests -q` — 40 passed; `py_compile` for CLI/core/simulator/tests — passed; `git diff --check` — passed. No production `export apply`; no runtime Lua or canonical source PNG changes.

Next action remains an external art-review boundary: provide or approve authentic modular W5 pilot masters before creating `Chassis/Pristine.png`, `Chassis/Worn.png`, socket reconstructions, or keyed component PNGs. Until then, keep W5 and the other nine devices blocked and continue only with non-destructive harness evidence.

## AH-R6 status-matrix checkpoint

Date / HEAD: 2026-10-16 / `4361cc6` (`feat(asset-harness): report per-device radio QA gates`), pushed cleanly after `489426c`.

- The tracked audit and all ten manifests now carry per-device QA requirements rather than a single aggregate status: source inventory, full-resolution source copy, alpha preview, pristine chassis, worn chassis, socket masks, component state sheets, source-to-idle diff, and visual review. W4 additionally tracks its bad-cut regression; W5 additionally tracks its blocked pilot acceptance sheet.
- Modular directories now expose readable-file records with dimensions, alpha summaries, SHA-256 and unreadable-file diagnostics, so future staged art cannot pass merely because filenames exist.
- Current authoritative audit report: [ah-r0-audit.json](../../tools/asset_harness/projects/radio/ah-r0-audit.json), SHA-256 `e6cae60215b7372415bc98f42c7366c2991b3be7aa8b023a108216e4817b0d3c`; summary remains `expected=10, blocked=10, proposed=0, verified=0, complete=0`.
- Verification: 40 harness tests, CLI/core/simulator/test `py_compile`, and `git diff --check` passed. Production `export apply` remains unused; runtime Lua, existing sprites, legacy atlases and saves remain untouched.

The only remaining production-art gate is still authentic, visually reviewed W5 modular artwork. Continue with harness-only evidence until that material approval boundary is supplied; do not mark any device complete from the QA matrix alone.

## W5 pilot evidence checkpoint

Date / HEAD: 2026-10-16 / `538adc8` (`feat(asset-harness): add blocked W5 pilot evidence`), pushed cleanly to `origin/main` after `49b93ba`.

- `assets audit --write-artifacts` now emits `walkie_5_pilot_acceptance.png` and `walkie_5_pilot_acceptance.json` in the ignored review workspace. The sheet shows the immutable W5 source and full-resolution alpha beside the blocked QA matrix; the JSON records `accepted: false`, `modular_artwork_created: false`, and `accepted_for_runtime: false`.
- Pilot evidence is explicitly not acceptance: the sheet/checklist remain `BLOCKED / NOT ACCEPTED`, and the W5 manifest keeps `pilot_acceptance_sheet` blocked with `evidence_status: generated_not_acceptance`. No chassis, socket mask, control state, worn variant, or source-to-idle diff was invented.
- Tracked audit report: [ah-r0-audit.json](../../tools/asset_harness/projects/radio/ah-r0-audit.json), SHA-256 `5d30655bec14f270fe270ec8449dcf1970d3ba5db28910791fae6d00121fca68`; summary remains `expected=10, blocked=10, proposed=0, verified=0, complete=0`.
- Review artifacts: `walkie_5_pilot_acceptance.png` SHA-256 `7d6efe11e5b792b1345f43ab8ae4fd6ded2e8b0b1411ec1fcdde695f1181797a`; `walkie_5_pilot_acceptance.json` SHA-256 `1ae65ee429aef8e0a78a767b49f2f37bc4a775818777ae17f4633ace34547e53`.
- Verification: 40 asset-harness tests, 52 profiler tests, CLI/core/simulator/test `py_compile`, `git diff --check`, refactor-binding smoke, and Lua action/registry/window smokes passed. All ten canonical radio source hashes remain unchanged. No production `export apply`, runtime Lua edit, legacy atlas edit, or canonical source edit occurred.

The production-art blocker remains unchanged: obtain authentic, visually reviewed W5 modular masters before authoring `Chassis/Pristine.png`, `Chassis/Worn.png`, socket masks, and keyed components. Keep all ten devices blocked.

## Manual reconstruction blocker checkpoint

Date / HEAD: 2026-10-16 / `7b29929` (`feat(asset-harness): record manual reconstruction blockers`), pushed cleanly to `origin/main` after `6ed51ca`.

- Every audited device now carries a `manual_reconstruction` record and blocked `manual_reconstruction_plan` QA gate. All ten current sources are `single_canvas` and therefore explicitly require concealed chassis pixels, real empty sockets, independent component states, and full-resolution reconstruction review.
- Each blocker is decomposed into `chassis_reconstruction`, `socket_masks`, `component_state_art`, and `reconstruction_review`; manifests use `FLATTENED_SOURCE_REQUIRES_MANUAL_RECONSTRUCTION` rather than treating filenames or automatic crops as approval evidence.
- Current audit report: [ah-r0-audit.json](../../tools/asset_harness/projects/radio/ah-r0-audit.json), SHA-256 `bdf6f6d5eb62b61a0a52896051fb79f82291046f26efc7b2c76af0ac2212019f`; summary remains `expected=10, blocked=10, proposed=0, verified=0, complete=0`.
- W5 pilot sheet SHA-256 `183fccdc83c3dc64f42a7494d55dcac70e4be7610e60640d34771e2f9c9315bb`; checklist SHA-256 `21b74406130e24b79f9c68ddf7ad514bbd9b30a14899d891e750cd2746140619`. The pilot remains `BLOCKED / NOT ACCEPTED`.
- Verification: 40 asset-harness tests, 52 profiler tests, CLI/core/simulator/test `py_compile`, and `git diff --check` passed. Canonical source hashes remain unchanged; no runtime Lua, legacy atlas, save, or production export changes were made.

Next authorized action remains conditional on an external reviewed modular W5 master: author the real pristine/worn chassis, source-space socket masks, keyed controls, states, and source-to-idle diff, then visually review before any device can leave `blocked`.

## Blocked diff evidence checkpoint

Date / HEAD: 2026-10-16 / `ad937ca` (`feat(asset-harness): add blocked radio diff reports`), pushed cleanly to `origin/main` after `1209dab`.

- `assets audit --write-artifacts` now emits ten per-device `diff/<device>_source_to_idle.json` records. They preserve the copied source SHA-256 and alpha-preview SHA-256 while explicitly setting `status: blocked`, `after: null`, `metrics: null`, and `fake_idle_generated: false` until reviewed modular idle art exists.
- W5 blocked source-to-idle report: `walkie_5_source_to_idle.json`, SHA-256 `55ebb7c1654d3cedd3ad8bb5005c5dbecc34f7843141b1387718d50a3b3bce58`. The tracked audit report is [ah-r0-audit.json](../../tools/asset_harness/projects/radio/ah-r0-audit.json), SHA-256 `405442fcca018d1494ef7142a5c1db0bcde375c1cd09eb46321ef501052058f3`.
- The W5 pilot sheet remains blocked and unchanged at SHA-256 `183fccdc83c3dc64f42a7494d55dcac70e4be7610e60640d34771e2f9c9315bb`; its checklist now records the diff-report hash and remains `accepted: false`.
- Verification: 40 asset-harness tests, 52 profiler tests, CLI/core/simulator/test `py_compile`, `git diff --check`, and refactor-binding smoke passed. No production export, runtime Lua, legacy atlas, save, or canonical source change occurred.

The diff reports improve auditability but do not satisfy the art gate. The next production milestone still requires authentic reviewed modular W5 masters and visual reconstruction acceptance.

## Modular LCD layer contract checkpoint

Date / HEAD: 2026-10-16 / `05ada94` (`feat(asset-harness): add modular LCD layer contract`), pushed cleanly to `origin/main` after `1cebac7`.

- Added `modular lcd set` for independent `glass`, `bezel_overlay`, and optional `matte` layers. The existing modular compositor renders these layers separately, while dynamic LCD content remains outside the physical shell images.
- Modular validation now requires both canvas-aligned LCD shell layers when the semantic `lcd` component is declared, and production status additionally requires explicit LCD visual-review evidence. Missing bezel/glass, unreadable layers, canvas mismatch, and unreviewed production LCD layers fail validation.
- Synthetic modular coverage now exercises production-reviewed LCD compositing, contact-sheet rendering, the required semantic `lcd` mapping, missing-bezel rejection, and CLI registration. The harness suite is `41` passing tests; profiler suite remains `52` passing tests.
- W5 manifest SHA-256 is `46d3811a760864d1b8770c583ce569d05e7dacb92766ac776df941f7a4ee7183`; the authoritative audit report remains SHA-256 `405442fcca018d1494ef7142a5c1db0bcde375c1cd09eb46321ef501052058f3`, with `blocked=10, complete=0`.

This closes a tooling contract gap only; no real LCD art was authored. The W5 pilot still cannot pass until reviewed modular chassis, masks, controls, states, and LCD layers exist.

## Visual-pilot course correction — documentation only

Date: 2026-10-16. Baseline reviewed: `e8ad4d9` (modular LCD contract), before this documentation update.

- Verified Git tree evidence: harness mask/modular/LCD tooling, simulator, and 10 JSON audit manifests exist; no newly authored modular device PNGs have been committed in `common/media/ui/Radio/` or `tools/asset_harness/`.
- Identified stalling behavior: the W5 pilot image only displays original/alpha, ten blocked diff reports intentionally set `after: null`, and frozen tests assert all ten devices remain blocked. Hardcoded source-format/provenance reasons prevent clean advancement. These are legitimate baseline diagnostics, **not visual-art milestones**.
- **Current stage / next work:** start W5 one-control pilot with precise authored mask, extracted face, localized empty socket/chassis candidate, idle/pressed appearance, native/game-scale previews and a real source/composition diff. Commit curated viewable PNGs so GitHub can show tangible progress. Test visual QA and dynamic blocked -> proposed -> verified transitions without auto-approving unchanged/poor art.
- **Authoring input:** existing canonical W5 sprite is the immutable design source; absence of a separately provided layered master is a reason for specific socket painting, not an automatic project-wide stop. W4 historical half-crop diagnostics are not the next output.
- **After pilot:** complete W5 including independent `Chassis/Pristine.png` and `Chassis/Worn.png`, then work one device at a time. Do not maintain old DTA atlas art, rewrite runtime Lua or apply a production export in this goal.
- **Scope of this checkpoint:** this entry and linked contract/runbook/goal text only. No harness Python changes, masks, chassis, control PNGs or test suite runs were performed by the documentation editor. The next agent must produce and examine the actual images.

## W5 Back control visual pilot — proposed artwork checkpoint

Date / base HEAD: 2026-10-16 / `507e46f`.

- Authored the first real W5 vertical slice under `tools/asset_harness/workspace/radio/walkie_5/`: the physical Back button at source bounds `[297,925,98,101]`, a pixel-tight source-space face mask, a localized reconstructed empty socket, an immutable-source face extraction, pristine chassis candidate, and independent idle/pressed states.
- The pressed state is actual authored state art with inward travel (`+3,+4`), reduced face scale (`0.94 x 0.93`), and contact shadow. Native-resolution and game-scale idle/pressed previews were visually inspected.
- Added a real source-to-idle diff and report: `12,185` changed pixels, bounds `[290,920,402,1032]`, `9,532` RGB-changed pixels, `max_rgb_delta=153`, `max_alpha_delta=3`; the report records `fake_idle_generated=false`, `source_mutation=false`, and `production_export_apply=false`.
- Curated review evidence is committed under `tools/asset_harness/review/radio/walkie_5/`, including source crop, mask overlay, socket candidate, idle/pressed composites, game-scale comparison, raw diff, visible alpha heatmap, and six-panel pilot sheet. `pilot_notes.json` records source/mask/socket hashes and the immutable source boundary.
- Dynamic audit state now transitions W5 from baseline `blocked` to honest `proposed`: pristine chassis, socket masks, component states, source-to-idle diff, and pilot review are proposed; worn chassis and remaining controls remain blocked. `modular validate` fails only for the intentionally incomplete worn/LCD/remaining-component gates. Pilot acceptance remains `accepted=false`; no runtime Lua, canonical PNG, legacy atlas, save, or production export changed.
- Verification: focused radio asset-harness unittest module passed; production mask validation passed `9/9`; both idle and pressed modular renders completed; `git diff --check` and Python compilation remain required before commit. Next work is to finish the other W5 controls and independent worn chassis, then perform full visual review before any approval transition.
