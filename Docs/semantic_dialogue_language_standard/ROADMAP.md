# Roadmap — ConvoEngine

**Parent status:** IN_PROGRESS — retained S11A/R1-R8A work is accepted, but R8D acceptance side-effect isolation and R9 Dialogue Completeness Workbench authoring readiness are mandatory before USER_ACCEPTANCE.
**Primary/owning repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Mandatory adopters:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
**Developer completion boundary:** S11A-S11E + S11R8D + S11R9 ACCEPTED / CLOSED. Broad dialogue/beat rewrite remains blocked until R9D.

## Objective and ownership

Make **ConvoEngine** the de-facto first-party conversation authoring/compiler system in
all three repositories. `PSDL`/`psdl` is a migration-era internal alias to retire through tested caller-zero migration, not the target public name. PsychopatzCore physically and architecturally owns the
ConvoEngine schema/Canonical Semantic Dialogue IR, parser/compiler/normalizer,
generic validation/predicates, actor-neutral participant/reference contracts,
typed slots/bindings, package routing, reusable CodeBuilder authoring service,
and reusable runtime contracts.

ProjectHoomans and DynamicTrading/DTCommon are adopters. They may own domain
records, translations/content, adapters, tests, and gameplay-specific
constraints. They must not contain another schema, IR, compiler, generic
predicate evaluator, binding engine, authoring service, or semantic dialogue
runtime.

ConvoEngine compiles into accepted authorities: Core semantic NLU/candidate machinery,
shared predicates/context/evidence projections, ResponsePlan, BranchOffers,
Interaction Director, Scene Runtime, Semantic Social Conversation,
SpeechRealization, and existing gameplay/relationship/knowledge/trading
services. PSDL does not replace those systems.

## Phase matrix

- **S0 — exact inventory and zero-new-legacy guard: ACCEPTED.** The Core-owned
  guard inventories Core, ProjectHoomans, and DynamicTrading and distinguishes
  Core mechanism ownership from adopter content.
- **S1 — Core IR, references, predicates: ACCEPTED.** Actor-neutral speaker,
  addressee, target, participants, typed slots/references, and collection
  predicates live in Core.
- **S2 — Core schema/compiler/normalizer: ACCEPTED.** There is one compiler and
  schema owner; adopters route records through it.
- **S3 — offers, turns, bindings, runtime contracts: ACCEPTED.** Player buttons
  and NPC choices consume the same participant-neutral semantic affordances.
- **S4 — behavior/beat/realization standardization: ACCEPTED for corrective
  closure.** Maintained Core catalogs use PSDL `kind` records; Interaction
  Director and SpeechRealization remain runtime authorities; simple dialogue
  does not require a beat.
- **S5 — first-party source migration: ACCEPTED.** Core’s surviving source inventory is PSDL
  plus justified recognition, semantic-memory, and routing data. Hoomans and
  DTCommon final adopter records are routed through Core; superseded authoring
  sources are deleted after parity/caller-zero evidence.
- **S6 — final cleanup/scaling: ACCEPTED foundation.** Deterministic generation, compact family source, runtime packing and semantic module routing are verified.
- **S6M — modular ConvoEngine exchange-family normalization: ACCEPTED through S6M8 implementation.** The compact family/compiler, CodeBuilder authoring path, runtime namespace migration, sharding, realization/reply/affordance normalization, action/result contracts, metadata cleanup and deterministic audit are implemented and tested. S8R adds one missing audit dimension: active legacy-name leakage.
- **S7 — ConvoEngine-native Semantic Lab: ACCEPTED.** Family-oriented authoring, action selection, player↔NPC/NPC↔NPC simulation and trace are implemented and Core-tested.
- **S8 — exhaustive acceptance: ACCEPTED.** Verified with zero S6M8/S8R violations across 566 families, two-pass determinism across 404 generated files, hardened active-legacy leakage checks, Kahlua2 zero-error verification, and fresh three-repository test suites.
- **S8R — final naming and truthful closure: ACCEPTED.** Removed active `psdl.*`/`pnc.psdl.*`/`Conversation/Text/psdl/` output naming through Core/CodeBuilder root causes, deleted the obsolete `psdl_authoring_pane.py` alias, hardened `convo_engine_s6m8_audit.py` and bare CLI three-repo discovery, committed all goal-owned normative docs, and reverified the full S8 matrix.

## Required gates by phase

### S0

Produce machine-readable evidence for every maintained surface:
source → repository/package owner → mechanism versus adopter record → callers /
references → generated outputs → compatibility status → final PSDL destination
→ migration/removal status. Ignore caches, interpreter artifacts, editor
backups, temporary files, and generated noise. Reject new first-party additions
to frozen old authoring roots without rejecting legitimate PSDL adopter records
or external compatibility boundaries.

### S1-S3

Keep the canonical IR and shared predicate/reference/slot/binding contracts in
Core. Support scalar/logical and bounded collection operations (`contains`,
`not_contains`, `contains_any`, `contains_all`) through one predicate system.
Use actor-neutral names and preserve fuzzy-resolution exactness/confirmation and
authoritative mutation validation. Keep EN as required fallback and locales
data-driven.

### S4-S5

Use PSDL `dialogue`, `behavior`, `beat`, and `realization` records as the only
maintained first-party semantic authoring authority. Behaviors are reusable
strategies; beats own entry/maintain/exit and rank behaviors but never wording;
Interaction Director remains the arbitration authority. Migrate directly to
final semantic IDs/layout, prove parity and EN/optional-locale placeholder
parity, prove caller/reference zero, then delete superseded sources. Never add
Legacy/Compat/Old/V1/Migrated/PartNN copies.

Current corrective source evidence is
`S5_CORE_SOURCE_AUDIT.json`: 42 surviving Core Conversation JSON sources are
individually classified, and 56 superseded first-party authoring sources are
recorded with final destinations.

### S6

Audit generated file/byte fan-out and manifest/index sizes. Preserve package
boundaries, lazy/bounded loading, source lineage, deterministic generation, and
Build 42 Lua local-variable safety. The accepted implementation packs PSDL
runtime records into bounded deterministic catalog shards and provides a
generated realization discovery alias for the existing UtterancePlan loader.
Generated artifacts remain downstream-only and must not become hand-authored
sources.

### S6M — compact exchange families, modular source and generated naming

This phase is normative. For Luna-class agents, read `PROGRESS.md`, `HANDOFF.md`, and `CONVO_ENGINE.md` first, then only the deeper specification for the active S6M subchunk. Do not load every design document for every edit.

#### S6M0 — machine-readable modularity inventory

Measure all three repositories and report:

- semantic families per ConvoEngine conversation source;
- source bytes and top-level record counts;
- flat versus hierarchical source paths;
- redundant `semantic.` prefixes;
- numbered records and whether the number is semantic migration residue or only
  wording/realization identity;
- top-level style/context duplication;
- separate static suggestion authority;
- duplicated action/result routing;
- stale source/owner/template metadata;
- generic generated `Catalog.lua` leaves;
- source/generated lineage.

Do not classify every numeric key as a defect. Stable numeric keys remain useful
for wording realization identity.

#### S6M1 — compact exchange-family compiler contract

Before mass migration, Core must support the final compact dialogue family:

```json
{
  "kind": "dialogue",
  "namespace": "social.knowledge",
  "id": "ask_person",

  "invoke": { ... },
  "affordance": { ... },

  "say": {
    "1": "...",
    "2": "..."
  },

  "reply": {
    "known": {
      "say": {
        "1": "...",
        "2": "..."
      }
    },
    "unknown": {
      "say": "..."
    }
  },

  "after": { ... }
}
```

