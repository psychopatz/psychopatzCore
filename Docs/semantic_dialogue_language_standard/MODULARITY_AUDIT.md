# ConvoEngine Modularity and Generated-Naming Audit — 2026-11-13

## Audit conclusion

This document began as the S6M0 pre-normalization audit. Those original
measurements are retained as historical evidence.

The S6M3-S6M8 implementation corrected the large flat-source and generated
`Catalog.lua` defects. The **2026-11-14 post-S8 closure audit below is the
current state** and reopens only final naming/audit/document closure as S8R.

Never interpret the historical measurements as permission to hand-edit
generated Lua.

## Pre-normalization measured source shape

At S6M0, ProjectHoomans had:

- 80 PSDL JSON files;
- all 80 directly under one flat `psdl/dialogue/` directory;
- 25 source files above 32 KiB;
- 12 source files above 64 KiB;
- 19 files with more than 16 top-level records;
- 11 files with more than 24 top-level records;
- largest source: `task_tool_replies.json`, 128,652 bytes / 46 records.

Representative monoliths:

```text
task_tool_replies.json                 128,652 B / 46 records
task_lifecycle.json                    110,734 B / 40 records
companion_commands_lifecycle.json      101,374 B / 35 records
social_interaction_scene_horde_work.json 82,931 B / 28 records
social_interaction_scene_travel_news.json 82,121 B / 28 records
social_reactions_ack_dispute.json       79,255 B / 28 records
social_tool_replies_affirmation.json    73,376 B / 25 records
social_emotes.json                      70,731 B / 30 records
health_content.json                     70,249 B / 24 records
```

Core is smaller but still has avoidable aggregates, including
`psdl/director/social.json` with 29 behaviors plus 3 beats in one file.

DynamicTrading's current three-record trader source is already small enough,
but it must adopt the same language/layout rules.

## Realization system — numeric wording keys are intentional

Numeric `1`, `2`, `3`, etc. remain useful, but their final role is now
explicit:

> they are stable realization keys under a semantic text role, not separate
> semantic family identities.

The current migration mixes:

- wording-only numbered semantic IDs;
- genuinely different semantic outcomes;
- migrated source buckets;
- style/tone top-level records;
- phrase variants.

Steady-state PSDL distinguishes:

1. **semantic family** — what the interaction means;
2. **reply outcome** — meaningful responder result/state;
3. **realization key** — stable wording alternative under initiating or reply
   `say`;
4. **style/context variant**;
5. **localized phrase alternative**.

Recommended compact exchange family:

```json
{
  "kind": "dialogue",
  "namespace": "social.knowledge",
  "id": "ask_person",

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
  }
}
```

The semantic family remains:

```text
social.knowledge.ask_person
```

Do not expand wording alternatives into
`social.knowledge.ask_person.1/.2`.

A family with one realization may use direct `say` shorthand. With multiple
alternatives, numeric keys remain stable; gaps may remain after deletion.

During migration, each existing numbered semantic ID must be classified:

- wording-only number -> move to a `say` realization key;
- real semantic difference -> give it a meaningful family/outcome name;
- migration shard number -> remove after parity/caller-zero.

## Style duplication defect

The current migration frequently represents styles as separate semantic
records. Example:

```text
semantic.interaction.scene.horde_prompt.neutral
semantic.interaction.scene.horde_prompt.warm
semantic.interaction.scene.horde_prompt.terse
semantic.interaction.scene.horde_prompt.guarded
```

All four point to the same `responseTemplateID` and each contains ten phrase
variants. They are one semantic family/style matrix, not four unrelated
semantic identities.

PSDL already supports context/style variants. The corrected model is one
semantic family with stable wording realizations:

```text
social.scene.horde.prompt

say.1
  variants:
    neutral
    warm
    terse
    guarded

say.2
  variants:
    neutral
    warm
    terse
    guarded
```

