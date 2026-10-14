# PsychopatzCore Radio OS — UI Stabilization Contract (U0–U7)

**Priority:** mandatory current implementation gate, dated 2026-10-15. Applies to the existing Core Radio OS implementation, **not** a proposal to rewrite its registry, device state, trading or NPC providers.

**Critical testing constraint:** the PZ Headless Harness is broken/unusable and **STRICTLY EXCLUDED**. No PZ Headless Harness setup, install, investigation, repair, launch, commands, examples, acceptance evidence or dependencies. Do not substitute a homegrown "headless native test" and call it a real game run. Only normal Project Zomboid Build 42 in-game execution (user-run when the agent has no desktop/game access) counts as native SP/MP visual acceptance; collect screenshots/console.txt/user feedback. Offline Lua, deterministic PIL/PNG inspection and ordinary unit tests remain allowed.

## Baseline and verified defects

Observed in the user's in-game US Army walkie screenshot (October 15) and source audit of Core main at `832a7e750bed35f42478416f5ed86a8dea141f1f`, DynamicTrading `017d739333d95b19ba927a54be6788daece705ff`, Hoomans `c96cadda1570f59810552f9d3fc55d5c957ba670`. Recheck HEAD/worktrees before changing anything.

- `PsychopatzRadioOSWindow.lua` derives from `ISPanel`, not the existing Core `PsychopatzWindow` UI geometry pattern. Current `Input.lua` consumes clicks on non-control pixels but lacks drag state, mouse capture/release/outside behavior and resize support. The radio window is rigid.
- The opener chooses initial scale/center position, but there is no usable runtime scale control, saved position/scale, responsive relayout or reliable screen-edge clamping on subsequent reopen/resolution change.
- `Window_Pages.lua::drawHome` renders text/selection only; registered `app.icon` IDs are not drawn. Physical buttons have art for backgrounds but icons/text are missing. Current Home attempts three rows with a two-line header in very small LCD bounds.
- US Army manifest's LCD cutout is roughly **72x55 art pixels**. Scaling the shell uniformly doesn't magically make a rich Contacts/portrait UI fit: font measurement, paging and clipping are necessary.
- Header/window layering places the physical shell over the underlying vanilla radio controls in the submitted screenshot; diagnose focus/order/position, not a rendering success.
- LCD mouse hit-testing, provider-data refresh/pagination, portrait clipping and text-overflow behavior need explicit tests.
- Six prebuilt walkie atlases and Core registration/access providers exist. Do **not** regenerate art, rewrite trader settlement or add speculative radio chat to solve UI defects.

The agent previously recorded R0–R7 as implemented at source/offline levels. That is historical evidence, **not passed native UI acceptance**. Reopen the radio renderer/window acceptance of R2 and the UI portion of R3; preserve actual R4–R7 integrations. This stabilization work is U0–U7, preceding further feature expansion.

## Existing Core infrastructure to reuse

Inspect, test and reuse rather than fork:
- `PsychopatzCore/UI/PsychopatzWindow.lua` plus `PsychopatzWindow_Geometry.lua`, `_Responsive.lua`, `_Persistence.lua`, `_Controls.lua`, and Core Settings geometry adapter.
- `PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow.lua`, `_Input.lua`, `_Renderer.lua`, `_Pages.lua`, `_Contacts.lua`, `_Navigation.lua`, `PsychopatzRadioOSDevice.lua`, `PsychopatzRadioManifest.lua`.
- Existing manifest sprite coordinates, 6 Core atlases, app/provider registration APIs, `RadioDeviceState`, `RadioActions`, `RadioSignalHost`, `PsychopatzPortraitPanel` and project Hoomans conversation interfaces.

**UI concept:** frameless diegetic handheld radio — physical chassis stays visible and proportional. Reuse/adapt the Core window geometry/persistence/resize algorithms, but do **not** force an opaque traditional titlebar/rectangular panel behind or around the shell. If full `PsychopatzWindow` inheritance conflicts with transparency or native resize widgets, extract/reuse its helpers and document the actual engine-tested solution; do not blindly swap the base class.

