# ConvoEngine Handoff

```yaml
status: "IN_PROGRESS"
checkpoint_mode: "dirty_resumable"
phase: "S11A — State-Aware Conversation Outcome Closure / regression freeze + single state-outcome substrate"
chunk: "Freeze the full S11A P0 regression matrix, then extend the existing Core semantic contracts with one Predicate-backed StatePolicy/SemanticOutcome substrate"
primary_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
participant_vector: "psychopatz-core=e3eb7ddce389dd86129f3a40651f8e646b09afec;project-hoomans=02c7fb18e714bf1a3adce052c0659a972313f081;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
residual_worktree_fingerprints:
  psychopatz-core: "41dcb5026a1e10a950ff410c77a6fe9a7a3716b7d31238fabe1c383ff8d38970" # 4 unrelated files; active S11 docs excluded
  project-hoomans: "7d898b60000d917a9e32e914d7e7f702b15aeb313f0e2a13617c2e33c5fdc463" # 20 unrelated/concurrent files
  dynamic-trading: "c36ffffa1e4c2f0912e81c4088773a8a03cd0883167023b78ae596bea070f1ce" # 5 unrelated files
goal_doc: "Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md"
architecture_doc: "Docs/semantic_dialogue_language_standard/S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md"
branching_audit: "Docs/semantic_dialogue_language_standard/S11_BRANCHING_DIALOGUE_AUDIT.md"
evidence: "IDENTITY_STATE_DEFECTS; TYPED_COMMAND_STATE_BYPASS; NEEDS_PROPOSAL_SELF_LOOP; HOSTILE_GREETING_PARITY_DEFECT; RECRUITMENT_STALE_TRANSITION; RELATIONSHIP_PROPOSAL_STALE_TRANSITION; EFFECT_REPEAT_RISK; REFERENCE_GOOD_14_OF_14"
updated_at: "2026-11-16"
```

## What became true

S10/S10R remains an accepted harness/acceptance baseline, but developer work is reopened by new semantic-state correctness evidence. The exact production ProjectHoomans worker reproduces a known-identity contradiction: the NPC selects the correct `question.identity.known` reminder reply while the dialogue state simultaneously opens a first-contact `PLAYER_NAME` obligation and exposes stranger-only truthful/refuse/lie identity choices.

The same worker also proves that repeated truthful identity claims can reapply the `identity_introduction` relationship effect and that a later snapshot can resurrect first-contact identity choices after live pending state has cleared.

A full branching/state audit then reproduced the same class outside identity: typed repeated companion commands bypass eligibility, the needs proposal branch self-loops without closure, hostile greeting can acquire a friendly follow-up, recruitment/proposal affordances stay stale after successful state changes, and several natural free-text equivalents for stateful root actions have no owned semantic route. Effectful authored wellbeing/trust/affinity choices also lack explicit repeat semantics.

The normative S11 goal is:

`Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`

Approved no-split-system architecture:

`Docs/semantic_dialogue_language_standard/S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`

Mandatory cross-dialogue audit:

`Docs/semantic_dialogue_language_standard/S11_BRANCHING_DIALOGUE_AUDIT.md`

The architecture decision is explicit: extend the existing Core Predicate / Offer / capability / flow contracts. Do not create a second state store, capability registry, eligibility engine, typed-input state engine, condition DSL, or repeat/cooldown subsystem.

The core product invariant is now explicit: state-constrained suggestions and typed/free-text input must consume the same authoritative semantic state/outcome classification, and every recognized reachable constrained state must have an immersive reply/effect/no-op outcome.

## Immediate Next Chunk

S11A only:

1. freeze the identity known/reconfirmation, duplicate-reward, and stale-choice cases as failing real-worker tests;
2. freeze the additional P0 branching regressions: repeated FOLLOW/STAY/GO HOME/CAMP and busy-command bypass, needs `proposal_pending` self-loop, hostile greeting/friendly-follow-up contradiction, recruitment post-success stale affordance/duplicate request, and relationship-proposal post-accept stale affordance;
3. map authoritative directional identity facts and overlapping transition ownership for identity, greeting, needs and wellbeing;
4. implement the approved Core substrate by extending current semantic contracts:
   - `PsychopatzSemanticPredicate` remains the single condition language/evaluator;
   - existing capability/flow descriptors gain `statePolicy`, `inputPolicy`, `repeatPolicy`, and optional postcondition/presentation metadata;
   - one canonical `SemanticOutcome` shape owns generic state classification and admission mode;
   - the existing CapabilityCatalog discovers the new fields;
   - CandidateEligibility remains parse/context eligibility only;