Required compiler behavior:

- canonical new-write schema is `psychopatz.convo-engine.v1`; the old `psychopatz.semantic.dialogue-language.v1` schema is migration-read-only until caller/source zero;
- root `kind`, `namespace`, family `id` written once;
- owner inherited from explicit family owner → manifest/shard owner →
  `defaultOwner`;
- family identity remains `namespace + id`;
- numeric keys under `say` are stable realization keys, not semantic IDs;
- one realization may use direct string/locale-map shorthand without an
  artificial `"1"`;
- named `reply` keys represent semantic outcomes;
- initiator and reply realization keys are independent;
- style/context variants remain inside a realization;
- localized phrase arrays remain phrase alternatives;
- semantic callers reference family/outcome, never wording key;
- canonical runtime text roles normalize explicitly to
  `button_label` / `spoken_action` / `response`;
- backward-reading support is migration-only and has a removal gate;
- the shared CodeBuilder authoring service understands the final exchange-family shape;
- a small headless ConvoEngine authoring/migration command/API can create, validate, move/shard, and write canonical families so agents do not manually manufacture JSON files.

The compiler must not expand:

```text
social.knowledge.ask_person + say["1"]
→ social.knowledge.ask_person.1
```

merely because wording has multiple realizations.

#### S6M2 — ConvoEngine runtime namespace + naming root fix

Fix Core owner-routing/generator/template code, not generated files.

Current generated conversation prefixes are:

```text
PsychopatzCore/Semantics/Generated/Conversation
PNC/Semantics/Generated/Conversation
DTCommon/Semantics/Generated/Conversation
```

and current runtime modules may add another `/PSDL/` segment.

Final ConvoEngine-owned runtime prefixes are:

```text
PsychopatzCore/ConvoEngine
PNC/ConvoEngine
DTCommon/ConvoEngine
```

The ConvoEngine namespace itself supplies the subsystem meaning. Do not retain
conversation-owned `Semantics`, `Generated`, `Conversation`, or `PSDL` path wrappers.

This is **not** a blind rename of every `Semantics/` module. Core's generic
parser/NLU, predicate, fuzzy/entity resolution, semantic IR, and other reusable
non-conversation semantic mechanisms remain under `PsychopatzCore/Semantics/`
unless separately proven ConvoEngine-owned.

##### S6M2A — ownership inventory

Before path edits, classify every affected current runtime module/reference as:

- ConvoEngine-owned: dialogue state/flow/router, conversation registry/manifest,
  offers/replies/chaining, interaction/social-conversation presentation,
  speech-realization modules used as part of the conversation engine, and
  adopter conversation adapters; or
- generic semantic infrastructure that stays under Core `Semantics/`.

Record the classification in machine-readable audit output. Do not decide by
filename substring alone.

##### S6M2B — root-cause namespace migration

After S6M2A is accepted:

- change Core package descriptor/owner-routing constants and generator/template logic;
- route generated ConvoEngine modules under `<Owner>/ConvoEngine/...`;
- migrate proven conversation-owned hand-authored runtime modules only where
  their ownership classification requires it;
- replace broad domain + literal `Catalog` leaves with semantic module names;
- rename proven conversation-owned module/API symbols from `PSDL` / `SemanticDialogue` / conversation-owned `Semantic*` names to clear ConvoEngine names where they are part of this subsystem, while leaving genuinely generic semantic APIs unchanged;
- update exact first-party requires, registries, manifests, tests, and diagnostics atomically;
- regenerate all three owners through CodeBuilder;
- prove old ConvoEngine-owned `Semantics/...Conversation...` and `PSDL`
  caller/reference count is zero;
- delete old generated/conversation-owned paths only after parity.

Target:

```text
sources/conversation/dialogue/social/knowledge/ask_person.json
→ <Owner>/ConvoEngine/Dialogue/Social/Knowledge/AskPerson.lua
```

The earlier audit found no current first-party hand-authored
`<Owner>/Semantics/Conversation/` collision; S6M2A must additionally verify
the final `<Owner>/ConvoEngine/` destination is collision-safe before writes.

Generated provenance remains in headers/manifests/fingerprints/source lineage,
not in the directory name.

Never manually move generated files. Reuse/extend collision-safe naming helpers
in `catalog_naming.py`.

#### S6M3 — semantic source sharding

Refactor source through canonical CodeBuilder roots **using the CodeBuilder ConvoEngine authoring/migration API**, not raw bulk filesystem writes. If the required headless migration operation is missing, add it to CodeBuilder first.

Primary rule:

> one file = one coherent semantic family/module.

Split broad aggregates by meaning, including:

- social argument/reaction/memory/scene families;
- horde/post-combat/excursion/news/work scene families;
- task lifecycle by task type;
- companion command exchanges by command;
- tool-result/reply families;
- health/wellbeing/medical families;
- navigation families;
- Core behavior/beat/social-director aggregates.

Do not create one file per phrase and do not create arbitrary PartNN shards. Do not manually create dozens of destination JSON files; let the validated CodeBuilder migration operation write them.

#### S6M4 — realization/style normalization + canonical ID cleanup

For each family:

- preserve genuine semantic family identity;
- move pure wording alternatives under `say` numeric realization keys;
- keep direct single-`say` shorthand when only one realization exists;
- move neutral/warm/terse/guarded/etc. under realization style/context variants
  when they do not change semantic meaning;
- keep phrase alternatives in localized text arrays;
- remove redundant routine `semantic.` prefixes;
- remove `.1/.2/.3` from semantic IDs when they only represented wording
  alternatives;
- give genuinely different semantics meaningful family/outcome names instead of
  arbitrary numeric identity;
- update first-party references/tests/generated mappings atomically;
- prove old-ID caller zero before removal.

Do not add broad permanent old-ID aliases.

#### S6M5 — affordance, reply and chaining normalization

Read `CHAINING_AND_AFFORDANCES.md`.

Add/normalize:

- family-root `invoke`;
- UI-only `affordance.label`;
- initiating `say` with stable realization keys;
- named `reply` semantic outcomes with independent `say`;
- reply-specific `after`, with root `after` as fallback only;
- typed slot candidate providers for dynamic labels/actions;
- bounded `after.recommend` family references;
- bounded recommendation groups;
- generic affordance utility + shared-predicate preference modifiers;
- `after.goto`, `after.end`, `after.resume`;
- participant-neutral player/NPC use of the same bound affordance instances.

Target:

```json
{
  "kind": "dialogue",
  "namespace": "social.knowledge",
  "id": "ask_person",

  "slots": {
    "person": {
      "type": "entity.person",
      "suggest": "knowledge.people",
      "limit": 4
    }
  },

  "invoke": {
    "intent": "QUESTION",
    "subject": "PERSON_LOCATION",
    "target": "$slot.person"
  },

  "affordance": {
    "label": "Ask about {slot.person.name}",
    "groups": ["social.info"],
    "utility": {
      "curiosity": 0.8
    }
  },

  "say": {
    "1": "Have you seen {slot.person.name} lately?",
    "2": "Do you know where {slot.person.name} is?"
  },

  "reply": {
    "known": {
      "say": {
        "1": "{slot.person.name} is near Riverside.",
        "2": "Last I heard, {slot.person.name} was around Riverside."
      },
      "after": {
        "recommend": ["navigation.ask_direction"]
      }
    },
    "unknown": {
      "say": "Sorry, I don't know."
    }
  }
}
```

