# P0B — Canonical schema and safe migration contract

Status: bounded P0B contract, 2026-10-18. This document defines the
preconditions for a future Core NPC import writer. It does not implement a
writer, rewrite ModData, alter Hoomans ownership, or publish a Workshop
revision.

Evidence heads:

- PsychopatzCore: `ae32edd` (local P0B proof; `origin/main` remains
  `8b8e0b7`).
- ProjectHoomans P0B planner/test: `72455cd1`; the checked-out branch's
  upstream source head remains `d117d861` and unrelated semantic commits are
  preserved separately.
- DynamicTrading: `2b1975a2` (local source; remote is one commit ahead and
  was not pulled or changed).

The Hoomans identity, appearance, inventory, relationship, and persistence
modules are executed by the two focused tests. SurvivorFactory and native
equipment construction are deterministic test-boundary fixtures only. Core
inventory media is excluded from the graph index, so the Core codec findings
below are direct-source findings.

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
| Hoomans CoreBridge / Core delta | 1 / 1 | Require exact nested schema and metadata validation. |
| PsychopatzCore virtual / dense item records | 1 / 1 | Require type, codec, state, quantity, and metadata representability. |
| Hoomans directed social state | 3 | Preserve exact target keys and memory IDs. |
| Core canonical NPC envelope | 1 (P0B contract) | Future writer only; no current runtime reader is implied. |

No older Hoomans save version is supported by this audit. An unknown, malformed,
partially readable, or unsupported schema produces:

```lua
{
    status = "quarantined",
    reason = "unsupported_schema" | "malformed_record"
        | "unrepresentable_field" | "identity_conflict",
    rawPayload = <untouched-copy>,
    sourceHash = <hash>,
}
```

The source payload remains unchanged. The normal Hoomans reset behavior is not
an import adapter and must not be used as one.

## Implemented read-only import plan

Hoomans commit `72455cd1` registers
`PNC.Persistence.ImportPlan`. `ImportPlan.Build` copies the raw payload,
computes a deterministic source hash, checks the exact current persistence
version, and returns a quarantined plan with the raw copy when the root is
malformed, unsupported, or missing an actor ID. With a source snapshot it
builds a canonical in-memory `PsychopatzCore.NPC` candidate and a decision log;
it does not call reset, write ModData, or mutate the input/options.

The field adapter requires and copies appearance policy schema 2, the full
voice tuple (`voice`, `voicePrefix`, `voiceType`, `voicePitch`), inventory
envelope/items/equipment state, directed social state, and location fields.
An item carrying `legacyTemplateKey` is explicitly quarantined with
`portable_metadata_unrepresentable`; no replacement template or invented
state is supplied. `pnc_npc_foundation_import_plan_smoke.lua` proves these
paths using the actual Hoomans identity, appearance, inventory, serializer,
and persistence modules and passes in the focused six-test harness command.

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
| Portable inventory metadata / codec parity | Source item: `id = "loot:p0b:01"`, `customName = "Ledger"`, `itemState.modData.source = "p0b"`, `legacyTemplateKey = "legacy:p0b:item"`. | `customName = "Ledger"` and `itemState.modData.source = "p0b"` survive; `legacyTemplateKey = nil` after serialization and rehydration. | Hoomans `PNC_Inventory_CoreBridge` and `PNC_Inventory_CoreDeltaCodec` call Core `encodeItem`; `PNC_Inventory_CoreStateCodec.metadata/applyMetadata` has no legacy-template field before `Internal.createItem`. | Extend the versioned metadata contract or keep an opaque/full source item envelope. Records with the missing field are not eligible for seed/delta-only import; do not replace the template or discard the record. |

The generic custom-name concern is therefore narrowed: the current path
preserves the canonical flat `customName` field. The confirmed loss is the
separate `legacyTemplateKey` metadata field.

## Relationship and location continuity

Relationship entries retain exact directed keys such as `npc:<id>` and
`player:<account>:<characterUUID>`, normalized scores, memory IDs, and
bounded journals. A username-only alias is not an import key. Position, spawn,
anchor, and active journey are separate fields with one declared authority;
conflicting revisions are quarantined rather than merged by last writer.

## P0B exit gate and next chunk

The bounded fixture now proves:

1. current-version records are copied without mutating the source;
2. authored appearance policy and all four voice values survive candidate
   construction;
3. the known `legacyTemplateKey` discrepancy produces an explicit
   opaque/quarantine decision rather than a replacement or discard;
4. relationships and location/journey conflicts are explicit; and
5. unsupported schemas preserve the raw source and fail closed.

Remaining P0B next chunk: add an explicit generator-provenance/definition
mismatch decision and candidate serialize/deserialize canonical-hash checks,
then review any remaining fields against the ownership matrix. A mismatch must
select a source baseline/full/opaque path or quarantine; it must never rerun a
changed generator as a silent default. Do not start the full P1 production
migration or live-game acceptance.
