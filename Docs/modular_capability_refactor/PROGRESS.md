# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P8 — Diagnostics and harness** (P0 through P7 complete)  
Verified Core revision: `c4d3961` on `main`, ahead of `origin/main` by 8 commits.

## Accepted P7 Evidence (Runtime-Role Split)

- **Role Eligibility Enforcement in Capability Graph**:
  - `PC_CapabilityResolver.ResolveClosure`: Enforces declared `desc.roles` constraints against active runtime roles (`isClient`, `isServer`, singleplayer).
  - Dedicated server rejects direct requests for client-only capabilities (`core.radio_os`, `core.preview`, `core.debug_hub`, `core.input_keybinds`, `core.audio_settings`) with actionable diagnostic error.
  - Client context rejects direct requests for server-only capabilities (`core.currency_server`) with actionable diagnostic error.
  - `PC_CapabilityResolver.ResolvePackClosure`: Filters capability packs by active runtime role, allowing multi-role packs (e.g. `pack.trading_abstract`) to activate safely on dedicated server without requiring client UI capsules.
- **Automated Verification**:
  - `tests/psychopatz_runtime_role_split_smoke.lua` PASS: Asserts server-only failure on client, client-only failure on server, and role-filtered pack activation on dedicated server.
- **Zero Regressions**:
  - `PsychopatzCore`: 120 passed, 6 pre-existing baseline failures preserved.
  - `DynamicTrading`: 41/41 passed.
  - `ProjectHoomans`: 982/982 passed.

## Next Chunk — P8 Diagnostics and Harness

Implement inspectable capability diagnostics and mechanical assertion harness:
1. `PsychopatzCore/Kernel/PC_CapabilityDiagnostics`:
   - `Report()`: Returns complete structured dictionary of all capability states, consumers, dependency reasons, and role eligibility.
   - `Explain(capId)`: Returns human-readable diagnostic explanation of why a capability is loaded/active/dormant/failed and who requested it.
   - `AssertActive(capId, consumerId)`, `AssertRegistered(capId)`, `AssertUnloaded(capId)`: Reusable assertion helpers for tests and debug inspection.
2. Wire diagnostics into `Core.Diagnostics` and `Core.Capabilities.Diagnostics`.
3. Create dedicated smoke test for diagnostic reporting and assertions.

### P8 Acceptance Criteria
- Diagnostics answer: who requested a feature, why it loaded, current state, and failure reasons.
- Diagnostic assertions verify active vs dormant vs unrequested capabilities.
- All test suites continue to pass with 0 regressions.