Do not use the button label as spoken dialogue. Do not pair initiating
`say.1` with reply `say.1`.

Migrate static/hub suggestions so target families own semantic meaning, UI
label, initiating speech and relevant reply outcomes once.

#### S6M6 — registered gameplay action/result contract

Read `ACTIONS_AND_RESULTS.md`.

Implement in Core one generic Semantic Action Contract mechanism separate from
the existing candidate ActionProvider registry.

Required generic contract:

- registered action ID;
- optional capability;
- execution mode (`sync`, `request_response`, `long_running`);
- typed input schema;
- bounded public result schema;
- normalized outcome/reasonClass mapping;
- runtime adapter seam;
- async correlation/idempotence/stale-result safety;
- diagnostics/Semantic Lab trace.

PSDL authoring uses:

```json
"execute": "pnc.companion.camp"
```

or bounded per-use mapping:

```json
"execute": {
  "use": "pnc.companion.camp",
  "with": {
    "target": "$slot.location"
  }
}
```

PSDL must never contain arbitrary Lua/module/function names.

Expose only schema-projected public `result.*` fields to predicates/bindings.
Raw adopter return tables remain private.

Use Hoomans CAMP as the primary acceptance case:

```text
semantic selection
→ initiating say
→ existing authoritative camp dispatcher/server path
→ pending/accepted/rejected/failed/completed result
→ bounded result.data.site projection
→ reply outcome
→ reply say/bindings
```

Do not replace or duplicate the existing camp gameplay authority.

Keep read-only query/candidate providers separate from mutation/execution.

#### S6M7 — metadata derivation cleanup

Audit consumers of migration-era metadata.

Derive routine source lineage, owner, family identity, text role and category
from canonical source/namespace/structure wherever possible.

Remove stale deleted-source `sourceSurface` and redundant
`responseTemplateID`/`contentOwner` authoring only after caller/runtime
parity is proven.

#### S6M8 — audit and acceptance

Add Core validation/audit for:

- one semantic family per file;
- namespace/path agreement;
- concise semantic family IDs;
- no wording-only numeric suffixes in semantic IDs;
- valid stable `say` realization keys;
- named reply semantic outcomes;
- no initiator/reply positional variety coupling;
- no button-label-as-speech fallback;
- correct runtime text roles;
- valid dynamic bindings;
- bounded slot-candidate expansion;
- dangling recommendation/goto references;
- bounded recommendation groups/chains;
- registered/typed `execute` references;
- no arbitrary Lua/function execution authoring;
- bounded public `result.*` access;
- safe async result correlation;
- no duplicate action execution;
- no separate first-party static suggestion authority;
- no generic generated `Catalog.lua` leaves;
- deterministic source/generated lineage.

Regenerate from source and prove:

- no hand-edited generated files;
- deterministic two-pass output;
- Kahlua/static compatibility;
- Core harness green;
- Hoomans broad semantic/conversation/PSDL tests green;
- DynamicTrading relevant focused/broad tests green;
- camp action/result/reply acceptance green;
- query-versus-execute safety green;
- Semantic Lab can trace affordance → speech → execute → result → reply.

### S7

The actual Semantic Lab must expose the existing Core authoring service, not a
second editor format. The ConvoEngine-native surface must support browse/select source;
create/edit/duplicate/delete semantic families; kind selection; participants and
speaker/addressee/target; predicates including collection constraints; typed
slots/references; bindings/resolvers; locale variants and EN fallback; turns,
advanced explicit offers, transitions; behavior/beat entry/maintain/exit/candidates;
realization forms/translations; source lineage; compile diagnostics; adjustable
preview speaker/addressee/target/context; player↔NPC and NPC↔NPC preview;
fuzzy/entity resolution inspection where applicable; and predicate → beat →
behavior → variant → affordance trace.

The normal dialogue editor must be family-oriented rather than expanded-record
oriented. It must support:

- hierarchical source browsing;
- root kind/namespace/family ID editing;
- manifest-derived owner display/override;
- compact family identity and ordinary root field editing;
- initiating `say` single-form or stable numeric realization-key editing;
- style/context variants inside a realization;
- named reply-outcome create/edit/delete/reorder and independent reply `say` editing;
- family `invoke` editing;
- UI-only `affordance.label` editing and preview;
- typed slot candidate-provider editing;
- affordance utility/preference editing and NPC score trace;
- registered `execute` action-contract picker and typed input mapping;
- bounded `result.*` schema/outcome/reasonClass preview;
- async action lifecycle/correlation diagnostics;
- result-driven reply branch trace;
- searchable semantic-family picker for `after.recommend`;
- recommendation-group editing/preview;
- `after.goto`, end and resume controls;
- player-button preview distinctly separated from initiating spoken-line preview;
- selected reply-outcome + reply spoken-line preview;
- NPC-affordance/selection preview;
- recommendation include/exclude/ranking/utility trace;
- no requirement to manually edit expanded canonical IDs or generated
  translation/button keys.

### S8

Freshly prove that ConvoEngine is the only maintained first-party conversation
authoring/compiler authority across Core, Hoomans, and DynamicTrading; source is hierarchically
sharded by coherent semantic family; ordinary dialogue source uses compact
exchange-family identity with stable initiating/reply `say` realization keys
and named semantic reply outcomes; owner boilerplate derives from
manifest/provider routing where possible; wording realization keys never become
semantic family IDs; canonical IDs are concise/non-redundant; reusable targets
own `invoke` + UI-only `affordance.label` once; actual initiating and reply
speech use independent style/translation/binding-aware realizations; player
recommendation buttons and NPC choices consume the same bound semantic
affordance instances; NPC choice can use relationship/trait/context utility
without parsing text; registered typed `execute` contracts preserve adopter
gameplay authority, bounded public `result.*` drives replies/bindings, async
results are safely correlated/idempotent, and query discovery never mutates;
nested chains use
bounded `after.recommend` / `after.goto` / end / resume normalization; generated
ConvoEngine Lua has semantic module filenames rather than generic Catalog leaves; old
node/choice/outcome and static-suggestion authorities are gone except explicitly
justified recognition or compatibility boundaries; actor permutations, typed
references, bindings, collection predicates, fuzzy safety, shared offers,
nested/multi-turn dialogue, modular beats, mixed scenes, data-driven locales,
`<Owner>/ConvoEngine/...` runtime namespace with no conversation-owned
`Semantics/Conversation/PSDL` wrappers, no active legacy PSDL naming in
maintained ConvoEngine source/generated/runtime/translation output, Core
ownership, adopter-only content, focused/broad tests, deterministic generation,
bounded output, cache-free audits, and committed job documents all pass. Do not
call the final checkpoint CLEAN while phase-owned files remain untracked.

### S8R — final ConvoEngine naming and closure

S8R exists only to close defects found by the 2026-11-14 audit. Do not redesign
the accepted compact exchange-family architecture.

Fresh measured baseline:

```text
canonical families
  Core       126
  Hoomans    429
  DTCommon    11
  total      566

family files >32 KiB          0
top-level records arrays      0
old source-schema files       0

generated/runtime PSDL token occurrences
  Core       57
  Hoomans   524
  DTCommon   10

Hoomans canonical pnc.psdl.* textDomain entries   38
Hoomans Conversation/Text/psdl translation files  76
direct first-party Text/psdl path callers           3
```

The existing S6M8 audit passes with explicit three-repository arguments, but it
does not inspect these active legacy-name surfaces. Its bare Core invocation
also fails to discover the Hoomans external source root. Both are S8R defects.

