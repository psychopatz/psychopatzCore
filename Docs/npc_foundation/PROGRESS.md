# Core NPC Foundation — Current Progress

Snapshot: 2026-10-19. Evidence basis: GitHub source/commit audit plus prior agent-recorded local test results. Remote GitHub does not prove local worktree cleanliness, and the reported test suite was not independently rerun in this audit.

## Current phase
**P0B — Canonical Schema and Safe Migration Contract: ACTIVE.**
P0A is accepted from source-backed evidence. P1 has NOT started. There is no production Core NPC registry/factory yet.

## Repository evidence
- PsychopatzCore source baseline audited at `50022acf`; subsequent commits in this goal refresh are documentation-only. P0A/P0B durable docs, field matrix and migration-risk register are present.
- ProjectHoomans main: `bc9c64d0`. NPC-foundation implementation/test commits exist on a divergent committed history through `9f153c0e`, including `f647daea` baseline, `72455cd1` read-only import planner, `f5326079` metadata-schema-2 item preservation, `5efc66fe` generation-root preservation, and `9f153c0e` seed-only policy-provenance gate.
- DynamicTrading main: `d6fccc3d`. Only the adapter contract is present for this goal; merchant travel/restock/relationship pricing/provider switching are not implemented.
- Hoomans foundation history and current `main` are divergent. This must be reconciled safely before cross-repo production migration; do not force-push/reset or overwrite unrelated work.

## Accepted P0A foundation
The ownership matrix, migration-risk register and source-backed baseline identify the current producers/writers for identity, appearance, personal inventory, social state, location/journey, map presentation and DT merchant linkage. Existing tests exercise real Hoomans identity, appearance, inventory, relationship, travel and persistence modules around deterministic engine-boundary fixtures.

The agent-reported focused suite is 9/9 passing and `pz_verify` reports zero Kahlua errors on the planner path. Treat that as recorded source-harness evidence, not live Project Zomboid acceptance.

## Implemented P0B safety work
- Read-only `PNC.Persistence.ImportPlan` builds a no-write candidate, decision log, source hash and rollback metadata; malformed/unsupported records quarantine without mutating the source.
- Generator provenance checks seed/archetype/generator/equipment/definition/template context and now fail closed for seed-only records when appearance-policy provenance is absent/mismatched.
- Metadata schema 2 preserves `legacyTemplateKey` alongside supported custom name/modData in delta and FULL current-schema inventory paths.
- Directed social personality/memories and journey ID/revision/state are represented in the planner; conflicts quarantine.
- Unmapped serialized roots can be preserved in `candidate.source.opaque` rather than silently dropped.

## What is NOT implemented/accepted
- **Normal Hoomans persistence still drops shared presentation data.** Current `sanitizeIdentity` serializes only legacy `identity.survivor.voice`; normal persistence does not carry the complete four-field voice profile. Normal record serialization also does not carry the authored `record.appearance` policy.
- The import-planner tests preserve those values only when an extra in-memory `sourceSnapshot` is supplied. That proves read-only planning behavior, not ordinary save/reload parity.
- The planner's test `CandidateCodec()` is an in-memory echo/copy helper, not a real PsychopatzCore NPC persistence codec. It must not be cited as P1 Core save/load acceptance.
- A missing authored appearance policy must be distinguished from a default/generated NPC that never had one. Default-generated actors must not be quarantined merely because `record.appearance` is absent.
- No production Core actor record, Core NPC factory, Core social owner, journey service, shared map migration, DT settlement roaming/restock, relationship pricing or DTAbstract<->DTHoomans switching exists yet.
- Native SP/MP, actual ISWorldMap rendering, mixed-mod load order, provider switching and performance remain open.
- Broader Hoomans suite has an unrelated non-game UI harness dependency on `ISUI/ISPanel`; do not spend this chunk repairing that solely to claim full-suite green.

## ONE Current Next Chunk — P0B production serializer/deserializer parity
Implement a bounded **ProjectHoomans production persistence** slice for shared appearance/voice continuity.

Required work:
1. Add source-backed failing regressions using the normal record path (`Types.NewRecord` -> ordinary `PNC.Persistence.SerializeRecord` -> `DeserializeRecord`) with **no** planner `sourceSnapshot`.
2. Introduce an explicit versioned representation that preserves the complete available voice profile: `voice`, `voicePrefix`, `voiceType`, `voicePitch`. Do not invent fields for old/incomplete saves or rerun SurvivorFactory to fill them.
3. Persist and restore authored appearance policy schema 2 exactly when present, including slot mode/type/wornSlot/itemState.
4. Represent the difference between:
   - no authored policy ever existed -> deterministic generated/default appearance remains valid; and
   - authored policy existed -> it must round-trip exactly and may not silently fall back to an archetype reroll.
5. Carry or version the minimum generator/policy provenance needed so current supported records cannot silently seed-replay incompatible clothing/appearance.
6. Re-run focused foundation tests and current identity/inventory/relationship regressions. Preserve older/unsupported input fail-closed/source-authoritative rules.

### Acceptance for this chunk
A supported current-version generated NPC and a supported current-version authored-appearance NPC both pass normal SerializeRecord -> DeserializeRecord without a source snapshot. The authored case retains exact policy + full available voice fields; the generated/default case is not falsely quarantined. Existing metadata-schema-2 item parity remains green. No save is rewritten in place, no Core production writer is introduced, and no Workshop/live-game acceptance is claimed.

After this acceptance, update P0B contract/evidence and decide whether only a small migration-compatibility closure remains or P0B can close. Then open exactly ONE P1 Next Chunk: real Core-only Create -> Save -> Reload -> Get for identity/appearance, using a real Core codec rather than the in-memory candidate echo helper.

## Standing boundaries
No Workshop publication/republication. No destructive save migration. No force-push/reset to reconcile Hoomans histories. No automated claim of manual live gameplay acceptance. Existing Dynamic Trading MVP, Radio OS and semantic goals remain separate.
