# Core NPC Foundation — Current Progress

Snapshot: 2026-10-20. Evidence basis: source-backed Hoomans Lua harnesses and
static verification; no live-game acceptance is claimed.

**PARENT GOAL: IN PROGRESS — complete the entire Foundation P1–P9 roadmap.** P0B accepted is a subordinate checkpoint only. The automation must execute the next chunk P1, then continue through all remaining mandatory chunks after each is verified; do NOT exit after a successful P1 commit or ask the user for another /goal. All developer-implementable work precedes user-owned native PZ tests.

## Current phase

**P0B — Canonical Schema and Safe Migration Contract: ACCEPTED from
source/harness evidence.** P1 is open as the next bounded implementation
chunk; no production Core actor registry or writer has been started.

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

## ONE CURRENT EXECUTION CHUNK — P1 (automatic continuation through P2–P9 follows) Core-only identity/appearance vertical slice

Implement the smallest real PsychopatzCore `Create -> Save -> Reload -> Get`
codec/registry slice for stable actor identity and the already-defined
appearance/voice contract. It must not begin portable inventory, social,
journey, DT, Hoomans body projection, or Workshop work. Acceptance must use a
real Core codec/registry, not `CandidateCodec()`, and prove stable identity,
resolved appearance/voice, generated/default-vs-authored state, duplicate-ID
rejection, and no dependency on PNC or DT.

Standing boundaries: no destructive save migration, no force-push/reset, no
ambiguous pull, no Workshop publication, and no automated claim of manual
normal-game SP/MP acceptance. Existing Dynamic Trading MVP T6 remains OPEN.
