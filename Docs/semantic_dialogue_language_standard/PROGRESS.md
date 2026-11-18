# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — R1 accepted (`Flow_Identity.lua` retired with caller-zero; canonical CodeBuilder `Flows/Semantic/Identity.lua` owns Identity flow); advancing to R2.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11 repair — R2 redo/finish S11C (companion commands + Needs + Greeting) through canonical CodeBuilder recipes.
**Immediate Next Chunk:** R2 — recipe-author companion command state policies (`FOLLOW`/`STAY`/`CAMP`/`RETURN_HOME`), remove family-specific semantic admission from `Input_Actions_Dispatch.lua`, recipe-author Needs and Greeting flows, regenerate via `reconcile.py`, prove parity + caller-zero, and delete `Flow_Needs.lua` and `Flow_Greeting.lua`.

## Current audited checkpoint

Audit-start commits before this documentation correction:

~~~text
psychopatzCore   3f8b933f2545a5e5f2e6b897555c86eee96b2d31
ProjectHoomans   35d1a6bc6b26a0515c2dd19247c3adbc4b4e5d3e
DynamicTrading   503d13037fbc51c66ad42c81191c8b91d1fd4da2
~~~

All three worktrees were clean at audit start.

Normative repair plan:

`Docs/semantic_dialogue_language_standard/S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md`

Authoritative foundation/migration order:

`Docs/semantic_dialogue_language_standard/S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`

## Verified truths to retain

- S11A0-A8 produced real foundation code in the intended order; do not rebuild it from scratch.
- Fresh focused S11 foundation tests: **23/23 PASS**.
- ProjectHoomans `test_automatic_flow_generation.py`: **9/9 PASS**.
- CodeBuilder recipe reconciliation: **clean**, `desired=407`, `missing=0`, `drifted=0`, `stale=0`, `ambiguous=0`.
- ConvoEngine integrity/determinism: **PASS**, `577` family files, `0` legacy-name violations, `404` deterministic files, `0` diffs.
- Canonical Identity source contains S11 state/input/repeat/postcondition/closure metadata.

## Reopened defects

- Completeness currently validates policy that exists but does not prove every constrained family from the branching audit adopted canonical policy. Only one current canonical dialogue source carries the new S11 policy metadata.
- `Flow_Identity.lua` remains live through `FlowCatalog.lua`; S11B behavior is repaired but caller-zero/retirement is incomplete.
- S11C command state admission was patched directly in `Input_Actions_Dispatch.lua`; Needs/Greeting were patched directly in `Flow_Needs.lua` / `Flow_Greeting.lua`. This violates recipe-only semantic migration.
- `Flow_Needs.lua` and `Flow_Greeting.lua` remain live; superseded semantic ownership was not retired.
- No implementation phase corresponding to the mandatory S11D full constrained-domain sweep was found before the S11E completion claim.
- Recruitment and relationship-proposal P0 cases prove pre-satisfied no-op admission but do not prove actionable -> successful mutation -> same-conversation refresh -> repeat no-op.
- Fresh full Core semantic-harness is **not green**: 307 tests ran with 1 failure and 2 skips. Current failure is `test_fast_subset_of_real_suites_executes_cleanly` because `tests/psychopatz_runtime_role_split_smoke.lua` crashes on a nil local. S11 causation is unproven, but retained acceptance is not reproducibly green.
- Prior PROGRESS/HANDOFF completion claims contradicted ROADMAP and are revoked.

## Mandatory repair sequence

~~~text
R0  acceptance-authority repair
    constrained-family manifest + analyzer/acceptance enforcement
    diagnose current retained Core acceptance failure
      ↓
R1  finish S11B Identity retirement
    canonical parity -> caller-zero -> delete superseded Flow_Identity
      ↓
R2  redo/finish S11C via canonical CodeBuilder recipes
    commands + Needs + Greeting
    remove family-specific semantic authority from hand-written runtime Lua
    caller-zero -> delete superseded flows
      ↓
R3  execute actual S11D full constrained-domain sweep
      ↓
R4  rerun S11E reproducible closure
    exact docs + participant vector + residual fingerprints
~~~

Do not return to USER_ACCEPTANCE until R0-R4 and the original S11 completion gate pass.

## Hard rules

- Canonical source/CodeBuilder recipe first; generated output is downstream-only.
- No compatibility shims, fallback readers, dual registries/writes, or permanent old/new semantic paths for project-owned internal code.
- Generic runtime kernels must not become family-specific semantic authorities.
- Reference-good domains should be regression-protected, not rewritten unnecessarily.
- Semantic correctness must require zero LLM calls.
- Do not implement the future autonomous Dialogue Director during this repair.
- Accepted multi-repo phases commit adopters first and Core last; never push/publish without explicit authorization.
