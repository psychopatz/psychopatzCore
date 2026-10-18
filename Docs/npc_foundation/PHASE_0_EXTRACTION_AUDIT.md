# P0 — Extraction, Save-Schema and Generator Parity Audit

Status: P0A next chunk, no phase accepted. Begin with actual checked-out sources.

## Mandatory evidence to collect
### Hoomans existing producers
- Core/Identity/PNC_Identity_Factory.lua and PNC_Identity_Profile.lua (SurvivorFactory resolved identity, stable seed, forename/surname/name, gender/voice/skin/hair).
- Core/Identity/PNC_Identity_Portrait.lua and PNC_Identity_Appearance.lua (portrait summary, appearance revisions and worn visuals).
- Core/Base/PNC_Types/PNC_Types_Record.lua (NewRecord creation, field defaults; includes Hoomans-only health/job/runtime).
- Core/Inventory/PNC_Inventory/PNC_Inventory_Templates.lua, Equipment/PNC_Inventory_EquipmentGeneration.lua (deterministic outfit, worn, weapons, bags, supplies).
- Core/Inventory/PNC_Inventory/PNC_Inventory_Persistence.lua and child CoreBridge/CoreDeltaCodec modules (seed/delta/full, item IDs/state, salvage limits).
- server/PNC/Social/RelationshipService/* and shared RelationshipTypes, EntityRef (directed social, personality, memory and player-character keys).
- Core/Presence/PNC_Presence/PNC_Presence_Materialize.lua and body lifecycle (body as presentation lease, inventory materialization, failure rollback).
- docs/Systems/Persistence.md — exact schema version RESET semantics. DO NOT rely on an automatic source migration reader; explicitly verify actual code and implement a non-destructive bridge later.

### Core existing services
- PsychopatzCore/Inventory/PsychopatzInventory, ItemTransfer, Economy/PsychopatzCurrency and state serializer; PortraitPanel; EventMarkers; notifications; runtime role rules. Inventory/portrait support is implemented in Core and should be reused, not duplicated.
### Dynamic Trading
- DTCommon_TraderRegistry, DTCommon_TraderService, DTCommon_TraderStock, DTCommon_Storage and inventory adapter. Audit traderID ↔ NPC id, stock vs carried goods, radio/local access validator and save/replay invariants.
- DTHoomans_CaravanLifecycle, DTHoomans_SettlementTrader, DTHoomans_Server; DTAbstract_Client and both module manifests. Audit Hoomans-dependent lifecycle and mode availability.

## P0A output artifacts (inside this job)
1. FIELD_OWNERSHIP_MATRIX.md: for each common field, producer, actual serialized key, owner/current writer, normalized type/bounds, exact authority, target Core field, old version, import rule, conflict precedence and a test anchor.
2. MIGRATION_RISKS.md: enumerate source-schema reset hazards, duplicate IDs, generator nondeterminism (SurvivorFactory), unknown Workshop item/visuals, inventory item-state round-trip, social target identity, body lease, active trade, stale journey, MP split-brain. Distinguish confirmed from hypothetical.
3. A small runnable source-backed parity baseline under relevant existing test harness directory, with exact command and both expected and observed behavior. Fixture should generate one NPC, serialize/deserialize and compare stable name, resolved face/voice/clothes, personal item IDs/state/worn/equipped slots, relationships and source revisions. Unknown producer paths must be reported rather than mocked away.
4. List every old version that is actually supported as input. For any unknown, fail closed and preserve source unchanged.

## P0A acceptance
- Each listed field has a known provenance and no more than one target writer.
- Document precise compatibility aliases for current PNC and DT consumers; no speculative global search/replace.
- Executable test reports green or honest targeted failures (red baseline is acceptable as evidence); no claim of in-game success.
- No production generation, persistence, map, pricing or NPC lifecycle code changed within P0A.
- Commit proof and advance PROGRESS to one P0B Next Chunk, only if evidence sufficient.

## P0B and handoff to P1
P0B resolves schema conflict decisions; defines reversible import/dry-run boundary, stable actorId mapping, source-visibility and creator version policy; picks minimal Core ID/identity baseline. P1 writes an independent Core Create/Get/Save/Load vertical slice and a physical-free harness acceptance. Later phases move items, social and map; not in P0A.
