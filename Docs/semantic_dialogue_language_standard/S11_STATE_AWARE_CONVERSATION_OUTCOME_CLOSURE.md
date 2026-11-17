# S11 — State-Aware Conversation Outcome Closure

**Status:** ACTIVE — post-G9 architecture reconciled; implementation not yet started.
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

The authoritative execution order is `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`. The detailed normative designs are S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md, S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md, S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md, S11_COMPILER_RUNTIME_OPTIMIZATION.md, and S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md.

Implementation follows compact ConvoEngine/PSDL source → Canonical Semantic Dialogue IR → Portable Dialogue Plan → descriptor-selected backend/generated runtime → typed ActionContract/capability adapter → authoritative adopter gameplay state.

Canonical source owns statePolicy, inputPolicy, repeatPolicy, optional postcondition/presentation policy, and the compact portable facts/effects/modifier declarations defined by S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md. Existing gameplay state remains truth. Reuse the existing predicate AST / PsychopatzSemanticPredicate. Equivalent click/free-text routes must produce the same canonical state outcome before presentation-specific wording. Actor/target item constraints, relationship/mood checks, immediate effects, and timed modifiers must normalize into portable IR and registered adopter domain schemas rather than raw persistence paths or opaque Lua callbacks.

The pre-admission state result and existing ActionContract result lifecycle form one normalized outcome contract. If dispatch is admitted, use ActionContract.Execute; normalize authority through ActionContract.ProjectResult. Do not create a second action/result registry merely named SemanticOutcome.

Recognized constrained input must close through owned reply/effect/no-op/confirmation/defer semantics. Effectful repeat policy uses existing history/repeat machinery. State-changing outcomes rebuild state-sensitive projection from fresh authority.

Behavioral S11 regressions are declarative-first through provider fixtures; imperative tests remain for compiler/schema, Portable Plan/Reference VM, backend parity, ActionContract lifecycle, GUI/protocol/static/performance responsibilities.

S11 fails if it introduces runtime-Lua-only policy absent from canonical source/Portable Plan, a second state/action/capability registry, second predicate DSL, domain-specific relationship/mood/inventory mini-DSLs that bypass canonical normalization, suggestion-only or typed-only gameplay-state authority, response-side state re-derivation, second repeat/cooldown/modifier-lifecycle system, persisted semantic shadow truth, or generated-file hand edits as semantic authoring.

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

The compiler must also own a machine-readable Dialogue Completeness Report derived from canonical IR/Portable Plan. For each maintained family it must classify reachable closure/progress, unhandled state/action outcomes, pending obligations, cycles, memory residue, and fixture coverage. Semantic Lab/Studio consume this report rather than reimplementing graph analysis.

Every terminal branch with meaningful residue must classify that residue as none, resolved episode, durable fact reference, open/deferred domain obligation, or state transition. Same-day semantic episodes enrich the existing ConversationMemory; they do not create another memory store.

## S11 phase plan

### S11A — foundation build and freeze before production migration

**State:** ACTIVE.

The exact execution order is normative in `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md` and ROADMAP S11A:

```text
S11A0  preflight + baselines + legacy ownership inventory
S11A1  canonical data-model freeze
S11A2  compact source → canonical IR → Portable Dialogue Plan
S11A3  Reference VM ↔ PZ/Lua structural parity
S11A4  Dialogue Completeness Analyzer over the frozen model
S11A5  direct adapters to existing authoritative domain systems
S11A6  memory/modifier lifecycle
S11A7  compiler/runtime optimization
S11A8  FOUNDATION FREEZE GATE
```

No production legacy semantic-family migration is allowed before S11A8.

S11A0 must classify relevant current surfaces as KEEP_AUTHORITY / ADAPT / MIGRATE_LATER / RETIRE_AFTER_PARITY / GENERATED_DO_NOT_EDIT / UNRELATED. S11A1-A3 use synthetic/minimal semantic fixtures to develop the generic compiler model instead of repeatedly migrating production dialogue while the schema is moving.

