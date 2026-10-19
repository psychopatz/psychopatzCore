# Core NPC Foundation — Current Progress

Snapshot: 2026-10-20. Evidence basis: source-backed Hoomans Lua harnesses and
static verification; no live-game acceptance is claimed.

## Current phase

**P3 — Non-destructive legacy migration: ACCEPTED source/harness evidence.**
P4 is the next bounded implementation chunk. P2’s physical Hoomans
body round-trip remains a P8 integration gate.

## Repository evidence

- PsychopatzCore is clean at `48b2dda` on `main`/`origin/main`; this chunk
  changed only the durable NPC-foundation evidence docs.
- ProjectHoomans is clean at `f7bfd6b6` on
  `codex/contextual-dialogue-quest-framework-0a`, pushed fast-forward to its
  matching GitHub branch. The branch carries the NPC-foundation commits with
  the unrelated semantic work; `origin/main` remains a separate, one-commit
  divergent line and was not force-merged, reset, or overwritten.
- DynamicTrading remains clean at `d6fccc3d` on `main`/`origin/main`; no DT
  runtime behavior changed.

## Accepted P0A/P0B foundation

- Ownership/risk audit, source-backed parity baseline, read-only
  `PNC.Persistence.ImportPlan`, fail-closed source preservation,
  metadata-schema-2 `legacyTemplateKey` preservation, relationship/journey
  continuity, deferred-root retention, and seed-only generator/policy
  provenance gates remain source/harness facts.
- Normal Hoomans persistence now carries a version-1 `voiceProfile` with the
  available `voice`, `voicePrefix`, `voiceType`, and `voicePitch` values plus
  an explicit completeness marker. Legacy/incomplete input keeps only the
  values it supplied; no factory reroll fills gaps.
- Authored appearance is copied as schema 2, including outfit, slots,
  `wornSlot`, and `itemState`. A version-1 `appearanceContract` distinguishes
  `AUTHORED_POLICY` from `GENERATED_DEFAULT` and records generator seed,
  archetype/version, equipment pool/template context, and authored policy
  hash where available.
- The normal `Types.NewRecord -> SerializeRecord -> DeserializeRecord` path
  now round-trips both authored and generated/default records without an
  import-planner `sourceSnapshot`.

## Validation evidence

- `python3 tests/run_tests.py pnc_npc_foundation --jobs 1 --verbose --timeout 60`
  — **7/7 passed**.
- Relevant persistence/equipment/inventory-state/relationship/social/travel
  regressions — **13/13 passed**.
- `python3 .../pz_verify.py --dir Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core --kahlua --severity ERROR --no-snippets`
  — **0 Kahlua errors** across 845 files; the new normal persistence test
  also passed single-file Kahlua verification.
- The broader filtered inventory run still has the known unrelated
  non-game `pnc_inventory_ui_smoke` failure because `ISUI/ISPanel` is not
  available. It is not included in the focused success count.

## Remaining boundaries

The planner's `CandidateCodec()` remains an in-memory echo/copy helper and is
not Core persistence acceptance. No in-place save migration, PsychopatzCore
writer, DT behavior, Workshop publication, native SP/MP test, or live-game
claim was made.

## P1 evidence — Core-only identity/appearance vertical slice

Production files: `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzActorFactory.lua`, `PsychopatzActorRegistry.lua`, `PsychopatzActorPersistence.lua`, `PsychopatzActors.lua`, and `PsychopatzActorUtil.lua`.

`tests/psychopatz_npc_actor_smoke.lua` passed with `/usr/bin/lua`: generated and authored actors both Create -> Save -> Reload into a fresh registry -> Get; names, seeds, voice tuples, resolved appearance, authored schema-2 slot/item state, and namespaced extensions remained stable; duplicate IDs and invalid IDs were rejected.

`tests/psychopatz_core_composition_smoke.lua` passed after recording the existing eager currency-diagnostics debug-settings load order. Actor modules loaded through the shared Core composition only.

`pz_verify.py --dir Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors --kahlua --severity ERROR --no-snippets` passed: 5 files, 0 compatibility errors.

Adjacent Core inventory regressions (`psychopatz_inventory_framework_smoke.lua`, `psychopatz_inventory_defaults_smoke.lua`, `psychopatz_inventory_reversible_smoke.lua`) passed. No Hoomans or DynamicTrading module was loaded by the actor smoke.

## P2 evidence — Core portable NPC personal inventory

- Production file: `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzActorInventory.lua`, exposed as `PsychopatzCore.Actors.Inventory` and persisted in the actor envelope as `personalInventory`.
- `tests/psychopatz_npc_inventory_smoke.lua` passed with `/usr/bin/lua`: existing Core weapon codecs captured exact state; stable item IDs, containers, equipment slots, FULL, BASELINE_DELTA, and SEED_ONLY envelopes all restored; actor save/reload preserved the inventory payload and no merchant stock or budget fields were present.
- Sparse JSON arrays now encode intentional null positions, preserving codec states such as weapon attachment payloads through actor persistence. Existing inventory framework/default/reversible smoke tests remained green.
- Kahlua verification passed for the actor tree and `PsychopatzJson.lua`, with zero errors.
- No physical engine item, Hoomans body, DT merchant stock, or DT budget is serialized in the personal ledger.

## P3 evidence — Non-destructive Hoomans to Core migration

- Core production: `PsychopatzActorMigration.lua`, `Registry:Remove`, and the public `PsychopatzCore.Actors.Migration` service. It consumes a ready source-preserving plan, validates identity/voice/appearance/inventory ownership, copies Hoomans social/location/source-opaque data, stores raw backups and mapping hashes, rejects conflicts, and commits only after candidate validation.
- Hoomans production: `PNC_Persistence_CoreMigration.lua` exposes an optional adapter without loading Core; callers inject the loaded Core facade and registry. The normal Hoomans persistence loader registers the adapter.
- `PZ_TEST_CORE_RUNTIME=42.20 PZ_TEST_CORE_REPOSITORY=/home/psychopatz/Zomboid/Workshop/psychopatzCore python3 tests/run_tests.py --jobs 1 --verbose --timeout 60 pnc_npc_foundation_core_migration pnc_npc_foundation_import_plan_continuity pnc_npc_foundation_parity_baseline pnc_seed_delta` passed 4/4.
- The migration smoke proves import, idempotent retry, source conflict quarantine, rollback with disabled mapping, and safe retry after rollback. `pz_verify.py` passed the Hoomans adapter and Core actor tree with zero Kahlua errors.
- Source payloads are copied and never rewritten; unknown or malformed plans remain quarantined. No Workshop, native SP/MP, or live-game claim is made.

## ONE Next Chunk — P4 shared social system

Implement Core-owned directional relationships, Approval, Respect, Familiarity, personality, bounded event memories, normalized actor/player target keys, revisioned reads, and authorized event recording. Add the Hoomans social adapter so existing directed state is copied once without duplicate event credit; keep social policy out of DT stock and pricing authority.

## ONE Next Chunk — P3 non-destructive legacy migration

Implement Core-owned, idempotent Hoomans legacy import and mapping. Read and validate source records before any exact-version reset path, preserve raw source and opaque roots, validate identity/appearance/voice/inventory/social/location ownership, commit candidates transactionally into a fresh Core registry, and provide rollback/retry evidence without mutating source saves.

Standing boundaries: no destructive save migration, no force-push/reset, no
ambiguous pull, no Workshop publication, and no automated claim of manual
normal-game SP/MP acceptance. Existing Dynamic Trading MVP T6 remains OPEN.
