# Radio OS v2 — Codex /goal: Controller and Modular Asset Production

**Use this new prompt for interaction/asset work.** The older `RADIO_OS_GOAL_PROMPT.md` covers the original A0–A8 asset overhaul and does not override this approved interaction design. User chose **radio-shaped mini-computer** (gameplay first) on 2026-10-15. This documentation commit creates no new runtime sprites.

```text
/goal

In psychopatzCore, implement RADIO OS INTERACTION & ANIMATION v2 and prepare the US Army walkie as the first authentically radio-shaped, modular, animatable radio-computer asset. DESIGN IS LOCKED: gameplay-first 1990s rugged radio-shaped mini-computer, NOT a phone, NOT a strictly realistic minimal LCD radio, NOT three unrelated OS forks. Large functional dynamic LCD with clickable game-friendly contacts/apps/optional portraits, tactile radio hardware, clear antenna/speaker/PTT/rotary knobs, dedicated and discoverable BACK, HOME/MENU, directional/OK, TX/RX LED behavior, and per-device character.

Read in order:
1. Docs/radio_os/CORE_RADIO_OS_INTERACTION_V2.md (authoritative behavior/control contract)
2. Docs/radio_os/CORE_RADIO_OS_DEVICE_ART_SPEC_V2.md (authoritative asset brief)
3. Docs/radio_os/CORE_RADIO_OS_INTERACTION_ROADMAP.md (I0–I9)
4. Docs/radio_os/CORE_RADIO_OS_INTERACTION_PROGRESS.md (checkpoint ledger)
5. Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md (existing A0–A8 fidelity/source plan)
6. Docs/radio_os/CORE_RADIO_OS_CONTRACT.md, CORE_RADIO_OS_COMPOSITOR_SCALE.md, CORE_RADIO_OS_UI_STABILIZATION.md
7. Docs/asset_harness/ASSET_HARNESS_CONTRACT.md, ASSET_HARNESS_PROGRESS.md and tools/asset_harness/README.md
8. docs/profiler.md and docs/preview-framework.md

Start I0 with a FRESH ACTUAL CODE AUDIT, not a blind rewrite: compare tools/asset_harness/simulator/{catalog,model,render}.py, simulator_cli/gui.py and asset_harness core/animations with RadioOSDevice.lua, RadioOSWindow_Navigation.lua, RadioOSWindow_Input.lua, RadioOSWindow_Renderer.lua, the current v1 manifest, existing tests and all staged model PNG paths. Verify actual vanilla B42 icon/item/source references and source availability. Record what is implemented, synthetic, missing, native unverified and the ability to salvage current art vs re-author phone-like casing.

Make **one device-independent semantic controller contract** before asset production: BACK, HOME, UP/DOWN/LEFT/RIGHT, SELECT, POWER, PTT hold, TUNE/CHANNEL, VOLUME, SCAN with device-local mappings, visible physical/LCD softkey fallback and GUI keyboard/joypad alternatives. BACK always returns one navigation level, contact detail -> contacts -> home -> close; no overloading channel-left into surprising Back. LCD menu rows and labeled softkeys must be directly clickable. Support provider custom pages and state/focus restoration, preserve existing app registry and provider authorization.

Build reusable pointer down/move/up/cancel, wheel+drag detents, rotary pivot/frames, PTT hold and guaranteed release on focus loss/close/mouse-up outside, single-click deduplication, LEDs driven by actual available device/game state, and ephemeral event-driven visual transitions. No state-faking, never leave transmitting stuck. Both the Python offline simulator and native Lua OS must consume/validate the same declarative action mapping and shared JSON scenario tests, without claiming Python and Lua execute one implementation.

Then prepare real art with existing tools/asset_harness rather than building a new Flask/Qt website: extend project manifests/export for per-part PNGs or packed frames, pivots, hitboxes, alpha LCD aperture/backing, button pressed and rotary detent animations, LEDs, clean/worn overlays, source provenance and preview contact sheets. Keep the established CLI and optional GUI. Work first with US Army Walkie Base.WalkieTalkie5 (verify item mapping before runtime binding). Produce convincing rugged radio-computer silhouette, full-resolution front shell, dedicated BACK/HOME/OK+D-pad, physical power/channel/volume controls and side PTT, reactive LEDs and substantially legible LCD, avoiding generic phone body. Show a complete controllable shell with pressed keys, turning knobs, TX/RX lighting and per-scale renders. Existing staged sheets may be references, not proof of approved final art. If a knob/phone-like region is inseparably baked, redraw it; don't pretend an overlay animates the underlying static component.

Implement incremental v2 device manifest support in Core while keeping legacy six walkie atlases/three-key skin and their APIs working. Runtime game-loadable assets ONLY in Contents/mods/PsychopatzCore/common/media/ui/psychopatz/radio/devices/<family>/<model>/; developer masters/projects/debug previews elsewhere. Shared UI widget atlases remain. Keep PZ compositor matte, LCD stencil, adaptive scale, custom portraits, Hoomans contacts, Dynamic Trading/DTCommon server authority and DTAbstract trading authorization unchanged.

Milestones I0–I9 are separate from H0–H9 asset-harness, A0–A8 art and older C/U stabilization. Prioritize I0/I1 and then the I5 authoring schema so we can MAKE THE ACTUAL ART next, while developing input/animations in safe parallel. Do not generate all ten skins at once. One approved US Army pilot -> native/runtime tests -> other 5 walkies + 3 distinct front-facing HAM + manpack. Every model retains its own silhouette, controls, and orientation; makeshift HAM must remain front-facing.

Run existing Python unit/CLI/simulator/sprite tests, Lua smokes, semantic scenario parity and per-frame PNG/alpha/geometry regression tests. Separate source, offline image, CLI, Lua mock, native SP, native MP and profiler results. Native game acceptance requires real normal Project Zomboid Build 42; never use/install/fix/investigate or depend on the broken PZ Headless Harness. A Python picture is not native rendering.

Work unattended in safe scoped commits, without repeat approval prompts for routine coding, fixture work or preview iteration. At the genuine ART approval/production overwrite boundary present the pilot art previews and one consolidated decision before promoting into active game assets; do not silently replace approved art or modify saves. Keep existing worktrees and unrelated code intact, no destructive resets/force push. Maintain Docs/radio_os/CORE_RADIO_OS_INTERACTION_PROGRESS.md with actual tests, art source hashes, artifacts, commits, exact phase and blocker; fast-forward-safe push changes when tested.

FIRST ACTION: begin I0 and freeze an I1 controller/asset layout contract, then make the editable US Army component asset pilot and visual test sheet. Continue safe tool/animation work without repeatedly stopping for routine confirmations. Mark native verification pending unless genuinely performed.
```
