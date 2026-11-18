# S11 Dialogue Completeness and Semantic Episode Memory Continuity

**Status:** APPROVED FOUNDATION DESIGN — required before broad S11 content migration.
**Date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Architecture dependency:** `S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md`
**Portable facts/effects dependency:** `S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md`
**Optimization dependency:** `S11_COMPILER_RUNTIME_OPTIMIZATION.md`
**Participant/emergent-dialogue dependency:** `S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md`

## Purpose

S11 must not merely repair the currently known branching bugs. The compiler must become capable of proving that maintained dialogue is semantically complete and of identifying exactly where a reachable conversational branch is still open-ended, under-specified, unreachable, contradictory, or missing memory continuity.

This foundation also strengthens same-day conversation memory.

A conversation branch is allowed to end without losing context. Conversational continuation state and durable/social/gameplay obligations are different things.

Example:

```text
NPC asks for water
→ player agrees
→ NPC acknowledges
→ conversation branch END_RESOLVED
→ semantic episode records player_accepted_help
→ gameplay/social obligation bring_water remains pending
```

The live flow must not remain artificially open for hours merely because a real-world obligation still exists.

## Existing memory layers to preserve

ProjectHoomans already has distinct mechanisms that S11 must extend rather than replace.

### Working conversation context

Current `DialogueContextState` owns bounded active-session context such as:

- current/previous topic;
- recent turns;
- focus and mentions;
- pending identity exchange;
- pending follow-up;
- flow sessions;
- agenda.

This is short-lived conversation state.

### Same-day ConversationMemory

The existing ConversationMemory event/topic system already stores compact per-player current-world-day topic memory and can project facts such as:

```text
Earlier today, you discussed <topics> with this player.
```

This is the correct persistence system to enrich with compact semantic episode references.

### Durable event/domain memory

Existing durable relationship/event/quest/task/etc. authorities own long-term or gameplay-significant truth.

Do not duplicate those facts into a new dialogue-memory store.

## Non-negotiable memory rule

Do not persist raw transcript summaries as semantic authority.

Do not add a second `DialogueMemorySystem`.

Persist compact semantic facts/references through existing ConversationMemory/domain authorities.

Wording is presentation. Memory authority is structured semantic state.

## Current implementation status — post-R9 usability audit

The compiler-side Dialogue Completeness Analyzer and its Semantic Lab Workbench integration now exist and are retained. However, the authoring-readiness gate is reopened under `S11_POST_R9_WORKBENCH_USABILITY_REPAIR.md` because the current Workbench is dialogue-only (520 analyzed versus 588 maintained canonical families), can desynchronize from the main editor selection, renders semantic color classes as text rather than actual visual priority, lacks exact-field/test workflow wiring, and retains obsolete legacy surfaces.

The same compiler-owned graph/report remains authoritative. R9R1 must improve coverage and presentation without creating a second Tk-owned semantic analyzer. Broad dialogue/beat/behavior/realization rewriting remains blocked until R9R1E.

## Compiler placement

Add one Dialogue Completeness Analyzer to the existing compiler pipeline:

```text
compact ConvoEngine/PSDL
→ canonical Semantic Dialogue IR
→ Portable Dialogue Plan
→ Dialogue Completeness Analyzer
→ backend generation / acceptance artifacts
```

The analyzer consumes the canonical semantic program. It does not become a runtime dialogue engine.

Its expensive graph/reachability/cycle/coverage reasoning belongs at compile/analyze time. Runtime must consume compact generated results/dependencies rather than rebuild the graph. Incremental analysis should recompute only changed families and their dependency closure where feasible; full package analysis remains the acceptance gate.

Its result is shared by:

- compiler validation;
- CodeBuilder authoring/scaffolding;
- Semantic Lab graph/diagnostics;
- declarative fixture coverage;
- agent repair packets;
- backend parity tests.

No second graph implementation should be maintained in Semantic Lab.

## Semantic conversation graph

For each maintained semantic family, build a normalized directed graph.

### Node classes

At minimum:

```text
family entry
state-policy outcome
input-policy gate
ActionContract dispatch
authoritative result outcome
reply outcome
flow node
confirmation/pending obligation
defer/expiry node
terminal closure
memory episode projection
```

### Edge classes

At minimum:

```text
predicate/state-rule match
typed/click input route
action result
reply branch
after.goto
after.recommend
after.end
flow transition
confirm
cancel/refuse
timeout/expiry
memory/obligation transfer
```

The graph must be derived from canonical IR/Portable Plan rather than by scraping generated Lua.

## Closure classes

Every reachable conversation branch must terminate or continue through one explicit semantic class:

```text
TERMINAL_RESOLVED
TERMINAL_CANCELLED
TERMINAL_REFUSED
TERMINAL_INTERRUPTED
TERMINAL_EXPIRED
TERMINAL_WITH_OBLIGATION
CONTINUES
PENDING_WITH_EXIT
DEFERRED_WITH_EXPIRY
STATE_TRANSITION
INTENTIONAL_BOUNDED_LOOP
INVALID_OPEN_END
```

Exact enum spelling may follow current compiler conventions, but these distinctions are required.

An absent edge in a stateful/effectful/multi-stage family must not silently mean “probably done.”

## Reachability and completeness

The analyzer must prove, for every reachable node:

1. there is at least one valid outgoing semantic outcome unless terminal;
2. every declared state-policy outcome is handled;
3. every ActionContract/result outcome requiring conversational ownership is handled or explicitly delegated;
4. every pending/confirmation obligation has completion/cancel/expiry/defer ownership;
5. every continuation target exists;
6. unreachable branches are reported;
7. shadowed state-policy rules are reported when provable;
8. state-changing outcomes have a fresh post-state projection contract.

## Cycle and progress analysis

Use strongly-connected-component/cycle analysis over the canonical graph.

A reachable nonterminal cycle is valid only if at least one edge/node proves semantic progress through:

- authoritative state mutation;
- required-slot progress;
- bounded retry count;
- timeout/expiry;
- explicit defer;
- explicit cancel/refuse escape;
- state-retirement condition;
- eventual terminal authoritative outcome.

The current Needs pattern:

```text
proposal_pending
→ ACCEPT
→ proposal_pending
```

with no observable progress must fail compilation.

## Continuation obligation accounting

Any semantic turn that asks the other participant for a response creates a compile-time continuation obligation.

Examples:

```text
What's your name?
→ identity.player_name

How many?
→ needs.quantity

Are you sure?
→ confirmation

Which one?
→ selection
```

Every obligation must be provably:

```text
consumed
cancelled
refused
expired
transferred to a durable/domain obligation
or explicitly deferred
```

An obligation must never disappear merely because the visible branch ended.

Conversely, a conversation-local obligation must not remain open after the branch is semantically resolved.

## Semantic episode residue

When a conversational branch closes, the canonical semantic program must be able to describe what remains relevant.

Allowed residue classes:

```text
none
resolved_episode
durable_fact_reference
open_domain_obligation
deferred_domain_obligation
state_transition
```

Conceptual episode data:

```text
family
topic
outcome
reason
important bounded slots/references
closure class
domain obligation reference/status
state-transition reference
world-day/session provenance
```

Do not store arbitrary prose as the canonical residue.

## Same-day memory integration

On terminal closure, emit a compact semantic episode projection into the existing ConversationMemory path when the family declares meaningful same-day residue.

Conceptual flow:

```text
canonical terminal outcome
→ compact semantic episode projection
→ existing ConversationMemory repository/events
→ current-world-day per-player memory
→ later request-local context projection
```

This enriches, rather than replaces, the existing same-day topic memory.

A later prompt/context may therefore receive structured facts such as:

```text
Earlier today:
- this player accepted your request for water;
- the related bring_water obligation is still pending;
- you already introduced yourself to this player.
```

Presentation may realize these facts differently by language/personality.

## Current authoritative state always wins

Memory records what happened; domain authority says what is true now.

Example:

```text
morning episode:
player accepted bring_water

afternoon authoritative task state:
bring_water = completed
```

