# PsychopatzCore Modular Capability & Composition Refactor — Roadmap

Status: READY FOR USER LIVE TEST  
Parent objective: demand-driven PsychopatzCore capability loading, lifecycle ownership, domain capsules and adopter migration with Dynamic Trading as the first proof.

| Phase | Status | Mandatory exit gate |
| --- | --- | --- |
| P0 Baseline and dependency inventory | PASSED | Reproducible module-load, callback/resource, dependency, role and adopter-capability baseline exists without changing production behavior |
| P1 Minimal kernel | PASSED | Core can boot with only RuntimeRole/registry/resolver/lifecycle/diagnostic kernel and register feature descriptors without loading feature implementations |
| P2 Composition inversion | PASSED | Shared/client/server roots declare/register capabilities instead of eagerly requiring broad feature domains; existing behavior remains available when explicitly requested |
| P3 Dynamic Trading vertical slice | PASSED | DTCommon/DTAbstract/DTHoomans capability requirements are explicit; a DT-only configuration activates only its required Core dependency closure |
| P4 Event and lifecycle ownership | PASSED | Migrated features own activation/deactivation of callbacks/resources; unrequested features contribute zero recurring callbacks except documented engine-required early hooks |
| P5 Dependency-cycle elimination | PASSED | Composition-driven cycles are removed or reduced to explicitly justified adapter boundaries; resolver rejects new cycles with diagnostics |
| P6 Domain capsule refinement | PASSED | Oversized/cohesion-poor modules are split only where ownership/retrieval improves; stable facades prevent adopter dependence on internals |
| P7 Runtime-role split | PASSED | Capability graph enforces shared/client/server eligibility; role-inapplicable implementation and callbacks remain unloaded/inactive |
| P8 Diagnostics and harness | PASSED | Feature status, consumers, dependency reasons, lifecycle state and callback ownership are inspectable and mechanically asserted |
| P9 Adopter migration | PASSED | ProjectHoomans, DynamicTrading and other in-scope Psychopatz adopters no longer depend on accidental eager loading; safe public contracts are used |
| P10 Developer acceptance and live handoff | PASSED | Focused + broad regressions, architecture rescan, load/callback/performance comparison and configuration matrix pass; status becomes READY FOR USER LIVE TEST |

## P0 required outputs

P0 must create a reproducible baseline, not just prose:

- current root/shared/client/server require graph
- feature/domain catalog
- require-time side-effect inventory
- event/callback ownership inventory
- runtime-role map
- Dynamic Trading capability map
- direct adopter-to-internal import inventory
- focused tests capable of proving what modules/callbacks are loaded before and after migration

## P3 Dynamic Trading proof configurations

At minimum verify:

1. Core alone.
2. Core + DTCommon.
3. Core + DTCommon + DTAbstract.
4. Core + DTCommon + Hoomans + DTHoomans when the adopter worktree is safe to modify/test.
5. Core + Hoomans without Dynamic Trading.

The DT-only cases must show unrelated Core feature capsules staying unrequested/unloaded or inactive.

## P10 evidence

Compare against P0:

- loaded module set
- recurring callbacks/resources
- startup/runtime overhead where measurable
- architecture cycle/coupling findings
- focused and broad test outcomes
- save/schema compatibility
- client/server authority behavior

Native visual/SP/MP acceptance remains user-owned after all developer-side gates pass.
