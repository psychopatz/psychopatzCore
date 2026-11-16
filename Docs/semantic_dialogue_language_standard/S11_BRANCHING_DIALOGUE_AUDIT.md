# S11 Branching Dialogue and Stateful Outcome Audit

**Status:** ACTIVE AUDIT INPUT FOR S11  
**Audit date:** 2026-11-16  
**Normative goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`  
**Approved shared architecture:** `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`  
**Repositories inspected:** PsychopatzCore + ProjectHoomans current `main`; DynamicTrading retained as compatibility participant.  
**Purpose:** enumerate every maintained conversation family with meaningful branching/state constraints and classify whether it is a confirmed S11 defect, a high-risk parity surface, or a reference-good contract to preserve.

## Audit method

The audit traced current production source and the manifest-selected ProjectHoomans worker across these ownership layers:

```text
authoring / PSDL offers
    ->
native Conversation composer/root choices
    ->
semantic suggestion providers
    ->
semantic parser/policy
    ->
flow kernel / pending follow-up state
    ->
action/task/quest/gift authority
    ->
relationship/effect authority
    ->
response realization
    ->
snapshot / menu / response-channel refresh
```

The audit intentionally distinguishes:

- **RUNTIME_VERIFIED_DEFECT** — reproduced on the current real PNC worker;
- **CODE_VERIFIED_DEFECT/RISK** — current source contract proves the mismatch or missing guard;
- **REFERENCE_GOOD** — source plus current focused tests demonstrate the desired bounded behavior;
- **HIGH_RISK_NEEDS_ACCEPTANCE** — underlying authority is promising, but equivalent suggestion/free-text/post-state coverage is incomplete.

The audit does not assume every button requires a free-text synonym. S11 must classify each stateful public branch as one of:

```text
typed_parity_required
typed_routes_to_confirmation
presentation_only_by_design
```

A branch may be presentation-only only when that is explicit, safe, and acceptance-owned. Natural player language that is already semantically supported must not silently bypass state authority or fall into generic clarification when an equivalent public semantic action exists.

## Branching/stateful surface inventory

### A. Manual semantic flows

Current maintained manual flow families:

- `identity`;
- `wellbeing`;
- `needs`;
- `greeting`;
- `weather_context`.

### B. Generated semantic workflows

Current generated action catalog includes:

**Simple command:**

- CAMP;
- COMBAT_AVOID;
- COMBAT_ENGAGE;
- COMBAT_HOLD;
- FOLLOW;
- GO;
- STAY;
- STOP;
- HELP / Clinic Supplies quest offer;
- QUEST_ACCEPT;
- QUEST_STATUS;
- QUEST_TURN_IN.

**Parameterized task:**

- CONSUME;
- DRINK;
- EAT;
- FETCH;
- GIVE;
- REFILL;
- WAIT_AT.

**Multi-stage gift:**

- GIFT.

### C. Native/root conversation branches

Maintained stateful root/composer actions include:

- ask-name;
- recruitment;
- disband/departure warning -> confirm/cancel;
- settlement admission;
- ambient visit;
- hostile ceasefire/parley;
- set-territory;
- relationship proposal;
- category/topic navigation;
- goodbye/close.

### D. Authored PSDL offer branches

Maintained PSDL branches with meaningful conditional/effect semantics include:

- needs support -> supplies / medical / gift -> gift-return;
- wellbeing -> condition / offer-help;
- small-talk -> weather / quiet-day;
- ask-about -> background / skills;
- personal trust;
- relationship affinity;
- set territory;
- work orders;
- hostile parley/ceasefire.

### E. Dynamic/social/contextual branches

Maintained contextual branching includes:

- interaction-director argument/reconciliation/repair behaviors;
- generated pragmatic affordances such as apologize, challenge, claim-joke, double-down;
- event response windows/follow-ups;
- grounded gossip;
- knowledge/fact continuation;
- gift consent;
- task and quest result lifecycles.

# Confirmed S11 defects

## D1 — identity first-contact/reconfirmation contradiction

**Evidence:** RUNTIME_VERIFIED_DEFECT.

Already captured in the normative S11 goal:

- known NPC reply chooses `question.identity.known`;
- same turn creates first-contact `PLAYER_NAME`;
- first-contact truthful/refuse/lie choices appear;
- repeated truthful claims reapply first-introduction relationship effects;
- later snapshot can resurrect resolved first-contact choices.

**S11 ownership:** S11A/S11B reference implementation.

---

## D2 — typed companion commands bypass state eligibility

**Evidence:** RUNTIME_VERIFIED_DEFECT + CODE_VERIFIED_CONTRACT_SPLIT.

The suggestion layer already knows state-specific eligibility through `Suggestions_Capabilities_Companion.lua`, including:

- `already_following`;
- `already_staying`;
- no-base / returning / camp-state restrictions;
- hostile/combat/busy/dead/incapacitated restrictions.

The typed action path does not consume that evaluation.

Fresh worker reproductions:

| Current authoritative/projected state | Typed input | Current result |
| --- | --- | --- |
| already following | `Follow me` | dispatches FOLLOW again; “Okay, I'll follow you.” |
| already guarding/staying | `Stay here` | dispatches STAY again |
| already returning home | `Go home` | dispatches RETURN_HOME again |
| NPC busy | `Follow me` | dispatches FOLLOW anyway |
| camp already active | `let's camp here` | dispatches CAMP again |

