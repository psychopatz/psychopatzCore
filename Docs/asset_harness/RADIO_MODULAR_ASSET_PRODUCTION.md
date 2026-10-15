# Radio Modular Asset Production — Harness-Only Contract

**Scope decision (2026-10-16):** Use the existing Psychopatz Asset Harness first to create trustworthy modular radio artwork. **No Project Zomboid runtime code, mod Lua, gameplay, installed mods or current game-loaded textures may be changed by this goal.** This file is the canonical detailed instruction for the scoped radio-asset production goal. Agent-facing /goal text should link here instead of repeating the specification.

## 0. Canonical asset decision and verified stale references (2026-10-16)

**Product decision:** The individual device files and their future modular per-device component/chassis sets under `Contents/mods/PsychopatzCore/common/media/ui/Radio/` are the **sole intended device-sprite architecture**. Do not build a second, competing `DTA_Walkie_*` device atlas pipeline or ship a permanent fallback selector. This is an *authoring-first, clean-cutover* strategy, not a dual-stack strategy.

**Verified code/file gap at this review:** `42.20/media/lua/client/PsychopatzCore/UI/Radio/OS/PsychopatzRadioManifest.lua` still names `media/ui/psychopatz/radio/shells/DTA_Walkie_Shells.png` and five `media/ui/psychopatz/radio/ui/DTA_Walkie_*.png` sheets. The live renderer calls that manifest, but none of those six binaries exists in the tracked `main` image tree at the referenced paths. Therefore **do not describe them as present fallback PNGs**. Treat the Lua references as *stale integration debt*, to be removed/replaced during a distinct, explicitly authorized **runtime cutover** after harness art acceptance. The current goal must not modify those Lua files.

**Simulator source-path defect:** `tools/asset_harness/simulator/catalog.py` currently names `Radio.WalkieTalkie*.png` while tracked walkies are `Base.WalkieTalkie*.png`; also verify the HAM makeshift trailing-space quirk. Fix these catalog paths inside **harness scope** as part of AH-R0/AH-R1, preserving provenance rather than renaming existing art.

**Shared UI:** `Radio/RadioMenu/radioUI.png` already exists; it is the intended shared UI asset. Before runtime cutover, map its actual regions against required display/button/icon/indicator semantics and author missing parts only as needed. Do not claim automatic parity with the untracked DTA UI atlases.

**Sequencing constraint:** This /goal makes the harness and modular images correct first, **not** the in-game runtime. When the per-device QA gates pass, launch a separate runtime integration/cutover assignment to switch the live manifest/renderer and smoke tests to the single `Radio/` asset scheme, eliminate obsolete DTA sheet references, and only then prune abandoned builders/tests/docs after reference checks. Do **not** leave ongoing compatibility fallback as a design requirement, but do **not** edit live code or delete anything in this harness-only goal either. Native game acceptance must be separately verified.

## 1. Authoritative locations and source-of-truth rules

**Canonical Project Zomboid image hierarchy (repo-relative):**
- `Contents/mods/PsychopatzCore/common/media/ui/Radio/WalkieTalkie/`
- `Contents/mods/PsychopatzCore/common/media/ui/Radio/Ham/`
- `Contents/mods/PsychopatzCore/common/media/ui/Radio/ManPack/`
- `Contents/mods/PsychopatzCore/common/media/ui/Radio/RadioMenu/` (shared; unchanged in this phase)

The flat existing files such as `WalkieTalkie/Base.WalkieTalkie4.png` are immutable source/reference inputs. Create any future modular texture sets **alongside** each existing source, not in an invented `art_source/radio/devices` or alternate `psychopatz/radio/devices` hierarchy. Retain exact existing basename capitalization, spaces and extension; report filename quirks instead of silently renaming.

Harness code lives at `tools/asset_harness/`. Editable JSON projects, selection masks, provenance, review/QA outputs, rejected renders and intermediate files live in a safe development workspace (prefer `tools/asset_harness/projects/radio/` for tracked configuration and an ignored `tools/asset_harness/workspace/` for generated intermediates). Such work files are **not** part of the PZ runtime image directory.

