# Agent Runbook — ConvoEngine

## Startup

This is a **mandatory three-repository goal**. Do not narrow it to two repositories.

Primary/owning repository for ConvoEngine itself and for this job's durable documentation:

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

For this job read `PROGRESS.md` first, then current `HANDOFF.md`, then `CONVO_ENGINE.md`. Read only the one deeper ROADMAP/ARCHITECTURE/LANGUAGE_SPEC/CHAINING/ACTIONS/NAMING section required by the active chunk plus exact source/tests. Do not force a Luna-class agent to ingest every ConvoEngine document on startup.

## Core ownership discipline

The reusable ConvoEngine mechanism belongs in PsychopatzCore. Implement the conversation schema, canonical IR, compiler/normalizer, generic validation, generic predicate/reference/slot/binding contracts, registered Semantic Action Contract/result mechanism, and shared CodeBuilder authoring service in Core. The pre-release first-party schema target is `psychopatz.convo-engine.v1` with `psychopatz.convo-engine.package.v1`; `PSDL`/`psychopatz.psdl.*` identifiers are migration residue to delete after S12 source/caller zero, not a parallel supported authoring path.

ProjectHoomans and DynamicTrading/DTCommon may contain only adopter-specific ConvoEngine conversation records, adapters, tests and gameplay/domain constraints. Do not copy the compiler, predicate engine, schema or generic runtime into an adopter merely because that adopter currently owns legacy dialogue source.

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

### S11 state/outcome discipline

For stateful semantic behavior, read S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md first, then S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md, S11_DIALOGUE_COMPLETENESS_MEMORY_CONTINUITY.md, S11_PORTABLE_FACTS_EFFECTS_MODIFIERS.md, S11_COMPILER_RUNTIME_OPTIMIZATION.md, S11_LLM_MINIMIZED_EMERGENT_DIALOGUE_FOUNDATION.md, and S11_BRANCHING_DIALOGUE_AUDIT.md before implementation.

S11 extends the accepted post-G9 ConvoEngine pipeline:

