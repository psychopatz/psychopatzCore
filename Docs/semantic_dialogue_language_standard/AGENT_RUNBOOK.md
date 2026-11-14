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

The reusable ConvoEngine mechanism belongs in PsychopatzCore. Implement the conversation schema, canonical IR, compiler/normalizer, generic validation, generic predicate/reference/slot/binding contracts, registered Semantic Action Contract/result mechanism, and shared CodeBuilder authoring service in Core. `PSDL`/`psdl` is migration compatibility only.

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

### S9 Semantic Harness convergence discipline

For S9, read `SEMANTIC_HARNESS_AUDIT.md` first. Read only the relevant
section of `SEMANTIC_HARNESS_COMPACT_ARCHITECTURE.md` for the active S9 chunk;
do not load the whole deep-design document by default.

Compactness means fewer authorities and public concepts, not fewer files at any
cost. New S9 code must converge on WorkspaceCatalog, ConvoCatalog, the shared
operation/transaction surface, production Lua ConvoProbe and BuildPlanner.

- add regression tests for a reproduced gap before replacing the old path;
- reuse the compiler/manifest participant map; do not add Studio-only sibling
  repository discovery;
- family create/edit/move/delete must go through a service transaction with
  owner routing, source fingerprint, global semantic-reference validation and
  regeneration;
- UI code must not call `Path.unlink()` on canonical ConvoEngine source;
- Python structural preview is allowed, but behavioral parity comes from
  production Lua Predicate/TextBinding/Affordance/ActionContract through the
  worker;
- do not hard-code adopter action contracts in Core Studio code when runtime or
  declarative registration can provide the catalog;
- missing canonical dataset sources are not editable and not workflow-ready;
- remove/hide obsolete zero-source authoring panes rather than keeping empty
  first-class surfaces;
- expose ConvoEngine through one discoverable main harness CLI/service contract;
- migrate tests off legacy PSDL record-bucket CRUD before deleting those
  compatibility methods;
- deterministic audits must not race by mutating the same live generated tree;
  use isolated output or a workspace generation lock;
- keep staging/temp output outside Project Zomboid `media/`.

S9 acceptance reruns the complete S8R matrix after focused harness parity tests.

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
