# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P6 — Domain capsule refinement** (P0 through P5 complete)  
Verified Core revision: `018e9f7` on `main`, ahead of `origin/main` by 6 commits.

## Accepted P5 Evidence (Dependency-Cycle Elimination)

- **Architecture Rescan Confirms Complete Elimination of Cycles**:
  - Re-scanned with `skills/architecture-audit/architecture_audit.py`.
  - **Dependency Cycles**: Dropped from **42 findings** at baseline to **0 findings** (100% eliminated).
  - **Production Findings**: Dropped from **54** to **5**.
  - **Refactor Pressure**: Dropped from **100.0/100** (critical) to **16.7/100** (healthy).
  - **Production Health**: Reached **93.0 / 100**.
- **Resolver Cycle Rejection**:
  - `PC_CapabilityResolver` performs DFS cycle detection with permanent/temporary markers.
  - Verified by `tests/psychopatz_kernel_smoke.lua` rejecting cyclic graphs (`cycle.a -> cycle.b -> cycle.c -> cycle.a`) with explicit diagnostics.
- **Zero Regressions Across All Repositories**:
  - `PsychopatzCore`: 118 passed, 6 pre-existing baseline failures preserved.
  - `DynamicTrading`: 41/41 passed.
  - `ProjectHoomans`: 982/982 passed.

## Next Chunk — P6 Domain Capsule Refinement

Refine domain capsules and stable public facades:
1. Ensure adopters access stable public facades (`Core.Inventory`, `Core.Currency`, `Core.Actors`, `Core.Conversation`, `Core.Translation`, `Core.Debug`, `Core.RadioOS`) rather than internal implementation paths.
2. In P0 audit, `DTCommon` and `DTHoomans` had direct requires to:
   - `PsychopatzCore/Inventory/PsychopatzInventory`
   - `PsychopatzCore/Inventory/PsychopatzInventoryConstants`
   - `PsychopatzCore/Economy/PsychopatzCurrency`
   - `PsychopatzCore/UI/Radio/OS/PsychopatzRadioRuntimeManifest`
   - `PsychopatzCore/UI/PsychopatzDebugHubWindow`
3. Provide stable, documented facade exports and service lookups (`Core.Services.Get` / `Core.Capabilities.GetFacade`) so future adopters do not couple to internal file organization.
4. Keep healthy implementations intact without unnecessary file splitting or abstraction chains.

### P6 Acceptance Criteria
- Stable facades provide complete access to all domain capabilities without requiring adopters to reach into private internal files.
- Service accessor `Core.Services.Get(serviceName)` provides clean access to active facades.
- All test suites continue to pass with 0 regressions.
