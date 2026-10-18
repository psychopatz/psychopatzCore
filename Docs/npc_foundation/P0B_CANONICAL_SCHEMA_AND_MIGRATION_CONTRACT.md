# P0B — Canonical schema and safe migration contract

Status: bounded P0B contract, 2026-10-18. This document defines the
preconditions for a future Core NPC import writer. It does not implement a
writer, rewrite ModData, alter Hoomans ownership, or publish a Workshop
revision.

Evidence heads:

- PsychopatzCore: `1b990938` (local P0B evidence head; `origin/main` remains
  `8b8e0b7`).
- ProjectHoomans P0B planner/test: `75d127e1` (fail-closed identity-source
 coverage on top of `f5326079`; metadata-schema-2 inventory
 repair on `cce488a6`, extending `6ad89ab0`, `3b8404fb`, and `72455cd1`); the
  checked-out branch is now `90fd728c` with unrelated commits `77300f59` and
  `90fd728c` preserved; its upstream is `15fc79aa`.
- DynamicTrading: `2b1975a2` (local source; remote is one commit ahead and
  was not pulled or changed).

The Hoomans identity, appearance, inventory, relationship, travel, and
persistence modules are executed by the focused tests. SurvivorFactory and
native equipment construction are deterministic test-boundary fixtures only.
Core inventory media is excluded from the graph index, so the Core codec
findings below are direct-source findings.

## Contract boundary

P0B accepts only a read-only, source-preserving import plan. A later
implementation may write a Core record only after every required field is
classified as `copied`, `recomputed`, `projected`, `quarantined`, or
`rejected`. `recomputed` is not allowed for authored identity, authored
appearance policy, voice profile, personal item state, relationships, or
active journey state when the source value is available.

The contract must never:

- pass an unknown Hoomans payload through the normal exact-version reset path;
- invent voice pitch/type, appearance slots, item templates, relationship
  targets, or identity IDs;
- use a new SurvivorFactory result to replace an authored or persisted value;
- merge DT merchant stock with an NPC's personal inventory;
- treat a physical IsoZombie or native inventory item as actor identity; or
- overwrite the source save before a complete candidate and rollback record
  exists.

## Stable identity mapping

The first mapping ledger has one immutable row per source actor:

| Source | Canonical mapping | Rule |
| --- | --- | --- |
| Hoomans `record.id` | Core `actorId` | Preserve the exact non-empty string in the `pnc:` actor namespace. Existing Core mapping wins on retry. |
| Hoomans `identitySeed` / `identity.seed` | `identity.seed` | Preserve the normalized seed as a generation input, never as an actor ID. Missing values are quarantined for explicit assignment. |
| DT `traderID` and physical binding `p` | Separate DT mapping row linked to `actorId` | Never replace the Hoomans actor ID and never copy stock into the personal ledger. One-to-many or many-to-one collisions are quarantined. |
| Native body / online ID | Hoomans projection lease | Never promoted to identity. A stale or duplicate lease is dropped from the candidate and re-materialized later by Hoomans. |

An empty ID, duplicate source ID, existing conflicting mapping, or ambiguous DT
link is a no-write result. Names, seeds, coordinates, and trader display labels
are not identity substitutes.

## Canonical Core record

P0B defines the following versioned envelope for the future Core writer. This
is a contract shape, not a claim that production code already accepts it.

