# ConvoEngine Actions, Results and Authoritative Gameplay Integration

## Purpose

This document defines how ConvoEngine interacts with gameplay/domain functions without
embedding arbitrary Lua or creating a second gameplay authority.

The required separation is:

```text
invoke
= semantic meaning

execute
= optional registered authoritative gameplay operation

result
= bounded typed public output from that operation
```

Dialogue may react to a result. It does not call arbitrary functions or inspect
mutable domain objects directly.

## Ownership

PsychopatzCore owns the generic:

- Semantic Action Contract registry;
- action-contract schema;
- input/output type validation;
- execution lifecycle vocabulary;
- bounded public `result.*` projection;
- correlation contract for asynchronous results;
- compiler validation of ConvoEngine `execute` references;
- generic observability/debug trace.

Adopters own domain execution:

- ProjectHoomans owns companion commands, camp placement, NPC tasks and other
  Hoomans-specific gameplay adapters;
- DynamicTrading/DTCommon owns trading/market mutation adapters;
- other adopters register their own domain action contracts.

Core must not absorb adopter gameplay policy merely because ConvoEngine can invoke it.

## One family owns conversational action policy

A registered action contract is gameplay execution authority. It does not justify
splitting one conversational interaction across several ConvoEngine families.

For a semantic action such as CAMP, the surviving canonical family should own:

~~~text
invoke.action
statePolicy
inputPolicy
repeatPolicy
postconditions
closure
execute
reply outcomes
after / continuation
~~~

Runtime may bind the current target/site/item/task/etc. and may execute the
registered action contract after admission. It must not search for another
project-owned family with the same action just to borrow missing policy.

If historical content/policy families are split this way, classify them as
`LEGACY_SPLIT_AUTHORITY`, migrate the complete policy into one canonical family,
retarget verification, prove caller/reference zero and delete the redundant
family without a forwarding shim.

## Existing Core ActionProviders are not execution contracts

The existing semantic ActionProvider registry collects candidate semantic
actions. It is useful for discoverability/affordance generation, but it is not
the mutation/execution contract described here.

Do not overload its `collect(context)` API with gameplay execution.

The action-execution contract is a separate generic Core mechanism.

## Registered Semantic Action Contract

A registered action contract exposes bounded metadata plus an implementation
adapter.

Conceptually:

```text
id
capability?
mode
inputs
result schema
outcome mapping
execute adapter
```

Example metadata for Hoomans camp:

```json
{
  "id": "pnc.companion.camp",
  "capability": "pnc:companion.camp",
  "mode": "request_response",

  "inputs": {
    "target": "entity.location",
    "scope": "token?"
  },

  "result": {
    "status": "token",
    "outcome": "token",
    "reason": "token?",
    "affected": "integer?",
    "data.site": "entity.location?"
  }
}
```

The actual adapter may route through existing Hoomans authorities such as the
companion-command dispatcher/server command handler. ConvoEngine never names those Lua
functions.

## ConvoEngine `execute`

The compact common form is:

```json
"execute": "pnc.companion.camp"
```

Use an object only when the family needs bounded per-use input mapping or
lifecycle policy:

```json
"execute": {
  "use": "pnc.companion.camp",
  "with": {
    "target": "$slot.location",
    "scope": "single"
  }
}
```

The compiler validates the referenced action contract and argument types.

Forbidden:

```json
"execute": {
  "lua": "PNC.CompanionCommands.Execute(...)"
}
```

or any arbitrary module/function-name invocation.

## Query versus execute

Read-only discovery and mutating execution are different contracts.

### Query/discovery

Use:

- typed slot candidate providers;
- context resolvers;
- binding resolvers;
- semantic/entity resolvers.

These may help produce:

```text
Make camp in the bedroom
Make camp by the campfire
```

without mutating the game.

### Execute

`execute` runs only after a semantic affordance/action has actually been
selected and has passed authority/safety gates.

Do not execute a mutating action merely to discover button candidates or format
a label.

## Bounded public result context

Raw implementation return tables are not exposed directly to ConvoEngine.

The action adapter projects the authoritative output into a bounded public
result context:

```text
result
├─ status
├─ outcome
├─ reason
├─ reasonClass?
├─ requestID?
├─ affected?
├─ target?
└─ data
   └─ ... bounded contract-declared fields
```

For camp, an adopter may project:

```text
result.data.site.id
result.data.site.name
result.data.site.kind
result.data.site.roomType
result.data.site.risk
```

The exact gameplay implementation may contain many more fields. Only
contract-declared public fields enter semantic dialogue context.

Private/internal data fails closed.

## Outcome normalization

Raw domain reasons are not the normal dialogue branch vocabulary.

Registered action contracts normalize implementation results into stable
semantic outcomes such as:

```text
pending
accepted
rejected
failed
completed
```

Domain-specific semantic outcomes may be added when they carry real meaning,
but raw implementation error strings should normally map to a bounded
`reasonClass` such as:

```text
out_of_range
unavailable
unsafe
no_target
conflict
permission_denied
```

