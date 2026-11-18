# ConvoEngine Handoff

~~~yaml
status: IN_PROGRESS
checkpoint_mode: committed_handoff
phase_commit: self
phase: S12 — ConvoEngine v1 Dynamic Dataset Modernization
chunk: S12A1 — one ConvoEngine v1 source/package schema
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md
authoring_standard: Docs/semantic_dialogue_language_standard/DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md
bulk_dialogue_rewrite_allowed: false
updated_at: 2026-11-19
~~~

## Participant checkpoint

~~~text
psychopatzCore   planning_doc_commit: self (base 37f13c1fa526ce214ca79851328f1a317cff982a)
ProjectHoomans   b5e538fbfe4213c4e45e6e966983ff814f9c71b4
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
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

## Immediate Next Chunk — S12A1

1. Reverify all participant HEAD/status.
2. Read the two S12 normative documents.
3. Audit every compiler/service/package/source dependency on `COMPACT_PSDL_SCHEMA` and `PACKAGE_DESCRIPTOR_SCHEMA`.
4. Design one direct pre-release migration to ConvoEngine v1 that preserves compact profiles/defaults/sidecars without a compatibility shim.
5. Implement/migrate through CodeBuilder tooling, not raw mass source writes.
6. Prove all first-party family/package sources use the v1 ConvoEngine schemas.
7. Remove obsolete PSDL schema read/alias paths after caller/source zero.
8. Continue automatically through S12A2 CAMP single-family authority, S12A3 duplicate-authority audit and S12A4 health-scope clarity.
9. Close S12A with full focused + canonical acceptance before starting S12B.

Do not begin S12C-E broad dataset rewriting during S12A.

Do not push, publish Workshop content, or launch native Project Zomboid without explicit authorization.
