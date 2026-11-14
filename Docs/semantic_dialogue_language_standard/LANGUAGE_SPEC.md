# ConvoEngine Authoring Contract

> Legacy/internal note: `PSDL` meant **Psychopatz Semantic Dialogue Language**. Treat `PSDL`/`psdl` identifiers as migration compatibility only; the target system name is **ConvoEngine**.

## 1. Document envelope

ConvoEngine uses one versioned conversation envelope with a kind-specific body.

For ordinary dialogue/content authoring, the preferred persisted form is one
compact **exchange family**. Semantic identity is written once; initiating
speech, reply outcomes, chaining, and optional gameplay execution live under
that family.

```json
{
  "schema": "psychopatz.convo-engine.v1",
  "kind": "dialogue",
  "namespace": "social.wellbeing",
  "id": "check_in",

  "invoke": { ... },
  "affordance": { ... },

  "say": {
    "1": "...",
    "2": "..."
  },

  "reply": {
    "positive": {
      "say": {
        "1": "...",
        "2": "..."
      }
    },
    "negative": {
      "say": "..."
    }
  }
}
```

Numeric keys under `say` are stable realization keys, not separate semantic
record IDs. A family with only one realization may author `say` directly as a
string or locale map.

The compiler normalizes compact source into explicit canonical IR. Runtime
systems do not consume authoring sugar directly.

Initial supported `kind` values:

- `dialogue`;
- `behavior`;
- `beat`;
- `realization`.

Unknown kinds fail validation. New kinds require an explicit language-version decision; they are not inferred from filenames.

`owner` identifies the package/domain that owns authored content and generated output. It does **not** identify a separate compiler implementation. The ConvoEngine language/compiler remains PsychopatzCore-owned even when resolved owner is `ProjectHoomans`, `DTCommon`, or another adopter. Ordinary adopter source may omit `owner` when manifest/shard/default ownership resolves it unambiguously.

## 2. IDs

Canonical IDs are lowercase dot-separated semantic identities.

Examples:

```text
social.wellbeing.check_in
social.identity.ask_name
task.fetch.status
behavior.social.warn
behavior.social.deescalate
beat.social.argument
beat.social.reconciliation
realization.social.acknowledge
```

IDs describe meaning, not implementation provenance.

Forbidden steady-state identity fragments include:

```text
generated
legacy
compat
old
v1
automatic_flow
parameterized_task
part02
part03
```

Version belongs in the schema/record metadata, not in semantic identity.

### 2.1 Compact exchange-family envelope

For ordinary dialogue/content, the preferred authoring unit is one semantic
exchange family:

```json
{
  "schema": "psychopatz.convo-engine.v1",
  "kind": "dialogue",
  "namespace": "social.knowledge",
  "id": "ask_person",

  "participants": {
    "speaker": ["participant"],
    "addressee": ["participant"]
  },

  "slots": {
    "person": {
      "type": "entity.person",
      "required": true
    }
  },

  "invoke": {
    "intent": "QUESTION",
    "subject": "PERSON_LOCATION",
    "target": "$slot.person"
  },

  "affordance": {
    "label": "Ask about {slot.person.name}"
  },

  "say": {
    "1": "Have you seen {slot.person.name} lately?",
    "2": "Do you know where {slot.person.name} is?"
  },

  "reply": {
    "known": {
      "when": {
        "path": "slot.person.knownLocation",
        "op": "exists"
      },
      "say": {
        "1": "{slot.person.name} is around {slot.person.knownLocation.name}.",
        "2": "Last I heard, {slot.person.name} was near {slot.person.knownLocation.name}."
      },
      "after": {
        "recommend": ["navigation.ask_direction"]
      }
    },

    "unknown": {
      "say": {
        "1": "Sorry, I haven't seen {slot.person.name}.",
        "2": "No idea where {slot.person.name} is."
      }
    }
  }
}
```

The semantic family identity is:

```text
social.knowledge.ask_person
```

It does **not** become `.1`, `.2`, etc. merely because there are multiple
ways to say it.

### 2.2 Owner and routing inheritance

`owner` may be omitted from a family source when the CodeBuilder
manifest/provider supplies an unambiguous owner through its shard/default
ownership contract.

The compiler resolves owner in this order:

1. explicit family/document owner;
2. manifest/shard owner;
3. manifest `defaultOwner`.