The UI/suggestion projection can hide the already-satisfied command while typed input still executes it.

An existing test, `test_generated_simple_command_uses_bounded_previous_action_memory`, currently encodes the wrong repeat contract by requiring a second `Follow me` to dispatch once again and remain `queued`.

**S11 requirements:**

- state evaluation must be shared before dispatch;
- repeated already-satisfied commands become no-op/reconfirmation outcomes;
- current action must not be re-enqueued;
- NPC reply must state the actual condition;
- accepted inverse/next action should become the visible affordance after refresh;
- rewrite tests that currently bless duplicate command dispatch.

**Priority:** P0 after identity reference contract.

---

## D3 — needs proposal branch has no completion path

**Evidence:** RUNTIME_VERIFIED_DEFECT + CODE_VERIFIED_DEFECT.

`Flow_Needs.lua` currently defines:

```text
proposal_pending:
    accepts ACCEPT / AGREE
    onMatch = proposal_pending
```

with an explicit comment that a future authority-backed confirmation path is not yet implemented.

Fresh worker sequence:

```text
Do you need anything?
  -> await_player_quantity

How many?
  -> quantity_answer / PROPOSAL

I'll get some
  -> proposal_pending

Okay
  -> proposal_pending

Okay
  -> proposal_pending

Okay
  -> proposal_pending
```

Each acceptance reopens the pending proposal with a new turn. The conversation never reaches an authoritative commitment, bounded no-op, explicit deferred state, or terminal outcome.

This is exactly the “understood input remains open-ended” failure S11 is intended to prevent.

**S11 requirements:**

- either connect the proposal to a real gameplay commitment/task authority, or close it truthfully as a non-binding conversational acknowledgement;
- no nonterminal self-loop may survive without a documented authoritative completion/defer/cancel contract;
- repeated ACCEPT must not indefinitely recreate the same pending obligation;
- provide button and typed-input outcome parity.

**Priority:** P0.

---

## D4 — greeting flow state constraints apply to buttons but not typed continuation

**Evidence:** RUNTIME_VERIFIED_DEFECT.

`Flow_Greeting.lua` places hostile/combat/busy/dead/incapacitated constraints on the `greeting.thanks` branch offer, but the flow trigger and typed THANK acceptance do not consume those constraints.

Fresh current-worker behavior:

```text
busy NPC:
  player: hello
  -> greeting pending
  -> Thank button hidden
  player types: thanks
  -> flow completes anyway

hostile NPC:
  root UI exposes ceasefire/parley
  player types: hello
  -> "State your business. Keep your distance."
  -> semantic greeting flow also appends "How have you been?"
  -> greeting pending remains
```

The hostile example is a clear dual-authority contradiction: native greeting ownership says parley, while typed semantic greeting opens a friendly reciprocal follow-up.

A dead-state harness scenario similarly starts the greeting flow; native reachability for a dead actor should be separately fail-closed, but the semantic flow must not assume impossible state is valid.

**S11 requirements:**

- flow trigger eligibility and branch-offer eligibility must use one state evaluation;
- hostile/parley state must not spawn friendly greeting follow-up obligations;
- busy/combat/dead/incapacitated behavior must be explicitly classified;
- typed continuation may differ from button visibility only when the state policy explicitly allows it.

**Priority:** P0/P1.

---

## D5 — recruitment state does not reproject after successful transition

**Evidence:** RUNTIME_VERIFIED_DEFECT.

For a neutral recruitable NPC with sufficient relationship:

```text
typed: "Would you like to join us?"
  -> accepted
  -> scenario.npc.recruited = true
```

But a following snapshot still exposes:

```text
conversation.root:menu:recruit
```

and repeating the same typed recruitment sends another recruitment request with:

```text
accepted = true
status = conversation_recruitment_pending
```

This contradicts the separately correct existing behavior where a scenario that starts as a companion receives a contextual `recruitment.reject.member.*` response.

The transition path fails to update/reproject the same ownership state that startup projection uses.

**S11 requirements:**

- successful recruitment must invalidate/replace the recruit affordance immediately;
- repeated typed recruitment must route to the already-member outcome without a new recruitment request;
- root menu, worker snapshot, and authoritative result must agree after the transition;
- no reward/effect/request duplication.

**Priority:** P0/P1.

---

## D6 — relationship proposal authority is state-aware, projection/input parity is not

**Evidence:** RUNTIME_VERIFIED_DEFECT + REFERENCE_GOOD_AUTHORITY.

The proposal authority already has strong reasons:

- `orientation_incompatible`;
- `family_excluded`;
- `approval_threshold`;
- `proposal_cooldown`;
- `already_lover`;
- accepted/rejected.

Fresh worker behavior after an accepted proposal:

```text
first proposal:
  accepted = true
  reason = accepted

next snapshot:
  social.relationship_proposal is still visible

repeat proposal:
  accepted = false
  reason = already_lover
```

So authority is correct but suggestion projection is stale.

Natural free text such as:

```text
Would you like to be together?
```

currently parses to `ASK_CLARIFICATION` rather than the existing proposal state machine.

**S11 requirements:**

- refresh proposal eligibility after accepted/rejected/cooldown state changes;
- classify free-text parity for relationship proposal;
- if free-text proposal is supported, route it through the same authority and cooldown;
- never duplicate relationship-state mutation.

**Priority:** P1.

---

## D7 — stateful root actions have inconsistent inputbox coverage

**Evidence:** RUNTIME_VERIFIED_INPUT_GAP.

Natural equivalents currently fall to generic clarification for several public stateful branches:

```text
"Would you like to be together?"     -> no relationship-proposal semantic route
"I want you to leave the group"      -> no departure semantic route
"Leave the group"                    -> no departure semantic route
"Ceasefire"                          -> no parley semantic route
"Let's call a ceasefire"             -> no parley semantic route
"Let's make this our base"           -> no territory semantic route
"Let's claim this territory"         -> no territory semantic route
```

This is not a requirement to make every UI control callable by arbitrary prose. It is a requirement to explicitly classify stateful public actions with natural conversational meaning.

**S11 requirements:**

For every stateful root action, choose and test exactly one policy:

