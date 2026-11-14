# Semantic Harness Compact & Future-Proof Architecture

**Date:** 2026-11-14
**Scope:** PsychopatzCore Semantic Harness + ProjectHoomans + DynamicTrading provider integration
**Status:** normative design for ROADMAP S9

## Why this document exists

S9 is not a request to make the harness smaller by blindly splitting or deleting
files. The objective is **authority compression**:

- fewer public concepts;
- fewer overlapping APIs;
- fewer places that reinterpret ConvoEngine;
- fewer UI surfaces that expose the same data differently;
- one extensibility mechanism for future providers;
- bounded, discoverable operations for humans and coding agents.

A modular implementation may still contain many small files. Compactness is
measured primarily by **how many authorities, contracts and choices a caller
must understand**.

## Measured current shape

Fresh source measurements on 2026-11-14, excluding the harness virtualenv and
`__pycache__`:

    Semantic Harness Python files                 277
    Semantic Harness Python LOC                71,593

    codebuilder                                  25,340 LOC
    ui                                           17,530 LOC
    testing                                       7,537 LOC
    runtime                                       3,802 LOC
    studio                                        3,333 LOC
    inspection                                    2,895 LOC
    providers                                       957 LOC

Large coordination surfaces:

    codebuilder/service.py                       2,729 LOC
      methods                                        97
      public methods                                 66

    entrypoints/cli.py                           1,425 LOC
      argparse add_argument calls                   123

    studio/convo_engine_authoring_pane.py          581 LOC
    codebuilder/convo_engine_studio_trace.py        455 LOC

Studio/UI contains 98 Python files and roughly 20.8k LOC when `studio/` and
`ui/` are combined.

These numbers are **diagnostic**, not deletion targets. The strongest
compactness opportunities are the 66-method service surface, overlapping CLI
entrypoints, repeated repository discovery, repeated semantic interpretation,
and legacy panes that no longer have live canonical data.

## Compactness principles

### 1. One authority per question

A caller should have exactly one answer to each of these questions:

    What repositories/providers are active?
        -> WorkspaceCatalog

    What ConvoEngine families exist and where?
        -> ConvoCatalog

    Is this family/source valid?
        -> ConvoEngine compiler

    What changes if I edit/move/delete it?
        -> ConvoChangePlanner + affected closure

    What would runtime actually choose/render?
        -> production Lua ConvoProbe

    What artifacts would change?
        -> BuildPlanner

    How do I apply the approved change?
        -> ConvoTransaction

    What operations can this harness perform?
        -> OperationRegistry

Do not add a second helper that answers the same question with slightly
different assumptions.

### 2. Thin clients, strong shared services

GUI, CLI, tests and coding agents are clients of the same operations.

They may format inputs and outputs differently, but they must not own separate:

- source discovery;
- package routing;
- semantic evaluation;
- action-contract catalogs;
- cross-reference validation;
- build logic;
- compatibility rules.

### 3. Capability discovery, not adopter branches

The existing `semantic.provider_manifest.v2` system is the extension boundary.

ProjectHoomans, DTCommon, DTAbstract, DTHoomans and future providers already
declare capabilities, runtime bootstrap, module paths and repository identity.

The harness should ask:

    does the active workspace provide capability X?

rather than:

    if ProjectHoomans ...
    elif DynamicTrading ...

New compatible mods should not require Core UI edits merely to appear in
discovery, source browsing or runtime probing.

### 4. Feature negotiation, never silent semantic fallback

If a production worker does not expose a required ConvoEngine probe capability,
Studio disables that behavioral preview with an explicit reason.

It must **not** silently fall back to a simplified Python evaluator.

Structural compiler preview is allowed without a worker. Runtime-behavior claims
require production-backed evidence.

### 5. Search-first and lazy, not catalog-dump-first

566 families are already enough that full document loading is unnecessary.
Future thousands of families must remain cheap.

The harness should load:

    compact FamilySummary index
      -> search/filter
      -> one selected full FamilyDocument
      -> one bounded affected closure
      -> one bounded trace

Never send or render the full source corpus when a bounded query is sufficient.

## Target architecture

The future-proof harness is organized around six stable ports.

### Port A — WorkspaceCatalog

Owns repository/provider discovery.

Input:

- current working directory;
- optional explicit repository overrides;
- provider manifests.

