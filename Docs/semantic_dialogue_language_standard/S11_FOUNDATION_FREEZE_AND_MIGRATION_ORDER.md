# S11 Foundation Freeze and Migration Order

**Status:** NORMATIVE EXECUTION ORDER — authoritative for S11 phase ordering.
**Date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`

## Purpose

Prevent repeated migration churn.

S11 must finish and accept the generic semantic/compiler/runtime foundations before production legacy dialogue families are migrated.

No production family should be migrated once for an incomplete schema and then migrated again after roles, memory, modifiers, completeness, dependency indexes, or persistence change.

## Authoritative execution order

This document and ROADMAP S11A own execution order. Foundation documents define contracts, not competing phase order.

### S11A0 — preflight, baseline, and legacy ownership inventory

Do not change production dialogue semantics yet.

- verify all repository HEAD/status/worktree state;
- reconcile or explicitly baseline pre-existing generated drift;
- freeze P0 failures as declarative fixtures;
- measure compiler/runtime/save-size baselines;
- inventory existing semantic/runtime files and classify each relevant surface as:
  - `KEEP_AUTHORITY`
  - `ADAPT`
  - `MIGRATE_LATER`
  - `RETIRE_AFTER_PARITY`
  - `GENERATED_DO_NOT_EDIT`
  - `UNRELATED`
- identify existing schedulers, caches, indexes, memory stores, modifier services, inventory authorities, relationship authorities, ActionContract seams, and CodeBuilder source/recipe ownership.

**Gate:** ownership inventory and baselines are recorded; no production dialogue migration occurred.

### S11A1 — canonical data-model freeze

Define/freeze the S11 v1 canonical structural vocabulary before building analyzers around it:

```text
EntityRef
ParticipantSet
RoleSpec / RoleBinding / cardinality
Predicate / Query
Action
SemanticOutcome
Effect
Modifier
Retention
MemoryResidue
TopicRef
EventRef
ActivityRef
MemoryRef / DomainRef
SemanticBeat
ConversationArchetype
statePolicy
inputPolicy
repeatPolicy
postconditions
continuation / closure
```

Add adopter-domain schema contracts and explicit ownership rules.

Do not migrate production legacy families in this stage.

**Gate:** schema/IR contract is stable enough that later stages consume it without redesigning its ownership model.

### S11A2 — source normalization → canonical IR → Portable Dialogue Plan

Teach canonical compact source and CodeBuilder authoring to express the frozen model.

Use synthetic/minimal fixtures to prove representation. Do not use broad legacy dialogue migration as compiler-development scaffolding.

Example synthetic fixtures may cover:

- one-to-one stateful action;
- multi-participant role binding;
- inventory-gated action;
- timed relationship/mood modifier;
- same-day semantic episode + domain obligation;
- optional role/group reaction.

**Gate:** source → IR → Portable Plan faithfully carries all S11A1 structures.

### S11A3 — backend and Reference VM structural parity

Project the frozen Portable Plan through Reference VM and PZ/Lua backend.

Prove structural equivalence before production content migration.

Keep generic evaluator fallback where optimized lowering is not yet proven.

**Gate:** both backends interpret the same S11 structures and diagnostics.

### S11A4 — Dialogue Completeness Analyzer

Only now build the canonical analyzer over the final S11 structural model.

Analyze:

- reachability;
- state/action outcome completeness;
- SCC/cycle bounded progress;
- continuation obligations;
- role/cardinality binding;
- optional/multi-role paths;
- effect/modifier lifecycle;
- semantic closure/residue;
- memory continuity;
- typed/click parity ownership;
- fixture coverage.

Do not build an analyzer against the old pair-shaped or pre-modifier model and then retrofit it later.

**Gate:** the analyzer understands the final S11A1-A3 representation.

### S11A5 — existing-domain adapters

Connect portable facts/actions/effects/modifiers/memory to existing authorities.

Examples:

```text
relationship effect → existing RelationshipService
inventory query/action → existing inventory authority
mood modifier → existing morale/mood authority
semantic episode → existing ConversationMemory
action execution → existing ActionContract
```

This is infrastructure integration, **not production dialogue migration**.

Do not create compatibility shims, duplicate stores, legacy wrappers, fallback readers, or dual execution paths.

**Gate:** portable contracts reach authoritative systems directly through typed adapters.

### S11A6 — runtime lifecycle

Finalize:

- same-day/timed/permanent/until memory lifecycle;
- timed modifier lifecycle;
- game-time expiry;
- stacking/dedupe/aggregation;
- bounded scheduling;
- compact semantic episode/reference behavior.

**Gate:** production migrations can target one stable lifecycle.

### S11A7 — compiler/runtime optimization

Execute optimization after baseline and structural correctness exist:

- stable generated IDs;
- dependency indexes;
- required-fact projection;
- authoritative invalidation;
- compact predicate/state lowering;
- incremental analysis;
- bounded expiry scheduling;
- compact persistence;
- opt-in traces;
- evidence-based performance/save-size budgets.

Do not create shadow gameplay state to optimize.

### S11A8 — FOUNDATION FREEZE GATE

No broad production legacy migration is allowed before this gate.

Required:

- canonical S11 data model stable;
- source → IR → Portable Plan complete;
- Reference VM ↔ PZ/Lua structural parity green;
- Completeness Analyzer understands final model;
- domain adapters use existing authorities directly;
- memory/modifier lifecycle stable;
- dependency/optimization metadata stable;
- deterministic/no-op generation proven;
- baseline and performance/save-size budgets recorded;
- zero-LLM semantic correctness;
- two-person dialogue proven as specialization of generic participant/role model.

After this gate:

```text
MIGRATION_ALLOWED = true
```

## Production migration order

### S11B — Identity reference migration

Identity is the first real production migration and reference implementation.

Migrate once onto the frozen substrate.

Do not use Identity to discover/redefine the architecture.

### S11C — Companion commands + Needs/Greeting

Migrate onto already-frozen state/action/role/memory/effect/runtime contracts.

### S11D — remaining constrained-domain migration

Migrate remaining audited legacy semantic families.

Use a strangler **replacement**, not compatibility shims:

```text
canonical source recipe
→ generated downstream output
→ parity/acceptance proof
→ prove old caller/reference count is zero
→ retire/delete old semantic definition/path
```

No forwarding aliases, dual readers, fallback legacy paths, shadow registries, or temporary compatibility layers may survive an accepted migration.

If a migration genuinely requires temporary transitional code inside one phase, it must be removed before that phase is accepted.

### S11E — closure

Run complete acceptance, CodeBuilder reconciliation, deterministic/no-op generation, legacy caller-zero/retirement proof, docs reconciliation, and exact repository checkpoint closure.

## CodeBuilder recipe-only migration rule

For dialogue/semantic content and generated runtime outputs, agents must use the existing CodeBuilder authoring + recipe pipeline.

Canonical authoring lives in CodeBuilder source records/packages.

The generation recipe is:

```text
tools/semantic_harness/codebuilder/generation_recipe.json
```

Canonical reconciliation commands are:

```bash
python3 tools/semantic_harness/codebuilder/reconcile.py \
  --recipe tools/semantic_harness/codebuilder/generation_recipe.json \
  --check