If ownership remains ambiguous, compilation fails.

### 2.3 Stable realization keys

When one semantic role has multiple authored realizations, persist them as a
numeric-keyed object:

```json
"say": {
  "1": "Who are you?",
  "2": "What's your name?",
  "4": "Who am I talking to?"
}
```

The key is a stable **realization identity**, not semantic meaning.

Removing key `3` does not rename `4`. Callers, semantic references and
recommendations reference the family/outcome, never wording key numbers.

When there is only one realization, compact source is preferred:

```json
"say": "Who are you?"
```

or:

```json
"say": {
  "EN": "Who are you?",
  "TL": "Sino ka?"
}
```

The compiler normalizes the single form into the same canonical realization
model.

A bare array may be accepted only as transient/editor sugar for brand-new
unreferenced wording. It is not the preferred persisted form because insert or
reorder would silently change realization identity.

### 2.4 Reply outcomes are semantic; wording keys are not

Reply branch names carry semantic meaning:

```text
known
unknown
accepted
rejected
refused
evasive
pending
completed
```

Each reply outcome owns its own independent `say` realization set.

There is no positional coupling:

```text
initiator say.1  !=  reply.known.say.1
initiator say.2  !=  reply.known.say.2
```

The initiating wording choice and reply wording choice are selected
independently from semantic/contextual eligibility.

### 2.5 Family, outcome, realization, style and phrase layers

ConvoEngine distinguishes:

1. **semantic family** — e.g. `social.knowledge.ask_person`;
2. **semantic reply outcome** — e.g. `known`, `unknown`, `refused`;
3. **stable realization key** — numeric `"1"`, `"2"`, ... under a `say` role;
4. **style/context variant** — neutral/warm/terse/guarded/etc.;
5. **phrase alternative** — multiple localized strings inside one variant.

Example:

```text
family: social.knowledge.ask_person

initiator say
  ├─ 1
  │  ├─ warm
  │  └─ guarded
  └─ 2
     ├─ warm
     └─ guarded

reply.known
  ├─ say.1
  └─ say.2

reply.unknown
  ├─ say.1
  └─ say.2
```

Semantic references stop at the family or meaningful outcome. Wording keys are
for realization stability, editing, translation, diagnostics and deterministic
selection.

## 3. Participant/reference syntax

Reserved actor-neutral references:

```text
speaker
addressee
target
initiator
observer
participants
slot
reference
relationship
scene
world
result
```

Common presentation accessors:

```text
{speaker.name}
{addressee.name}
{target.name}
{slot.person.name}
{slot.location.name}
```

Do not introduce new canonical variables such as `{npcName}` or `{playerFirstName}` for reusable content.

## 4. Simple dialogue

The common case should remain compact:

```json
{
  "schema": "psychopatz.convo-engine.v1",
  "kind": "dialogue",
  "id": "social.greeting.basic",
  "owner": "PsychopatzCore",
  "on": {
    "intent": "GREET"
  },
  "respond": {
    "EN": [
      "Hello, {addressee.name}.",
      "Hey there."
    ],
    "TL": [
      "Kumusta, {addressee.name}.",
      "Uy."
    ]
  }
}
```

The compiler expands `respond` into the canonical response/turn representation.

## 5. Full exchange-family shape

```json
{
  "schema": "psychopatz.convo-engine.v1",
  "kind": "dialogue",
  "namespace": "social.knowledge",
  "id": "ask_person",

  "participants": {
    "speaker": ["participant"],
    "addressee": ["participant"]
  },

  "slots": {
    "person": {
      "type": "entity.person",
      "required": true,
      "suggest": "knowledge.people",
      "limit": 4
    }
  },

  "invoke": {
    "intent": "QUESTION",
    "subject": "PERSON_LOCATION",
    "target": "$slot.person"
  },

  "affordance": {
    "label": "Ask about {slot.person.name}",
    "groups": ["social.info"],
    "utility": {
      "curiosity": 0.8
    }
  },

  "say": {
    "1": "Have you seen {slot.person.name} lately?",
    "2": "Do you know where {slot.person.name} is?"
  },

  "reply": {
    "known": {
      "when": {
        "path": "slot.person.knownLocation",
        "op": "exists"
      },
      "say": {
        "1": "{slot.person.name} is around {slot.person.knownLocation.name}.",
        "2": "Last I heard, {slot.person.name} was near {slot.person.knownLocation.name}."
      },
      "after": {
        "recommend": ["navigation.ask_direction"]
      }
    },

    "unknown": {
      "say": {
        "1": "Sorry, I haven't seen {slot.person.name}.",
        "2": "No idea where {slot.person.name} is."
      }
    }
  },

  "after": {
    "recommend": ["social.topic.change"]
  }
}
```

