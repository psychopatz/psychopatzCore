# S11 — State-Aware Conversation Outcome Closure

**Status:** ACTIVE — opened by native/Semantic Lab regression evidence on 2026-11-16.  
**Parent goal:** ConvoEngine / Semantic Harness full immersive conversation correctness.  
**Accepted baseline retained:** S0-S10 + S10R infrastructure and acceptance integrity remain accepted unless S11 evidence directly disproves a retained behavior.  
**Primary adopter:** ProjectHoomans.  
**Participant scope:** PsychopatzCore owns reusable semantic/state contracts and acceptance mechanisms; ProjectHoomans owns gameplay-specific state predicates, identity/relationship effects, conversation projection, and adopter replies; DynamicTrading participates only where the shared ConvoEngine contract or provider compatibility is affected.  
**User value:** button suggestions, typed/free-text input, NPC replies, gameplay effects, and the next response channel all agree with the actual world/conversation state instead of exposing contradictory or already-resolved choices.

**Mandatory branching audit:** `S11_BRANCHING_DIALOGUE_AUDIT.md` is a normative scope input for S11C/S11D. Every maintained family classified there as a confirmed defect or high-risk state branch must be repaired or explicitly classified, and every reference-good family must remain regression-protected.

**Approved architecture:** `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md` is normative for S11A-S11D. S11 must extend the existing Core Predicate / Offer / capability / flow contracts into one state→outcome path. Creating a second semantic state store, action registry, suggestion eligibility engine, typed-input state engine, repeat engine, or UI-owned state authority is out of scope.

## Why S11 exists

Native/Semantic Lab testing after S10R exposed a developer-side correctness regression that the accepted harness now makes reproducible.

For an NPC whose identity is already known, the current production path can correctly answer:

```text
PLAYER: What's your name?
NPC: I'm Mara Vale. We already know each other.
```

while the same turn also opens a first-introduction obligation and renders:

```text
Say your real name
Don't tell your name
Lie about your name
```

This is contradictory state handling, not a wording-only defect.

Fresh real-worker reproduction also proved two more failures:

1. a truthful repeated identity claim can apply the first-introduction relationship reward again;
2. after the authoritative identity exchange clears the pending obligation, a later snapshot can resurrect the same three identity choices.

S11 therefore reopens developer work after S10R. S10R acceptance integrity remains useful and retained; its job was to ensure the harness truthfully reports behavior. S11 fixes the newly exposed behavior.

## Verified regression evidence

### R1 — known identity question creates a first-contact obligation

The response layer correctly recognizes a known NPC and selects `question.identity.known`.

However `ContextState_Turns.lua` currently treats every:

```text
intent = QUESTION
subject = IDENTITY
```

as sufficient to create:

```text
pendingIdentityExchange = {
    kind = "PLAYER_NAME",
    requestedAt = <sequence>
}
```

without first classifying whether the exchange is first contact, reminder, reconfirmation, correction, deception follow-up, or already resolved.

An existing Lua smoke test currently encodes this behavior as expected, while the contextual-talk parity suite separately expects known companions not to expose the stranger identity affordance. S11 must reconcile those contracts.

### R2 — identity knowledge is directional but current conversation logic collapses it

`identityState == "known"` primarily means that the **player knows the NPC identity**.

Whether the NPC knows the player's identity is represented through relationship/identity-interaction history and related projections.

Those are separate facts. A response such as:

```text
"We already know each other."
```

must not be used as proof that both directions of identity knowledge are established unless the authoritative state actually supports that conclusion.

S11 must preserve the two directional facts:

```text
NPC identity known to player
Player identity known to NPC
```

without inventing a second parallel state store.

### R3 — repeated truthful identity claims can duplicate first-introduction effects

Fresh worker reproduction showed:

```text
first truthful claim:
  approval     +1
  respect      +2
  familiarity  +6

repeat truthful claim:
  approval     +1 again
  respect      +2 again
  familiarity  +6 again
```

The authoritative server currently routes each accepted truthful claim through the `identity_introduction` effect.

First introduction, reconfirmation, repetition, correction, and known-person joking/deception require different effect policies. Repetition must not farm first-introduction relationship rewards.

### R4 — resolved identity choices can resurrect after refresh/snapshot

Immediately after a truthful identity choice, the live dialogue context can report:

```text
pendingIdentityExchange = nil
```

and the immediate semantic projection can stop exposing the three first-contact identity choices.

