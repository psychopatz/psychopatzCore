# Core NPC Foundation — Ordered Roadmap

Snapshot: 2026-10-20. P0A–P9 developer-implementable requirements have accepted source/harness evidence. Status: READY FOR USER LIVE TEST.

| Phase | Status | Mandatory exit gate |
| --- | --- | --- |
| P0A Extraction audit | ACCEPTED | Ownership matrix, risk register, executable parity baseline |
| P0B Canonical schema and safe migration | ACCEPTED | No-loss supported save/load, fail-closed, reversible import contract |
| P1 Core identity and appearance | ACCEPTED | Core-only actor Create → Save → Reload → Get with stable identity, voice, appearance, policy, and duplicate rejection |
| P2 Portable NPC inventory | ACCEPTED | Deterministic starter equipment, slots, seed/delta persistence, and exact item-state restoration |
| P3 Legacy migration | ACCEPTED | Non-destructive, idempotent, ownership-validated Hoomans conversion with rollback |
| P4 Shared social system | ACCEPTED | Authoritative directional relationships, bounded personality/memories, and event integration |
| P5 Tasks and journeys | ACCEPTED | Bounded scheduling, anchors, abstract travel, and save/reload continuity |
| P6 Map and interaction | ACCEPTED | Core map/portrait/nearby conversation/notification contracts coexist with existing UI |
| P7 DynamicTrading integration | ACCEPTED | Separate merchant stock/budget, availability, restocking, relationship pricing, and authoritative fulfillment |
| P8 Provider switching and Hoomans integration | ACCEPTED | DTAbstract/DTHoomans adapters preserve canonical state and enforce one-body lease ownership |
| P9 End-to-end developer acceptance | ACCEPTED — READY FOR USER LIVE TEST | Four configuration modes, old saves, authority/reconnect boundaries, continuity, bounded work, and compatibility evidence |

## User-owned live matrix

Core-only; Core + DTCommon + DTAbstract; Core + DTCommon + Hoomans + DTHoomans; both provider frontends; Core + DTCommon alone; Hoomans without DT; save/restart provider switching; and a dedicated multiplayer authority/reconnect harness.

## Explicit non-goals

No Workshop publishing, destructive save reset, unrelated subsystem refactor, synthetic-only graphical UI claim, or duplication in Core of DT stock/budget or Hoomans needs, combat, colony, faction, and body-lifecycle ownership.
