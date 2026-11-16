# S11 Semantic State / Outcome Architecture

**Status:** APPROVED DESIGN — implementation begins in S11A after regression freeze.
**Date:** 2026-11-16
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Mandatory evidence input:** `S11_BRANCHING_DIALOGUE_AUDIT.md`

## Decision

S11 must improve the existing semantic data structures rather than add parallel state/eligibility systems.

The architecture is:

```text
player text / semantic button / authored offer
                    |
                    v
              Semantic IR
             "what is meant"
                    |
                    v
      canonical projected game state
      "what is actually true now"
                    |
                    v
     existing capability / flow contract
     + Core Predicate-based statePolicy
                    |
                    v
        one StateOutcome evaluation
                    |
        +-----------+------------+
        |           |            |
        v           v            v
   presentation  admission    response
    policy        policy       family
        |           |            |
        +-----------+------------+
                    |
                    v
          authoritative gameplay
          authority when admitted
                    |
                    v
       authoritative result mapping
                    |
                    v
          canonical SemanticOutcome
                    |
                    v
      fresh post-state projection
```

There must not be separate semantic truth for:

- suggestion/button eligibility;
- typed-input admission;
- flow-entry admission;
- root-menu admission;
- gameplay-action admission;
- response selection;
- post-turn suggestion refresh.

Those surfaces may present the result differently, but they must consume the same canonical state/outcome contract.

## Non-negotiable no-split-system rules

### NS1 — no second persisted state store

Do not create a semantic-owned copy of relationship, identity, task, quest, companion-order, health, gift, event, world/base, or knowledge truth.

Domain systems remain authoritative.

The semantic layer may only build a bounded, read-only projection of those authorities for evaluation.

### NS2 — no second action/capability registry

Do not add a separate `StatefulDialogueRegistry`, `ConversationStateActionRegistry`, or similar catalog beside the existing semantic capability/action/offer registries.

Extend the existing descriptor contracts.

### NS3 — no suggestion-only eligibility authority

Existing suggestion-specific predicates such as companion `already_following` logic must move behind, or delegate to, the shared state/outcome evaluator.

Suggestion code may decide presentation layout/ranking. It may not independently decide gameplay-state truth.

### NS4 — CandidateEligibility remains parse/context eligibility

`Dialogue/CandidateEligibility.lua` may continue to validate:

- IR validity;
- required semantic context;
- required captures;
- event-follow-up scope;
- fuzzy/recovered mutation safety;
- reference resolution.

It must not become a second gameplay-state admission engine.

After candidate selection, stateful semantic acts go through the shared StateOutcome evaluator.

### NS5 — gameplay authority remains authoritative

Core state evaluation must never replace server/domain mutation authority.

The shared evaluator decides semantic admission intent such as:

```text
actionable
already_satisfied
blocked
unavailable
requires_confirmation
pending
```

If the result is actionable, the existing domain authority still performs the mutation and may reject it because of newer authoritative state.

The authority result is then normalized through the descriptor's existing `outcomeMapping`.

### NS6 — no response-side state re-derivation

Response selection consumes the canonical semantic outcome and reason.

It may use personality/localization/variation to choose wording, but it may not independently decide that the actor is already following, already a lover, already recruited, etc.

### NS7 — post-transition UI is rebuilt from fresh authority

State-changing outcomes invalidate state-sensitive semantic projection.

Do not preserve stale eligibility merely because an old closure/menu row still exists.

Root menus, response channels, generated suggestions and worker snapshots must re-evaluate against the new authoritative state.

## Existing architecture to extend

S11 must reuse these existing pieces.

### Core Predicate

`PsychopatzCore/Semantics/PsychopatzSemanticPredicate.lua`

Already provides:

- bounded declarative predicates;
- projected-field lookup;
- typed comparisons;
- all/any/not composition;
- unknown/private handling;
- diagnostic trace.

This is the condition language for `statePolicy`.

Do not invent another condition DSL.

### Core Offer

`PsychopatzCore/ConvoEngine/Offer.lua`

Already provides:

- stable offer ID;
- UI label;
- spoken utterance;
- typed semantic frame;
- constraints;
- consumers;
- priority/visibility.

Offer constraints remain useful for contextual presentation.

When an offer represents a stateful semantic capability, its state availability must resolve through the same capability StateOutcome policy used by typed input.

Do not copy state rules into `Offer.constraints` and a capability policy independently unless the constraints are presentation-only and are explicitly proven not to alter semantic admission.

### Existing capability descriptors

ProjectHoomans command/task/gift/etc descriptors already expose fields such as:

```text
capabilityID
owner
route
workflowKind
triggerFrames
requiredSlots
permissionGate
outcomeMapping
responsePools
arguments
requires
result
```

