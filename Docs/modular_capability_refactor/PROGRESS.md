# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P1 — Minimal kernel** (P0 complete)  
Verified Core revision: `c01daef545fe5a9d2742186eca2bc0aa911f99cc` on `main`, equal to `origin/main`.

## Accepted P0 Evidence (Baseline and Dependency Inventory)

- **Dynamic Baseline Harness**: `tools/refactor_baseline/baseline_harness.lua` & `record_baseline.py` dynamically execute and instrument Core bootstraps without modifying production behavior.
  - `shared`: 123 modules loaded, 243 require edges, 12 callbacks attributed.
  - `client`: 153 modules loaded, 284 require edges, 16 callbacks attributed (including OnTick from Keybinds and RadioOS).
  - `server`: 128 modules loaded, 254 require edges, 13 callbacks attributed.
- **Require-Time Callback Attribution**: All 12 require-time callbacks on shared boot attributed to registering modules:
  - `PsychopatzCustomTranslationManager` -> `OnGameBoot`
  - `PsychopatzInventory` -> `OnInitGlobalModData`
  - `PsychopatzMoneyWeight` -> `OnGameBoot`, `OnGameStart`
  - `PsychopatzCurrencyCategory` -> `OnGameBoot`, `OnGameStart`, `OnCreatePlayer`
  - `PsychopatzMoneyBundler` -> `OnGameBoot`, `OnGameStart`
  - `PsychopatzTraitRegistry` -> `OnGameBoot`
  - `PsychopatzTraitRecovery` -> `OnCreatePlayer`, `OnPlayerUpdate` (recurring player tick)
- **Capability Contracts & Catalog**:
  - `PsychopatzCore/Kernel/PC_CapabilityContract`: Validates capability descriptors (`id`, `domain`, `roles`, `depends`, `load`, `activate`, `deactivate`, `facade`) and capability packs.
  - `PsychopatzCore/Kernel/PC_CapabilityCatalog`: 28 capability descriptors and 4 adopter packs (`pack.trading_common`, `pack.trading_abstract`, `pack.trading_hoomans`, `pack.core_legacy_full`).
- **Dynamic Trading Source-Backed Capability Map**:
  - `DTCommon`: Inventory, InventoryConstants, Currency (requires); Actors, DebugSettings, RadioDeviceState, RuntimeRole (globals).
  - `DTAbstract`: RadioRuntimeManifest (requires); RadioDeviceState (globals).
  - `DTHoomans`: DebugHubWindow (requires); Conversation, Debug, DebugHub, RuntimeRole, Teleport (globals).
- **Test Suite Baseline**:
  - 121 total tests, 114 passed, 7 pre-existing failures preserved, 0 regressions.
  - `tests/psychopatz_baseline_smoke.lua` PASS.
  - `tests/psychopatz_capability_contract_smoke.lua` PASS.
- Machine-readable artifact `Docs/modular_capability_refactor/P0_BASELINE.json` and human-readable `Docs/modular_capability_refactor/P0_BASELINE.md` generated.

## Next Chunk — P1 Minimal Kernel

Implement the minimal Core Kernel:
1. `PC_CapabilityRegistry`:
   - Registers capability descriptors without loading their implementation modules.
   - Registers capability packs.
   - Tracks lifecycle states (`REGISTERED`, `LOADED`, `ACTIVE`, `DORMANT`, `FAILED`).
   - Consumer reference counting (`consumers[consumerId] = count`).
2. `PC_CapabilityResolver`:
   - Resolves transitive dependency closure for requested capabilities.
   - Detects dependency cycles and reports actionable cycle paths.
   - Enforces runtime-role eligibility (client vs server vs shared).
3. `PC_CapabilityLifecycle`:
   - Coordinates lazy loading (`load()`) and activation (`activate()`).
   - Ensures implementation modules are required only once upon demand.
   - Manages reference counts and deactivation (`deactivate()`) when all consumers release.
4. `PC_Kernel`:
   - Exposes clean public Core API: `Core.Capabilities.Require(capId, consumerId)`, `Core.Capabilities.RequirePack(packId, consumerId)`, `Core.Capabilities.GetStatus()`, `Core.Capabilities.Release(capId, consumerId)`.
5. Harness verification:
   - Smoke test proving kernel boots with zero feature modules loaded and zero callbacks installed.
   - Smoke test verifying dependency closure, role filtering, and cycle detection.

### P1 Acceptance Criteria
- Kernel boots independently with only RuntimeRole / registry / resolver / lifecycle / diagnostics.
- Registered capabilities do NOT load feature implementation files until requested.
- Dependency closure resolves dependencies in topological order.
- Unknown dependency or cycle produces clear diagnostic error.
- Role mismatch prevents activation with actionable reason.
