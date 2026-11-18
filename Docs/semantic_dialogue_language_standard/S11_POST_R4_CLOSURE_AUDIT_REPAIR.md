# S11 Post-R4 Closure Audit Repair

**Status:** NORMATIVE ACTIVE REPAIR PLAN
**Audit date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Mandatory scope input:** `S11_BRANCHING_DIALOGUE_AUDIT.md`
**Historical repair:** `S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md`

## Purpose

R0-R4 repaired substantial S11 implementation, but a fresh post-R4 source/test/document audit found that closure can still report green while mandatory audit rows are omitted, mis-owned, or only partially tested.

This repair is deliberately narrow.

Do **not** rebuild S11A, Identity, Needs, Greeting, or maintained companion command migrations. Preserve the accepted canonical work and close the remaining acceptance/authority gaps once.

## Verified retained foundation

Current accepted implementation includes:

- generic S11 compiler/runtime foundation;
- dynamic ParticipantSet + semantic-role/cardinality foundation;
- canonical Identity migration with old flow retired;
- canonical companion-command, Needs, and Greeting migrations with old flows retired;
- canonical recruitment, relationship proposal, ceasefire, territory, and effectful wellbeing/trust families;
- recruitment/proposal transition-refresh and repeat-no-op fixtures;
- Core semantic-harness unit suite 308 PASS / 2 skips;
- focused ProjectHoomans quest/event/automatic-flow tests 17/17 PASS;
- recipe reconcile clean at 410 desired outputs;
- integrity/determinism clean at 588 family files and 407 deterministic generated files.

These are implementation evidence, not permission to weaken the remaining gates.

## Finding P1 — constrained-family manifest is not closed-set against the branching audit

`constrained_family_manifest.json` declares an `auditSource`, but the analyzer does not consume or reconcile that source.

Therefore:

~~~text
branching audit contains mandatory row X
manifest omits X
strict_manifest=True
→ can still report green
~~~

### Required repair

Create one machine-readable canonical audit inventory or deterministic extraction/compilation step owned by the acceptance/compiler layer.

The maintained audit inventory and constrained-family manifest must have exact closed-set coverage.

Acceptance must fail for:

- an audit row missing from the manifest;
- a manifest row with no audit row;
- duplicate audit IDs;
- unsupported classification;
- a `CANONICAL_STATEFUL` row without its canonical family/policy;
- a `RETIRED` row still present;
- an `EXPLICIT_PRESENTATION_ONLY` or `REFERENCE_GOOD_REGRESSION` row without valid acceptance ownership.

Do not parse arbitrary English prose at runtime. Prefer a small machine-readable inventory adjacent to/derived from the maintained audit while the Markdown remains human-readable.

This inventory is acceptance metadata only. It must not become gameplay or semantic runtime authority.

## Finding P2 — acceptance ownership is not verified

Current analyzer logic effectively proves only:

~~~text
acceptanceOwner != ""
~~~

Confirmed bad examples include task, quest, disband, and settlement/ambient rows pointing at `test_automatic_flow_generation.py` even though that module does not contain quest lifecycle, disband, settlement, or ambient-visit acceptance.

### Required repair

Use machine-verifiable acceptance ownership.

A manifest row should reference a stable test/fixture coverage ID, not merely a prose path. A suitable model is:

~~~text
acceptance:
  ownerKind: declarative_fixture | python_test | lua_test | acceptance_suite
  source: <path>
  caseIds / testIds: [...]
  requiredClaims: [...]
~~~

Exact schema may follow existing testing infrastructure, but validation must prove:

1. source exists;
2. referenced case/test ID exists;
3. declared audit/claim ID is owned by that test or fixture;
4. required claims for the classification are covered;
5. stale/deleted acceptance owners fail.

Reuse established Semantic Test classification/fixture discovery where practical; do not create a duplicate general test registry.

## Finding P3 — quest conversation lifecycle is not closed

The authoritative `PNC_QuestService` already has strong service-level lifecycle behavior:

~~~text
AVAILABLE
→ ACTIVE
→ READY_TO_TURN_IN
→ REWARDED
→ repeat turn-in idempotent
→ save/reload
~~~

But the conversation worker still permits:

~~~text
"Can you help me?"
→ available

"Can you help me?"
→ available
~~~

The branching audit specifically required conversation projection against real quest state.

### Required R5B quest acceptance

Use the real authoritative quest path to prove:

~~~text
offer visible/actionable
→ accept
→ active
→ repeated offer becomes already-active/no-op or appropriate status
→ objective progress
→ ready-to-turn-in projection
→ turn-in
→ rewarded
→ repeat does not re-reward
→ suggestion/free-text surfaces reflect current authoritative state
~~~

Do not replace QuestService with ConvoEngine state. ConvoEngine consumes QuestService authority.

## Finding P4 — parameterized task state parity is under-proven

Automatic-flow generation proves template/result routing, including admitted/rejected/failed branches, but not the required conversation-state lifecycle.

### Required R5B task matrix

For representative parameterized tasks, prove the applicable sequence:

~~~text
available/actionable
→ admitted/active
→ duplicate behavior while active
→ completed/failed/rejected
→ repeated input after terminal state
→ no duplicate task dispatch/effect
→ fresh suggestion/free-text projection
~~~

Use the existing task authority and semantic task contracts. Do not create a ConvoEngine task store.

## Finding P5 — event expiry, disband, settlement/ambient ownership gaps

### Event response-window expiry

A real production-worker expiry test already exists, but the constrained manifest omits the audit row. Add explicit manifest/inventory ownership and bind the actual expiry test/case. Do not rewrite the event system if behavior is already correct.

