# S10 Label / Speech Realization Acceptance

**Status:** ACTIVE S10 acceptance specification.
**Authority:** `LANGUAGE_SPEC.md` remains the normative ConvoEngine authoring contract. This document defines the runtime/harness evidence required to prove that contract on real adopter surfaces.
**First concrete adopter case:** ProjectHoomans identity exchange.

## Problem statement

Fresh Semantic Lab testing exposed a presentation/realization regression:

```text
button label:
Say your real name

observed player transcript:
Say your real name
```

The player choice label describes the semantic action. It is not the line the
player character should literally speak.

ProjectHoomans already carries the authoritative canonical player name inside
the identity semantic frame, but the current identity suggestion source authors:

```text
label:     "Say your real name"
utterance: "My real name."
identityClaim.name = <canonical player name>
```

This proves that the data needed for grounded speech exists, but the current
realization path does not consistently bind it into natural player dialogue.

## Existing normative contract

Do not invent a competing mechanism for this fix.

The accepted ConvoEngine language contract already requires:

```text
semantic family / bound instance
        |
        +-- affordance.label  -> UI presentation only
        |
        +-- say               -> initiating spoken realization
        |
        +-- invoke            -> semantic/gameplay meaning
```

Rendered labels and rendered speech are presentation. Neither is semantic
authority, and neither may be reparsed to recover meaning.

A conversational affordance that implicitly uses its UI label as canonical
speech is invalid.

## Required implementation contract

### 1. UI label is never an implicit speech fallback

For conversational affordances, a missing/invalid `say` realization must fail
validation or produce an explicit bounded diagnostic. Runtime projection must
not silently substitute:

```text
affordance.label -> spoken line
```

Compatibility adapters may preserve older data only when the adapter has an
explicit migration owner and cannot leak the label to the player/NPC transcript.

### 2. Identity speech binds authoritative semantic slots

For the truthful identity choice, the bound semantic instance must carry the
canonical player identity:

```text
intent = INFORM
subject = IDENTITY
identityClaim.mode = canonical
identityClaim.name = <authoritative canonical player name>
```

The selected spoken realization then binds that value. Example equivalent
realizations include:

```text
"I'm Patrick."
"Patrick."
"My name's Patrick."
"It's Patrick."
"Name's Patrick."
"You can call me Patrick."
"I'm called Patrick."
"Patrick's my name."
"Just Patrick."
"The name's Patrick."
```

These examples are acceptance guidance, not a requirement to hard-code exactly
these ten strings. Canonical source should provide a healthy variant family
(approximately ten or more for high-frequency identity claims where wording
quality supports it) without changing semantic meaning.

### 3. Lie identity uses the same mechanism

The false-name choice must not remain a special concatenated runtime path.
Instead it binds the generated alias into the same typed identity-claim
realization contract:

```text
identityClaim.mode = generated
identityClaim.name = <generated alias>
```

Truthful and false claims differ by bound semantic data, not by separate
presentation architecture.

### 4. Semantic meaning is independent from wording

All natural variants of a truthful identity claim must dispatch the same
semantic frame and authoritative action. Changing wording must not change:

- intent;
- subject;
- identity claim mode;
- claimed name;
- server authority route;
- relationship/knowledge consequence.

The same rule applies to generated aliases.

### 5. Intentional label/speech equality is explicit

Some actions may naturally use the same short wording for label and speech
(e.g. a compact command such as "Follow me."). That equality is permitted only
when the canonical source explicitly authors both roles. It must never be the
result of a generic label-to-speech fallback chain.

## ProjectHoomans identity acceptance case

Add a focused real-runtime regression using a deterministic fixture player name
(for example `Patrick`) and the real PNC provider path.

The test must present the pending identity exchange, select the truthful
identity affordance, and prove all of the following:

```text
visible button label == "Say your real name"

player transcript line != "Say your real name"
player transcript line resolves the bound canonical player name

semantic frame:
  intent == INFORM
  subject == IDENTITY
  identityClaim.mode == canonical
  identityClaim.name == fixture player name

authoritative identity action receives the same canonical name

NPC response is grounded in the submitted identity claim

repeated realization may vary wording without changing semantic meaning
```

Also cover the generated-alias branch and refusal branch.

## Harness acceptance layers

This regression must exist at more than one layer.

### Focused source/compiler validation

Prove that canonical authoring distinguishes:

- `affordance.label` / runtime role `button_label`;
- initiating `say` / runtime role `spoken_action`;
- reply `say` / runtime role `response`.

Reject a conversational family whose initiating speech is absent and only a UI
label can satisfy the projection.

### Real PNC worker acceptance

Exercise the exact manifest-selected ProjectHoomans provider worker, not a
neutral Core substitute. The resulting semantic click/turn must preserve the
bound identity frame and produce grounded player speech.

### Real Semantic Lab GUI acceptance

Under Tk/Xvfb:

1. start Semantic Lab with the real PNC provider;
2. load/open a deterministic conversation fixture;
3. reach a pending identity exchange;
4. assert the response-channel button text is the UI label;
5. invoke the actual widget/controller path;
6. assert the conversation transcript contains a natural bound utterance;
7. assert the trace/interaction retains the typed semantic identity claim;
8. assert no label string is used as semantic authority;
9. repeat enough times or with deterministic salts to prove variant selection;
10. restart the worker and repeat to prove catalog stability.

Prefer stable feature IDs/controller seams over pixel coordinates.

## S10 interaction with current worker-startup work

This acceptance work does not replace the current S10A startup blocker.

Current dirty-work evidence has progressed from the original empty
`CONSUME.active` variant to a later real-worker startup failure:

```text
automatic semantic response registration failed:
pool=semantic.generated.multi_stage_gift.gift.failed
reason=response_pool_limit
capability=pnc:gift.offer
action=GIFT
```

The focused Lua preflight smoke passes, while the exact manifest-selected
provider-worker startup test remains red.

Do not hide this by raising `MAX_POOLS` without first proving why the automatic
catalog now reaches the limit. Audit duplicate/over-granular generated pools,
registration idempotence, and canonical ownership. S10A remains incomplete
until the real worker starts and restarts cleanly.

Once startup is restored, the label/speech identity regression becomes a
mandatory S10A/S10C acceptance case before the harness can be declared reliable.

## Cross-surface audit

After the identity case is fixed, audit maintained conversational affordances
for these failure classes:

- label authored but no initiating `say`;
- label copied into `textFallback` or `utteranceFallback` by projection;
- runtime fallback chain that permits `labelFallback` to become speech;
- manually concatenated dynamic speech that should be slot-bound `say`;
- generated affordance provider setting label and spoken text from one rendered
  value without an explicit semantic reason;
- locale variants whose placeholders differ between label and speech bindings.

Do not mass-rewrite all equal label/speech strings. Classify intentional
equality separately from accidental fallback coupling.

## Completion gate

This acceptance item is complete only when:

1. the exact PNC provider worker is green and catalog-stable;
2. compiler/source validation enforces UI-label vs spoken-role separation;
3. truthful identity binds the authoritative player name into natural `say`
   realizations;
4. generated aliases use the same typed realization mechanism;
5. focused real-worker tests prove semantic invariance across wording variants;
6. real Tk/Xvfb Semantic Lab acceptance proves the button label and transcript
   speech are different presentation roles;
7. the maintained affordance audit has no unexplained label-to-speech fallback;
8. all retained S10/S9 regression gates remain green.

Passing this one identity scenario is not parent-goal completion. Continue
through S10B-S10D and the full S10 completion gate.
