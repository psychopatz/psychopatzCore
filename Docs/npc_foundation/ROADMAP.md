# Core NPC Foundation — Ordered Roadmap

Status snapshot: 2026-10-20. P0A, P0B, P1, P2, P3, and P4 have accepted
developer-side source/harness evidence. P5 is the next bounded phase. P2
physical-body parity remains a P8 integration gate. Existing DynamicTrading
MVP T6 live SP/MP acceptance remains separate and open.

| Phase | Status | Work | Mandatory exit gate |
| --- | --- | --- | --- |
| P0A Extraction audit | ACCEPTED | Trace creators, schemas, persistence, map/trade coupling; produce ownership and risk evidence | Ownership matrix and executable source-backed parity baseline |
| P0B Canonical schema and safe migration contract | ACCEPTED | Resolve no-loss schema decisions and fail-closed migration rules | Supported save/load retains shared presentation data; authored/default appearance is explicit |
| P1 Core factory and actor registry | ACCEPTED | Core-owned identity, voice, appearance, registry, persistence, and extension contracts | Core-only Create → Save → Reload → Get with stable identity and no PNC/DT dependency |
| P2 Portable NPC personal inventory | ACCEPTED (body gate in P8) | Deterministic starter equipment and exact portable item state with seed/delta/full payloads | Stable item IDs/state across codec round-trip; no merchant-stock ownership |
| P3 Legacy import compatibility | ACCEPTED | Validate and map Hoomans records without source mutation; preserve rollback state | Idempotent import, conflict quarantine, rollback/retry, source untouched |
| P4 Shared social | ACCEPTED | Core directional Approval/Respect/Familiarity, personality, memories, validation, revisions | Hoomans social state projects once; authorized events cannot double-apply |
| P5 Generic agent/journey/anchors | NEXT | Bounded scheduler, behavior registration, location anchors, abstract A-to-B journeys | Journey identity/state survives save/reload and arrival is applied once |
| P6 Map/portrait/notifications/interactions | OPEN | Core map hooks/layers, travel markers, filtered portraits, nearby Talk, notifications | Core/DT/Hoomans UI layers coexist without duplicate hooks or ungated discovery |
| P7 DynamicTrading merchant policies | OPEN | Settlement visits, availability, restocking, relationship-sensitive server quotes, authoritative fulfillment | One DT stock/budget; capped social modifier; no far-away magical transfer |
| P8 Provider switching and Hoomans physical adapter | OPEN | DTHoomans materialization, DTAbstract presentation, provider switching and body leases | Stable identity/face/items/social/location/merchant state; one body lease |
| P9 Integration regression and user acceptance | OPEN | Module matrices, old saves, MP authority/reconnect, performance, map UI, real-game handoff | Developer evidence complete plus explicit user-run SP/MP acceptance |

## Compatibility matrix

Core+DTCommon+DTAbstract without Hoomans; Core+DTCommon+Hoomans+DTHoomans
without DTAbstract; both frontends; Core+DTCommon alone; Hoomans without DT;
safe save/restart provider switching; and dedicated MP with two clients and
reconnect.

## Explicit non-goals

No Steam Workshop publishing or republishing, no destructive user save reset,
no unrelated Radio OS/semantic refactor, no synthetic-only claim for graphical
UI, and no duplication in Core of MarketSense economy, Hoomans needs/combat/
colony/mobile-director ownership, or DT merchant stock/budget.
