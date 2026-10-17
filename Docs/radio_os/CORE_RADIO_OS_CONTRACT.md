# PsychopatzCore Radio OS — ownership and runtime contract

**Updated:** 2026-10-17

PsychopatzCore owns the mod-agnostic in-game Radio OS framework. It provides the device registry, modular renderer, input lifecycle, navigation, and extension points for apps and provider actions. It does not own NPC, trader, inventory, or server-authoritative gameplay facts.

## Canonical runtime source

The single authoring source is the set of canonical pilot projects:

`tools/asset_harness/projects/radio/*_pilot.json`

The deterministic compiler packages them as:

`Contents/mods/PsychopatzCore/common/media/ui/Radio/DeviceManifest.json`

Core Lua loads that file through `getModFileReader("PsychopatzCore", "media/ui/Radio/DeviceManifest.json", false)`. The loader validates schema 2 and the `psychopatz_radio_runtime` kind, normalizes rectangles/components, and indexes by both pilot ID and vanilla full type. Invalid or missing data is reported as unsupported; the renderer does not silently resurrect the old atlas manifest.

The packaged assets are full-canvas device images and authored layers below `common/media/ui/Radio/`. The manifest carries native canvas dimensions, LCD geometry, pristine/worn chassis, LCD matte/glass/bezel layers, component state images, and the interaction policy. The old `PsychopatzRadioManifest.lua`, DynamicTrading atlas manifest, and source-catalog route are retired.

## Core API responsibilities

Core exposes:

1. Device lookup by vanilla full type and stable device ID.
2. `GetDeviceContext` with the actual radio `DeviceData` power/validity state.
3. One Radio OS window with proportional, per-device geometry.
4. Shared semantic actions: Back, Home, Up, Down, Left, Right, Select, and Power.
5. App and contact-provider registration without taking ownership of provider data.
6. Bounded input capture, pressed visuals, LCD clipping, PTT cancellation, and window close/restore behavior.

Power uses the verified vanilla `DeviceData:getIsTurnedOn()` / `setIsTurnedOn(boolean)` API. Provider actions remain operational-state gated; the Core Radio OS surface can open while a supported device is powered off so the user can reach the authored Power control.

## Cross-mod integration

DynamicTrading, Project Hoomans, and future mods register provider actions or content through Core APIs. They do not duplicate the device manifest, hitboxes, renderer, or reducer. DTAbstract's preview is only an adapter: it requires Core's runtime manifest and draws Core's modular assets.

## Acceptance boundary

The following are offline/source acceptance only: deterministic manifest compilation, Python reducer tests, Lua smoke tests, Kahlua verification, and native-size image inspection. Native Build 42 SP/MP acceptance is still pending and must use a normal game run with screenshots and console evidence. The prohibited/broken PZ Headless Harness is not evidence.

See [CORE_RADIO_OS_INTERACTION_V2.md](CORE_RADIO_OS_INTERACTION_V2.md) for the semantic interaction contract and [CORE_RADIO_OS_INTERACTION_ROADMAP.md](CORE_RADIO_OS_INTERACTION_ROADMAP.md) for phase status.
