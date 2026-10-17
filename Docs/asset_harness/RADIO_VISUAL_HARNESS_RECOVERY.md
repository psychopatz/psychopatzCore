# Radio Visual Harness Recovery — Active Goal Contract

> **Current harness rule (2026-10-16):** GUI, CLI, and direct simulator construction use the same canonical `<device>_pilot.json` registry. The retired Source catalog selector and static radio-device fallback are removed; older radio project JSONs are not accepted by the shared simulator.

**Effective:** 2026-10-16. **Audited baseline:** `669b97a`. **Active priority:** make the existing Asset Harness a working visual authoring/simulator loop **for real Project Zomboid sprite PNGs**. This document overrides earlier "start another W5 extraction" and "collect more blocked JSON" next-step instructions. Keep `RADIO_MODULAR_ASSET_PRODUCTION.md` as the design/fidelity and full ten-device specification.

## 1. Product, not paperwork

**Actual deliverable:** individually edited transparent raster sprites for ten Project Zomboid radio devices, separate `Chassis/Pristine.png` and `Chassis/Worn.png` per model, correct control idle/pressed/knob/PTT/LED/power states, accurately aligned LCD, and a working GUI/CLI Asset Harness showing **those same compositions**. A JSON manifest, SHA inventory, synthetic fixture, test pass, source copy or review contact sheet alone is NOT a deliverable. Metadata exists only to align and load PNGs.

Canonical **mod image** root: `Contents/mods/PsychopatzCore/common/media/ui/Radio/`; families `WalkieTalkie/`, `Ham/`, `ManPack/`, with `RadioMenu/` and existing source PNGs preserved. New modular PNGs belong **under each existing model basename** (for example `WalkieTalkie/Base.WalkieTalkie5/Chassis/Pristine.png`, `Chassis/Worn.png`, `Buttons/Back/Idle.png`, `Buttons/Back/Pressed.png`, `LEDs/PWR/On.png`). These are the **only intended future device sprites**, not an additional DTA device atlas. Runtime Lua will load them in a *separate later cutover*; simply putting files here does not automatically change the current in-game Radio OS.

**Allowed now:** harness Python, GUI, CLI, project metadata/configuration, focused tests, staged preview PNGs, and **new** reviewed/inspectable modular PNG files in the canonical media folder. **Forbidden now:** modifying game/mod runtime Lua, gameplay logic, existing single-canvas source PNGs, game saves, PZ Headless Harness, recreating missing DTA atlases, running production export apply, or falsely claiming in-game acceptance.

## 2. Verified defects to fix — do not rediscover

At `669b97a`, commits `c272542` and `5523220` produced **real candidate W5 artwork**: masks, chassis candidates, control states, review sheets. They are not verified-quality sprite masters yet.

- `tools/asset_harness/workspace/` is .gitignored. Most *individual* W5 layers are here; GitHub has **review PNGs**, not a complete portable artwork set. The W5 project also references local/absolute developer paths. Make an explicit staged-to-canonical copy/publish operation for **new** sprites after visual inspection; commit actual component files; use portable, relative paths. Never silently overwrite original `Base.WalkieTalkie5.png`.
- `simulator_gui.py` opens only catalog-source `RadioSimulator(device_id, variant=...)`. `simulator_cli.py` already accepts `--project`, and `simulator/render.py` already has a project-backed path. GUI must support `--project` and automatic per-device project discovery / Source vs Modular WIP selector. Modular preview must not silently fall back to the static catalog. Make `./run.sh --device walkie_5` a usable modular visual preview when the authored project is available.
- `simulator/catalog.py` scales generic historical hitboxes from 627x1254; the user's screenshots show navigation hitboxes on the **speaker**, and the green LCD overlay over physical buttons. For W5 modular mode use only project-local actual hitboxes/masks, pivot and LCD rects. Correct `walkie_5_pilot.json` top-level `lcd` fields; they are currently empty, which causes fallback to the whole canvas. Avoid double-drawing the LCD/bezel.
- `simulator_gui.py` handles canvas `<Button-1>` as a completed press; the reducer already supports pointer-down/up/move/cancel and wheel. Wire these to the GUI with press-while-held visuals, release, PTT hold, rotary wheel/drag, power and LEDs. Preserve correct coordinate transform through zoom/center/crop; add keyboard/mouse parity where practical.
- The W5 scripts contain hardcoded polygon coordinates, synthetic blurred socket fills, scaled/shadow-shifted pressed states, and a globally desaturated/contrasted worn variant. These are **image proposals**, not established fidelity. Visually inspect at native and game/UI scale and correct art **in the shared harness project**, not via more detached W5-only pipelines.
- The recorded W5 source-to-idle difference is 258,274 changed pixels, with max alpha change 255. Do not declare success just because masks/JSON pass structural tests; investigate actual visual differences, alpha cutouts, wrong controls and misplaced content.

