# Core NPC Foundation — Current Progress Snapshot: 2026-10-18

Evidence is from the checked-out local source heads. No foundation
production implementation or live-game acceptance is claimed.

## Planning input revisions

- PsychopatzCore: `532be6c` (local P0B evidence head; `origin/main` remains
  `8b8e0b7`).
- ProjectHoomans P0B evidence: `5efc66fe` (generation provenance preservation
  on top of `1310433a` definition-mismatch coverage and `75d127e1`
  identity-source fail-closed coverage; earlier `f5326079` inventory,
  `cce488a6` deferred-root, and planner/generator/hash tests;
  checked-out branch now `5efc66fe`; unrelated commits `77300f59` and
  `90fd728c` remain preserved before it; upstream is `15fc79aa`).
- DynamicTrading: `2b1975a2` (local source; remote is one commit ahead and was
  not pulled or changed).
- MarketSense dependency: not inspected in this bounded P0B chunk.

## P0A checkpoint — formally closed, implementation still gated

The required P0A artifacts are present locally: the Core ownership matrix and
risk register, the Hoomans parity baseline, and the durable progress/audit
documents. The baseline executes the real Hoomans identity factory/profile,
appearance resolver, `Types.NewRecord`, inventory template/persistence and
CoreBridge, relationship normalizer, and record serializer/deserializer.

Verified local P0A deliverables:

- `Docs/npc_foundation/FIELD_OWNERSHIP_MATRIX.md`
- `Docs/npc_foundation/MIGRATION_RISKS.md`
- `ProjectHoomans/tests/pnc_npc_foundation_parity_baseline_smoke.lua`
- Updated `PROGRESS.md` and `PHASE_0_EXTRACTION_AUDIT.md`

The baseline covers stable identity, name/seed, persisted voice, resolved face
fields, seeded clothing, portable item IDs/state, worn/equipped slots,
directed relationship memory, position/anchor, and unsupported-version
rejection.

The broader legacy harness remains outside this goal: its first unrelated UI
test cannot load `ISUI/ISPanel` outside the game UI runtime. That failure is
not used to weaken or inflate the focused evidence.

P0A acceptance is supported by the existing artifact commits: Core
documentation `8b8e0b7`, Hoomans baseline `f647daea`, and Hoomans gap
characterization `3f313b0b`. These are local source-control facts only; no
Workshop publication occurred.

## P0B evidence

The focused source-backed command is:

```text
python3 tests/run_tests.py \
  pnc_npc_foundation_parity_baseline_smoke \
  pnc_npc_foundation_p0b_gap_characterization_smoke \
  pnc_npc_foundation_import_plan_smoke \
  pnc_npc_foundation_import_plan_continuity_smoke \
  pnc_npc_foundation_import_plan_generator_smoke \
  pnc_npc_foundation_import_plan_codec_smoke \
  pnc_seed_delta_smoke pnc_relationship_foundation_smoke \
  pnc_unique_npc_smoke --jobs 1
PASS 9/9 in 0.42s
```

The read-only planner was introduced in Hoomans `72455cd1`, extended with
generator provenance and candidate hashing in `3b8404fb`, and extended with
this bounded continuity/rollback audit in `6ad89ab0`, followed by deferred
serialized-root preservation in `cce488a6`, followed by metadata schema 2
inventory preservation in `f5326079`, followed by fail-closed incomplete
identity-source coverage in `75d127e1`, definition-mismatch and hash stability
coverage in `1310433a`, and generation-root source preservation in `5efc66fe`.

`pnc_npc_foundation_import_plan_smoke.lua` uses real Hoomans identity,
appearance, inventory, serializer, deserializer, and import-plan modules. It
preserves the authored appearance policy, all four voice values, exact item
state, generator provenance, and fail-closed behavior for raw schema-16
records without a source snapshot, unsupported appearance policy versions,
and incomplete voice profiles. Current metadata schema 2 preserves
`legacyTemplateKey` in both baseline-delta and FULL payloads; schema-1 payloads
remain explicitly incompatible with that field.

`pnc_npc_foundation_import_plan_continuity_smoke.lua` uses the real Hoomans
relationship and travel constructors. It verifies generated personality,
directed relationship memories, journey ID/revision/state, bounded metadata,
and explicit rollback metadata. Journey revision conflicts, unsupported
journey schemas, and opaque source fields omitted by the current serializer
are quarantined with the raw payload untouched.

The same continuity test now proves that serialized roots outside the bounded
canonical candidate—such as `semanticCognition` and an unknown future root—are
copied exactly into `candidate.source.opaque` with
`canonical_mapping_deferred` decisions. It now also preserves the real
serialized `generation` root exactly. They remain projected source data; no
default, writer, or silent discard is introduced.

Static `pz_verify` checks report zero Kahlua errors on the planner modules and
no token-bloat findings after the continuity split. Test-file warnings are the
known false positive for the harness helper's `T.load` calls.

The result is not live SP/MP acceptance. Confirmed no-loss blockers remain:
authored appearance-policy persistence, the complete SurvivorFactory voice
profile in the normal Hoomans payload. Deferred serialized roots now remain
visible in the opaque source envelope, but their canonical owners are not yet
established. A legacy metadata-schema-1 payload still cannot claim complete
item parity and must remain source-authoritative or opaque. No silent fallback
is accepted.

## Verified ownership boundary

- Hoomans owns physical IsoZombie materialization, body leases, combat, needs,
  jobs, faction/colony simulation, and live pathing.
- PsychopatzCore is the intended owner of canonical actor identity, resolved
  appearance, personal inventory, directed relationships, generic location /
  journey state, and generic presentation contracts.
- DTCommon owns merchant stock, budget, pricing, access, fulfillment, and
  restock. Its radio/abstract access path remains a later physical-transfer
  blocker.

## Active bounded goal: P0B — Canonical Schema and Safe Migration Contract

The contract is recorded in `P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md`.
It defines stable actor-ID mappings, exact current source/component versions,
canonical field shape, source-preserving rollback, deterministic generator
compatibility, appearance/voice/inventory/relationship continuity, and
explicit unsupported-schema behavior.

The deferred-root ownership audit is now recorded in the field matrix. Every
root emitted by the current Hoomans serializer is classified as an explicit
foundation field or exact opaque source data; no root was promoted to a writer
mapping. The next bounded chunk is the generator/provenance adapter contract
for `generation`, definition/template references, equipment-pool provenance,
and seed-only replay refusal, with one source-backed no-seed-replay test. Do
not start the full P1 production migration, rewrite saves, publish Workshop
content, or claim live-game acceptance.

## Evidence remaining open

Native SP/MP parity; portrait rendering in actual `ISWorldMap`; mixed-mod load
order; provider switching; old-save import; relationship/price policy;
settlement restock; real trader authorization migration; and performance.

## Standing boundary

No Workshop publication or republication. No silent destructive migration. No
automated claim of manual live gameplay acceptance. Existing DT trading and
Radio OS semantic-harness goals remain separate.
