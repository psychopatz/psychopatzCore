# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P5 — Dependency-cycle elimination** (P0, P1, P2, P3, and P4 complete)  
Verified Core revision: `a431005` on `main`, ahead of `origin/main` by 5 commits.

## Accepted P4 Evidence (Event & Lifecycle Ownership)

- **Lifecycle Ownership Enforced**:
  - `PsychopatzTraitRecovery`: Implemented `Recovery.Uninstall()` and encapsulated `Recovery.Install()` within the `core.traits` capability lifecycle. When unrequested, traits contribute ZERO callbacks to `Events.OnPlayerUpdate` or `Events.OnCreatePlayer`.
  - `PsychopatzKeybinds`: Encapsulated into `Keybinds.Install()` and `Keybinds.Uninstall()`, attached to `core.input_keybinds` activation/deactivation. When unrequested, contributes ZERO callbacks to `Events.OnTick` or `Events.OnGameBoot`.
  - Type-safe callback invocation (`type(...) == "table"`) prevents errors when modules are stubbed or preloaded in testing.
- **Automated Lifecycle Verification**:
  - `tests/psychopatz_lifecycle_smoke.lua` PASS: Asserts 0 listeners initially on `OnPlayerUpdate`, `OnCreatePlayer`, and `OnTick`; confirms listeners are attached upon capability activation; verifies all listeners are cleanly detached upon deactivation.
- **Zero Regressions Across All Repositories**:
  - `PsychopatzCore`: 118 passed, 6 pre-existing baseline failures preserved.
  - `DynamicTrading`: 41/41 passed (`PASS 41/41`).
  - `ProjectHoomans`: 982/982 passed (`PASS 982/982`).
  - `tests/refactor_binding_smoke.py`: PASS with 0 leaks.

## Next Chunk — P5 Dependency-Cycle Elimination

Audit and eliminate composition-driven dependency cycles in PsychopatzCore:
1. Re-scan codebase using architecture tooling to measure cycle findings against the initial audit (42 cycle findings at baseline).
2. Composition inversion (P2) already decoupled the major cycle where `00_PsychopatzCore_Init` -> `PC_SharedComposition` -> `PC_SharedFeatures` -> `PC_SharedFeatures_Diagnostics` -> `PsychopatzDebug` -> `00_PsychopatzCore_Init`.
3. Check and decouple remaining cycles:
   - Currency <-> MoneyBundler <-> CurrencyServer
   - RadioOS <-> DeviceManifest <-> RadioImageAnimation
   - Conversation <-> Semantic <-> PersonaKnowledge
4. Ensure the Capability Resolver strictly rejects any new cycles with actionable diagnostics.
5. Record architecture rescan report.

### P5 Acceptance Criteria
- Architecture analyzer rescan confirms elimination or containment of composition-driven cycles.
- Resolver cycle detection verified under complex graph structures.
- All test suites continue to pass with 0 regressions.
