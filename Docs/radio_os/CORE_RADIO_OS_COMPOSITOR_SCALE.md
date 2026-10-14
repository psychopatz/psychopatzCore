# PsychopatzCore Radio OS — Compositor, Fidelity and Scaling Gate (C0–C6)

> **Asset architecture update (2026-10-15):** Current compositing, LCD sandwich, zoom, texture sampling and UV-gutter fixes remain valid. The next **art-production phase** is [CORE_RADIO_DEVICE_ASSETS.md](CORE_RADIO_DEVICE_ASSETS.md) (A0–A8): individual high-resolution **walkie, HAM and manpack** shell assets/manifests, with shared UI widget atlases and optional condition variants. The old 341×341 compact sheet is a historical compatibility fallback, **not** the new art source. Do not restart C0–C6 or regenerate approved artwork without model-by-model review.


**Status: current priority, 2026-10-15.** The user supplied two new screenshots of the working-but-flawed US Army walkie on a normal Project Zomboid Build 42 session. This plan supplements the existing U0–U7 stabilization contract. Preserve already completed source/offline U0–U4 work; native acceptance remains open. No gameplay code is changed by the documentation update.

**Absolute restriction:** DO NOT USE, INSTALL, REPAIR, LAUNCH, INVESTIGATE OR DEPEND ON THE **PZ HEADLESS HARNESS**. It is broken. Offline Lua/Pillow tests and normal real-game SP/MP (user-run if needed) are the only supported paths here. Never label mocks as native.

## Evidence and competing hypotheses — do not prematurely claim causes

Latest planning inspection: `psychopatzCore/main` `87d16a3117c3dba689627c6a3167313bb0b8590e`; `DynamicTrading/main` `1fd47cac048502a838fbfbcf1c79a12dce4facd7`; Hoomans unchanged at `c96cadda1570f59810552f9d3fc55d5c957ba670`. **Re-read current HEAD and status before changing code.**

- **Confirmed source fidelity issue:** `tools/radio_os/build_dtabstract_walkie_shells_compact.py` reconstructs a 1024×1024 atlas from a **341×341 compact PNG** using nearest-neighbor resizing. This cannot restore fine detail discarded when the full image was reduced. The high-resolution source builder (`build_dtabstract_walkie_shells.py`) requires an original approved 1448×1086 art source, **not bundled** with the current repository. Do not invent fidelity or quietly replace the approved design; locate an authentic existing master if available, otherwise record missing original as a separate art-blocker while pursuing the compositor.
- **Confirmed current layer code:** `PsychopatzRadioOSWindow_Renderer.lua` draws `screen_bg_<theme>`, app text/sprites, status and scanlines in `drawScreen()` called from `prerender()`; then draws `drawShell()` and hardware controls in `render()`. This shows **an LCD sprite is attempted**, not that an opaque backing covers every alpha-zero pixel in the shell.
- **Manifest geometry:** `PsychopatzRadioManifest.lua` defines a small US Army LCD rect `{x=107,y=247,w=72,h=55}` in a 256×432 shell. Both the concept art's larger apparent hollow screen and the transparent cutout *outside* that rect are plausible causes of world bleed-through. Another possibility is missing `getTexture`, invalid UVs, low-alpha screen sprite, PZ stencil/layer ordering, or child portrait lifecycle. Verify; do not assert a single unproven explanation.
- **Scale is implemented but poorly exposed:** `_Geometry.lua::applyScale`, `_Input.lua::isResizeHandle` and settings persistence exist. `PsychopatzRadioOSDevice.lua` defaults to height-based scale clamped around 1–1.75 and `OS.Open` clamps saved/options scale to **0.75–2.25**. A hidden corner grip is not a discoverable zoom control. The latest screenshot demonstrates a usable drag position, NOT a proven absence of resize code.
- **Pixel rendering unknown:** `drawSubTexture` presently accepts floating screen coordinates. PZ sampling/filtering behavior at non-integer scales must be observed with a targeted actual-game experiment. A 341px compressed source, font/system antialiasing and texture sampling are independent quality variables. Nearest filtering cannot restore source detail.

**Unified sprite atlases are not inherently the problem.** Preserve atlas-based sprite slicing; fix source fidelity, hole/backing coverage, compositing lifecycle and user scale separately.

## Ownership and scope

Only `psychopatzCore` owns shared device art, shell manifest/coordinates, LCD compositing, scaling and reusable Radio OS widgets. Hoomans supplies NPC contacts/portraits and Dynamic Trading supplies registered trader/scanner apps. Do not move the renderer back into DTCommon, reimplement V2 trade screens, change prices/settlement, or pretend Hoomans discovery is live chat.

## Required phase ordering