#### S8R1 — classify remaining PSDL names

Inventory remaining `PSDL` / `psdl` references and classify each as exactly
one of:

- **active ConvoEngine identity/output** — must migrate;
- **bounded migration reader/test fixture** — may remain temporarily only when a
  real supported migration seam still requires it;
- **generic semantic infrastructure** — may retain semantic naming when it is
  broader than conversation;
- **obsolete compatibility alias/file/symbol** — remove after caller-zero.

Do not use a blind global rename. In particular,
`psychopatz.semantic.dialogue-ir.v1` and other genuinely generic Semantic IR
contracts are not automatically ConvoEngine naming defects.

#### S8R2 — remove active PSDL output identity

Fix Core compiler/generator/translation routing first, then migrate source
through CodeBuilder and regenerate all owners.

Required steady-state:

```text
generated response/translation template IDs:
  convo.<family>...

Hoomans conversation text domains:
  pnc.convo.<domain>...

Hoomans generated/maintained conversation text path:
  Conversation/Text/convo/...
```

No maintained ConvoEngine source or generated/runtime/translation artifact may
emit:

```text
psdl.*
pnc.psdl.*
Conversation/Text/psdl/
```

Update exact callers atomically. Never rename generated output by hand.

#### S8R3 — harden the exhaustive audit

Extend `convo_engine_s6m8_audit.py` and tests so S8 fails on active legacy-name
leakage in:

- canonical ConvoEngine sources;
- generated ConvoEngine Lua;
- generated/maintained conversation translation trees;
- manifest/registry output;
- first-party runtime path callers.

The audit must explicitly allow only classified migration-reader fixtures and
generic semantic infrastructure.

Make `convo_engine_cli.py audit-s6m8 --check-determinism` safe for Luna-class
agents: discover the required sibling/workspace repositories from current
workspace evidence when unambiguous, or fail fast with a precise actionable
repository-argument diagnostic. It must never silently degrade into a partial
one-owner acceptance run.

#### S8R4 — truthful documentation checkpoint

The S8 commit is not a clean canonical checkpoint while normative goal docs are
dirty/untracked.

Before final acceptance, commit the actual goal-owned documentation, including
at minimum:

- `ARCHITECTURE.md`;
- `LANGUAGE_SPEC.md`;
- `NAMING_AND_LAYOUT.md`;
- `AGENT_RUNBOOK.md`;
- `ROADMAP.md`;
- `PROGRESS.md`;
- `HANDOFF.md`;
- `CONVO_ENGINE.md`;
- `MODULARITY_AUDIT.md`;
- `CHAINING_AND_AFFORDANCES.md`;
- `ACTIONS_AND_RESULTS.md`.

Preserve unrelated Hoomans legacy-job documentation changes and DynamicTrading
architecture/cache dirt unless exact evidence proves they belong to S8R.

#### S8R5 — final acceptance gate

After regeneration, rerun from the final worktree:

- Core Python semantic-harness suite;
- Core ConvoEngine/Semantic/Conversation Lua suite through the intended Lua
  package-path harness;
- three-repository `audit-s6m8 --check-determinism`;
- DynamicTrading full suite;
- ProjectHoomans full suite;
- Kahlua ERROR verification over all three ConvoEngine runtime trees;
- explicit active-legacy-name leakage audit;
- `git diff --check`;
- final three-repository Git/worktree verification.

The known Hoomans
`pnc_population_director_smoke.lua:316` failure may remain an accepted
unrelated baseline only while fresh evidence continues to prove that neither
the test nor PopulationDirector implementation changed in the ConvoEngine
migration and no ConvoEngine/Conversation dependency reaches that subsystem.

S8R closes only when the final committed HANDOFF truthfully records exact HEADs,
residual unrelated dirt, fresh gate results and the remaining user-owned native
SP/MP acceptance.

## S9 — Semantic Harness ConvoEngine convergence

**Status:** COMPLETE / ACCEPTED.

S9H0-S9H7 implemented the compact six-port Semantic Harness architecture:

    WorkspaceCatalog
    ConvoCatalog
    OperationRegistry / ConvoTransaction
    production Lua ConvoProbe
    BuildPlanner
    thin GUI/CLI clients

Accepted S9 results include:

- one manifest-driven workspace/source discovery authority;
- bounded 566-family ConvoCatalog;
- 11-versioned-operation OperationRegistry;
- owner-routed fingerprint-guarded ConvoTransaction;
- production Lua ConvoProbe with no Python behavioral fallback;
- primary Conversations / Source Impact / Review Studio surfaces;
- compatibility-gated missing legacy dataset/workflow surfaces;
- main CLI `workspace` + `convo` commands;
- removal of dead public record-bucket PSDL CRUD methods;
- isolated deterministic BuildPlanner and workspace generation lock;
- 188/188 Core Python tests, 36/36 relevant Core Lua tests, 89/89 DynamicTrading, 1020/1021 ProjectHoomans with only the independent PopulationDirector baseline, and zero Kahlua errors across the three ConvoEngine trees.

The original S9 findings in `SEMANTIC_HARNESS_AUDIT.md` are historical baseline evidence. Do not treat them as current open defects.

## S9R — post-S9 closure reconciliation

**Status:** COMPLETE / ACCEPTED (verified 2026-11-14: `192/192` Core Python, `36/36` Core Lua, `566` families / `0` violations / `368` isolated determinism hashes, `89/89` DynamicTrading, `1020/1021` ProjectHoomans with only independent PopulationDirector baseline, `0` Kahlua errors).

S9R closed the five residual audit mismatches (`R1`–`R5`) without reopening S0–S9 architecture.

### S9R0 — pin residual closure defects

Add focused tests or assertions for:

1. `convo.simulate` advertises the real production runtime requirement:
   - required capability `semantic.convo_probe`;
   - worker requirement `required`, unless explicitly split into structural and behavioral operations.
2. the composition root exposes a usable BuildPlanner port rather than `harness.build == None`.
3. OperationRegistry build operations consume the composition-root BuildPlanner port.
4. ConvoEngine Studio authoring/simulation/audit actions dispatch through the canonical operation surface, or wrappers are proven 1:1 delegates by parity tests.
5. final continuity docs never regress to stale S9 planning state.

**Gate:** focused tests fail on the known residuals before implementation and do not reopen already accepted S9 functionality.

### S9R1 — operation/composition/client wiring cleanup

Implement only the bounded residual fixes:

- correct `convo.simulate` OperationDescriptor metadata;
- wire BuildPlanner into `HarnessContext.build` using a workspace-aware eager or lazy port;
- remove OperationRegistry's private competing BuildPlanner construction path and consume the composition-root build port;
- route ConvoEngine Studio through `dispatch_operation()` / OperationRegistry where practical;
- if a typed service wrapper remains, make it a strict thin delegate to a canonical operation and cover it with parity tests;
- do not add new public operation IDs unless required by a concrete missing semantic responsibility;
- do not redesign ConvoEngine schema/runtime, provider manifests, ConvoProbe, BuildPlanner semantics or Studio information architecture.

**Gate:** GUI, CLI and agents share the same machine-discoverable operation contract for the ConvoEngine responsibilities touched by S9R.

### S9R2 — durable continuity reconciliation

Reconcile current documentation:

- `PROGRESS.md` contains only current truth and one immediate Next Chunk;
- `SEMANTIC_HARNESS_AUDIT.md` clearly labels H1-H10 as pre-S9 historical findings and records their S9 resolution;
- `ROADMAP.md` marks S9 complete and S9R active/complete accurately;
- `HANDOFF.md` records the current participant vector and uses the correct checkpoint state;
- `SEMANTIC_HARNESS_COMPACT_ARCHITECTURE.md` remains the normative stable design rather than a progress ledger;
- avoid reintroducing stale PSDL/current-defect language into active docs.

**Gate:** grep/consistency review finds no active document claiming S9 is unimplemented or the resolved H1-H10 defects are current.

### S9R3 — final acceptance and committed handoff

Freshly rerun:

- focused S9R tests;
- full Core Python Semantic Harness suite;
- all 36 Core ConvoEngine/Semantic/Conversation/RuntimeRole Lua smokes;
- unified main CLI `convo audit --check-determinism`;
- DynamicTrading full suite;
- ProjectHoomans full suite;
- Kahlua ERROR verification for Core, ProjectHoomans and DTCommon ConvoEngine trees;
- `git diff --check`;
- exact Git status/HEADs for all participants.

The accepted PopulationDirector failure may remain only if it is still the sole Hoomans failure and fresh evidence continues to show S9R does not touch/reach it.

At acceptance:

1. preserve unrelated Hoomans and DynamicTrading dirt;
2. commit changed adopter repositories first if S9R changes them;
3. commit Core last;
4. final Core HANDOFF must use:
   - `checkpoint_mode: committed_handoff`;
   - `phase_commit: self`;
   - exact participant commit vector;
   - residual-work fingerprints;
   - state `USER_ACCEPTANCE` or equivalent developer-complete state;
5. do not push.

**Historical S9R completion gate:** S9R was accepted when its residual wiring/docs mismatches closed and the then-defined matrix remained green. Its conclusion that only native Project Zomboid acceptance remained is superseded by S10 after real provider-worker/GUI-path testing exposed an omitted developer-side acceptance surface.

## S10 — Semantic Lab end-to-end reliability and maintainability

**Status:** COMPLETE — S10A-S10D plus S10R1-S10R4 accepted; canonical 9-suite acceptance is green from the recorded closure checkpoint.

S10 was opened because real 2026-11-15 acceptance disproved the prior developer-complete claim without invalidating the accepted S0-S9R architecture. The manifest-selected PNC provider-worker startup defect and label-versus-speech identity defect were repaired by S10A. The 2026-11-16 post-completion audit then repaired acceptance integrity and reproducible closure through S10R.

The normative S10 design is `SEMANTIC_HARNESS_RELIABILITY.md`. The focused runtime acceptance for UI-label versus spoken realization is `S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md`. The closure-repair record is `S10_ACCEPTANCE_INTEGRITY_REPAIR.md`; `LANGUAGE_SPEC.md` remains the semantic authoring authority.

S11 later reopened **new developer-side semantic-state correctness work** after the accepted S10 harness exposed contradictory state/outcome behavior. That evidence does not invalidate the S10 harness/acceptance architecture.

### S10A — real PNC worker startup and automatic-flow integrity

**Status:** COMPLETE (`MAX_POOLS = 256` preserved; manifest-selected `LuaSemanticWorker` startup/restart catalog-stable; `hello` & `CAPABILITIES` persona payload kept compact while `PERSONA_CATALOG` retains full phrase content; `ResponseCatalog_Conversation` canonical pool extension preserves `SpeechRealization` family lookup and prioritizes styled pools; `affordance.label` vs initiating `say` vs reply `say` contract enforced; bound canonical/generated identity claims and distinct refusal verified in real worker + real Tk/Xvfb GUI journey with 36/36 provider/GUI tests and Lua preflight/local route smokes green).

- freeze the exact manifest-selected `LuaSemanticWorker` failure;
- preflight generated response pools before registry mutation;
- audit all parameterized task response metadata against canonical ConvoEngine wording;
- repair the source-of-truth mismatch rather than skipping/ignoring invalid pools;
- improve registration diagnostics with reason/capability/template identity;
- prove repeated start/restart is idempotent and catalog-stable;
- enforce the existing ConvoEngine rule that `affordance.label` is UI-only and cannot become spoken dialogue through an implicit fallback;
- bind truthful/generated identity claims into `say` realizations from authoritative semantic slots rather than generic/manual runtime strings;
- add the ProjectHoomans identity click regression defined in `S10_LABEL_SPEECH_REALIZATION_ACCEPTANCE.md`, including natural wording variants with semantic invariance.

**Gate:** the real PNC provider worker starts/restarts, returns capabilities, all generated pools are resolvable/non-empty and catalog-stable, label-to-speech fallback is rejected or explicitly classified, and the focused real-worker identity case proves the button label is not the spoken player line while the bound canonical/generated identity remains authoritative.

### S10B — unified acceptance orchestration

**Status:** COMPLETE via S10R. The unified runner remains the canonical acceptance orchestrator; S10R1 restored deleted/stale acceptance ownership and S10R3 made the canonical nine-suite workflow reproducibly green.

Create one bounded developer acceptance workflow that reports Core Python/Lua, Hoomans root Lua, Hoomans provider Python, real provider-worker acceptance, real Tk/Xvfb GUI, DynamicTrading, deterministic ConvoEngine audit, and Kahlua/static verification as distinct suites.

Mandatory suites may not silently disappear. Display-required tests run under Xvfb when available. Report passed/failed/skipped/allowed-skips per suite.

**Gate:** the accepted report represents the real harness surface, not only component/root smoke tests.

### S10C — feature-owned real GUI acceptance

**Status:** COMPLETE via S10R. Real Tk/Xvfb journeys remain green; S10R2 completed public CLI/UI acceptance ownership discovery and negative coverage enforcement.

Introduce one compact machine-readable Feature Acceptance Registry mapping supported public actions to surface, canonical operation/capability, provider applicability, mutation class and automated acceptance owner.

Inventory World & Mods, Simulation, Quality Sweep, Studio and actionable diagnostics. Add real Tk/Xvfb journeys using the real session/provider path and hermetic fixture repositories for mutating authoring tests.

The mandatory Simulation/Conversation journeys include the identity-label regression: reach a pending identity exchange, verify the visible button remains a compact UI affordance, invoke that real widget path, and prove the player transcript uses a bound `say` realization containing the authoritative name rather than the UI label.

**Gate:** every mandatory supported feature has acceptance ownership, every GUI feature has a real-surface case, the label/speech identity journey passes through the real selected provider, and adding an uncovered supported feature fails validation.

### S10D — provider lifecycle, maintainability and closure

**Status:** COMPLETE (S10R1-S10R4 acceptance-integrity repairs completed; 9/9 `--acceptance` suites PASS from exact committed state).

Run start/request/restart/reconfigure/shutdown matrices for all supported manifest selections, repeat lifecycle transitions to expose stale globals/duplicate registration/registry drift, document the one-command acceptance workflow, and reconcile continuity docs only after all real-path gates pass.

**Completion gate:** SATISFIED for S10 (S10A + S10B-S10D + S10R1-S10R4 + retained S9/S9R green). The historical S10 handoff returned to native acceptance; S11 subsequently reopened new semantic-state correctness work from fresh runtime evidence.

### S10R — acceptance integrity and reproducible closure

**Status:** COMPLETE (`S10R1 -> S10R2 -> S10R3 -> S10R4` all green; 9/9 `--acceptance` PASS).

Normative repair design: `S10_ACCEPTANCE_INTEGRITY_REPAIR.md`.

