# PsychopatzCore Modular Capability & Composition Refactor — P0 Baseline

- Git Revision: `0d8367e60ff7741ebcc11b352ce91f0268132332`
- Scanned Core Files: 345
- Scanned Core Subsystems/Domains: 35
- Pre-refactor Tests: 120 passed / 7 failed (127 total)

## 1. Dynamic Boot Module Loads & Require-Time Callbacks

| Runtime Role | Success | Unique Modules Loaded | Require Edges | Require-Time Callbacks |
| --- | --- | --- | --- | --- |
| `shared` | True | 12 | 16 | 0 |
| `client` | False | 16 | 20 | 0 |
| `server` | True | 15 | 19 | 0 |

### Require-Time Callbacks Observed (Eager Side Effects)

| Role | Event | Registering Module | Attributed | Source Location |
| --- | --- | --- | --- | --- |

## 2. Dynamic Trading Capability Requirements Map

Dynamic Trading requires only a bounded subset of PsychopatzCore, confirming the need for demand-driven capability activation.

### Submodule `DTCommon` Direct Requires

| Required Core Module | Classification | Reference Locations |
| --- | --- | --- |
| `PsychopatzCore/Economy/PsychopatzCurrency` | Public Facade | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TraderService.lua:8` |
| `PsychopatzCore/Inventory/PsychopatzInventory` | Public Facade | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/00_DTCommon_Init.lua:6`, `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_SettlementExchangeCandidates.lua:9`, `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_Storage.lua:6` |
| `PsychopatzCore/Inventory/PsychopatzInventoryConstants` | Public Facade | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_SettlementExchangeCandidates.lua:10`, `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TraderService.lua:7` |

### Submodule `DTHoomans` Direct Requires

| Required Core Module | Classification | Reference Locations |
| --- | --- | --- |
| `PsychopatzCore/UI/PsychopatzDebugHubWindow` | Internal Implementation | `Contents/mods/DTHoomans/42.20/media/lua/client/DTHoomans/00_DTHoomans_Client_Init.lua:12` |

### Submodule `DTAbstract` PsychopatzCore Global Access

| PsychopatzCore Global Property | Reference Locations |
| --- | --- |
| `PsychopatzCore.RadioDeviceState` | `Contents/mods/DTAbstract/42.20/media/lua/client/DTAbstract/DTAbstract_Client.lua:6` |
| `PsychopatzCore.Require` | `Contents/mods/DTAbstract/42.20/media/lua/client/DTAbstract/00_DTAbstract_Client_Init.lua:1`, `Contents/mods/DTAbstract/42.20/media/lua/client/DTAbstract/00_DTAbstract_Client_Init.lua:2` |

### Submodule `DTCommon` PsychopatzCore Global Access

| PsychopatzCore Global Property | Reference Locations |
| --- | --- |
| `PsychopatzCore.Actors` | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_CoreActorPolicy.lua:226`, `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_CoreActorPolicy.lua:239`, `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_CoreActorPolicy.lua:240` |
| `PsychopatzCore.DebugSettings` | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TradeAudit.lua:241`, `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TradeAudit.lua:246` |
| `PsychopatzCore.RadioDeviceState` | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TraderService.lua:322` |
| `PsychopatzCore.RequirePack` | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/00_DTCommon_Init.lua:3`, `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/00_DTCommon_Init.lua:4` |
| `PsychopatzCore.RuntimeRole` | `Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_Storage.lua:18` |

### Submodule `DTHoomans` PsychopatzCore Global Access

| PsychopatzCore Global Property | Reference Locations |
| --- | --- |
| `PsychopatzCore.Conversation` | `Contents/mods/DTHoomans/42.20/media/lua/client/DTHoomans/DTHoomans_Client.lua:41`, `Contents/mods/DTHoomans/42.20/media/lua/client/DTHoomans/DTHoomans_Client.lua:42` |
| `PsychopatzCore.Debug` | `Contents/mods/DTHoomans/42.20/media/lua/client/DTHoomans/00_DTHoomans_Client_Init.lua:17` |
| `PsychopatzCore.DebugHub` | `Contents/mods/DTHoomans/42.20/media/lua/client/DTHoomans/00_DTHoomans_Client_Init.lua:15` |
| `PsychopatzCore.Require` | `Contents/mods/DTHoomans/42.20/media/lua/client/DTHoomans/00_DTHoomans_Client_Init.lua:9`, `Contents/mods/DTHoomans/42.20/media/lua/client/DTHoomans/00_DTHoomans_Client_Init.lua:10` |
| `PsychopatzCore.RuntimeRole` | `Contents/mods/DTHoomans/42.20/media/lua/server/DTHoomans/DTHoomans_CaravanLifecycle.lua:1`, `Contents/mods/DTHoomans/42.20/media/lua/server/DTHoomans/DTHoomans_CaravanLifecycle.lua:2`, `Contents/mods/DTHoomans/42.20/media/lua/server/DTHoomans/DTHoomans_CaravanService.lua:1` |
| `PsychopatzCore.Teleport` | `Contents/mods/DTHoomans/42.20/media/lua/server/DTHoomans/DTHoomans_Server.lua:459`, `Contents/mods/DTHoomans/42.20/media/lua/server/DTHoomans/DTHoomans_Server.lua:460` |

## 3. Pre-Refactor Test Suite Baseline

- Total tests: 127
- Passing tests: 120
- Pre-existing failing tests: 7

### Pre-Existing Test Failures (Preserved Baseline)

| Test File | Failure Reason |
| --- | --- |
| `tests/psychopatz_command_hub_callback_smoke.lua` | `lua: ...nt/PsychopatzCore/UI/Components/PsychopatzUIControls.lua:6: module 'PsychopatzCore/UI/Components/PsychopatzScrollPanel' not found:` |
| `tests/psychopatz_image_resolver_smoke.lua` | `lua: tests/psychopatz_image_resolver_smoke.lua:5: instance-item icon fallback resolves: expected=table: 0x5e78bccdb8c0 actual=nil` |
| `tests/psychopatz_label_layout_smoke.lua` | `lua: ...nt/PsychopatzCore/UI/Components/PsychopatzUIControls.lua:6: module 'PsychopatzCore/UI/Components/PsychopatzScrollPanel' not found:` |
| `tests/psychopatz_profiler_client_composition_smoke.lua` | `lua: ...hopatzCore/Compatibility/PsychopatzWalkieHotbarGuard.lua:1: module 'TimedActions/ISAttachItemHotbar' not found:` |
| `tests/psychopatz_profiler_server_composition_smoke.lua` | `lua: tests/psychopatz_profiler_server_composition_smoke.lua:3: server role did not start after server loading: expected=1 actual=0` |
| `tests/psychopatz_widget_window_smoke.lua` | `lua: tests/psychopatz_widget_window_smoke.lua:6: widget button follows resized title bar: expected=103 actual=83` |
| `tests/psychopatz_world_inventory_smoke.lua` | `lua: tests/psychopatz_world_inventory_smoke.lua:9: single-player teleport: expected=true actual=false` |

## 4. P0 Invariants Established

- Baseline instrumentation is reproducible via `python3 tools/refactor_baseline/record_baseline.py`.
- Core bootstraps dynamically exercise actual production composition paths.
- Every require-time event registration is attributed to its caller module.
- Dynamic Trading's requirements are grounded in source code with exact file and line mappings.
- No production behavior was altered in P0A.