```lua
{
    schema = "PsychopatzCore.NPC",
    schemaVersion = 1,
    actorId = "pnc:<source-record-id>",
    source = {
        provider = "ProjectHoomans",
        persistenceVersion = 16,
        sourceRecordHash = "<hash>",
        importedFromVersion = 16,
        decisionSet = "<dry-run-id>",
        opaque = <exact-unmapped-serialized-roots>,
    },
    identity = {
        schemaVersion = 1,
        seed = <identitySeed>,
        archetypeID = <archetypeID>,
        displayName = <displayName>,
        survivor = {
            forename = <forename>,
            surname = <surname>,
            hairModel = <hairModel>,
            beardModel = <beardModel>,
            skinColor = <color>,
            hairColor = <color>,
            skinTexture = <texture>,
            voice = {
                legacy = <voice>,
                prefix = <voicePrefix>,
                type = <voiceType>,
                pitch = <voicePitch>,
                complete = <boolean>,
            },
        },
    },
    appearance = {
        policySchemaVersion = 2,
        policy = <authored-policy-or-opaque-source>,
        resolved = <resolved-appearance>,
        generator = <seed-and-definition-provenance>,
    },
    inventory = {
        sourceSchema = 2,
        metadataSchema = 2,
        mode = "SEED_ONLY" | "BASELINE_DELTA" | "FULL" | "OPAQUE",
        baseline = <source-baseline>,
        items = <exact-portable-items>,
    },
    relationships = {
        sourceSchema = 3,
        entries = <exact-directed-target-keys-and-memories>,
    },
    location = {
        position = <source-position>,
        spawn = <source-spawn>,
        anchor = <source-anchor>,
        journey = <source-journey-or-opaque-source>,
    },
}
```

Canonical fields have one writer. Hoomans remains the physical-body, director,
job, faction, and live simulation provider; DTCommon remains merchant stock,
budget, pricing, access, fulfillment, and restock authority. Core owns only
the canonical actor record and generic projections after a later migration
phase explicitly installs those writers.

## Supported versions and fail-closed behavior

The current source-backed input set is intentionally narrow:

| Component | Verified source version | Import rule |
| --- | ---: | --- |
| Hoomans NPC persistence | 16 | Read and preserve the raw root before any normal loader call. |
| Hoomans appearance policy | 2 | Preserve the full policy, including slot mode, type, worn slot, and item state. |
| Hoomans inventory envelope | 2 | Keep `SEED_ONLY`, `BASELINE_DELTA`, and `FULL` distinct. |
| Hoomans CoreBridge / Core delta | envelope 1 / metadata 2 / delta 1 | Require exact nested schema and metadata validation; schema-1 metadata is read-compatible but not complete for legacy-template identity. |
| PsychopatzCore virtual / dense item records | 1 / 1 | Require type, codec, state, quantity, and metadata representability. |
| Hoomans directed social state | 3 | Preserve exact target keys and memory IDs. |
| Core canonical NPC envelope | 1 (P0B contract) | Future writer only; no current runtime reader is implied. |

No older Hoomans save version is supported by this audit. An unknown, malformed,
partially readable, or unsupported schema produces:

```lua
{
    status = "quarantined",
    reason = "unsupported_schema" | "malformed_record"
        | "unrepresentable_field" | "identity_conflict"
        | "voice_profile_incomplete"
        | "authored_appearance_policy_missing"
        | "appearance_schema_unsupported"
        | "portable_metadata_invalid",
    rawPayload = <untouched-copy>,
    sourceHash = <hash>,
}
```

The source payload remains unchanged. The normal Hoomans reset behavior is not
an import adapter and must not be used as one.

Every serialized root outside the explicit adapter set (`schemaVersion`, `id`,
`identity`, `inventory`, `social`, `position`, `spawn`, `anchor`, `travel`, and
`generation`) is projected into `source.opaque` with a
`canonical_mapping_deferred` decision. This is source retention, not a claim
that Core owns the field or may write it. The current source-backed fixture
exercises `semanticCognition` and an unknown `futureRoot`; both survive the
candidate codec unchanged in Hoomans `cce488a6`.

## Implemented read-only import plan

Hoomans commits `72455cd1`, `3b8404fb`, `6ad89ab0`, `cce488a6`, `f5326079`,
and `75d127e1` register and extend
`PNC.Persistence.ImportPlan`. `ImportPlan.Build` copies the raw payload,
computes a deterministic source hash, checks the exact current persistence
version, and returns a quarantined plan with the raw copy when the root is
malformed, unsupported, or missing an actor ID. With a source snapshot it
builds a canonical in-memory `PsychopatzCore.NPC` candidate and a decision log;
it does not call reset, write ModData, or mutate the input/options.