Output is one immutable `WorkspaceSnapshot`:

    schema
    workspaceFingerprint
    providers[]
      providerID
      repository
      repositoryKind
      capabilities[]
      materializationModes[]
      runtimeModules[]
      conversationSources[]
    owners{}
    warnings[]

Rules:

- one discovery implementation for GUI, CLI, audit and CodeBuilder;
- explicit overrides win;
- provider manifests are the normal extension mechanism;
- unresolved required owners fail closed;
- no sibling-directory guesses inside Studio panes;
- no permanent assumption that the primary repository is ProjectHoomans.

The current provider manifests are already sufficient foundation. S9 should
normalize their conversation-source declaration into one service-level view
without inventing another manifest format.

### Port B — ConvoCatalog

Compiler-owned read model over canonical ConvoEngine source.

A lightweight `FamilySummary` should contain only agent/UI discovery data:

    id
    kind
    owner
    sourcePath
    sourceFingerprint
    fieldsPresent[]
    locales[]
    executeAction?
    incomingReferenceCount
    outgoingReferenceCount
    generatedArtifactCount

Full source is loaded only when requested.

The catalog also owns:

- family search/filter;
- source -> family lookup;
- family -> generated routing;
- incoming/outgoing semantic references;
- bounded affected closure;
- model/workspace fingerprint.

Studio, Source Explorer, CLI and audits consume this same index.

### Port C — OperationRegistry

Expose a small versioned command/query vocabulary instead of dozens of
top-level public service methods.

Initial stable operation families:

    workspace.describe

    convo.catalog
    convo.get
    convo.impact
    convo.validate
    convo.simulate

    convo.change.preview
    convo.change.apply

    convo.build.preview
    convo.build.apply

    convo.audit

Operations have descriptors:

    id
    mode              query | command
    requiredCapability?
    workerRequirement none | optional | required
    mutatesCanonical
    mutatesRuntime
    inputVersion
    outputVersion

GUI and CLI dispatch the same operation IDs.

Typed Python convenience wrappers may exist, but the registry is the canonical
discoverable surface for agents and future clients.

### Port D — ConvoTransaction

All canonical family mutation uses one change model:

    ChangeSet
      operation       create | edit | move | delete
      familyID?
      expectedFingerprint?
      requestedOwner?
      requestedIdentity?
      document?

Preview pipeline:

    WorkspaceSnapshot
      -> resolve owner/package
      -> compile candidate
      -> build global reference index
      -> validate incoming/outgoing references
      -> compute affected closure
      -> render changed-artifact plan
      -> return ChangePreview

Apply pipeline:

    accepted ChangePreview
      -> reacquire workspace generation lock
      -> recheck source/workspace fingerprints
      -> write canonical source atomically
      -> regenerate planned output
      -> verify generated hashes
      -> return ChangeResult

UI code never:

- chooses repository roots;
- calls `Path.unlink()` on canonical source;
- renames canonical files directly;
- writes generated output;
- bypasses fingerprint protection.

### Port E — production Lua ConvoProbe

Behavioral truth comes from the same Lua runtime modules used by the game.

Use one versioned worker family, conceptually:

    CONVO_PROBE

with bounded read-only operations:

    describe
    render_role_text
    evaluate_predicate
    expand_slots
    collect_affordances
    score_affordance
    select_npc_affordance
    select_reply
    resolve_after
    list_action_contracts
    project_action_result

The worker returns a `TraceEnvelope`:

    schema: semantic.harness.convo_trace.v1
    operation
    familyID?
    contextFingerprint
    result
    trace[]
      stage
      authority
      decision
      reason?
      boundedCandidates?
    warnings[]

Unknown future trace stages are displayed generically rather than rejected.

For Studio preview, action dispatch remains non-mutating: authors may provide a
hypothetical bounded public result and ask production ConvoEngine how it would
select the reply/after path.

Mutation-capable integration tests remain isolated harness scenarios and are not
the default Studio preview path.

### Port F — BuildPlanner

Compilation and artifact rendering are separated from live-tree writes.

Preferred model:

    canonical model
      -> RenderPlan in memory/temp root
      -> ArtifactPlan
           owner
           relativePath
           hash
           status
      -> compare
      -> optional apply

Determinism checks render to isolated temporary roots and compare hashes. They
do not rewrite/prune the live generated tree twice.

A single workspace-scoped generation lock protects live apply. The lock lives
outside Project Zomboid `media/` and is keyed by the WorkspaceSnapshot.