## 3. One shared project, one editable visual loop

The **GUI and headless CLI must share one model, one renderer and one state reducer**, using the same persisted project metadata and actual PNG files.

**Agent workflow:** load device -> inspect rendered source and active modular composition -> overlay an exact control mask/hitbox -> change a mask, image layer or source-space rectangle -> save -> re-render -> open and inspect resulting PNG (full resolution **and** representative UI scale) -> click, hold or rotate -> inspect states -> correct errors -> after quality review publish new modular PNGs into canonical `Radio/` paths and commit them.

The GUI should provide (or expose existing capabilities through) device selection, explicit Source / Modular WIP mode, pristine/worn choice, active path, inspection overlay, visible hitboxes, LCD bounds, refresh/reload, and current layer/control identity; prefer extending the existing Tk UI over building a second separate app or web server. Headless CLI must be able to reproduce rendered images for the LLM without launching a game or graphical desktop.

**Publishing:** separate mutable scratch work from versioned PZ assets. Ensure an explicit narrow, non-destructive "publish reviewed new PNGs" capability; enforce exact target paths, refuse overwrites of any existing file (including original radio sprites), and write a compact portable manifest reference in the harness project. Review status `proposed` can accompany visibly inspectable published **new** PNGs; it must not claim artist-approved or activated in-game. Do not leave final image layers in the ignored workspace with absolute machine paths.

## 4. Bounded sequence with visible pass/fail gates

| Gate | Work now | Must be demonstrable before proceeding |
| --- | --- | --- |
| **VH1: Fix simulator integration** | GUI selects/auto-loads real W5 modular project; normalize relative file paths; source/modular selection; independent pristine/worn; correct LCD geometry and render. | Actual **modular W5** appears on GUI and in saved CLI render, and pristine/worn toggle changes **the chassis**. Screenshots or render PNGs inspected. Source mode explicitly labeled. **No new art scripts** until this passes. |
| **VH2: Correct controls and input** | Project-local W5 hitboxes, correct LCD clip, mouse-down/up/cancel and wheel/drag via same reducer. | Hitbox overlays cover buttons/knobs/PTT rather than speaker; LCD stays within screen; a held button/PTT visually changes, releases; knob and LEDs respond. A few real screenshot comparisons, not a JSON-only test. |
| **VH3: Fix/publish actual W5 artwork** | Inspect and refine existing W5 masks/chassis/pressed states/worn condition. Consolidate only necessary reusable tools. Publish versioned **new modular PNGs** in canonical Radio family folder with portable project references. | Re-cloneable W5 project + actual PNG files committed at canonical game asset path, composited GUI view matched to CLI and visually reviewed (proposed if still awaiting human approval). No original sprite changes. |
| **VH4: Remaining nine devices** | Use working harness to author/review each of the other 5 walkies, 3 HAM and 1 manpack individually, preserving each hardware silhouette/layout; separate pristine/worn and relevant component states. | All 10 own their real modular PNGs, aligned interactive previews and per-device clear visual QA. Individual blockers recorded precisely; do not stop after W5 unless genuinely unable to proceed. |

**Gate discipline to save Codex quota:** Do a bounded read of the six implicated files and one W5 project; avoid broad new repository audits, 10 repeated hash/diff JSON generators, historic H0 reimplementation, and unrelated profiler/Lua suites. First commit must fix visible simulator behavior or show a reproducible, specific environment blocker; no audit-only first milestone. Tests: only targeted GUI/renderer/hitbox/asset-path tests after visible correction; full suite at **integration gates**. Avoid one-off art-generation scripts per device when reusable harness functions can perform the operation.

**Stop/failure policy:** Never mark a candidate verified or visually reviewed without opening the output. If a particular mask/socket cannot be authored correctly, commit the exact attempted close-up and report the specific pixel/area failure, then continue other independent regions/devices. Do not turn one flattened PNG into a permanent global blocker. Do not replace a picture with a JSON assertion.

## 5. Required checkpoint report

After every gate, report in order: **(1)** visual change and paths to inspectable PNGs/screenshots, **(2)** what was visually inspected and corrected, **(3)** GUI launch/CLI render command + interaction outcome, **(4)** newly committed actual assets at canonical Radio path when VH3+, **(5)** one short line of targeted test result and commit SHA, **(6)** next gate/blocker. Do not lead with source hashes, unchanged audit totals or long test-count tables.

**Completion:** This task is not complete until the Asset Harness actually supports viewing and manipulating real device compositions, AND all ten radios have received their independently authored and visually inspected modular images at the proper Project Zomboid media paths (or each precise unfinished art blocker is documented). **Runtime Radio OS Lua activation is out of scope for this goal** and requires a separately authorized clean cutover with native game verification.