- `typed_parity_required`;
- `typed_routes_to_confirmation` — required for destructive actions such as departure;
- `presentation_only_by_design` with an explicit rationale and contextual typed fallback.

Generic “I'm not sure what you mean” is not acceptable for a natural phrase when the game exposes an equivalent conversational semantic act and S11 declares typed parity.

**Priority:** P1.

---

## D8 — effectful authored PSDL choices have no explicit repeat policy

**Evidence:** CODE_VERIFIED_RISK.

Current authored choices applying `pnc:relationship` effects include:

- wellbeing condition: `approval +1, familiarity +1`;
- wellbeing offer-help: `approval +2, respect +1`;
- personal trust: `approval +2, familiarity +2`;
- relationship affinity: `approval +2, familiarity +2`.

The affected source plans/choices currently declare no `repeat` policy. Generated conversation blocks also do not synthesize one.

`PNC_ConversationSelector.CheckRepeat` treats a missing policy as unrestricted.

`Relationships.ApplyConversationEffect` derives its default event identity using block/choice/outcome plus the current time, so later repeated uses can become distinct relationship events. Request-ID deduplication does not provide a semantic cooldown/once policy.

State-changing non-relationship effects also need explicit transition review:

- `pnc:open_territory_claim`;
- `pnc:ceasefire`.

Those may naturally become unavailable after their state transition, but the retirement must be proven rather than assumed.

**S11 requirements:**

Every effectful authored conversational choice must explicitly declare one of:

- one-time;
- cooldown/repeat policy;
- state-transition retirement;
- intentionally repeatable effect with bounded rationale.

No relationship reward may be farmable merely because the category can be reopened.

**Priority:** P1.

---

## D9 — overlapping authorities exist for identity/greeting/needs/wellbeing

**Evidence:** CODE_VERIFIED_ARCHITECTURAL_RISK + runtime defects above.

The same topic can be represented simultaneously by:

- native PSDL Conversation blocks;
- semantic flows;
- static/generated suggestions;
- interaction-director behaviors.

Examples:

**Greeting**
- PSDL audience/time/relationship-selected greeting and hostile parley;
- semantic `Flow_Greeting`.

**Needs**
- PSDL `needs_*_support` branch graph including gift continuation;
- semantic `Flow_Needs` quantity/proposal graph.

**Wellbeing**
- PSDL wellbeing branch choices with relationship effects;
- semantic `Flow_Wellbeing` reciprocal follow-up.

**Identity**
- native ask-name/root presentation;
- semantic identity flow;
- server identity claim authority.

Multiple presentation paths are acceptable. Multiple independent state authorities are not.

**S11 requirements:**

- name one state/outcome owner per semantic transition;
- presentation systems may adapt that result but may not independently infer state transitions;
- tests must cover cross-surface convergence for overlapping topics.

**Priority:** architectural S11A requirement.

# High-risk branches requiring explicit S11 acceptance

## H1 — parameterized tasks

**Status:** HIGH_RISK_NEEDS_ACCEPTANCE; server authority is comparatively strong.

The server action-plan service already rejects a second nonterminal plan with:

```text
npc_action_plan_active
```

and task response presentation has the contextual line:

```text
"I'm still handling the last thing you asked."
```

This is the desired typed-input outcome pattern.

However generated suggestions/affordances and typed task requests do not yet have one audited state matrix for:

- active plan;
- stale-plan cleanup failure;
- completed task;
- missing item;
- unsuitable consume target;
- missing water/container;
- unresolved WAIT_AT destination;
- CAMP already active / movement/path failure.

**S11 requirement:** prove button projection, typed input, authoritative plan admission, response wording, and post-result refresh all agree. Preserve the existing specific reason handling.

---

## H2 — quest lifecycle

**Status:** HIGH_RISK_NEEDS_ACCEPTANCE; production authority is state-aware.

`QuestService` already distinguishes:

- available;
- already allocated;
- active;
- ready-to-turn-in;
- completed;
- rewarded;
- already active;
- already rewarded;
- not ready;
- locked/ineligible;
- stale revision.

`Input_QuestResults.lua` has explicit state-specific response text.

This is good authority design.

Risk remains because generated quest actions use the generic `simple_command` template and the singleplayer worker harness default does not persist quest lifecycle between requests; an existing test currently expects two repeated `Can you help me?` turns to both return `available`.

**S11 requirement:** add production-state acceptance for offer -> accept -> active -> ready -> rewarded -> repeat and verify suggestion/free-text behavior follows the real QuestService state, not the harness default shortcut.

---

## H3 — relationship proposal/recruitment transition refresh

Covered by D5/D6, but must be generalized to all relationship-state-changing branches:

- recruit;
- proposal accept/reject/cooldown;
- lover state;
- departure/disband;
- faction/ownership transition.

Every state mutation must invalidate stale presentation state before the next snapshot/menu.

---

## H4 — settlement admission / ambient visit

**Status:** REFERENCE_GOOD_AUTHORITY + refresh acceptance needed.

Existing authority tests prove request-ID replay does not duplicate settlement admission or ambient visit mutations.

Existing conversation tests prove an expired settlement visit disappears when a new definition is built.

S11 should retain these as reference contracts and add post-success/current-view retirement checks where state changes occur.

---

## H5 — set territory / hostile parley

**Status:** HIGH_RISK_STATE_TRANSITION + input parity gap.

The authored branches correctly carry:

- base-not-established gating for territory;
- hostile-player parley gating;
- close behavior after effect.

Existing tests prove a rebuilt definition hides set-territory after a base exists and fail closed when hostility data is incomplete.

S11 should prove the **same active conversation** refreshes after the effect and classify natural typed equivalents for territory/parley rather than relying only on click presentation.

---

## H6 — pragmatic social repair/escalation

**Status:** REFERENCE_GOOD_CORE + effect/idempotence audit required.

Fresh audit sequence:

```text
insult
  -> argument_escalation

sorry
  -> reconciliation

sorry again
  -> bounded reconciliation response

sorry after beat closes
  -> contextual "What are you referring to?"
```

Existing tests also prove generated-click and typed-apology convergence.

Important intentional asymmetry:

`AffordanceContinuationPolicy` explicitly controls generated button frontier and does **not** reject typed NLU.

S11 must preserve that design where appropriate. The invariant is not “hidden button means typed input forbidden”; it is “typed input must receive the correct state outcome and must not duplicate gameplay effects.”

Audit all state-mutating social behaviors for repeat/cooldown/idempotence, but do not force button and typed availability to be identical.

# Reference-good branch contracts to preserve

## G1 — wellbeing semantic follow-up

**Status:** REFERENCE_GOOD.

Current tests prove generated and typed wellbeing answers converge and clear the pending follow-up.

This is a model for S11 click-vs-input parity.

---

## G2 — event response windows

**Status:** REFERENCE_GOOD.

Current tests prove:

- event facts generate bounded follow-up offers;
- clicked and typed follow-up converge;
- unavailable facts return truthful unknown;
- response windows expire.

This is a model for bounded state-aware follow-up ownership.

---

## G3 — grounded gossip

**Status:** REFERENCE_GOOD.

Current behavior:

- safe grounded gossip can appear as a button;
- unavailable gossip hides the button;
- typed `any gossip?` still returns `gossip.unknown` rather than inventing content;
- target/stale target grounding is checked;
- EN/TL localization is covered.

This directly demonstrates the desired S11 rule: hidden/unsupported suggestion does not make typed input an open-ended dead end.

---

## G4 — gift lifecycle / consent

**Status:** REFERENCE_GOOD with stale-state regression coverage still required.

Existing code/tests cover:

- selection required;
- pending transfer;
- completed/rejected/failed;
- consent granted/declined;
- ambiguous multi-recipient consent;
- stale group/expired consent;
- unavailable recipient;
- request replay/idempotence.