The initiating `say` and selected reply outcome are independent. If a reply
branch has its own `after`, that branch-specific continuation wins; otherwise
the family root `after` is the fallback.

A family that performs gameplay work may additionally declare `execute`; see
Section 15 and `ACTIONS_AND_RESULTS.md`.

## 6. Predicate authoring

Canonical predicate form remains explicit:

```json
{
  "all": [
    {
      "path": "speaker.traits",
      "op": "contains",
      "value": "Brave"
    },
    {
      "path": "relationship.speakerToAddressee.approval",
      "op": "gte",
      "value": 30
    }
  ]
}
```

The friendly DSL may accept compact sugar:

```json
{
  "speaker.traits": {
    "contains": "Brave"
  },
  "relationship.speakerToAddressee.approval": {
    ">=": 30
  }
}
```

Compiler normalization must produce the canonical form before runtime generation. The explicit canonical form remains valid for advanced cases.

## 7. Constraint placement

`when` may appear on:

- a dialogue/module;
- a response variant;
- a turn;
- an offer;
- a behavior;
- a beat candidate/modifier where supported.

All use the same predicate engine.

## 8. Turns

A turn is one delivered message from the same responder.

```json
{
  "turns": [
    {
      "id": "reaction",
      "text": {
        "EN": ["Yeah... I've been better."]
      }
    },
    {
      "id": "detail",
      "text": {
        "EN": ["Got hurt yesterday."]
      }
    }
  ]
}
```

Turns compile to the existing bounded ResponsePlan delivery path.

Do not create extra nodes merely to represent consecutive messages.

## 9. Affordances, recommendation labels, spoken actions and replies

The canonical concept is a semantic **affordance**. A player button and an NPC
choice are projections of the same bound semantic affordance instance.

ConvoEngine distinguishes:

- `affordance.label` — short UI/navigation label;
- family `say` — what the selecting actor actually says;
- `invoke` — semantic meaning dispatched;
- `execute` — optional registered authoritative gameplay action;
- `reply.<outcome>.say` — what the responder says after semantic/result
  outcome selection.

The label is not canonical speech and is never reparsed for meaning.

For compact source, structural position supplies text role. Core normalization
emits explicit runtime text roles such as `button_label`,
`spoken_action`, and `response`.

There is no automatic `button_label -> spoken_action` fallback.

### 9.1 Self-describing reusable affordance

```json
{
  "kind": "dialogue",
  "namespace": "social.identity",
  "id": "ask_name",

  "invoke": {
    "intent": "QUESTION",
    "subject": "IDENTITY"
  },

  "affordance": {
    "label": "Ask who they are",
    "consumers": ["participant"],
    "groups": ["check_in", "identity"],
    "priority": 50
  },

  "say": {
    "1": "Who are you?",
    "2": "What's your name?"
  },

  "reply": {
    "named": {
      "say": {
        "1": "I'm {addressee.name}.",
        "2": "Name's {addressee.name}."
      }
    }
  }
}
```

The semantic family remains `social.identity.ask_name`. Wording keys do not
become semantic IDs.

### 9.2 Dynamic label and speech binding

Button labels and speech may use the same bound semantic instance:

```text
Ask about {slot.person.name}
Ask about {slot.settlement.name}
Ask about {slot.item.name}
Warn about {slot.threat.name}
Offer {slot.item.name}
Ask for {slot.item.name}
Tell them to go to {slot.location.name}
```

Example:

```text
button:
Ask about Bob

initiating speech:
"Hey, have you seen Bob lately?"
```

The bound entity/reference identity is authority. Rendered names are
presentation only.

### 9.3 Spoken realization contract

A single realization may be compact:

```json
"say": "Who are you?"
```

Multiple stable realizations use numeric keys:

```json
"say": {
  "1": "Who are you?",
  "2": "What's your name?"
}
```

