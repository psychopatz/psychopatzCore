# NPC foundation migration risks

Status: P0A audit artifact plus bounded P0B evidence, 2026-10-18. These
controls remain prerequisites for any production import writer. Nothing here
migrates live saves, rewrites ModData, changes production ownership, or
publishes Workshop content.

## Confirmed risks and controls

| Risk | Evidence | Required control |
| --- | --- | --- |
| Exact-version reset can destroy the only readable copy | Hoomans persistence checks exact `PERSISTENCE_VERSION = 16` and rejects unsupported roots; the normal path is not a migration adapter. | Copy and hash the untouched raw payload before hydration. Unknown or malformed roots remain quarantined and are never passed through reset as an import strategy. |
| Authored appearance policy is dropped by the normal payload | Hoomans appearance policy schema 2 is consumed by `RollAppearance`, but `Types.NormalizeDefinition` and `Persistence.SerializeRecord` do not carry `record.appearance`. | Preserve `record.appearance` as a versioned source field. Do not reroll slots or fall back to archetype appearance when authored policy is present. |
| Complete SurvivorFactory voice profile is not serialized | Factory source fields are `identity.survivor.voice`, `voicePrefix`, `voiceType`, and `voicePitch`; the current identity sanitizer writes only legacy `voice`. | Add a versioned voice object. Missing type/pitch remains incomplete or opaque; never invent it or regenerate it from a new factory result. |
| Portable inventory metadata can vary by codec version | CoreBridge/delta metadata schema 2 now preserves `customName`, bounded `itemState.modData`, and `legacyTemplateKey = "legacy:p0b:item"` through both delta and FULL paths. Metadata schema 1 has no legacy-template slot. | Require metadata schema 2 for complete item parity. Treat schema-1 records carrying legacy-only identity as source-authoritative/opaque; never replace a legacy template with a current one. |
| Deferred serialized roots can be silently omitted | Current `PNC.Persistence.SerializeRecord` emits roots including `semanticCognition`, `semanticActionPlan`, `progression`, `recipeKnowledge`, `mapPresentation`, `npcJournal`, and `bodyHint` that are outside the bounded Core candidate. | Hoomans `cce488a6` projects every unadapted serialized root into `candidate.source.opaque` with a `canonical_mapping_deferred` decision. Keep those exact roots until an owner/version mapping exists; do not treat projection as Core write eligibility. |
| Seed-only inventory can change when definitions change | Hoomans `SEED_ONLY` replays current archetype/loadout/equipment definitions from seed and generator version. | Require generator version, archetype, equipment pool, definition revision, template reference, and policy hash compatibility. Otherwise use exact source state or quarantine. |
| Personality and relationship memory can be lost in a blob mapping | `NormalizeSocialState` carries generated `personality`, `personalityOverrides`, `recentEventIDs`, directed target entries, and per-entry `memories`. | Map these fields separately. `6ad89ab0` requires their source containers and records copied/quarantine decisions; missing personality or memory containers never receive generated defaults. |
| Journey provenance can diverge | Travel summaries carry `journeyId`, `schemaVersion = 2`, `state`, `revision`, bounded `metadata`, and route state. The continuity smoke proves revision conflict, unsupported journey schema, and serializer-dropped opaque data. | Compare ID/revision/state before import, preserve bounded metadata, and quarantine conflicts or opaque fields that cannot be represented. Never merge by last writer. |
| Duplicate identity and trader links can split authority | Hoomans actor IDs, DT `traderID`, DT physical binding `p`, faction binding `g/l/m`, and a future Core actor ID are separate namespaces. | Maintain an immutable mapping ledger. Reject one-to-many or many-to-one collisions without an explicit reviewed alias. Keep DT stock separate from personal inventory. |
| Inventory item IDs and body projections can duplicate | Hoomans inventory can be abstract, hydrated into a body, and captured again; body leases and native items are not canonical identity. | Import only the portable ledger. Reconcile one body lease with a transfer token and idempotency key; never import abstract and native copies as separate items. |
| Radio access can authorize distant DT trade | `DTCommon_TraderService.validateAccess` permits radio-authorized access when no nearby body exists. | Keep this as a later DT physical-transfer blocker. Separate abstract quotes from physical fulfillment and preserve MarketSense valuation. |

## Conditional risks requiring later fixtures

- Unknown or partially indexed source versions, native item types, and missing
  visuals must fail closed and preserve an opaque source copy.
- Stale body leases, online IDs, multiplayer split-brain, map knowledge, and
  physical body simulation require server-authority and projection checks.
- Active DT trades require a stock/budget/quote revision fence; a failed fence
  aborts extraction.
- MarketSense valuation inputs and DT pricing remain DTCommon-owned.

## Reversible import protocol

The first real import must be a read-only dry run with a durable ledger:

1. Capture repository/save heads, module manifests, schema versions, source
   record hash, and the untouched raw payload.
2. Validate actor ID, generator references, appearance policy, complete voice,
   item state representability, social target keys/memories, journey revision,
   and any DT transaction fence.
3. Produce a candidate and a field-level decision log with `copied`,
   `recomputed`, `projected`, `quarantined`, or `rejected` actions.
4. Serialize and deserialize the candidate in memory and compare canonical
   hashes for identity, appearance, personal inventory, relationships, and
   location. Compare merchant stock separately through DTCommon.
5. Commit only an idempotent mapping and candidate after the complete set
   passes. Keep the raw source and decision log.

The P0B planner now emits rollback metadata: ready plans use
`DISABLE_CANDIDATE_MAPPING`; quarantined plans use `NO_WRITE_QUARANTINE`; both
carry `sourceHash`, `sourcePreserved = true`, and `writesPerformed = false`.
This is a dry-run contract, not a production writer.

## P0B fixture evidence

Hoomans `72455cd1`, `3b8404fb`, `6ad89ab0`, `cce488a6`, and `f5326079` add the read-only
`PNC.Persistence.ImportPlan` and focused tests. The actual source-backed suite
passes `9/9` in `0.45s`. It proves raw/source non-mutation, authored policy and
complete voice preservation from the source snapshot, exact personal item
state, metadata-schema-2 delta/FULL restoration, generator compatibility and
fallback, personality/memory continuity, journey provenance, opaque
nested-field quarantine, deferred serialized-root preservation, candidate codec
hash verification, and rollback metadata. It never calls reset, writes
ModData, overwrites saves, or claims live-game acceptance.

## Explicit P0A boundary

P0A created the ownership matrix, this risk register, and the passing isolated
baseline. It did not change Hoomans generation/persistence, Core production
behavior, DT pricing/access, map behavior, or NPC lifecycle. P0B must resolve
the remaining canonical field and codec gaps before a Core actor registry or
production import writer is introduced.