Future incremental generation may render only the proven affected owner/closure,
but **global identity/reference validation still runs first**. If incremental
safety cannot be proven, fall back to full render.

## Shrinking the service facade

`SemanticLabAuthoringService` currently has 66 public methods. S9 should not
replace it with another giant class.

Preferred shape:

    HarnessContext
      .workspace
      .convo
      .runtime
      .build
      .audit
      .compat      # temporary, explicitly removable

The existing service may remain as a compatibility facade during migration, but
new GUI/CLI code should call the component ports or OperationRegistry.

Compatibility wrappers must be:

- thin delegation only;
- marked deprecated/internal;
- covered by caller-zero removal tests;
- forbidden from adding new behavior.

### Soft complexity review triggers

These are review triggers, not artificial pass/fail line-count laws:

- public facade exceeds ~20 stable operations;
- one coordinator file exceeds ~800 hand-written lines;
- one UI pane exceeds ~600 lines;
- CLI parser requires a bespoke flag for each new ConvoEngine field;
- a provider-specific ID appears in Core Studio code;
- the same field list/predicate/action contract is duplicated in two layers.

When triggered, first ask whether authority is duplicated. Do not split code
merely to satisfy a number.

## Future-proof ConvoEngine editor model

The editor should not hard-code every future language field in multiple places.

Compiler-owned `FieldDescriptor` metadata should describe authoring structure:

    path
    kinds[]
    role
    editorKind
    required?
    compactForms[]
    help
    order

Example:

    affordance.label
      role: button_label
      editorKind: localized_text

    say
      role: spoken_action
      editorKind: realizations

    reply
      role: response
      editorKind: outcome_map

    execute
      editorKind: action_contract

    when
      editorKind: predicate

This metadata is **presentation metadata**, not a second validator. The compiler
remains authority.

Benefits:

- Studio can add structured support for a new field without duplicating grammar;
- CLI help can describe the same model;
- unknown future fields can round-trip safely in Advanced JSON;
- older Studio versions preserve unknown fields instead of deleting them.

## Compact Studio information architecture

Keep the existing five broad product areas only where they remain useful, but
make conversation authoring itself much simpler.

Target Studio conversation surface:

    Conversations
      left: search + bounded family list
      center: structured family editor
      right/bottom: preview + trace

    Source / Impact
      source owner/path/fingerprint
      incoming/outgoing refs
      generated artifacts
      affected closure

    Review
      validation issues
      wording/translation review
      build diff
      audit findings

Avoid separate first-class panes for a legacy Dataset Library, Dialogue Content
Registry, workflow composer or other source model when there is no live
canonical source behind it.

Advanced/raw views remain available behind one explicit Advanced control.

### SurfaceRegistry

Top-level/Studio surfaces may be described by a small Core-owned registry:

    id
    label
    requiredCapabilities[]
    order
    factory

This is only UI composition. Providers do **not** inject arbitrary UI code into
Core. Unsupported surfaces simply do not appear.

## Compact CLI for humans and agents

The main CLI should expose one ConvoEngine namespace rather than hundreds of
field-specific flags.

Conceptual interface:

    semantic-harness workspace describe

    semantic-harness convo list [query]
    semantic-harness convo show <family>
    semantic-harness convo impact <family>
    semantic-harness convo validate <source|family>
    semantic-harness convo simulate <family> --context FILE

    semantic-harness convo change preview FILE
    semantic-harness convo change apply FILE

    semantic-harness convo build preview
    semantic-harness convo build apply
    semantic-harness convo audit

Machine output defaults to bounded structured records. A compact
`workspace describe` result should be sufficient for a Luna-class agent to
discover available providers, capabilities and operation IDs without reading
the whole codebase.

Do not add one CLI flag for every future ConvoEngine field. Complex family
content travels as a canonical JSON document or compact change document.

## Caching and scale

Use fingerprint-keyed caches only for derived read-only data:

    WorkspaceSnapshot
    ConvoCatalog index
    compiled family projection
    generated ArtifactPlan
    read-only simulation trace

Cache key includes the relevant source/model/workspace fingerprints.

Rules:

- no cache is semantic authority;
- invalidation is fingerprint-based, not time-based;
- bounded LRU or per-session cache;
- persistent caches are optional and disposable;
- no cached rendered button list/transcript becomes game persistence.

## Extension story

A future compatible mod should need only:

1. a `semantic.provider_manifest.v2` provider declaration;
2. its canonical ConvoEngine source manifest/root;
3. runtime bootstrap that registers its semantic capabilities/action contracts;
4. optional adopter-specific worker/provider adapter only where production
   runtime access genuinely differs.