S11 extends these descriptors rather than replacing them.

### CapabilityCatalog

`PNC_SemanticCapabilityCatalog.lua` already discovers live semantic registrations and publishes descriptor fields to tools.

Extend it to expose the S11 contract automatically.

Do not maintain a manually duplicated state-action list for Semantic Lab.

## New Core contracts

Exact module/file names may follow current repository conventions, but the responsibilities below are mandatory.

### 1. StatePolicy

A bounded declarative policy attached to the existing capability/flow contract.

Conceptual descriptor:

```lua
statePolicy = {
    {
        id = "dead",
        when = {
            path = "actor.healthState",
            op = "eq",
            value = "dead",
        },
        outcome = "unavailable",
        reason = "companion_dead",
    },
    {
        id = "busy",
        when = {
            path = "actor.activity",
            op = "in",
            values = { "busy", "combat", "hostile" },
        },
        outcome = "blocked",
        reason = "companion_busy",
    },
    {
        id = "already_following",
        when = {
            path = "companion.orderKind",
            op = "eq",
            value = "follow",
        },
        outcome = "already_satisfied",
        reason = "already_following",
    },
    {
        id = "default",
        outcome = "actionable",
        reason = "actionable",
    },
}
```

The policy evaluator must:

- evaluate rules deterministically in documented order/priority;
- use Core Predicate for `when`;
- return one canonical state classification;
- fail closed on malformed policy;
- preserve bounded diagnostics;
- never mutate state.

### 2. SemanticOutcome

A normalized result consumed by suggestions, typed input, flows, responses, diagnostics and acceptance.

Conceptual shape:

```lua
{
    capabilityID = "pnc:companion.follow",
    semantic = {
        intent = "REQUEST",
        action = "FOLLOW",
    },

    state = {
        outcome = "already_satisfied",
        reason = "already_following",
        policyRuleID = "already_following",
    },

    admission = {
        mode = "no_op",
    },

    response = {
        outcome = "already_satisfied",
        family = "command.follow.already_following",
    },

    presentation = {
        action = "hide",
    },

    stateChanged = false,
}
```

An actionable pre-authority result may look like:

```lua
{
    capabilityID = "pnc:companion.follow",
    state = {
        outcome = "actionable",
        reason = "actionable",
    },
    admission = {
        mode = "dispatch",
    },
    response = {
        outcome = "queued",
    },
    expectedPostconditions = {
        {
            path = "companion.orderKind",
            op = "eq",
            value = "follow",
        },
    },
}
```

After gameplay authority returns, existing `outcomeMapping` maps domain results such as `queued`, `accepted`, `rejected`, `failed`, `already_active`, etc. into the canonical SemanticOutcome.

### 3. Small generic outcome vocabulary

Core owns only generic semantic state classes.

Initial target vocabulary:

```text
actionable
already_satisfied
blocked
unavailable
requires_confirmation
pending
active
completed
rejected
failed
deferred
unknown
```

Do not encode domain meaning such as `already_following`, `already_lover`, or `quest_rewarded` as Core outcome types.

Those remain adopter/domain `reason` values.

Avoid adding a new outcome type when an existing generic state plus a specific reason expresses the case.

### 4. Admission mode

Semantic outcome must explicitly say what the caller should do.

Initial bounded modes:

```text
dispatch
no_op
reject
confirm
defer
none
```

Examples:

```text
already_following
  outcome = already_satisfied
  admission = no_op

companion_busy
  outcome = blocked
  admission = reject

disband natural-language request
  outcome = requires_confirmation
  admission = confirm

valid FOLLOW
  outcome = actionable
  admission = dispatch
```

This prevents parser recognition from being mistaken for mutation authorization.

## Descriptor extensions

Extend existing capability/flow/offer-adjacent descriptors with the smallest required fields.

### statePolicy

Canonical pre-admission state classification.

### inputPolicy

Every stateful public semantic action declares one:

```text
typed_parity
typed_confirmation
presentation_only
```

Meaning:

- `typed_parity`: recognized free text enters the same StateOutcome contract as the button;
- `typed_confirmation`: recognized free text enters the same state contract but cannot directly mutate; it opens the same confirmation lifecycle;
- `presentation_only`: no direct typed semantic action is promised; this must be explicit, justified and acceptance-owned.

Do not create separate typed handlers with independent state logic.

### repeatPolicy

Every effectful semantic/dialogue act declares explicit repeat semantics.

Initial modes:

```text
once
cooldown
max_uses
state_retired
repeatable
idempotent
```

Examples:

```lua
repeatPolicy = {
    mode = "idempotent",
    key = "identity_introduction",
}

repeatPolicy = {
    mode = "state_retired",
    postcondition = {
        path = "relationship.kind",
        op = "eq",
        value = "lover",
    },
}

repeatPolicy = {
    mode = "cooldown",
    window = "24h",
}
```

