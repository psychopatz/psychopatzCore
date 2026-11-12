# Agent Runbook — Psychopatz Semantic Dialogue Language Standard

## Startup

This is a **mandatory three-repository goal**. Do not narrow it to two repositories.

Primary/owning repository for PSDL itself and for this job's durable documentation:

```text
/home/psychopatz/Zomboid/Workshop/psychopatzCore
```

Mandatory adopter repositories:

```text
/home/psychopatz/Zomboid/Workshop/ProjectHoomans
/home/psychopatz/Zomboid/Workshop/DynamicTrading
```

All three are in scope from S0 through S8. DynamicTrading/DTCommon is not optional future work. Additional repositories may enter scope only when current source evidence proves they are also required.

Before editing any repository:

1. read its root `AGENTS.md`;
2. inspect branch/HEAD/upstream/worktrees/current dirty state;
3. preserve unrelated staged/unstaged/untracked work;
4. derive current work/content roots from the filesystem;
5. use Codebase Memory when available, but treat current dirty source as truth.

For this job read `PROGRESS.md` first, then current `HANDOFF.md`, then only the active ROADMAP/ARCHITECTURE/LANGUAGE_SPEC/NAMING_AND_LAYOUT sections needed.

## Core ownership discipline

The reusable PSDL mechanism belongs in PsychopatzCore. Implement the language schema, canonical IR, compiler/normalizer, generic validation, generic predicate/reference/slot/binding contracts and shared authoring service in Core.

ProjectHoomans and DynamicTrading/DTCommon may contain only adopter-specific PSDL records, adapters, tests and gameplay/domain constraints. Do not copy the compiler, predicate engine, schema or generic runtime into an adopter merely because that adopter currently owns legacy dialogue source.

When a reusable mechanism is needed by more than one adopter, move/implement it in Core and expose a public seam. Keep product-specific gameplay authority in its adopter.

## Authority discipline

Do not build another runtime stack.

Prefer adapting/generating into accepted authorities:

- Core semantic NLU;
- shared semantic predicates;
- ResponsePlan;
- BranchOffers / affordance frontier;
- Interaction Director;
- Scene Runtime / Social Conversation;
- SpeechRealization/translation;
- existing gameplay/domain authorities.

If a missing capability is discovered, prove it with source/tests before changing an accepted subsystem.

## PSDL source discipline

New first-party semantic dialogue content is authored only in the PSDL standard once its compiler phase is available.

During migration:

- existing old source may be read and converted;
- do not add new production features to old authoring just because conversion is unfinished;
- do not make checked-in migration copies under `Legacy`, `Compat`, `Old`, `V1`, `Migrated`, `PartNN` or similar;
- do not maintain both old and PSDL definitions after a domain is accepted;
- do not hand-edit generated output.

A bounded compiler migration reader is acceptable when unavoidable, but must have a removal gate and must not become an authoring API.

## Naming/layout discipline

Follow `NAMING_AND_LAYOUT.md`.

Canonical IDs describe semantic meaning. Physical shard path and generated module path are provenance.

Do not encode implementation history in stable IDs.

Do not create numeric shard overflow files; split by semantic ownership instead.

## Actor neutrality

Generic source uses:

```text
speaker
addressee
target
participants
slot.*
reference.*
```

Do not add new reusable player/NPC-specific variables or branches when the distinction can be represented through participant type/role/context predicates.

Player/NPC-specific gameplay restrictions may remain domain constraints, but not separate generic dialogue engines.

## Predicate discipline

All PSDL contextual eligibility uses the shared predicate contract.

Do not introduce trait-specific/gender-specific/relationship-specific mini evaluators.

Extend generic predicate/context projection only when the required capability is reusable and bounded.

Private/undiscovered data must fail closed.

## Beat discipline

Beats are optional orchestration.

