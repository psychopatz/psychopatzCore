# S11 Post-R5 Final Closure Repair

**Status:** HISTORICAL R6 REPAIR PLAN — substantially landed; final two acceptance proofs and continuity cleanup moved to R7
**Audit date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Mandatory scope input:** `S11_BRANCHING_DIALOGUE_AUDIT.md`
**Previous repair:** `S11_POST_R4_CLOSURE_AUDIT_REPAIR.md`

**Current repair authority:** `S11_POST_R6_CLOSURE_AUDIT_REPAIR.md`. Do not restart R6; retain accepted R6 work and execute R7.

## Purpose

R5 materially improved S11 and its acceptance system. Closed-set audit inventory, exact test/source lookup, event expiry ownership, disband confirmation safety, canonical reply projection, recipe reconciliation and broad test health are real and must be retained.

A post-R5 source audit found six remaining closure defects:

1. acceptance claim ownership is still proven by keyword presence rather than explicit stable claim IDs owned by the exact test/case;
2. the production quest conversation test stops at ACTIVE/premature turn-in instead of proving READY_TO_TURN_IN → REWARDED → repeat idempotence;
3. parameterized-task acceptance proves duplicate suppression but not suggestion/response-channel parity across active and terminal state;
4. settlement/ambient tests prove service/authority/replay/expiry behavior but not current-conversation surface refresh after success;
5. generic `Input_Actions_Dispatch.lua` still names `RECRUIT` and `RELATIONSHIP_PROPOSAL` solely to run canonical policy before their domain dispatchers;
6. final S11 continuity docs disagree and the recorded ProjectHoomans residual fingerprint is stale.

This is a narrow final repair. Do not rebuild S11A, R1/R2, or the accepted R5 work.

## Retained evidence

Retain without reimplementation unless a targeted new test disproves it:

- S11A0-A8 foundation and zero-LLM semantic authority;
- canonical Identity, Needs, Greeting and maintained companion-command migrations;
- closed-set 25-row branching audit inventory;
- exact acceptance source/test ID resolution;
- event response-window expiry acceptance;
- disband presentation-only confirmation/cancel/replay acceptance;
- recruitment/proposal canonical reply projection via `S11PolicyEvaluator.ProjectReply`;
- hard-coded recruitment reason→template/text mappings removed;
- fresh Core semantic-harness: 310 PASS / 2 skips;
- fresh focused R5B provider tests: 24/24 PASS;
- CodeBuilder reconcile clean at 410 desired outputs;
- ConvoEngine integrity/determinism clean at 588 family files / 407 deterministic files / 0 violations.

Passing these gates does not waive the remaining R6 requirements.

## R6 sequence

~~~text
R6A  explicit acceptance-claim ownership
  ↓
R6B  residual lifecycle/presentation acceptance
     quest + task + settlement/ambient
  ↓
R6C  single generic canonical policy-admission seam
  ↓
R6D  full reproducible acceptance + one exact final continuity checkpoint
~~~

The full R6 sequence is mandatory before S11 can return to user-owned native Project Zomboid acceptance.

# R6A — explicit acceptance-claim ownership

## Current defect

The R5 analyzer correctly validates:

- closed-set audit IDs;
- owner source existence;
- exact Python method / declarative case / Lua test ID existence;
- required canonical family policy.

However, semantic ownership is still inferred from `claimKeywords` appearing in test source. For Lua owners the current extractor can effectively search the whole file.

Therefore a test can appear to own an audit claim merely because words such as `settlement` or `ambient` occur in that source.

That is not a durable acceptance contract.

## Required contract

Acceptance claims are stable IDs defined by the branching-audit inventory, for example:

~~~text
quest_offer_accept_turnin_repeat
settlement_ambient_admission_boundary
confirmation_modal_required
no_unconfirmed_destructive_dispatch
~~~

The exact test/case must explicitly declare the claim IDs it owns.

The manifest may reference the owner, but the manifest must not self-certify the claim merely by repeating `requiredClaims`.

Desired proof chain:

~~~text
audit inventory
  requiredClaims=[A,B]

manifest
  source=X
  testIds=[Y]

owner X / exact test Y
  auditClaims=[A,B]

validator
  inventory.requiredClaims ⊆ owner.auditClaims
~~~

No keyword/text semantic matching is allowed as acceptance evidence.

