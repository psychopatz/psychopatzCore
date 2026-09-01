# PsychopatzCore voice gateway

`PsychopatzCore.VoiceGateway` is an optional adapter from the canonical
`PsychopatzCore.Conversation.Message` event to the bounded Core packet
streams. It is intended for Project Hoomans and future mods to share without
making Core understand any mod's NPC data or TTS provider.

An integration registers a source:

```lua
PsychopatzCore.VoiceGateway.RegisterSource("MyMod", {
    bufferUntilReady = true,
    -- Set this only when the host calls VoiceGateway.Update() from its own
    -- existing safe tick; otherwise Core installs the tick callback itself.
    externalTick = false,
    filter = function(message)
        return message.speakerKind == "npc" or message.speakerKind == "player"
    end,
    enrich = function(message)
        return {
            voice_binding = {
                npc_uuid = message.speakerID,
                slot = "VoiceFemale:0",
                pitch = 0,
            },
        }
    end,
})
```

Player bindings use the same `slot` and `pitch` contract, but identify the
speaker with `speaker_kind = "player"`, `speaker_id`, and `player_uuid`.
Project Hoomans keeps that path opt-in through the Core `Sounds` in-game
setting; disabled player speech is rejected before a packet is queued.

Core publishes resolved text to `psychopatzcore.voice:utterances`. The stream
is bounded and ephemeral. Every packet includes the canonical message and
conversation identity, save-aware day/time, source mod, resolved text, and an
optional compact voice binding. Long text is capped for bridge safety while
the canonical conversation history remains unchanged.

PBrainZ consumes the channel through the existing `SpeechScheduler`. TTS is
therefore asynchronous and bounded; the game UI/nameplate can update before
audio finishes. `speechStarted`, `speechFinished`, and `speechFailed` are
optional lifecycle acknowledgements under `psychopatzcore.voice` and carry
metadata only, not audio bytes or full prompts.

When no source is registered, Core installs no message or tick listener. A
source may buffer briefly while the bridge is starting, but the buffer is
in-memory, bounded, and expires. This is not save data and is not a substitute
for the persistent conversation/memory stores.
