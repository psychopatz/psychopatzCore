# S11 Post-Implementation Audit Repair

**Status:** HISTORICAL R0-R4 REPAIR PLAN — implementation substantially landed; final closure reopened by post-R4 audit
**Audit date:** 2026-11-18
**Parent goal:** `S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md`
**Authoritative ordering dependency:** `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`

**Current repair authority:** `S11_POST_R5_FINAL_CLOSURE_REPAIR.md`. Do not resume R0 from this historical document; retain accepted R0-R5 work and execute R6.

## Why S11 is reopened

A fresh source/Git/test audit disproved the prior S11E completion claim.

The foundation work is real and should be preserved. The migration/closure work is not complete.

Do **not** rebuild S11A from scratch. Repair the acceptance loophole, finish the incomplete recipe migrations, perform the missing S11D sweep, then rerun S11E.

## Verified repository checkpoint before this audit-doc correction

```text
psychopatzCore   3f8b933f2545a5e5f2e6b897555c86eee96b2d31
ProjectHoomans   35d1a6bc6b26a0515c2dd19247c3adbc4b4e5d3e
DynamicTrading   503d13037fbc51c66ad42c81191c8b91d1fd4da2
```

All three worktrees were clean at audit start.

## Evidence that remains accepted

### Foundation implementation

The following S11A commits exist in correct order and have useful implementation behind them:

```text
631f9ae  S11A0 baseline / ownership inventory
a5b6d56  S11A1 canonical semantic contract
02f6cc2  S11A2 source -> IR -> Portable Plan
82bff24  S11A3 Reference VM <-> PZ/Lua structural parity
32a5ffc  S11A4 Dialogue Completeness Analyzer
be87af1  S11A5 domain adapters
452bcaa  S11A6 lifecycle
c2763df  S11A7 dependency/index optimization
28e9a2e  S11A8 foundation-freeze checkpoint
```

Fresh focused verification:

```text
Core S11 foundation unit tests                         23/23 PASS
ProjectHoomans test_automatic_flow_generation.py      9/9 PASS
CodeBuilder reconcile --check                         clean
  desired=407 missing=0 drifted=0 stale=0 ambiguous=0
ConvoEngine integrity/determinism audit               PASS
  familyFilesChecked=577
  legacyNameViolations=0
  deterministic fileCount=404
  diffs=[]
```

These results mean the foundation is useful. Do not discard it merely because later migration gates were falsely closed.

## Finding R1 — Completeness Analyzer coverage is opt-in and can report a false green

The current analyzer correctly checks policy that exists in Portable Plan, but it does not prove that every **required constrained family from S11_BRANCHING_DIALOGUE_AUDIT.md** adopted the canonical policy.

Current canonical CodeBuilder conversation sources containing S11 state/input/repeat/postcondition/closure policy:

```text
count = 1
tools/semantic_harness/codebuilder/sources/conversation/dialogue/core_identity/question_identity.json
```

Therefore a legacy stateful family can remain outside the S11 policy model while the analyzer still reports zero errors.

### Required repair

Create one compiler-visible **constrained-family acceptance manifest/inventory** derived from `S11_BRANCHING_DIALOGUE_AUDIT.md`.

Every maintained row must resolve to exactly one accepted classification:

```text
CANONICAL_STATEFUL
EXPLICIT_PRESENTATION_ONLY
REFERENCE_GOOD_REGRESSION
RETIRED
```

For `CANONICAL_STATEFUL`, the analyzer must fail if the family lacks the required canonical state/input/repeat/closure/effect policy.

For `EXPLICIT_PRESENTATION_ONLY`, require an explicit reason and acceptance owner.

For `REFERENCE_GOOD_REGRESSION`, require regression coverage and prove no missing stateful semantic action was hidden behind this classification.

For `RETIRED`, require caller/reference zero and absence from generated/runtime ownership.

Do not make this a second semantic registry. It is compiler acceptance metadata over canonical family IDs.