A later reference to “that water” must resolve to the episode, but the reply must use current task state and say it is completed rather than still pending.

Never resurrect obsolete state from memory.

## Context-reference resolution

The semantic context resolver should be able to rank recent episode/obligation references for inputs such as:

```text
about that...
about what you asked earlier...
did you still need it?
what about our conversation earlier?
you remember my name, right?
```

Ranking should prefer:

1. same NPC/player pair;
2. same day;
3. explicit semantic/topic match;
4. unresolved domain obligation where relevant;
5. recency;
6. salient resolved episode.

Do not infer from raw transcript text when structured episode references exist.

## Memory continuity diagnostics

Add fail-closed compiler/audit diagnostics including:

### CE_MEMORY_LOST_COMMITMENT

A branch creates or claims a commitment but terminates without a domain obligation or memory owner.

### CE_MEMORY_DANGLING_PENDING

A conversation-local pending obligation remains open after semantic terminal closure.

### CE_MEMORY_TERMINAL_CONTRADICTION

A branch is classified resolved while the same obligation remains conversation-pending.

### CE_MEMORY_STATELESS_REFERENCE

A maintained later-context reference expects an episode class that is never persisted/projected.

### CE_MEMORY_UNRESOLVED_WITHOUT_EXPIRY

A persisted/deferred obligation has no completion/cancel/expiry/state-retirement semantics.

### CE_MEMORY_SHADOW_TRUTH

Episode memory attempts to persist a mutable domain fact as a competing source of truth instead of a reference to domain authority.

## Core dialogue completeness diagnostics

The analyzer should also emit stable machine-readable codes for:

```text
CE_DEAD_END
CE_UNHANDLED_STATE_OUTCOME
CE_UNHANDLED_ACTION_OUTCOME
CE_PENDING_WITHOUT_EXIT
CE_UNBOUNDED_CYCLE
CE_UNREACHABLE_BRANCH
CE_SHADOWED_STATE_RULE
CE_TYPED_PARITY_GAP
CE_MISSING_REPEAT_POLICY
CE_STALE_POSTSTATE_RISK
```

Diagnostics must include:

- semantic family;
- source provenance;
- graph node/edge;
- witness/cycle path where applicable;
- missing ownership/progress category;
- suggested valid closure classes.

## Action/result-derived branch obligations

Where a family executes an ActionContract/capability, compiler analysis should derive the authoritative result outcomes that require conversational handling.

Where a statePolicy exists, compiler analysis should derive its possible pre-admission outcomes.

The completeness report should therefore show an explicit matrix such as:

```text
command.follow

pre-admission
  actionable             handled
  already_satisfied      handled
  blocked                missing

action result
  queued                 handled
  rejected               handled
  failed                 missing

typed parity
  actionable             fixture present
  already_satisfied      fixture missing
```

Do not depend on an author/agent remembering all possible outcomes manually.

## Content scaffolding

CodeBuilder may offer a safe scaffold operation that creates missing structural stubs from compiler evidence.

It may scaffold:

- missing reply outcome branch;
- missing terminal/continuation declaration;
- missing declarative fixture skeleton;
- missing memory residue declaration;
- missing input/repeat policy field.

It must not invent final dialogue wording or gameplay effects silently.

Empty/placeholder authored content must remain a validation failure until intentionally completed.

Use the existing CodeBuilder authoring service; do not create another authoring subsystem.

## Fixture coverage generation

The compiler/completeness analyzer should emit a branch-coverage manifest that declarative fixtures can own.

For each stateful family, identify expected scenario classes such as:

```text
actionable / typed
actionable / click
already_satisfied / typed
already_satisfied / click
blocked / typed
blocked / click
confirmation / confirm
confirmation / cancel
terminal memory continuity
later same-day context reference
```

Where a simple state predicate can be satisfied from a bounded scenario patch, CodeBuilder may scaffold a fixture witness.

Complex adopter state may remain an explicit fixture-authoring responsibility.

## Semantic Lab / Studio

Semantic Lab and Studio should consume the compiler-generated conversation graph and completeness report.

Do not reimplement reachability/cycle/completeness logic in the UI.

