# Player animation controller

`PsychopatzCore.Animation.Player` is an opt-in, client-side controller for
testing or driving the current `IsoPlayer` through Project Zomboid's native
player-animation paths. It is available in the Build 42 client runtime and
does not depend on a mod-specific animation catalog or UI.

## Loading

Load the controller from a client Lua file after the Core mod is available:

```lua
require "PsychopatzCore/Animation/PsychopatzPlayerAnimationController"
local PlayerAnimation = PsychopatzCore.Animation.Player
```

The module installs one maintenance hook when `Events.OnTick` is available and
cleans up an owned preview on `Events.OnResetLua`. Do not install a second
maintenance loop in a consumer window.

## Entry contract

The controller accepts a catalog-neutral entry. A consumer owns the XML bridge
and metadata that produce the entry:

```lua
local entry = {
    playable = true,
    mode = "action", -- or "emote"
    state = "Loot",
    node = "LootHigh",
    anim = "Bob_IdleLooting_High",
    action = "Loot",
    variables = {
        { name = "LootPosition", kind = "STRING", value = "High" },
    },
    debugDuration = 120,
}
```

An action entry uses the native timed-action queue and applies
`setActionAnim`, `setAnimVariable`, and an optional event. An emote entry uses
`IsoPlayer:playEmote()` and the native emote state. The controller deliberately
does not access `AnimationPlayer`, zombie state machines, track priorities, or
raw animation time setters.

## Playback

```lua
local ok, reason, handle = PlayerAnimation.Play(nil, entry, {
    owner = "MyMod.AnimationPreview",
    loop = false,
    actionEvents = { Loot = "EventLootItem" },
})

if ok then
    -- Keep the opaque handle; another owner cannot stop this preview.
    PlayerAnimation.Stop(handle, "my_mod_done")
end
```

Passing `nil` as the player resolves `getSpecificPlayer(0)` and falls back to
`getPlayer()`. The resolved player must be local, alive, and not seated in a
vehicle. These checks keep the request on the local player's normal client
action/emote path in both singleplayer and multiplayer.

`loop = true` requeues a completed timed action or re-enters a completed emote
through the same native API. The controller observes normal emote cancellation
and does not defeat the player's cancel input.

`Stop` and `Replay` require the exact handle returned by `Play`. The controller
uses a single active owner and fails closed with `animation_owned_by_other` or
`animation_handle_not_active` rather than touching another system's action.

## Consumer responsibilities

Consumers should:

- generate or ship namespaced bridge XML under their own mod media path;
- provide only player-compatible action/emote entries to this controller;
- map consumer-specific action events through `actionEvents`;
- retain and use the returned handle for stop/replay;
- stop the handle when closing a preview or switching actors;
- treat `HoldCurrentFrame` and `SetHoldPose` as unsupported until a safe native
  player API exists.

The controller is intentionally not a zombie/NPC adapter. A future actor
adapter can reuse catalog metadata, but it must own the actor-specific route
and synchronization rules separately.