Raw `result.reason` may remain available for diagnostics or exceptional
fine-grained predicates when explicitly safe/public.

## Synchronous and asynchronous lifecycle

The contract declares its execution mode. ConvoEngine does not repeat network/callback
details.

Supported conceptual modes:

```text
sync
request_response
long_running
```

A camp command may therefore behave as:

```text
select semantic affordance
        ↓
choose/speak initiating `say`
        ↓
execute pnc.companion.camp
        ↓
immediate result: pending
        ↓
optional pending reply
        ↓
authoritative server result: accepted/rejected/failed
        ↓
optional later completion result
        ↓
completed reply
```

Core/adopter runtime owns request IDs, server messages, callbacks and
correlation. Authors do not write those protocol details.

## Exchange family with execution

Recommended compact family:

```json
{
  "kind": "dialogue",
  "namespace": "command",
  "id": "camp",

  "invoke": {
    "intent": "REQUEST",
    "action": "CAMP"
  },

  "execute": "pnc.companion.camp",

  "affordance": {
    "label": "Make camp here"
  },

  "say": {
    "1": "Let's make camp here.",
    "2": "We'll stay here for now.",
    "3": "Set up camp here."
  },

  "reply": {
    "pending": {
      "say": {
        "1": "Alright. I'll start setting things up.",
        "2": "Got it. I'll get camp ready."
      }
    },

    "accepted": {
      "say": {
        "1": "I'll set up camp {camp.locationPhrase}.",
        "2": "Alright. We'll settle {camp.locationPhrase}."
      }
    },

    "rejected": {
      "say": {
        "1": "I can't make camp there.",
        "2": "That spot won't work."
      }
    },

    "completed": {
      "say": {
        "1": "We're set up {camp.locationPhrase}.",
        "2": "Camp's ready {camp.locationPhrase}."
      }
    }
  }
}
```

The initiating `say` realization and reply realization are independent.

There is no `say.1 -> reply.1` pairing.

## Reply branches and result selection

`reply` keys describe semantic outcomes, not wording identity.

Examples:

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

A branch may select on the normalized execution result:

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

If no branch-specific `after` exists, the family root `after` is the
fallback. Do not implicitly merge arbitrary branch/root recommendation graphs.

## Result bindings

Result data may feed ordinary typed bindings.

Example:

```json
"bindings": {
  "camp.locationPhrase": {
    "resolver": "pnc.camp.location_phrase",
    "from": "result.data.site"
  }
}
```

Then reply text may use:

```text
We're set up {camp.locationPhrase}.
```

Binding resolvers remain pure presentation/derivation services. They do not
authorize or perform mutation.

## Action result safety

The generic runtime must guarantee:

- action contract exists;
- capability/authority checks pass;
- declared input types match;
- mutating recovered/fuzzy targets still obey exact/confirm policy;
- result payload is bounded and schema-projected;
- unknown/private fields are unavailable to ConvoEngine;
- one semantic execution instance dispatches an action at most once unless the
  contract explicitly models idempotent retry;
- asynchronous results correlate to the correct semantic exchange;
- duplicate/stale results do not replay mutation or duplicate speech;
- result lifecycle transitions are bounded;
- execution timeout/cancellation is explicit where required;
- no ConvoEngine source can name arbitrary Lua functions.

## Semantic Lab requirements

Semantic Lab should display:

```text
family
→ invoke
→ execute contract
→ resolved typed inputs
→ authority/capability gate
→ dispatch
→ immediate result
→ authoritative result update(s)
→ normalized outcome/reasonClass
→ public result projection
→ selected reply branch
→ selected reply say/style/phrase
→ after continuation
```

For a camp example it should be possible to inspect the exact site/result data
that produced a line such as:

```text
"We're set up in the bedroom."
```

without exposing private runtime state or duplicating the gameplay evaluator.

## Migration guidance

Existing adopter action descriptors are valuable migration evidence.

For Hoomans CAMP, preserve the current authoritative behavior:

- existing command registry/dispatcher remains mutation authority;
- existing server validation remains authority;
- current typed slot/argument/capability/outcome knowledge is migrated into or
  projected through the new registered action contract;
- current ad-hoc result extraction is replaced gradually by bounded
  `result.*` projection and ordinary ConvoEngine bindings/reply branches;
- no gameplay behavior is moved into ConvoEngine source.

Migrate callers atomically and prove parity before deleting old response-routing
glue.

## Acceptance

This contract is accepted only when:

- Core owns one generic registered action/result mechanism;
- adopters keep actual gameplay execution/policy;
- ConvoEngine can reference an action contract without naming functions;
- compiler validates action references and typed inputs;
- runtime exposes bounded typed `result.*`;
- synchronous and asynchronous results are supported;
- normalized outcomes drive reply branches;
- result fields can feed ordinary predicates/bindings;
- query/discovery remains separate from mutation;
- duplicate/stale async results are safe;
- camp proves end-to-end parity using the existing authoritative gameplay path;
- Semantic Lab can explain the execution/result/reply trace;
- no arbitrary Lua/function callback authoring is introduced.
