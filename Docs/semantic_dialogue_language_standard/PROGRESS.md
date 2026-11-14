# Progress — ConvoEngine

**Status:** DEVELOPER_COMPLETE — S0-S8 + S8R ACCEPTED (native PZ SP/MP live/visual acceptance remains user-owned).
**Estimated developer progress:** 100% (developer-side complete).
**Branch:** existing `main` in all three repositories.
**Active phase:** NONE — S8R final naming, audit hardening, and documentation closure complete.
**Completion boundary:** accepted S0-S8 + S8R naming/audit/document closure + fresh exhaustive three-repository verification. Native Project Zomboid live/visual acceptance remains user-owned.

## Mandatory ownership and scope

- PsychopatzCore owns ConvoEngine: the conversation schema/Canonical Semantic Dialogue IR,
  compiler/normalizer, generic validation/predicates, actor-neutral references,
  typed slots/bindings, exchange-family/realization/reply rules, registered
  action-result contracts, package routing, modularity audit, CodeBuilder authoring service,
  and generated naming policy. `PSDL`/`psdl` is migration compatibility only.
- ProjectHoomans and DynamicTrading/DTCommon own adopter semantic records,
  adapters, gameplay constraints, tests, and translations/content.
- Existing ResponsePlan, BranchOffers, Interaction Director, Scene Runtime,
  Semantic Social Conversation, SpeechRealization and gameplay authorities
  remain runtime authorities. ConvoEngine remains authoring/compilation/orchestration rather than a replacement gameplay authority.

## Accepted foundation

The previous corrective work remains useful and must not be discarded:

- S0-S5 architecture/source-authority migration is accepted foundation.
- Core owns the only ConvoEngine compiler/schema/IR/shared service; `PSDL`/`psdl` survives only as migration compatibility.
- maintained old Core flow/response/UI/behavior/beat authoring roots were removed;
- DynamicTrading consumes the same Core mechanism;
- ProjectHoomans, Core, and DTCommon canonical conversation source now use `psychopatz.convo-engine.v1` family files under `sources/conversation/{dialogue,behavior,beat,realization}/...`;
- Core Semantic Lab exposes the ConvoEngine family-oriented pane and simulation trace;
- deterministic generation/runtime packing and `<Owner>/ConvoEngine/...` routing are accepted foundations.

## 2026-11-14 final S8R closure verification

All S8R naming, audit hardening, and documentation gates have now passed and
adopter commits have landed on `main` (`ProjectHoomans` `a21cfd5f806abe9075d97f9dd9c774a43127b412`,
`DynamicTrading` `d7c888de62d6f90dcf6746a24e5f50d7f7346e1d`):

```text
Core Python semantic-harness                  150/150 PASS
Core Convo/Semantic/Conversation Lua           34/34 PASS
Core refactor_binding_smoke                    PASS (17 changed Lua files)
Bare CLI audit-s6m8 --check-determinism        ok=true, 566 families, 404 files, 0 diffs, 0 legacyNameViolations
DynamicTrading                                 89/89 PASS
ProjectHoomans                               1020/1021 (focused convo/psdl Lua 27/27 PASS)
Kahlua ConvoEngine runtime trees               0 errors (Core 52, Hoomans common 219 + 42.20 181, DT 5)
```

The single ProjectHoomans failure remains the pre-ConvoEngine
`tests/pnc_population_director_smoke.lua:316` world-bootstrap assertion; neither
that test nor PopulationDirector runtime changed in the ConvoEngine migration
and `Population` Lua has zero `ConvoEngine`/`Conversation` references.

Pre-S8R vs steady-state legacy identity elimination (`convo_engine_psdl_inventory.py`):

```text
generated/runtime psdl.* occurrences     Core 57 -> 0, Hoomans 524 -> 0, DTCommon 10 -> 0
Hoomans canonical pnc.psdl.* entries     38 -> 0 (now pnc.convo.*)
Hoomans Conversation/Text/psdl files     76 -> 0 (now Conversation/Text/convo/)
direct Conversation/Text/psdl callers     3 -> 0
obsolete PSDLAuthoringPane alias          1 -> 0 (deleted)
```

