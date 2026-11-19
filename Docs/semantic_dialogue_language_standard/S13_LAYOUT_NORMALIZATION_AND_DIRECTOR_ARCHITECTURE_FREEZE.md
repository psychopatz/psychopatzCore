# S13 — ConvoEngine Layout Normalization and Director Architecture Freeze

**Status:** PLANNED — BLOCKED ON DURABLE S12 CORE CLOSURE COMMIT
**Date:** 2026-11-19
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Participants:** ProjectHoomans, DynamicTrading/DTCommon
**Layout standard:** `CONVOENGINE_PHYSICAL_LAYOUT_AND_LOCALIZATION.md`
**Director architecture:** `CONVERSATION_DIRECTOR_ARCHITECTURE.md`

## Objective

Remove the remaining physical split-system layout before implementing the
Conversation Director.

S13 does two things:

1. normalize localization and generated behavior/beat projection so one semantic
   source does not become multiple competing physical representations;
2. freeze the Director architecture that will consume the normalized model.

S13 does **not** yet implement autonomous Director selection.

## Current evidence motivating S13

ProjectHoomans currently demonstrates multiple localization forms:

~~~text
350 main canonical JSON records inspected
333 contain inline EN/TL text
63 use textSidecars
132 translation sidecar files
63 use textSidecars while also containing inline EN/TL data
~~~

Generated runtime also contains both:

~~~text
PNC/ConvoEngine/Behavior/Scene/*.lua
PNC/ConvoEngine/Behaviors/Director/Scene/*.lua
~~~

and analogous Beat/Beats projections must be audited.

`command.return_home` demonstrates the localization problem: complete EN/TL
variant corpora are embedded into generated Lua even though the mod already has
`media/translation/<LOCALE>/Conversation/...` and runtime translation support.

## Gate before S13 implementation

The current Core worktree contains the verified S12 swarm integration but it is
not yet durably committed.

Do not run layout migration on top of an uncommitted S12 foundation.

Before S13A:

- finish/review the existing S12-owned Core integration;
- reconcile the six S12/S12R1/S12R2 status docs;
- commit Core last after already-committed adopter work;
- require clean participant worktrees;
- verify closure/reconcile from the committed vector.

Only then activate S13.

# S13A — Exhaustive physical-layout inventory

Inventory all three owners.

Machine-readable inventory must classify:

### Localization authoring

- inline locale maps;
- deterministic translation sidecars;
- `textSidecars`;
- `textTarget`;
- mixed localization shapes;
- UI-only localization;
- runtime inline-registration dependency;
- owner/package translation root.

### Generated runtime projections

For each canonical family ID:

- canonical generated module;
- behavior/beat Director projection;
- registry collections referencing it;
- runtime consumers;
- semantic-body duplication hash;
- safe collapse strategy.

Explicitly audit:

~~~text
Behavior vs Behaviors/Director
Beat vs Beats/Director
Dialogue/Realization duplicate bodies
Registry/Index duplicate payloads
translation corpus embedded in Lua
cross-owner translation writes
~~~

S13A closes only when every generated output has one classified ownership role.

# S13B — Canonical localization authoring migration

Implement the normative source layout:

~~~text
sources/conversation/translations/<LOCALE>/<kind>/<domain>/<family>.json
~~~

through CodeBuilder migration APIs.

Requirements:

- semantic family source no longer carries complete locale corpora;
- deterministic source→translation path derivation;
- retire `textSidecars` when it only repeats deterministic paths;
- normalize mixed inline/sidecar families;
- preserve semantic IDs and realization/variant IDs;
- generated translation keys remain stable where already public/runtime-visible;
- EN fallback remains guaranteed;
- additional declared locales use explicit coverage/fallback rules.

No raw repository-wide JSON rewrite script outside CodeBuilder migration
authority.

# S13C — External runtime localization only

Switch maintained ConvoEngine generated runtime to:

~~~text
translationKey / realizationID
+ optional EN fallback
~~~

instead of complete multi-locale arrays.

Generated text goes to each owner's own:

~~~text
media/translation/<LOCALE>/Conversation/...
~~~

Update runtime consumers to use the existing translation manager/catalog.

Retire ConvoEngine-specific inline-registration paths after caller-zero. Do not
remove generic translation utilities still required outside ConvoEngine.

Gate:

~~~text
generatedLuaMultiLocaleCorpusCount = 0
crossOwnerTranslationWrites = 0
translationKeyMissingEN = 0
~~~

# S13D — Collapse duplicate behavior/beat physical projections

Use one generated semantic artifact for each canonical behavior/beat.

Target:

~~~text
ConvoEngine/Behavior/...
ConvoEngine/Beat/...
~~~

Retire full-payload duplicates:

~~~text
ConvoEngine/Behaviors/Director/...
ConvoEngine/Beats/Director/...
~~~

after runtime caller migration.

Registry may still expose:

~~~text
CONVO_PLANS
BEHAVIORS
BEATS
DirectorIndex
~~~

but all are views over the same canonical record.

If the Director/Interaction runtime needs compact lookup data, generate one
ID-based/index-only projection; never another semantic body.

Gate:

~~~text
duplicateBehaviorProjectionBodies = 0
duplicateBeatProjectionBodies = 0
obsoleteDirectorProjectionCallers = 0
~~~

# S13E — Director architecture readiness freeze

Do not implement autonomous selection yet.

Verify the normalized runtime exposes everything required by
`CONVERSATION_DIRECTOR_ARCHITECTURE.md`:

- ParticipantSet and dynamic RoleSpec/cardinality;
- stimulus/domain/topic/event/activity/memory hooks;
- required-fact metadata;
- base relevance/cooldown/diversity metadata;
- continuation/closure information;
- canonical validation entry point;
- compact index generation seam;
- translation-key-based realization.

Produce a machine-readable readiness report.

No second Director source tree is permitted.

# S13F — Closure

Required:

- all S13 physical-layout audits green;
- source translation migration complete in Core/Hoomans/DT;
- old localization shapes caller/source-zero or explicitly non-ConvoEngine;
- duplicate Director behavior/beat projection paths deleted;
- generation/reconcile clean from committed participant vector;
- focused compiler/translation/runtime tests green;
- existing semantic acceptance remains green;
- two-pass deterministic generation/acceptance;
- docs reconciled;
- adopter commits first, Core last;
- no push;
- no native Project Zomboid launch without explicit authorization.

## Completion boundary

S13 is complete when:

> ConvoEngine has one semantic source representation, one localization authoring
> convention, owner-local generated translation catalogs, one generated semantic
> artifact per canonical family, no full semantic-body Director duplicates, and
> a frozen sparse/event-driven Conversation Director architecture that can be
> implemented next without introducing another source of truth.
