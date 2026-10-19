# Core NPC Foundation — Ordered Roadmap

Status snapshot: 2026-10-20. P0A, P0B, P1, and the Core P2 ledger slice are accepted from source-backed harness evidence; P3 is the next bounded chunk. The P2 physical-body gate remains part of P8 integration. P4–P9 remain open. Existing Dynamic Trading MVP T6 live SP/MP acceptance remains OPEN separately.

| Phase | Status | Work | Mandatory exit gate |
| --- | --- | --- | --- |
| P0A Extraction audit | ACCEPTED (source/harness evidence) | Trace creators, normalized schemas, persistence, map/trade coupling; produce field matrix, risks and parity baseline | Ownership matrix + risk register + executable source-backed parity baseline with honest gaps |
| P0B Canonical schema and safe migration contract | ACCEPTED (source/harness evidence) | Resolve no-loss schema decisions and repair current Hoomans persistence gaps needed for migration | Normal supported save/load retains shared identity presentation data; default vs authored appearance is explicit; read-only import remains fail-closed; one reversible migration contract |
| P1 Core factory and actor registry | ACCEPTED (source/harness evidence) | Single authoritative identity generator, stable ID/seed, resolved name/gender/voice/appearance, extension contracts | Core-only NPC Create -> Save -> Reload -> Get remains identical without PNC and without duplicate IDs |
| P2 Portable NPC personal inventory | ACCEPTED (Core source/harness; body gate in P8) | Deterministic starter clothes/gear/bags plus exact portable items, worn/equipped slots, seed + deltas/full fallback | Same item IDs/state across regen-free save/load; no duplication; physical body parity verified in P8 |
| P3 Legacy import and compatibility | OPEN (next bounded chunk) | Read/validate Hoomans legacy data before exact-version reset; map identities/domains; wrappers | Non-destructive idempotent import, rollback/retry, source untouched until candidate commit |
| P4 Shared social | NOT STARTED | Core directional Approval/Respect/Familiarity/personality/memories, validators and revisioned reads | Existing Hoomans social state/player-character keys preserved; no double event credit |
| P5 Generic agent/journey/anchors | NOT STARTED | Bounded scheduler/behavior registration, location anchors and A-to-B journeys | DT-only merchant travels and arrives once across restart without Hoomans mobile director |
| P6 Map/portrait/notifications/interactions | NOT STARTED | Single Core map hook/layers, travel markers, filtered hover face, nearby floating portrait/Talk, notification variants | Core/DT/Hoomans layers coexist with no duplicate hooks and knowledge-gated actor discovery |
| P7 DynamicTrading merchant policies | NOT STARTED | Settlement visiting/restock, availability, relationship-sensitive server quotes, communication vs fulfillment | One DT stock/budget, capped relationship modifier, earned restock, no far-away magical transfer |
| P8 Provider switching and Hoomans physical adapter | NOT STARTED | DTHoomans live materialization from Core; DTAbstract abstract presentation; provider switching | Stable identity/face/items/social/location/merchant data in both directions; one body lease |
| P9 Integration regression and user acceptance | NOT STARTED | Module matrices, older saves, MP authority/reconnect, performance, map UI and real game | Scoped automated evidence plus USER-run manual SP/MP evidence; no implicit Workshop release |

## Current mandatory sequence
1. Keep the accepted P0B serializer/import evidence and its focused regressions green.
2. Begin only the minimal P1 Core Create/Get/Save/Load identity/appearance slice.
3. Continue P2–P8 only as bounded chunks with their own acceptance evidence.
4. P9 live normal-game SP/MP acceptance belongs to the user.

## P0B production persistence acceptance
A current supported Hoomans NPC must survive ordinary SerializeRecord -> DeserializeRecord without a test-only source snapshot while preserving:
- stable identity/seed/name and resolved face fields;
- complete available voice values (`voice`, `voicePrefix`, `voiceType`, `voicePitch`) under an explicit versioned contract;
- authored appearance policy schema 2 exactly when it exists;
- the distinction between "no authored appearance policy; use deterministic generated/default appearance" and "an authored policy existed but was lost";
- current metadata-schema-2 personal item identity/state and existing relationship/location behavior.

Unsupported/older incomplete data remains source-preserved or quarantined; values are never invented by rerunning SurvivorFactory.

## Compatibility matrix (later mandatory gates)
Core+DTCommon+DTAbstract without Hoomans; Core+DTCommon+Hoomans+DTHoomans without DTAbstract; both frontends; Core+DTCommon alone; Hoomans without DT; safe save/restart switch after migration; MP dedicated with two clients and reconnect.

## Explicit non-goals
No Steam Workshop publishing/re-publishing, no user save reset, no unrelated Radio OS/semantic refactor, no synthetic-only claim for graphical UI, no duplication of MarketSense economy or Hoomans needs/combat/colony/mobile director inside Core.
