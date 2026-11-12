# Roadmap — Psychopatz Semantic Dialogue Language Standard

**Parent status:** IN PROGRESS — S0-S4 ACCEPTED; continuing automatically through S5-S8.
**Primary/owning repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Mandatory adopter repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
**Mandatory adopter repository:** `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
**Developer completion boundary:** S8.
**Publication:** no push / Workshop publication without explicit user authorization.

## Parent objective

Make PSDL the de-facto first-party semantic conversation authoring standard so new and migrated dialogue is easy to add, modular, actor-neutral, locale-ready, semantic-first and reusable across player↔NPC, NPC↔player, NPC↔NPC and multi-participant conversations.

**PsychopatzCore is the physical and architectural owner of the PSDL language, schema, canonical IR, compiler, generic validation, generic predicate/reference/binding contracts and shared authoring service.** ProjectHoomans and DynamicTrading/DTCommon are mandatory adopters that own only their domain-specific PSDL records/adapters and gameplay-specific constraints. Neither adopter may contain a duplicate PSDL compiler/runtime authority.

The completed system must eliminate split first-party dialogue authoring authority rather than add another layer beside it, and it must prove adoption across all three repositories before S8 can pass.

## Accepted foundation to preserve

Do not reimplement accepted runtime systems unless evidence proves a missing contract:

- PsychopatzCore semantic NLU/candidate machinery;
- contextual semantic evidence and actor projections;
- ResponsePlan multi-turn delivery;
- BranchOffer / generated affordance concepts;
- Interaction Director behavior/beat arbitration;
- Scene Runtime and Semantic Social Conversation;
- relationship/knowledge/gameplay domain authorities;
- SpeechRealization and translation infrastructure;
- CodeBuilder deterministic generated-artifact discipline.

## S0 — exact authoring inventory and zero-new-legacy guard

**Status:** ACCEPTED on 2026-11-12. Machine-readable evidence is maintained in
`S0_AUTHORING_INVENTORY.json`; the Core-owned guard passes against the current
three-repository worktrees and focused fixtures.

Inventory every maintained first-party conversation authoring surface across **PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon**. All three repositories are in mandatory scope from S0 onward; do not defer DynamicTrading discovery as optional adopter work.

Classify at least:

- common Conversation `Definitions` nodes/choices/outcomes;
- CodeBuilder `content`, `patterns`, `flows`, `responses`, `ui`, `behaviors`, `beats`, `realization` and text sources;
- hard-coded dialogue/suggestion wording in Lua;
- manual translation-only dialogue catalogs;
- generated artifacts;
- external compatibility boundaries.

Create machine-readable audit output showing canonical owner, callers, generated outputs and intended PSDL destination.

Add a guard that prevents **new** first-party authoring from being added to frozen superseded surfaces while migration is in progress. The guard must not require copying existing content into a `Legacy/` tree.

**Gate:** current split surfaces are evidence-backed; new first-party dialogue additions to frozen old surfaces fail focused validation; unrelated external compatibility is not falsely rejected.

## S1 — canonical IR, reference model and predicate v2

**Status:** ACCEPTED on 2026-11-12. Core owns the canonical IR and shared
predicate contract; the ProjectHoomans generic evaluator now routes through
Core, DynamicTrading was audited without adding a duplicate mechanism, and
the actor-swapped contract gate passes.

Implement the shared canonical Semantic Dialogue IR and actor-neutral reference model **in PsychopatzCore**. Adopters may project their domain context into this Core contract; they may not implement parallel IR/predicate/reference engines.

Required:

- `speaker`, `addressee`, `target`, participant/reference/slot contracts;
- bidirectional directed relationship projections;
- typed entity/reference/slot metadata;
- public/private context path registry;
- shared predicate normalization;
- `contains`, `not_contains`, `contains_any`, `contains_all`;
- compile/runtime bounds and traceability;
- no player/NPC-specific canonical variable requirement.

Preserve existing predicate/runtime behavior through adapters where necessary, but do not create a second evaluator.

**Gate:** controlled fixtures prove the same predicate/dialogue context works with player↔NPC and NPC↔NPC actor swaps, including trait, gender/identity, relationship, role/capability and situation constraints.

**Evidence:** `tools/semantic_harness/codebuilder/semantic_dialogue_ir.py`,
the Core Lua semantic IR/predicate/state contracts, the Hoomans Core predicate
seam, and `tests/psychopatz_semantic_dialogue_contract_smoke.lua`; 100 Core
semantic harness tests and the changed-file Kahlua scan pass.

## S2 — PSDL parser/compiler and language validation

**Status:** ACCEPTED on 2026-11-12. The Core-owned compiler, language
validation, deterministic runtime plan projection, and authoring-service
preview seam pass the representative multi-kind fixture; no adopter compiler
or schema copy was added.

Implement `psychopatz.semantic.dialogue-language.v1` as the canonical authoring envelope **inside PsychopatzCore's CodeBuilder/tooling and reusable runtime contract surface**. ProjectHoomans and DynamicTrading must consume this Core implementation; a compiler/schema copy in either adopter fails S2.

Required initial kinds:

- `dialogue`;
- `behavior`;
- `beat`;
- `realization`.

Implement:

- friendly syntax sugar → canonical IR normalization;
- stable IDs independent of physical path;
- owner/package routing;
- inline locale maps with EN fallback;
- placeholder/binding validation;
- reference/slot validation;
- cross-module reference validation;
- deterministic generation;
- bounded diagnostics/source lineage.

Existing old formats may have bounded migration readers, but no new checked-in compatibility copy of source records is allowed.

**Gate:** representative PSDL fixtures compile deterministically into existing runtime-compatible artifacts; malformed/ambiguous source fails with precise diagnostics.

**Evidence:** `tools/semantic_harness/codebuilder/psdl_compiler.py`,
`tools/semantic_harness/tests/test_psdl_compiler.py`, the Core service preview
methods, and the 105-test semantic harness. Runtime plans use existing
ResponsePlan/offer-shaped contracts and Core package routing.

## S3 — turns, bindings, slots and participant-neutral offers

**Status:** ACCEPTED on 2026-11-12. Core owns the semantic offer and text
binding contracts; PSDL response plans project into the existing ResponsePlan
and BranchOffers authorities, and the Hoomans adopter façade preserves the
public path without duplicating generic logic.

Make ordinary interactive dialogue fully expressible in PSDL.

Required:

- compact simple-response syntax;
- canonical multi-turn response syntax mapping to ResponsePlan;
- implicit `{speaker.name}`, `{addressee.name}`, `{target.name}` bindings;
- custom typed resolver bindings;
- typed slots for person/item/location/faction/settlement/etc.;
- response variants with shared predicates;
- offers that are semantic affordances rather than UI-owned buttons;
- consumer policy supporting participant/player/NPC;
- nested semantic offer/navigation composition without a second UI graph.

**Gate:** one source definition demonstrates translated multi-turn dialogue with dynamic target names and nested offers, consumed as a real player response surface and as an NPC semantic affordance without reparsing rendered text.

**Evidence:** Core `PsychopatzSemanticOffer.lua` and
`PsychopatzSemanticTextBinding.lua`, PSDL runtime-plan projection, the Core
semantic smoke fixture, and Hoomans
`tests/pnc_psdl_core_response_offer_smoke.lua`; 105 Core tests and changed-file
Kahlua scans pass.

## S4 — behaviors and beats under PSDL

**Status:** ACCEPTED on 2026-11-12. Core PSDL behavior/beat records now
validate against and project into the existing Interaction Director contracts;
no PSDL-specific beat director or wording authority was added.

Migrate behavior/beat authoring to PSDL while preserving the accepted Interaction Director.

Required:

- behaviors remain reusable semantic strategies;
- beats retain entry/maintain/exit, candidate relevance, cooldown, max turns and groups;
- beat authoring uses the same context/predicate language as dialogue;
- simple dialogue does not require a beat;
- beats reference semantic behaviors rather than wording files;
- beat/source diagnostics remain explainable;
- no parallel “PSDL beat director”.

Prove argument/reconciliation/suspicious-first-contact parity first.

**Gate:** existing representative beat/director tests pass from PSDL-generated definitions and NPC-generated semantic acts continue to enter at the semantic-stimulus layer.

**Evidence:** `render_psdl_director_plan` in Core's PSDL compiler, the
representative behavior/beat fixture in `test_psdl_compiler.py`, shared
predicate normalization, and the existing Core conversation validation/registry
contracts. The full Core semantic harness passes 106 tests.

## S5 — first-party domain migration and deletion

Migrate existing maintained dialogue by coherent semantic domain, not by individual string.

Recommended order:

1. greetings / identity / wellbeing;
2. personal / relationship / memory questions;
3. needs / health / gifts;
4. task / command / companion actions;
5. social apology / hostility / reconciliation;
6. navigation / knowledge / world/event dialogue;
7. remaining ProjectHoomans-specific conversation definitions and suggestions;
8. DynamicTrading/DTCommon trader conversation packs, static suggestions, semantic adapters and related first-party dialogue surfaces.

For each domain:

1. characterize current callers and semantic behavior;
2. create final PSDL source using final naming/layout;
3. compile/regenerate;
4. prove player typed input/button parity;
5. prove NPC affordance parity where applicable;
6. prove EN + optional-locale placeholder parity;
7. prove caller/reference zero for superseded first-party source;
8. delete the superseded source in the same accepted phase.

Do **not** move superseded content into `Legacy/`, `Compat/`, `V1/` or alias registries.

### Current S5 execution checkpoint

The first bounded adopter chunk is accepted: DynamicTrading/DTCommon trader
pack/static suggestions and ProjectHoomans companion `whats_up` check-in
suggestions now have final Core-compiled PSDL sources, parity smokes and
superseded-source removal. The next bounded chunk also moved Core's remaining
static suggestion authoring into final Core-owned PSDL shards, preserved all
ten records and refreshed both adopter projections. Continue S5 with the
remaining maintained ProjectHoomans and DynamicTrading surfaces; this
checkpoint does not close S5.

The next S5 chunk is also implemented pending its adopter-first commit
boundary: Core now emits registry-addressable PSDL runtime plans and explicit
downstream text catalogs, while ProjectHoomans owns six actor-neutral social
check-in dialogue records for wellbeing and small talk. The adopter adapter
projects those plans into the existing Core conversation block registry; it
does not introduce a PSDL runtime. The superseded Hoomans wellbeing/small-talk
definition files and five Core social text source files are removed, with
EN/TL placeholder parity and caller/reference-zero checks passing.

The following S5 chunk is implemented pending its commit boundary: the
ProjectHoomans greetings domain now has one final PSDL source containing the
20 relationship/time greeting records and hostile parley. Core preserves
variant text catalogs and registry module bounds, while the Hoomans adapter
maps the shared relationship/time predicates and existing ceasefire/portrait
authorities. The old greetings definition and 21 legacy Core text sources have
caller/reference-zero evidence and EN/TL parity.

**Gate:** each accepted domain has one maintained PSDL authoring authority and no duplicate first-party source.

### S5 settlement-admission migration checkpoint

ProjectHoomans' settlement-admission greeting now has one final adopter-owned PSDL record with three response variants and a Core-routed accepted-response text row. The adopter projection preserves the existing settlement-visit gate and admission authority flow without adding a PSDL runtime. All 8 legacy EN/TL entries have parity, the superseded definition/Core text source are removed, and the three-repository guard passes.

**Gate:** each accepted domain has one maintained PSDL authoring authority and no duplicate first-party source.

### S5 companion-topics migration checkpoint

ProjectHoomans' personal trust, relationship affinity, territory claim, and
member work-orders topics now share one final adopter-owned
`psdl/dialogue/social_companion_topics.json` source. The Core compiler routes
the plans and EN/TL catalogs; the adopter projection preserves actor-neutral
bindings, relationship/audience/base gates, territory diagnostics, priorities,
relationship effects, and the territory-claim effect. All 30 legacy text
entries have parity, the superseded Hoomans 90–93 modules and four Core text
sources/generated catalogs are removed, and the retained needs authority is
unchanged.

**Gate:** each accepted domain has one maintained PSDL authoring authority and no duplicate first-party source.

### S5 needs and gift-continuation migration checkpoint

ProjectHoomans' neutral, member, and special needs conversations now share one
final adopter-owned `psdl/dialogue/needs_support.json` source. The Core
compiler routes the plans and EN/TL catalogs under adopter-owned PSDL text
targets; the Hoomans projection preserves all three opening offers, the gift
continuation turn, the return-to-root transition, and existing gift-item
placeholder/received-text contracts. All 120 legacy audience-locale entries
have parity, the superseded needs definition and three Core text sources are
removed, and the independent gift-preference catalog remains unchanged.

**Gate:** each accepted domain has one maintained PSDL authoring authority and no duplicate first-party source.

### S5 ask-about migration checkpoint

ProjectHoomans' neutral/member/special ask-about records now have one final adopter-owned PSDL source, routed through Core's compiler and existing conversation block registry. EN/TL parity covers all 30 legacy entries; the two legacy player-name bindings are intentionally authored as `{addressee.name}` and resolve through Core's shared actor-neutral text-binding seam. The superseded Hoomans definition and Core ask-about text sources/generated catalogs are removed, with exact caller/reference-zero evidence and the three-repository authoring guard passing.

**Gate:** each accepted domain has one maintained PSDL authoring authority and no duplicate first-party source.

### S5 task, command, and companion-action migration checkpoint

ProjectHoomans now owns four final PSDL dialogue shards covering player
commands, companion replies, lifecycle actions, and combat/horde reactions.
They preserve 76 legacy semantic phrase families with actor-neutral
`speaker`/`addressee` bindings and 152 EN/TL locale entries. The existing
semantic response catalog and companion speech authority project wording from
Core-generated PSDL plans, while command execution, horde acknowledgement,
safety, effects, and gameplay authorities remain unchanged. The superseded
Core command/player, command/replies, command/lifecycle, and combat-horde
sources and generated Content modules are removed, and the Core manifest routes
the four adopter-owned PSDL shards. Direct command and horde smokes, Core
harness, caller/reference-zero checks, and the three-repository guard pass. A
broad presentation smoke retains a known baseline camp-rejection handoff
failure after direct semantic resolution and is not counted as PSDL parity
failure.

**Gate:** each accepted domain has one maintained PSDL authoring authority and no duplicate first-party source.

### S5 social apology, hostility, and reconciliation migration checkpoint

ProjectHoomans now owns the final `psdl/dialogue/social_apology.json` source
for the default, friendly, stressed, and withdrawn apology/reconciliation
families. Each family is represented by four bounded style plans (neutral,
warm, terse, guarded), preserving 160 EN/TL phrase pairs and 320 locale
values. The existing Hoomans response catalog remains the selector; its social
adapter projects Core-generated plans into the existing phrase-family and
SpeechRealization authorities. Core validation recognizes the PSDL-declared
`responseTemplateID` alias used by existing Core-owned behaviors without
creating a second schema or runtime. Superseded Core/Hoomans Apology sources,
generated SocialApology/Apology outputs, and translation-manifest entries are
removed. Source parity, Core harness, PSDL build, S0 guard, direct Lua family
load, and changed-file Kahlua gates pass. The Lua worker retains the known
duplicate automatic-flow registration baseline after advancing past the former
apology-template failure.

**Gate:** each accepted domain has one maintained PSDL authoring authority and no duplicate first-party source.

## S6 — taxonomy, layout and generated-output cleanup

Reach the final naming/layout standard in `NAMING_AND_LAYOUT.md`.

Required:

- semantic IDs describe meaning;
- no steady-state implementation-history IDs;
- no numeric overflow shards;
- no duplicate owner trees;
- no manually maintained split translation source for migrated dialogue;
- generated artifacts are bounded, deterministic and downstream-only;
- source discovery/indexes point to PSDL records;
- old source directories disappear when their final owning records reach zero.

**Gate:** source audit reports zero first-party duplicate authoring authorities, zero forbidden migration-copy directories and zero forbidden steady-state naming patterns.

## S7 — Semantic Lab / agent authoring experience

Make PSDL genuinely easy to author rather than only architecturally clean. The reusable authoring/validation service is Core-owned; adopter tooling calls that service and supplies adopter-owned records/context rather than forking it.

Required editor/preview capabilities:

- create/edit/duplicate/delete/reorder PSDL records;
- syntax-aware predicates and collection constraints;
- participant role selection;
- slot/reference/binding editor;
- locale variant editor;
- turn/offer tree editor;
- behavior/beat editing;
- source lineage and compile diagnostics;
- preview context for speaker/addressee/target;
- adjustable traits, identity/gender, personality, relationship, roles and world state;
- player↔NPC and NPC↔NPC simulation;
- fuzzy input/entity-resolution inspection;
- predicate → beat → behavior → variant → offer trace.

GUI and agents must use the same authoring service and compiler APIs.

**Gate:** a new dialogue with nested offers, constraints, translations and an optional beat can be created through the canonical service without hand-editing generated Lua/translation output.

## S8 — exhaustive acceptance and old-authority removal

Final developer acceptance must prove:

- PSDL is the only maintained first-party semantic dialogue authoring standard;
- no new first-party legacy/compat authoring files exist;
- no maintained production dialogue still depends on the old node/choice/outcome source model;
- no maintained static suggestion source is a separate semantic authority;
- actor-neutral references work across player/NPC permutations;
- traits, identity/gender, relationships, capabilities, situation and knowledge constraints work;
- typed slots/references and dynamic names work;
- fuzzy NLU/entity resolution remains bounded and mutation-safe;
- player buttons and NPC choices consume the same semantic affordance model;
- multi-turn/nested offers work;
- beats remain modular orchestration, not wording ownership;
- NPC↔NPC and mixed multi-participant scenes work;
- locale generation remains data-driven with EN fallback;
- PsychopatzCore physically owns the PSDL language/compiler/shared runtime contracts with no duplicate implementation in ProjectHoomans or DynamicTrading;
- ProjectHoomans and DynamicTrading/DTCommon both consume Core PSDL through public contracts and retain only adopter-specific semantic content/gameplay adapters;
- all three repositories pass their relevant Lua/Python/Kahlua/CodeBuilder/harness gates;
- two-pass generation is byte-identical;
- generated artifacts remain downstream-only;
- no save/source mutation occurs during developer acceptance.

Only explicit user-owned native feel/visual acceptance may remain after S8.

## Scope boundaries

Do not use this goal to:

- replace the accepted semantic NLU engine;
- add routine LLM-driven conversation;
- create persistent transcripts;
- redesign unrelated gameplay domains;
- create a cinematic scripting engine;
- weaken fuzzy-action safety;
- preserve first-party old systems through new legacy compatibility trees.

## Phase commit rule

Each accepted developer phase is committed locally before the next phase.

For a cross-repo phase:

1. inspect all three repositories and preserve unrelated dirty work;
2. commit adopter repositories (`ProjectHoomans`, `DynamicTrading`) first when that phase changes them;
3. reconcile this Core-owned job's PROGRESS/HANDOFF;
4. commit `psychopatzCore` last as the primary/job repository;
5. verify the three-repository commit vector and remaining dirty work;
6. continue automatically.

Never push automatically.