python3 tools/semantic_harness/codebuilder/reconcile.py \
  --recipe tools/semantic_harness/codebuilder/generation_recipe.json \
  --apply
```

Use the existing shared CodeBuilder ConvoEngine authoring/migration service for bulk create/edit/move/shard/write operations.

Do not manually manufacture destination JSON trees when the CodeBuilder authoring operation exists.

Do not hand-edit generated Lua, generated registries/manifests, generated translations, or other recipe-owned downstream artifacts.

When dialogue logic changes, edit the canonical compact source/recipe inputs once and regenerate/reconcile downstream outputs.

This is specifically intended to reduce agent token usage: agents should inspect canonical source + compiler contract + recipe/reconcile evidence, not repeatedly read/edit every generated downstream Lua copy.

## No compatibility-shim policy

S11 migration is a cleanup/refactor, not a permanent compatibility-layer project.

Do not add:

- forwarding wrapper modules preserving obsolete semantic APIs;
- duplicate old/new registries;
- fallback reads from legacy dialogue structures;
- dual writes to old and new persistence;
- legacy aliases whose only purpose is keeping migrated internal callers alive;
- old generated output kept beside new generated output after parity;
- compatibility normalizers added solely to avoid migrating owned internal source.

For project-owned internal callers, migrate callers to the canonical path and remove obsolete code after parity/caller-zero proof.

Preserve compatibility only when there is a verified external/public contract that the user explicitly requires. Do not assume one.

## Foundation-doc ordering rule

The following documents define requirements but do not override this execution order:

- `S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md`
- `S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md`
- `S11_COMPILER_RUNTIME_OPTIMIZATION.md`
- `S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md`

If their local implementation-order prose conflicts with this document/ROADMAP, follow this document/ROADMAP and update the stale local prose.

## Completion invariant

> S11 foundations are built once before production migration; production semantic families migrate only after the S11A8 freeze; migrated content is authored through canonical CodeBuilder source/recipes and regenerated downstream; obsolete project-owned legacy semantic paths are deleted after parity/caller-zero proof rather than preserved behind compatibility shims; and no accepted phase leaves dual semantic authorities or duplicate old/new implementations.

## Post-implementation audit clarification

A later audit found that the foundation implementation exists but the S11A4/A8 **acceptance authority was too permissive**: Completeness could validate policy that existed without proving that every constrained family required by `S11_BRANCHING_DIALOGUE_AUDIT.md` had entered canonical policy.

Therefore the foundation freeze is retained, but before migration closure the compiler/acceptance system must also enforce a constrained-family manifest with explicit classifications:

```text
CANONICAL_STATEFUL
EXPLICIT_PRESENTATION_ONLY
REFERENCE_GOOD_REGRESSION
RETIRED
```

A required `CANONICAL_STATEFUL` family that lacks canonical state/input/repeat/closure/effect metadata must fail acceptance. This manifest is acceptance metadata over canonical family IDs, not a second state or semantic registry.

See `S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md`.

This clarification does not authorize rebuilding the accepted A0-A8 substrate. It closes an acceptance blind spot and then resumes the original recipe-only, no-shim migration order.
