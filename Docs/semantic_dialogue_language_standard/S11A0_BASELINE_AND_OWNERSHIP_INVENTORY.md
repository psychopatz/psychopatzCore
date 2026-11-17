# S11A0 — Preflight, Baselines, and Legacy Ownership Inventory

**Status:** ACCEPTED (S11A0)
**Date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Execution order:** `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`

## 1. Repository & Reconciliation Preflight

Verified starting HEADs on existing `main` branches (no branches created):

- `psychopatzCore`: `a583dbd246b6d8f6f4ba519462aecae92424a06f` (pre-existing S11 doc edits/untracked files preserved)
- `ProjectHoomans`: `942ef41304287e6dadc6023a0c2577910cef2408`
- `DynamicTrading`: `e21387081776e3c8c8e2ba34d419a83441be801f`

The two pre-existing `DTCommon` generated fingerprint drifts (`Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Manifest.lua` and `Registry.lua`) were reconciled through the canonical CodeBuilder recipe (`tools/semantic_harness/codebuilder/reconcile.py --apply`), restoring `reconcile.py --check` to `ok=true, clean=true, desired=407, missing=0, drifted=0, stale=0, retired_present=0, ambiguous=0` and leaving `DynamicTrading` clean against HEAD.

## 2. Frozen P0 Regression Fixtures & Corrected Tests

- Added `ProjectHoomans/tools/providers/pnc/fixtures/v1/interaction/state_aware_outcome_closure.json` (`9` cases, passes `test_lint.py`):
  - `known_identity_question_no_player_name_obligation` — FAIL (reproduces `pendingIdentityExchange.kind == PLAYER_NAME`)
  - `repeat_truthful_identity_no_reward_farming` — FAIL (reproduces duplicate `approval=2, respect=4, familiarity=12`)
  - `resolved_identity_choices_do_not_resurrect` — PASS (baseline guard; resurrection remains monitored across snapshots)
  - `already_following_typed_command_zero_dispatch` — FAIL (reproduces `dispatchTransport count == 1` on repeat)
  - `busy_blocked_typed_command_zero_dispatch` — FAIL (reproduces `dispatchTransport count == 1` when hostile/ineligible)
  - `needs_proposal_acceptance_closes_or_progresses` — FAIL (reproduces `flow:needs:proposal_pending` remaining `open`)
  - `hostile_greeting_no_friendly_continuation` — FAIL (reproduces `flow:greeting:await_thanks` opening for hostile NPC)
  - `already_member_recruitment_not_actionable` — PASS (baseline guard)
  - `accepted_relationship_proposal_not_actionable` — PASS (baseline guard)
- Corrected existing tests that blessed P0 defects:
  - `ProjectHoomans/tools/providers/pnc/tests/test_automatic_flow_generation.py`: replaced `test_generated_simple_command_uses_bounded_previous_action_memory` with `test_generated_simple_command_does_not_redispatch_when_already_following` (`dispatchCount == 0`, `len(dispatchTransport) == 0` on repeated `Follow me`).
  - `ProjectHoomans/tools/providers/pnc/fixtures/v1/interaction/context_repair_and_pronouns.json`: updated `interaction.context_repair_and_pronouns.needs_commitment_survives_topic_switch` turn `"okay"` to expect `contextAfter.dialogue.pendingFollowUp: {"absent": true}` instead of `status: "open"`.
- Preserved legitimate first-contact identity fixtures:
  - `ProjectHoomans/tools/providers/pnc/fixtures/v1/interaction/identity_pending_exchange_interruptions.json`: `13/13 PASS`.

## 3. Performance & Save-Size Baselines (Pre-S11A1)

Measured on current HEADs (`2026-11-18`):

| Metric | Measured Baseline | Notes |
| --- | --- | --- |
| One-family compile | `0.1182 ms` | `psdl_compiler.compile_convo_engine_document` (50-run avg, single `dialogue` record) |
| Full compile + reconcile check | `1733.71 ms` | `reconcile.py --recipe ... --check` across all 3 owners (`407` desired artifacts) |
| Completeness analyzer | `N/A (not implemented)` | Introduced in `S11A4` |
| Semantic-turn evaluation | `92.54 ms` | Warm `ProjectHoomans` Lua worker, 10-run avg (`w.input("Follow me")`) |
| Suggestion / snapshot generation | `46.38 ms` | Warm `ProjectHoomans` Lua worker, 10-run avg (`w.snapshot()`) |
| Memory lookup turn | `115.31 ms` | Warm `ProjectHoomans` Lua worker, 10-run avg (`w.input("What did we talk about?")`) |
| Generated artifact footprint | `407` files / `9,972,394` B | Core: `72` / `1,297,197` B; Hoomans: `323` / `8,526,882` B; DTCommon: `12` / `148,315` B |
| Representative persisted semantic payload | `27,579` B context / `142` B rel | `contextAfter` JSON (`27,579` B), `relationshipAfter` JSON (`142` B); full `snapshot` (`418,814` B) |

## 4. Legacy Surface Ownership & Classification

Every relevant surface is classified as one of `KEEP_AUTHORITY`, `ADAPT`, `MIGRATE_LATER`, `RETIRE_AFTER_PARITY`, `GENERATED_DO_NOT_EDIT`, or `UNRELATED`:

### PsychopatzCore