- author state/input/repeat/postcondition policy in compact ConvoEngine/PSDL source;
- normalize it through Canonical Semantic Dialogue IR and Portable Dialogue Plan;
- reuse the existing canonical predicate AST / PsychopatzSemanticPredicate;
- evaluate one portable pre-admission outcome for buttons, typed input and flow entry;
- short-circuit no_op / reject / confirm / defer before gameplay dispatch;
- use existing ActionContract.Execute plus adopter capability adapter for mutation;
- use existing ActionContract.ProjectResult/outcome mapping for authoritative post-dispatch results;
- rebuild state-sensitive affordances from fresh authority after state changes;
- expose compiled policy through existing catalog/Semantic Lab diagnostics rather than authoring it there;
- carry repeat semantics through existing dialogue history/repeat machinery;
- keep CandidateEligibility limited to parser/context candidate safety;
- derive one compiler conversation graph from canonical IR/Portable Plan for reachability, completeness, cycle/progress, obligation, closure and memory-residue diagnostics;
- let CodeBuilder/Semantic Lab consume that compiler report rather than reimplement graph analysis;
- close conversation-local flow state when semantically done while transferring any real-world promise/task into existing domain authority and compact same-day ConversationMemory episode references;
- never use raw transcript summaries or stale live flow state as the canonical one-day memory;
- normalize actor/target fact queries, inventory constraints, relationship/mood predicates, typed effects, duration literals, stacking and reusable presets into canonical IR/Portable Plan before backend generation;
- keep `when` predicates read-only; use existing ActionContract/domain adapters for mutation;
- use one generic modifier lifecycle/retention model for timed buffs/debuffs and require adopter domain schemas for allowed fields/ranges/roles/authority;
- keep semantic memory and active modifiers distinct even when one episode creates both;
- reject opaque provider callbacks or raw persistence-path predicates that make completeness/backend parity blind;
- prefer compile-time normalization/analysis over runtime discovery; generated runtime consumes compact definitions and indexes;
- compile family required-fact metadata and invalidate semantic projections by authoritative fact changes; retain a safe full-rebuild fallback until parity is proven;
- never optimize by creating a shadow inventory/relationship/mood store;
- use stable compiled IDs for compact runtime/persistence only when source IDs remain recoverable and migration-safe;
- use bounded game-time scheduling for timed memory/modifier expiry and definition-driven dedupe/aggregation for repeatable instances;
- keep presets/macros compile-time only and detailed decision traces opt-in;
- measure compile/runtime/save-size baselines before establishing hard performance thresholds; correctness gates remain higher priority than speed;
- model scenes as bounded ParticipantSets plus dynamically bound semantic roles/cardinality, not participant-number-specific dialogue variants;
- keep two-person dialogue as a specialization of the generic participant/role model;
- preserve structured TopicRef/EventRef/ActivityRef/MemoryRef-compatible metadata and discoverable semantic act/archetype metadata for a future Dialogue Director;
- keep realization separate from semantic meaning so authored/templates can function without an LLM;
- do not implement autonomous beat/topic scoring in S11; only establish the typed metadata and bounded compiler/runtime seams;
- semantic correctness and gameplay authority must require zero LLM calls;
- obey the S11A0→S11A8 foundation order and do not migrate production semantic families before the S11A8 freeze gate;
- classify legacy surfaces before editing them as KEEP_AUTHORITY / ADAPT / MIGRATE_LATER / RETIRE_AFTER_PARITY / GENERATED_DO_NOT_EDIT / UNRELATED;
- do not add compatibility shims, fallback readers, dual registries, dual writes, forwarding wrappers, or parallel old/new semantic paths for project-owned internal code; migrate callers and delete obsolete code after parity/caller-zero proof;
- author migrated dialogue/semantic logic in canonical CodeBuilder source/recipes and use the shared authoring/migration service; run generation through `tools/semantic_harness/codebuilder/generation_recipe.json` and recipe-driven reconcile; generated Lua/registries/manifests/translations are downstream-only and must not be hand-edited;
- for bulk dialogue migrations, read canonical compact source plus compiler/recipe evidence rather than repeatedly reading generated downstream copies.
- treat `S11_BRANCHING_DIALOGUE_AUDIT.md` plus the compiler-visible constrained-family inventory/manifest as mandatory **closed-set** acceptance coverage; missing audit rows and extra unowned manifest rows fail acceptance;
- accepted constrained-family classifications are `CANONICAL_STATEFUL`, `EXPLICIT_PRESENTATION_ONLY`, `REFERENCE_GOOD_REGRESSION`, or `RETIRED`, each with machine-verifiable acceptance ownership;
- an `acceptanceOwner` path/string alone is not evidence: the exact referenced test/fixture/case must explicitly declare its stable audit claim IDs; manifest repetition, `claimKeywords`, substring matching, test-name similarity, or whole-file source-text scans are not semantic ownership proof; keep claims atomic by observable surface so one sibling behavior cannot certify another untested sibling;
- production/native presentation claims require native or native-equivalent context parity: a worker-only field or worker-only authority projection cannot certify an in-game behavior unless the native `Contents/` path produces the same bounded contract;
- canonical acceptance must remain hermetic under supported parallel execution: tests that mutate canonical source use isolated temp roots, and GUI/display-dependent tests have one explicit deterministic suite owner rather than order-dependent skips;
- for the reopened S12 goal, follow `PROGRESS.md` / `HANDOFF.md` and `S12R1_STRUCTURAL_DATASET_MODERNIZATION_CLOSURE_REPAIR.md`: classified structural repair is allowed, but every actionable inventory finding must become RESOLVED or INTENTIONALLY_RETAINED with machine-checkable justification before final closure; blind prose replacement remains forbidden;
- Semantic Lab completeness UI must consume the canonical `analyze_convo_completeness()` report; do not reimplement termination/cycle/outcome/closure reasoning in Tk;
- completeness diagnostics and scaffolds must navigate/write canonical compact source through existing services; generated Lua/registry/manifest/translation remains downstream-only;
- authoring-health UI must cover every maintained canonical family kind that is in rewrite scope; kind-specific health checks may differ, but source-catalog inventory and Workbench inventory must not silently diverge;
- Workbench and primary Conversations editor must share one synchronized current-family identity; a health report for a different family than the visible editor is an acceptance failure;
- problem-first authoring is the default: real Tk semantic tags/styles plus textual health labels, severity-first sorting, and contextual repairs only when a diagnostic applies;
- retire project-owned legacy UI after parity and caller-zero rather than preserving hidden compatibility panes or shims; preserve useful current capabilities by moving/renaming them before deleting obsolete containers;

