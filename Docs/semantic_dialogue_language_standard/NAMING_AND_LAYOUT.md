# PSDL Naming and Source Layout Standard

## Purpose

This document is normative for new PSDL source organization. It exists to keep authoring discoverable for humans, Codebase Memory and coding agents as the catalog grows.

## Canonical source roots and ownership

The **PSDL language/compiler root is in PsychopatzCore**. Do not create a ProjectHoomans or DynamicTrading copy of the compiler/schema/IR.

Core canonical mechanism/source root:

```text
/home/psychopatz/Zomboid/Workshop/psychopatzCore/tools/semantic_harness/codebuilder/sources/conversation/
```

ProjectHoomans and DynamicTrading may keep adopter-owned PSDL recipe roots where their package/provider ownership requires it, but those roots contain domain records only and compile through the Core PSDL service. In particular, DynamicTrading's existing `tools/providers/dt/codebuilder/sources/conversation/` is mandatory migration input/adopter content, not a second language/compiler authority.

Target Core steady state:

```text
tools/semantic_harness/codebuilder/sources/conversation/
├─ manifest.json
├─ dialogue/
│  ├─ social/
│  ├─ knowledge/
│  ├─ task/
│  ├─ command/
│  ├─ combat/
│  └─ world/
├─ behaviors/
│  ├─ social/
│  ├─ tactical/
│  └─ task/
├─ beats/
│  ├─ social/
│  ├─ tactical/
│  └─ task/
└─ realization/
   ├─ social/
   ├─ tactical/
   └─ shared/
```

Add domain/subdomain directories only when they represent stable semantic ownership.

Do not create owner-named duplicate trees merely to route generated output. The source record/manifest owner controls package routing.

## Current pre-PSDL trees

Existing `content/`, `patterns/`, `flows/`, `ui/` and similar first-party authoring trees are migration inputs, not the target place for new dialogue.

Migrate by semantic domain into the target tree. Do not create a parallel `legacy/` tree before deletion.

## File naming

Use lowercase `snake_case.json` filenames that describe the cohesive semantic subject:

```text
check_in.json
person_location.json
argument.json
reconciliation.json
task_status.json
```

Avoid:

```text
Generated.json
CommonInteractions2.json
Part03.json
LegacyResponses.json
NewDialogue.json
FinalFixed.json
```

A file may contain a small cohesive set of records when they share one semantic concern. Do not create one file per sentence and do not create giant cross-domain aggregates.

## Canonical ID naming

Use lowercase dot-separated semantic IDs.

Recommended prefixes by kind:

```text
dialogue record:  social.wellbeing.check_in
behavior:         behavior.social.warn
beat:             beat.social.argument
realization:      realization.social.acknowledge
```

Do not repeat implementation terms such as `semantic`, `generated`, `codebuilder`, `automatic`, `runtime`, or source filename in the canonical identity unless the concept itself genuinely has that meaning.

## Translation keys

Authors normally do not write runtime translation-key boilerplate.

Keys are derived from canonical semantic identity plus stable local record identity. Generated translation paths follow package ownership.

Do not encode locale into canonical semantic IDs.

## Variant naming

Variant IDs describe semantic/style distinctions:

```text
neutral
warm
guarded
terse
aggressive
fearful
known
unknown
ambiguous
```

Avoid numeric identity unless the variants are intentionally semantically indistinguishable phrase alternatives. Phrase alternatives should normally be list entries with generated/stable compiler identity rather than author-visible `.001`, `.002` semantic IDs.

## Participant/reference naming

Use:

```text
speaker
addressee
target
initiator
observer
participants
slot.<semantic_name>
reference.<semantic_name>
```

Slot names describe role/meaning:

```text
slot.person
slot.item
slot.location
slot.settlement
slot.threat
```

Do not use actor implementation names:

```text
npc1
npc2
playerChar
targetNPC
otherHooman
```

unless a fixture is explicitly naming synthetic actors.

## Relationship naming

Directional relationship paths are explicit:

```text
relationship.speakerToAddressee
relationship.addresseeToSpeaker
```

Do not use ambiguous generic fields such as `relationshipWithPlayer` in new reusable source.

## Beat naming

Beat IDs describe temporary conversational state:

```text
beat.social.argument
beat.social.reconciliation
beat.social.suspicious_first_contact
beat.tactical.immediate_threat
```

Beat groups describe arbitration dimensions:

```text
beat_group.social_primary
beat_group.tactical
beat_group.task
```

Do not nest beat files beneath specific dialogue phrase files.

## Behavior naming

Behaviors are reusable strategies:

```text
behavior.social.warn
behavior.social.challenge
behavior.social.deescalate
behavior.social.reconcile
behavior.tactical.coordinate
```

A behavior ID must not include a particular speaker/NPC name or phrase wording.

## Generated output naming

Generated modules/shards describe semantic domain/kind, not arbitrary byte partition.

Numeric overflow names such as `Part02` are forbidden steady state. If a shard exceeds budget, split the source by semantic ownership.

Generated artifacts remain downstream-only and may be reorganized without changing canonical PSDL IDs.

## Migration naming rule

A migrated domain moves directly to its final semantic name.

Do not create intermediate names such as:

```text
social.wellbeing.v2
social.wellbeing.psdl
social.wellbeing.new
social.wellbeing.migrated
```

unless the semantic meaning itself changed and requires a distinct canonical identity.

## Discoverability rule

A coding agent looking for one semantic feature should normally need:

1. one PSDL source file or cohesive domain directory;
2. its shared language/runtime contract;
3. focused tests.

It should not need to open a separate EN file, TL file, static suggestion file, response pool, flow table, UI button registry and behavior wording file to understand one ordinary dialogue feature.
