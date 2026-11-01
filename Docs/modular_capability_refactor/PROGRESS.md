# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P4 — Event and lifecycle ownership** (P0, P1, P2, and P3 complete)  
Verified Core revision: `13ca5a6` on `main`, ahead of `origin/main` by 4 commits.

## Accepted P3 Evidence (Dynamic Trading Vertical Slice)

- **Five Representative Configurations Proven**:
  - `tests/psychopatz_dt_slice_smoke.lua` mechanically verifies all 5 configurations in isolated execution contexts:
    1. **Core alone**: Kernel boots with 10 modules, 0 require-time callbacks; unrelated feature capsules remain unrequested, unloaded, and inactive.
    2. **Core + DTCommon**: Activates only required capability closure (`core.inventory`, `core.currency`, `core.actors`, `core.conversation`, `core.runtime`, `core.debug`). Unrelated systems (`core.traits`, `core.zombie_kill_detector`, `core.animation`, `core.world_loot`, `core.radio_os`) remain strictly UNLOADED.
    3. **Core + DTCommon + DTAbstract**: Activates `core.radio_device_state` without activating unrequested Traits, ZombieKillDetector, Animation, or WorldLoot.
    4. **Core + Hoomans without Dynamic Trading**: Activates Hoomans capabilities while DTCommon and DTAbstract remain completely unrequired and unloaded.
    5. **Core + DTCommon + Hoomans + DTHoomans**: Activates the combined integration smoothly with full capability resolution.
- **Adopter Suites Pass Cleanly**:
  - `DynamicTrading`: 41/41 tests passing (`PASS 41/41`).
  - `ProjectHoomans`: 982/982 tests passing (`PASS 982/982`).
  - `PsychopatzCore`: 117 passed, 6 pre-existing baseline failures preserved, 0 regressions.
- **Git Worktree Safety**:
  - User's unrelated local edit in `DynamicTrading/Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua` preserved intact.
  - Zero branches created; main-only discipline maintained.

## Next Chunk — P4 Event and Lifecycle Ownership

Migrate features so they encapsulate and own activation/deactivation of their runtime callbacks and resources:
1. Ensure migrated capabilities encapsulate their `Events.*.Add` within explicit `activate(context)` and `deactivate(context)` lifecycles rather than firing side effects on `require`.
2. Specifically audit and encapsulate:
   - `core.traits` (`PsychopatzTraitRecovery.lua`: `OnCreatePlayer`, `OnPlayerUpdate`)
   - `core.currency` (`PsychopatzMoneyBundler.lua`: `OnGameBoot`, `OnGameStart`; `PsychopatzMoneyWeight.lua`: `OnGameBoot`, `OnGameStart`; `PsychopatzCurrencyCategory.lua`: `OnGameBoot`, `OnGameStart`, `OnCreatePlayer`)
   - `core.zombie_kill_detector` (`PsychopatzZombieKillDetector.lua`: `OnZombieDead`)
   - `core.input_keybinds` (`PsychopatzKeybinds.lua`: `OnTick`, `OnGameBoot`)
   - `core.radio_os` (`PsychopatzRadioOSLifecycle.lua`: `OnTick`)
3. Guarantee invariant: unrequested features contribute ZERO recurring runtime callbacks, and active features cleanly manage their lifecycle resources.

### P4 Acceptance Criteria
- Require-time side-effects for migrated features moved behind lifecycle `activate()` methods.
- Dynamic baseline harness shows 0 callbacks registered at `require` time for these features until explicitly activated.
- Activation attaches the callbacks; deactivation detaches them when supported.
- All test suites continue to pass with 0 regressions.