- review family-specific semantic checks or canonical reply mappings added to generic hand-written runtime kernels as architecture defects when the policy/reply already belongs in canonical source/Portable Plan; canonical action-policy admission must use one generic path before domain-specific mutation routing;
- use `S11_POST_R9_WORKBENCH_USABILITY_REPAIR.md` when resuming current S11 work; `S11_POST_R8_AUTHORING_READINESS_REPAIR.md` is the retained R8D/R9 implementation plan; `S11_POST_R6_CLOSURE_AUDIT_REPAIR.md` is historical R7 context, `S11_POST_R5_FINAL_CLOSURE_REPAIR.md` is historical R6 context, and earlier repair docs are historical.

Behavioral regressions belong primarily in provider-owned declarative fixtures under tools/providers/<provider>/fixtures/. Keep imperative tests for compiler/schema, Portable Plan/Reference VM, backend parity, ActionContract lifecycle, GUI/protocol/static/performance responsibilities.

For S11, Reference VM and PZ/Lua backend must agree on matched state rule, outcome, reason, admission and reply outcome for the same canonical family plus projected state.

Do not create a StatefulDialogueRegistry, second action catalog, second predicate DSL, relationship/mood/inventory mini-DSL that bypasses canonical normalization, separate button-state evaluator, separate typed-input state evaluator, separate cooldown/modifier engine, persistent semantic shadow state, semantic shadow inventory/cache without authoritative invalidation ownership, runtime preset-expansion system, participant-count-specific dialogue copies where role binding would suffice, autonomous S11 Dialogue Director/scorer, LLM-required semantic authority, compatibility shim/fallback/dual-path for migrated internal semantic code, or hand-written/generated runtime descriptor that becomes a second semantic authoring authority.

At review, search for duplicated domain-state predicates and policy fields present only in generated/adopter Lua but absent from canonical source/Portable Plan. Either defect fails S11 even if focused behavior tests are green.

## S12 dynamic dataset modernization discipline

Before modifying maintained conversation dataset source for S12, read
`DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md` and
`S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md`.

For every family:

- identify stable semantic meaning before editing wording;
- classify the family using the S12 modernization classes;
- prefer typed roles/slots/references over hard-coded context duplicates;
- prefer realization variants over wording-only semantic duplicates;
- prefer bounded beats/archetypes over monolithic contextual scripts;
- require one family to own the full conversational policy for one semantic action;
- keep gameplay truth/mutation behind adopter ActionContract/capability authority;
- let runtime bind/select/compose only compiler-valid pieces;
- never require an LLM for semantic correctness;
- use CodeBuilder authoring/migration APIs for dataset changes and delete superseded source after parity/caller-zero.

Do not start broad S12C-E dataset rewriting before S12A ConvoEngine-v1/single-authority cleanup and S12B machine-readable classification inventory are accepted.

## ConvoEngine / CodeBuilder authoring discipline

New first-party conversation content is authored only through the Core CodeBuilder ConvoEngine authoring/migration path once that API is available.

Agents must not bulk-create, shard, rename, or rewrite canonical conversation JSON with raw filesystem writes when the CodeBuilder authoring/migration service can own the operation. The allowed content workflow is: preview/validate through CodeBuilder → write canonical source through CodeBuilder → rebuild through CodeBuilder → validate generated artifacts. Direct edits are reserved for CodeBuilder/compiler/tests/docs themselves or for a narrowly justified bootstrap before the authoring API exists.

Generated runtime Lua/JSON/translation/index files are never hand-authored or manually moved.

During migration:

- existing old source may be read and converted;
- do not add new production features to old authoring just because conversion is unfinished;
- do not make checked-in migration copies under `Legacy`, `Compat`, `Old`, `V1`, `Migrated`, `PartNN` or similar;
- do not maintain both old and ConvoEngine definitions after a domain is accepted;
- do not hand-edit or manually move generated output;
- do not manually manufacture mass conversation-source shards; extend/use CodeBuilder's authoring/migration API and let it validate/write them.

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

All ConvoEngine contextual eligibility uses the shared predicate contract.

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

ConvoEngine does not implement fuzzy algorithms.

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
3. create final ConvoEngine source and final semantic IDs through CodeBuilder;
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

## Modularity / variety discipline

