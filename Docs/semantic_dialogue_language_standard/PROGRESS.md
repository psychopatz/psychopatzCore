# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — S12 ConvoEngine v1 Dynamic Dataset Modernization is active.
**Branch:** existing `main` in all three repositories.
**Active phase:** S12A — ConvoEngine v1 standard freeze and single-authority cleanup.
**Immediate Next Chunk:** S12A1 — unify compact/package authoring onto the one ConvoEngine v1 schema contract before any broad dataset rewrite.
**Content rewrite gate:** `BULK_DIALOGUE_REWRITE_ALLOWED=false` until S12B classification inventory is accepted.

## Current checkpoint

~~~text
psychopatzCore   planning_doc_commit: self (base 37f13c1fa526ce214ca79851328f1a317cff982a)
ProjectHoomans   b5e538fbfe4213c4e45e6e966983ff814f9c71b4
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot at goal creation:

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

## Retained accepted foundation

- R9/R9R1 Semantic Lab authoring UI is compact, health-colored and kind-discoverable.
- One compiler-owned authoring-health report covers the maintained dialogue/behavior/beat/realization catalog.
- Structural health and family-test coverage are separate/truthful.
- Exact declarative/Python/Lua family verification is implemented.
- Behavior/beat/realization kind-aware routing and write safety are implemented.
- Two fresh canonical acceptance runs from one clean exact participant vector passed 9/9 suites with `convoScopeOk=true`.
- CodeBuilder reconcile remained clean.

## Why S12 is required before content modernization

1. Core docs/tooling still carry contradictory pre-release schema identities: the language spec targets `psychopatz.convo-engine.v1` while most compact source/package descriptors still use `psychopatz.psdl.v2` / `psychopatz.psdl.package.v2`.
2. Because the project is unreleased, the target is one ConvoEngine v1 standard; no v2 or permanent compatibility layer is needed.
3. CAMP still exposes a real split conversational authority: `command.camp` owns content/action/replies while `command.companion.camp` owns state/input/repeat/closure policy, joined by runtime action lookup.
4. The maintained dataset needs a machine-readable modernization classification before family-by-family rewriting so agents generalize context into roles/slots/references instead of merely polishing duplicated scripts.
5. Dynamic composition must be a core authoring rule: reusable meaning is authored once; runtime binds live context and composes only validated pieces; realization supplies wording; gameplay authority remains adopter-owned.

## Mandatory sequence

~~~text
S12A  v1 schema/toolchain convergence + CAMP/split-authority cleanup
  ↓
S12B  classify every maintained family
  ↓
S12C  Core dataset modernization
  ↓
S12D  ProjectHoomans dataset modernization
  ↓
S12E  DynamicTrading/DTCommon dataset modernization
  ↓
S12F  exhaustive composition-readiness closure
~~~

Read `DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md` before modifying any dataset family and `S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md` for phase gates.

Do not launch native Project Zomboid, push, publish, reset/stash unrelated work, or hand-edit generated ConvoEngine artifacts.