The field adapter requires and copies appearance policy schema 2, the full
voice tuple (`voice`, `voicePrefix`, `voiceType`, `voicePitch`), inventory
envelope/items/equipment state, directed social state, and location fields.
The metadata-schema-2 bridge carries `legacyTemplateKey` at metadata index 17
in FULL payloads and in each delta upsert; schema-1 reads remain supported but
cannot reconstruct that field. `pnc_npc_foundation_import_plan_smoke.lua` and
the gap characterization prove exact current-schema preservation and keep
raw schema-16 identity loss, unsupported appearance policy versions,
incomplete voice profiles, and invalid metadata fail-closed. These paths use the actual Hoomans identity,
appearance, inventory, serializer, and persistence modules. The focused
source-backed suite passes `9/9`.

The generator adapter checks current version `4`, seed, archetype, equipment
pool, definition revision, and optional template reference. It marks a match
`SEED_COMPATIBLE`; with exact item state present, a mismatch is
`SOURCE_AUTHORITATIVE`; with seed-only state, it quarantines
`generator_provenance_mismatch`. Candidate readiness requires an explicit
deterministic codec and equal canonical hashes before and after the
in-memory round trip; missing or changed codec content quarantines.

The continuity follow-up in Hoomans `6ad89ab0` separates social and journey
provenance. It requires normalized social `personality`,
`personalityOverrides`, `recentEventIDs`, directed relationship entries, and
each relationship's `memories` container. It requires journey `journeyId`,
`schemaVersion`, `state`, and `revision`, copies bounded `metadata`, and
quarantines persisted/source revision conflicts or a source `opaque` field
omitted by the current travel serializer. Every ready or quarantined plan now
includes a no-write rollback record with the source hash and
`sourcePreserved = true`.

The deferred-root follow-up in `cce488a6` makes otherwise-unmapped serialized
roots explicit in the candidate's opaque source envelope and decision log. It
does not make those fields importable by a future writer; each still requires
an owner, version, and restoration contract.

## Non-destructive import and rollback

The dry-run transaction is:

1. Capture source repository/save heads, module manifests, schema versions,
   raw payload, and a content hash.
2. Validate IDs, version gates, generator provenance, item types/codecs,
   appearance policy, voice completeness, relationship keys, and
   position/journey revisions without mutating the source.
3. Produce a field-level decision log and a candidate Core envelope.
4. Serialize and deserialize the candidate in a fresh in-memory registry, then
   compare canonical hashes for identity, appearance policy and resolved
   appearance, personal inventory, equipment slots, relationships, and
   location. Compare DT stock/budget separately.
5. Commit only an idempotent mapping row and candidate record after the whole
   candidate set passes. Keep the raw source and decision log.

Rollback disables the candidate mapping and removes only the candidate Core
record. It never rewrites or “repairs” the source payload. A failed preflight,
conflict, active DT transaction, or uncertain body/journey lease aborts the
candidate.

## Generator and appearance restoration rules

Seed-only replay is valid only when all of these match the source baseline:

- Hoomans generator version `PNC.Const.GENERATOR_VERSION = 4`;
- archetype ID and definition revision;
- equipment pool ID and revision;
- inventory template reference;
- appearance policy schema and policy hash; and
- the source seed.

If any provenance is missing or changed, the importer must use the source
baseline/delta/full item representation or preserve an opaque source section.
It must not rerun SurvivorFactory and silently accept a new name, voice,
clothing, or face. Resolved appearance is a projection of the preserved policy
and source item ledger, not a replacement for them.

## Confirmed parity decisions