Before changing ConvoEngine content or generated output, read `CONVO_ENGINE.md` first and only the deeper modularity/chaining/action/naming document required by the active chunk.

- Numeric `1`, `2`, `3`, ... keys under `say` are stable **realization identities**, not separate semantic family identities.
- A family with one realization may author `say` directly without an artificial `"1"`.
- Ordinary dialogue/content source uses one compact exchange-family root: `kind`, `namespace`, family `id`, optional slots/participants/when, `invoke`, optional `execute`, `affordance`, initiating `say`, named `reply` outcomes, and `after`.
- Semantic callers reference the family or meaningful reply outcome, never wording realization keys.
- Initiating and reply realization keys are independent; never pair `say.1` to reply `say.1` by position.
- Ordinary adopter owner should derive from explicit family owner → manifest/shard owner → manifest `defaultOwner`; do not repeat owner in every record without need.
- Distinguish semantic family, reply outcome, stable realization key, style/context variant, and phrase alternatives.
- One source file owns one coherent semantic family/module. Do not preserve migration buckets such as `social_content.json`, `task_tool_replies.json`, or broad director catalogs.
- Use hierarchical semantic directories beneath `sources/conversation/dialogue/`; the migration-era `psdl/` wrapper must not survive final layout.
- Routine canonical dialogue IDs must not carry a redundant `semantic.` prefix after normalization.
- Do not encode neutral/warm/terse/guarded as separate semantic records when they are only style/context variants of one realization.
- Reusable recommendation targets own family-root `invoke` + UI-only `affordance.label`; callers use `after.recommend` semantic references or bounded groups instead of copying button/frame metadata.
- Actual initiating speech belongs in family `say`; responder speech belongs in named `reply.<outcome>.say`; never reuse the UI button label as canonical spoken dialogue.
- Compact source roles normalize to explicit runtime text roles (`button_label`, `spoken_action`, `response`); no implicit label→speech fallback is allowed.
- Dynamic label and `say` placeholders resolve from the same bound semantic instance and typed slots.
- Player buttons and NPC choices must project from the same semantic affordance instances; never add a separate button graph or parse rendered strings for meaning.
- NPC policy may score affordances using generic utility dimensions plus shared predicates fed by adopter relationship/trait/stat/mood/scene projections.
- Use `turns` for same-speaker message chaining and `after` for post-exchange recommendation/goto/end/resume semantics; branch-specific reply `after` overrides root fallback.
- ConvoEngine `execute` may reference only a registered typed Semantic Action Contract; never add arbitrary Lua/module/function callback authoring.
- Keep read-only query/candidate/binding providers separate from gameplay mutation/execution.
- Expose only bounded contract-declared `result.*` fields to ConvoEngine; raw adopter return tables remain private.
- Async actions must have bounded correlation/idempotence/stale-result safety; duplicate results must not replay mutation or speech.
- Preserve adopter gameplay authority: Core owns the generic action/result mechanism, not Hoomans camp/trading/domain policy.
- Do not manually rename or edit generated `Catalog.lua` or `StaticSuggestions.lua` files. Fix Core compiler/generator/template routing first, regenerate, then validate.
- Generated ConvoEngine runtime modules must live under `<Owner>/ConvoEngine/...` with meaningful leaves, e.g. `PNC/ConvoEngine/Dialogue/Social/Argument/Deescalate.lua`; do not retain conversation-owned `Semantics`, `Generated`, `Conversation`, or `PSDL` path wrappers.
- Before moving runtime modules out of `Semantics/`, classify ownership. Generic Core parser/NLU/predicate/fuzzy/IR infrastructure stays under `PsychopatzCore/Semantics/`; only proven ConvoEngine-owned runtime moves.
- Use/extend Core `catalog_naming.py` rather than inventing a second generated-name algorithm.
- Treat `sourceSurface`, `responseTemplateID`, `contentOwner`, and broad `category` metadata as migration residue unless a real current consumer requires it. Migrate consumers to derived compiler projections before removing authored fields.
- Never start a mass file move until compact exchange-family normalization, affordance/reply/chaining normalization, action/result contracts, and generator naming are tested in Core.

## Completion-audit discipline

Do not equate compiler support with catalog migration or service APIs with GUI acceptance.

Before closing S4-S8:

- enumerate surviving migration-era/pre-ConvoEngine Conversation sources and classify them explicitly;
- a file containing maintained dialogue wording, response pools, semantic offers, beat/behavior/realization authoring, or node/choice/outcome source structure is not “mechanism” merely because it lives under Core tooling;
- recognition-only patterns or explicit compatibility data may remain only with an evidence-backed non-authoring classification;
- do not restore deleted legacy source/translations to satisfy stale tests; update tests to the canonical ConvoEngine/CodeBuilder runtime seam;
- source/audit inventories must ignore `__pycache__`, `.pyc`, cache/temp files, editor backups, and equivalent non-source noise;
- a phase cannot be CLEAN_CHECKPOINT while phase-owned normative docs or adopter pointers remain untracked/unstaged;
- S7 requires the user-facing ConvoEngine-native Semantic Lab/editor workflow, not only Python CRUD/service methods.

Generated-output size/file count is not itself a failure, but S6 must measure it and justify retained fan-out. Reduce semantically redundant per-record output when safe without violating package boundaries, deterministic generation, or Project Zomboid/Build 42 Lua limits.

## Validation

Minimum per relevant phase:

- `git diff --check`;
- focused Python compiler/authoring tests;
- focused Lua semantic/dialogue/scene/director tests;
- ConvoEngine schema/validation tests plus explicit bounded legacy-reader fixtures where still supported;
- exchange-family/reply/realization-key normalization tests;
- registered action-contract input/result-schema tests;
- sync + async result/reply/correlation/idempotence tests;
- query-versus-execute mutation-safety tests;
- deterministic two-pass generation;
- source/audit no-new-legacy guard;
- Kahlua/static verification when available;
- full isolated Lua suite for runtime/generated changes;
- Semantic Harness worker fixtures for changed behavior;
- EN + optional-locale placeholder/source consistency;
- source/save immutability where applicable.

S8 additionally runs the exhaustive participant/constraint/offer/beat matrix from ROADMAP.

### S8R final-name/closure discipline

Before declaring S8 accepted:

- classify every remaining `PSDL` / `psdl` reference as active ConvoEngine
  identity/output, bounded migration reader/test fixture, generic semantic
  infrastructure, or obsolete alias;
- no maintained ConvoEngine source/generated/runtime/translation output may
  emit `psdl.*`, `pnc.psdl.*`, or `Conversation/Text/psdl/`;
- change compiler/CodeBuilder source of truth first and regenerate; never rename
  generated output by hand;
- extend `convo_engine_s6m8_audit.py` to scan canonical source, generated Lua,
  translations, manifests/registries and first-party runtime path callers;
- a bare `convo_engine_cli.py audit-s6m8 --check-determinism` must either
  discover all mandatory current repositories or fail fast with exact required
  arguments; a partial one-owner run is not S8 evidence;
- use the explicit three-repository audit invocation until auto-discovery is
  fixed;
- the known Hoomans PopulationDirector failure may be recorded as unrelated only
  while fresh Git/dependency evidence continues to prove no ConvoEngine change
  reaches that subsystem;
- do not mark HANDOFF `CLEAN_CHECKPOINT` or `DEVELOPER_COMPLETE` while
  goal-owned normative docs are dirty/untracked or while the committed handoff
  references files absent from the commit.

Do not weaken assertions or inflate limits/timeouts merely to make migration pass.

### S9 / S9R accepted architecture and S10 reliability discipline

S9H0-S9H7 and S9R0-S9R3 remain architecturally accepted. Do not redesign their
six-port model without a concrete regression. However, developer-side acceptance
is reopened as S10 because the real manifest-selected PNC provider worker and
GUI path were not part of the previous accepted matrix and now reproduce a
startup failure.

For S10, read `PROGRESS.md`, `HANDOFF.md`,
`SEMANTIC_HARNESS_RELIABILITY.md`, and the S10 section of
`SEMANTIC_HARNESS_AUDIT.md` before editing.

Preserve the accepted S9/S9R invariants:

- keep manifest/provider-driven workspace discovery;
- keep all family mutation behind ConvoTransaction;
- keep production Lua ConvoProbe as behavioral truth with no Python fallback;
- keep missing legacy sources fail-closed and compatibility-gated;
- keep deterministic audits isolated from live generated trees;
- keep staging/temp output outside Project Zomboid `media/`;
- do not add adopter-specific action IDs or repository branches to Core Studio;
- do not expand the 11-operation public vocabulary unless a real missing
  semantic responsibility is proven.

