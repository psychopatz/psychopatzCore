# Social flavor hub

`PsychopatzCore.SocialFlavor` is the shared, deterministic flavor registry.
`PsychopatzCore.SocialFlavorClient` is the client-only arbitration and
canonical-message publisher.  A consumer can register a definition and enqueue
an event without depending on a conversation window or a nameplate renderer.

```lua
require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

PsychopatzCore.SocialFlavor.Register("my_mod.gossip", {
    npc = { "I heard something about {name}." },
    variants = {
        {
            id = "hostile",
            when = { socialRole = "hostile" },
            npc = { "I am not telling you anything." },
        },
    },
})

PsychopatzCore.SocialFlavorClient.Enqueue({
    eventID = "my_mod:gossip:123",
    flavorID = "my_mod.gossip",
    family = "gossip",
    speakerID = "npc-123",
    priority = 35,
    weight = 1,
    context = { name = "the stranger", socialRole = "neutral" },
    llmEligible = true,
})
```

Priority is a hard class: critical alerts use `100`, client LLM flavor uses
`90`, and ordinary social flavor normally uses `35`.  Weight breaks ties only.
Events are bounded, deduplicated, mergeable, expire from the queue, and are
limited by family/speaker/cadence cooldowns.  Routine flavor is not copied to
durable LLM memory unless `memoryEligible = true` is set explicitly.

The server may send a compact event hint alongside an authoritative relationship
result, but never generates text or owns the queue.  In SP the existing local
server-command path delivers the hint to the same client handler used by MP.
The client adapter publishes a canonical Core conversation message, allowing
nameplates, conversation history, diary entries, voice, or future surfaces to
subscribe independently.