The numeric keys are realization handles, not global semantic IDs. Style can
remain part of canonical identity only when it changes semantic meaning or is
an externally referenced semantic contract, not merely wording selection.

Current measured evidence:

- Hoomans: 804 PSDL records;
- 623 records are style-like top-level records;
- at least 66 response-template families have multiple top-level records for
  what is primarily style/context variation.

## Redundant canonical ID defect

Current Hoomans records:

- 804 total records;
- 715 begin with `semantic.` (~88.9%).

Examples:

```text
semantic.interaction.argument.deescalate.guarded
semantic.question.wellbeing.default.neutral
semantic.tool_reply.order_camp.1
semantic.command.follow.queued.trusted
```

The language itself is already semantic, so `semantic.` is redundant.

Correct steady-state IDs should describe meaning rather than wording order:

```text
social.argument.deescalate
wellbeing.check_in
command.camp
command.follow
```

Meaningful outcomes such as accepted/rejected/known/unknown belong in named
reply/result semantics when needed. Numeric wording alternatives belong under
`say` realization keys.

Style/relationship conditions belong inside realization variants when possible.

## File/module organization defect

Current Hoomans source is flat:

```text
psdl/dialogue/*.json
```

Target layout is hierarchical and semantic:

```text
psdl/
  dialogue/
    social/
      argument/
        deescalate.json
        retaliate.json
      scene/
        horde/
          prompt.json
          brave_reply.json
          cautious_reply.json
          steady_reply.json
        post_combat/
          clear.json
        excursion/
          preparing.json
          departing.json
          returning.json
          home.json
          failed.json
        work/
          assigned.json
          completed.json
    task/
      fetch/
        lifecycle.json
      eat/
        lifecycle.json
      drink/
        lifecycle.json
    command/
      follow/
        lifecycle.json
        replies.json
      camp/
        lifecycle.json
        replies.json
```

One source file owns one coherent semantic family/module. A family may contain
many initiating/reply realization alternatives and localized phrase alternatives;
the purpose is semantic cohesion, not an arbitrary one-record-per-file rule.

## Generated `Catalog.lua` root cause

The screenshot is produced by generator policy, not by manually named files.

Current `conversation_compiler.py`:

1. groups PSDL runtime plans by `(owner, kind, domain)`;
2. derives `domain` from the current broad source/domain bucket;
3. always calls `module_path(..., [kind.title(), domain, "catalog"], ...)`.

Therefore output is intentionally generated as:

```text
PSDL/Dialogue/CombatBanterWeaponKillBrave/Catalog.lua
PSDL/Dialogue/SocialInteractionArgument/Catalog.lua
...
```

This is the root cause of the vague leaf name.

Do not rename generated files manually.

The generator must instead route from the final CodeBuilder semantic source
module path and flattened runtime prefix:

```text
source:
sources/conversation/dialogue/social/argument/deescalate.json

runtime:
<Owner>/ConvoEngine/Dialogue/Social/Argument/Deescalate.lua
```

and:

```text
source:
sources/conversation/dialogue/social/scene/horde/brave_reply.json

runtime:
<Owner>/ConvoEngine/Dialogue/Social/Scene/Horde/BraveReply.lua
```

Generated provenance remains metadata/header/manifest information, not a
`Generated` or `PSDL` runtime directory.

The repository already contains shared collision-safe naming helpers in
`catalog_naming.py`; the ConvoEngine generator should reuse/extend those helpers
rather than creating a second naming algorithm.

Generated modules remain downstream-only.

## Migration metadata residue

Across the current 1,029 PSDL records in Core + Hoomans + DynamicTrading:

- ~71% have `metadata.sourceSurface`;
- ~71% have `metadata.responseTemplateID`;
- ~60% have `metadata.contentOwner`;
- ~75% have `metadata.category`.

Much of this is migration-era duplication.

Steady state:

