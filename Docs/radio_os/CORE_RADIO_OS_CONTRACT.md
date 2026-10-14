# PsychopatzCore Radio OS — Reusable Platform Contract

Status (updated 2026-10-15): **a Core Radio OS foundation and provider adapters are implemented**, but user-supplied Build 42 screenshot shows the window is rigid and the LCD presentation incomplete. Native functional acceptance has NOT passed. The immediate binding stabilization specification is [CORE_RADIO_OS_UI_STABILIZATION.md](CORE_RADIO_OS_UI_STABILIZATION.md).

## Vision

PsychopatzCore owns a **mod-agnostic in-game radio device/OS framework** usable by Project Hoomans, Dynamic Trading, and future Psychopatz mods. The radio is a physical, Project Zomboid-inspired UI with individually skinned vanilla radios, dynamic LCD content, modular apps/widgets, contacts, display controls, and reusable runtime APIs. Radio ownership and actual device operating state are validated using the game's existing methods. Other mods plug in content and actions; Core never takes ownership of their game semantics.

**No hard dependency on Project Hoomans, Dynamic Trading, DTCommon, DTAbstract, MarketSense, or LLM services.** A Core-only installation must load cleanly and provide the framework and an inert Home/Settings experience.

## Existing sources to extend, not duplicate

- `common/media/lua/shared/PsychopatzCore/Radio/PC_RadioDeviceState.lua`: already exposes `GetDeviceData`, `Validate`, `IsAudible`, `IsActive`, `GetPlayerDevices`, `FindPlayerDevice`, `FindActivePlayerDevice` and `FindAudiblePlayerDevice`. Review its present portable/two-way/volume/mic requirements before reusing them for a UI that may show non-transmitting status or new device families.
- `42.20/media/lua/client/PsychopatzCore/UI/Radio/PsychopatzRadioActions.lua`: already provides a registry of independently ordered actions extending the vanilla radio UI. Do not create a competing patch to `ISRadioWindow`.
- `42.20/media/lua/client/PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost.lua`: already attaches registered actions to the vanilla radio signal module and recalculates layout. Integrate with this host without causing duplicate buttons or expensive `prerender` scans.
- `42.20/media/lua/client/PsychopatzCore/UI/Components/PsychopatzPortraitPanel.lua`: generic, already reusable portrait widget. Profile/verify clipping inside tiny LCD cutouts; Core must never depend on PNC-specific identities.

## Core-owned implementation

Core owns and exports:
1. Device registry (vanilla fullType -> family, skin, texture rect, screen cutout, physical key hitboxes; pluggable future devices).
2. Cached texture-atlas renderer, screen clipping and screen themes; per-device scale, input, focus, responsive zoom, drag/close lifecycle, hover/pressed/disabled art and accessible alternative navigation.
3. Generic app registry; Home, Settings and safe placeholders can work with Core alone. Define app identifiers with owner namespace and predictable deterministic order.
4. Generic contact-provider registry and normalized presentation model; bounded paging, sorting, statuses, optional portrait descriptor, capabilities/actions and refresh events. Core does **not** own authoritative NPC/world contact knowledge.
5. Generic call/action dispatch interfaces that delegate to a provider; Core only performs device/UI prechecks and never grants remote NPC/trader authority on behalf of installed mods.
6. Public versioned extension API, diagnostics and mock/native tests for third-party integration.

Suggested namespace: `PsychopatzCore.RadioOS`, with `RegisterApp`, `UnregisterApp`, `RegisterContactProvider`, `UnregisterContactProvider`, `RegisterDeviceSkin`, `Open`, `Close` and `GetDeviceContext`. These are **proposed APIs**; audit and evolve against actual Core conventions before freezing. Provider callbacks must be bounded and fail closed (safe error results, no implicit authorization). UI display flags/capabilities are **not security checks**.

The current UI implementation also accepts optional app callbacks `render`, `onMove`,
`onSelect`, `onBack`, `hitTest` and `onScreenClick`.  The last two are presentation
hooks for direct LCD-row activation; consequential work still belongs to the owning
provider.  The frameless window persists position and uniform scale per local player,
clamps geometry to the current resolution, and consumes shell/LCD mouse events so
input cannot fall through to the world.  Native Build 42 SP/MP acceptance remains a
separate gate.

Proposed contact list entry:
```lua
{
  id = "providermod:stable-id",
  providerID = "providermod:contacts",
  title = "contact label from authorized provider",
  portraitDescriptor = nil, -- optional, validated separately
  status = "unknown",
  actions = { "providermod:call", "providermod:trade" },
}
```

Provider owns acquisition, authorization, server validation and sensitive information; Core handles presentation only. Contact lists should not become a giant persistent Core ModData database. Existing data stays in the owning mod's persistence layer. Deduplicate/sort with namespaced identities and bounded results.

## Two separate integration domains

### Project Hoomans

