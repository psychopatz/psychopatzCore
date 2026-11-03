# Core NPC Foundation — Ordered Roadmap

Snapshot: 2026-11-03.

The earlier 2026-10-20 headless P1–P9 acceptance remains useful historical evidence, but the parent goal is **REOPENED for map/presentation integration recovery** after native/source audit exposed a contract violation.

| Phase | Current status | Mandatory exit gate |
| --- | --- | --- |
| P0A Extraction audit | ACCEPTED FOUNDATION | ownership matrix/risk baseline retained |
| P0B Canonical schema/migration | ACCEPTED FOUNDATION | no-loss/reversible contract retained |
| P1 Identity/appearance | ACCEPTED | no regression |
| P2 Portable inventory | ACCEPTED | no regression |
| P3 Legacy migration | ACCEPTED | no regression |
| P4 Shared social | ACCEPTED | no regression |
| P5 Tasks/journeys | ACCEPTED | projected-position follow-up already added |
| P6 Map/interaction | **REOPENED** | one Core production map host; Hoomans/DT register through it; no duplicate adopter `ISWorldMap` hooks; authoritative client presentation projection |
| P7 DynamicTrading integration | PARTIAL FOLLOW-UP | DT economics preserved; DTAbstract presentation/persistence integration must use the repaired Core seams |
| P8 Provider switching/Hoomans | **REOPENED FOLLOW-UP** | production orchestration, not only adapter compatibility |
| P9 End-to-end acceptance | **REOPENED** | split client/server, production persistence, Core map host, cross-adopter regression all green before native handoff |

## Active recovery sequence

### C1 — Generic Core map host
- one deterministic vanilla map hook;
- ordered overlay register/unregister;
- generic map tool/toolbar seam if required;
- load-order safe;
- consumer failure isolation.

### C2 — Migrate adopters
- Hoomans generic map host/toolbar responsibilities register through Core;
- Hoomans-specific layers/policy stay in Hoomans;
- DTAbstract registers through Core;
- remove duplicate active map monkey patches.

### C3 — Actor presentation sync
- bounded authority→client actor/world projection;
- revisioned/stale-safe;
- reconnect/full resync;
- map/debug/discovery consume client projection.

### C4 — Production persistence
- wire real Core actor registry save/load lifecycle;
- preserve journey/provider state;
- deterministic missing-link recovery.

### C5 — Provider orchestration
- production DTAbstract↔DTHoomans transition policy;
- same actor, one body, no duplicate stock/arrival.

### C6 — Cross-repository acceptance
- Core/Hoomans/DT/DTHoomans regression;
- no duplicate map hooks;
- split client/server acceptance;
- production persistence evidence;
- then native user-owned matrix.

## Completion rule

Do not return to **READY FOR USER LIVE TEST** until C1–C6 developer gates pass.

The earlier headless evidence remains historical foundation, not current completion proof.
