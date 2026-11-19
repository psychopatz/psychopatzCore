# ConvoEngine Physical Layout and Localization Standard

**Status:** NORMATIVE
**Date:** 2026-11-19
**Applies to:** PsychopatzCore, ProjectHoomans, DynamicTrading/DTCommon
**Related architecture:** `ARCHITECTURE.md`
**Director architecture:** `CONVERSATION_DIRECTOR_ARCHITECTURE.md`

## Purpose

ConvoEngine has one authored semantic model. Physical source/output layout must
make that fact obvious.

The current system proves that semantic source can be canonical while the
generated filesystem is still confusing:

- some families externalize text into `media/translation/<LOCALE>/Conversation/...`;
- some families carry complete EN/TL corpora inside generated Lua;
- canonical source uses multiple localization authoring shapes
  (inline locale maps, `textSidecars`, `textTarget`, and mixed forms);
- behavior and beat source can be emitted both as full ConvoEngine plans and as
  almost-duplicate `Behaviors/Director` / `Beats/Director` Lua payloads.

These are physical split systems even when they originate from one source.

The steady state is:

> one semantic source, one localization source convention, one generated
> semantic artifact per canonical family, and any runtime-specific view is a
> compact derived index/projection that references the canonical artifact rather
> than copying its semantic body.

## 1. Canonical localization authoring

Localized prose is not semantic authority.

Maintained first-party family source must not embed complete locale corpora such
as:

~~~json
"EN": ["...", "..."],
"TL": ["...", "..."]
~~~

inside semantic `say`/`reply`/realization structures.

Canonical family source owns:

- semantic IDs;
- acts/intents;
- roles/slots/references;
- state/repeat/closure policy;
- action/result ownership;
- realization/variant IDs;
- optional non-localized metadata.

Localized human-readable prose belongs in one deterministic translation source
tree per owner.

Target source convention:

~~~text
sources/conversation/
├─ dialogue/
├─ behavior/
├─ beat/
├─ realization/
└─ translations/
   ├─ EN/
   │  ├─ dialogue/
   │  ├─ behavior/
   │  ├─ beat/
   │  └─ realization/
   └─ TL/
      ├─ dialogue/
      ├─ behavior/
      ├─ beat/
      └─ realization/
~~~

A semantic source path determines its translation-sidecar path. Do not require
every family to author a `textSidecars` map merely to repeat deterministic path
information.

Example:

~~~text
dialogue/companion_commands_lifecycle/command_return_home.json

translations/EN/dialogue/companion_commands_lifecycle/command_return_home.json
translations/TL/dialogue/companion_commands_lifecycle/command_return_home.json
~~~

CodeBuilder migration APIs own conversion from legacy inline/mixed shapes. Do
not manually mass-edit hundreds of family files.

## 2. Runtime localization ownership

Each package generates localized output into that package's own mod translation
root.

Example ProjectHoomans output:

~~~text
Contents/mods/ProjectHoomans/common/media/translation/
├─ EN/
│  └─ Conversation/
│     └─ Text/
│        └─ convo/
│           └─ ...
├─ TL/
│  └─ Conversation/
│     └─ Text/
│        └─ convo/
│           └─ ...
└─ manifests/
   └─ Conversation.json
~~~

Equivalent owner-local roots apply to PsychopatzCore and DTCommon.

Generated ConvoEngine Lua contains:

- stable translation key / realization ID;
- style/variant identity;
- semantic metadata;
- at most one generated EN fallback where the runtime requires resilience.

Generated Lua must not contain the complete multi-locale phrase corpus.

The translation manager/catalog is the text authority. ConvoEngine generated Lua
is a semantic/runtime descriptor, not a translation database.

## 3. Translation key derivation

Translation identity is deterministic from canonical semantic identity.

Preferred shape:

~~~text
convo.<family-or-template>.<semantic-path>.<variant>
~~~

Exact key normalization remains CodeBuilder-owned.

Keys must not depend on generated shard filenames.