Effectful authored choices must fail validation if repeat semantics are omitted.

Non-effectful small talk may remain repeatable when explicitly or safely classified by schema policy.

### expectedPostconditions

Optional declarative checks describing what should become true after an accepted state-changing authority result.

They are validation/refresh hints, not mutation instructions.

Examples:

```text
FOLLOW accepted
  -> companion.orderKind == follow

recruitment accepted
  -> actorAuthority.companion == true

relationship proposal accepted
  -> relationship.kind == lover
```

A postcondition failure must surface as diagnostic/acceptance evidence; do not mutate local shadow state to make it pass.

### presentationPolicy

Only presentation behavior derived from the canonical state outcome.

Typical mapping:

```text
actionable            -> show
already_satisfied     -> hide or alternate
blocked               -> hide/disable
unavailable           -> hide/disable
requires_confirmation -> alternate/confirmation
pending               -> alternate/pending
```

Domain descriptors may override presentation choice where needed, but they may not override the underlying state classification.

## Canonical evaluation sequence

Every stateful semantic route uses this lifecycle.

### Step 1 — produce Semantic IR

Source can be:

- parser/free text;
- response-channel click;
- root/menu click;
- generated affordance;
- compatible provider.

### Step 2 — resolve existing capability/flow owner

Use current registries/capability discovery.

No separate S11 registry.

### Step 3 — build bounded state projection

Read current authoritative domain state into the established public context projection.

Do not persist it as semantic truth.

### Step 4 — evaluate StatePolicy

Return the canonical pre-admission SemanticOutcome.

### Step 5 — apply input policy

For typed input:

- parity -> continue according to canonical admission;
- confirmation -> enter shared confirmation lifecycle;
- presentation-only -> return explicit contextual response/clarification policy without inventing mutation.

### Step 6 — admit or short-circuit

```text
dispatch -> call existing gameplay authority
no_op    -> do not dispatch; select state-specific response
reject   -> do not dispatch; select blocked/unavailable response
confirm  -> create bounded confirmation obligation
defer    -> create bounded defer/pending state
```

### Step 7 — normalize authoritative result

Use the descriptor's existing `outcomeMapping`.

Do not make the UI infer success from transport acknowledgement alone.

### Step 8 — select response

Use canonical outcome + reason + personality/localization.

Response wording does not determine state.

### Step 9 — invalidate/rebuild state-sensitive projection

When `stateChanged == true` or an expected postcondition is associated with the result:

- rebuild semantic state projection;
- re-evaluate root/menu candidates;
- re-evaluate response-channel candidates;
- re-evaluate generated affordances;
- update snapshot diagnostics.

No stale eligibility preservation.

## Identity reference contract

Identity should use the same architecture, not a special side system.

Conceptual projected facts:

```text
identity.npcKnownToPlayer
identity.playerKnownToNPC
identity.playerClaimState
dialogue.identityExchangeKind
```

These are projections from existing knowledge/relationship/interaction authority.

Example policy:

```text
first-contact truthful claim
  -> actionable / dispatch identity authority
  -> repeatPolicy idempotent(identity_introduction)

known canonical repeat
  -> already_satisfied / no_op
  -> identity.reconfirmation response

known-person false claim
  -> actionable or rejected according to adopter deception policy
  -> never overwrite canonical identity

known NPC name question
  -> reminder response
  -> no first-contact PLAYER_NAME obligation unless explicit reconfirmation state is opened
```

Do not add a separate identity-state engine.

## Companion command reference contract

FOLLOW is the second required proof that the model is generic.

Current duplicated suggestion-only checks for:

- dead/incapacitated;
- busy/combat/hostile;
- already following;
- already staying;
- camp availability;

must be moved behind or delegated to capability StatePolicy.

Then:

```text
button FOLLOW + already following
    -> StateOutcome already_satisfied
    -> hidden/alternate

typed "Follow me" + already following
    -> same StateOutcome
    -> no dispatch
    -> "I'm already following you."

typed "Follow me" + busy
    -> StateOutcome blocked / companion_busy
    -> no dispatch
    -> contextual busy response
```

This is the acceptance proof that S11 did not create another UI-only patch.

## Flow schema improvements

Manual flows remain part of the same system.

Flow nodes may use the same StatePolicy/Predicate contract for:

- flow-entry admission;
- branch admission;
- continuation state.

### No unbounded self-loop

A flow transition returning to the same node must declare bounded semantic progress.

Accepted progress forms include:

- authoritative state change;
- required-slot progress;
- bounded retry count;
- timeout/expiry;
- explicit defer;
- explicit cancel/refuse route;
- terminal completion reached after the authority result.