S10R did not reopen the accepted S10A identity/worker implementation; it repaired the acceptance/closure system identified by the post-S10 audit:

- **S10R1 — deleted/stale acceptance ownership:** COMPLETE (all 12 `5f8b5000`-deleted modules mapped in the S10R1 ledger; retired pre-ConvoEngine `semantic_flows`/`common_dialogue`/`grounded_personal` dataset specs; repaired `dataset_catalog.py`, `interaction_generation.py`, and `variation_auditor.py` for canonical `convo_engine` / `patterns` / `wordnet_concepts` sources; Core `test_s10r1_dataset_and_workflow.py` + `test_s10r1_c5_variation_adapters_specs.py` + S9/S9R `40/40` and Hoomans `test_s10r1_worker_precision_and_history.py` `2/2` PASS).
- **S10R2 — complete public feature discovery:** COMPLETE (dynamic `argparse` `_parser()` discovery in `feature_registry.py` covers all 66 supported top-level CLI actions with `CLI_MODIFIER_OPTIONS` separation, alias mapping, and negative tests in `test_feature_registry.py` `4/4` + `test_s10r2_cli_actions.py` `1/1` + `test_s10r2_worker_cli.py` `2/2`).
- **S10R3 — genuinely green canonical acceptance:** COMPLETE (`unrelated_baselines.json` + `classify_hoomans_lua_results` require exact failure-signature match + owner + `provenanceCommit` and forbid ConvoEngine/timeout waivers; `suite.py` captures `failureOutput` on failures; `workspace_catalog.py` skips system temp roots during sibling discovery; canonical `--acceptance` accepts only signature-verified reviewed baselines with `--strict-baselines` strict mode and `convoScopeOk` purely diagnostic; `hoomans_lua` `1028/1032` PASS with 4 reviewed P1/PopulationDirector signatures and 0 unexpected failures).
- **S10R4 — manifest-complete lifecycle + closure:** COMPLETE (`test_s10d_provider_lifecycle.py` dynamically derives executable presets and cross-provider reconfigure matrices from `ModManager.discover` and rejects uncovered executable provider manifests (`4/4` PASS in `25.82s`); full 9-suite `--acceptance` `9/9` suites / `2171/2200` cases PASS in `1448.07s`; docs reconciled and committed with `phase_commit: self`, exact participant commits, and SHA-256 residual fingerprints).

**Gate:** SATISFIED — S10R1-S10R4 pass; all still-supported public surfaces have current acceptance ownership; every supported worker-bearing provider selection automatically enters lifecycle acceptance; canonical 9-suite acceptance is reproducibly green; and the final S10R handoff records exact participant commits and residual-work fingerprints. S11 is a later behavior-correctness phase, not a reopening of S10R acceptance integrity.

## S11 — State-Aware Conversation Outcome Closure

**Status:** IN_PROGRESS — R8A native task parity is retained; R8D must repair acceptance side effects, then R9 must expose the canonical Dialogue Completeness graph/report in Semantic Lab before broad content rewriting.

Historical repairs: R0-R4 in `S11_POST_IMPLEMENTATION_AUDIT_REPAIR.md`; R5 in `S11_POST_R4_CLOSURE_AUDIT_REPAIR.md`; R6 in `S11_POST_R5_FINAL_CLOSURE_REPAIR.md`; R7 in `S11_POST_R6_CLOSURE_AUDIT_REPAIR.md`.

Normative design: S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md. Approved post-G9 architecture: S11_SEMANTIC_STATE_OUTCOME_ARCHITECTURE.md. Mandatory branching/state audit: S11_BRANCHING_DIALOGUE_AUDIT.md.

The 2026-11-18 production-worker audit P0/P1/P2 scope is closed on current `main` HEADs: known-identity first-contact leakage/reward farming/stale choices; repeated or busy companion-command dispatch; Needs proposal_pending self-loop; hostile greeting plus friendly follow-up; stale recruitment; stale relationship proposal; parameterized task presentation lifecycle; quest ready→rewarded→repeat lifecycle; disband confirmation safety; event response-window expiry; and atomic settlement-admission / ambient-visit post-success conversation refresh.

The implementation seam changed after G7-G9:

~~~text
compact ConvoEngine/PSDL
→ canonical IR
→ Portable Dialogue Plan
→ backend/runtime
→ ActionContract/capability adapter
→ authoritative gameplay
~~~

Do not make runtime Lua capability descriptors or Semantic Lab the primary S11 authoring authority. Do not create a second outcome execution engine beside ActionContract.

### S11A — foundation build and freeze before production migration

**Status:** ACCEPTED / RETAIN. S11A0-A8 foundation is implemented and current focused verification remains green. R5 repairs acceptance inventory integrity around the foundation; do not rebuild A0-A8.

Execution order is authoritative in `S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md`. Do not use foundation-doc local prose to reorder these subphases.

#### S11A0 — preflight, baselines, legacy ownership inventory
Verify repo/worktree truth; reconcile or explicitly baseline the two pre-existing DTCommon generated fingerprint drifts; freeze P0 defects as declarative fixtures; measure compile/runtime/save-size baselines; classify relevant legacy surfaces as KEEP_AUTHORITY / ADAPT / MIGRATE_LATER / RETIRE_AFTER_PARITY / GENERATED_DO_NOT_EDIT / UNRELATED. Do not migrate production dialogue.

#### S11A1 — canonical data-model freeze
Freeze the generic S11 structural model: EntityRef, ParticipantSet, RoleSpec/RoleBinding/cardinality, Predicate/Query, Action/SemanticOutcome, Effect/Modifier/Retention/MemoryResidue, TopicRef/EventRef/ActivityRef/MemoryRef/DomainRef, SemanticBeat/ConversationArchetype, state/input/repeat/postcondition and continuation/closure policy. Do not migrate production dialogue.

#### S11A2 — canonical source → IR → Portable Plan
Extend compact canonical source and CodeBuilder authoring to carry the frozen model through canonical IR and Portable Dialogue Plan. Use synthetic/minimal fixtures rather than production legacy families as compiler-development scaffolding.

#### S11A3 — Reference VM / PZ structural parity
Project the frozen model through both backends and prove equivalent structure/diagnostics before broad runtime integration.

#### S11A4 — canonical Dialogue Completeness Analyzer
Build reachability, outcome completeness, SCC/progress, continuation-obligation, role/cardinality, effect/modifier lifecycle, closure/residue, memory-continuity, typed/click ownership and fixture-coverage analysis over the final S11A1-A3 representation.

**Post-R8 status note:** backend analyzer is accepted and retained; the originally required Semantic Lab exposure of the same graph/report was missed and is now a mandatory R9 authoring-readiness gate.

#### S11A5 — existing-domain adapters
Connect portable contracts directly to existing authoritative RelationshipService, inventory services, morale/mood authority, ConversationMemory and ActionContract. This is infrastructure integration, not production dialogue migration. Do not introduce compatibility shims, fallback readers, duplicate registries/stores or dual execution paths.

#### S11A6 — memory/modifier runtime lifecycle
Finalize same-day/timed/permanent/until memory semantics, timed modifiers, game-time expiry, stacking/dedupe/aggregation and bounded scheduling.

#### S11A7 — compiler/runtime optimization
Add stable IDs, dependency indexes, required-fact projection, authoritative invalidation, compact lowering, incremental analysis, bounded expiry scheduling, compact persistence, opt-in traces and evidence-based performance/save-size budgets.

