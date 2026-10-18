# Core NPC Foundation — Current Progress Snapshot: 2026-10-18

Evidence is now from the checked-out local source heads, not only remote source
inspection. No foundation production implementation is claimed.

## Planning input revisions

- PsychopatzCore: `ae32edd` (local P0B proof; `origin/main` remains `8b8e0b7`)
- ProjectHoomans: `3b8404fb` (read-only P0B planner, generator provenance, and
  candidate-hash tests; upstream remains `d117d861`)
- DynamicTrading: `2b1975a2`
- MarketSense dependency: not inspected in this P0A chunk.

## P0A checkpoint — formally closed, implementation still gated

Changed only these scoped artifacts:

- `Docs/npc_foundation/FIELD_OWNERSHIP_MATRIX.md`
- `Docs/npc_foundation/MIGRATION_RISKS.md`
- `ProjectHoomans/tests/pnc_npc_foundation_parity_baseline_smoke.lua`
- `ProjectHoomans/tests/pnc_npc_foundation_p0b_gap_characterization_smoke.lua`

The baseline uses the actual Hoomans identity factory/profile, appearance
resolver, `Types.NewRecord`, inventory template/persistence/CoreBridge,
relationship normalizer, and record serializer/deserializer. Its deterministic
engine fixtures cover one generated NPC and verify stable ID, name/seed,
persisted voice, resolved face fields, seeded clothing, portable item IDs/state,
worn/equipped slots, directed relationship memory, position/anchor, and
unsupported-version rejection.

Focused command and result:

```text
python3 tests/run_tests.py pnc_npc_foundation_parity_baseline_smoke pnc_npc_foundation_p0b_gap_characterization_smoke pnc_seed_delta_smoke pnc_relationship_foundation_smoke pnc_unique_npc_smoke --jobs 1 --verbose
PASS 5/5
```

The source-backed P0B planner command also passes:

```text
python3 tests/run_tests.py pnc_npc_foundation_parity_baseline_smoke pnc_npc_foundation_p0b_gap_characterization_smoke pnc_npc_foundation_import_plan_smoke pnc_npc_foundation_import_plan_generator_smoke pnc_npc_foundation_import_plan_codec_smoke pnc_seed_delta_smoke pnc_relationship_foundation_smoke pnc_unique_npc_smoke --jobs 1
PASS 8/8 in 0.54s
```

`pnc_npc_foundation_import_plan_smoke.lua` loads the real parity baseline and
then exercises `PNC.Types.NewRecord`, `PNC.Identity.Appearance.Normalize`,
`PNC.Inventory.Internal.createBaseInventory`, `PNC.Inventory.ApplyDelta`,
`PNC.Persistence.SerializeRecord`, and `PNC.Persistence.ImportPlan`. Its
source snapshot carries the authored appearance policy and all four voice
fields; its inventory cases use actual Hoomans inventory mutations. The
planner copies raw input, fails closed on unsupported schema versions, logs
field-level decisions, and quarantines `legacyTemplateKey` rather than
discarding or replacing it.

Hoomans `3b8404fb` adds generator provenance checks for the actual current
generator version (`4`), template seed/archetype/equipment-pool/definition
revision, and optional template reference. A compatible source is marked
`SEED_COMPATIBLE`; a changed generator falls back to
`SOURCE_AUTHORITATIVE` when exact item state exists and quarantines when only
seed replay remains. Candidate readiness requires a supplied deterministic
codec whose post-deserialize canonical hash matches the pre-serialize hash;
missing or mismatched codecs quarantine without changing the source.

The result is not live SP/MP acceptance. Confirmed gaps are authored
appearance-policy persistence, the complete SurvivorFactory voice profile, and
the `legacyTemplateKey` portable inventory metadata field. The focused P0B
characterization also proves that canonical `customName` and bounded
`modData` survive this path. The confirmed gaps remain explicit no-loss
import blockers; no silent fallback is accepted.

P0A acceptance is supported and formally closed by the existing artifact
commits: Core documentation `8b8e0b7`, Hoomans baseline test `f647daea`.
The P0B characterization is committed as Hoomans `3f313b0b`. These commits
are local source-control history only; no Workshop publication occurred.
The P0B canonical-schema contract is committed as Core `92be3e2`; the
read-only import-plan implementation and follow-up provenance/hash tests are
committed as Hoomans `72455cd1` and `3b8404fb`. The Hoomans branch is ahead of
its remote by unrelated semantic work as well; only the eight P0B paths in
`3b8404fb` were staged for this chunk. These commits are local source-control
history only; no Workshop publication occurred.

The broader legacy harness is not clean in this checkout: its first unrelated
UI test, `pnc_building_catalog_local_recipes_smoke.lua`, cannot load
`ISUI/ISPanel` outside the game UI runtime. This did not involve the new test;
the four focused identity/inventory/relationship tests passed independently.

## Verified source boundaries

- Hoomans owns physical IsoZombie materialization, body lease, combat, needs,
  jobs, faction/colony simulation, and live pathing.
- PsychopatzCore is the intended owner of canonical actor identity, resolved
  appearance, personal inventory, directed relationships, generic location /
  journey state, and generic presentation contracts.
- DTCommon owns merchant stock, budget, pricing, access, fulfillment, and
  restock. Its current radio/abstract access path remains a later migration
  blocker for physical item transfer.

## Active bounded chunk: P0B — Canonical Schema and Safe Migration Contract

The contract is recorded in
`P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md`. It defines stable actor-ID
mapping, exact current source/component versions, a complete canonical field
shape, source-preserving rollback, deterministic generator compatibility,
appearance/voice/inventory/relationship continuity, and explicit unsupported
schema behavior. The bounded in-memory import-plan and decision-log fixture,
including generator provenance and candidate-hash verification, is now
implemented and verified. P0B remains active for the next single chunk: audit
the remaining canonical fields against the matrix, especially personality,
relationship memory, journey provenance, opaque unsupported nested fields, and
rollback decision records. Add only source-backed tests or adapters needed to
prove those contracts before a Core production writer or P1 migration is
introduced.

## Evidence remains open

Native SP/MP parity; portrait rendering in actual `ISWorldMap`; mixed-mod load
order; provider switching; old-save import; relationship/price policy;
settlement restock; real trader authorization migration; and performance.

## Standing boundary

No Workshop publication or republication. No silent destructive migration. No
automated claim of manual live gameplay acceptance. Existing DT trading and
Radio OS semantic harness goals remain separate.