Preserve this as a multi-stage reference implementation.

S11 should still assert that completed/expired consent offers do not remain visible in later projections.

---

## G5 — departure warning/confirmation click route

**Status:** REFERENCE_GOOD for authoritative click lifecycle.

Current production tests prove:

```text
disband
  -> warning
  -> disband_confirm / disband_cancel
  -> confirmed authority mutation
  -> conversation closes
```

rejection leaves state unchanged, and request replay is bounded.

The missing piece is natural free-text policy: a phrase such as `Leave the group` currently falls to generic clarification. S11 must classify that path as confirmation-routed or intentionally presentation-only.

---

## G6 — settlement visit expiry and territory gating on rebuilt context

**Status:** REFERENCE_GOOD.

Existing tests prove:

- active settlement visit exposes admission;
- expired visit restores default recruitment;
- established base hides territory;
- incomplete hostility data fails closed for parley.

S11 should reuse these as examples for post-mutation projection tests.

# Manual flow audit summary

| Flow | Current classification | S11 action |
| --- | --- | --- |
| identity | RUNTIME_VERIFIED_DEFECT | S11A/S11B reference repair |
| wellbeing | REFERENCE_GOOD semantic follow-up | retain; cross-check overlapping PSDL effects |
| needs | RUNTIME_VERIFIED_DEFECT at proposal_pending | give proposal a terminal/authority-backed outcome |
| greeting | RUNTIME_VERIFIED_DEFECT for state-gate parity | gate trigger/typed continuation from same state decision |
| weather_context | REFERENCE_GOOD response-only gate | retain |

# Generated workflow audit summary

| Workflow/family | Current classification | S11 action |
| --- | --- | --- |
| simple companion commands | RUNTIME_VERIFIED_DEFECT | state-aware no-op/reject/alternate before dispatch |
| parameterized tasks | HIGH_RISK, authority comparatively good | full state parity matrix |
| quest operations | HIGH_RISK, production authority good | production lifecycle + projection parity |
| gift | REFERENCE_GOOD multi-stage | preserve + stale-projection checks |

# Native/root branching audit summary

| Branch | Current classification | S11 action |
| --- | --- | --- |
| ask name | RUNTIME_VERIFIED_DEFECT through identity lifecycle | S11B |
| recruit | RUNTIME_VERIFIED stale transition | retire/alternate after success; typed repeat already-member |
| disband | good click warning/confirm, typed gap | typed-to-confirmation or explicit presentation-only policy |
| relationship proposal | strong authority, stale suggestion + typed gap | refresh + typed parity |
| settlement admission | good replay/expiry authority | post-success refresh |
| ambient visit | good replay authority | post-start refresh |
| ceasefire | state gate exists, typed gap | state refresh + typed policy |
| set territory | state gate exists, typed gap | state refresh + typed policy |
| goodbye | low-risk terminal | retain |
| category navigation | low-risk unless choices mutate state | effectful choices require repeat policy |

# Authored effect audit

Every effectful dialogue choice must enter the S11 state/outcome inventory.

Current effect-bearing PSDL branch families:

| Family | Effect | Current repeat declaration |
| --- | --- | --- |
| wellbeing neutral/member/special condition | relationship approval/familiarity | none |
| wellbeing neutral/member/special offer-help | relationship approval/respect | none |
| personal special trust | relationship approval/familiarity | none |
| relationship special affinity | relationship approval/familiarity | none |
| set territory | open territory claim | none; relies on state gate |
| hostile parley | ceasefire | none; relies on state transition/close |

S11 must not assume missing repeat metadata is harmless.

# New S11 acceptance rules derived from this audit

## Rule 1 — no button-only state predicate for an equivalent semantic action

If a suggestion is hidden/alternated because of current gameplay state, equivalent recognized free text must consume the same state reason before effect dispatch.