If a user-provided `Radio.zip` exists, inspect it as an additional candidate and compare SHA-256, alpha, dimensions, file names and design with repository sources. Do **not** assume it is identical, newer, faithful or approved. Past chatbot-generated modular ZIPs and approximate rectangle masks are **invalid** inputs. Never silently overwrite accepted original artwork.

**Permitted changes for this goal:** `tools/asset_harness/**`, narrowly scoped harness tests/fixtures, harness-specific docs/progress, and new **staged** modular PNGs. Adding new PNGs under the canonical `Radio/` family folders is allowed **only after** the per-device quality gate and review/approval for that specific artwork. Do not modify/replace any existing PNG there. Do not modify files in `42.20/media/lua/`, `Contents/mods/**/media/lua/`, shared UI atlases, gameplay, providers, other mods, runtime manifest Lua or the PZ Headless Harness. No production export/apply for this goal; the existing export facility remains intact and disabled in this workflow.

## 2. Repo baseline: extend; do not restart

The existing harness already has Python CLI with bounded JSON, Pillow source inspection, rectangular regions/alpha islands, layered rendering, animation/contact sheets, variants, diff, validation, staged export, an optional Tk client and a ten-device radio simulator. Inspect the actual current HEAD and tests before editing; the prior H0–H6 and H8 scaffold track has completed milestones. Do **not** restart those phases, rebuild the harness, introduce Flask, force GUI/desktop usage, or build an unrelated extractor.

Known gap: `core/regions.py` alpha-island detection and rectangular cropping cannot separate controls embedded in an opaque chassis; `core/render.py` can compose layers but cannot guarantee precise source ownership or reconstruct hidden sockets; the current simulator slices clean/worn portions of flat staged sheets and lacks independently authored physical part artwork. Preserve API backward compatibility.

The Radio OS I0–I9 roadmap remains a separate future runtime-integration plan. This harness-only task covers the authoring/asset portion of I5–I6 without beginning Lua I7 or changing gameplay.

## 3. Per-device asset tree (same template for all ten)

The example for `Base.WalkieTalkie4` is located under:

~~~text
Contents/mods/PsychopatzCore/common/media/ui/Radio/
  WalkieTalkie/
    Base.WalkieTalkie4.png          # EXISTING: NEVER OVERWRITE
    Base.WalkieTalkie4/
      Chassis/
        Pristine.png                 # complete chassis with correctly reconstructed empty sockets
        Worn.png                     # separate independent complete chassis; same geometry
      Buttons/
        Back/Idle.png
        Back/Pressed.png
        Home/Idle.png
        Home/Pressed.png
        OK/Idle.png
        OK/Pressed.png
        Up/... Down/... Left/... Right/...
      PTT/
        Idle.png
        Held.png
      Knobs/
        Volume/Frame_00.png
        Volume/Frame_01.png
        Channel/Frame_00.png
      Switches/
        Power/Off.png
        Power/On.png
      LEDs/
        PWR/Off.png
        PWR/On.png
        RX/Off.png
        RX/On.png
        TX/Off.png
        TX/On.png
      LCD/
        Glass.png
        BezelOverlay.png
~~~

This tree is a **target**, not a claim that any parts are already accurate or that every model owns every listed control. Use per-device inventory, not invented universal layouts. Preserve the HAM and manpack family-specific geometries, microphones and additional controls. Reuse part-state formats and tooling, **not** model-specific pixel coordinates.

Tracked metadata should live in `tools/asset_harness/projects/radio/<family>/<model>.json` (or an existing backward-compatible project convention): registered source hash/dimensions, absolute source-canvas bounds, tight binary/antialiased mask reference, source-space anchor, hit shape, pivot, z-order, logical role, state names, variant compatibility, reconstruction regions, approval status and per-state image hashes. Image paths resolve to the above `Radio/` hierarchy. Do not place developer JSON, contact sheets, empty masks or debug images into runtime `common/media/ui/Radio/`.

## 4. Two separate chassis files; orthogonal interactive states

