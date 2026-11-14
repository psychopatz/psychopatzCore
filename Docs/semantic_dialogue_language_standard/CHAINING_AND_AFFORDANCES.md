# ConvoEngine Chaining, Affordances and Exchange Families

## Purpose

This document defines the compact authoring/runtime model for:

- player recommendation buttons;
- NPC-to-NPC semantic choices;
- dynamic button labels;
- actual player/NPC spoken lines;
- stable realization variety keys;
- reply outcomes and independent reply realization alternatives;
- typed slot expansion;
- relationship/trait/context-driven NPC choice;
- chained follow-up recommendations;
- optional authoritative gameplay execution;
- result-driven replies;
- automatic semantic continuation;
- end/resume navigation.

The goal is one semantic affordance system reused by players and NPCs.

## Exchange-family model

A reusable dialogue family represents one semantic interaction, not one wording
variant.

Recommended shape:

```text
family
├─ identity
│  ├─ kind
│  ├─ namespace
│  └─ id
├─ participants?
├─ slots?
├─ when?
├─ invoke
├─ execute?            # optional registered gameplay action
├─ affordance
│  ├─ label
│  ├─ groups?
│  ├─ priority?
│  ├─ utility?
│  └─ when?
├─ say                 # initiating actor's realization(s)
├─ reply               # named semantic reply outcomes
│  ├─ outcome_name
│  │  ├─ when?
│  │  ├─ say
│  │  └─ after?
│  └─ ...
└─ after?              # default post-exchange continuation
```

The semantic family identity is stable regardless of how many ways it can be
spoken.

## Button label versus actual speech

A button label is UI/navigation text. It is not necessarily first-person
speech.

Examples:

```text
Ask about {slot.person.name}
Ask about {slot.settlement.name}
Ask about {slot.item.name}
Warn about {slot.threat.name}
Offer {slot.item.name}
Ask for {slot.item.name}
Tell them to go to {slot.location.name}
```

The actual actor-spoken line belongs to `say`.

Example:

```text
button:
Ask about Bob

spoken:
"Hey, have you seen Bob lately?"
```

Core normalization emits explicit runtime text roles:

```text
button_label
spoken_action
response
```

Authors do not repeat a `type` field everywhere because structural position
already declares the role.

There is no automatic button-label -> spoken-action fallback.

## Stable realization keys

A family with one spoken realization may stay minimal:

```json
"say": "Who are you?"
```

When variation is needed:

```json
"say": {
  "1": "Who are you?",
  "2": "What's your name?",
  "4": "Who am I talking to?"
}
```

The numeric key is a stable realization handle only.

It is useful for:

- translation/editing stability;
- deterministic testing;
- diagnostics;
- anti-repeat history;
- source lineage.

It is **not** part of semantic family identity.

Do not generate semantic IDs such as:

```text
social.identity.ask_name.1
social.identity.ask_name.2
```

merely because the family has two wording alternatives.

Callers reference:

```text
social.identity.ask_name
```

Removing realization key `3` does not renumber `4`.

## Style/context variants inside a realization

A realization key may contain context/style variants:

```json
"say": {
  "1": {
    "variants": [
      {
        "id": "warm",
        "when": {
          "path": "relationship.speakerToAddressee.approval",
          "op": "gte",
          "value": 20
        },
        "text": {
          "EN": [
            "Hey, have you seen {slot.person.name} around?"
          ]
        }
      },
      {
        "id": "guarded",
        "text": {
          "EN": [
            "I'm looking for {slot.person.name}. Heard anything?"
          ]
        }
      }
    ]
  }
}
```

Keep these layers distinct:

```text
semantic family
→ realization key
→ style/context variant
→ localized phrase alternative
```

## Reply outcomes

Replies are independent from initiating wording.

Example:

```json
"reply": {
  "known": {
    "say": {
      "1": "{slot.person.name} is near Riverside.",
      "2": "Last I heard, {slot.person.name} was around Riverside."
    }
  },

  "unknown": {
    "say": {
      "1": "Sorry, I haven't seen {slot.person.name}.",
      "2": "No idea where {slot.person.name} is."
    }
  }
}
```

There is no pairing:

```text
initiator say.1 -> reply say.1
initiator say.2 -> reply say.2
```

The system independently selects:

1. semantic affordance;
2. initiating realization;
3. reply outcome;
4. reply realization/style/phrase.

Reply outcome names carry semantic meaning. Wording keys do not.

Useful outcome names include:

```text
known
unknown
accepted
rejected
refused
evasive
pending
failed
completed
```

## Reply-specific chaining

Continuation commonly depends on the reply outcome.

Example:

```json
"reply": {
  "known": {
    "say": "{slot.person.name} is in Riverside.",
    "after": {
      "recommend": [
        "navigation.ask_direction",
        "social.knowledge.ask_more"
      ]
    }
  },

  "unknown": {
    "say": "Sorry, I don't know.",
    "after": {
      "recommend": [
        "social.topic.change"
      ]
    }
  }
}
```

If a reply branch declares `after`, it wins for that exchange.

If it does not, the root family `after` is the fallback.

Do not silently merge arbitrary root and branch recommendation graphs.

## Dynamic text binding

Dynamic formatting uses bounded semantic bindings:

```text
{speaker.name}
{addressee.name}
{target.name}
{slot.person.name}
{slot.settlement.name}
{slot.item.name}
{slot.threat.name}
{slot.location.name}
{reference.faction.name}
{result.data.site.name}
```

Rendered text is never reparsed to recover semantic identity.

Required missing bindings fail closed.

## Affordance template versus bound instance

Authored source defines an AffordanceTemplate.

Runtime creates bounded AffordanceInstances by resolving slots/context.

Template:

```text
social.knowledge.ask_person
label = Ask about {slot.person.name}
```

Instances:

```text
ask_person + Bob
ask_person + Alice
ask_person + Kate
```

The bound entity identity/UUID is semantic authority. The formatted name is
presentation only.

## Typed slot candidate expansion

A typed slot may advertise a bounded candidate provider:

```json
"slots": {
  "person": {
    "type": "entity.person",
    "suggest": "knowledge.people",
    "limit": 4
  }
}
```

Other examples:

```json
"settlement": {
  "type": "entity.settlement",
  "suggest": "knowledge.settlements",
  "limit": 3
}
```

```json
"item": {
  "type": "entity.item",
  "suggest": "inventory.transferable",
  "limit": 4
}
```

Candidate providers are registered read-only services.

### Cartesian-product rule

Do not blindly multiply several independently enumerable slots.

Default:

> one independently enumerable slot per ordinary affordance.

If several dynamic values are required, a registered provider returns
compatible binding tuples.

## Query versus execute

Candidate discovery and gameplay mutation are different.

```text
query/discovery
→ slot candidate providers / context / bindings
→ read-only, bounded
→ can shape buttons and speech

execute
→ registered authoritative action contract
→ occurs only after semantic selection
→ may mutate gameplay
```

Do not execute a mutating action to discover recommendation candidates.

See `ACTIONS_AND_RESULTS.md`.

## Invoke versus execute

`invoke` describes semantic meaning:

```json
"invoke": {
  "intent": "REQUEST",
  "action": "CAMP"
}
```

`execute` optionally links that meaning to an authoritative gameplay action:

```json
"execute": "pnc.companion.camp"
```

ConvoEngine never embeds arbitrary Lua callbacks.

## Result-driven reply outcomes

If a family executes gameplay work, a bounded public `result.*` context may
select reply outcomes.

Example:

```json
"reply": {
  "pending": {
    "say": "Alright. I'll start setting things up."
  },

  "accepted": {
    "say": "I'll set up camp {camp.locationPhrase}."
  },

  "rejected": {
    "say": "I can't make camp there."
  },

  "completed": {
    "say": "We're set up {camp.locationPhrase}."
  }
}
```

The registered action contract normalizes implementation results into stable
semantic outcomes.

Reply variants may inspect bounded fields such as:

```text
result.outcome
result.reasonClass
result.data.site
```

Raw implementation tables are not public dialogue context.

## Async actions

Some actions have more than one result phase.

Camp can conceptually be:

```text
choose affordance
→ speak initiating say
→ execute
→ pending
→ later authoritative accepted/rejected/failed
→ later completed
```

The runtime owns correlation/request IDs and duplicate/stale result safety.

Authors do not write network callback names.

## Player and NPC reuse

Player projection:

```text
eligible bound affordance
→ format affordance.label
→ player selects
→ choose initiating say
→ speak
→ invoke/execute
→ reply outcome
→ reply say
```

NPC projection:

```text
eligible bound affordance
→ semantic utility scoring
→ NPC selects
→ choose initiating say
→ speak
→ invoke/execute
→ reply outcome
→ reply say
```

NPC policy does not need to read the literal button label.

## Hard eligibility versus preference

Hard `when` answers:

> can this action be selected?

`utility` answers:

> how attractive is this valid action to this NPC right now?

Example:

```json
"utility": {
  "curiosity": 0.9,
  "affiliation": 0.5,
  "intimacy": 0.3,
  "dominance": -0.2,
  "risk": 0.1
}
```

ProjectHoomans may derive the NPC preference vector from:

- traits;
- personality;
- mood;
- relationship;
- role;
- memory;
- task;
- danger;
- scene;
- conversation history.

Core stays generic.

Optional local preference modifiers reuse the shared predicate DSL.

## What versus how

Keep semantic selection and wording selection separate:

```text
WHAT action?
→ affordance eligibility + utility

HOW initiating actor says it?
→ say realization/style/phrase

WHAT reply meaning?
→ reply outcome selection

HOW responder says it?
→ reply outcome say realization/style/phrase
```

This prevents content explosion.

## Explicit recommendation references

```json
"after": {
  "recommend": [
    "social.identity.ask_name",
    "social.wellbeing.ask",
    "trade.open"
  ]
}
```

References target semantic families, not realization keys.

## Dynamic recommendation groups

A family may advertise:

```json
"affordance": {
  "label": "Ask how {addressee.name} is doing",
  "groups": ["check_in", "social"],
  "priority": 50
}
```

A caller may request:

```json
"after": {
  "recommend": {
    "group": "check_in",
    "limit": 6
  }
}
```

The resolver:

1. finds eligible target families;
2. creates bounded slot instances;
3. applies hard predicates;
4. checks consumer eligibility;
5. removes duplicates;
6. scores/ranks;
7. returns a bounded result set.

## NPC selection variability

NPCs should not always select mathematical rank 1.

After filtering/scoring, use bounded deterministic weighted choice among viable
top candidates.

Stable seed inputs may include:

```text
world/save seed
speaker identity
addressee identity
conversation identity
turn index
```

This keeps behavior varied but reproducible/debuggable.

## Same-speaker continuation

Use `turns` when one actor continues speaking within one realization.

Do not manufacture recommendation nodes merely to split one speech act across
two bubbles.

## Semantic chaining

Use:

```text
after.recommend
after.goto
after.end
after.resume
```

for post-exchange continuation.

`after.goto` is automatic semantic continuation and must be bounded/cycle-safe.

## Back/resume

Back/navigation is not ordinary dialogue content.

Core may provide a reserved navigation affordance such as
`resume_previous`. NPC semantic policy normally ignores presentation-only
navigation.

## Explicit offer escape hatch

A one-off continuation may inline an explicit offer:

```json
{
  "id": "ask.when",
  "label": "Ask when it happened",
  "invoke": {
    "intent": "QUESTION",
    "subject": "EVENT_TIME"
  },
  "say": "When did it happen?",
  "consumers": ["participant"]
}
```

It still normalizes to the same affordance contract.

## Runtime pipeline

```text
explicit family refs / recommendation group
              |
              v
       AffordanceTemplates
              |
              v
       bounded slot binding
              |
              v
       hard predicate filter
              |
              v
      AffordanceInstances
         /            \
        /              \
player projection     NPC projection
        |              |
format label       utility scoring
        |              |
player selects     weighted select
        \              /
         \            /
          selected instance
                |
                v
       choose initiating say
                |
                v
              speak
                |
                v
             invoke
                |
                v
         optional execute
                |
                v
      semantic/result outcome
                |
                v
          choose reply
                |
                v
        choose reply say
                |
                v
          responder speaks
                |
                v
    branch after / root after
```

## Boundedness and safety

At minimum:

- recommendation count never exceeds Core Offer limits;
- slot providers have hard limits;
- ordinary affordances avoid unbounded Cartesian products;
- automatic goto has a hop/depth budget;
- unconditional automatic cycles fail validation;
- semantic references are compile-time validated;
- private/unavailable bindings fail closed;
- missing label/speech bindings do not render unresolved placeholders;
- utility dimensions/modifiers are bounded;
- NPC selection is reproducible under equal context;
- mutating actions preserve existing exact/confirmation/authority policy;
- arbitrary function callbacks are forbidden;
- result payloads are bounded/schema-projected;
- stale/duplicate async results cannot replay mutation or duplicate speech.

## Semantic Lab requirements

The ConvoEngine UI should expose:

- family identity/invoke;
- UI-only affordance label;
- initiating `say` realizations;
- reply outcomes and their independent `say` realizations;
- style/context/locale variants;
- typed slot candidate providers;
- utility/preference data;
- execute action-contract picker;
- typed execute input preview;
- bounded result schema;
- result-driven reply outcome trace;
- searchable after.recommend references/groups;
- after.goto/end/resume;
- player button preview;
- initiating spoken-line preview;
- reply spoken-line preview;
- NPC candidate/score selection;
- bound slot/result preview;
- inclusion/exclusion trace;
- execute/result lifecycle trace.

The editor must visibly distinguish:

```text
BUTTON
Ask about Bob

INITIATOR SPEECH
"Have you seen Bob lately?"

REPLY
"Last I heard, Bob was near Riverside."
```

## Static suggestion migration

During migration:

1. move reusable UI labels to target family `affordance.label`;
2. move actual initiating speech to target family `say`;
3. organize responder content under meaningful `reply` outcomes where the
   exchange owns those replies;
4. preserve semantic meaning in `invoke`;
5. use `execute` only for registered authoritative gameplay work;
6. replace hub/static suggestion lists with family references/groups;
7. generate temporary compatibility UI projections downstream only;
8. prove player/NPC parity;
9. remove separate static suggestion authority after caller-zero.

Do not hand-edit generated StaticSuggestions output.

## Acceptance

Accepted only when:

- UI label and spoken dialogue are distinct roles;
- stable realization keys are not semantic family IDs;
- a single-line family does not require artificial `"1"`;
- reply outcomes are semantic and have independent realization alternatives;
- initiator and reply realization keys are never positionally paired;
- player and NPC share one semantic affordance candidate set;
- dynamic slot labels/speech use the same bound semantic instance;
- NPC selection can use relationship/traits/stats/context utility;
- NPCs never parse rendered button/speech strings for meaning;
- typed gameplay execution uses registered action contracts;
- bounded result data can drive reply outcomes and bindings;
- async result lifecycles are safe/correlated;
- static suggestions are no longer a separate semantic authority;
- chaining uses existing bounded runtime authorities;
- Semantic Lab exposes the complete reasoning/execution/reply trace.