S10 adds these acceptance rules:

- a neutral Core worker with provider metadata is not proof that a manifest-
  selected provider Python worker/provider Lua worker starts;
- every provider declaring a worker must enter the mandatory provider lifecycle
  matrix automatically;
- every supported public GUI/CLI/agent action must have one compact Feature
  Acceptance Registry entry and a real-path acceptance owner;
- GUI-exposed features require real Tk/Xvfb acceptance, not only mocked widget
  or service tests;
- when Xvfb is available, DISPLAY-dependent mandatory tests must run rather than
  silently skip;
- top-level acceptance must report Core tests, root adopter Lua, provider Python,
  provider real-worker, GUI/Xvfb, DT, deterministic audit and Kahlua/static
  suites separately;
- mandatory unexplained skips are failures;
- source-writing GUI tests use hermetic temporary repositories/outputs and never
  mutate the user's live canonical sources;
- worker startup/restart acceptance must prove catalog/registry stability and
  no duplicate/stale registration;
- preserve strict invalid-response failure; never fix startup by ignoring empty
  pools, skipping capabilities, or inflating unrelated limits;
- preserve the ConvoEngine text-role contract: `affordance.label` is UI-only,
  initiating `say` is spoken action, and reply `say` is response text;
- never allow a generic `labelFallback -> utterance/textFallback` chain to make
  a conversational button label the canonical spoken line;
- dynamic speech uses the same bound semantic instance/typed slots as the
  action; do not recover names/targets by parsing rendered strings;
- intentional label/speech equality must be explicitly authored in both roles,
  not inherited through fallback;
- the ProjectHoomans identity regression in
  `S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md` is mandatory S10 evidence;
- error output should expose provider, feature/operation, pool/capability and
  underlying reason when available.

A feature is not developer-complete merely because its underlying service or CLI
operation has unit coverage. If users/agents invoke it through another surface,
acceptance must exercise that real surface through the selected provider/runtime
path.

S10 acceptance reruns the retained S9/S9R matrix plus all mandatory provider and
real-GUI gates defined in `SEMANTIC_HARNESS_RELIABILITY.md`.

S10R adds these closure rules:

- deleting a test is not a repair when its public/service responsibility still exists; require parity replacement or caller-zero retirement proof;
- public-surface discovery must include supported top-level argparse options as well as `convo` subcommands and GUI controls;
- a CLI action remaining in `--help` is treated as supported unless the implementation and docs explicitly deprecate/remove it;
- `convoScopeOk` is diagnostic only and never overrides a failed mandatory suite;
- unrelated-baseline allowances require an explicit reviewed machine classification with provenance/owner/reason; filename heuristics alone are insufficient;
- lifecycle acceptance must execute every supported non-alias worker-bearing selection returned by current manifest/preset discovery; do not maintain a hard-coded provider allowlist;
- final acceptance evidence must be reproduced from the recorded participant checkpoint; dirty residual work must be fingerprinted and cannot silently contribute to a committed-complete claim;
- final HANDOFF must contain exact participant commit IDs and no `<updating...>` placeholders.

### One-command S10 acceptance workflow

Run all 9 mandatory developer acceptance suites from `psychopatzCore`. The command is accepted only when its overall result is PASS; a green narrower-scope diagnostic inside a failed suite is not sufficient:

```bash
PYTHONPATH=. python3 -m tools.semantic_harness --acceptance --acceptance-jobs 4 \
  --acceptance-report /path/to/s10_acceptance.json
```

Focus specific suites with `--acceptance-suite <suite>` (`core_python`, `core_lua`,
`hoomans_lua`, `hoomans_provider_python`, `real_provider_worker`, `tk_xvfb_gui`,
`dynamic_trading`, `convo_audit`, `kahlua_static`). Verify UI/CLI acceptance
ownership mapping and provider start/restart/reconfigure invariants with:

```bash
PYTHONPATH=. python3 -m unittest \
  tools.semantic_harness.tests.test_feature_registry \
  tools.semantic_harness.tests.test_s10d_provider_lifecycle \
  tools.semantic_harness.tests.test_acceptance_runner \
  tools.semantic_harness.tests.test_convo_engine_s9r_closure -v
```

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

Stop only for a genuine blocker/ownership conflict or after all developer work is complete and only user-owned native acceptance remains.\n
