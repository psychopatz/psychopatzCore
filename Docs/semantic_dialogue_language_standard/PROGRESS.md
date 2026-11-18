# Progress — ConvoEngine / Semantic Harness

**Status:** REOPENED — S12 implementation is stable but structural dataset modernization is incomplete.
**Branch:** existing `main` in all three repositories.
**Active phase:** S12R1 — Structural Dataset Modernization Closure Repair.
**Immediate Next Chunk:** S12R1A — make the live modernization inventory a real closure authority with OPEN / RESOLVED / INTENTIONALLY_RETAINED resolution states.
**Content rewrite gate:** classified structural repair is allowed; S12 may not return to COMPLETE until S12R1D passes.

## Current checkpoint

~~~text
psychopatzCore
bfb10f0a60ac611fc7902bfa46df45179eeba605

ProjectHoomans
ebbf113d5acbaf505f2c157d9c0a24454ba212b7

DynamicTrading
2b0c3cb5b2371aff1a5837361f44916fda59d081
~~~

Audit-close residual fingerprints for all three repositories:

~~~text
rows=0
sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

## Accepted and retained

- canonical maintained conversation/package sources use ConvoEngine v1;
- `command.camp` is the single CAMP conversation authority;
- split-action authority audit is green;
- Semantic Lab health scopes are explicit;
- machine-readable modernization inventory covers all 587 maintained families;
- useful S12 roles/slots/topic/event/activity/memory/domain metadata additions remain;
- CodeBuilder generation/reconcile remains deterministic and clean;
- current runtime/provider/GUI acceptance is stable.

Fresh audit acceptance from the exact vector above, twice:

~~~text
9/9 suites
2145/2174 cases
4 known unrelated Hoomans Lua baseline failures
25 allowed skips
0 unclassified skips
convoScopeOk=true
~~~

Fresh generation evidence:

~~~text
family files: 587
deterministic generated files: 408
integrity violations: 0
split-authority violations: 0
determinism diffs: 0

reconcile desired: 411
missing/drifted/stale/retired_present/ambiguous: 0
~~~

## Why S12 is reopened

The accepted inventory still reports structural work after the claimed S12C-E modernization:

~~~text
duplicateGroupCount         30

CONTEXT_VARIANT            140
REALIZATION_ONLY           126
REDUNDANT_SPECIALIZATION    44
SLOT_PARAMETERIZABLE        33
ARCHETYPE_MEMBER            30
BEAT_COMPONENT               3
~~~

Representative live recommendations still include:

~~~text
parameterize_context_or_predicate_variants
merge_into_single_family_realization_variants
collapse_into_slot_parameterized_family
preserve_and_expose_director_hooks_and_roles
~~~

S12C-E mostly enriched existing families with generic roles/slots/hooks while
leaving many recommended specialization/realization/context families intact.
The previous S12F gate verified classification coverage, ordinary tests,
integrity and determinism, but did not require the actionable modernization
backlog to be resolved.

Core also still maintains active legacy-schema/PSDL compatibility surfaces
(legacy supported-schema/read flags and PSDL-named implementation modules).
Because the project is unreleased, S12R1 must finish the direct ConvoEngine-v1
migration rather than retain a permanent compatibility path.

## Mandatory repair sequence

~~~text
S12R1A  closure-authority hardening
  ↓
S12R1B  retire active legacy schema/compiler compatibility
  ↓
S12R1C1 Core structural dataset groups
  ↓
S12R1C2 ProjectHoomans structural dataset groups
  ↓
S12R1C3 DTCommon structural dataset groups
  ↓
S12R1C4 behavior/beat composition-readiness sweep
  ↓
S12R1D reproducible final closure
~~~

Normative repair:
`S12R1_STRUCTURAL_DATASET_MODERNIZATION_CLOSURE_REPAIR.md`

Authoring standard:
`DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md`

Do not launch native Project Zomboid, push, publish, reset/stash unrelated work,
or hand-edit generated ConvoEngine artifacts.