- actual source lineage comes from the compiler's source path;
- owner comes from the PSDL envelope/provider routing;
- response/template identity should derive from canonical family + semantic
  role/outcome + realization key only when an accepted runtime seam genuinely
  needs an explicit external ID;
- category should be derived from semantic namespace where possible;
- deleted legacy `sourceSurface` paths must not remain as routine authoring
  metadata.

Do not remove metadata blindly. First identify runtime consumers, introduce
derived compiler projections, update callers/tests, prove parity, then delete
redundant authored metadata.

## Audit/tooling defect

The current source audit primarily uses byte thresholds:

```text
preferred: 64 KiB
hard:      128 KiB
```

That is insufficient. A semantically coherent realization-heavy family may be
larger than a tiny file containing several unrelated families.

The new modularity audit must measure at least:

- semantic families per source module;
- source namespace/path agreement;
- number of initiating/reply realization keys and named reply outcomes;
- style records that can be collapsed under one family/realization;
- redundant `semantic.` prefixes;
- stale migration metadata;
- broad/miscellaneous filenames such as `*_content.json`,
  `*_responses.json`, or combined multi-topic names;
- generated `Catalog.lua` leaves;
- source/generated lineage parity.

Primary rule: **one file = one coherent semantic family/module**.

Size thresholds are secondary review signals, not the definition of modularity.

## Recommendation/button/reply/action duplication defect

Current first-party suggestion authoring still demonstrates migration
duplication: button presentation, initiating speech, reply routing and gameplay
result handling may live in separate catalogs/adapters.

The compact steady-state family is self-describing:

```text
family
├─ invoke
├─ execute?                 # registered typed gameplay action
├─ affordance.label         # UI-only recommendation label
├─ affordance utility/...   # constraints/groups/priority/utility
├─ say                      # initiating speech realization(s)
├─ reply
│  ├─ meaningful_outcome
│  │  ├─ say
│  │  └─ after?
│  └─ ...
└─ after?
```

Callers chain with semantic family references or bounded groups.

Player buttons and NPC choices consume the same bound affordance instances.

If gameplay execution is involved, Core's generic registered action-result
mechanism exposes only bounded public `result.*`; adopter gameplay remains
authoritative. Reply outcomes may react to normalized results without
camp/trade-specific routing duplicated in the dialogue engine.

Read-only candidate discovery remains separate from mutation.

See `CHAINING_AND_AFFORDANCES.md` and `ACTIONS_AND_RESULTS.md`.

## Post-S8 closure audit — 2026-11-14

A fresh audit after the claimed S8 completion confirms that the architectural
migration is largely successful but final naming/closure is incomplete.

Verified current source shape:

```text
Core ConvoEngine family files        126
ProjectHoomans family files          429
DTCommon family files                 11
total                                566

files >32 KiB                          0
files >64 KiB                          0
top-level records-array families       0
legacy source-schema families          0
```

The explicit three-repository S6M8 audit reproduces:

```text
ok=true
familyFilesChecked=566
psdlDirectories=0
catalogLuaLeaves=0
legacyRuntimeDirectories=0
convoPlans=566
determinism.fileCount=404
determinism.diffs=[]
violationCount=0
```

The two remaining Hoomans hand-authored runtime files named
`PNC/ConvoEngine/Social/Catalog.lua` and
`PNC/ConvoEngine/Interaction/Catalog.lua` are not the old generated
`.../<domain>/Catalog.lua` defect and must not be counted as generated leaves
unless a separate naming refactor proves they should change.

### S8R active legacy-name leakage closure

The pre-S8R audit previously missed active legacy identity outside canonical
source-folder and generated-module-path checks.

Measured pre-S8R residue vs resolved S8R steady state:

```text
generated/runtime psdl.* occurrences
  Core       57 -> 0
  Hoomans   524 -> 0
  DTCommon   10 -> 0

Hoomans canonical pnc.psdl.* textDomain entries    38 -> 0
Hoomans Conversation/Text/psdl translation files   76 -> 0
direct first-party Conversation/Text/psdl callers   3 -> 0
```

