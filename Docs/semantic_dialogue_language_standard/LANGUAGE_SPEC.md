# PSDL Language Specification — Authoring Contract

## 1. Document envelope

PSDL uses one versioned language envelope with a kind-specific body.

```json
{
  "schema": "psychopatz.semantic.dialogue-language.v1",
  "kind": "dialogue",
  "id": "social.wellbeing.check_in",
  "owner": "PsychopatzCore"
}
```

Initial supported `kind` values:

- `dialogue`;
- `behavior`;
- `beat`;
- `realization`.

Unknown kinds fail validation. New kinds require an explicit language-version decision; they are not inferred from filenames.

`owner` identifies the package/domain that owns the authored record and generated output. It does **not** identify a separate compiler implementation. The PSDL language/compiler remains PsychopatzCore-owned even when `owner` is `ProjectHoomans`, `DTCommon`, or another adopter.

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
  "schema": "psychopatz.semantic.dialogue-language.v1",
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

## 5. Full dialogue shape

```json
{
  "schema": "psychopatz.semantic.dialogue-language.v1",
  "kind": "dialogue",
  "id": "social.ask_person_location",
  "owner": "PsychopatzCore",

  "participants": {
    "speaker": ["player", "npc"],
    "addressee": ["player", "npc"]
  },

  "on": {
    "intent": "QUESTION",
    "subject": "PERSON_LOCATION",
    "recognition": "safe"
  },

  "slots": {
    "person": {
      "type": "entity.person",
      "required": true
    }
  },

  "when": {
    "path": "speaker.knowledge",
    "op": "exists"
  },

  "response": {
    "act": "ANSWER_LOCATION",
    "variants": [
      {
        "id": "known",
        "when": {
          "path": "slot.person.knownLocation",
          "op": "exists"
        },
        "turns": [
          {
            "id": "answer",
            "text": {
              "EN": [
                "{slot.person.name} is around {slot.person.knownLocation.name}."
              ]
            },
            "offers": [
              {
                "id": "ask.direction",
                "label": {
                  "EN": "Ask for directions"
                },
                "utterance": {
                  "EN": "Which way is that?"
                },
                "frame": {
                  "intent": "QUESTION",
                  "subject": "LOCATION_DIRECTION",
                  "target": "$slot.person"
                },
                "consumers": ["participant"]
              }
            ]
          }
        ]
      }
    ]
  }
}
```

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

## 9. Offers

An offer is a semantic continuation usable by an eligible participant.

```json
{
  "id": "ask.when",
  "label": {
    "EN": "Ask when it happened"
  },
  "utterance": {
    "EN": "When did it happen?"
  },
  "frame": {
    "intent": "QUESTION",
    "subject": "EVENT_TIME"
  },
  "consumers": ["participant"]
}
```

Supported consumer policy should distinguish semantic eligibility from presentation. Initial forms:

```text
participant
player
npc
```

`participant` is the normal reusable default.

Player UI may render an eligible offer as a button. NPC policy may consume the same offer as an affordance. Neither reparses rendered text.

## 10. Variants

Variants change realization while preserving semantic identity.

```json
{
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
      "when": {
        "path": "speaker.personality.aggression",
        "op": "gte",
        "value": 0.7
      },
      "text": {
        "EN": [
          "Fine. Leave it there."
        ]
      }
    }
  ]
}
```

Do not duplicate semantic logic solely to add wording variety.

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

Resolution is owned by semantic/entity resolvers. PSDL does not embed fuzzy algorithms.

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

Binding resolvers are registered typed services. Arbitrary function names or inline Lua are not valid PSDL.

## 13. Behavior modules

```json
{
  "schema": "psychopatz.semantic.dialogue-language.v1",
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

The exact compiled runtime structure may retain existing behavior records. PSDL is the authoring contract.

## 14. Beat modules

```json
{
  "schema": "psychopatz.semantic.dialogue-language.v1",
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

## 15. Effects and transitions

PSDL may declare typed semantic transitions/effects. It may not run arbitrary mutation code.

Transition examples:

```text
continue
await_participant
terminate
resume_previous
enter_flow
exit_flow
```

The final vocabulary must map to existing bounded lifecycle/runtime authority rather than create a second state engine.

Gameplay effects reference registered typed authorities.

## 16. Translation rules

- EN is mandatory fallback for first-party rendered text.
- Other locales are optional data.
- Placeholder sets must be validated per locale.
- Locale names are data, not hard-coded compiler branches.
- Runtime translation keys/paths are generated.

## 17. Validation requirements

PSDL compile must reject at least:

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
- duplicate semantic source in both PSDL and a superseded first-party authoring surface.

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