A keyed realization may itself own style/context variants:

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
          "EN": ["Hey, have you seen {slot.person.name} around?"]
        }
      },
      {
        "id": "guarded",
        "text": {
          "EN": ["I'm looking for {slot.person.name}. Heard anything?"]
        }
      }
    ]
  }
}
```

The same grammar applies independently to each reply outcome's `say`.

### 9.4 Reply outcomes

Reply keys describe meaning, not wording order:

```json
"reply": {
  "known": {
    "say": {
      "1": "{slot.person.name} is in Riverside.",
      "2": "Last I heard, {slot.person.name} was in Riverside."
    }
  },

  "unknown": {
    "say": {
      "1": "Sorry, I don't know.",
      "2": "No idea."
    }
  }
}
```

Initiator `say.1` does not pair with `reply.known.say.1`.

Outcome eligibility may use semantic context, relationship/knowledge state, or
bounded `result.*` after an executed action.

### 9.5 Compact recommendation references

```json
"after": {
  "recommend": [
    "social.identity.ask_name",
    "social.wellbeing.ask",
    "trade.open"
  ]
}
```

Recommendations reference semantic families, never wording keys.

### 9.6 Typed slot affordance instances

A family may define bounded candidate providers:

```json
"slots": {
  "person": {
    "type": "entity.person",
    "suggest": "knowledge.people",
    "limit": 4
  }
}
```

One source family may instantiate as:

```text
Ask about Bob
Ask about Alice
Ask about Kate
```

without generating new source families.

Ordinary affordances should expose at most one independently enumerable slot.
Multi-slot dynamic actions use a registered provider returning compatible
binding tuples.

### 9.7 Recommendation groups

```json
"affordance": {
  "label": "Ask how {addressee.name} is doing",
  "groups": ["check_in", "social"],
  "priority": 50
}
```

```json
"after": {
  "recommend": {
    "group": "check_in",
    "limit": 6
  }
}
```

The resolver creates bounded instances, applies hard eligibility, deduplicates,
scores/ranks and returns at most the requested limit.

### 9.8 NPC semantic choice

NPC policy uses the same bound affordance instances as player UI.

Hard `when` decides whether an action is valid. Optional `utility` describes
generic motivational meaning:

```json
"utility": {
  "curiosity": 0.9,
  "affiliation": 0.5,
  "intimacy": 0.3,
  "dominance": -0.2,
  "risk": 0.1
}
```

Adopters may derive the current speaker preference vector from traits,
personality, mood, relationship, memory, task, danger, scene and conversation
history. Core remains generic.

NPC policy never chooses meaning by parsing `affordance.label` or rendered
speech.

### 9.9 Advanced explicit offer

A one-off continuation may still inline an offer:

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

It normalizes to the same bounded affordance contract.

### 9.10 Compact chaining

ConvoEngine keeps runtime concepts distinct:

- `turns` = one actor continues one realization;
- `after.recommend` = expose semantic affordances;
- `after.goto` = automatic semantic continuation;
- `after.end` = terminate;
- `after.resume` = resume the previous recommendation context.

Normal reusable exchange:

```text
bind semantic instance
-> render button label for player if needed
-> player/NPC selects semantic affordance
-> choose initiating say realization/style
-> actor speaks
-> dispatch invoke
-> optional execute
-> normalize semantic/result outcome
-> choose reply outcome
-> choose reply say realization/style
-> responder speaks
-> apply reply-specific after, else root after
```

No rendered label or spoken string is reparsed for semantic meaning.

## 10. Realization keys, style variants and phrase alternatives

Numeric `say` keys are stable realization handles inside one semantic role.
They are not separate semantic records.

Style/context variants live inside one realization key and preserve the same
semantic meaning:

```json
"say": {
  "1": {
    "variants": [
      {
        "id": "warm",
        "when": {
          "path": "relationship.speakerToAddressee.approval",
          "op": "gte",
          "value": 40
        },
        "text": {
          "EN": [
            "I'm glad you're alright.",
            "Good to hear, {addressee.name}."
          ]
        }
      },
      {
        "id": "guarded",
        "text": {
          "EN": ["Fine. Leave it there."]
        }
      }
    ]
  }
}
```

Layers are:

```text
semantic family / reply outcome
    -> stable realization key
        -> style/context variant
            -> localized phrase alternative
