# S11 Semantic State / Outcome Architecture

**Status:** APPROVED POST-G9 DESIGN — implementation begins with S11A preflight/regression freeze.
**Date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Mandatory evidence input:** `S11_BRANCHING_DIALOGUE_AUDIT.md`
**Compiler/memory foundation:** `S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md`
**Portable facts/effects/modifier foundation:** `S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md`
**Compiler/runtime optimization foundation:** `S11_COMPILER_RUNTIME_OPTIMIZATION.md`
**LLM-minimized emergent-dialogue foundation:** `S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md`

## Decision

S11 remains required: the current production ProjectHoomans worker still reproduces the identity, repeated-command, needs-loop, hostile-greeting, recruitment-refresh, and relationship-proposal-refresh defects.

The implementation architecture changed after the G7-G9 structural cleanup.

The semantic-plan authority is now:

```text
compact ConvoEngine / PSDL source
→ Canonical Semantic Dialogue IR
→ Portable Dialogue Plan
→ descriptor-selected backend
→ generated runtime
→ typed capability / ActionContract adapter
→ authoritative gameplay/domain system
```

S11 must extend this pipeline. It must not attach a second authored state system beside it.

The governing rule is:

> ConvoEngine source describes semantic meaning and state-aware conversational policy. Existing domain systems own mutable truth. The Portable Dialogue Plan carries the canonical state/outcome policy. The runtime evaluates that policy against a bounded projection of current authoritative state. Mutating actions then enter the existing `ActionContract`/capability adapter boundary. Buttons, typed input, flows, replies, diagnostics, and refresh consume the same normalized outcome.

## Authority boundaries

State-aware semantic policy is authored in compact ConvoEngine/PSDL source and normalized through the canonical IR into the Portable Dialogue Plan. Hand-written ProjectHoomans Lua descriptors, suggestion providers, root menus, and Semantic Lab catalogs are projections or consumers, not the S11 authoring authority.

ProjectHoomans remains authoritative for mutable Hoomans gameplay facts and effects. DynamicTrading/DTCommon remains authoritative for its own domain state and actions. Core never manufactures adopter gameplay truth.

Core already owns `PsychopatzCore/ConvoEngine/ActionContract.lua`. S11 extends this action/result lifecycle rather than creating a second outcome execution engine. `ActionContract.Execute()` remains the mutation boundary and `ActionContract.ProjectResult()` remains the bounded post-authority normalization seam.

A state-aware turn therefore has two phases of one outcome lifecycle:

```text
pre-admission state outcome
→ dispatch / no-op / reject / confirm / defer
→ if dispatch: ActionContract.Execute
→ domain authority
→ ActionContract.ProjectResult
→ post-authority outcome
```

The canonical `SemanticOutcome` is a data contract spanning these phases, not a second registry/runtime.

## Non-negotiable no-split-system rules

1. No second persisted semantic copy of relationship, identity, order, task, quest, gift, event, knowledge, or world truth.
2. No `StatefulDialogueRegistry`, second capability catalog, or second action registry.
3. No second predicate/condition DSL. Reuse the existing canonical predicate AST and `PsychopatzSemanticPredicate`.
4. No suggestion-only gameplay-state authority.
5. No typed-input-only gameplay-state authority.
6. No response-side re-derivation of gameplay state.
7. No second cooldown/repeat/history subsystem.
8. No UI/Semantic Lab-owned source of truth.
9. No hand-editing generated ConvoEngine runtime artifacts.
10. No family-specific duplicate evaluator merely to make button and typed paths both green.

## Current post-G9 seams to extend

### Compact PSDL / ConvoEngine source

Historical S11 implementation used `psychopatz.psdl.v2` and `psychopatz.psdl.package.v2` as compact/package identifiers. The later pre-release S12 standard supersedes that naming: first-party authoring converges on `psychopatz.convo-engine.v1` / `psychopatz.convo-engine.package.v1` with no released compatibility obligation. The state/outcome semantics defined here remain normative; only the pre-release schema naming decision is superseded.

The accepted production seam is:

```text
compact source
→ canonical IR
→ Portable Dialogue Plan
→ backend projection
```

State/outcome fields must survive this entire path.

### Canonical predicate

Reuse the current predicate normalization/evaluation used by the compiler, Portable Reference VM, and Lua runtime. State policy conditions must be portable predicate AST, not adopter callbacks.

### Portable Dialogue Plan

