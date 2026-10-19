# Core NPC Foundation — Current Progress

Snapshot: 2026-10-20. Evidence basis: source-backed Hoomans Lua harnesses and
static verification; no live-game acceptance is claimed.

## Current phase

**P1 — Core identity and appearance: ACCEPTED source/harness evidence.** P2
is the next bounded implementation chunk. P3–P9 remain open and are not
accepted.

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

## ONE Next Chunk — P2 portable NPC personal inventory

Extend the Core actor envelope with a reusable personal inventory ledger using the existing Core portable-item codecs. Add deterministic starter equipment, stable item IDs, container/worn/equipped references, seed/delta/full persistence, exact state restoration, and a Core-only actor inventory round trip. Keep DT merchant stock separate and do not materialize a Hoomans body in P2.

Standing boundaries: no destructive save migration, no force-push/reset, no
ambiguous pull, no Workshop publication, and no automated claim of manual
normal-game SP/MP acceptance. Existing Dynamic Trading MVP T6 remains OPEN.
