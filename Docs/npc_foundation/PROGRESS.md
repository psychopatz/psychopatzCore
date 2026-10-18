# Core NPC Foundation — Current Progress Snapshot: 2026-10-18

Evidence is now from the checked-out local source heads, not only remote source
inspection. No foundation production implementation is claimed.

## Planning input revisions

- PsychopatzCore: `8b8e0b7`
- ProjectHoomans: `3f313b0b` (P0B test; production source at `d117d861`)
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
schema behavior. The next single chunk is an in-memory import-plan and
decision-log fixture; it must resolve the three confirmed parity blockers
before any Core production writer or P1 migration is introduced.

## Evidence remains open

Native SP/MP parity; portrait rendering in actual `ISWorldMap`; mixed-mod load
order; provider switching; old-save import; relationship/price policy;
settlement restock; real trader authorization migration; and performance.

## Standing boundary

No Workshop publication or republication. No silent destructive migration. No
automated claim of manual live gameplay acceptance. Existing DT trading and
Radio OS semantic harness goals remain separate.
