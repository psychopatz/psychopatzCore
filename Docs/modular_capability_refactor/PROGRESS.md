# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-02  
Parent status: **IN PROGRESS**  
Current phase: **P7 — Runtime-role split** (P0 through P6 complete)  
Verified Core revision: `1e9e273` on `main`, ahead of `origin/main` by 7 commits.

## Accepted P6 Evidence (Domain Capsule Refinement)

- **Unified Facade and Service Discovery**:
  - Implemented `PsychopatzCore/Kernel/PC_Services`: Exposes `Core.Services.Get(serviceName, consumerId)` for on-demand activation and facade retrieval; `Core.Services.Has(serviceName)` for status query; `Core.Services.ListActive()` for active capability enumeration.
  - Exposed `Core.Features = Core.Capabilities` as first-class alias.
  - Attached `Inventory.Constants` directly onto `PsychopatzCore.Inventory` facade, eliminating the need for adopters to reach into private internal file paths.
- **Automated Verification**:
  - `tests/psychopatz_services_smoke.lua` PASS: Proves `Services.Has` reflects activation state; `Services.Get` retrieves `Inventory` and `Currency` facades; facade exposes `Constants` without private require; `Features.Require` works identically to `Capabilities.Require`.
- **Zero Regressions**:
  - `PsychopatzCore`: 119 passed, 6 pre-existing baseline failures preserved.
  - `DynamicTrading`: 41/41 passed.
  - `ProjectHoomans`: 982/982 passed.
  - `tests/refactor_binding_smoke.py`: PASS with 0 leaks.

## Next Chunk — P7 Runtime-Role Split

Enforce runtime-role eligibility in the capability graph:
1. Validate capability activation under pure dedicated server role (`isServer=true, isClient=false`) and pure client role (`isClient=true, isServer=false`).
2. Ensure client-only capsules (`core.radio_os`, `core.debug_hub`, `core.input_keybinds`, `core.audio_settings`, `core.preview`) never load or activate in dedicated server environments.
3. Ensure server-only capsules (`core.currency_server`) never activate in client-only contexts.
4. Support role filtering in pack activation so packs can be safely requested anywhere without activating invalid role modules.
5. Create dedicated smoke test for runtime-role enforcement.

### P7 Acceptance Criteria
- Dedicated server role rejects client-only activation with actionable reason.
- Client role rejects server-only activation with actionable reason.
- Pack activation automatically filters out role-ineligible capabilities without crashing.
- All test suites continue to pass with 0 regressions.