### C0 — Reproduce, instrument and isolate (immediate next chunk)

1. Audit latest window `prerender/render`, child portrait draw calls, manifest UV, `screen_bg_<theme>` PNG alpha and getTexture cache; verify full shell alpha mask for each skin and compare to the claimed LCD rect and actual visible aperture.
2. Create a **debug-only compositor visualization** toggle: overlay per-device LCD/backplate rectangle, visible transparent-hole bounds, shell UV rect, clipping and hardware hitboxes in distinct colors, show current scale and backing alpha. No debug art/settings on production by default. Avoid processing alpha pixels per frame; use build-time tests/lookup metadata.
3. Build a deterministic offline **alpha-hole/backing coverage** smoke: inspect all 6 shell sprite alpha holes, characterize connected/open regions and compare a filled backplate footprint with the entire intended aperture; render a synthetic opaque LCD plate + content + shell into RGBA image. Check that the hole exposes the composited plate and never world/background in intended LCD pixels while exterior remains transparent. Do not count this as native proof.
4. Distinguish artifacts that are a deliberately open body gap or ornamental notch (must stay alpha-zero) from the intended LCD aperture (must be backed). Do not fill every transparent pixel of the whole shell silhouette. Document discrepancies per skin and actual PNG sha/build settings.
5. Gate: dated matrix of each cause (verified/ruled-out/unverified), offline failing/guard tests and exact source of the alpha/scale artifacts. Continue without waiting for routine approval.

### C1 — Deterministic layered LCD sandwich

Create/verify explicit **device-local** layer responsibilities:
```text
Device drop shadow / back chassis treatment (optional)
LCD opaque matte/backplate UNDER the complete intended display aperture
LCD theme/textured backing INSIDE the same viewport
Dynamic app sprites/text and provider portrait (each clipped)
Optional screen effects/glare/noise (clipped, adjustable/disableable)
Front shell with alpha-zero display hole and proper bezel overlap
Physical keys, LEDs, resize affordance and hover/press highlights
```
- Draw the **opaque matte first** using a cached atlas sprite only if it is genuinely opaque over required pixels, otherwise a solid `drawRect` of a theme color before the textured LCD sprite; a transparent ornament alone is not a backing. Use measured aperture geometry rather than arbitrarily enlarging past a real bezel.
- Reconcile the named manifest viewport with the **actual hole**: if art/manifest are inconsistent, adjust authored metadata or a separate `lcdBackdrop` / `lcdContentViewport` pair and update all six skins + tests. The backdrop may occupy the larger window behind the bezel while content remains in a safe inset. Ensure backing does not flood antenna gaps, buttons or world outside device.
- Verify frame order in PZ ISUI: parent prerender, child portrait render, parent render may be interleaved; avoid shell painting over non-screen elements or drawing children on top of shell unexpectedly. Portraits must be clipped through an actual working method validated in B42, not by a decorative `overlay_mask` image.
- Gate: Lua draw-command test ensures opaque backing precedes text/effects/shell and stencil resets even on failed app render; per-skin Pillow composite image test proves LCD coverage. Real PZ screenshot still required for native acceptance.

### C2 — Recover source fidelity and crispness

- Compare Core's 341×341 compact source, reconstructed 1024×1024 shell, production metadata, authoring script and any **genuine** high-resolution approved source already present locally/in Git. Never assume the original master is still available. Do not download arbitrary unrelated walkie images or regenerate the approved style without explicit art direction.
- Preserve high-fidelity approved art if located; regenerate six cutouts/metadata in sync, **never** upscale compact art and call it high-res. If original isn't available, explicitly report art fidelity blocked and retain the current source while improving render quality elsewhere.
- Check alpha fringe/unassociated-alpha handling on transparent edges, UV gutters, subtexture coordinates and filtering. Test native game's supported texture filter controls; choose pixel-sharp nearest or suitable stable rendering **only when supported and without globally altering vanilla UI textures**.
- Snap final device and layer destinations to integer screen coordinates using one canonical transform. Compare fractional vs pixel-snapped at test scales; do not force integer zoom only if that makes UI unusable on common monitors.
- Gate: before/after magnified art comparisons (with source lineage) and native screenshots at 100%, 150%, 200%. Distinguish asset limitations from sampler and font quality.

### C3 — Discoverable adaptive scale and zoom