#### S11A8 — FOUNDATION FREEZE GATE
Before any production semantic-family migration, prove canonical model stability; source→IR→Portable Plan completeness; Reference VM↔PZ structural parity; completeness coverage over the final model; direct authoritative adapters; stable memory/modifier lifecycle; deterministic/no-op CodeBuilder generation; dependency/optimization metadata; zero-LLM semantic correctness; and two-person dialogue as a specialization of the generic participant/role model.

**Migration barrier:** production legacy semantic-family migration is forbidden before S11A8 passes.

**CodeBuilder rule:** dialogue/semantic migrations must edit canonical CodeBuilder source/recipe inputs and regenerate downstream through `tools/semantic_harness/codebuilder/generation_recipe.json` with recipe-driven reconcile. Generated Lua/registries/manifests/translations are downstream-only and must not be hand-edited.

**No-shim rule:** migrated project-owned internal code is replaced, not preserved via compatibility wrappers, fallback readers, dual registries/writes or parallel old/new semantic paths. After parity and caller-zero proof, retire/delete obsolete code in the same migration phase. Preserve compatibility only for a verified external/public contract explicitly required by the user.

**Gate:** S11A0-S11A8 are accepted; no production migration occurred before the freeze; all generic contracts are stable and portable; generation is deterministic/no-op; performance/save-size baselines and budgets exist; no parallel semantic/effect/modifier/memory/optimization authority or legacy compatibility path remains.

### Historical S11 R0-R4 post-implementation repair order

R0-R4 landed and are retained as historical phase evidence. R5 and R6 are retained as accepted historical repair phases; R7A atomic acceptance work is retained, while R7B's final closure claim was superseded by R8.

Historical order:

1. **R0 acceptance-authority repair** — derive a constrained-family acceptance manifest from `S11_BRANCHING_DIALOGUE_AUDIT.md`; require every maintained family to be `CANONICAL_STATEFUL`, `EXPLICIT_PRESENTATION_ONLY`, `REFERENCE_GOOD_REGRESSION`, or `RETIRED`; fail required stateful families that lack canonical policy; add negative tests; diagnose the current retained Core Lua acceptance failure.
2. **R1 finish S11B retirement** — canonical Identity parity, caller-zero, remove superseded `Flow_Identity.lua`; no shim.
3. **R2 redo/finish S11C canonically** — recipe-author companion-command state policy, Needs and Greeting; remove family-specific semantic admission from generic dispatch Lua; caller-zero and delete superseded flows.
4. **R3 execute S11D** — close every maintained branching-audit row, including transition-refresh and repeat-policy cases.
5. **R4 rerun S11E** — canonical nine-suite acceptance, completeness over mandatory inventory, recipe reconcile/determinism, Kahlua/static guards, caller-zero retirement, exact docs/vector/fingerprints.

Do not broad-migrate dialogue during R0. Do not rewrite reference-good domains merely to make them look migrated; classify and regression-protect them explicitly.

### S11B — identity reference migration

**Status:** ACCEPTED (R1 accepted). Canonical Identity policy and trigger/flow metadata are authored in `identity_exchange_responses.json`, `Flow_Identity.lua` is deleted with caller-zero, and `Registry.Get("identity")` passes smoke + 22/22 declarative Identity fixtures.

### S11C — companion commands + flow reference migrations

**Status:** ACCEPTED (R2 accepted). Companion commands (`follow`, `stay`, `camp`, `return_home`), Needs (`flow_needs_exchange.json`), and Greeting (`flow_greeting_exchange.json`) are canonically authored in `psychopatz.convo-engine.v1` recipes; `Input_Actions_Dispatch.lua` delegates to generic `S11PolicyEvaluator.EvaluateStatePolicy`; `Flow_Needs.lua` and `Flow_Greeting.lua` are deleted with caller-zero.

### S11D — full constrained-domain sweep + real surfaces

**Status:** ACCEPTED. All 25 maintained rows in `S11_BRANCHING_DIALOGUE_AUDIT.md` and `constrained_family_manifest.json` have exact atomic `auditClaims` ownership, including `task_native_projection_parity` on `audit.task.parameterized` (`test_native_task_projection_parity_lifecycle_and_duplicate_suppression` / `pnc_native_task_projection_parity_smoke.lua`).

### S11E — retained acceptance and reproducible closure

**Status:** NOT ACCEPTED — canonical results are 9/9, but `real_provider_worker` mutates live DynamicTrading generated output. Exact-vector closure remains open under R8D.

### S11R5 — post-R4 closure integrity repair

**Status:** HISTORICAL / ACCEPTED. Retained the closed-set 25-row audit inventory, exact source/test-ID validation, event/disband acceptance, canonical `ProjectReply`, and removed hard-coded recruitment reply mapping. Historical record: `S11_POST_R4_CLOSURE_AUDIT_REPAIR.md`.

#### R5A — acceptance inventory + ownership integrity

Make the constrained-family acceptance inventory closed-set/machine-complete against the maintained branching audit. Make acceptance ownership machine-verifiable rather than accepting any non-empty path. Add negative tests for omitted/extra audit rows, missing owner sources/IDs, owner-claim mismatch, and canonical-stateful policy omission.

#### R5B — residual S11D lifecycle closure

Close parameterized task state parity; quest offer→accept→active→ready→rewarded→repeat conversation projection; event response-window expiry ownership; disband destructive confirmation/presentation policy; and settlement admission/ambient visit post-transition refresh/retirement. Reuse existing authoritative services; do not create ConvoEngine shadow state.

#### R5C — generic runtime policy/reply projection

Remove family-specific recruitment/proposal canonical reply projection from generic `Input_Actions_Dispatch.lua`. Consume compiled `replyOutcome` and canonical reply/consequence projection generically. Domain-specific action execution may remain behind typed dispatch after canonical `dispatch` admission.

#### R5D — reproducible final closure

Rerun focused R5 tests, full semantic-harness, canonical nine-suite acceptance, strict closed-set Completeness, CodeBuilder reconcile, integrity/determinism, Kahlua/static and caller-zero guards. Reconcile all current docs by replacement rather than appending stale states. Final HANDOFF records exact participant commits plus SHA-256 residual-work fingerprints. No push/publication.

**Gate:** SATISFIED for historical R5 scope; later final-closure authority is R8.

### S11R6 — post-R5 final closure repair

**Status:** HISTORICAL / ACCEPTED. R6A explicit exact-test `auditClaims` enforcement, R6B production quest READY_TO_TURN_IN → REWARDED → repeat lifecycle, and R6C single generic canonical policy-admission seam are accepted and retained. Historical record: `S11_POST_R5_FINAL_CLOSURE_REPAIR.md`.

#### R6A — explicit exact-test acceptance claim ownership

Retain the closed-set 25-row audit inventory and exact source/test-ID lookup. Replace semantic `claimKeywords`/source-text inference with stable audit claim IDs explicitly declared by the exact owning fixture case / Python test method / Lua smoke test. Manifest repetition and keyword presence are not evidence. Add negative guards for missing/wrong claims, keyword-only false positives, Lua whole-file false positives, and stale renamed owners.

#### R6B — residual lifecycle/presentation acceptance

Complete the same production QuestService-backed conversation lifecycle through READY_TO_TURN_IN → REWARDED → repeat idempotence; prove representative parameterized-task suggestion/response-channel parity across active/terminal state; and prove settlement/ambient public conversation affordances refresh/retire after authoritative success. Reuse existing authorities; do not create ConvoEngine shadow state.

#### R6C — single generic canonical policy-admission seam

