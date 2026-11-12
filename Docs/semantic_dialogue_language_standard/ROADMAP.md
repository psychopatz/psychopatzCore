# Roadmap — Psychopatz Semantic Dialogue Language Standard

**Parent status:** IN PROGRESS — the previous S8 completion claim was reopened by fresh audit on 2026-11-13.
**Primary/owning repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Mandatory adopters:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
**Developer completion boundary:** S8. No push, PR, tag, release, Workshop publication, or native Project Zomboid drive without explicit authorization.

## Objective and ownership

Make PSDL the de-facto first-party semantic conversation authoring standard in
all three repositories. PsychopatzCore physically and architecturally owns the
PSDL schema/language, Canonical Semantic Dialogue IR, parser/compiler/
normalizer, generic validation/predicates, actor-neutral participant/reference
contracts, typed slots/bindings, package routing, reusable authoring service,
and reusable runtime contracts.

ProjectHoomans and DynamicTrading/DTCommon are adopters. They may own domain
records, translations/content, adapters, tests, and gameplay-specific
constraints. They must not contain another schema, IR, compiler, generic
predicate evaluator, binding engine, authoring service, or semantic dialogue
runtime.

PSDL compiles into accepted authorities: Core semantic NLU/candidate machinery,
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
- **S6 — final cleanup/scaling: ACCEPTED.** Deterministic two-pass generation,
  cache-free inventory, package routing, Kahlua checks, bounded packed PSDL
  catalogs, and output measurements pass.
- **S7 — PSDL-native Semantic Lab: ACCEPTED.** The structured PSDL authoring
  tab consumes the Core service and supports source/record CRUD, participants,
  typed contracts, predicates, offers, behavior/beat/realization fields,
  diagnostics, lineage, actor-neutral preview context, and trace. Native live
  Project Zomboid acceptance remains user-owned.
- **S8 — exhaustive acceptance: NOT ACCEPTED.** Attempt only after S4-S7 close
  freshly across all three repositories.

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

### S7

The actual Semantic Lab must expose the existing Core authoring service, not a
second editor format. The PSDL-native surface must support browse/select source;
create/edit/duplicate/delete/reorder records; kind selection; participants and
speaker/addressee/target; predicates including collection constraints; typed
slots/references; bindings/resolvers; locale variants and EN fallback; turns,
offers, transitions; behavior/beat entry/maintain/exit/candidates; realization
forms/translations; source lineage; compile diagnostics; adjustable preview
speaker/addressee/target/context; player↔NPC and NPC↔NPC preview; fuzzy/entity
resolution inspection where applicable; and predicate → beat → behavior →
variant → offer trace.

### S8

Freshly prove that PSDL is the only maintained first-party semantic dialogue
authority across Core, Hoomans, and DynamicTrading; old node/choice/outcome and
static-suggestion authorities are gone except explicitly justified recognition
or compatibility boundaries; actor permutations, typed references, bindings,
collection predicates, fuzzy safety, shared offers, nested/multi-turn dialogue,
modular beats, mixed scenes, data-driven locales, Core ownership, adopter-only
content, focused/broad tests, deterministic generation, bounded output, cache-free
audits, and committed job documents all pass. Do not call the final checkpoint
CLEAN while phase-owned files remain untracked.

## Commit protocol

At each accepted cross-repository boundary, preserve unrelated work, stage only
exact phase-owned paths, commit changed ProjectHoomans and DynamicTrading paths
first, reconcile Core `PROGRESS.md` and replace `HANDOFF.md`, commit Core last,
then verify all three HEADs and residual dirty work. Use existing `main` branches.
Never reset, stash, discard, overwrite uncertain work, broad-stage, push, amend,
rebase, force-update, publish, or launch native Project Zomboid without explicit
authorization.