| Discrepancy | Exact expected source fields and values | Actual current value | Affected path | Required migration behavior |
| --- | --- | --- | --- | --- |
| Authored appearance policy preservation | `record.appearance.schemaVersion = 2`; `slots.Torso_Upper = { mode = "item", type = "Base.Jacket", wornSlot = "Torso_Upper", itemState.modData.source = "authored" }`; `outfit = "none"`. | `PNC.Persistence.SerializeRecord` emits `payload.appearance = nil`; `DeserializeRecord` restores `record.appearance = nil`. | `PNC_Identity_Appearance.Normalize/Resolve` can consume the policy, but `PNC_Types_Normalization`, `PNC_Types_Record`, `PNC_Persistence_Serialize`, and `PNC_Persistence_Deserialize` do not carry it. | Add a versioned canonical policy field and preserve the raw policy until then. Do not fall back to the archetype look or reroll slots. |
| Complete NPC voice profile | Factory source survivor fields: `voice = "parity_voice"`, `voicePrefix = "parity_voice"`, `voiceType = 3`, `voicePitch = 1.25`. | Payload keeps only `identity.survivor.voice = "parity_voice"`; `voicePrefix`, `voiceType`, and `voicePitch` are `nil`. | `PNC_Identity_Factory.GenerateResolvedIdentity` and `PNC_Identity_Profile.RollAppearance` produce all four; `PNC_Persistence_Primitives.sanitizeIdentity` writes only legacy `voice`. | Add a versioned voice object. Map old legacy voice only to the legacy/prefix slot when justified; missing type/pitch remains incomplete/opaque, never invented or factory-regenerated. |
| Portable inventory metadata / codec parity | Source item: `id = "loot:p0b:01"`, `customName = "Ledger"`, `itemState.modData.source = "p0b"`, `legacyTemplateKey = "legacy:p0b:item"`. | Before `f5326079`, schema-1 metadata dropped `legacyTemplateKey`; current metadata schema 2 preserves it through delta and FULL rehydration. | Hoomans `PNC_Inventory_CoreBridge` and `PNC_Inventory_CoreDeltaCodec` call Core `encodeItem`; `PNC_Inventory_CoreStateCodec.metadata/applyMetadata` now carries index 17 under metadata schema 2. | Require metadata schema 2 for complete parity. Old schema-1 records carrying legacy-only identity remain source-authoritative/opaque; do not replace the template or discard the record. |

The generic custom-name concern is therefore narrowed: the current metadata
schema 2 preserves the canonical flat `customName` field, bounded `modData`,
and the separate `legacyTemplateKey` field. The remaining compatibility gap is
explicitly limited to older metadata-schema-1 payloads.

## Relationship and location continuity

Relationship entries retain exact directed keys such as `npc:<id>` and
`player:<account>:<characterUUID>`, normalized scores, memory IDs, and
bounded journals. Personality and relationship memory are explicit canonical
fields, not defaults derived during import. A username-only alias is not an
import key. Position, spawn, anchor, and active journey are separate fields
with one declared authority; conflicting revisions are quarantined rather than
merged by last writer. The continuity smoke is source-backed by the real
Hoomans relationship and travel constructors.

## P0B exit gate and next chunk

The bounded fixture now proves:

1. current-version records are copied without mutating the source;
2. authored appearance policy and all four voice values survive candidate
   construction;
3. metadata schema 2 preserves `legacyTemplateKey` through both delta and FULL
   paths, while schema-1 reads remain explicitly incomplete for that field;
4. relationships and location/journey conflicts are explicit; and
5. personality, relationship memories, and journey provenance are explicit;
6. opaque nested journey fields and location conflicts quarantine without loss;
7. rollback metadata records source preservation and no writes; and
8. unsupported schemas, raw schema-16 payloads without a source snapshot,
   unsupported appearance-policy versions, and incomplete voice profiles
   preserve the raw source and fail closed.

Remaining P0B next chunk: specify the versioned writer/reader mapping for
authored appearance policy and the complete SurvivorFactory voice profile,
using the fail-closed source tests as the boundary for schema-16 unknown/old
inputs. A
mismatch must select a source baseline/full/opaque path or quarantine; it must
never rerun a changed generator as a silent default. Do not start the full P1
production migration or live-game acceptance.
