# S12 — ConvoEngine v1 Dynamic Dataset Modernization

**Status:** NORMATIVE ACTIVE GOAL
**Date:** 2026-11-19
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Participants:** ProjectHoomans, DynamicTrading/DTCommon
**Core authoring standard:** `DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md`
**Content rewrite gate:** `BULK_DIALOGUE_REWRITE_ALLOWED=false` until S12B inventory is accepted; then modernization proceeds only through classified batches.

## Objective

Modernize the maintained ConvoEngine dataset so every family follows the v1 dynamic-composition authoring standard and is safe for later context-driven/emergent conversation selection.

The goal is not to simply rewrite sentences.

The goal is to transform the first-party dataset toward:

~~~text
reusable semantic family/archetype
+ typed roles/slots/references
+ authoritative state/outcome policy
+ bounded runtime binding/composition
+ independent realization
~~~

while deleting duplicated specialization, wording-only semantic duplicates and split conversational authorities.

## Pre-release schema decision

There is no released compatibility boundary.

The only maintained first-party target becomes:

~~~text
family/source schema:
psychopatz.convo-engine.v1

package schema:
psychopatz.convo-engine.package.v1
~~~

Do not create a v2.

`psychopatz.psdl.v2` and `psychopatz.psdl.package.v2` are pre-release implementation residue, not a second supported standard.

Migration is direct:

~~~text
all first-party canonical source/package descriptors
→ ConvoEngine v1
→ caller/source zero for PSDL schema identifiers
→ delete old read/alias paths
~~~

No compatibility shim.

Compact source remains compact under v1. Do not expand every family into verbose normalized IR merely to remove the PSDL schema name.

## Current checkpoint

At goal creation:

~~~text
psychopatzCore   37f13c1fa526ce214ca79851328f1a317cff982a
ProjectHoomans   b5e538fbfe4213c4e45e6e966983ff814f9c71b4
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

All three worktrees were clean.

Current maintained authoring inventory is approximately 588 families and must be re-derived from current source at phase start rather than treated as a hardcoded constant.

## Non-negotiable principles

1. One semantic interaction/action has one canonical family authority.
2. Runtime binding/composition is encouraged; runtime semantic invention is forbidden.
3. Mutable gameplay/domain truth remains adopter-owned.
4. Use roles/slots/typed references instead of hard-coded contextual duplicates.
5. Use realization variants for wording/style/localization differences.
6. Use beats/archetypes for reusable conversation composition.
7. Semantic correctness requires zero LLM calls.
8. No direct generated-artifact edits.
9. No project-owned compatibility wrappers after parity/caller-zero.
10. Every migrated family must pass health/completeness and relevant verification before its superseded sources are deleted.

## S12A — ConvoEngine v1 standard freeze and single-authority cleanup

### A1. Unify schema/toolchain naming

Change compiler/authoring/package implementation so compact first-party source is directly `psychopatz.convo-engine.v1`.

Target:

~~~text
CONVO_ENGINE_SCHEMA = psychopatz.convo-engine.v1
CONVO_ENGINE_PACKAGE_SCHEMA = psychopatz.convo-engine.package.v1
~~~

Compact authoring detection must be structural/profile-aware within v1, not dependent on a second `psychopatz.psdl.v2` schema identity.

Migrate all first-party canonical source and package descriptors through CodeBuilder tooling.

After source/caller zero, remove:

- `COMPACT_PSDL_SCHEMA` as a supported authoring schema;
- `PACKAGE_DESCRIPTOR_SCHEMA = psychopatz.psdl.package.v2`;
- dual-schema acceptance checks owned only by the old pre-release identity;
- obsolete PSDL-named authoring/compiler modules or symbols where caller-zero allows direct rename/removal.

Do not rename generic semantic infrastructure that is genuinely broader than ConvoEngine.

### A2. Collapse CAMP to one family

Use `command.camp` as the canonical CAMP interaction unless current evidence proves another ID is semantically superior.

The surviving family must own:

~~~text
invoke/action
slots/bindings
statePolicy
inputPolicy
repeatPolicy
postconditions
closure
execute
reply outcomes
continuation
realizations
~~~

Retarget exact acceptance ownership to the surviving family.

Prove typed/button parity and zero remaining source/runtime/registry callers for `command.companion.camp`, then delete it and regenerate.

Remove project-owned runtime logic that searches the registry for another family with the same action merely to borrow state policy, unless an independently justified generic use remains.

### A3. Duplicate semantic-authority audit

Add a machine audit that detects suspicious multi-family ownership of the same mutating semantic action.

The audit must distinguish legitimate distinct semantic families from split project-owned policy/content authority.

No other split-authority family may remain hidden before dataset migration.

### A4. Health-scope clarity

Make Semantic Lab explicitly distinguish:

~~~text
Package health
Selected family semantic health
Test coverage
Current filter scope
~~~

When the selected family is outside the active issue filter, say so explicitly rather than rendering package issues beside an unrelated healthy family without scope labeling.

### S12A gate