Evaluate canonical action policy exactly once for any action with a policy plan before domain-specific action routing. Domain-specific mutation routing may still name recruitment/proposal, but generic dispatch must not name a family solely to decide whether canonical policy runs. Preserve generic `ProjectReply` projection and target-hint requirements.

#### R6D — reproducible final closure

Run explicit-claim guards, full retained semantic/provider/GUI/static acceptance, quest/task/settlement R6 regressions, canonical nine-suite acceptance, recipe reconcile, integrity/determinism, caller-zero guards and `git diff --check`. Rewrite all current continuity docs to one state and record exact participant commits plus live residual path counts/SHA-256 fingerprints. No push/publication.

**Gate:** SATISFIED (historical R6; final two atomic acceptance proofs and continuity reconciliation completed in R7).

### S11R7 — final atomic acceptance-proof closure

**Status:** HISTORICAL / SUPERSEDED FINAL-CLOSURE CLAIM. R7A atomic claim work and settlement/ambient behavior remain accepted. R7B's final developer-complete closure claim was superseded by R8.

Historical record: `S11_POST_R6_CLOSURE_AUDIT_REPAIR.md`. Current repair authority: `S11_POST_R8_AUTHORING_READINESS_REPAIR.md`.

#### R7A — task + settlement/ambient atomic acceptance proof

**Status:** ACCEPTED. Added `task_conversation_projection_lifecycle` and proved the public `pnc:task.wait_at` affordance is present/actionable before dispatch and retired/projected after active/terminal transition (`test_parameterized_task_conversation_lifecycle_and_duplicate_suppression`). Replaced broad `settlement_ambient_admission_boundary` with atomic `settlement_admission_post_success_refresh` and `ambient_visit_post_success_refresh` claims. Retained the ambient owner (`test_ambient_visit_root_choice_refreshes_and_retires_after_start`) and added an exact settlement-admission conversation-level owner (`test_settlement_admission_root_choice_executes_authority_and_refreshes_conversation`) proving authoritative success → active-conversation refresh → stale affordance retirement → stale replay zero mutation.

#### R7B — final reproducible acceptance + continuity closure

**Status:** SUPERSEDED / NOT FINAL ACCEPTANCE. The recorded focused tests and generation/static evidence remain historical evidence, but fresh post-R7 audit disproved the reproducibility/native-parity assumptions behind the final closure: worker-only task-state projection does not certify native runtime, and canonical Core acceptance is order/concurrency dependent.

**Gate:** SUPERSEDED BY R8 — R7A atomic claims are retained; final closure requires R8 native parity plus reproducible acceptance.

### S11R8 — native-parity and acceptance-reproducibility repair

**Status:** PARTIAL — R8A accepted; original R8B race/accounting repairs retained; R8C final closure invalidated by live-repo mutation found after acceptance. Continue with R8D.

Completed repair plan: `S11_POST_R7_NATIVE_PARITY_ACCEPTANCE_REPAIR.md`.

#### R8A — native task-state projection parity

**Status:** ACCEPTED. Replaced worker-only `Runtime.taskStates` with the shared bounded `taskProjection` contract (`PNC_SemanticTaskProjection.lua`) produced natively in `PNC_ConversationComposer_Context.lua` and `Input_ContextProjection.lua`, updated in `Input_Tasks.lua` and `Input_TaskDispatch.lua`, consumed by `Suggestions_Capabilities_Rows.lua`, and matched by the headless worker. Added `task_native_projection_parity` to `audit.task.parameterized` owned by `test_native_task_projection_parity_lifecycle_and_duplicate_suppression` (`tests/pnc_native_task_projection_parity_smoke.lua`) plus worker parity guards.

#### R8B — canonical acceptance isolation and deterministic accounting

**Status:** ACCEPTED. Moved `test_psdl_semantic_domain_decomposition.test_real_source_variant_and_new_subdomain_are_local` into an isolated `tempfile.TemporaryDirectory()` root, partitioned Core `tkinter` startup tests (`test_gui_startup`) into `tk_xvfb_gui` so `core_python` runs headlessly with zero skips, added accounting/ownership regressions in `test_compact_test_runners.py`, and proved `core_python` `jobs=1`/`jobs=4` (`307/307` PASS) and two consecutive canonical 9-suite `--jobs 4` runs (`9/9` PASS, `convoScopeOk=true`) from one exact vector.

#### R8C — exact-vector full closure

**Status:** NOT ACCEPTED — two 9/9 canonical runs were reproducible by result but `real_provider_worker` dirtied live DynamicTrading Manifest/Registry output. Superseded by R8D closure-integrity repair.

**Gate:** NOT SATISFIED — R8D must prove effect-free participant status and post-acceptance reconcile before R8 may close.

#### R8D — acceptance side-effect isolation and exact-vector closure

**Status:** ACTIVE. Repair generation-bearing tests that mix temporary source models with live adopter/output repositories; add participant-status side-effect guards; prove `real_provider_worker` and two canonical 9-suite runs leave all participant status bytes unchanged; run `reconcile.py --check` after acceptance.

Current authority: `S11_POST_R8_AUTHORING_READINESS_REPAIR.md`.

### S11R9 — Dialogue Completeness Workbench and authoring readiness

**Status:** NOT STARTED / MANDATORY BEFORE BULK CONTENT REWRITE.

The existing S11A4 backend analyzer is retained, but the originally planned Semantic Lab graph/report exposure is not implemented. There are zero GUI callers of `analyze_convo_completeness()`, and the primary Conversations pane does not make the full S11 state/repeat/postcondition/closure model first-class.

#### R9A — canonical authoring-report enrichment

Enrich the compiler-owned completeness report with source provenance, graph/witness/cycle paths, outcome matrices, closure classes, affected-family closure, and fixture/parity ownership as needed for authoring. Do not create UI-owned graph logic.

#### R9B — primary Dialogue Completeness Workbench

Add a first-class primary Semantic Lab surface/tab with batch health/filtering, compiler-derived family graph, diagnostic detail, and canonical-source navigation. Distinguish resolved terminal, continuation, domain obligation, bounded pending/deferred, warning, and invalid paths.

#### R9C — complete semantic authoring controls + structural scaffolding

Expose `statePolicy`, `inputPolicy`, `repeatPolicy`, `postconditions`, `closure`, roles/cardinality, continuation, outcome coverage, and memory/domain references through compiler-owned descriptors/schema. Add previewable structural scaffolds through ConvoTransaction/CodeBuilder; never invent final prose or hand-edit generated output.

#### R9D — GUI acceptance and rewrite gate

Prove canonical report parity, navigation, representative invalid/valid graph rendering, affected-family refresh, scaffold preview/apply discipline, and real Tk/Xvfb behavior. Only after R9D may `BULK_DIALOGUE_REWRITE_ALLOWED=true` be recorded.

**Gate:** broad dialogue/beat/behavior/realization rewriting is forbidden until R9A-R9D are accepted. The Workbench must consume the same compiler-owned completeness graph/report used by acceptance.


## Commit protocol

At each accepted cross-repository boundary, preserve unrelated work, stage only
exact phase-owned paths, commit changed ProjectHoomans and DynamicTrading paths
first, reconcile Core `PROGRESS.md` and replace `HANDOFF.md`, commit Core last,
then verify all three HEADs and residual dirty work. Use existing `main` branches.
Never reset, stash, discard, overwrite uncertain work, broad-stage, push, amend,
rebase, force-update, publish, or launch native Project Zomboid without explicit
authorization.
