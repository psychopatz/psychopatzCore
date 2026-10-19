# Core NPC Foundation — Ordered Roadmap

Status snapshot: 2026-10-20. P0A–P7 have accepted developer-side
source/harness evidence. P8 is next; P9 includes explicit user-run live-game
acceptance. The P2 physical-body gate remains part of P8.

| Phase | Status | Mandatory exit gate |
| --- | --- | --- |
| P0A Extraction audit | ACCEPTED | Ownership matrix, risk register, executable parity baseline |
| P0B Canonical schema and safe migration | ACCEPTED | No-loss supported save/load and fail-closed reversible import contract |
| P1 Core identity and appearance | ACCEPTED | Core-only Create → Save → Reload → Get; stable identity and no PNC/DT dependency |
| P2 Portable personal inventory | ACCEPTED; body gate P8 | Stable item IDs/state and no merchant-stock ownership |
| P3 Legacy migration | ACCEPTED | Idempotent import, conflict quarantine, rollback/retry, source untouched |
| P4 Shared social | ACCEPTED | Directed state preserved and authorized events cannot double-apply |
| P5 Generic tasks, journeys, anchors | ACCEPTED | Bounded task/scheduler state and journey arrival survive save/reload once |
| P6 Map and interaction systems | ACCEPTED | Knowledge-gated map/portrait/Talk/notification contracts coexist with UI providers |
| P7 DynamicTrading merchant policies | ACCEPTED | Separate DT stock/budget, earned restock, capped social pricing, authoritative fulfillment |
| P8 Provider switching and Hoomans physical adapter | NEXT | Stable state across DTAbstract/DTHoomans switching with one body lease |
| P9 End-to-end developer acceptance | OPEN | Module matrix, old saves, authority/reconnect/performance evidence plus user-run SP/MP |

## Compatibility matrix

Core+DTCommon+DTAbstract without Hoomans; Core+DTCommon+Hoomans+DTHoomans
without DTAbstract; both frontends; Core+DTCommon alone; Hoomans without DT;
save/restart switching; and dedicated MP with two clients and reconnect.

## Explicit non-goals

No Workshop publishing, destructive user save reset, unrelated subsystem
refactor, synthetic-only graphical UI claim, or duplication in Core of DT stock/
budget or Hoomans needs/combat/colony/mobile-director ownership.