- Simple dialogue does not require a beat.
- Beats reference behaviors, not phrase files.
- Behaviors own strategy, not mutable gameplay state.
- Wording/realization remains separate.
- Do not nest beats into scripted trees when semantic entry/maintain/exit arbitration can express the transition.
- Preserve Interaction Director as the only beat/behavior arbitration authority.

## Fuzzy-resolution discipline

PSDL does not implement fuzzy algorithms.

Core semantic/entity/item/world resolvers remain responsible for matching and confidence.

Authoring may declare semantic policy such as exact/safe/confirm only when the runtime contract supports it.

Never weaken the existing rule that fuzzy/recovered mutating actions require exactness/confirmation/authority.

## Translation discipline

EN is required fallback.

Additional locales are ordinary data.

Do not hard-code TL or any other optional locale into compiler control flow.

Validate placeholder parity and binding availability.

## Migration procedure

For each semantic domain in **all three repositories**:

1. inventory canonical old source, generated outputs and real callers;
2. freeze focused behavioral fixtures;
3. create final PSDL source and final semantic IDs;
4. compile/regenerate;
5. run focused compiler/runtime tests;
6. run player/NPC semantic affordance parity where applicable;
7. validate locale placeholders;
8. prove superseded caller/reference count is zero;
9. delete superseded first-party source;
10. run broader acceptance;
11. reconcile docs/HANDOFF;
12. commit the accepted phase/slice locally.

Do not keep old source “just in case”; Git history is the archive.

## Completion-audit discipline

Do not equate compiler support with catalog migration or service APIs with GUI acceptance.

Before closing S4-S8:

- enumerate surviving pre-PSDL Conversation sources and classify them explicitly;
- a file containing maintained dialogue wording, response pools, semantic offers, beat/behavior/realization authoring, or node/choice/outcome source structure is not “mechanism” merely because it lives under Core tooling;
- recognition-only patterns or explicit compatibility data may remain only with an evidence-backed non-authoring classification;
- do not restore deleted legacy source/translations to satisfy stale tests; update tests to the canonical PSDL/generated/runtime seam;
- source/audit inventories must ignore `__pycache__`, `.pyc`, cache/temp files, editor backups, and equivalent non-source noise;
- a phase cannot be CLEAN_CHECKPOINT while phase-owned normative docs or adopter pointers remain untracked/unstaged;
- S7 requires the user-facing PSDL-native Semantic Lab/editor workflow, not only Python CRUD/service methods.

Generated-output size/file count is not itself a failure, but S6 must measure it and justify retained fan-out. Reduce semantically redundant per-record output when safe without violating package boundaries, deterministic generation, or Project Zomboid/Build 42 Lua limits.

## Validation

Minimum per relevant phase:

- `git diff --check`;
- focused Python compiler/authoring tests;
- focused Lua semantic/dialogue/scene/director tests;
- PSDL schema/validation tests;
- deterministic two-pass generation;
- source/audit no-new-legacy guard;
- Kahlua/static verification when available;
- full isolated Lua suite for runtime/generated changes;
- Semantic Harness worker fixtures for changed behavior;
- EN + optional-locale placeholder/source consistency;
- source/save immutability where applicable.

S8 additionally runs the exhaustive participant/constraint/offer/beat matrix from ROADMAP.

Do not weaken assertions or inflate limits/timeouts merely to make migration pass.

## Git and phase close

No new branches.

At every accepted phase:

1. reconcile exact phase-owned changes in all three repositories;
2. stage only those paths;
3. commit changed adopter repositories (`ProjectHoomans`, `DynamicTrading`) first;
4. update this Core-owned PROGRESS/HANDOFF;
5. commit `psychopatzCore` last;
6. verify the three-repository commit vector and residual dirty work;
7. continue to the next mandatory phase.

Do not push, PR, tag, release, rebase, amend or force-update without explicit authorization.

## Stop policy

A bounded chunk is not the completion boundary.

Continue mandatory phases automatically after acceptance.

Stop only for a genuine blocker/ownership conflict or after all developer work is complete and only user-owned native acceptance remains.