## Finding R2 — S11B Identity is behaviorally repaired but structurally incomplete

Canonical Identity source was migrated:

```text
tools/semantic_harness/codebuilder/sources/conversation/dialogue/core_identity/question_identity.json
```

However the old ProjectHoomans semantic flow remains live:

```text
Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Dialogue/Flow_Identity.lua
```

and is still loaded by `FlowCatalog.lua`.

### Required repair

- prove the canonical Identity path owns the semantic behavior intended to replace the old flow;
- migrate any remaining required semantics into canonical CodeBuilder source rather than a wrapper;
- update callers/flow registration;
- prove caller/reference zero for the superseded hand-authored Identity semantic definition;
- delete it in the same accepted repair phase;
- do not leave a forwarding shim.

## Finding R3 — S11C behavior fixes bypassed the required recipe architecture

Behavioral fixes were added directly to hand-written Hoomans runtime/flow Lua:

```text
Dialogue/Input_Actions_Dispatch.lua
Dialogue/Flow_Needs.lua
Dialogue/Flow_Greeting.lua
```

The current companion command pre-admission logic contains family-specific FOLLOW/STAY/RETURN/GO_HOME/CAMP state evaluation directly in `Input_Actions_Dispatch.lua`.

The current Needs/Greeting fixes modify their hand-authored semantic flow definitions in place.

This violates the accepted rule:

```text
canonical CodeBuilder source
-> canonical IR
-> Portable Dialogue Plan
-> generated/runtime projection
```

### Required repair

Recipe-author the semantic policy for:

- maintained companion commands;
- Needs;
- Greeting.

Move semantic state admission out of family-specific runtime dispatch checks where the canonical policy can own it.

Keep `Input_Actions_Dispatch.lua` only as a generic dispatch kernel; it must not be the semantic source of truth for command-specific already-satisfied/blocked rules.

Migrate Needs/Greeting through canonical CodeBuilder source/recipes, prove parity, update callers, prove old definitions have zero callers, and delete superseded semantic flow files.

Do not add compatibility wrappers or fallback readers.

## Finding R4 — S11D was not executed

No implementation phase corresponding to the required full constrained-domain S11D sweep was found before the S11E completion commit.

The branching audit still records unresolved/high-risk work including:

- recruitment transition refresh + repeat typed admission;
- relationship proposal transition refresh + typed parity;
- disband typed confirmation/presentation-only classification;
- ceasefire typed policy and fresh state projection;
- territory typed policy and fresh state projection;
- parameterized task state parity;
- quest offer/accept/status/turn-in lifecycle parity;
- effectful wellbeing/trust/affinity repeat semantics;
- settlement admission/ambient-visit post-success refresh;
- retained gift/event/gossip/departure/social-repair regressions.

### Required repair

Execute the actual S11D inventory to closure.

Do not treat a passing P0 fixture as closure for an entire domain.

Each branching-audit row must receive an explicit final classification in the constrained-family acceptance manifest.

## Finding R5 — two P0 fixtures are weaker than the transition defect they are named after

Current recruitment and relationship-proposal P0 fixtures start from an already-satisfied state and verify zero dispatch.

They do **not** prove:

```text
actionable
-> successful mutation
-> same active conversation refresh
-> stale affordance disappears
-> typed repeat becomes already_satisfied/no-op
```

### Required repair

Add real multi-turn/state-transition fixtures for recruitment and relationship proposal.

Keep the existing already-satisfied admission cases as separate useful tests.

Do not rename a pre-satisfied-state test as proof of post-mutation refresh.

## Finding R6 — prior S11E acceptance is currently false

The prior HANDOFF claimed:

```text
Core full semantic-harness suite 307/307 PASS
```

Fresh audit on current clean HEAD actually produced:

```text
Ran 307 tests
FAILED (failures=1, skipped=2)
```

Failing test:

```text
test_acceptance_runner.AcceptanceRunnerTests.test_fast_subset_of_real_suites_executes_cleanly
```