### Disband

The final classification may remain `EXPLICIT_PRESENTATION_ONLY` if that is the intended product rule, but acceptance must prove that free text cannot bypass destructive confirmation, UI confirmation/cancel remains authoritative, and no direct duplicate destructive dispatch occurs. If typed natural language should open confirmation, prove that instead.

### Settlement admission / ambient visit

Existing authority/replay/expiry tests are useful, but S11 requires the conversation surface to refresh after successful transition where applicable.

Prove:

~~~text
eligible affordance
→ authoritative admit/start
→ current conversation projection refresh
→ stale affordance retires/changes
→ repeat is bounded/idempotent
~~~

If a surface is intentionally rebuild-only rather than live-refresh, encode and test that explicit policy.

## Finding P6 — generic dispatch contains family-specific canonical reply mapping

Canonical recruitment source already declares state policy, `replyOutcome`, and authored reply branches.

R3/R4 added hand-written recruitment-specific reason→template/text mapping in:

`ProjectHoomans/.../Dialogue/Input_Actions_Dispatch.lua`

That is duplicate semantic/presentation authority.

### Required R5C repair

Generalize policy handling:

~~~text
find canonical plan
→ evaluate canonical statePolicy
→ admission no_op/reject
→ read generic replyOutcome
→ project canonical reply/consequences
→ return generic blocked/no-op result
~~~

No `if RECRUIT then choose this template/text` logic in generic dispatch.

The same generic path should serve relationship proposal and future canonical families. Domain-specific action execution may remain domain-specific after `dispatch` admission.

Do not add a compatibility wrapper.

## Finding P7 — final continuity closure was contradictory

Previous `PROGRESS.md`/`HANDOFF.md` simultaneously contained COMPLETE and NOT ACCEPTED/R0-only sections, while ROADMAP/parent goal remained reopened. Final residual fingerprints were absent.

This repair rewrites current PROGRESS/HANDOFF to one current truth. R5D must do the same at final acceptance: replace current baton/progress state rather than appending old defect history. Git history is the archive.

## R5 execution order

### R5A — acceptance inventory + owner integrity

1. Preserve current accepted implementation and unrelated work.
2. Make audit inventory ↔ constrained manifest closed-set and deterministic.
3. Make acceptance ownership machine-verifiable.
4. Add negative tests for omitted/extra audit rows, missing owner source/ID, owner-claim mismatch, and canonical-stateful policy omission.
5. Correct current manifest rows only after the mechanism can reject bad ownership.
6. Commit accepted R5A locally.
7. Continue automatically to R5B.

### R5B — remaining S11D closure

Close only:

- parameterized task state matrix;
- quest production conversation lifecycle;
- event response-window expiry ownership;
- disband explicit typed/presentation policy;
- settlement admission / ambient visit post-transition projection and repeat behavior.

Do not broad-remigrate reference-good dialogue. Where product authority is already correct, repair projection + acceptance rather than duplicating authority.

### R5C — generic runtime de-duplication

Remove family-specific recruitment/proposal state/reply projection from generic `Input_Actions_Dispatch.lua`.

Consume canonical plan `replyOutcome` and reply/consequence projection generically.

Add a regression that fails if canonical reply content changes while dispatch still carries a hard-coded old mapping.

No compatibility shim.

### R5D — final reproducible closure

Only after R5A-R5C:

- run focused new negative/behavior tests;
- run full Core semantic-harness;
- run provider declarative/real-worker tests;
- run canonical nine-suite acceptance;
- run Completeness with strict closed-set manifest/inventory;
- run recipe `reconcile.py --check`;
- apply/reconcile only if current authoritative generation requires it;
- run integrity/determinism;
- run Kahlua/static verification;
- prove retired-flow caller/reference zero remains true;
- run `git diff --check`;
- reconcile ROADMAP, PROGRESS, HANDOFF, parent goal, branching audit, and this repair doc;
- final HANDOFF records exact participant commit vector and SHA-256 residual-work fingerprints;
- commit changed participant repos first, Core last;
- no push/publication.

## CodeBuilder / no-shim invariant

Dialogue semantic policy belongs in canonical CodeBuilder source/recipes and generated Portable Plan/runtime projection.

Do not hand-edit generated Lua/registries/manifests/translations.

Do not solve R5 by reintroducing forwarding wrappers, old/new registries, fallback readers, dual writes, duplicate semantic reply tables, family-specific policy in generic dispatch, or conversation-owned task/quest/settlement shadow state.

Use authoritative gameplay/domain services for mutable truth.

## Emergent-dialogue foundation preservation

R5 must preserve:

~~~text
ParticipantSet
dynamic role bindings/cardinality
SemanticBeat
ConversationArchetype
TopicRef
EventRef
ActivityRef
MemoryRef
DomainRef
~~~

Two-person dialogue remains a specialization of generic participant/role binding.

Do not implement autonomous beat/topic selection or an LLM-driven Dialogue Director in R5.

Semantic correctness, actions, effects, memory truth, role legality, and closure must work with zero LLM calls.

## Completion invariant

S11 may return to user-owned native Project Zomboid acceptance only when every maintained branching-audit row is present in the machine-verifiable acceptance inventory, every classification has real acceptance ownership, task/quest/event/disband/settlement residual state behavior is proven, generic runtime dispatch no longer duplicates canonical recruitment/proposal reply semantics, all retained acceptance gates are reproducibly green, and ROADMAP/PROGRESS/HANDOFF describe one exact committed checkpoint with participant residual fingerprints.