The Portable Dialogue Plan is the cross-backend semantic-plan authority. S11 state policy, input policy, repeat policy, and postcondition metadata must be present there so the Reference VM and PZ/Lua backend can be tested for equivalence.

### Offer, ActionContract, capability ABI, and catalogs

`Offer.lua` remains the semantic affordance/presentation contract. Stateful availability must derive from the same canonical outcome used by typed input.

Use the existing ActionContract for authoritative mutation and normalized result projection. S11 may extend its generic result envelope where necessary but must not add a parallel lifecycle.

The current capability ABI and typed adapter boundary remain valid. State policy must remain package-neutral; Core must not hard-code PNC action IDs, source roots, or Hoomans-specific reasons.

CapabilityCatalog/Semantic Lab may expose the compiled contract for diagnostics. They do not author it.

CandidateEligibility remains parser/context safety, not gameplay-state admission.

## Portable state policy

A stateful semantic family may declare a bounded `statePolicy` using the existing predicate AST. Conceptually:

```json
{
  "statePolicy": [
    {
      "id": "already_following",
      "when": {"path": "addressee.companion.orderKind", "op": "eq", "value": "follow"},
      "outcome": "already_satisfied",
      "reason": "already_following",
      "admission": "no_op"
    },
    {
      "id": "default",
      "outcome": "actionable",
      "reason": "actionable",
      "admission": "dispatch"
    }
  ]
}
```

The exact compact syntax may evolve, but canonical IR must remain explicit and validation-friendly. Evaluation must be deterministic, non-mutating, fail-closed, and diagnostic.

## Canonical outcome envelope

Use one normalized data envelope across pre-admission and post-authority stages. It carries semantic identity/family/capability, matched state rule, outcome, reason, admission, response outcome, presentation implication, authoritative result when dispatched, stateChanged, and expected postconditions.

Generic pre-admission outcomes should remain small:

```text
actionable
already_satisfied
blocked
unavailable
requires_confirmation
pending
deferred
```

Existing action/result outcomes remain valid after dispatch:

```text
queued
accepted
rejected
failed
completed
pending
```

Adopter-specific meaning stays in `reason`, such as `already_following`, `already_lover`, `already_member`, `companion_busy`, and `quest_already_active`.

## Admission, input, repeat, and postconditions

Admission modes are bounded:

```text
dispatch
no_op
reject
confirm
defer
none
```

Recognition does not imply authorization.

Every maintained stateful public act owns one portable input policy:

```text
typed_parity
typed_confirmation
presentation_only
```

Effectful authored acts declare repeat semantics in canonical source:

```text
once
cooldown
max_uses
state_retired
repeatable
idempotent
```

Carry repeat policy through canonical IR/Portable Plan into the existing history/repeat machinery; do not add another cooldown engine.

Expected postconditions are verification/refresh contracts, not mutation instructions. A failed postcondition is diagnostic evidence; never patch shadow state to make it pass.

## Canonical evaluation lifecycle

```text
1. player text / affordance / authored continuation
2. semantic IR / selected family
3. bounded fresh projection of authoritative state
4. evaluate portable statePolicy
5. apply inputPolicy
6. short-circuit no_op/reject/confirm/defer OR dispatch
7. if dispatch, execute existing ActionContract/capability adapter
8. normalize authoritative result through existing result mapping
9. select reply from normalized outcome + reason
10. rebuild state-sensitive projection from fresh authority
```

Buttons and typed input may present differently, but they must not disagree about canonical state outcome for the same family and projected state.

## Identity reference migration

Identity is the first reference migration. Project directional facts from current authorities, distinguish first introduction/reconfirmation/repetition/correction/deception, prevent known-name reminders from opening first-contact obligations, make first-introduction effects idempotent, prevent stale choice resurrection, and prove typed/click convergence before wording selection.

Identity must not get an identity-only state evaluator.

## Companion command reference migration

Companion commands are the second proof that the architecture is generic. The current cleanup already provides the modern pattern for `command.camp`:

```text
compact PSDL action/execute
→ registered Core ActionContract
→ Hoomans capability adapter
```

Normalize maintained FOLLOW/STAY/STOP/GO HOME/CAMP/combat commands toward that path where feasible. Already-satisfied or blocked typed commands must dispatch zero gameplay requests.

## Flow migration and bounded progress

The generic flow runtime may remain. Hand-written domain flow definitions such as identity/needs/greeting must not become a second semantic authoring authority when their semantic definition can live in canonical source.

