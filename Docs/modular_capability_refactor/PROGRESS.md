# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P3 — Dynamic Trading vertical slice** (P0, P1, and P2 complete)  
Verified Core revision: `064d25a` on `main`, ahead of `origin/main` by 3 commits.

## Accepted P2 Evidence (Composition Inversion)

- **Composition Roots Inverted**:
  - `PsychopatzCore/00_PsychopatzCore_Init.lua` and `PC_SharedComposition`: Boots minimal identity + RuntimeRole + Kernel, registering all capability descriptors. Broad domains (Actors, Currency, MoneyBundler, Diagnostics, Traits, etc.) are NO LONGER eagerly required at boot.
  - `00_PsychopatzCore_Client_Init.lua` and `PC_ClientComposition`: Removed eager requires of Keybinds, RadioOS, AudioSettings, SocialFlavorClient, MoneyBundlerAction, MoneyBundlerUI. Only engine-level walkie hotbar patch remains.
  - `00_PsychopatzCore_Server_Init.lua` and `PC_ServerComposition`: Removed eager requires of CurrencyServer and MoneyBundlerServer. Only documented engine-required MapObjects compatibility guard (`PsychopatzFeedingTroughGuard`) loads early.
- **Drastic Boot Load Reduction (Proven via baseline harness)**:
  - `shared`: Dropped from **123 modules** to **10 modules** (-91.8%).
  - `shared callbacks`: Dropped from **12 callbacks** to **0 callbacks** (-100%).
  - `client`: Dropped from **153 modules** to **89 modules** (-41.8%); recurring callbacks dropped.
- **On-Demand Facades & Compatibility**:
  - `Core.Require(capId, consumerId)` and `Core.RequirePack(packId, consumerId)` provide clean demand-driven activation.
  - `Core.RequireLegacySharedFull()` provides full capability activation for legacy suites.
  - On-demand metatable fallback ensures accessing `PsychopatzCore.<Feature>` lazily activates only the required capability and its declared dependencies.
- **Tests**:
  - `tests/psychopatz_core_composition_smoke.lua` PASS: Proves unrequested features remain unloaded on boot and activate cleanly on demand.
  - `tests/psychopatz_radio_frequencies_smoke.lua` PASS.
  - `tests/psychopatz_custom_radio_smoke.lua` PASS.
  - Overall test suite: 116 passed, 6 pre-existing failures preserved, 0 regressions (1 pre-existing failure fixed!).
  - `tests/refactor_binding_smoke.py` PASS.

## Next Chunk — P3 Dynamic Trading Vertical Slice

Prove demand-driven Core activation with representative configurations:
1. Core alone: verifies minimal kernel boot (10 modules, 0 shared callbacks).
2. Core + DTCommon: declares explicit requirement for `pack.trading_common` (or `core.inventory`, `core.currency`, `core.actors`, `core.conversation`, `core.runtime`, `core.debug`).
3. Core + DTCommon + DTAbstract: activates `core.radio_device_state` and `core.radio_os`.
4. Core + Hoomans without Dynamic Trading: activates full Hoomans requirements.
5. In all DT-only configurations, verify unrelated Core systems (`core.traits`, `core.zombie_kill_detector`, `core.animation`, `core.world_loot`, etc.) remain strictly UNREQUESTED, UNLOADED, and INACTIVE.
6. Verify and preserve unrelated user work in DynamicTrading (`DTHoomans_Conversation.lua`).

### P3 Acceptance Criteria
- Adopter capability declaration verified for DTCommon and DTAbstract.
- Harness mechanically asserts module and callback counts for each representative configuration.
- DT-only configurations prove unrelated capsules (Traits, ZombieKillDetector, Animation, WorldLoot) contribute zero modules and zero callbacks.
- Trading behavior and DT authority contracts remain unchanged.
- Unrelated user edits in DynamicTrading are untouched.
