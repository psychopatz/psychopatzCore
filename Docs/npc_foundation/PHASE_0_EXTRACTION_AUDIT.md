# P0 — Extraction, Save-Schema and Generator Parity Audit

Status: P0A formally closed; P0B active. Begin with actual checked-out sources.
Latest bounded P0B evidence is Hoomans `5efc66fe` and the focused suite is
`PASS 9/9`; this remains source-harness evidence, not live-game acceptance.

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

## P0A closure checkpoint — 2026-10-18

The required P0A artifacts are now present in the local worktrees:

- `FIELD_OWNERSHIP_MATRIX.md` records source paths, serialized keys, current
  writers, target ownership, version policy, and test anchors.
- `MIGRATION_RISKS.md` records confirmed reset/appearance/voice/item-state
  hazards, conditional risks, and a reversible import protocol.
- `ProjectHoomans/tests/pnc_npc_foundation_parity_baseline_smoke.lua` is a
  runnable source-backed baseline. It passed `1/1` in the existing isolated Lua
  harness. It uses deterministic engine-boundary fixtures and makes no live
  Project Zomboid acceptance claim.
- `P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md` records the bounded
  canonical schema, version gates, mapping ledger, rollback rules, and exact
  discrepancy decisions.
- `ProjectHoomans/tests/pnc_npc_foundation_p0b_gap_characterization_smoke.lua`
  executes the actual Hoomans persistence/identity/inventory bridge and passes
  `1/1`. It confirms custom-name and bounded modData preservation, exposes the
  schema-1 legacy-template loss, and pairs with the schema-2 delta/FULL repair.
- `ProjectHoomans/tests/pnc_npc_foundation_import_plan_smoke.lua` executes the
  real Hoomans identity, appearance, inventory, persistence, and new
  read-only import-plan modules. It passes the complete focused command,
  preserves the authored policy and all four voice fields from an untouched
  source snapshot, fail-closes raw schema-16 records without that snapshot,
  unsupported appearance-policy versions, incomplete voice profiles, and
  invalid metadata;
  metadata schema 2 now preserves `legacyTemplateKey` in delta and FULL
  payloads.
- `ProjectHoomans/tests/pnc_npc_foundation_import_plan_generator_smoke.lua`
  verifies current generator compatibility, exact-item source-authoritative
  fallback, definition-revision mismatch decisions, candidate canonical-hash
  stability, source non-mutation, and seed-only generator-mismatch quarantine.
- `ProjectHoomans/tests/pnc_npc_foundation_import_plan_codec_smoke.lua`
  verifies missing-codec and canonical-hash mismatch quarantine.
- `ProjectHoomans/tests/pnc_npc_foundation_import_plan_continuity_smoke.lua`
  verifies real relationship/personality memory continuity, journey
  provenance, opaque nested-field quarantine, unsupported journey schema,
  deferred serialized-root preservation, metadata-schema-2 inventory
  preservation, generation-root preservation, and source-preserving rollback
  metadata.

The baseline is intentionally bounded. It passes generated identity, seeded
resolved appearance, personal inventory, equipment slots, directed social
state, position/anchor, and exact-version rejection. It does not claim parity
for authored appearance policy, the complete factory voice profile, every
portable item codec, journeys, DT merchant policy, map knowledge, or physical
body leases. Those are explicit P0B or later gates. No production generation,
persistence, map, pricing, or NPC lifecycle code changed in P0A.

P0A evidence is sufficient to start P0B design, but P1 remains gated on the
reversible no-loss import dry run and the confirmed field conflicts.

## Commit and source-control proof

Current Core P0B documentation commits are `1bd2625` (provenance and
deferred-root evidence), `69af55e` (serialized-root ownership audit), and
`afdc184` (provenance gate and verification state); no push was made.

- Core P0A documentation: `8b8e0b7`, already equal to `origin/main`.
- Core P0B canonical-schema contract: `92be3e2`, local and not pushed.
- Hoomans P0A baseline: `f647daea`, committed on the local documentation
  branch and absent from GitHub `main`.
- Hoomans P0B characterization: `3f313b0b`, committed on that same local
  branch; unrelated semantic work remains untouched and uncommitted.
- Hoomans P0B import planner: `72455cd1`; generator provenance and candidate
  hash follow-up: `3b8404fb`; continuity and rollback follow-up: `6ad89ab0`;
  deferred serialized-root preservation: `cce488a6`; metadata-schema-2
  inventory codec repair: `f5326079`; fail-closed identity-source coverage:
  `75d127e1`; definition-mismatch/hash coverage: `1310433a`; generation-root
  source preservation: `5efc66fe`.
- DynamicTrading local source: `2b1975a2`; local branch is one commit behind
  its remote and was not changed.

No repository was pushed during this chunk. GitHub source control was kept
separate from Steam Workshop publication.

## P0B active boundary — one next chunk

The deferred-root audit is recorded in `FIELD_OWNERSHIP_MATRIX.md`: all roots
emitted by the current serializer are either in the explicit foundation set
or retained as exact opaque source data. No remaining root received a Core
writer mapping. The next bounded chunk is the generator/provenance adapter
contract for definition/template/equipment-pool references and a
source-backed seed-only replay refusal test. Do not start the full P1
production migration, rewrite saves, publish Workshop content, or claim
live-game acceptance.