S8R bare audit CLI discovery (`convo_engine_cli.py audit-s6m8 --check-determinism`)
now resolves `PsychopatzCore`, `ProjectHoomans`, and `DTCommon` automatically
when sibling checkouts are present or fails closed with actionable repository
diagnostics, and all goal-owned normative docs are committed cleanly.

## Modularity audit findings

Normative evidence is in `MODULARITY_AUDIT.md`.

### ProjectHoomans pre-normalization source shape

Historical S6M0 measured state:

```text
80 PSDL files
all 80 directly under psdl/dialogue/
25 files > 32 KiB
12 files > 64 KiB
19 files > 16 top-level records
11 files > 24 top-level records
largest: task_tool_replies.json = 128,652 bytes / 46 records
```

Representative aggregates:

```text
task_tool_replies.json                  46 records
task_lifecycle.json                     40 records
companion_commands_lifecycle.json       35 records
social_interaction_scene_horde_work     28 records
social_interaction_scene_travel_news    28 records
social_reactions_ack_dispute            28 records
social_tool_replies_affirmation         25 records
social_emotes                            30 records
health_content                           24 records
```

These are migration buckets rather than the intended self-contained semantic
modules.

### Canonical IDs

ProjectHoomans currently has approximately:

```text
804 PSDL records
715 IDs beginning semantic. (~88.9%)
```

The routine `semantic.` prefix is redundant because PSDL is already the
semantic authoring language.

Current long IDs frequently repeat domain/style information already known from
source/module context.

### Stable realization keys

Numeric `1`, `2`, `3`, ... keys remain useful, but the audit/planning
decision has been refined:

> numeric wording keys are stable **realization identities**, not separate
> semantic family identities.

The target stack is:

```text
semantic family
  → optional named reply outcome
      → stable say realization key 1 / 2 / 3 / ...
          → style/context variant
              → localized phrase alternative
```

Example:

```text
social.knowledge.ask_person

initiating say
  1
  2

reply.known
  say.1
  say.2

reply.unknown
  say.1
  say.2
```

Semantic callers reference `social.knowledge.ask_person` or a meaningful reply
outcome, never wording key `1`/`2`.

A family with one realization may author `say` directly without an artificial
`"1"`. Numeric keys become useful when multiple stable alternatives exist.

Existing numbered semantic IDs must be classified during S6M:

- if the number means only alternate wording, collapse it into a `say`
  realization key;
- if the number hides genuinely different semantic meaning, give that meaning a
  descriptive family/outcome name;
- do not renumber surviving realization keys merely to remove gaps.

### Style duplication

Current Hoomans measurements:

```text
804 total PSDL records
623 style-like top-level records
at least 66 response-template families with multiple top-level style records
```

Example current shape:

```text
semantic.interaction.scene.horde_prompt.neutral
semantic.interaction.scene.horde_prompt.warm
semantic.interaction.scene.horde_prompt.terse
semantic.interaction.scene.horde_prompt.guarded
```

Those records point to the same semantic response-template family. Style should
normally be nested inside a stable `say` realization using PSDL variants and
`when` predicates.

### Migration metadata residue

Across Core + Hoomans + DynamicTrading PSDL records:

```text
~71% metadata.sourceSurface
~71% metadata.responseTemplateID
~60% metadata.contentOwner
~75% metadata.category
```

Much of this is migration-era duplication and should become compiler-derived
where runtime consumers allow it.

## Generated naming defect

The screenshot's vague generated `Catalog.lua` leaves are generator-created.

Current Core `conversation_compiler.py`:

1. groups PSDL runtime plans by `(owner, kind, domain)`;
2. uses the broad current source/domain bucket;
3. calls the shared module naming function with:
   `[kind.title(), domain, "catalog"]`.

That intentionally produces:

```text
PSDL/Dialogue/CombatBanterWeaponKillBrave/Catalog.lua
PSDL/Dialogue/SocialInteractionArgument/Catalog.lua
```

Do not rename those files manually.

Target CodeBuilder mapping:

```text
sources/conversation/dialogue/social/argument/deescalate.json
→ <Owner>/ConvoEngine/Dialogue/Social/Argument/Deescalate.lua

sources/conversation/dialogue/social/scene/horde/brave_reply.json
→ <Owner>/ConvoEngine/Dialogue/Social/Scene/Horde/BraveReply.lua
```