- only ConvoEngine v1 first-party family/package schemas remain;
- compact authoring still works;
- PSDL schema read/alias paths reach caller/source zero and are deleted;
- CAMP has one canonical family;
- duplicate action-authority audit is green;
- health scopes are unambiguous;
- reconcile/integrity/determinism/provider tests pass;
- two canonical acceptance runs preserve the exact participant vector.

Commit adopters first, Core last.

## S12B — machine-readable dataset modernization inventory

Before broad source rewriting, classify every maintained family using the core standard:

~~~text
STATIC_LITERAL
SLOT_PARAMETERIZABLE
CONTEXT_VARIANT
BEAT_COMPONENT
ARCHETYPE_MEMBER
REDUNDANT_SPECIALIZATION
DOMAIN_ACTION
REALIZATION_ONLY
LEGACY_SPLIT_AUTHORITY
~~~

The inventory must be machine-readable and generated/maintained through Core tooling, not a hand-maintained second semantic registry.

For each family record at least:

~~~text
canonicalID
owner
kind
source
classification
semantic act / intent / subject where available
current roles
candidate runtime roles
slots / candidate slots
topic/event/activity/memory/domain hooks
stateful?
mutating?
execute contract?
repeat/closure policy
realization count
test coverage state
possible duplicate/specialization group
recommended modernization action
~~~

Add group-level findings for families that should collapse into one parameterized family or one realization pool.

### S12B gate

Every maintained family is classified and the inventory has zero unknown ownership/source identity.

Only after this gate may broad dataset modernization begin.

## S12C — PsychopatzCore dataset modernization

Modernize Core-owned families in coherent semantic-domain batches.

Suggested order:

1. identity/greetings/wellbeing/check-in;
2. knowledge/person/location/activity/time/weather;
3. memory/gossip/world-event reactions;
4. generic social reactions/conflict/repair;
5. generic tasks/requests/offers;
6. behaviors/beats/realizations.

For every batch:

- inspect classification;
- collapse redundant specialization;
- introduce typed slots/roles/references where useful;
- move wording-only differences into realization;
- make state/repeat/closure explicit when applicable;
- expose discoverable metadata for future composition;
- preserve semantic/gameplay behavior;
- use CodeBuilder authoring APIs;
- run affected analysis and family tests;
- regenerate/reconcile;
- delete superseded source only after parity/caller-zero;
- local phase/batch commit.

## S12D — ProjectHoomans dataset modernization

Modernize Hoomans-owned families after Core primitives are stable.

Prioritize:

1. companion/domain actions;
2. recruitment/relationship/settlement/social state;
3. needs/tasks/quests/events;
4. contextual social reactions;
5. behaviors/beats and participant-role composition.

Domain actions must keep actual gameplay truth/mutation in Hoomans adapters while the single ConvoEngine family owns conversational admission/outcomes.

Prefer runtime-bound context such as current NPC, camp site, task, event, memory, settlement, item, threat and activity over hard-coded context-specific families.

## S12E — DynamicTrading/DTCommon dataset modernization

Modernize trading dialogue using the same standard:

- typed trader/item/offer/settlement/economic references;
- one family per semantic trade interaction;
- dynamic binding of current market/trader context;
- realization variation separated from trade meaning;
- no duplicated market/gameplay authority in dialogue.

## S12F — composition-readiness closure

Run an exhaustive final audit across all maintained families.

Required zero findings:

~~~text
legacy PSDL source/package schema
split project-owned semantic action authority
unclassified family
redundant participant-count specialization without justification
wording-only semantic duplicate left unclassified
hard-coded entity/context duplicate that should be a slot
runtime-invented gameplay authority
direct generated-artifact edits
~~~

Required evidence:

- all maintained families healthy or explicitly accepted with documented reason;
- classification inventory reconciles exactly with current catalog;
- coverage state is truthful;
- Core/Hoomans/DT affected tests pass;
- real Tk authoring flows remain usable;
- CodeBuilder reconcile/integrity/determinism clean;
- canonical acceptance twice from one exact vector;
- exact participant HEADs + residual fingerprints;
- docs reconciled to one current truth.

## What S12 does not implement

S12 prepares and modernizes the dataset for emergent composition. It does not require a full autonomous Dialogue Director.

Do not add:

- unrestricted topic generation;
- global personality conversation planning;
- LLM-authored semantic branches;
- LLM-controlled gameplay actions/effects;
- unbounded nearby-NPC chatter;
- a second semantic planner/runtime.

A later director may discover/rank/compose the validated dataset.

## Completion invariant

S12 is complete when:

> all maintained first-party conversation source uses ConvoEngine v1; each semantic interaction has one canonical conversational authority; context-specific duplication is replaced by roles/slots/typed references where appropriate; wording-only duplication is realization; reusable interactions are composition-ready through beats/archetypes; gameplay authority remains in adopter systems; the modernization inventory matches the source catalog; the full dataset is tested/reconciled; and future deterministic runtime composition can bind live world/social context without inventing semantic or gameplay authority.