## Preferred low-duplication representation

Keep claim ownership beside the actual test rather than creating another broad registry.

Use the existing test system where practical:

- declarative fixture case: explicit `auditClaims` array on that exact case;
- Python unittest: explicit machine-readable method metadata, preferably a method docstring/annotation parsed by AST or an existing classification field tied to that exact method;
- Lua smoke: explicit machine-readable claim marker associated with that exact smoke/test ID, not whole-file prose keyword search.

If the existing `TEST_CLASSIFICATION.json` is extended, bind claims at `methodDetails` level and validate it against current source/test names. Do not duplicate the whole test catalog merely for S11.

Equivalent explicit local metadata is acceptable if it is deterministic, exact-test scoped, and validated.

## R6A removals

`claimKeywords` may remain as non-authoritative human search hints only if clearly ignored by acceptance; preferably remove them from the acceptance proof path.

Do not use:

~~~text
substring match
test name keyword match
whole-file keyword search
manifest requiredClaims copied back as proof
~~~

## R6A negative tests

Prove failure for:

- owner file/test exists but declares no audit claim;
- owner declares the wrong audit claim;
- only a human-readable keyword appears in the source;
- Lua file contains the keyword elsewhere but the exact test owner lacks the claim;
- manifest repeats the required claim while owner metadata does not;
- stale owner claim references a deleted/renamed test.

R6A closes only when the real 25-row inventory passes under explicit claim ownership with no semantic keyword heuristic.

Commit accepted R6A locally, then continue automatically to R6B.

# R6B — residual lifecycle/presentation acceptance

Do not redesign working authorities. Add the missing end-to-end proofs and only make the smallest implementation changes necessary when a test exposes a real projection defect.

## Quest — complete the production lifecycle

Current production QuestService-backed conversation test proves:

~~~text
offer → available
accept → accepted/active
repeat offer → active/already_allocated
status → active
premature turn-in → rejected
~~~

It does not yet prove the required terminal half.

Extend the same production-authority conversation lifecycle through:

~~~text
objective progress using existing QuestService authority
→ READY_TO_TURN_IN

conversation status / suggestion projection
→ ready

turn in
→ REWARDED

repeat turn in
→ no second reward / idempotent terminal result

repeat offer/status after reward
→ terminal/rewarded projection
→ never available again
~~~

This must use the same real QuestService-backed worker path, not a canned `runtime.questResponses` result.

Buttons/suggestions and typed/free-text must agree with the authoritative quest state where those surfaces are public.

Do not create ConvoEngine quest shadow state.

## Parameterized tasks — prove projection parity

Retain the existing R5B duplicate-suppression test.

Add one representative conversation-surface test that proves:

~~~text
before request
→ task affordance actionable

after admitted/active
→ refreshed suggestion/response-channel reflects active or retires according to policy

typed duplicate
→ zero dispatch

after authoritative terminal state
→ refreshed suggestion/response-channel reflects terminal/retired state

typed repeat
→ zero duplicate dispatch/effect
~~~

Use the existing task authority/contracts. If the current product intentionally rebuilds rather than live-refreshes a surface, encode that explicit policy and test it.

Do not create a second task-state store.

## Settlement admission / ambient visit — prove conversation refresh

Retain the strong existing service and server-authority tests.

Add a production conversation/presentation regression covering the public surface:

~~~text
eligible admission/ambient candidate visible
→ click/execute through authoritative service
→ success result handled by client conversation path
→ current conversation projection refreshes
→ stale admission/visit affordance disappears or changes
→ repeated stale click/input cannot duplicate mutation
~~~

For settlement admission, verify the admitted NPC no longer exposes the stale admission affordance in the active conversation.

For ambient visit, verify the active visit state produces the intended post-success surface and repeat behavior.

If live refresh is intentionally not supported and a conversation rebuild is the product contract, encode and test that explicitly; do not leave it accidental.

The audit manifest must point to the actual conversation-level owner, not only the low-level service smoke.

# R6C — one generic canonical policy-admission seam

## Current defect

R5C correctly removed hard-coded recruitment reply text/reason mapping.

But generic `Input_Actions_Dispatch.lua` still contains a family-specific admission block:

~~~text
if action == RELATIONSHIP_PROPOSAL or action == RECRUIT
    evaluateCanonicalPolicyBlock(...)
~~~