A following worker snapshot can nevertheless present those choices again with:

```text
reason = identity_exchange_pending
```

This proves a stale/reconstructed presentation-state seam exists between live dialogue authority and later suggestion/view projection.

Native root-menu reconstruction has a related risk: state-sensitive menu options are preserved across context refresh and can outlive the state that made them eligible.

### R5 — state constraints are fragmented across UI, policy, action, and reply paths

Current production code already has useful state checks for identity facets, companion ownership, hostility, busy/combat/dead/incapacitated states, follow/stay toggles, base/home state, safe gossip, relationship proposal eligibility, gift consent, pending follow-ups, cooldowns, task lifecycle, and known facts.

The problem is ownership fragmentation:

```text
suggestion provider      -> button eligibility
parser/policy            -> typed-input meaning
action/server adapter    -> execution admission/effect
response layer           -> reply wording
view refresh             -> next response channel
```

Those layers can currently disagree.

S11 establishes a state/outcome contract that every layer consumes rather than adding more one-off button patches.

## Normative S11 invariant

For every state-constrained semantic family:

> One authoritative state evaluation must determine whether the semantic act is actionable, redundant, pending, blocked, unavailable, already satisfied, or otherwise state-specific. Button suggestions and free-text input must consume the same semantic classification. Every understood free-text turn must resolve to a state-appropriate reply/effect/no-op outcome even when the equivalent button is hidden or disabled.

A hidden button is **not** permission for typed input to fall into an open-ended or generic response.

A typed input is **not** permission to bypass state authority merely because the parser recognized its semantics.

Rendered wording remains presentation. It may not become state authority.

## Required architecture contract

The detailed approved design is `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`.

The central architectural rule is:

> Semantic IR describes meaning. Existing authoritative game systems describe reality. The existing semantic capability/flow contract, extended with one Core Predicate-based StatePolicy, combines those into one canonical SemanticOutcome. Suggestions, typed input, flow transitions, responses, effects and post-turn projections consume that outcome; no parallel semantic state or eligibility engine exists.

### 1. Reuse existing authoritative state

Do not introduce a second relationship store, identity store, task store, companion-order store, knowledge store, or UI-owned shadow state.

State evaluation must consume existing canonical/adopter projections such as:

- player-scoped NPC presentation/knowledge;
- relationship and interaction history;
- dialogue context obligations;
- actor authority/capability state;
- NPC task/order/behavior/health state;
- gift/task/event lifecycle;
- world/base/destination facts;
- existing ConvoEngine predicates and response outcomes.

Core owns the portable `StatePolicy` / `SemanticOutcome` contract, validation, generic outcome/admission vocabulary, and reuses the existing `PsychopatzSemanticPredicate` evaluator. ProjectHoomans projects its existing authoritative gameplay facts into that contract and keeps gameplay-specific predicates/reasons/effects.

Do not add a parallel `StatefulDialogueRegistry`, second capability catalog, second condition DSL, second repeat/cooldown engine, or a persistent semantic shadow copy of gameplay state.

### 2. Separate semantic availability from presentation policy

A state evaluation must be capable of expressing, at minimum, the concepts needed to distinguish:

```text
actionable
redundant / already satisfied
pending / already active
completed
blocked
unavailable
unknown / insufficient state
ambiguous
```

Exact enum names are implementation decisions; do not create enum proliferation when an existing outcome vocabulary can be extended cleanly.

The result must provide enough stable reason/outcome data for callers to choose:

```text
SHOW
HIDE
DISABLE
ALTERNATE
```

without reimplementing the underlying state test.

### 3. Clicked suggestions and typed input share outcome semantics

Equivalent semantic actions reached through:

- a root menu;
- a response-channel button;
- a generated affordance;
- a typed/free-text input;
- a compatible provider route;

must converge before authoritative effect selection.

They may have different presentation/provenance, but they may not disagree on whether the current state is already satisfied, blocked, pending, or actionable.

### 4. Every recognized constrained turn has an immersive outcome

For recognized semantic input, state-specific outcomes must exist for reachable cases.

Examples:

```text
FOLLOW while already following
  -> no duplicate order
  -> "I'm already following you."

STAY while already staying
  -> no duplicate order
  -> "I'm already staying here."

GO HOME while already returning
  -> no duplicate return-home admission
  -> "I'm already on my way back."

known fact requested again
  -> reminder/reconfirmation reply
  -> no duplicate disclosure consequence

known identity stated again
  -> reconfirmation/reminder
  -> no first-introduction reward
```