`Chassis/Pristine.png` and `Chassis/Worn.png` are required **separate raster image files per model**, with identical dimensions, exterior silhouette, screen aperture, physical sockets, pivot coordinates and hit regions. Each is an independently inspected condition variant. Any wear masks or scratches used during authoring are optional tools, not a substitute for writing both final chassis files.

Treat dimensions independently:
- `chassis_variant`: `pristine` | `worn` (future: more conditions);
- `control_states`: keyed momentary button idle/pressed, PTT idle/held, power off/on, rotary frame/detent and LED state;
- `lcd_state`: independent backing, glass and dynamic preview content.
Do not bake every condition/control combination into one sprite or select controls by swapping an entire chassis. Controls should be reusable for both chassis variants **if visual and anchor validation support reuse**; distinct condition-specific controls are allowed when objectively required. Existing simulator `clean` may alias new `pristine` for backward compatibility, without renaming existing source artifacts.

## 5. Precision editing and component contracts

**Do not infer hardware separation from a rectangle.** Bounding boxes locate components; alpha masks select actual silhouettes. Support device-local editable masks (indexed/gray PNG alpha, hand-defined polygon/path or equivalent), preview with overlay/zoom and source-coordinate QA. Auto segmentation produces only proposals. Never mark a proposed mask verified without an actual visual inspection.

For each movable part, distinguish:
1. base chassis with its **real empty socket/recess**, fastening/shadow and proper occlusion;
2. independently masked moving face/cap, preserving the original label/icon and materials;
3. visually honest changed state(s), with believable travel/depth for buttons, pivot-locked detents for knobs, different rocker geometry for power, held PTT, localized lens/emissive/glow for LEDs.

For flattened artwork, concealed chassis pixels are unavailable. Reconstruction must be localized, editable, documented and reviewed, not a magical automatic rectangle deletion. Output a specific reconstruction mask and blocked state until the socket is authored/verified. Do not use fill-transparent holes, huge cloned patches, arbitrary darkening/shift-only fake 'pressed' images, glow smearing, generic replacement controls or generation that changes device hardware.

The LCD aperture must have precise alpha and an independently drawn matte/background, with original bezel/controls intact. Transparent exterior means true zero alpha outside approved device/glow pixels; forbid black vignette, gray checkerboard, color haze and clipped antenna/microphone. Keep antialiased edges; never delete genuine thin wires or highlights to pass alpha thresholds.

No art-style changes or redesign are authorized in this goal. All device silhouettes, labels, layouts, colors and established styling remain the source of truth.

## 6. Efficient, unattended agent workflow (AH-R0 to AH-R6)

| Gate | Job | Required evidence |
| --- | --- | --- |
| **AH-R0** | Re-audit current HEAD, worktree, actual harness functions, simulator, source PNGs (including paired clean/worn sheet layout), prior issues and existing unit tests. | File/hash/alpha inventory for six walkies, three HAM and manpack; confirmed owner paths; baseline tests. |
| **AH-R1** | Implement reusable mask editing/import, preview, extraction, source provenance and non-destructive alpha-contamination QA through existing CLI/core. | Synthetic + actual-source tests that reject incorrect neighbor pixels/oversized masks. |
| **AH-R2** | Implement versioned separate chassis pristine/worn outputs, reconstructable socket masks and condition-independent state composition. | Identical canvas/anchors; no chassis gaps; missing socket authoring explicitly fails. |
| **AH-R3** | Implement part-state authoring/validation for idle/pressed, rocker on/off, PTT hold, rotary detents, independent LEDs and LCD. | Separate images with clear visual differences and stable pivots; invalid fake states rejected. |
| **AH-R4** | Extend **offline** simulator/CLI to load modular projects, render every combination, simulate clicks, knob, PTT, power, LED and variant switching without runtime mod hooks. | CLI JSON scenarios, PNG contact sheets, unit/image-diff checks, compatible old simulator. |
| **AH-R5** | Use the known bad-cut `Base.WalkieTalkie4` as extraction/alpha regression, then the existing I6-designated US Army `Base.WalkieTalkie5` as the full production-quality pilot. | Human/vision inspectable per-part sheets, source-to-idle compositing diff, both chassis variants, no unverifiable 'passed' flags. |
| **AH-R6** | Repeat individually for the other eight devices, preserving distinctive source designs and family controls. | Ten separate manifests, no guessed shared coordinates, per-device QA status and blockers. |

