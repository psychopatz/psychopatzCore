# ConvoEngine Handoff

~~~yaml
status: DIRTY_RESUMABLE
checkpoint_mode: committed_handoff
phase_commit: self
phase: S11C — companion commands + Needs + Greeting (S11B accepted)
chunk: S11C — companion commands, Needs, and Greeting state-aware closure
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
foundation_order_doc: Docs/semantic_dialogue_language_standard/S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md
updated_at: 2026-11-18T08:11:30Z
~~~

## What became true in S11B

- Migrated `question_identity.json` (`offer.question.identity`) to carry S11 `statePolicy` (`already_known` -> `no_op`, `first_contact_question` -> `dispatch`), `inputPolicy: "typed_parity"`, `repeatPolicy: "state_retired"`, `postconditions`, and `closure`, and reconciled all three owners via `reconcile.py --apply` (`clean=true`).
- Fixed known-NPC identity question obligation leak in `Input_Context.lua` (`Internal.RecordContextTurn` passing `ShallowContext(view).identityState`) and `ContextState_Turns.lua` (`not identityKnown` guard on `pendingIdentityExchange`), and fixed repeat truthful identity reward farming in `PNC_PlayerKnowledgeCommands_Identity.lua` (idempotent guard on `before.identityTrust == "trusted"` / `identity_introduction` memory).
- Verified `16/16 PASS` across all Identity P0 cases (`known_identity_question_no_player_name_obligation`, `repeat_truthful_identity_no_reward_farming`, `resolved_identity_choices_do_not_resurrect`) and all `13/13` `identity_pending_exchange_interruptions` cases.

## Immediate Next Chunk

Execute **S11C** (companion commands `FOLLOW`/`STAY`/`GO HOME`/`CAMP`, Needs `proposal_pending`, and Greeting hostile/friendly coherence).
