# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P9 — Adopter migration** (P0 through P8 complete)  
Verified Core revision: `70da832` on `main`, ahead of `origin/main` by 9 commits.

## Accepted P8 Evidence (Diagnostics and Harness)

- **Mechanically Inspectable Capability Diagnostics**:
  - Implemented `PsychopatzCore/Kernel/PC_CapabilityDiagnostics`:
    - `Report()`: Returns structured system-wide diagnostic dictionary containing all capability IDs, domains, lifecycle states, declared roles, declared dependencies, total consumer counts, individual consumer lists, and failure reasons.
    - `Explain(capId)`: Formats clear human/agent-readable explanation of capability status, consumer attribution, and dependency path.
    - `AssertActive(capId, consumerId)`: Asserts capability is ACTIVE and held by the given consumer.
    - `AssertRegistered(capId)`: Asserts capability is REGISTERED (dormant/unloaded with 0 consumers).
    - `AssertFailed(capId)`: Asserts capability failure state.
  - Wired into `Core.Capabilities.Report()`, `Core.Capabilities.Explain()`, `Core.Capabilities.Diagnostics`.
- **Automated Verification**:
  - `tests/psychopatz_diagnostics_smoke.lua` PASS: Validates unrequested capability explanation (0 consumers, REGISTERED), active capability explanation (reflecting consumer attribution), and assertion helpers.
- **Zero Regressions**:
  - `PsychopatzCore`: 121 passed, 6 pre-existing baseline failures preserved.
  - `DynamicTrading`: 41/41 passed.
  - `ProjectHoomans`: 982/982 passed.

## Next Chunk — P9 Adopter Migration

Migrate adopters to use explicit capability requirements rather than accidental eager loading:
1. Re-audit DynamicTrading worktree to ensure user's edit in `DTHoomans_Conversation.lua` remains untouched.
2. In `DTCommon` (`00_DTCommon_Init.lua`): Explicitly require `pack.trading_common`.
3. In `DTAbstract` (`00_DTAbstract_Client_Init.lua`): Explicitly require `core.radio_os`.
4. In `DTHoomans` (`00_DTHoomans_Client_Init.lua`): Explicitly require `core.debug_hub`.
5. Run full DynamicTrading and ProjectHoomans test suites.

### P9 Acceptance Criteria
- Adopters declare explicit capability requirements at their composition entry points.
- Zero reliance on accidental global eager loading.
- Unrelated user edits in `DTHoomans_Conversation.lua` remain 100% preserved.
- All test suites across all repositories pass with 0 regressions.