```

Do not create new semantic family IDs merely to add wording variety or style.

## 11. Slots

Typed slot declarations are bounded and explicit.

```json
{
  "slots": {
    "person": {
      "type": "entity.person",
      "required": true
    },
    "location": {
      "type": "entity.location",
      "required": false
    }
  }
}
```

Resolution is owned by semantic/entity resolvers. ConvoEngine does not embed fuzzy algorithms.

## 12. Bindings

Common properties are implicit.

Derived values use bindings:

```json
{
  "bindings": {
    "direction": {
      "resolver": "spatial.direction",
      "from": "target.position"
    }
  },
  "text": {
    "EN": [
      "{target.name} is {direction} of here."
    ]
  }
}
```

Binding resolvers are registered typed services. Arbitrary function names or inline Lua are not valid ConvoEngine.

## 13. Behavior modules

```json
{
  "schema": "psychopatz.convo-engine.v1",
  "kind": "behavior",
  "id": "behavior.social.warn",
  "owner": "PsychopatzCore",
  "stimuli": ["HUMAN_UTTERANCE", "NPC_SEMANTIC_ACT"],
  "act": "BOUNDARY_WARNING",
  "when": {
    "path": "pragmatic.contextualAdmission.admitted",
    "op": "truthy"
  },
  "respondWith": "social.argument.warn",
  "baseRelevance": 0.65
}
```

The exact compiled runtime structure may retain existing behavior records. ConvoEngine is the authoring contract.

## 14. Beat modules

```json
{
  "schema": "psychopatz.convo-engine.v1",
  "kind": "beat",
  "id": "beat.social.argument",
  "owner": "PsychopatzCore",
  "group": "beat_group.social_primary",
  "stimuli": ["HUMAN_UTTERANCE", "NPC_SEMANTIC_ACT"],
  "entry": {
    "path": "stimulus.semantic.speechAct",
    "op": "in",
    "values": ["INSULT", "HOSTILE_REMARK", "THREATEN"]
  },
  "maintain": {
    "path": "history.hostilityCount",
    "op": "gt",
    "value": 0
  },
  "exit": {
    "any": [
      {
        "path": "stimulus.semantic.intent",
        "op": "eq",
        "value": "APOLOGIZE"
      },
      {
        "path": "scene.ended",
        "op": "truthy"
      },
      {
        "path": "world.immediateDanger",
        "op": "truthy"
      }
    ]
  },
  "candidates": [
    {
      "behavior": "behavior.social.warn",
      "relevance": 0.65
    },
    {
      "behavior": "behavior.social.deescalate",
      "relevance": 0.35
    }
  ],
  "cooldownTurns": 3,
  "maxTurns": 6
}
```

Friendly `enterOn`/`exitOn` sugar may be added only when it normalizes unambiguously to the same predicate/beat IR.

## 15. Effects, execution, results and transitions

ConvoEngine may declare typed semantic transitions/effects and may reference registered
authoritative action contracts. It may not run arbitrary mutation code or name
arbitrary Lua functions.

### 15.1 Semantic meaning versus gameplay execution

```text
invoke
= semantic meaning

execute
= optional registered authoritative gameplay operation

