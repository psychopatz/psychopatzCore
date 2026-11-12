# Progress — Psychopatz Semantic Dialogue Language Standard

**Status:** COMPLETE — S0-S8 accepted after fresh three-repository audit.
**Branch:** existing `main` in all three repositories.
**Active phase:** S8 accepted.
**Completion boundary:** fresh three-repository S8 acceptance achieved.

## Mandatory ownership and scope

- PsychopatzCore owns the PSDL schema/language, Canonical Semantic Dialogue IR,
  compiler/normalizer, generic validation/predicates, actor-neutral references,
  typed slots/bindings, package routing, authoring service, and runtime contracts.
- ProjectHoomans and DynamicTrading/DTCommon own only adopter records, adapters,
  gameplay-specific constraints, tests, and translations/content.
- Existing ResponsePlan, BranchOffers, Interaction Director, Scene Runtime,
  Semantic Social Conversation, SpeechRealization, and gameplay authorities
  remain runtime authorities. PSDL is authoring and compilation, not a second
  dialogue runtime.

## Phase truth

- **S0 ACCEPTED.** All three repositories are inventoried by the Core-owned
  machine-readable guard; new first-party additions to frozen old surfaces are
  rejected without rejecting legitimate adopter PSDL records or compatibility
  boundaries.
- **S1 ACCEPTED.** Core owns actor-neutral IR/reference/predicate contracts.
- **S2 ACCEPTED.** Core owns the only PSDL schema/compiler/normalizer.
- **S3 ACCEPTED.** Participant-neutral offers, ResponsePlan projection, typed
  slots/references, bindings, and runtime seams are proven.
- **S4 ACCEPTED for the corrective slice.** Maintained Core behavior, beat, and
  realization catalogs now use PSDL module records. Interaction Director and
  SpeechRealization remain the accepted consumers.
- **S5 ACCEPTED.** The
  surviving Core source inventory is PSDL plus explicitly justified recognition,
  semantic-memory, and routing data. The remaining response/flow/UI/text/
  behavior/beat/realization authorities were migrated and superseded sources
  removed. DynamicTrading wording is in the final DTCommon PSDL trader source.
- **S6 ACCEPTED.** Output fan-out is packed into bounded deterministic shards;
  cache-free inventories, package routing, source lineage, Kahlua checks, and
  two-pass generation all pass.
- **S7 ACCEPTED.** Core service CRUD/preview/write APIs remain the sole
  authority and Semantic Lab exposes a structured PSDL authoring tab. Native
  visual/runtime acceptance remains user-owned.
- **S8 ACCEPTED.** Fresh exhaustive acceptance passed across Core,
  ProjectHoomans, and DynamicTrading/DTCommon: ownership, source closure,
  actor-neutral runtime projections, tests, audits, deterministic generation,
  Kahlua compilation, cache-free evidence, and committed handoff all pass.

## S5 corrective source evidence

`Docs/semantic_dialogue_language_standard/S5_CORE_SOURCE_AUDIT.json` is the
machine-readable per-file inventory. It records:

- 42 surviving Core Conversation JSON sources, including 25 maintained PSDL
  record files, six recognition/NLU files, nine semantic-memory backstory fact
  catalogs, and two routing manifests;
- explicit reasons why recognition and fact-value data are not competing
  dialogue authoring authorities;
- production references, generated output boundaries, compatibility status,
  final PSDL destination, and migration status for every maintained source;
- 56 deleted superseded first-party authoring files and their final destinations.

The strict Core source audit reports 41 source JSON files (the manifest itself
is excluded from that source count), zero issues, zero hard/preferred oversize
files, and zero cache/interpreter/editor artifacts. The PSDL authoring guard
for Core, ProjectHoomans, and DynamicTrading reports zero violations.

Surviving Core source layout is now:

```text
sources/conversation/manifest.json
sources/conversation/text/manifest.json
sources/conversation/patterns/**/*.json                 recognition authority
sources/conversation/text/memory/backstory/*.json       semantic-memory facts
sources/conversation/psdl/**/*.json                     maintained PSDL records
```

No maintained Core `flows/`, `responses/`, `ui/`, `beats/`, `behaviors/`, or
legacy `realization/` authoring tree remains. No new Legacy/Compat/Old/V1 or
migration-copy tree was created.

## Current validation evidence

- Core full semantic harness: **112/112 passed**.
- Core GUI shell/startup plus PSDL tests: **22/22 passed**.
- ProjectHoomans repaired migration-facing conversation tests:
  `pnc_conversation_smoke` and `pnc_psdl_core_response_offer_smoke`: **2/2 passed**.
- ProjectHoomans broad semantic/conversation/PSDL sweep, including the
  NPC↔NPC scene presentation regression: **51/51 passed**.
- DynamicTrading trader/conversation/PSDL focused set: **9/9 passed**.
- Core, ProjectHoomans, and DTCommon generated Conversation trees pass the
  Kahlua compatibility scan: **42/208/5 files, zero errors/warnings**.
- Deterministic two-pass generation: **255 Conversation output hashes,
  identical on both passes**.
- Current generated Conversation scale after packing:
  - Core: 42 files / 973,739 bytes;
  - ProjectHoomans: 208 files / 5,503,687 bytes;
  - DynamicTrading: 5 files / 72,834 bytes.
  The combined builder reports 457 generated downstream artifacts. Hoomans'
  304,306-byte manifest has zero local declarations. PSDL runtime catalogs are
  packed to bounded shards while preserving package routing, source lineage,
  deterministic generation, and lookup IDs.

## S7 Semantic Lab surface

`SemanticLabAuthoringService` remains Core-owned and now indexes manifest-routed
PSDL sources across all three repositories. `PSDLAuthoringPane` is exposed in
Semantic Lab's Developer Tools and provides:

- source browse/select with owner, shard, record IDs, and source lineage;
- create, edit, duplicate, delete, reorder, validate, preview, and explicit
  write operations through the shared service;
- dialogue/behavior/beat/realization kind selection;
- speaker/addressee participant editing, generic target, typed slots and
  references;
- predicate/collection constraints, bindings/resolvers, turns, nested offers,
  transitions, behavior candidates, beat entry/maintain/exit, realization
  translations/forms, and EN/TL fields;
- actor-neutral speaker/addressee/target preview context and a bounded
  predicate → beat → behavior → variant → offer trace;
- source fingerprint/owner routing and compile diagnostics. Generated output
  remains downstream-only.

The existing runtime-oriented editors remain compatibility views; they do not
own a second PSDL format or compiler.

## Completion boundary

All developer-side S8 gates pass and all phase-owned paths are committed.
Only optional native Project Zomboid feel/visual/live acceptance remains
user-owned; it is not required for this developer-side objective.
