# Zombie kill detector

`PsychopatzCore.ZombieKillDetector` is an opt-in, reusable Project Zomboid
player-zombie-kill detector. It handles the engine's `OnWeaponHitCharacter`
and `OnZombieDead` events, native player kill-counter context, local/SP
identity, pure-MP client reporting, server validation, and short-lived
duplicate suppression.

Consumers register callbacks from their own shared/client/server composition:

```lua
local Detector = require
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"

Detector.RegisterConsumer("MyMod.Combat", {
    findZombieByOnlineID = function(onlineID) end,
    onClientHit = function(player, zombie, context) end,
    onClientKill = function(player, zombie, context) end,
    onServerHit = function(player, zombie, context) end,
    onServerKill = function(player, zombie, context) end,
})
```

`onServerHit` and `onServerKill` run only on authoritative runtimes. In pure
MP, the core sends one validated `ZombieKillReport` through the
`PsychopatzCore` command module and invokes `onServerKill` on the server.
Consumers should keep relationship, scoring, or reward mutations inside
`onServerKill`.

The native counter is also available directly as
`PsychopatzCore.ZombieKillDetector.GetNativeZombieKills(player)`.
