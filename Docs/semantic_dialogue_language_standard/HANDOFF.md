# ConvoEngine Handoff

~~~yaml
status: IN_PROGRESS
checkpoint_mode: dirty_resumable
phase: S11A — post-G9 preflight/regression freeze + compiler completeness/memory continuity + participant-agnostic portable facts/effects/modifiers + optimized state-outcome substrate
chunk: S11A0 only — preflight/baseline/legacy ownership inventory; no production semantic migration until S11A8 foundation freeze
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
participant_vector: psychopatz-core=a583dbd246b6d8f6f4ba519462aecae92424a06f;project-hoomans=942ef41304287e6dadc6023a0c2577910cef2408;dynamic-trading=e21387081776e3c8c8e2ba34d419a83441be801f
residual_worktree_fingerprints:
  psychopatz-core: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b  # 0 residual paths; active S11 docs excluded
  project-hoomans: 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b  # clean
  dynamic-trading: ab22639e384c1da211005e25b5af7cdc6fd2222ddf108b71ba4ee3628e7d70d5  # 2 pre-existing generated fingerprint drifts
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
foundation_order_doc: Docs/semantic_dialogue_language_standard/S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md
architecture_doc: Docs/semantic_dialogue_language_standard/S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md
completeness_memory_doc: Docs/semantic_dialogue_language_standard/S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md
portable_facts_effects_doc: Docs/semantic_dialogue_language_standard/S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md
optimization_doc: Docs/semantic_dialogue_language_standard/S11_COMPILER_RUNTIME_OPTIMIZATION.md
emergent_dialogue_foundation_doc: Docs/semantic_dialogue_language_standard/S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md
branching_audit: Docs/semantic_dialogue_language_standard/S11_BRANCHING_DIALOGUE_AUDIT.md
evidence: POST_G9_ARCH_REAUDIT; P0_DEFECTS_REPRODUCED; CORE_G8_G9_13_OF_13; HOOMANS_FOCUSED_15_OF_15; DT_GENERATION_DRIFT_2; PORTABLE_FACT_EFFECT_MODIFIER_DESIGN_APPROVED; COMPILER_RUNTIME_OPTIMIZATION_DESIGN_APPROVED; LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION_APPROVED
updated_at: 2026-11-18
~~~

## Current truth

S11 implementation has not started. G7-G9 changed the correct integration seam but did not repair the S11 behavior defects.

Fresh production-worker evidence on current HEAD reproduces known identity first-contact leakage/reward farming/stale choices, repeated or busy companion-command dispatch, Needs proposal self-loop, hostile greeting plus friendly follow-up, stale recruitment, and stale relationship proposal.

Focused structural baseline remains healthy: Core G8/G9 production/backend/decomposition tests 13/13 PASS; Hoomans focused stateful/flow/proposal tests 15/15 PASS. Those suites do not currently cover the reproduced S11 defects.

## Accepted post-G9 architecture

Production semantic authority is compact ConvoEngine/PSDL source → Canonical Semantic Dialogue IR → Portable Dialogue Plan → descriptor-selected backend/generated runtime → typed capability/ActionContract adapter → authoritative gameplay/domain state.

The previous runtime-descriptor-first S11 design is superseded. State/input/repeat/postcondition policy must be authored canonically and carried through Portable Plan.

SemanticOutcome is a normalized data contract spanning pre-admission state classification and existing ActionContract result lifecycle, not a second execution registry/runtime.

CapabilityCatalog/Semantic Lab exposes compiled policy; it does not own it. CandidateEligibility remains parser/context safety.

## Immediate Next Chunk

Execute **S11A0 only**.

1. Re-read all three current HEAD/status values and preserve unrelated work.
2. Close or explicitly baseline the two pre-existing DTCommon generated fingerprint drifts.
3. Freeze the known P0 behavior as provider-owned declarative fixtures and correct tests that currently bless duplicate FOLLOW dispatch or unbounded Needs pending state.
4. Record current compile/runtime/save-size baselines before optimization.
5. Inventory relevant existing semantic/runtime surfaces and classify each as KEEP_AUTHORITY / ADAPT / MIGRATE_LATER / RETIRE_AFTER_PARITY / GENERATED_DO_NOT_EDIT / UNRELATED.
6. Record existing scheduler/cache/index/inventory/relationship/mood/memory/ActionContract/CodeBuilder ownership to prevent duplicate systems.
7. Do not implement the new production semantic model yet and do not migrate any production dialogue family in S11A0.

After S11A0 is accepted, continue strictly through S11A1→S11A8 from `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`. Production migration remains forbidden until the S11A8 freeze gate passes.

All later dialogue/semantic migrations must be authored in canonical CodeBuilder source/recipe inputs and regenerated downstream through `tools/semantic_harness/codebuilder/generation_recipe.json` using recipe-driven reconcile. Do not hand-edit recipe-owned generated Lua/registries/manifests/translations.

Migration is replacement, not compatibility layering: project-owned obsolete semantic paths must be removed after parity and caller-zero proof. Do not leave forwarding wrappers, fallback readers, dual registries/writes, legacy aliases or parallel old/new semantic authorities.

Do not persist transcript summaries or keep live flow state open merely to simulate memory.

Do not start by adding statePolicy only to hand-written PNC Lua descriptors. Do not create a second state/action/outcome/memory registry, relationship/mood/inventory mini-DSL, duplicate timed-modifier engine, compatibility shim, fallback legacy reader, or dual old/new semantic path.

## Testing authority

Behavioral S11 acceptance should primarily use tools/providers/pnc/fixtures/v1/. Imperative tests remain for compiler/schema, Portable Plan/Reference VM, backend projection/parity, ActionContract lifecycle, GUI/protocol/static/performance responsibilities. Preserve valid first-contact identity fixtures.

## Boundaries

PsychopatzCore owns portable language/IR/Portable Plan/runtime mechanisms, generic predicates, ActionContract/result normalization, compiler validation and backend parity infrastructure.

ProjectHoomans owns Hoomans canonical semantic programs, projected gameplay facts, gameplay adapters/authority, effects and domain response content.

DynamicTrading/DTCommon is a mandatory portability participant. Do not hard-code PNC assumptions into Core. Generated artifacts are downstream; do not hand-edit generated Lua as S11 source.

Do not reset, stash, discard, broad-stage, push, publish, amend, rebase, force-update, or launch native Project Zomboid.

## Acceptance for S11A

S11A requires accepted S11A0-S11A8 in the authoritative order; executable P0 regressions; a frozen generic canonical model before analyzer construction; canonical source→IR→Portable Plan→Reference VM/PZ structural parity; compiler-proven reachability/closure/progress and continuation obligations over the final model; direct adapters to existing domain authorities; stable memory/modifier lifecycle; stable compact definitions/dependency indexes; bounded optimized runtime/persistence; measured performance/save-size budgets; deterministic recipe-driven generation; zero-LLM semantic correctness; no production semantic-family migration before S11A8; and no runtime-only/parallel semantic authority, compatibility shim, fallback legacy path or duplicate old/new implementation.

The parent completion boundary remains S11A-S11E.