S11A4 is intentionally after the canonical model and backend structural parity so the analyzer is built once against ParticipantSet/roles, facts/actions/effects/modifiers, memory residue, semantic beats/archetypes and continuation/closure rather than retrofitted repeatedly.

S11A5 adapts existing RelationshipService, inventory authority, morale/mood authority, ConversationMemory and ActionContract directly. It must not create compatibility shims, fallback readers, dual stores/registries, or old/new execution paths.

Dialogue/semantic content migration must use canonical CodeBuilder source/recipes. The recipe ledger is `tools/semantic_harness/codebuilder/generation_recipe.json`; use recipe-driven `reconcile.py --check` / `--apply`. Generated Lua, generated manifests/registries, generated translations and other recipe-owned outputs are downstream-only.

**S11A gate:** S11A0-S11A8 pass; canonical source→IR→Portable Plan and both backends carry the frozen model; completeness analysis understands the final model; authoritative adapters and memory/modifier lifecycle are stable; optimization/dependency/persistence contracts are proven; deterministic/no-op generation passes; zero-LLM semantic correctness passes; no production family was migrated before the freeze; and no compatibility shim or parallel legacy semantic authority was introduced.

### S11B — identity reference migration

Fix known/reminder first-contact leakage, classify first introduction/reconfirmation/repetition/correction/deception, make first-introduction effects idempotent, eliminate stale choice resurrection, preserve S10A label/speech semantics, and prove typed/click canonical outcome parity.

### S11C — companion commands + flow reference migrations

Normalize maintained companion commands toward compact action/execute plus ActionContract, use one portable state policy for affordances and typed input, prove zero dispatch for already-satisfied/blocked commands, and repair/migrate Needs/Greeting semantic flow definitions with bounded progress.

### S11D — full constrained-domain sweep + real-surface acceptance

Cover every family in S11_BRANCHING_DIALOGUE_AUDIT.md. Use declarative fixture sweep plus compiler/schema/completeness/Portable Plan/Reference VM tests, Reference VM ↔ PZ/Lua parity, real provider worker, response-channel click, inputbox/free text, Tk/Xvfb, cross-conversation same-day context-reference cases, and persistence-sensitive lifecycle tests.

For conversations that create promises/tasks/commitments, prove the conversational branch closes while the domain obligation remains authoritative and recallable. After the obligation changes state, later same-day reference must use current authority rather than stale remembered status.

### S11E — retained acceptance and closure

Rerun S10A label/speech, all S11 fixtures/tests, canonical nine-suite acceptance, CodeBuilder reconciliation and deterministic/no-op generation, strict S10R baselines, and git diff --check; reconcile docs; commit adopters first/Core last; record exact vector/fingerprints; do not push/publish.

**Gate:** only after S11A-S11E are accepted may the project return to USER_ACCEPTANCE. Closure additionally requires that compiler completeness catches open-ended/unhandled branches, meaningful same-day context survives branch closure through existing ConversationMemory/domain authority without retaining stale live flow state, and the richer semantic system remains within measured runtime/save-size budgets using compile-time normalization, compact definitions, dependency-driven projection/invalidation, bounded expiry scheduling, dedupe/aggregation, and on-demand diagnostics.

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
- Do not migrate production semantic families before the S11A8 foundation freeze.
- Do not preserve superseded project-owned semantic paths through compatibility shims, forwarding wrappers, fallback readers, dual registries/writes or parallel old/new execution paths; after parity/caller-zero proof, delete obsolete code.
- Do not hand-edit recipe-owned generated Lua/registries/manifests/translations. Author canonical dialogue/logic through CodeBuilder source/recipes and regenerate/reconcile downstream.
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
12. accepted phase work is locally committed without automatic push/publication;
13. S11A0-S11A8 completed in the authoritative foundation-first order and no production family was migrated before the freeze;
14. migrated dialogue/semantic content is authored through canonical CodeBuilder source/recipes with deterministic reconcile/no-op generation rather than generated-file edits;
15. superseded project-owned internal semantic implementations have caller-zero/parity proof and are deleted, with no compatibility shim/fallback/dual-path residue.

Only then return to user-owned native Project Zomboid acceptance.