| Surface | Classification | Notes |
| --- | --- | --- |
| `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/ActionContract.lua` | `KEEP_AUTHORITY` | Canonical action execution & `ProjectResult` normalization seam |
| `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Offer.lua`, `Affordance.lua` | `ADAPT` | Extend to project canonical `SemanticOutcome` / state availability |
| `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/DialogueFlow.lua`, `DialogueState*.lua`, `DialogueRouter.lua`, `DialogueTurn.lua` | `ADAPT` | Generic flow/state/router runtime; must consume compiled S11 policy |
| `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticPredicate.lua` | `ADAPT` | Canonical predicate evaluator; extend for portable fact/query ops |
| `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzActorScheduler.lua` | `KEEP_AUTHORITY` | Existing actor/game-time scheduler |
| `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Inventory/*`, `Actors/PsychopatzActorInventory.lua` | `KEEP_AUTHORITY` | Core inventory/transaction authority |
| `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Dialogue/*.lua`, `Beat/**`, `Behavior/**`, `Realization/**` (recipe-owned) | `GENERATED_DO_NOT_EDIT` | Regenerated via `generation_recipe.json` |
| `tools/semantic_harness/codebuilder/{psdl_compiler,semantic_dialogue_ir,portable_runtime,reconcile,generation_recipe}.py` | `ADAPT` | Core compiler, IR, Portable Plan, and CodeBuilder recipe pipeline |

### ProjectHoomans

| Surface | Classification | Notes |
| --- | --- | --- |
| `Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Social/PNC_RelationshipService.lua` | `KEEP_AUTHORITY` | Authoritative relationship state, trust, memories, and decay |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Conversation/Memory/PNC_ConversationMemory.lua` | `ADAPT` | Existing same-day conversation memory; extend with compact semantic episodes |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Needs/PNC_MoraleModifierDefinitions.lua` | `ADAPT` | Existing morale/mood modifier definitions behind generic lifecycle |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Inventory/*`, `Semantics/PNC_SemanticInventoryQuery.lua` | `KEEP_AUTHORITY` | Authoritative inventory repository and semantic inventory query |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Scheduling/PNC_Scheduler.lua`, `server/PNC/Needs/PNC_NeedsScheduler.lua` | `KEEP_AUTHORITY` | Existing Hoomans game-time schedulers |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Dialogue/ContextState_Turns.lua` | `ADAPT` | Remove hardcoded `IDENTITY` -> `PLAYER_NAME` side-effect in `S11B` |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Dialogue/Flow_Identity.lua` | `MIGRATE_LATER` | First production reference migration (`S11B`), then `RETIRE_AFTER_PARITY` |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Dialogue/Flow_Needs.lua`, `Flow_Greeting.lua` | `MIGRATE_LATER` | Migrate in `S11C` with bounded progress, then `RETIRE_AFTER_PARITY` |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Dialogue/Flow_Weather.lua`, `Flow_Wellbeing.lua` | `MIGRATE_LATER` | Audit/migrate in `S11D` as needed |
| `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Dialogue/Suggestions_*.lua` | `ADAPT` | Consume compiled `statePolicy` / `SemanticOutcome` instead of split checks |
| `Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/**` (recipe-owned) | `GENERATED_DO_NOT_EDIT` | Regenerated via `generation_recipe.json` |
| Non-ConvoEngine Hoomans gameplay systems (e.g. `PopulationDirector`, farming, combat) | `UNRELATED` | Outside S11 semantic scope |

### DynamicTrading

| Surface | Classification | Notes |
| --- | --- | --- |
| `Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/**` (recipe-owned) | `GENERATED_DO_NOT_EDIT` | Regenerated via `generation_recipe.json` |
| DynamicTrading merchant stock, budgets, quotes, and trade authority | `KEEP_AUTHORITY` | Domain-owned trade authority |
| Non-ConvoEngine DynamicTrading gameplay | `UNRELATED` | Outside S11 semantic scope |

## 5. Existing Infrastructure Ownership (Anti-Duplication Map)

- **Action execution & result projection:** `PsychopatzCore/ConvoEngine/ActionContract.lua` (`Execute` / `ProjectResult`) — do not create a second action/outcome registry.
- **Predicates:** `PsychopatzCore/Semantics/PsychopatzSemanticPredicate.lua` + canonical IR predicate AST — do not create a second predicate DSL.
- **Conversation memory:** `PNC_ConversationMemory.lua` — extend for compact same-day semantic episodes; do not create a parallel dialogue memory store.
- **Relationships & social memories:** `PNC_RelationshipService.lua` — adapt directly; do not duplicate relationship truth.
- **Morale / mood modifiers:** `PNC_MoraleModifierDefinitions.lua` — adapt behind portable modifier lifecycle; do not build a parallel mood modifier engine.
- **Inventory queries & mutations:** `PsychopatzCore/Inventory/*` and `PNC/Core/Inventory/*` + `PNC_SemanticInventoryQuery.lua` — query/mutate through typed adapters; do not build shadow inventory state.
- **Schedulers:** `PsychopatzActorScheduler.lua` and `PNC_Scheduler.lua` — reuse for bounded game-time expiry rather than per-frame global scans.
- **Authoring & generation:** `tools/semantic_harness/codebuilder/generation_recipe.json` and `reconcile.py` — all dialogue/semantic migrations author canonical source and regenerate downstream.