- User-visible and clickable **zoom + / zoom − / reset/fit** affordance (e.g. a discreet shell control, right-click radio shell context option, explicit Settings row and optional mapped hotkeys). A hidden extreme-corner pixel target is **not sufficient**. Do not confuse zoom controls with the radio's hardware Call/Back keys.
- Automatically choose a readable default based on the real usable viewport/resolution/UI-scale and optional split-screen viewport: the radio should fill a sensible fraction of available height while remaining fully visible, not use a fixed 1.75 max for all large monitors. Compute effective `maxScale` from usable width/height and an explicit safety margin rather than hardcoded 2.25 ceiling, respecting performance and genuine source-art detail. Provide a sensible minimum for smaller monitors and a maximum governed by viewport. Keep shell aspect 256:432.
- **Saved manual per-player/per-device scale wins** over auto default on subsequent opens; scale/reset/fit changes persist via existing Core UI settings and screen clamping. After game resolution changes, clamp and center as needed without erasing preferred scale; restore it when display permits.
- Single canonical transform: same scale and snapped origin for shell, full LCD backdrop, content rect, portrait, keys, resize hitbox, hover area and input. No independent per-layer hand-tuned offsets. Check resize grip visibility, click priority, drag and near-edge access.
- Gate: offline tests for 1280×720, 1920×1080, 2560×1440, 3840×2160, optional split-screen and multiple UI scales; geometry/ratio/persist/reopen/resize-hit test. Native screenshots still necessary.

### C4 — Visual/interaction alignment smoke tests

- Augment offline tests for screenshot-like composites with synthetic green/amber LCD, title/status, icon and silhouette; verify composite pixels at the screen's interior are opaque, no bleed at the bezel boundary, exterior remains transparent, no duplicated overlay and hardware/control destinations line up.
- Verify native actual-game `prerender/render` behavior with temporary **debug compositor probe**: tint backing a conspicuous color, draw border/anchor marks, change scale and move while verifying no world leak or drift; disable probe outside testing.
- Make the compositor extensible to HAM/manpack/other future skins via declarative backdrop, safe content rectangle and optical insets, not a US-Army-only `if fullType` hack.
- Gate: per-skin test artifact and explicit pass/fail table, mock/native evidence distinct.

### C5 — Compact, readable screens with true portrait support

- Keep Home/Contacts/Settings/Trader Scanner dynamically rendered and paginated. A 72×55 safe viewport cannot fit a full chat/portrait plus several text lines at low scale; use deliberate one/two-row/page layouts with native font measurements.
- Keep the portrait in an exact safe content viewport while retaining a visually continuous glass/matte background; test child portrait lifecycle and stencil at every supported scale.
- No baked NPC portraits, contact names, UI text or trader stock in the shell PNG. Call/chitchat only through real provider APIs; Trade opens the existing V2 UI separately.
- Gate: no text/portrait world bleed; real button and clickable-row focus agrees with visual bounds; no fake capability states.

### C6 — Normal-game visual/MP and performance acceptance

- Normal Build 42 SP with all 6 devices at low/high resolution + UI scales: shell crispness, opaque LCD, readable apps, drag and user zoom controls, reopen saved geometry, clickable keys and LCD hitboxes, portrait containment.
- Dedicated MP: Core alone and combined with Hoomans/DT, trader-scanner access/physical vs abstract rules unchanged, no duplicate windows or new server authority.
- Profile draw/cache behavior with existing native game profiler or manual measurements; don't load textures or examine pixel masks per-frame.
- If Luna lacks desktop access, finish all offline tasks/commits, produce one concise manual acceptance checklist with screenshot filenames/console.txt observations, and label C6/native gates pending. Do **not** repeatedly request screenshots before proceeding safely.

## Integration with old milestones and stopping rules

The U0–U7 UI stabilization plan remains valid. Current screenshots **supersede any claim that U1–U4 are native-passed**; code and mock tests may have improved them. **C0–C4 are the immediate focused implementation queue**, then C5–C6, then revisit any pending U5–U7 / R8–R9 gates. Do not undo already implemented geometry, paging, app registry, provider or security work.

Work unattended in small coherent, verified, fast-forward-safe commits, recording changed owning repo, tests, artifacts, actual screenshot/native status and next chunk in `DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md`. Preserve user worktrees, installs/saves and all unrelated gameplay. No destructive resets or force pushes.

**Important limitation:** no high-fidelity replacement shell is guaranteed until its authentic source is located. Report that separately; compositor/scaling work must proceed regardless.

## Packaging correction: Core common/media/ui (2026-10-15)

Production walkie shell and shared-UI PNGs have been moved (same blob hashes) to `PsychopatzCore/common/media/ui/psychopatz/radio`. The Lua manifest still uses valid game-relative `media/ui/psychopatz/radio/...` paths and remains under the existing version-specific Lua folder. The 341px builder source is at `art_source/radio/legacy/`. New standalone model shells and animated LED frames also export into `common/media/ui` after art validation. Native texture resolution is pending normal gameplay testing.
