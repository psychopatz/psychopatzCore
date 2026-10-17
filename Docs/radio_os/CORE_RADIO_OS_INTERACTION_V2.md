# Radio OS interaction contract v2

**Decision locked:** 2026-10-15
**Implementation audit:** 2026-10-17

The product is a radio-shaped mini-computer: a tactile, rugged radio chassis with a readable LCD and shared applications. The LCD is a gameplay surface, but the device must retain its radio identity. Power state comes from the actual Project Zomboid `DeviceData`; the UI never invents radio authority.

## One data contract

The authoring source is one canonical pilot JSON per supported device:

`tools/asset_harness/projects/radio/*_pilot.json`

The build projection is:

`Contents/mods/PsychopatzCore/common/media/ui/Radio/DeviceManifest.json`

The projection contains the device identity, native canvas size, LCD geometry, pristine/worn chassis paths, authored LCD layers, component states, and the interaction policy. All image references are rewritten to game-relative `media/ui/...` paths and validated to remain inside Core's runtime media root.

The simulator and Lua runtime are different languages, so they do not share executable code. They do share the same authored JSON contract and generated projection. The simulator uses the pilot directly; Core Lua reads the generated projection with `getModFileReader`. This is data parity, not a second simulation system.

## Semantic controls

The default active control set is:

`back`, `down`, `home`, `left`, `ok`, `power`, `right`, `up`

`channel`, `volume`, and `ptt` may remain authored for visual reference, but the current policy marks them hidden and non-interactive unless a future reviewed pilot explicitly changes that policy. Active hitboxes must have positive area and may not overlap. Physical IDs map to stable semantic actions: Back, Home, Up, Down, Left, Right, Select, and Power.

Power is a momentary UI button in the interaction lifecycle, not a free-standing switch abstraction. Lua toggles `DeviceData:setIsTurnedOn(boolean)` and confirms the resulting `getIsTurnedOn()` state. The simulator follows the same down/up semantics for authored preview behavior. PTT is released on pointer-up, pointer-cancel, focus loss, and window close.

## Render and input lifecycle

```text
pointer / keyboard / joypad / CLI event
    -> device-local hit test
    -> one normalized semantic action
    -> radio state or navigation reducer
    -> pressed/LED/LCD visual state
```

Mouse-down captures a control and shows its pressed state. Mouse-up commits a momentary action exactly once. An outside release cancels the capture. LCD rows are tested in screen-local coordinates and take precedence over shell dragging. The same reducer path is used by simulator buttons, simulator JSON events, and the simulator GUI.

The Lua window draws the authored chassis and component layers, clips dynamic LCD content to the generated content rectangle, then draws authored glass/bezel overlays. It does not load the retired six-walkie atlas.

## Ownership boundaries

- Core owns the runtime manifest loader, device registry, Radio OS window, input lifecycle, and shared actions.
- The asset harness owns pilot authoring, validation, deterministic compilation, CLI endpoints, and the inspection GUI.
- DynamicTrading may register provider actions and expose an optional preview adapter. It consumes Core's manifest and assets; it does not own a radio catalog, atlas, or duplicate state machine.
- Native game acceptance remains a separate gate from Python/Lua smoke tests and image review.

## Required acceptance evidence

Offline evidence must include manifest compilation, Python reducer tests, Lua loader/registry/action/window smokes, Kahlua verification, and native-size visual inspection. Native evidence must come from a normal Project Zomboid SP/MP run using the packaged Core files, including power-off/open behavior, all supported device families, mouse/keyboard/joypad input, scale/drag persistence, focus-loss PTT release, and provider regressions.