result
= bounded typed public output
```

Compact form:

```json
"execute": "pnc.companion.camp"
```

Per-use typed arguments:

```json
"execute": {
  "use": "pnc.companion.camp",
  "with": {
    "target": "$slot.location",
    "scope": "single"
  }
}
```

The compiler validates the registered contract and argument types.

### 15.2 Public result context

Only contract-declared bounded fields are exposed:

```text
result.status
result.outcome
result.reason
result.reasonClass
result.affected
result.target
result.data.*
```

Raw adopter return tables are not directly readable by ConvoEngine.

### 15.3 Result-driven replies

Execution contracts normalize raw implementation results into stable outcomes,
normally:

```text
pending
accepted
rejected
failed
completed
```

Those outcomes may directly select `reply` branches.

Example:

```json
"reply": {
  "rejected": {
    "variants": [
      {
        "when": {
          "path": "result.reasonClass",
          "op": "eq",
          "value": "out_of_range"
        },
        "say": "That spot's too far away."
      }
    ]
  }
}
```

### 15.4 Async lifecycle

Action contracts declare whether they are synchronous, request/response, or
long-running. ConvoEngine does not author request IDs, network command names or
callbacks.

Runtime owns correlation and may update one semantic exchange through:

```text
pending -> accepted/rejected/failed -> completed
```

Duplicate/stale results must not replay mutation or duplicate conversation
speech.

### 15.5 Query is not execute

Candidate providers, context resolvers and binding resolvers are read-only
discovery/derivation mechanisms. They may build dynamic labels or slots.

`execute` runs only after semantic selection and authority/safety gates.

### 15.6 Effects and transitions

Transition examples:

```text
continue
await_participant
terminate
resume_previous
enter_flow
exit_flow
```

Typed effects and action contracts map to existing bounded runtime/gameplay
authorities rather than create a second state or mutation engine.

See `ACTIONS_AND_RESULTS.md`.

## 16. Translation rules

- EN is mandatory fallback for first-party rendered text.
- Other locales are optional data.
- Placeholder sets must be validated per locale.
- Locale names are data, not hard-coded compiler branches.
- Runtime translation keys/paths are generated.
- New/steady-state ConvoEngine template IDs use `convo.<family>.<role>...`.
- ProjectHoomans steady-state conversation text domains use `pnc.convo.<domain>...`.
- Maintained conversation text output uses `Conversation/Text/convo/...`.
- `psdl.*`, `pnc.psdl.*`, and `Conversation/Text/psdl/` are migration-era identities and must not be emitted by steady-state ConvoEngine generation.
- Explicit migration readers may recognize legacy names only behind a bounded compatibility contract; they never write them.
- Generic provider-neutral semantic IR schema names are outside this text-identity rule unless separately reclassified as ConvoEngine-owned.

## 17. Validation requirements

ConvoEngine compile must reject at least:

- duplicate IDs;
- unknown module kinds;
- unsupported canonical fields;
- invalid semantic tokens;
- unresolved module/behavior/beat references;
- dangling offers/transitions;
- invalid predicate paths/operators/types;
- undefined slots;
- undefined placeholders/bindings;
- private/inaccessible bindings;
- locale placeholder mismatch;
- recursive/unbounded cycles;
- turn/offer/participant/constraint budget overflow;
- beat with no valid behavior candidate;
- duplicate semantic source in both ConvoEngine and a superseded first-party authoring surface;
- active ConvoEngine output that emits legacy `psdl.*`, `pnc.psdl.*`, or `Conversation/Text/psdl/` identity outside an explicitly classified migration-reader fixture;
- invalid/duplicate family namespace + root-ID identity;
- invalid/non-positive/non-integer/duplicate `say` realization keys;
- semantic references that incorrectly target wording realization keys;
- positional coupling between initiator and reply realization keys;
- ambiguous owner when neither file nor manifest/provider ownership resolves it;
- invalid/dangling `invoke`, `affordance`, `after.recommend`, or `after.goto` semantic references;
- invalid/missing `affordance.label` presentation bindings;
- conversational affordance that incorrectly uses its UI label as the canonical spoken line instead of a `say` realization;
- invalid/missing initiating or reply `say` bindings or locale placeholder mismatches;
- invalid/duplicate/unnamed reply semantic outcomes;
- invalid branch-specific `after` semantics;
- unbounded typed-slot candidate providers or accidental multi-slot Cartesian expansion;
- invalid/unbounded affordance utility dimensions or local preference modifiers;
- unknown/unregistered `execute` action contract;
- invalid `execute.with` input names/types;
- arbitrary Lua/module/function execution references;
- result predicates/bindings that access undeclared/private result fields;
- invalid/unbounded result schema or lifecycle transition;
- async action result without safe correlation/idempotence contract;
- unbounded unconditional automatic `after.goto` cycles;
- recommendation-group result limits above the bounded semantic-offer maximum;
- routine redundant `semantic.` canonical prefix after migration closure;
- source files mixing unrelated semantic families when modularity validation is enabled;
- generated ConvoEngine module leaves that collapse semantic identity into generic
  `Catalog.lua` naming.

## 18. No-new-legacy authoring

During migration, old source may be read only as existing migration input.

Do not add:

```text
Legacy/
Compat/
Old/
V1/
Migrated/
Part02/
```

copies to preserve first-party old content.

Do not add new production dialogue to old `nodes/choices/outcomes`, static suggestion catalogs, old response-pool-only authoring or old split translation files.

Convert the owning source directly to PSDL and delete the superseded first-party authoring source once parity/caller-zero acceptance is proven.