Root causes resolved in **S8R2**:

- Core `psdl_compiler.py` (`_offer_runtime_projection`,
  `_response_plan_projection`) and `conversation_compiler.py` (`"ConvoEngine"`
  manifest/report shard kind) now emit `convo.*` offer/turn template keys and
  ConvoEngine shard identity rather than generating Lua edits by hand.
- ProjectHoomans canonical `pnc.psdl.*` text domains (`38` families) migrated via
  CodeBuilder `SemanticLabAuthoringService.migrate_legacy_text_identity` to
  `pnc.convo.*`, and regenerated translations moved cleanly under
  `Conversation/Text/convo/` alongside atomic updates to the three direct
  first-party runtime callers (`PNC_ConversationComposer_GiftPresentation.lua`,
  `PNC_ConversationComposer_SettlementAdmission.lua`,
  `PNC_ConversationDefinition_Lifecycle_Open.lua`), `DialogueBlocks.lua`, and
  `DTHoomans_Conversation.lua` (`convo_referral_plan_unavailable`).
- Zero-caller obsolete alias `tools/semantic_harness/studio/psdl_authoring_pane.py`
  was deleted.

Steady-state identity enforced by `convo_engine_psdl_inventory.py` and
`convo_engine_s6m8_audit.py`:

```text
psdl.<...>        -> convo.<...>
pnc.psdl.<...>    -> pnc.convo.<...>
Conversation/Text/psdl/... -> Conversation/Text/convo/...
```

Only explicit bounded migration readers/test fixtures retain old PSDL
identity (`46` classified bounded fixtures/readers). Generic provider-neutral
Semantic IR contracts (`psychopatz.semantic.dialogue-ir.v1` and `Semantics/`
runtime modules) remain classified as generic semantic infrastructure (`0`
violations).

### Audit CLI discovery closure

Previously, bare `convo_engine_cli.py audit-s6m8 --check-determinism` failed to
discover sibling participant repositories cleanly.

**S8R3** added `discover_convo_engine_repositories` in
`convo_engine_s6m8_audit.py` and wired `SemanticLabAuthoringService.run_convo_engine_s6m8_audit(require_all_owners=True)`
so bare CLI invocations unambiguously resolve `PsychopatzCore`,
`ProjectHoomans`, and `DTCommon` from workspace siblings/env markers or fail
closed (`CompileError` / `missing_mandatory_repository`), never silently passing
a partial single-owner run.

### Documentation closure

**S8R4** reconciled and committed the full goal-owned normative documentation
set (`ARCHITECTURE.md`, `LANGUAGE_SPEC.md`, `NAMING_AND_LAYOUT.md`,
`AGENT_RUNBOOK.md`, `ROADMAP.md`, `PROGRESS.md`, `HANDOFF.md`,
`CONVO_ENGINE.md`, `MODULARITY_AUDIT.md`, `CHAINING_AND_AFFORDANCES.md`,
`ACTIONS_AND_RESULTS.md`, and `S8R1_PSDL_CLASSIFICATION.json`), recording the
exact committed repository HEADs and preserved unrelated working-tree items.

## Non-goals

- do not remove useful stable realization keys merely to reduce content variety;
- do not collapse all phrase variety into one string;
- do not hand-edit generated Lua;
- do not create a second PSDL compiler or naming system;
- do not change runtime semantic IDs without updating all first-party callers
  atomically;
- do not add permanent broad legacy aliases merely to preserve bad migrated
  names;
- do not split one coherent family into meaningless Part01/Part02 shards.

## Required completion

S8 cannot close until the source layout, canonical IDs, realization/reply/action-result
contracts, Semantic Lab authoring UX, generated module naming, and generated
lineage all agree on this modular model.