A nonterminal self-loop must prove bounded progress through authoritative state change, required-slot progress, bounded retry, timeout/expiry, explicit defer, cancel/refuse, or eventual terminal authority result.

The current `proposal_pending -> proposal_pending` ACCEPT loop with no progress must fail validation. Needs must either create a real commitment/task or truthfully close as conversational acknowledgement. Greeting/parley must consume the same actor-state policy.

## Dialogue completeness and memory continuity

`S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md` is normative for the compiler foundation.

Before broad content migration, the compiler must derive one semantic conversation graph from canonical IR/Portable Plan and prove reachability, branch/outcome completeness, bounded cycle/progress, continuation-obligation ownership, terminal closure classification, memory-residue ownership, and same-day context-reference continuity.

A conversation-local flow may close while a domain obligation remains pending. Do not keep flow state artificially open to simulate memory.

Meaningful terminal residue must project through the existing ConversationMemory/domain authority rather than raw transcript prose or a second memory store. The existing same-day topic memory should be enriched with compact semantic episode references such as family/outcome/reason/important bounded references/closure class/domain-obligation reference. Current authoritative domain state always wins over remembered episode state.

The compiler/completeness report is the single analysis authority for CodeBuilder scaffolding, Semantic Lab visualization, fixture coverage, and agent repair packets. Do not implement a second graph/completeness analyzer in the UI.

## Portable facts, effects, and timed modifiers

`S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md` is normative for compact state conditions and consequences.

Core compiler vocabulary remains small: EntityRef, Predicate/Query, Action, Effect, Modifier, Retention, and MemoryResidue. Adopters register domain schemas/providers/adapters for relationship, mood, inventory, health, traits, needs, tasks, quests, combat, and future domains.

`when` is read-only and resolves through registered semantic fact/query providers. `execute` requests authoritative mutation through the existing ActionContract/capability path. `effects` apply typed adopter-owned consequences. Timed buffs/debuffs use one generic modifier lifecycle with game-time retention and explicit stacking. `memory` remains semantic episode persistence and is distinct from active modifiers.

Authoring sugar such as actor/target item constraints, relationship thresholds, duration literals, and reusable presets must normalize into explicit canonical IR before Portable Plan generation. Raw adopter persistence paths and opaque Lua callbacks are not portable semantic policy.

ProjectHoomans current `pnc:relationship` / `pnc:memory`, RelationshipService memories/decay, `PNC_MoraleModifierDefinitions`, and authoritative inventory query/consumption services are reference seams to adapt, not duplicate.

## Compiler/runtime optimization

`S11_COMPILER_RUNTIME_OPTIMIZATION.md` is normative for keeping the expanded semantic system cheap enough for Project Zomboid.

The optimization rule is: do expensive reasoning at compile time; generate compact deterministic definitions, dependency indexes, and analysis artifacts; keep runtime evaluation bounded and authority-driven.

Compiled families should declare required facts. Runtime should project only those facts and invalidate only consumers affected by authoritative state changes. Static definition data stays in generated definitions; persisted memory/modifier instances keep only mutable data and stable references.

Timed memories/modifiers must use bounded game-time scheduling rather than per-frame global scans. Presets/macros expand at compile time. Detailed decision traces are opt-in diagnostics, not normal runtime allocations.

Optimization must be measured. S11A establishes current baselines and evidence-based performance/save-size budgets before hard thresholds. Never weaken semantic correctness, completeness, backend parity, or domain authority merely to improve a benchmark.

## Participant-agnostic emergent-dialogue foundation

`S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md` is normative for future-proofing the semantic model without implementing the future Dialogue Director.

Canonical IR/Portable Plan must be able to represent a bounded ParticipantSet plus dynamically bound semantic roles with cardinality. `speaker`/`addressee` remain convenience roles, not a two-person hard limit.

Reusable families/archetypes should preserve structured semantic act, TopicRef, EventRef, ActivityRef and MemoryRef-compatible metadata; required/optional role contracts; required facts; repeat/cooldown; continuation/closure; and realization references. This makes future candidate discovery/scoring mechanical rather than prose- or LLM-dependent.

S11 must not implement autonomous beat/topic selection, global social utility scoring, personality conversation planning, or unrestricted procedural semantic generation. Future director logic remains a consumer of validated ConvoEngine candidates.

Semantic correctness and gameplay authority must be executable with zero LLM calls. Optional future LLM use may assist presentation or bounded ranking among already-valid candidates only.

## Testing authority after the structural cleanup