Useful visual classifications:

```text
complete terminal
pending/deferred
state-changing action
unreachable
missing/open branch
unbounded cycle
memory residue
domain obligation transfer
```

Selecting an issue should show its exact source family/provenance and diagnostic witness.

## Agent repair packet

Expose the analyzer result in compact machine-readable form.

Example:

```json
{
  "family": "needs.support_offer",
  "status": "incomplete",
  "issues": [
    {
      "code": "CE_UNBOUNDED_CYCLE",
      "node": "proposal_pending",
      "path": ["proposal_pending", "ACCEPT", "proposal_pending"],
      "missingProgress": [
        "terminal",
        "state_change",
        "slot_progress",
        "retry_bound",
        "expiry",
        "cancel"
      ]
    }
  ]
}
```

This is intended to reduce agent context and avoid requiring a model to rediscover the whole dialogue graph.

## Same-day memory acceptance scenarios

At minimum add cross-conversation acceptance for:

### Identity

Conversation 1:
- first truthful introduction;
- branch closes;
- same-day episode records resolved identity introduction.

Conversation 2:
- “You remember my name, right?”
- no first-contact obligation;
- current authoritative identity knowledge wins.

### Needs commitment

Conversation 1:
- NPC requests water;
- player accepts;
- conversation branch closes;
- domain obligation remains pending;
- same-day episode references it.

Conversation 2:
- “About that water...”
- context resolves the earlier episode/obligation;
- reply reflects current authoritative obligation state.

Then complete the obligation and repeat the reference:
- memory still resolves the same episode;
- reply reflects completed state rather than pending state.

### Cancel/refuse

Conversation 1:
- NPC asks;
- player refuses/cancels;
- branch closes;
- no false open obligation remains.

Conversation 2:
- later context reference must not claim that the player promised to help.

## Three-level memory invariant

Maintain this separation:

```text
working conversation context
    ↓ terminal semantic closure
same-day semantic episode memory
    ↓ only if domain-significant/salient
existing durable domain/event memory
```

Do not make same-day episode memory permanent by default.

Do not keep working flow state alive merely to simulate memory.

## S11 integration order

**Ordering note:** authoritative S11 execution order is `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md` / ROADMAP S11A. This section describes this subsystem's internal dependencies only and must not move analyzer construction ahead of the S11A1-A3 canonical model/backend freeze.

Before broad identity/companion/flow migration:

1. build the canonical semantic conversation graph;
2. add reachability + outcome/branch completeness;
3. add SCC/cycle + bounded-progress analysis;
4. add continuation-obligation accounting;
5. add semantic closure/residue classification;
6. add same-day episode projection contract into existing ConversationMemory;
7. add machine-readable completeness/coverage report;
8. add the portable EntityRef / fact-query / action / effect / modifier / retention contract and adopter domain schemas;
9. teach completeness analysis to reason about effect authorities, timed modifier lifecycle/stacking, and condition/action contradictions;
10. add stable definition/dependency indexes and incremental-analysis fingerprints from `S11_COMPILER_RUNTIME_OPTIMIZATION.md`;
11. add CodeBuilder structural scaffolding;
12. expose the same graph/report in Semantic Lab without normal-runtime graph reconstruction;
13. add cross-conversation same-day memory and modifier-lifecycle fixtures;
14. establish measured compile/analyze/runtime/save-size budgets;
15. then migrate Identity → Companion Commands → Needs/Greeting → remaining S11 domains.

## Completion invariant

The compiler foundation is accepted only when this statement is true:

> Every reachable maintained dialogue branch can be classified as terminal, progressing, bounded-pending/deferred, or invalid; every continuation obligation has an owner/exit; every meaningful terminal branch declares what semantic residue remains; same-day context is persisted through the existing ConversationMemory/domain authorities rather than stale flow state or transcript prose; typed fact/effect/modifier semantics remain analyzable through registered portable schemas; and the compiler can identify missing branches, unbounded cycles, unowned outcomes, invalid modifier/effect lifecycles, and memory-continuity gaps before backend generation.