The validator must reject a self-loop like:

```text
proposal_pending
  ACCEPT -> proposal_pending
```

when nothing observable can progress.

### Needs repair direction

The current needs proposal must either:

1. dispatch a real authority-backed promise/task/commitment and consume its result; or
2. truthfully close as a conversational acknowledgement with no implied gameplay commitment.

Do not keep an infinite semantic proposal loop.

### Greeting repair direction

Greeting flow entry and continuation must evaluate the same actor-state policy used by greeting/parley presentation.

A hostile/busy/combat/dead/incapacitated actor may not receive a contradictory friendly follow-up merely because the typed parser matched `hello` or `thanks`.

## Authored PSDL effect integration

Do not create a separate repeat/cooldown engine for authored PSDL choices.

Carry `repeatPolicy` through the existing dialogue-block/choice compilation into the existing conversation history/repeat machinery.

Effectful choices without explicit repeat semantics fail authoring validation.

State-changing effects such as ceasefire or territory claim should usually use `state_retired` with a postcondition rather than an arbitrary cooldown.

## State projection ownership

Core may define the portable shape/evaluator.

ProjectHoomans projects domain state into it.

Examples of adopter-owned projection fields:

```text
actorAuthority.*
npcState.healthState
npcState.activeBehavior
npcState.orderKind
relationship.*
identity.*
quest.*
task.*
gift.*
event.*
world/base/destination facts
```

Do not force every domain into one gigantic universal state object.

Projection is capability-driven and bounded: only fields needed by registered policies need to be exposed.

## Diagnostics and Semantic Lab

Because the contract becomes declarative, Semantic Lab should expose the decision trace.

Example:

```text
Input
  "Follow me"

IR
  REQUEST / FOLLOW

Capability
  pnc:companion.follow

Projected state
  companion.orderKind = follow
  actor.activity = idle

StatePolicy
  rule = already_following

SemanticOutcome
  outcome = already_satisfied
  reason = already_following
  admission = no_op

Response
  command.follow.already_following

Post projection
  FOLLOW hidden
  STAY visible
  GO HOME visible
```

Diagnostics must also detect cross-surface contradiction:

```text
same capability + same state projection
button outcome != typed outcome
    -> acceptance failure
```

## Validation rules

Add schema/acceptance validation for at least:

1. stateful public capability missing `inputPolicy`;
2. effectful action/choice missing `repeatPolicy`;
3. malformed or unreachable `statePolicy` default;
4. duplicate policy rule IDs;
5. unknown generic outcome/admission values;
6. self-looping flow with no bounded progress declaration;
7. state-changing outcome with stale post-projection in real worker acceptance;
8. button/typed canonical outcome mismatch for the same capability/state;
9. new stateful capability absent from S11 acceptance ownership;
10. ProjectHoomans-specific domain outcome accidentally added to Core's generic outcome vocabulary.

## Migration strategy

Do not perform a flag-day rewrite.

### M1 — substrate without behavior change

Implement Core StatePolicy + SemanticOutcome normalization and descriptor validation.

Expose them through the current capability catalog.

Keep existing behavior adapters temporarily delegating into the new evaluator where possible.

### M2 — identity reference migration

Migrate identity to prove:

- directional identity state projection;
- first-contact vs reconfirmation;
- effect idempotence;
- response-channel refresh.

### M3 — companion-command migration

Move existing suggestion state rules into/delegate them to capability StatePolicy.

Make typed input consume the same result.

Delete duplicate state logic only after parity tests prove replacement.

### M4 — flow migration

Migrate needs and greeting.

Add bounded self-loop/progress validation.

### M5 — social/root transition migration

Recruitment, relationship proposal, disband confirmation, territory, ceasefire and settlement transitions.

### M6 — authored repeat semantics

Wellbeing/trust/affinity and other effectful PSDL choices.

### M7 — tasks/quests/reference-good families

Apply parity/coverage to tasks and quests while preserving their stronger existing authority.

Protect gift/gossip/event/departure reference-good behavior.

## Deletion rule

Do not delete old eligibility/state code merely because a new evaluator exists.

Deletion requires:

- all callers migrated;
- click + typed + worker tests green;
- no alternate authority remains;
- current reference-good behavior retained;
- caller-zero proof for the old helper.

## Completion architecture invariant

S11 is architecturally correct only when this statement is true:

> Semantic IR describes meaning. Existing authoritative game systems describe reality. The existing semantic capability/flow contract, extended with one Core Predicate-based StatePolicy, combines those into one canonical SemanticOutcome. Suggestions, typed input, flow transitions, responses, effects and post-turn projections consume that outcome; no parallel semantic state or eligibility engine exists.