Refactoring how many source records share one generated Lua shard must not rename
translation keys.

## 4. Locale coverage

EN is the required fallback language for maintained first-party text.

Every package-declared additional locale must either:

- provide the same required translation keys; or
- use one explicit compiler-recognized fallback/untranslated policy.

Silent key disappearance is invalid.

CodeBuilder validates key parity and reports missing locale entries before
generation.

## 5. One generated semantic artifact per family

A canonical behavior/beat/dialogue/realization must not be materialized twice
merely because two consumers need different views.

Target generated semantic namespaces:

~~~text
<Owner>/ConvoEngine/
├─ Dialogue/
├─ Behavior/
├─ Beat/
├─ Realization/
├─ Registry.lua
├─ Manifest.lua
└─ Index/
~~~

Do not maintain both:

~~~text
Behavior/...
Behaviors/Director/...
~~~

or both:

~~~text
Beat/...
Beats/Director/...
~~~

with duplicated semantic payloads.

The full canonical generated plan is the semantic artifact.

If a runtime consumer requires a faster/smaller view, CodeBuilder may generate
a compact index such as:

~~~text
Index/Director.lua
~~~

but that index may contain only derived lookup/scoring data such as:

- canonical ID;
- stimulus/topic/activity/domain keys;
- required-fact IDs;
- role/cardinality summary;
- base relevance / cooldown summary;
- continuation classification;
- module or registry reference.

It must not duplicate:

- action/effect authority;
- conditions/predicates;
- response/reply bodies;
- translation corpora;
- complete behavior/beat payloads.

## 6. Registry projection rule

Multiple runtime collections are allowed; multiple semantic artifacts are not.

For example, one canonical generated behavior may be indexed into:

~~~text
Registry.CONVO_PLANS[id]
Registry.BEHAVIORS[]
DirectorIndex.byStimulus[...]
~~~

from the same underlying generated record.

A consumer-specific collection is a view/index, not another source or another
full generated module.

## 7. Generated shard rule

Generated sharding is an implementation detail.

A generated file may contain multiple canonical records for filesystem/runtime
efficiency, but:

- canonical IDs stay stable;
- translation keys stay stable;
- source lineage stays recoverable;
- generated shard names do not become semantic authority;
- no agent authors directly against shard filenames.

Large generated Lua files must not be large because of copied locale corpora.

## 8. Forbidden steady states

Reject:

- inline EN/TL corpora in maintained semantic family source;
- mixed inline + `textSidecars` localization for the same family;
- package text emitted into another mod's translation root;
- generated Lua carrying full multi-locale text arrays;
- `Behavior` plus `Behaviors/Director` semantic-body duplication;
- `Beat` plus `Beats/Director` semantic-body duplication;
- hand-authored Director copies of canonical behavior/beat source;
- hand-edited generated translation JSON/Lua;
- compatibility wrappers preserving obsolete generated paths after caller-zero.

## 9. Acceptance invariants

Steady-state acceptance requires:

~~~text
inlineLocaleCorpusInCanonicalFamilies = 0
mixedLocalizationAuthoringFamilies = 0
generatedLuaMultiLocaleCorpusCount = 0
duplicateBehaviorProjectionBodies = 0
duplicateBeatProjectionBodies = 0
translationKeyMissingEN = 0
crossOwnerTranslationWrites = 0
generatedReconcile.clean = true
~~~

The exact machine-readable audit names may differ, but all dimensions must be
covered.

## 10. Migration rule

This standard changes layout/representation, not semantic meaning.

Migration order:

1. inventory every localization authoring shape and generated projection;
2. add fail-closed audits for new split output;
3. implement CodeBuilder migration APIs and canonical translation path derivation;
4. migrate source translation ownership;
5. switch runtime consumers to external translation keys;
6. regenerate;
7. collapse duplicate behavior/beat projections;
8. caller-zero old generated paths;
9. delete obsolete generators/tests;
10. reconcile and acceptance-test all owners.

No compatibility shim is retained after caller-zero.