5. add schema/negative acceptance proving stateful public actions cannot bypass or duplicate the shared substrate;
6. reconcile tests that currently bless duplicate dispatch or contradictory pending behavior.

Do not begin the broad S11C rewrite before these regressions are executable and the shared substrate exists. Identity remains the first domain migration, followed immediately by companion commands as the proof that the contract is generic.

## Expensive discoveries worth preserving

- `identityState == "known"` is principally player knowledge of the NPC, not proof that the NPC knows the player's identity.
- `ContextState_Turns.lua` currently creates `pendingIdentityExchange` for every IDENTITY question without classifying first contact versus reminder/reconfirmation.
- the server identity path currently maps each accepted truthful claim to the same first-introduction relationship effect;
- immediate post-click state and later snapshot projection can disagree about whether the identity exchange is still pending;
- native/menu refresh logic preserves session-local menu options and therefore state-sensitive choices must be revalidated rather than blindly retained;
- Core already provides `PsychopatzSemanticPredicate`; Core `Offer` already owns semantic affordance/frame/constraints; ProjectHoomans capability descriptors already own `permissionGate`, `outcomeMapping`, and `responsePools`; S11 must extend these instead of creating parallel machinery;
- current state constraints already exist across identity, companion orders, gossip, relationship, gifts, tasks, cooldowns and knowledge; S11 should unify outcome ownership rather than create another state store;
- repeated FOLLOW/STAY/GO HOME/CAMP and busy-state FOLLOW currently dispatch through typed input despite suggestion-state restrictions;
- `Flow_Needs.proposal_pending` is an unbounded self-loop on ACCEPT/AGREE without authoritative progress;
- hostile greeting has dual ownership: native parley presentation and semantic greeting flow can disagree on follow-up state;
- recruitment and relationship proposal authority can change state without invalidating the next suggestion snapshot;
- parameterized task authority, quest lifecycle, gossip, gift consent, event follow-ups and departure confirmation contain useful reference patterns and should be preserved rather than rewritten blindly;
- effectful authored wellbeing/trust/affinity branches have no explicit repeat policy and therefore require an idempotence/repeat audit.

## Boundaries

PsychopatzCore owns the reusable `StatePolicy` / `SemanticOutcome` contract, generic validation/outcome vocabulary, existing Predicate integration, and acceptance mechanisms. It does not own ProjectHoomans gameplay state.

ProjectHoomans owns identity/relationship/companion/task/etc. gameplay authority, bounded state projection into the shared contract, conversation lifecycle, authoritative effects, and adopter reply content. Its UI/suggestion/input paths must consume the Core contract rather than maintain independent state truth.

DynamicTrading is a compatibility participant only unless shared ConvoEngine changes reach its provider/adopter surfaces.

Preserve all unrelated dirty work in all three repositories. ProjectHoomans currently contains substantial unrelated job/docs/CommandHub **and concurrent Starting Companion/character-creation work** (20 residual paths at this handoff); do not overwrite, reset, stash, or broad-stage it. Re-read current status before edits because that work changed during this audit.

Do not launch native Project Zomboid, publish Workshop content, push, PR, amend, rebase, or force-update without explicit authorization.

## Acceptance for S11A

S11A is accepted only when the identity regressions **and the P0 branching matrix from `S11_BRANCHING_DIALOGUE_AUDIT.md`** are frozen as executable tests, the single-system substrate from `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md` is implemented/discoverable, overlapping transition ownership is mapped, and the implementation can answer from canonical state rather than presentation text:

- Is this semantic act actionable, already satisfied/redundant, pending/active, blocked, completed, unavailable, or another explicit state outcome?
- For identity, is this first introduction, reconfirmation, repetition, correction, or deception/evasion follow-up?
- Does the equivalent button show/hide/disable/alternate?
- What happens when the player types the same semantic action manually?
- Is a gameplay effect admitted, no-op, rejected, deferred, or routed to confirmation?
- Which contextual NPC response family owns the outcome?
- What state must the next response-channel/root projection observe?
- If multiple presentation systems cover the topic, which single authority owns its state transition?
- Which existing capability/flow descriptor owns `statePolicy`, `inputPolicy`, `repeatPolicy`, and authoritative result mapping?
- Can the same projected state + semantic capability produce one canonical SemanticOutcome regardless of button or free-text provenance?

A S11A implementation that introduces a parallel state/action/eligibility/repeat registry fails the phase even if focused tests become green.

The full parent goal remains S11A-S11E. Do not return to `USER_ACCEPTANCE` after only the identity screenshot or one branching family is fixed.