- Hoomans owns NPCs, portrait data, NPC identity/knowledge, conversation/orchestration, and radio discovery semantics.
- Inspect existing `PNC.WorldDiscovery.CallContact` and `WorldDiscovery.HandleAction` (`radio_scan`, `radio_ambient`, `call_contact`); reuse supported client/server API. **These actions may advance discovery phases and must not be falsely presented as actual live NPC chat.**
- Register an app/contact provider in Core for NPC/faction/settlement contacts, with clear capabilities and permission handling. If actual radio chatting is supported by verified Hoomans APIs, delegate to its authoritative conversation service; otherwise show disabled/no-response rather than invent dialogue.
- Preserve face-to-face NPC interactions and near-NPC trade/conversation rules. Core does not force a Hoomans encounter to use a radio shell.

### Dynamic Trading V2

- DTCommon owns MarketSense integration, trader service/stock/snapshots, V2 trade-window orchestration, quote and server-authoritative settlement. It registers a **trader app** and any shared trade contact presentation/provider into Core.
- DTAbstract registers the remote trader access adapter, scanner/discovery sources and radio action. It may trade without a spawned NPC only when the server validates abstract eligibility and actual required device/session rights.
- DTHoomans registers physical merchant-specific access; for in-person trade a real, available, nearby, authorized merchant NPC is mandatory, even if its contact is shown in the same Core UI. Guards only refer to the merchant.
- No Core dependency on DT services, no second stock/basket screen painted on the device. The Trade action calls the established DTCommon Client.OpenTrader flow with the server enforcing appropriate origin/access.
- A contact card does not authorize trade. Revalidate at snapshot, quote/action and settlement; never trust client-provided mode, NPC position or contact/merchant authority.

## Committed visual assets and migration plan

The six walkie PNGs were originally authored in `psychopatz/DynamicTrading` under `DTAbstract`. **The production copies, manifest, build tools and current Radio OS window are now Core-owned**; consult current `PsychopatzCore/42.20/media/ui/psychopatz/radio` and `PsychopatzCore/UI/Radio/OS` files rather than the historical source paths:
- DTA_Walkie_Shells.png — 1024×1024, 6 handheld skins; color-reduced approved artwork.
- DTA_Walkie_UI_Core.png — 1024×1024, 25 UI sprites.
- DTA_Walkie_Buttons.png — 1024×512, 36 button-state backgrounds.
- DTA_Walkie_Icons.png — 512×512, 32 icons.
- DTA_Walkie_Indicators.png — 512×256, 25 indicators.
- DTA_Walkie_Overlays.png — 512×512, 8 optional transparent effects.

**Migration status:** Core has production atlases and the six-skin manifest. Keep a thin DTAbstract compatibility shim only as needed. The next phase is **UI stabilization U0–U7**: ensure correct drag/resize/geometry/persistence/viewport layout/icons/clicks and actual in-game acceptance, not another atlas ownership migration.

Existing shell LCD openings range ~72–83 × 55–61 source pixels: a serious legibility and portrait constraint. Solve by measured uniform scaling, compact pagination/zoom or redesigned coordinated art/manifest—not stretching a finished shell or overflowing text. HAM/manpack/receive-only art does not yet exist as production atlases. Do not claim those device families are done; leave their extension hooks open.

## Security, scaling and testing

Core's device validator is a **shared mechanism**, not the server authority for a given game action. Each provider checks the authoritative player, radio instance, proximity, NPC/trader state, access mode, request identity/session and action at the server boundary; client UI cannot elevate permissions. Abstract trader flag `record.a == 1` currently bypasses physical proximity in DTCommon's access method and must be audited separately as part of Dynamic Trading integration.

SP and dedicated MP must behave consistently; provider-sensitive lists must not leak unknown NPC identities or traders. Prefer event-driven refresh and bounded caches. Cache textures and sprites; no per-tick global scans or repeated per-frame device/world lookups. Test Core alone; Core + Hoomans; Core + DTCommon/DTAbstract; Core + DTCommon/DTHoomans; combined installation; third-party dummy plugin; six walkie variants; native B42, SP, MP, responsiveness/portrait cost.

## Coordinated unattended goal

The up-to-date plan and pasteable Luna/Codex goal are in `psychopatz/DynamicTrading`:
`Docs/radio_os/DT_RADIO_OS_AGENT_RUNBOOK.md`,
`Docs/radio_os/DT_RADIO_OS_CONTRACT.md`,
`Docs/radio_os/DT_RADIO_OS_ROADMAP.md`,
`Docs/radio_os/DT_RADIO_OS_PROGRESS.md`,
and `RADIO_OS_GOAL_PROMPT.md`. This Core contract governs reusable framework ownership when implementation work touches Core. Keep those goal documents synchronized; do not allow Domain modules to own the shared UI.

## Current mandatory UI stabilization gate

Core Radio OS still derives its window from `ISPanel`, while existing Core window geometry/persistence/resize helpers are not integrated. The latest user screenshot demonstrates major functionality/UI problems. Before extending radio features, implement the ordered **U0–U7** milestones in [`CORE_RADIO_OS_UI_STABILIZATION.md`](CORE_RADIO_OS_UI_STABILIZATION.md). The initial foundation R0–R7 exists; reopen the renderer/window acceptance gate rather than rebuilding consumer integrations.

**Absolute testing prohibition:** the PZ Headless Harness is known broken and must not be used, installed, fixed, or considered as evidence. Use offline Lua/atlas tests plus **normal Project Zomboid gameplay** for native acceptance. If agent lacks game GUI capability, provide a single manual test handoff and leave native status pending.
