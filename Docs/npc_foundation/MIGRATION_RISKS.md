# NPC foundation migration risks

Latest P0B evidence: Hoomans `9f153c0e`; focused source suite `PASS 9/9` in
`0.41s`. Seed-only policy provenance is now explicitly fail-closed; the
appearance/voice serializer gap remains open.

Status: P0A audit artifact plus bounded P0B evidence, 2026-10-19. These
controls remain prerequisites for any production import writer. Nothing here
migrates live saves, rewrites ModData, changes production ownership, or
publishes Workshop content.

## Confirmed risks and controls

| Risk | Evidence | Required control |
| --- | --- | --- |
| Exact-version reset can destroy the only readable copy | Hoomans persistence checks exact `PERSISTENCE_VERSION = 16` and rejects unsupported roots; the normal path is not a migration adapter. | Hash and retain an untouched raw payload before hydration. Unknown or malformed roots remain quarantined and never pass through a reset import strategy. |
| Authored appearance policy can be dropped by the normal payload | Appearance policy schema 2 is consumed by `PNC_Identity_Appearance.Normalize/Resolve`, but `PNC_Types_Normalization`, `PNC_Types_Record`, `PNC_Persistence_Serialize`, and `PNC_Persistence_Deserialize` do not carry `record.appearance`. | Preserve the versioned `record.appearance` source field. Do not reroll slots or fall back to an archetype appearance when an authored policy exists. |
| Complete SurvivorFactory voice profile is not serialized | Factory source fields are `identity.survivor.voice = "parity_voice"`, `voicePrefix = "parity_voice"`, `voiceType = 3`, and `voicePitch = 1.25`; the payload keeps only legacy `identity.survivor.voice`. | Add a versioned voice object. A legacy value may only populate the legacy/prefix slot when justified; missing type or pitch remains incomplete or opaque and is never invented or regenerated from a new factory result. |
| Portable inventory metadata can vary by codec version | Source item `loot:p0b:01` has `customName = "Ledger"`, `itemState.modData.source = "p0b"`, and `legacyTemplateKey = "legacy:p0b:item"`. Metadata schema 2 preserves these through delta and FULL rehydration; schema 1 has no legacy-template slot. | Require metadata schema 2 for complete item parity. Schema-1 records carrying legacy-only identity remain source-authoritative or opaque; never replace the legacy template or discard the record. |
| Generator provenance and definition mismatch can change seed-only inventory | `PNC_Persistence_ImportPlan_Generator.Check` compares generator version, seed, archetype, equipment pool, definition revision, and template reference; it computes a source appearance `policyHash`, but the real inventory template has no independently persisted policy hash to compare. The source-backed mismatch fixture sets `template.definitionRevision = source.definitionRevision - 1`. | Exact source item state is authoritative when available. Seed-only replay requires an independently versioned policy hash; until that field is persisted and checked, missing or mismatched policy provenance quarantines with `generator_provenance_mismatch` rather than accepting a reroll. |
| A serialized generation root can be silently omitted | `PNC.Persistence.SerializeRecord` emits `generation`; the continuity fixture supplies `source = "starting_companion_trait"`, `traitID = "PNC_HasBrother"`, `relationshipKind = "brother"`, and `playerCharacterUUID = "char:p0b:continuity"`. The candidate adapter previously had no canonical mapping for this root. | Preserve the exact root in `candidate.source.opaque` with `canonical_mapping_deferred` until a reviewed owner and version mapping exist. Do not infer relationship or personality defaults from it. |
| Personality and relationship memory can be lost in blob mapping | `NormalizeSocialState` carries `personality`, `personalityOverrides`, `recentEventIDs`, directed target entries, and per-entry `memories`. | Map fields separately. Missing personality or memory containers receive no generated defaults; unrepresentable values remain source-preserved or quarantined. |
| Journey provenance can diverge | Travel summaries carry `journeyId`, `schemaVersion = 2`, `state`, `revision`, bounded `metadata`, and route state. Continuity tests cover revision conflict, unsupported journey schema, and serializer-dropped opaque data. | Compare ID, revision, and state before import. Preserve bounded metadata; quarantine conflicts or fields that cannot be represented. Never merge by last writer. |
| Duplicate identity/trader links can split authority | Hoomans uses actor IDs; DynamicTrading uses `traderID`, physical binding `p`, and faction bindings `g/l/m`; a future Core actor ID is a separate namespace. | Maintain an immutable mapping ledger. Reject one-to-many or many-to-one collisions without an explicit reviewed alias. Keep DT stock separate from personal inventory. |
| Inventory item IDs can duplicate native body projections | Hoomans inventory can be abstract, hydrated into a body, and captured again; native body leases are not canonical identity. | Import only the portable ledger. Reconcile one body lease with an idempotent transfer token; never import an abstract copy as a second native item. |
| Radio access can authorize distant DT trade | `DTCommon_TraderService.validateAccess` permits radio-authorized access when no nearby body exists. | Keep physical transfer and server-authority checks separate from MarketSense valuation. Active trades require stock, budget, and quote revision fences. |

## Reversible import protocol

The first real import must be a read-only dry run with a durable ledger:

1. Capture repository and save heads, module manifests, schema versions, the
   source record hash, and an untouched raw payload.
2. Validate actor IDs, version gates, generator provenance, item types and
   codecs, appearance policy, voice completeness, relationship keys, and
   position/journey revisions without mutating the source.
3. Produce a field-level decision log using only `copied`, `recomputed`,
   `projected`, `quarantined`, or `rejected` actions. `recomputed` is not
   permitted for authored identity, appearance policy, voice, personal item
   state, relationships, or active journey state when a source value exists.
4. Serialize and deserialize the candidate in memory, then compare canonical
   hashes for identity, appearance policy and resolved appearance, personal
   inventory, equipment slots, relationships, and location. Compare DT stock
   and budget separately through DTCommon.
5. Commit only an idempotent mapping and candidate record after the complete
   set passes. Keep the raw source and decision log.

The P0B planner emits rollback metadata only: ready plans use
`DISABLE_CANDIDATE_MAPPING`; quarantined plans use `NO_WRITE_QUARANTINE`; both
carry `sourceHash`, `sourcePreserved = true`, and `writesPerformed = false`.
This is a dry-run contract, not a production writer.

## P0B fixture evidence

The source-backed Hoomans evidence is on local commit `5efc66fe`, with
definition-mismatch and canonical-hash coverage in `1310433a`, identity-source
fail-closed coverage in `75d127e1`, metadata-schema-2 inventory preservation in
`f5326079`, deferred-root preservation in `cce488a6`, and the original planner,
generator, and rollback work in `72455cd1`, `3b8404fb`, and `6ad89ab0`.

The bounded focused suite passes `9/9` in `0.45s`. It executes the real
Hoomans identity, appearance, inventory, relationship, travel, serializer,
deserializer, and import-plan modules. It verifies raw/source non-mutation,
authored appearance and complete voice preservation from the source snapshot,
exact item state, metadata-schema-2 delta/FULL restoration, generator
provenance mismatch handling, candidate canonical-hash stability, opaque
generation-root preservation, and fail-closed behavior for unsupported or
incomplete input. This is source-level evidence only, not live-game acceptance.

## Explicit P0A boundary

P0A created the ownership matrix, risk register, passing parity baseline, and
the evidence-backed P0B entry point. It did not change Hoomans generation or
persistence, Core production behavior, DT pricing or access, map behavior, or
NPC lifecycle. P0B must resolve the remaining canonical field and codec gaps
before a Core actor registry or production import writer is introduced.