Generic `"I can't do that yet."` remains valid only when the actual classified outcome is genuinely generic and no more truthful state-specific outcome exists.

### 5. Post-turn projection must be monotonic with accepted state transitions

Once an authoritative action resolves a pending obligation or changes eligibility, every subsequent suggestion/menu/snapshot projection must consume the new state.

A completed/cleared obligation may not resurrect because:

- an old response-channel projection survived;
- stale `conversationMenuOptions` were preserved;
- a root refresh rebuilt from pre-action context;
- worker snapshot rehydration read an obsolete copy;
- provider-local state disagreed with live dialogue state.

Refresh/preservation logic may retain closures or presentation metadata only when their state-sensitive eligibility is revalidated.

## Identity reference implementation

Identity is the mandatory first implementation because it demonstrates every S11 concern: directional knowledge, pending obligations, state-aware UI variants, authoritative effects, relationship mutation, and post-turn refresh.

### Identity state distinctions

The implementation must be able to distinguish at least these concepts using existing authoritative data:

```text
NPC identity unknown to player
NPC identity known to player

player identity unknown to NPC
player identity known/trusted by NPC
player previously deceptive/evasive
identity exchange currently pending
```

Do not infer reciprocal knowledge solely from `identityState == "known"`.

### First-contact identity behavior

When the NPC genuinely does not know the player's identity and the dialogue creates a player-name obligation, the existing three semantic choices remain valid:

```text
Say your real name
Don't tell your name
Lie about your name
```

S10A's accepted label-versus-spoken-speech contract remains mandatory:

- compact UI label;
- natural initiating `say`;
- typed semantic claim/evasion;
- authoritative server validation;
- no label-to-speech fallback.

### Known/reconfirmation identity behavior

If the NPC already knows the player's identity, a repeated typed identity statement must be treated as reconfirmation/repetition, not a new introduction.

State-aware response-channel variants may include equivalent semantics such as:

| Semantic act | First contact label | Known/reconfirmation label |
| --- | --- | --- |
| truthful claim | Say your real name | Remind them of your name |
| refusal | Don't tell your name | Refuse to repeat it |
| deceptive claim | Lie about your name | Lie anyway / give another name |

Exact wording should use the canonical authoring/realization system and localization; the table defines semantic distinctions, not mandatory literal strings.

NPC replies for known/reconfirmation outcomes should use contextual variants, for example:

```text
"I know, Patrick."
"Yeah, Patrick. I remember."
"You don't need to introduce yourself again."

"Fair enough. I already know who you are."

"Nice try, Patrick."
"You're not fooling me. I know your name."
```

These examples are acceptance guidance. They must be authored through the existing response/realization architecture rather than concatenated as one-off runtime strings.

### Known NPC name question behavior

If the player asks a known NPC:

```text
"What's your name?"
```

the NPC may still answer naturally with a reminder response.

That question must **not automatically create a first-contact `PLAYER_NAME` obligation**.

If design intentionally wants a reciprocal reconfirmation beat, it must be represented as a distinct state/outcome from first introduction and must use known-state response-channel variants.

### Identity effect policy

Mandatory rules:

- first accepted truthful introduction may apply the existing first-contact relationship effect;
- truthful reconfirmation/repetition must not reapply the first-introduction reward;
- repeated canonical identity text must be idempotent with respect to first-introduction reward;
- known-person refusal must not automatically reuse the first-contact evasion penalty unless authoritative policy explicitly classifies it as an actual evasion;
- deceptive known-person claims may produce a social/deception consequence, but may not overwrite canonical identity or masquerade as first contact;
- generated alias handling remains authoritative and server-validated;
- existing identity memory/history must remain bounded and deterministic.

## Cross-domain constraint sweep

After identity is correct, audit every maintained stateful conversation family.

At minimum cover:

### Companion commands and movement

- FOLLOW already following;
- STAY when following versus already holding;
- GO/return-home with no base, already home, or already returning;
- CAMP already active/in progress, no usable site, unsafe/busy/combat;
- WAIT_AT destination-required and active-task states;
- dead/incapacitated/hostile/busy authority restrictions.

### Knowledge and conversation topics

- NPC identity and identity facets already known;
- known backstory/knowledge facts;
- gossip unavailable versus safe gossip available;
- repeated fact requests;
- relationship-status questions after already answered state;
- conversation follow-up obligations and cooldowns.

