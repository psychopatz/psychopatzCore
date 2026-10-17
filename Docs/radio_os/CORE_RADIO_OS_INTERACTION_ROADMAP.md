# Radio OS v2 — implementation roadmap

**Updated:** 2026-10-17

This roadmap describes the live implementation, not the retired atlas/source-catalog plan. The canonical device definitions are the ten `*_pilot.json` files in `tools/asset_harness/projects/radio/`. They compile to one packaged runtime projection:

`Contents/mods/PsychopatzCore/common/media/ui/Radio/DeviceManifest.json`

The Python CLI, simulator GUI, Core Lua Radio OS, and the optional DynamicTrading preview all consume that same device definition and the same `common/media/ui/Radio/` assets. DynamicTrading owns no radio skin catalog or renderer.

## Phase status

| Phase | Status | Evidence |
|---|---|---|
| I0 — audit and contract | complete | Canonical pilots, asset roots, vanilla `DeviceData` power API, and legacy references audited. |
| I1 — semantic manifest | complete | Deterministic schema-2 compiler and packaged `DeviceManifest.json`; duplicate full types and overlapping active hitboxes fail compilation. |
| I2 — navigation contract | complete offline | Shared semantic controls: Back, Home, Up, Down, Left, Right, Select, Power. Python and Lua smoke coverage exists. |
| I3 — gesture lifecycle | complete offline | Pointer down/up/cancel, pressed state, power toggle, and PTT release paths are covered by reducer/window tests. |
| I4 — component projection | complete offline | Full-canvas pristine/worn chassis, LCD layers, keyed controls, LEDs, and hidden non-interactive rotary/PTT components render from the manifest. |
| I5 — canonical asset package | complete for current staged pilots | All ten pilot projects compile and resolve to repository-relative `media/ui/Radio/...` paths. |
| I6 — pilot art | complete for current staged assets | W5 and the other nine devices have native-size pristine/worn outputs; visual review remains separate from native-game acceptance. |
| I7 — Core Lua integration | implemented; native gate pending | Core loads the JSON with `getModFileReader`, registers all ten devices, and renders the modular assets. Offline Lua smokes pass. |
| I8 — family coverage | implemented in the manifest; native gate pending | Walkies, HAMs, and manpack are all in the same generated manifest. |
| I9 — native hardening | pending | Requires a normal Project Zomboid SP/MP run for window placement, input, scale, focus-loss, and provider regression evidence. |

## Ownership rule

Core owns the runtime loader, device registry, renderer, input lifecycle, and shared Radio OS actions. The asset harness owns authoring, validation, compilation, CLI, and GUI inspection. DynamicTrading and other mods may provide actions or use the preview adapter; they must not fork the device manifest, atlas, hitboxes, or Radio OS state machine.

The old `PsychopatzRadioManifest.lua`, `DTA_Walkie_Manifest.lua`, and atlas/source-catalog routes are retired. A missing or invalid generated manifest is an explicit load failure; there is no silent legacy fallback.

## Verification commands

```bash
PYTHONPATH=tools python3 tools/asset_harness/cli.py runtime-manifest \
  --out Contents/mods/PsychopatzCore/common/media/ui/Radio/DeviceManifest.json

PYTHONPATH=tools python3 -m unittest \
  tools.asset_harness.tests.test_runtime_manifest \
  tools.asset_harness.tests.test_radio_simulator \
  tools.asset_harness.tests.test_modular_radio

lua tests/radio_os/psychopatz_radio_manifest_smoke.lua
lua tests/radio_os/psychopatz_radio_os_registry_smoke.lua
lua tests/radio_os/psychopatz_radio_os_action_smoke.lua
lua tests/radio_os/psychopatz_radio_os_window_smoke.lua
```

Offline verification does not count as native Build 42 acceptance. The next gate is a normal game run using the exact packaged Core files, followed by console and screenshot evidence.