Run safe phases without routine approval prompts. If a particular flattened image needs genuinely manual pixel artwork, record the precise mask and blocker, keep other tool work moving, and seek one consolidated art review at the material approval boundary. Do not lower QA to produce a superficial 10/10 complete report.

## 7. Hard QA gates and measurable acceptance

For each source/variant:
- Input SHA, dimensions, legitimate alpha/island inventory and no bleed beyond exterior boundaries.
- Visual mask inspection for every control; **no neighboring buttons, body or labels** included unintentionally.
- All layers share integer source-canvas coordinates; register pivots/hit shapes and supported z-order; round-trip idle compositing against approved source produces a diff. Unexplained pixels **outside** documented reconstruction/condition areas are a failure; report numeric RGB/alpha error counts and a visual heatmap, not just a pass boolean.
- Missing sockets, ghost images, alpha holes, halos, wrong button names and clipped mic coils/antennas fail.
- Pristine vs worn differ in material condition but preserve mechanical geometry; no drifting LCD apertures or control targets.
- A button visually depresses and returns; rotary motion keeps registered pivot; an LED lens has isolated on/off and optional bounded glow; power switch moves to distinct on/off appearance; PTT releases. Reject a mere offset-and-dim approximation as production art.
- Preview pristine/worn, off/on, idle/pressed and combined state grids at 1:1 and representative downscaled UI sizes. No fictitious proof of actual PZ rendering.
- JSON results contain per-device verified/proposed/blocked flags, reasons, file paths, SHA-256, exact test commands and image inspection artifacts.

A 'complete' device must actually render and be visually reviewed. A technically valid mask, Pillow composition, simulator response or exported archive is **not** evidence that physical art is correct. It is acceptable and safer to mark a device incomplete.

## 8. Scope safety, delivery and future runtime handoff

Allowed development: Python harness, harness tests/fixtures, staged per-device assets and documents. Preserve the existing CLI API and unrelated mods. Current v1 Lua/atlas references are known stale integration debt; leave the Lua untouched during this harness-only goal, but do not build, promise, or perpetuate an old-atlas fallback in the future single-system design. Do not run/repair the PZ Headless Harness. Do not modify game code, live Radio OS renderer, navigation, Lua manifests, PZ saves or runtime integration. No destructive Git reset, force push, bulk replacement or unsafe file writes. Record exact HEAD/worktree, tests and commits. Prefer small verified, safely pushed commits for harness/docs and keep user work untouched.

Do **not** invoke `export apply` or automatically copy generated art into already-active game textures in this goal. Approved *new* per-model PNG files may be added at `common/media/ui/Radio/` once their per-file review gate passes; existing files remain immutable. I7+ runtime binding, performance/native SP/MP and Hoomans/DynamicTrading compatibility are separate future tasks.

Deliverables: changed harness source/tests, repeatable bounded CLI commands and scenarios, preserved immutable originals, per-device masks and source-authoring projects, separate Pristine/Worn chassis files wherever approved, independently keyed control states, visual contact sheets, source-to-render diff reports, per-device status matrix, and a concise checkpoint in the asset-harness progress ledger. Report blocked or incomplete artwork truthfully rather than packing failed output as final.

## 9. Precedence and required reading for /goal

For this narrow harness-only radio task **this document's path and no-runtime-change rules supersede the older authoring path examples** in `CORE_RADIO_OS_DEVICE_ART_SPEC_V2.md` and `ASSET_HARNESS_GOAL_PROMPT.md`. For already implemented APIs and prior evidence, keep `Docs/asset_harness/ASSET_HARNESS_CONTRACT.md`, `ASSET_HARNESS_PROGRESS.md` and `tools/asset_harness/README.md` authoritative; for semantic control names/behavior, consult `Docs/radio_os/CORE_RADIO_OS_INTERACTION_V2.md`. Do not advance I7 runtime integration or overwrite H0–H9 history while following this goal.