The final ConvoEngine-owned runtime path has no redundant `Semantics`,
`Generated`, `Conversation`, or `PSDL` wrapper.

Generic Core semantic infrastructure that is broader than conversation remains
under `PsychopatzCore/Semantics/`.

Use/extend Core's existing collision-safe `catalog_naming.py` helpers.

## New normative compact language direction

Ordinary dialogue/content PSDL now uses one compact **exchange family**:

```json
{
  "kind": "dialogue",
  "namespace": "social.knowledge",
  "id": "ask_person",

  "invoke": { ... },

  "affordance": {
    "label": "Ask about {slot.person.name}"
  },

  "say": {
    "1": "Have you seen {slot.person.name} lately?",
    "2": "Do you know where {slot.person.name} is?"
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

The root owns semantic family identity once. Manifest/provider ownership
supplies ordinary adopter owner unless an explicit override is required.

PSDL must keep the following roles distinct:

```text
affordance.label
= UI-only recommendation label

say
= initiating actor's actual speech

invoke
= semantic meaning

reply.<outcome>.say
= responder speech after semantic/result outcome selection
```

Initiating and reply realization keys are independent. There is no
`say.1 -> reply.say.1` pairing.

Player buttons and NPC choices are projections of the same bound Core semantic
affordance instances. NPC selection uses semantic utility/predicates, never
rendered text.

PSDL also now requires a typed gameplay execution seam:

```text
invoke
→ optional execute registered action contract
→ bounded public result.*
→ named reply outcome
→ reply say
```

Example:

```json
"execute": "pnc.companion.camp"
```

PsychopatzCore owns the generic action-contract/result mechanism; ProjectHoomans
retains the real camp gameplay/validation/server authority. Raw Lua callbacks
and raw return tables are not PSDL.

Read-only candidate/binding resolvers remain separate from mutation/execution.
Asynchronous results must be correlated/idempotent and may drive
pending/accepted/rejected/failed/completed replies.

Filesystem path is discoverability, not canonical identity.

## Current phase truth

- **S0:** accepted foundation.
- **S1:** accepted foundation.
- **S2:** accepted foundation; the compact exchange-family/reply/action-result extensions were implemented in S6M.
- **S3:** accepted foundation.
- **S4:** accepted runtime concept; required source sharding/normalization was completed in S6M.
- **S5:** accepted old-authority closure; ConvoEngine source normalization was completed in S6M.
- **S6:** ACCEPTED foundation.
- **S6M:** ACCEPTED through S6M8 implementation; S8R adds the missing active-legacy-name leakage gate.
  - **S6M0:** accepted baseline audit (`MODULARITY_AUDIT.md`).
  - **S6M1A:** ACCEPTED (compact exchange-family compiler + CodeBuilder preview/validation seam; 120 `tools/semantic_harness/tests` tests passing).
  - **S6M1B:** ACCEPTED (headless CodeBuilder `convo_engine_authoring.py` / `convo_engine_cli.py` + `SemanticLabAuthoringService` create/edit/move/shard/write API; 124 `tools/semantic_harness/tests` tests passing).
  - **S6M2A:** ACCEPTED (three-repo ownership inventory in `convo_engine_ownership_inventory.py` + `S6M2A_OWNERSHIP_INVENTORY.json`: 805 modules classified into 530 `convo_engine` vs 275 `generic_semantic_infrastructure`, collision check passing, 127 tests passing).
  - **S6M2B:** ACCEPTED (root-cause ConvoEngine routing across Core, ProjectHoomans, and DynamicTrading to `<Owner>/ConvoEngine/...` with semantic module filenames and zero `Catalog.lua` leaves; migrated proven ConvoEngine-owned runtime modules/identifiers while preserving Core generic `Semantics/`; regenerated 457 files cleanly via CodeBuilder; verified caller-zero in Lua across all 3 repos; Core Python 127/127 OK, Core refactor smoke PASS, Core 12 Lua smoke tests PASS, DynamicTrading 89/89 PASS, ProjectHoomans Lua 1003/1020 with 17 pre-existing S1/S5 baseline failures recorded for S6M3-S8 closure).
  - **S6M3:** ACCEPTED (migrated/sharded all 106 `psdl/` buckets / 1029 records across Core, ProjectHoomans, and DynamicTrading via `SemanticLabAuthoringService.migrate_convo_engine_bucket` & `convo_engine_cli.py migrate-bucket` into 688 coherent family shards under `sources/conversation/{behavior,beat,realization,dialogue}/...`, leaving zero `psdl/` directories across all three repos; regenerated 454 files via `build.py`; verified Core Python 129/129 OK, Core refactor smoke PASS, Core semantic Lua smokes 9/9 PASS, DynamicTrading 89/89 PASS, ProjectHoomans Lua 1003/1020 matching exact pre-existing S1/S5 baseline; verified `DTCommon` optional `externalSourceRoots` compatibility with Hoomans ownership/apology compiler tests).
  - **S6M4:** ACCEPTED (normalized all remaining `psychopatz.semantic.dialogue-language.v1` numeric-ID/style-sibling shards across Core [120 sources], ProjectHoomans [510 sources], and DynamicTrading [3 sources] via `convo_engine_normalization.py` / `convo_engine_cli.py` + compiler updates in `conversation_compiler.py` / `conversation_rendering.py` / `Foundation.lua`; reached zero `psychopatz.semantic.dialogue-language.v1` sources across all three repos; regenerated all ConvoEngine outputs; updated runtime catalogs, `ConvoPlanFamily.lua`, `SpeechRealization.lua`, `Interaction/Presentation.lua`, `Dialogue/`, `client/` adapters, Core observatory fixtures, and smoke tests atomically; verified Core Python 131/131 OK, Core `refactor_binding_smoke.py` PASS, Core semantic Lua tests 18/18 PASS, DynamicTrading 89/89 PASS, ProjectHoomans 1012/1020 PASS [8 pre-existing S1/S5/SocialFlavorClient baseline failures], and 0 Kahlua2 compatibility issues across all modified Lua files).
  - **S6M5:** ACCEPTED (implemented S6M5 compiler/registry/runtime support in `convo_engine_exchange.py`, `conversation_registry.py` [`CONVO_REPLY_INDEX` & `ConvoOutcome`], `conversation_compiler.py`, `psdl_compiler.py` [`render_psdl_ui_plan` for `affordance` + `say`], Core `PsychopatzCore/ConvoEngine/Affordance.lua` + `Foundation.lua`, and Hoomans `PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily.lua`; added CodeBuilder normalization/sharding operations `fold_suggestion_pair`, `fold_outcome_family`, and `shard_offers_to_families` in `convo_engine_normalization.py` & `service.py`; migrated Core [`question.knowledge`, `question.identity` outcomes, `core_check_in`, `core_identity`], Hoomans [`static_suggestion_text` 12 suggestion pairs, `companion_check_in`, `health_content`, `companion_commands_lifecycle` 5 commands, `quest_content` 4 stages, `task_lifecycle` 7 tasks + `gift`], and DynamicTrading [`trade_conversation_suggestions` -> 8 offer families + `suggestions_recognition`] strictly through CodeBuilder; regenerated 466 generated files cleanly via `build.py`; verified Core Python 135/135 OK, `refactor_binding_smoke.py` PASS, Core Lua semantic+S6M5 tests 18/18 PASS, DynamicTrading 89/89 PASS, ProjectHoomans 1012/1020 PASS [exact 8 pre-existing failures, 0 regressions], and 0 Kahlua2 errors on edited Lua modules).
  - **S6M6:** ACCEPTED (implemented Core registered Semantic Action Contract / `execute` + bounded public `result.*` compiler/IR/runtime support in `semantic_dialogue_ir.py` [`result` context root], `convo_engine_exchange.py` [`normalize_execute` rejecting Lua/callbacks + `bindings` projection], `psdl_compiler.py` [dotted binding names + `action_contracts` checks], `PsychopatzSemanticIR.lua` [`result` public root], `TextBinding.lua` [raw structured resolver inputs + camelCase placeholder names], `ActionContract.lua` [capability/input/schema validation, `discoveryOnly` guard, sync+async `CompleteAsync` correlation, duplicate/stale idempotency guard, fail-closed public `result.*` projection], and `Affordance.lua` [`ExecuteExchange` & `ApplyActionResult` + predicate `result.*` branching]; registered Hoomans `pnc.companion.camp` + `pnc.camp.location_phrase` in `PNC/ConvoEngine/CampActionContract.lua` routing through existing `PNC.Client.RequestSemanticTask` / `TaskRequestService.Submit` authority and client-observed `camp_site` hint rules; updated `command_camp.json` via `SemanticLabAuthoringService.write_convo_engine_source` and regenerated 466 artifacts via `build.py`; verified Core Python 140/140 OK [incl. `test_convo_engine_s6m6_actions.py`], `refactor_binding_smoke.py` PASS, `convo_engine_s6m6_action_contract_smoke.lua` & `convo_engine_s6m5_affordance_smoke.lua` PASS, DynamicTrading 89/89 PASS, ProjectHoomans 1013/1021 PASS [incl. `pnc_convo_engine_camp_action_smoke.lua` PASS & 10/10 camp/task filter pass, exact 8 pre-existing baseline failures, 0 regressions], and 0 Kahlua2 errors across all 6 edited/created Lua modules).
  - **S6M7-S6M8:** ACCEPTED (enforced `strip_stale_migration_metadata` in `convo_engine_authoring.py` / `SemanticLabAuthoringService.write_convo_engine_source` and fixed cross-file `compile_convo_engine_sources` + `beat`-to-sibling-`behavior` validation in `psdl_compiler.py` / `service.py`; stripped stale migration metadata [`sourceSurface`, `migration`, `sourceCatalog`, `originalOwner`, `metadata.sourcePath`, `metadata.sourceProfile`] across all 436 Core/Hoomans + 2 DynamicTrading canonical ConvoEngine sources through CodeBuilder; restored `opening.001..003` `metadata.textRows` in `social_settlement_admission.json` + regenerated 466 artifacts via `build.py`; fixed Core `UI.json` missing `UI_PsychopatzConversation_Goodbye` & `PsychopatzConversationText.lua` camelCase placeholder regex `{[a-z][a-zA-Z0-9_.]*}`; closed all 7 Hoomans ConvoEngine/semantic/translation/emote/gift/context regressions [`DialogueBlocks.lua` compact `say` support, `PNC_CompanionCommandInteractionQueue.lua` explicit player actor + synchronous pump without `OnTick`, `PNC_CompanionCommandInteraction.lua` unique per-exchange correlation ID, `PNC_TranslationBootstrap.lua` + `_Segments.lua` `^semantic.` / `^UI_DT_Conversation_` / `DebugDiscoveryRawLabel`, `Gifts_Receive_Presentation.lua` nil-guards, `pnc_conversation_smoke.lua` canonical ConvoEngine greeting plan expectation, `pnc_semantic_context_smoke.lua` & `pnc_semantic_cognition_client_smoke.lua`]; added `convo_engine_s6m8_audit.py` + CLI `audit-s6m8` + `test_convo_engine_s6m8_audit.py`; verified Core Python 144/144 OK, Core ConvoEngine S6M5/S6M6 Lua smokes PASS, `audit-s6m8` 0 violations across 566 family files & 0 diffs across 404 generated files in two-pass determinism check, Kahlua2 0 errors across 288 scanned Lua files, DynamicTrading 89/89 PASS, ProjectHoomans 1020/1021 PASS [only unrelated `pnc_population_director_smoke.lua:316` world-bootstrap check fails]).
- **S7:** ACCEPTED (added `convo_engine_studio_trace.py` + `SemanticLabAuthoringService.{list_convo_engine_families, list_convo_engine_action_contracts, simulate_convo_engine_family}` and upgraded Semantic Lab UI via `ConvoEngineAuthoringPane` [`studio/convo_engine_authoring_pane.py`, compatibility wrapper `studio/psdl_authoring_pane.py`, `ui/studio_surface_builder.py` `"ConvoEngine"` tab] supporting hierarchical/filtered ConvoEngine family browsing across 566 families, compact family CRUD [`kind`/`namespace`/`id`/`slots`/`say`/`reply`/`execute`/`after.recommend`], registered `execute` contract picker, separated `UI Button` vs `Initiating Speech` vs `Selected Reply` simulation preview for `player<->NPC` and `NPC<->NPC` contexts, result-driven reply branch selection, full `predicate -> affordance -> invoke -> speech -> execute -> result -> reply -> after` trace, and built-in S6M8 audit runner; verified Core Python 146/146 OK incl. `test_convo_engine_studio_s7.py`).
- **S8:** ACCEPTED (566 canonical family files, 404 deterministic generated files with 0 diffs, 0 Kahlua2 errors, Core Python 150/150 OK, Core ConvoEngine/Semantic/Conversation Lua 34/34 PASS, DynamicTrading 89/89 PASS, ProjectHoomans 1020/1021 PASS with pre-existing `pnc_population_director_smoke.lua:316` proven independent).
- **S8R:** ACCEPTED (`S8R1` classified all 279 PSDL references into `S8R1_PSDL_CLASSIFICATION.json`; `S8R2` eliminated all active `psdl.*`/`pnc.psdl.*`/`Conversation/Text/psdl/` output identity and `psdl_authoring_pane.py` obsolete alias across Core, ProjectHoomans, and DynamicTrading via CodeBuilder regeneration; `S8R3` hardened `convo_engine_s6m8_audit.py` + `convo_engine_cli.py` + `service.py` with active leakage scanning and unambiguous three-repo workspace discovery / fail-closed diagnostics; `S8R4` reconciled and committed all goal-owned normative docs; `S8R5` verified fresh three-repo regeneration and full test/Kahlua/leakage gates).

Developer-side ConvoEngine work is complete. Native Project Zomboid live SP/MP
visual/feel acceptance remains user-owned.

## Final completion boundary

S8 can close only when:

- source is hierarchically organized by coherent semantic family;
- ordinary dialogue uses compact exchange-family identity;
- manifest/provider ownership removes unnecessary owner boilerplate;
- numeric wording keys are stable realization handles, not semantic family IDs;
- a single realization does not require artificial `"1"`;
- reply outcomes carry semantic names and own independent reply realizations;
- initiator and reply wording keys are never positionally coupled;
- style/context/phrase alternatives occupy the correct nested dimensions;
- canonical IDs are concise/non-redundant;
- reusable targets own `invoke` + UI-only `affordance.label`;
- runtime text roles normalize explicitly with no label→speech fallback;
- player and NPC use the same bound semantic affordance instances;
- NPC choice can use relationship/traits/stats/context utility without parsing
  rendered text;
- registered typed `execute` contracts preserve adopter gameplay authority;
- only bounded contract-declared `result.*` fields enter dialogue context;
- sync and async results safely drive named reply outcomes/bindings;
- duplicate/stale async results cannot replay mutation or duplicate speech;
- read-only query/candidate discovery never performs mutating execution;
- Hoomans CAMP proves the action/result/reply path using its existing authority;
- static suggestion/hub text is not a separate first-party authority;
- chaining uses bounded `after.recommend` / `after.goto` / end / resume;
- generated ConvoEngine modules use semantic filenames under `<Owner>/ConvoEngine/...`;
- maintained ConvoEngine source/generated/runtime/translation output emits no
  `psdl.*`, `pnc.psdl.*`, or `Conversation/Text/psdl/` identity;
- any remaining PSDL names are explicitly classified bounded migration
  readers/test fixtures, not steady-state writers/output;
- no generated artifacts are hand edited;
- Semantic Lab authors/traces the final exchange/affordance/reply/action-result
  model;
- broad Core/Hoomans/DynamicTrading tests pass, with any unrelated accepted
  baseline proven by fresh dependency/Git evidence;
- deterministic generation/Kahlua/source/legacy-name audits pass;
- bare exhaustive audit invocation either discovers all mandatory repos or
  fails fast rather than running partial acceptance;
- all goal-owned normative docs/adopter pointers required by the handoff are
  committed and present in that commit;
- final handoff records exact three-repository HEADs/residual worktrees and is
  not marked CLEAN while phase-owned files remain dirty/untracked.

Native Project Zomboid live/visual/feel acceptance remains user-owned after
developer-side S8 genuinely passes.
