# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P2 — Composition inversion** (P0 and P1 complete)  
Verified Core revision: `85fc009` on `main`, ahead of `origin/main` by 2 commits.

## Accepted P1 Evidence (Minimal Kernel)

- **Minimal Kernel Components Implemented**:
  - `PsychopatzCore/Kernel/PC_CapabilityRegistry`: Registers capability descriptors without loading implementation modules; tracks state transitions (`REGISTERED`, `LOADED`, `ACTIVE`, `DORMANT`, `FAILED`); consumer reference counting.
  - `PsychopatzCore/Kernel/PC_CapabilityResolver`: Resolves topological dependency closure; detects cycles with actionable error path; enforces role eligibility (client/server/shared).
  - `PsychopatzCore/Kernel/PC_CapabilityLifecycle`: Manages lazy `load()` and `activate()`; prevents redundant loading; coordinates `deactivate()` upon final consumer release.
  - `PsychopatzCore/Kernel/PC_Kernel`: Unified facade (`PsychopatzCore.Capabilities` and `Core.Kernel`) exposing `Require`, `RequirePack`, `Release`, `GetStatus`, `GetAllStatus`, `GetFacade`, `Register`, and `RegisterPack`.
- **Harness & Contract Validation**:
  - `tests/psychopatz_kernel_smoke.lua` PASS: Proves kernel boots with zero feature modules loaded and zero callbacks installed; validates topological load/activation ordering; multi-consumer refcounting (retaining ACTIVE until last consumer releases to DORMANT); cycle detection (rejecting A -> B -> C -> A); and role eligibility enforcement.
  - `tests/refactor_binding_smoke.py` PASS: Zero private helper leaks.
  - Regression test suite: 115 passed, 7 pre-existing failures preserved, 0 regressions.

## Next Chunk — P2 Composition Inversion

Invert Core's shared, client, and server root bootstraps so they initialize the minimal kernel rather than eagerly requiring broad feature groups.
1. `PC_SharedComposition`:
   - Initialize identity and kernel.
   - Register capability descriptors/catalog.
   - Do NOT eagerly require Actors, MoneyWeight, CurrencyCategory, Currency, MoneyBundler, Diagnostics, Radio, Traits, etc.
   - Maintain backward compatibility: if `PsychopatzCore.RequireLegacySharedFull()` is called or if a legacy config requests it, activate `pack.core_legacy_full`.
2. `00_PsychopatzCore_Client_Init` & `PC_ClientComposition`:
   - Do not eagerly require Keybinds, RadioOS, AudioSettings, SocialFlavorClient, WalkieHotbarGuard, MoneyBundlerAction, MoneyBundlerUI.
   - Register client capability descriptors.
3. `00_PsychopatzCore_Server_Init` & `PC_ServerComposition`:
   - Do not eagerly require CurrencyServer, MoneyBundlerServer.
   - Register server capability descriptors.
   - Preserve MapObjects sprite/chunk compatibility guards required by the engine at boot.
4. Verify dynamic load reduction via `baseline_harness.lua` and update tests.

### P2 Acceptance Criteria
- Shared root boot loads ONLY kernel + identity foundation, not broad feature capsules.
- Dynamic modules loaded on bare Core boot drops drastically (target: < 25 modules vs 123 in P0).
- Eager require-time callbacks on bare Core boot drops to 0 (except engine-required early hooks).
- Any capability requested on-demand loads cleanly and provides its facade.