Underlying current failure:

```text
core_lua:
tests/psychopatz_runtime_role_split_smoke.lua
attempt to index a nil value (local 'f')
```

Do not assume S11 caused this failure. Causation is unproven.

It nevertheless blocks S11E because S11E requires reproducibly green retained acceptance.

## Finding R7 — ROADMAP / PROGRESS / HANDOFF were not reconciled

Before this correction:

- PROGRESS said S11A-S11E COMPLETE;
- HANDOFF said S11E COMPLETE;
- ROADMAP still said S11A ACTIVE and S11B-S11E PENDING.

That is not an accepted closure checkpoint.

## Repair execution order

Follow this order exactly.

### R0 — acceptance-authority repair

1. Preserve the existing S11A foundation.
2. Add the constrained-family acceptance manifest/inventory.
3. Wire the Completeness Analyzer/acceptance tests so required S11 families cannot silently remain outside canonical policy.
4. Add negative tests proving an audited required stateful family without canonical policy fails.
5. Keep reference-good/presentation-only classifications explicit and acceptance-owned.
6. Diagnose and fix or correctly classify the current retained Core Lua acceptance failure.
7. Do not broad-migrate dialogue yet until this guard is green.

### R1 — finish S11B Identity retirement

1. Verify canonical Identity behavior.
2. Move any remaining semantic ownership out of `Flow_Identity.lua`.
3. Update registration/callers.
4. Prove caller-zero.
5. Delete the superseded semantic definition.
6. Reconcile through CodeBuilder recipe; no hand-editing generated output.

### R2 — redo/finish S11C through canonical recipes

1. Recipe-author command state policies.
2. Remove command-specific semantic admission authority from generic dispatch Lua.
3. Recipe-author Needs.
4. Recipe-author Greeting.
5. Prove Reference VM/PZ parity and declarative behavior.
6. Prove old flow caller-zero.
7. Delete superseded Needs/Greeting semantic definitions.
8. No compatibility shims.

### R3 — execute S11D full constrained-domain sweep

Close every maintained row from `S11_BRANCHING_DIALOGUE_AUDIT.md`.

Use canonical source/recipe migrations only where stateful semantic policy is required.

Preserve reference-good domains through explicit regression coverage rather than rewriting them unnecessarily.

### R4 — S11E reproducible closure

Only after R0-R3:

- full Core semantic-harness tests;
- provider declarative fixtures;
- real worker/click/typed/Tk-Xvfb acceptance where required;
- full canonical nine-suite acceptance;
- Completeness Analyzer over the mandatory constrained-family inventory;
- VM/PZ parity;
- CodeBuilder reconcile check;
- deterministic/no-op generation;
- Kahlua verification;
- legacy caller-zero/retirement checks;
- `git diff --check`;
- exact ROADMAP/PROGRESS/HANDOFF reconciliation;
- participant commit vector + residual-work fingerprints;
- adopter phase commits first, Core last;
- no push/publication.

## CodeBuilder / no-shim invariant

Dialogue semantic migrations must be authored through canonical CodeBuilder source/recipes and downstream generation.

Do not solve this repair by adding more family-specific policy to hand-written runtime Lua.

Do not preserve superseded internal semantic definitions through wrappers, aliases, dual registries, fallback readers or dual writes.

External mod compatibility adapters that are genuine public integration surfaces are not automatically legacy shims. Do not delete them merely because a path contains `Compatibility`; verify ownership and external contract first.

## Completion invariant

> S11 is not complete until every audited maintained constrained family is explicitly acceptance-owned, canonical stateful families are compiler-enforced rather than opt-in, Identity/Needs/Greeting/command semantic ownership follows the CodeBuilder recipe path, superseded project-owned flows are caller-zero and removed, the missing S11D sweep is complete, retained acceptance is reproducibly green, and ROADMAP/PROGRESS/HANDOFF describe the same exact checkpoint.
