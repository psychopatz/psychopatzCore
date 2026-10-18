# Core NPC Foundation — Current Progress Snapshot: 2026-10-18

Evidence is now from the checked-out local source heads, not only remote source
inspection. No foundation production implementation is claimed.

## Planning input revisions

- PsychopatzCore: `911d0bc`
- ProjectHoomans: `cb2b07e7`
- DynamicTrading: `2b1975a2`
- MarketSense dependency: not inspected in this P0A chunk.

## P0A checkpoint — audit complete, implementation still gated

Changed only these scoped artifacts:

- `Docs/npc_foundation/FIELD_OWNERSHIP_MATRIX.md`
- `Docs/npc_foundation/MIGRATION_RISKS.md`
- `ProjectHoomans/tests/pnc_npc_foundation_parity_baseline_smoke.lua`

The baseline uses the actual Hoomans identity factory/profile, appearance
resolver, `Types.NewRecord`, inventory template/persistence/CoreBridge,
relationship normalizer, and record serializer/deserializer. Its deterministic
engine fixtures cover one generated NPC and verify stable ID, name/seed,
persisted voice, resolved face fields, seeded clothing, portable item IDs/state,
worn/equipped slots, directed relationship memory, position/anchor, and
unsupported-version rejection.

Focused command and result:

```text
python3 tests/run_tests.py pnc_npc_foundation_parity_baseline_smoke --jobs 1 --verbose
PASS 1/1
```

The result is not live SP/MP acceptance. Confirmed gaps are authored
appearance-policy persistence, the complete SurvivorFactory voice profile, and
at least one generic portable item-state codec case. These remain explicit
no-loss import blockers; no silent fallback is accepted.

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

## Next bounded chunk: P0B

Resolve the confirmed schema conflicts and design a read-only, reversible
legacy-import dry run: preserve raw Hoomans payloads, define actor-ID mapping,
carry authored appearance and full voice without reroll, classify portable item
state representability, and emit conflict/quarantine decisions. Do not add a
Core production writer or change DT/Hoomans runtime ownership until that dry run
has a passing no-loss fixture.

## Evidence remains open

Native SP/MP parity; portrait rendering in actual `ISWorldMap`; mixed-mod load
order; provider switching; old-save import; relationship/price policy;
settlement restock; real trader authorization migration; and performance.

## Standing boundary

No Workshop publication or republication. No silent destructive migration. No
automated claim of manual live gameplay acceptance. Existing DT trading and
Radio OS semantic harness goals remain separate.