Then the harness should automatically gain:

- workspace discovery;
- source/family listing;
- source ownership;
- generated routing;
- generic validation;
- generic structured editing;
- production action-contract discovery;
- generic simulation/trace;
- audit/build participation.

No Core branch such as `if NewMod ...` should be required for ordinary
ConvoEngine participation.

## Compatibility quarantine

Legacy PSDL schema readers may survive only behind `compat`/migration APIs.

They must not appear in:

- primary Studio navigation;
- the main public OperationRegistry;
- new documentation examples;
- new provider contracts.

Removal sequence:

    migrate tests/callers
      -> caller-zero evidence
      -> remove public wrapper
      -> retain narrow reader only if still required
      -> eventually remove reader when fixture obligation ends

Git is the archive; dead authoring systems are not kept as UI options.

## Token-efficiency rules for coding agents

Default agent-facing commands must be bounded.

Good:

    workspace.describe
      -> providers + capabilities + counts

    convo.catalog query=camp limit=20
      -> compact summaries

    convo.get command.camp
      -> one family

    convo.impact command.camp limit=24
      -> bounded closure

    convo.simulate command.camp
      -> bounded trace

Bad:

- dump 566 full family documents;
- dump every generated Lua file;
- require reading the 2,729-line service to discover one operation;
- require knowing whether a function lives in the main CLI or ConvoEngine CLI;
- return raw production state when a small public projection is sufficient.

## S9 implementation mapping

### S9H0 — regression-lock + architecture freeze

Add regression tests for the already reproduced defects and freeze this
document's six-port model before implementation.

### S9H1 — WorkspaceCatalog + ConvoCatalog

Unify participant/repository discovery and create the compact family/source
index. Migrate Studio family discovery and Source Explorer first.

### S9H2 — OperationRegistry + ConvoTransaction

Introduce the small operation surface and safe owner-routed change preview/apply
pipeline. Migrate GUI CRUD away from direct filesystem operations.

### S9H3 — production ConvoProbe

Add worker feature negotiation and production-backed read-only behavioral
simulation. Delete Python semantic-policy duplication after parity tests.

### S9H4 — compact Studio

Promote Conversations to the primary authoring surface, merge source/impact and
review workflows around the same family model, hide/remove dead zero-source
panes, and use compiler field descriptors for structured editors.

### S9H5 — compact CLI + compatibility caller-zero

Make the main CLI dispatch the same OperationRegistry. Move old PSDL
record-bucket APIs and missing legacy datasets behind compatibility quarantine,
then remove them after caller-zero.

### S9H6 — BuildPlanner + cache/lock

Make preview/determinism isolated from live output, add the workspace generation
lock, and introduce fingerprint-keyed derived caches where measurements show
benefit.

### S9H7 — acceptance and complexity audit

Run the existing S8R gates plus:

- operation inventory contains no overlapping public conversation authorities;
- Core Studio contains no provider-specific action-contract IDs;
- missing sources cannot advertise editable/ready;
- GUI and CLI resolve the same WorkspaceSnapshot and ConvoCatalog;
- production ConvoProbe parity covers every Predicate operation;
- unknown provider/family fields preserve round-trip behavior;
- determinism audit is isolated/concurrency-safe;
- compact agent bootstrap can discover workspace + operations without corpus
  dumps;
- legacy public PSDL CRUD is caller-zero or explicitly quarantined.

## Non-goals

- no generic plugin framework that allows arbitrary provider UI injection;
- no replacement for the existing provider manifest system;
- no second JSON schema validator beside the ConvoEngine compiler;
- no rewrite of accepted ConvoEngine runtime architecture;
- no giant universal command bus for unrelated Project Zomboid tooling;
- no microservice/network architecture;
- no mandatory persistent cache/database;
- no line-count-driven file splitting without an ownership reason.

## Completion definition

The harness is compact and future-proof when adding a normal new ConvoEngine
family, action contract, locale, provider, or optional language field does not
require editing multiple independent discovery, validation, simulation, UI and
CLI authorities.

The expected steady-state path is:

    provider/source declares capability
      -> compiler indexes it
      -> OperationRegistry exposes it
      -> Studio/CLI discover it
      -> production Lua ConvoProbe explains it
      -> BuildPlanner renders it

with no parallel hand-maintained interpretation.
