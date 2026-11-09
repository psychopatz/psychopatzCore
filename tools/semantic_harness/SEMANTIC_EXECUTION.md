# Semantic Harness execution boundary

P2 begins from an existing Core semantic engine, not a second conversation
implementation. Core already owns the parser/IR and actor conversation,
identity, social, knowledge, journey, and conversation-landing primitives under
`PsychopatzCore`.

## Core-neutral contract candidates

The shared harness must eventually expose typed seams for:

- actor/context projection from an opaque provider actor record;
- text and semantic-frame submission;
- relationship/identity snapshots;
- bounded turn/result projection;
- interaction-envelope creation and lifecycle operations;
- materialization mode (`abstract` versus `physical`) as capability metadata.

Each seam must accept provider callbacks or opaque namespaced payloads. Core
must not import PNC, Dynamic Trading merchant records, or Project Hoomans
fixture defaults.

## Current adopter boundary

Project Hoomans' worker conversation stack still owns PNC `DialogueInput`,
health/faction/knowledge presentation, companion authority dispatch,
translations, and the production interaction-lifecycle store. Its generic
turn counters and bounded delta collection are candidates for extraction, but
the current `Conversation_Context_Builder.lua`, `Conversation_Turn.lua`,
`OutputProjection.lua`, and `CommandRouter_InteractionLifecycle.lua` are
mixed files and must not be moved wholesale.

The first implementation chunk is now Core `worker/SemanticExecution.lua` plus
the Hoomans adapter wiring. It covers context, text, preview, frame, and
snapshot callbacks. Interaction is intentionally optional and currently fails
closed when an adopter has not registered that callback. Only after both
providers can run through the contract may generic turn/result or interaction
modules move and Hoomans duplicates be deleted.
