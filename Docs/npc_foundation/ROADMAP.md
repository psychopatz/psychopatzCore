# Core NPC Foundation — Ordered Roadmap

Status: newly approved planning goal; NONE of P0–P9 accepted yet. Every phase needs code-path evidence plus its specific tests, not just documentation or mocked schemas. One bounded Next Chunk at a time. Existing DT MVP T6 acceptance stays OPEN separately.

| Phase | Work | Mandatory exit gate |
| --- | --- | --- |
| P0 Extraction ledger and migration contract | Trace actual creators, normalized schemas, inventory and social persistence, map hooks, DT access and load order; baseline regression tests | Field-level source-to-target ownership table, missing-state/legacy-version policy, executable parity baseline, no silent-loss path |
| P1 Core factory and actor registry | Single authoritative identity generator, stable ID/seed, resolved name/gender/voice/appearance, extension contracts | Core-only NPC created, saved/reloaded, identical without PNC or duplicate IDs |
| P2 Portable NPC personal inventory | Deterministic starter clothes/gear/bags plus exact portable items, worn/equipped slots, seed + deltas/full fallback | Same item IDs/state across regen-free save/load and body round trip; no duplication |
| P3 Legacy import and compatibility | Read/validate Hoomans legacy data before its exact-version reset; map identities and domains; wrappers | Non-destructive idempotent import, rollback/retry, old untouched during staged validation |
| P4 Shared social | Core directional Approval/Respect/Familiarity/personality/memories, event validators and revisioned reads | Existing Hoomans social state and player-character keys preserved, no double event credit |
| P5 Generic agent/journey/anchors | Bounded scheduler/behavior registration; location discovery, settlement anchors, A-to-B journeys | DT-only merchant travels, arrives exactly once and resumes across restart; no Hoomans mobile director |
| P6 Map/portrait/notifications/interactions | Single Core map hook/layer registry, travel markers, filtered hover face, nearby floating portrait and Talk, notification variants | Core/DT/Hoomans map layers coexist, no duplicate renders; contact only if viewer eligible |
| P7 DynamicTrading merchant policies | Settlement visiting/restock, availability, relationship-sensitive server quotes, remote communication vs trade fulfillment | One DT stock/budget, capped modifier, earned restock, no far-away magical trade |
| P8 Provider switching and Hoomans physical adapter | DTHoomans live materialization from Core record; DTAbstract abstract contact; save/restart switch and loaded-provider swap | Stable ID/face/items/social/location/merchant data after both directions; one body lease, no orphan |
| P9 Integration regression and user acceptance | Independent module matrices, older saves, MP authority/reconnect, performance, map UI and real game | All scoped tests and manual in-game SP/MP gates recorded with evidence; no implicit Workshop release |

## Required implementation order
- P0A: audit generation/schema and produce a field-by-field provenance/migration matrix and an executable *source-backed* parity baseline; commit it. See PHASE_0_EXTRACTION_AUDIT.md.
- Then P0B: accept migration contract and failure cases, fix source fixture discrepancies, establish namespaced Core public schema plan.
- P1: build only the minimal Core identity + canonical save/load vertical slice before moving heavy AI/UI.
- P2–P8 each split into bounded chunks with truthful PROGRESS Next Chunk and code-level acceptance.
- P9: user alone conducts final manual live-game playtesting; agents prepare exact steps and audit logs, not fabricated green gates.

## Compatibility matrix (required)
Core+DTCommon+DTAbstract without Hoomans; Core+DTCommon+Hoomans+DTHoomans without DTAbstract; both frontends; Core+DTCommon alone; Hoomans without DT; old save/restart without former adapter; MP dedicated with two clients and reconnect. Keep install/load dependency manifests accurate.

## Explicit non-goals
No Steam Workshop publishing/re-publishing, no automatic public mod release, no user save reset, no unrelated radio art/OS refactor, no synthetic-only acceptance of graphical/UI behavior, no duplication of MarketSense economy or full Hoomans needs/combat/colony/mobile director in Core.
