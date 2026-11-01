# PsychopatzCore Modular Capability & Composition Refactor — Progress

Snapshot: 2026-11-01  
Parent status: **IN PROGRESS**  
Current phase: **P0 — Baseline and dependency inventory**  
Verified Core revision at planning time: `c01daef545fe5a9d2742186eca2bc0aa911f99cc` on `main`, equal to `origin/main`.

## Accepted starting evidence

- Root `AGENTS.md` is already lean and durable; no change is needed for this goal.
- Existing Composition files provide useful boundaries but still eagerly require broad shared/client/server feature sets.
- Checked-in architecture audit reports 307 production files, 46,319 scored production LOC, 30 logical subsystems, 54 production findings and 42 dependency-cycle findings; Composition/root composition and UI are the highest-pressure areas.
- Source scan found 29 Core Lua files containing PZ event-hook registration surfaces; require-time/lifecycle ownership must be baselined before migration.
- Dynamic Trading consumes a bounded but nontrivial subset of Core and is the first adopter proof target.
- Individual systems such as Voice and Profiler already demonstrate useful opt-in/dormant patterns worth preserving rather than rewriting blindly.

## Immediate Next Chunk — P0A Baseline instrumentation and contracts

Create a read-only, repeatable developer baseline that records for representative configurations:

1. modules loaded by the Core shared/client/server roots
2. feature/domain-to-feature dependency edges
3. require-time event/callback/resource registrations
4. runtime-role eligibility
5. adopter imports of Core public versus internal implementation paths
6. Dynamic Trading's current Core capability requirements

Prefer reusable test/harness instrumentation over a hand-maintained snapshot.

### P0A acceptance

- no production behavior changes
- focused baseline tests execute against actual Core bootstrap/composition modules
- output identifies why a module/callback is present, or explicitly marks attribution unknown for later resolution
- Dynamic Trading capability map is source-backed
- current test baseline is recorded
- `PROGRESS.md` is updated with evidence and the next P0 chunk

After P0A passes, continue automatically through the remaining P0 outputs and then P1-P10. Do not return control merely because P0A or P0 completes.

## Remaining mandatory gap

The minimal kernel, feature registry/resolver, composition inversion, Dynamic Trading pilot, lifecycle migration, cycle removal, domain refinement, runtime-role enforcement, diagnostics, adopter migration and final developer acceptance are all still unimplemented for this goal.

Native PZ SP/MP validation remains user-owned after developer-side completion.