Behavioral semantic acceptance is provider-owned declarative fixture data under `tools/providers/pnc/fixtures/v1/`. Use those fixtures as the primary S11 behavioral regression authority.

Imperative tests remain appropriate for compiler/schema validation, Portable Plan normalization, Reference VM, PZ backend projection, ActionContract lifecycle, static ownership guards, worker lifecycle/protocol, GUI/Tk/Xvfb, and performance.

Correct existing behavior contracts that bless the defects rather than adding contradictory parallel tests. Repeated FOLLOW currently expects a second dispatch, and a Needs fixture currently permits `proposal_pending` to remain open after acknowledgement. Valid first-contact identity fixtures remain valid.

## Cross-backend parity gate

For the same canonical family, semantic input, and projected state, Portable Reference VM and PZ/Lua backend must agree on matched state rule, outcome, reason, admission, and reply outcome.

## Validation requirements

Add generic validation for malformed/duplicate policy rules, unsupported outcome/admission, missing input/repeat policy, unbounded self-loops, dispatch after no-op/reject, stale post-state projection, button/typed mismatch, missing acceptance ownership, adopter reason leaking into Core vocabulary, Portable Plan/backend policy divergence, and any new parallel registry/evaluator.

## DynamicTrading scope

DTCommon is a mandatory portability participant, not an automatic Hoomans behavior-rewrite target. S11 compiler/schema/Portable Plan changes must remain generic.

Before S11 source implementation begins, close or explicitly baseline pre-existing CodeBuilder reconciliation drift. The 2026-11-18 audit found exactly two pre-existing DTCommon generated fingerprint drifts:

```text
DTCommon/ConvoEngine/Manifest.lua
DTCommon/ConvoEngine/Registry.lua
```

## S11 implementation sequence

### Preflight
Verify all three repositories, preserve unrelated work, and reconcile or baseline the two DT generated drifts.

### S11A — regression freeze + compiler-completeness/participant-agnostic/portable/optimized substrate
Encode P0 regressions as declarative fixtures; build the canonical conversation graph/completeness analyzer; add reachability, outcome completeness, bounded-cycle/progress, continuation-obligation, closure/residue, same-day semantic episode continuity, branch/fixture coverage and machine-readable repair diagnostics; add the portable EntityRef/fact-query/action/effect/modifier/retention vocabulary and adopter domain-schema registration; add stable definition IDs, dependency metadata, dependency-driven projection/invalidation, compact runtime lowering, incremental analysis, bounded timed-expiry scheduling, dedupe/aggregation, compact persistence, on-demand traces, and measured performance budgets; extend compact source → IR → Portable Plan → backend/Reference VM with state/input/repeat/postcondition policy; integrate outcomes/effects with existing ActionContract/domain authorities; add parity and negative guards.

### S11B — identity migration
Fix known/reminder state, idempotence, reconfirmation/repetition, stale projection, and typed/click parity.

### S11C — companion + flow reference migrations
Normalize companion actions toward canonical action/execute + ActionContract; remove duplicate state tests after proof; repair/migrate Needs and Greeting.

### S11D — full constrained-domain sweep
Cover every family in `S11_BRANCHING_DIALOGUE_AUDIT.md`, preserving reference-good authorities.

### S11E — real surfaces + closure
Run S11 fixtures, compiler/backend parity, real worker, click/inputbox, Tk/Xvfb, S10A label/speech, canonical nine-suite acceptance, reconciliation/no-op generation, and `git diff --check`; then commit adopters first and Core last.

## Completion gate

S11 is complete only when all maintained stateful families have one canonical portable state/outcome policy; actor/target conditions and typed effects/modifiers use one compiler-normalized portable vocabulary with adopter domain schemas; generated definitions/indexes are deterministic and compact; runtime fetches only required authoritative facts, invalidates affected dependencies, avoids per-frame global memory/modifier scans, and persists only mutable instance data; buttons and typed input agree; already-satisfied/blocked actions do not duplicate gameplay dispatch; effectful repeats and timed modifiers are safe; every reachable branch is classified as terminal/progressing/bounded-pending or invalid; continuation obligations have owners/exits; meaningful terminal residue survives through existing same-day ConversationMemory/domain authorities without stale live flow state; state-changing results refresh affordances; Reference VM and PZ backend agree; measured performance/save-size budgets pass; no parallel semantic/effect/modifier authority exists; declarative behavioral fixtures and canonical acceptance are green; and exact cross-repository closure is recorded.