## U0 — Reproduce and lock down failures (first task)

- Audit current HEAD/status across three repos; read window/renderer/input/device/manifest plus Core UI geometry, persistence and clip helpers. Map actual mouse coordinates, child widgets, draw order and class lifecycle.
- Preserve and summarize screenshot findings, include correct previous commit/test status and capture actual baseline tests. Add FAIL-FIRST offline geometry/input/draw-command tests for missing drag, scale changes, persistence, atlas icon calls, LCD overflow and click rows.
- Record separately: **offline** proven failures vs **in-game screenshot** observations; do not fabricate new native runs.
- Gate: source-path diagnosis + failing regression tests + smallest safe U1 patch design; avoid unrelated feature modifications.

## U1 — Movable, proportionally resizable device window

- Introduce safe shell drag zones (noninteractive casing, not antenna tips outside hitbox, not LCD nor physical keys), mouse-down / move / mouse-up / mouse-up-outside capture/release with a drag threshold; no accidental app/softkey activation.
- Support user resize from discreet discoverable corner grip and optionally +/− controls (mouse wheel over shell may be added only if it doesn't conflict with device controls). Keep fixed **256:432 art ratio** and use uniform scale for shell, LCD, source UVs, highlights, hitboxes and portrait placement.
- Store position and **scale** using Core's geometry/settings infrastructure, *per player and device family or per skin as appropriate*, never global ModData. Reopen restores state; handle resolution/UI-scale changes with clamping and min/max scale based on real screen size. Consider split-screen viewport.
- Preserve OS open/close/focus, z-order, existing native radio action button, no duplicate windows, no destructive changes to the native radio panel or its controls.
- Gate: offline mouse-drag state tests, ratio/bounds/persistence geometry tests; **native U1 acceptance remains pending** until a normal in-game drag/resize/reopen screenshot or direct verified gameplay run.

## U2 — LCD layout and legibility

- Centralized local coordinates measured from `skin.screen`; ensure every app uses same layout metrics/header/row/softkey/padding model, deriving fitting rows from **actual** available height/font line metrics.
- Text-width measurement via actual native fonts when available; safe ellipsis/truncation/fallback for long localized names, statuses, settings. No `#characters * 7` sizing rule.
- Paginate/single-selection rows where tiny screen requires it; stable scroll offsets, status bar/footer, contact detail, empty/loading/error states. Do not force 3 rows in 55-pixel LCD.
- Strict screen clipping for dynamic text, content sprites and any child portrait widget; ensure native stencil cleanup and correct draw order after rendering the shell. Overlay named "mask" is decorative, **not clipping**.
- Evaluate UI scale at least 1280x720 and 1920x1080, default/nondefault UI scale. If the exact art cannot deliver readable multi-line chat/portraits, record UX limitation and optionally propose new synchronized shell/manifest art; don't silently repaint this milestone.
- Gate: overflow/regression tests, clipping checks, native screenshots for text size/pagination (or honestly pending).

## U3 — Real atlas-backed widgets and iconography

- Render `app.icon` from the **existing** Core icons atlas into selectable Home rows/tiles, and contact/action icons where valid. Use existing UI Core panels/frame sprites, button states idle/hover/pressed/disabled/selected, indicators and optional overlays. Dynamic text and NPC data remain separate.
- Avoid green debug-looking bars and plain text "buttons" when prepared sprites exist. Use visually coherent state art and readable contrast; don't bake contact names, prices or NPC portraits into textures.
- Cache textures, sprite UV mappings and state IDs once; no getTexture/pixel decoding per render, no per-frame global catalog scan. Unknown signal/battery stays unknown rather than invented.
- Gate: offline draw-command assertions verify actual icon atlas IDs and state transitions; normal PZ screenshot must visibly confirm icons and button states before native pass.

## U4 — Fully clickable OS navigation

- Unify pointer hit testing for LCD list rows/app icons/contact rows/action buttons, with hardware button left/center/right and keyboard/joypad paths. Provide accessible Back/Close/Settings, pager next/previous and focus/hover/pressed.
- Input hitboxes and on-screen art must share one layout tree and uniform shell transform, including after resize. Do not click through to game world/native radio panel or accidentally start shell drag from interactive regions.
- Support scrolling/paging beyond first provider page; provider revision/change events invalidate caches safely without per-frame scans. Preserve selected contact when refreshed.
- Gate: offline pointer-to-action and resize/multi-resolution tests; native mouse+hardware/keyboard and long-list evidence is required for native pass.

## U5 — Portrait and contact presentation integration

- Correct `PsychopatzPortraitPanel` child lifecycle and screen clipping/position while changing pages, zoom and window position. Prefer an actual derived portrait descriptor from Project Hoomans; abstract contact with no NPC has a neutral fallback.
- Keep Hoomans `call_contact` discovery distinct from real dialogue; do not invent interactive chit-chat here. Provider-owned real call availability only.
- Gate: portrait correctness/absence, no clipping leak, bounded updates, no duplicate input or child panel background. Defer new dialogue features.

## U6 — Cross-mod functionality regressions

- Preserve the shared Core app/provider SDK and the DTCommon trader UI handoff, MarketSense pricing, item/stock/basket and authoritative server settlement.
- Abstract trader may trade without spawned NPC when legitimately radio-authorized. Physical Hoomans merchant needs actual nearby interactable merchant body/role, guard referral-only; no client UI privilege escalation.
- Test Core-only, Core+Hoomans, Core+DTCommon+DTAbstract, Hoomans+DTHoomans, combined mods, six skins, offline/disabled radio and no-available-provider. No new trade window in the physical radio.
- Gate: prior regressions and new access tests pass; independently report any pre-existing unrelated failures.

## U7 — Normal game native acceptance and profiling

- **Never use the PZ Headless Harness.** Normal installed Project Zomboid (user-run if necessary) is the only native acceptance path.
- Native SP: six devices, position/scale persistence after close/reopen, freely drag, fixed-aspect resize, no click-through; Home/Contacts/Scanner/Settings icons visible, LCD rows clickable, long contacts paginate, portrait contained, all resolutions/UIScales, open with vanilla device options and correct focus/z-order.
- Dedicated MP: two players, remote/physical trader rule and server rejection, radio off/on, reconnect, unchanged V2 trade window. Test isolated/disposable saves only. Preserve user-reported screenshots, logs and actual profile timings.
- If native game access is unavailable to the agent, complete all **safe offline** implementation/testing and prepare a concise **manual native test handoff** (commands, exact setup, screenshots to capture, console.txt lines). Mark native SP/MP/profiler **pending**; never block indefinitely asking permission, nor claim success from Lua mocks.
- Gate: user-provided verifiable native evidence or an actual normal-game run validates each behavior. R8 and R9 production readiness remain open if it is missing.

## Agent execution policy

1. Begin U0, then U1–U4 before extending feature scope; complete U5–U7 only after foundation is stable at available evidence level. Do not restart already implemented R0–R7 or rewrite working adapters as a detour.
2. Every chunk: inspect git changes; edit only owning repo; run scoped tests and pre-existing Core/DT/Hoomans regressions; update DynamicTrading/Docs/radio_os/DT_RADIO_OS_PROGRESS.md; fast-forward-safe commit/push; continue automatically through safe work.
3. For every acceptance claim separate `source`, `offline Lua`, `atlas/image`, `native SP`, `native MP`, and `profiler`. Treat the user's original screenshot as evidence of **failure**, not success. Do not invent manual verification.
4. No PZ Headless Harness tasks or commands, even as a suggestion. No dangerous resets, force-pushes, overwrite of user changes/saves/installed mods.
5. When native verification is blocked because the agent cannot use the normal game UI, explicitly hand off one consolidated checklist rather than repeatedly asking. Continue any independent safe work; only final production-ready claim awaits real native evidence.