### Relationship/social actions

- proposal/recruitment when already in an incompatible/established state;
- disband/departure when not applicable;
- hostile/rival state restrictions;
- repeated social acts with cooldowns or already-applied consequences.

### Gifts, inventory, tasks, quests, events

- pending gift selection/consent;
- already-completed or active task stages;
- duplicate requests;
- already-satisfied consume/eat/drink/refill states;
- completed/rejected/failed lifecycle outcomes;
- expired/closed event follow-up windows.

This sweep is evidence-driven. Do not rewrite unrelated dialogue merely to normalize wording.

## Required machine-readable coverage

S11 must add a bounded acceptance inventory/matrix for state-constrained semantic families.

Each maintained family must identify:

```text
semantic family/action
authoritative state source
reachable state/outcome
button presentation policy
typed-input behavior
authoritative effect policy
NPC response owner
post-turn projection expectation
acceptance owner
```

This matrix may extend an existing Feature Acceptance Registry or another canonical machine-readable acceptance surface if that is the cleanest ownership seam. Do not create a duplicate registry solely for S11.

A newly added state-constrained public semantic action must fail validation if it has no state/outcome acceptance ownership.

## S11 phase plan

### S11A — regression freeze + single semantic state/outcome substrate

**State:** ACTIVE.

1. Freeze the identity and branching-audit P0 regressions before behavior repair: known/reconfirmation contradiction, duplicate identity reward, stale identity choices, repeated FOLLOW/STAY/GO HOME/CAMP and busy-command bypass, needs proposal self-loop, hostile greeting follow-up contradiction, recruitment stale transition/duplicate request, and relationship-proposal stale transition.
2. Inventory current state predicates and outcome/reply ownership across Core and ProjectHoomans; record overlapping transition ownership for identity, greeting, needs and wellbeing.
3. Implement the approved `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md` substrate in Core by extending existing semantic structures rather than adding parallel registries:
   - one Predicate-based `StatePolicy` evaluator;
   - one normalized `SemanticOutcome` shape;
   - bounded generic outcome/admission vocabulary;
   - descriptor fields for `statePolicy`, `inputPolicy`, `repeatPolicy`, and optional `expectedPostconditions`/presentation mapping;
   - discovery through the existing capability catalog;
   - validation for malformed/missing stateful contracts.
4. Keep CandidateEligibility limited to parse/context eligibility; stateful gameplay admission must happen after candidate selection through the shared StatePolicy path.
5. Make directional identity knowledge explicit as a projection of existing authority without adding a second identity store.
6. Add negative tests proving a stateful public capability cannot silently introduce a second/unowned state path.

**Gate:** P0 regressions are frozen; the shared Core substrate exists and is discoverable; no new parallel state/action/eligibility registry exists; stateful descriptors can produce canonical SemanticOutcome diagnostics from projected authoritative state; identity/companion repairs can consume the substrate without UI-owned state truth.

### S11B — identity reference migration onto the shared substrate

1. Migrate identity onto the S11A StatePolicy/SemanticOutcome substrate; do not implement a separate identity state evaluator.
2. Stop known-NPC reminder questions from automatically creating first-contact player-name obligations.
3. Add first-contact versus reconfirmation/repetition identity outcome classification.
4. Add known-state response-channel variants for truthful/refuse/lie semantics where a reciprocal beat is actually active.
5. Route free-text identity input through the same state classification.
6. Make first-introduction relationship effects idempotent.
7. Revalidate/rebuild state-sensitive root/response-channel choices after authoritative identity results.
8. Eliminate snapshot/refresh resurrection of resolved identity choices.
9. Preserve S10A label/speech separation and natural realization variants.
10. Prove button and typed identity routes emit the same canonical SemanticOutcome for the same projected state before presentation-specific wording is selected.

**Gate:** all identity routes consume the shared substrate and produce state-correct replies/effects; repeated truthful claims cannot farm relationship rewards; resolved first-contact choices do not reappear; no identity-only shadow state/eligibility engine was introduced.

### S11C — constrained-domain parity sweep

`S11_BRANCHING_DIALOGUE_AUDIT.md` defines the required sweep and its evidence classification. S11C must not stop after identity.