and later another generic policy evaluation path for normal actions.

Thus recruitment/proposal remain named by the generic kernel solely for policy admission.

## Required architecture

Canonical policy admission occurs once for any action that has a canonical policy plan.

Desired shape:

~~~text
resolve action intent
→ prepare generic context / required target hints
→ find canonical policy plan
→ evaluate canonical admission exactly once
→ if blocked: project canonical replyOutcome generically and return
→ if dispatch admitted: route to domain-specific action dispatcher
~~~

Domain-specific mutation dispatch may still contain:

~~~text
if action == RELATIONSHIP_PROPOSAL → DispatchRelationshipProposal
if action == RECRUIT → DispatchRecruitment
~~~

because those are action routing responsibilities.

What must disappear is family-specific branching whose only purpose is deciding whether canonical policy should run.

Preserve camp/world-target hint requirements: prepare whatever generic context an action needs before its single policy evaluation without reintroducing family-specific policy authority.

## R6C regression

Strengthen the static/runtime regression to prove:

- no hard-coded recruitment reason/template/text mapping;
- canonical `ProjectReply` is used for blocked reply projection;
- `EvaluateStatePolicy`/policy admission has one generic call path in `DispatchAction`;
- no `RECRUIT`/`RELATIONSHIP_PROPOSAL` condition exists solely around policy evaluation;
- changing canonical reply metadata still changes projected runtime reply without editing dispatch Lua.

No compatibility shim.

# R6D — final reproducible closure

Only after R6A-R6C are accepted.

Run at least:

- explicit-claim negative guards and full 25-row strict inventory validation;
- Core semantic-harness;
- ProjectHoomans provider tests;
- real LuaSemanticWorker paths;
- task lifecycle + response-channel projection test;
- full production quest lifecycle through ready/rewarded/repeat;
- settlement/ambient conversation refresh test;
- disband/event retained regressions;
- recruitment/proposal canonical policy/reply regressions;
- Reference VM ↔ PZ/Lua parity where affected;
- canonical nine-suite acceptance;
- CodeBuilder `reconcile.py --check`;
- integrity/determinism;
- Kahlua/static verification;
- retired Flow_Identity/Flow_Needs/Flow_Greeting caller-zero;
- `git diff --check`.

Do not bless new baselines merely to achieve green.

Unrelated NPCAuthoring/StartingCompanions/UniqueNPCEditor dirty work remains outside S11. Preserve it and classify any failures by exact signature.

## Final continuity reconciliation

At accepted R6D, rewrite—do not append—the current closure state in:

- `ROADMAP.md`;
- `PROGRESS.md`;
- `HANDOFF.md`;
- `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`;
- `S11_BRANCHING_DIALOGUE_AUDIT.md`;
- this R6 repair doc;
- historical R5 repair status.

All must describe one state.

Final HANDOFF records:

~~~text
exact Core commit
exact ProjectHoomans commit
exact DynamicTrading commit
exact residual path count
SHA-256 residual fingerprint for every participant
acceptance evidence
~~~

A participant worktree changing after the checkpoint invalidates the baton and must be re-snapshotted before handoff.

## CodeBuilder / no-shim invariant

Dialogue semantic policy remains canonical CodeBuilder source → canonical IR → Portable Dialogue Plan → generated runtime.

Do not hand-edit generated artifacts.

Do not introduce forwarding wrappers, fallback readers, dual registries/writes, legacy aliases, parallel old/new semantic paths, or shadow task/quest/settlement authority.

## LLM-minimized / emergent foundation invariant

Preserve:

~~~text
ParticipantSet
dynamic roles/cardinality
SemanticBeat
ConversationArchetype
TopicRef
EventRef
ActivityRef
MemoryRef
DomainRef
~~~

Do not implement the future Dialogue Director in R6.

Semantic correctness, state, effects, actions, memory truth, role legality and closure must require zero LLM calls.

## Completion invariant

S11 is developer-side complete only when:

> every maintained audit row is closed-set and owned by an exact test/case that explicitly declares the required stable audit claim IDs; production quest conversation state reaches ready/rewarded/repeat correctly; representative task and settlement/ambient conversation surfaces refresh consistently with authoritative state; generic action policy admission is single-path and family-agnostic; all retained acceptance gates are reproducibly green; and every continuity document records one exact committed participant checkpoint with current residual fingerprints.
