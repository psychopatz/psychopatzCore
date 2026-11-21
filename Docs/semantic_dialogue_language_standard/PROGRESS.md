# Progress — ConvoEngine / Semantic Harness

**Status:** COMPLETE — S13A–S13F layout normalization, externalized owner-local localization, single-artifact behavior/beat projection collapse, compact derived `Index/Director.lua` generation, and Director readiness freeze are complete and verified across all three repositories.
**Branch:** existing `main` in all three repositories.
**Active phase:** S13F complete.
**Immediate Next Chunk:** ProjectHoomans Phase U5b (Façade-inspired Micro-Beat Dialogue Director & RDR2 Street Interaction) over frozen `CONVERSATION_DIRECTOR_ARCHITECTURE.md`.
**Parent Goal:** `UnifiedSchemaDrivenNPCAI` (Phase U5a gate closed).

## Verified S12 + S13A–S13F participant vector

~~~text
psychopatzCore   S13D–S13F closure commit on main (see HANDOFF.md phase_commit: self)
ProjectHoomans   S13D–S13F generated artifacts reconciled cleanly (closes in Phase U5 commit)
DynamicTrading   d4034fac5f547e00253dc3b9db5fd4554e37b535
~~~

Earlier durable Core checkpoints on `main`:
- `ce86135` — S12R2 durable Core closure integration and PSDL retirement (`activeCurrentPsdlIdentityCount = 0`).
- `885065c` — S13 physical layout, localization, and Director architecture freeze docs.

## Verified S13A–S13C localization closure evidence

- **S13A (exhaustive localization inventory):** classified all 470 maintained ConvoEngine families across PsychopatzCore (110), ProjectHoomans (349), and DTCommon (11), plus generated Lua, `media/translation/` trees, runtime consumers, CodeBuilder stages, and tests.
- **S13B (canonical localization authoring migration):**
  - Migrated all 436 localized ConvoEngine families (`34` `NO_LOCALIZED_TEXT` = `470` total) to deterministic `sources/conversation/translations/<LOCALE>/<kind>/<domain>/<family>.json` (`psychopatz.convo-engine.translation.v1`) via `convo_engine_translation_migration.py` / `convo_engine_cli.py migrate-translations`.
  - Removed all inline EN/TL corpora from maintained semantic family bodies, retired `textSidecars`, and deleted 146 legacy sidecar files (including 6 orphaned legacy sidecars).
  - Added fail-closed `convo_engine_localization_audit.py` (`convo_engine_cli.py localization-audit`) wired into `convo_engine_integrity_audit.py` (`convo.audit`).
- **S13C (external owner-local runtime localization):**
  - Stripped multi-locale corpora from generated ConvoEngine Lua (`Dialogue/*.lua`, `Responses/*.lua`, `UI/*.lua`, `Realization/*.lua`), retaining only `translationKey`/`templateID`/`labelKey`/`utteranceKey` + compact EN fallback.
  - Retired `construction.tl.*` separate Lua generation; `Realization` emits one canonical construction record with `translationKey`.
  - Emitted domain-sharded `Conversation/Text/convo/ConvoEngine_*.json` catalogs into each owning mod's `media/translation/<LOCALE>/` tree and registered them in each owner's `manifests/Conversation.json`.
  - Eliminated cross-owner `UI.json` writes (`crossOwnerTranslationWrites = 0`).
  - Updated Lua runtime consumers (`Affordance.lua`, `Foundation.lua`, `S11PolicyEvaluator.lua`, `PsychopatzCoreTranslation.lua`, `PsychopatzCustomTranslationManager.lua`, `ConvoPlanFamily.lua`, `SpeechRealization.lua`, `UtterancePlan.lua`, `PNC_TranslationBootstrap.lua`, `DTCommon_Translation.lua`, `DTCommon_TraderConversation.lua`) and deleted `PNC.Translation.ConvoInline` / `RegisterInlineText` at caller-zero.

~~~text
inlineLocaleCorpusInCanonicalFamilies = 0
mixedLocalizationAuthoringFamilies    = 0
legacyTextSidecarsPathCount           = 0
generatedLuaMultiLocaleCorpusCount    = 0
crossOwnerTranslationWrites           = 0
translationKeyMissingEN               = 0
orphanTranslationEntryCount           = 0
duplicateTranslationKeyCount          = 0
unknownLocalizationShapeCount         = 0
activeCurrentPsdlIdentityCount        = 0
modernization closureOk               = true (470/470)
reconcile --check                     = clean (missing=0, drifted=0, stale=0, retired_present=0, ambiguous=0)
~~~

## Verified S13D–S13F Director projection collapse & readiness freeze

- **S13D (Single-artifact Behavior/Beat projections):**
  - Eliminated duplicate `Behaviors/Director/*` (10 files) and `Beats/Director/*` (3 files) generated modules across `PsychopatzCore` and `ProjectHoomans` via `conversation_compiler.py` and `reconcile.py --apply`.
  - Consolidated `Registry.BEHAVIORS`, `Registry.BEATS`, `Registry.CONVO_PLANS`, and `Registry.DIRECTOR_INDEX` over canonical single-artifact `Behavior/*` and `Beat/*` modules in `conversation_registry.py`.
  - Implemented compact ID-based `convo_engine_director_index.py` emitting sparse inverted indexes (`byStimulus`, `byDomain`, `byTopic`, `byActivity`, `byEventType`, `byRequiredFact`, `byKind`) into owner-isolated `Index/Director.lua` without duplicating semantic bodies.
- **S13E–S13F (Director Readiness Freeze & Closure):**
  - Implemented fail-closed `convo_engine_director_audit.py` + `convo_engine_cli.py director-readiness`, wired into `convo_engine_integrity_audit.py` (`convo.audit`).
  - Verified all 8 `CONVERSATION_DIRECTOR_ARCHITECTURE.md` readiness invariants (`behaviorCount=30`, `beatCount=3`) and zero layout duplication counters:

~~~text
duplicateBehaviorProjectionBodies       = 0
duplicateBeatProjectionBodies           = 0
obsoleteDirectorProjectionCallers         = 0
directorIndexBodyDuplicationCount       = 0
missingDirectorReadinessCapabilityCount = 0
director-readiness --summary ok         = true
audit-integrity --check-determinism ok  = true (446 files, diffs=0)
reconcile --check                       = clean (missing=0, drifted=0, stale=0, retired_present=0, ambiguous=0)
~~~