Intentional generated-affordance cooldown asymmetry is allowed only when typed input remains state-correct and effect-safe.

## Rule 2 — no nonterminal self-loop without bounded semantic progress

Any flow node with `onMatch` returning to itself must prove at least one of:

- authoritative state progress;
- bounded counter/timeout;
- explicit defer state;
- explicit cancel/refuse route;
- changing required slots that can actually be satisfied.

A self-loop that simply reopens the same obligation on every accepted answer fails S11.

## Rule 3 — every effectful conversation choice declares repeat semantics

Effectful choices must explicitly state one of:

- one-shot;
- cooldown;
- max uses;
- state-retired after effect;
- intentionally repeatable.

The acceptance suite must prove the policy.

## Rule 4 — state mutation invalidates presentation projections

After recruitment, proposal acceptance, identity completion, task admission/completion, quest progression, settlement admission, ceasefire, territory claim, gift completion, or similar state change:

- stale root choices may not persist;
- stale response-channel rows may not persist;
- a later snapshot may not resurrect the prior state;
- a restarted/reconfigured worker must project the same authoritative state.

## Rule 5 — destructive branches use typed confirmation, never direct free-text mutation

Where natural free text maps to a destructive branch such as departure/disband:

```text
typed request
    -> same warning/confirmation state
    -> explicit confirm/cancel
    -> authoritative effect
```

Do not bypass the confirmation because the parser recognized the action.

## Rule 6 — reference-good flows are regression baselines

S11 must retain the existing good behavior for:

- wellbeing answer convergence;
- event follow-up expiry;
- grounded gossip unknown handling;
- gift consent ambiguity/expiry;
- departure warning/confirmation;
- settlement visit expiry;
- pragmatic apology/reconciliation closure.

The repair is not accepted if fixing broken branches regresses these contracts.

# S11 implementation priority derived from audit

### P0 — freeze before implementation

Add failing tests for:

1. identity known/reconfirmation contradiction;
2. repeated identity relationship reward;
3. identity stale-choice resurrection;
4. FOLLOW/STAY/GO HOME/CAMP repeated-state typed bypass;
5. busy/blocked typed command bypass;
6. needs proposal infinite acceptance loop;
7. hostile greeting friendly follow-up contradiction;
8. recruitment post-success stale affordance + duplicate request;
9. relationship proposal post-accept stale affordance.

### P1 — effect/input parity

Add tests for:

10. disband natural-language -> confirmation policy;
11. relationship proposal natural-language parity;
12. ceasefire natural-language parity or explicit presentation-only policy;
13. set-territory natural-language parity or explicit presentation-only policy;
14. effectful wellbeing/trust/affinity repeat semantics;
15. active task duplicate/no-op response;
16. quest offer/accept/status/turn-in lifecycle after real state transitions.

### P2 — retained/reference closure

Keep explicit regression coverage for:

17. gift consent and stale expiry;
18. event response window expiry;
19. grounded gossip unavailable/unknown;
20. wellbeing click/typed convergence;
21. departure confirmed close;
22. settlement admission/ambient visit replay and state retirement;
23. pragmatic social repair bounded closure.

# Completion impact

This audit expands S11C/S11D.

S11 is not complete when identity alone is fixed.

The parent completion gate now requires the state/outcome acceptance inventory to cover **every family listed in this audit**, with each row classified as repaired, explicitly presentation-only, or reference-good and regression-protected.

All repaired/high-risk families must consume the single existing-registry `StatePolicy -> SemanticOutcome` architecture defined in `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`. Creating family-specific eligibility/state engines is not an acceptable audit closure even if behavior tests pass.

A future branch/stateful semantic feature must fail acceptance if it is introduced without:

- authoritative state source;
- UI projection policy;
- free-text policy;
- effect/admission policy;
- contextual response owner;
- post-transition refresh expectation;
- repeat/idempotence policy where effects exist;
- automated acceptance owner.