1. Migrate companion-order state rules out of suggestion-only ownership and onto the same capability `statePolicy` consumed by suggestions and typed input. Cover already-following, already-staying, already-returning/home, camp-active, busy/combat/hostile/dead/incapacitated and related state reasons; typed commands must not bypass the same canonical SemanticOutcome that shapes suggestions.
2. Close the needs/proposal flow so accepted input cannot remain in an unbounded `proposal_pending -> proposal_pending` loop without authoritative progress/defer/cancel semantics.
3. Reconcile greeting/parley state ownership so hostile/busy/combat/dead/incapacitated actors cannot receive contradictory friendly follow-up obligations through typed input.
4. Repair recruitment and relationship-proposal post-transition projection; repeated input must reach already-member/already-lover/cooldown outcomes without duplicate mutation/request admission.
5. Classify every stateful root action with natural conversational meaning as `typed_parity_required`, `typed_routes_to_confirmation`, or `presentation_only_by_design`; departure/disband must preserve its warning/confirmation boundary.
6. Carry `repeatPolicy` through the existing PSDL/dialogue-block compiler and existing conversation history/repeat machinery; do not create a second repeat/cooldown subsystem. Audit every effectful PSDL branch for explicit one-shot, cooldown/max-use, state-retired, idempotent, or intentionally-repeatable semantics. Relationship effects must not be farmable through category repetition.
7. Add production-state parity for parameterized tasks and quest lifecycle stages; preserve their existing specific authority reasons and response families.
8. Apply the contract to knowledge/gossip/fact repetition, gifts/consent, event follow-ups, settlement/ambient visits, territory, ceasefire and pragmatic social repair where the audit requires coverage.
9. Retain domain-specific authority/effects in the owning adopter; do not centralize ProjectHoomans gameplay policy in Core.
10. Preserve the audit's reference-good contracts for wellbeing convergence, event-window expiry, grounded gossip unknown handling, gift consent/expiry, departure confirmation, settlement expiry and pragmatic apology/reconciliation.

**Gate:** every family listed in `S11_BRANCHING_DIALOGUE_AUDIT.md` has a final classification of repaired, explicitly presentation-only, or reference-good/regression-protected; every maintained constrained family has button/free-text/effect/reply/repeat/post-transition coverage; and all migrated families use the same existing-registry StatePolicy/SemanticOutcome substrate rather than domain-specific duplicate evaluators.

### S11D — real-surface outcome-closure acceptance

Run the regression through:

1. focused Lua/state-policy tests;
2. real manifest-selected ProjectHoomans worker;
3. real response-channel click path;
4. free-text/inputbox path;
5. real Tk/Xvfb Semantic Lab conversation UI;
6. snapshot/restart/reconfigure lifecycle where state persistence matters.

Add adversarial repeat loops. For identity, state the same canonical name at least ten times after the first accepted introduction and prove no additional first-introduction approval/respect/familiarity is applied.

Add negative acceptance proving a newly introduced stateful semantic action without outcome ownership fails validation.

S11D must also exercise the branching-audit regressions through the real worker/inputbox and, where user-visible, real Tk/Xvfb surfaces: repeated companion commands, needs proposal closure, hostile greeting/parley, recruitment transition, relationship proposal transition, destructive typed confirmation, effectful authored-choice repeat policy, active task state and real quest lifecycle transitions.

**Gate:** automated developer acceptance proves no reachable constrained semantic state in the mandatory branching audit is button-only, typed-input-open-ended, effect-duplicating, unbounded-self-looping, or stale-projection-dependent.

### S11E — retained acceptance and closure

1. Re-run focused S10A label/speech acceptance.
2. Re-run all S11 identity/state-parity suites.
3. Re-run canonical nine-suite `--acceptance`.
4. Preserve S10R signature-based unrelated-baseline rules; do not widen waivers to hide S11 failures.
5. Reconcile ROADMAP/PROGRESS/HANDOFF and any stable architecture/runbook contracts actually changed.
6. Commit changed adopter repositories first and Core last using exact phase-owned paths.
7. Record exact participant commit vector and residual-work fingerprints.
8. Do not push, publish Workshop content, or launch native Project Zomboid without explicit authorization.

**Gate:** only after S11A-S11E are accepted may the project return to `USER_ACCEPTANCE`.

## Mandatory regression scenarios

### Scenario A — known NPC, typed name question

Precondition:

```text
NPC identity known to player
```

Action:

```text
PLAYER: What's your name?
```

Required:

- NPC selects known/reminder response;
- no first-contact `PLAYER_NAME` obligation is created merely because the question subject is IDENTITY;
- first-contact real/refuse/lie choices do not appear;
- if a reconfirmation beat is intentionally opened, it uses a distinct known-state contract;
- next snapshot/UI refresh agrees with the resolved state.

### Scenario B — first introduction

Precondition:

```text
player identity not yet known to NPC
first-contact player-name obligation active
```

Required:

- truthful/refuse/lie choices appear;
- button labels remain presentation-only;
- selected player line is natural semantic `say`;
- server validates canonical/generated claims;
- first truthful introduction applies its relationship effect exactly once;
- pending first-contact obligation clears.

### Scenario C — repeated truthful identity

After Scenario B, submit multiple equivalent free-text claims and/or truthful response-channel actions.

Required:

- classified as reconfirmation/repetition;
- NPC gives a known-state reply;
- no duplicate `identity_introduction` reward;
- no new first-contact obligation;
- no first-contact choices resurrect.

### Scenario D — known-person refusal and lie

With player identity already known to the NPC:

- refusal/rebuff gets a known-state contextual outcome and does not automatically count as first-contact evasion;
- a deliberate false name gets an appropriate known-person deception/joking response according to policy;
- canonical identity remains unchanged;
- no first-contact reward is possible.

### Scenario E — stateful command parity

For at least FOLLOW/STAY/GO HOME:

- button eligibility reflects current state;
- manually typing the redundant command still receives the matching already-satisfied reply;
- no duplicate command/effect is admitted;
- response-channel refresh presents the newly actionable inverse/next action where appropriate.

## Acceptance principles

S11 is not complete because one screenshot looks correct.

Developer acceptance requires all of the following:

1. **state authority:** one semantic state classification per constrained act, sourced from canonical state;
2. **surface parity:** clicks and typed/free-text input resolve through the same state outcome;
3. **outcome closure:** every recognized reachable constrained state has an immersive response/effect/no-op;
4. **effect idempotence:** repeated already-satisfied actions cannot reapply first-time gameplay consequences;
5. **projection correctness:** completed/cleared state does not resurrect stale choices after refresh/snapshot/restart;
6. **directional knowledge correctness:** NPC-known-to-player and player-known-to-NPC are not conflated;
7. **presentation separation:** UI labels and rendered speech remain non-authoritative presentation;
8. **extensibility:** a new stateful semantic action cannot silently ship without state/outcome acceptance ownership;
9. **retained compatibility:** S10A, S10R, provider lifecycle, DynamicTrading compatibility, and canonical acceptance remain green unless an intentional contract change is explicitly reconciled.

## Non-goals

- Do not replace the existing parser with an LLM or use generated prose as state authority.
- Do not add a parallel relationship/knowledge/task state store.
- Do not make every state-specific button visible; hiding redundant actions remains valid when typed input still has a closed contextual outcome.
- Do not hard-code the screenshot sentence or one NPC/persona as the solution.
- Do not solve only the Semantic Lab projection while leaving native Project Zomboid conversation state inconsistent.
- Do not solve only the native menu while leaving the worker/harness inconsistent.
- Do not rewrite all dialogue families or translations without state/evidence need.
- Do not weaken server authority for identity, relationships, tasks, or knowledge.
- Do not broaden unrelated-baseline/skip policy to make S11 green.
- Do not push, PR, release, publish Workshop content, or launch native Project Zomboid without explicit user authorization.

## Completion boundary

S11 is developer-complete only when:

1. the identity regression is reproduced and fixed through the real production worker;
2. known identity questions no longer create first-contact obligations by default;
3. first introduction and reconfirmation/repetition are distinct outcomes;
4. repeated truthful identity claims cannot duplicate first-introduction relationship rewards;
5. known-state truthful/refuse/lie routes have appropriate response-channel/free-text outcomes;
6. resolved identity choices remain resolved through refresh/snapshot/restart;
7. all maintained constrained conversation families have button/free-text/effect/reply state coverage;
8. a machine-readable acceptance owner prevents new stateful semantic actions from shipping without outcome coverage;
9. real Tk/Xvfb acceptance exercises both response-channel click and inputbox routes;
10. canonical nine-suite acceptance and retained S10/S10R gates pass;
11. continuity docs and exact participant/residual checkpoint truth are reconciled;
12. accepted phase work is locally committed without automatic push/publication.

Only then return to user-owned native Project Zomboid acceptance.
