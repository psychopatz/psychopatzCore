# ConvoEngine Handoff

~~~yaml
status: IN_PROGRESS
checkpoint_mode: committed_handoff
phase_commit: self
phase: S12 — ConvoEngine v1 Dynamic Dataset Modernization
chunk: S12B — machine-readable dataset modernization inventory
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md
authoring_standard: Docs/semantic_dialogue_language_standard/DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md
bulk_dialogue_rewrite_allowed: false
updated_at: 2026-11-19
~~~

## Participant checkpoint

~~~text
psychopatzCore   S12A commit: self (base d40384c3d1ac7b074d34ce45a0a8b602cc1dd45e)
ProjectHoomans   5039b405
DynamicTrading   f9c8e60f
~~~

All three worktrees were clean at goal creation.

Residual fingerprints:

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

## Retain

- accepted S11 state/outcome, completeness, memory, facts/effects/modifier and compiler/runtime foundations;
- R9/R9R1 Semantic Lab authoring/readability/test-verification improvements;
- one compiler-owned health/completeness authority;
- current CodeBuilder authoring/reconcile workflow;
- existing adopter gameplay/domain authority.

## Active decisions

- Public/system/language name is ConvoEngine.
- Pre-release first-party family/source schema is `psychopatz.convo-engine.v1`.
- Pre-release first-party package schema is `psychopatz.convo-engine.package.v1`.
- Do not create ConvoEngine v2 during this modernization.
- `psychopatz.psdl.v2` / `psychopatz.psdl.package.v2` are migration residue to remove after source/caller zero.
- Compact authoring remains compact under v1; normalized IR is a compiler stage, not a second authoring schema.
- One semantic interaction has one canonical family conversational authority.
- Runtime binds live roles/slots/typed references and may compose validated families/beats; it may not invent semantic/gameplay authority.
- Wording-only differences belong in realization.
- Broad source modernization begins only after S12B classifies every maintained family.

## Immediate Next Chunk — S12B

1. Build machine-readable dataset modernization inventory (`convo_engine_modernization_inventory.py`) through Core tooling.
2. Classify all 587 maintained families with roles, slots, typed ref hooks, state/mutation/execute/repeat/closure/coverage metadata, and duplicate/specialization groups.
3. Verify S12B gate (`catalog count == inventory count`, zero unknown ownership, zero unclassified families).
4. Continue automatically to S12C-E classified batch modernization and S12F closure.

Do not begin S12C-E broad dataset rewriting during S12A.

Do not push, publish Workshop content, or launch native Project Zomboid without explicit authorization.
