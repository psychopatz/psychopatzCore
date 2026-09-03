local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local handlers = {}
local sent = {}
local clientHits = 0
local clientKills = 0

Events = {
    OnWeaponHitCharacter = {
        Add = function(handler) handlers.hit = handler end,
    },
    OnZombieDead = {
        Add = function(handler) handlers.dead = handler end,
    },
    OnClientCommand = {
        Add = function(handler) handlers.command = handler end,
    },
}

isClient = function() return true end
isServer = function() return false end
instanceof = function(value, className)
    return (className == "IsoPlayer" and value.kind == "player")
        or (className == "IsoZombie" and value.kind == "zombie")
end

local player = {
    kind = "player",
    getOnlineID = function() return 7 end,
    getPlayerNum = function() return 0 end,
    isLocalPlayer = function() return true end,
    getUsername = function() return "client" end,
    getZombieKills = function() return 12 end,
}
local zombie = {
    kind = "zombie",
    getOnlineID = function() return 42 end,
    getPersistentOutfitID = function() return 99 end,
    getAttackedBy = function() return player end,
    isDead = function() return true end,
    isOnKillDone = function() return true end,
}

getPlayer = function() return player end
getSpecificPlayer = function() return player end
sendClientCommand = function(receivedPlayer, module, command, args)
    sent[#sent + 1] = {
        player = receivedPlayer,
        module = module,
        command = command,
        args = args,
    }
end

PsychopatzCore = {
    COMMAND_MODULE = "PsychopatzCore",
}

local Detector = dofile(
    ROOT .. "PsychopatzCore/ZombieKillDetector/"
        .. "PsychopatzZombieKillDetector.lua"
)
Detector.RegisterConsumer("CoreClientSmoke", {
    onClientHit = function() clientHits = clientHits + 1 end,
    onClientKill = function() clientKills = clientKills + 1 end,
})

assert(handlers.hit and handlers.dead, "core client hooks registered")
handlers.hit(player, zombie, {}, 1)
handlers.dead(zombie)
assert(clientHits == 1, "client hit callback emitted")
assert(clientKills == 1, "client kill callback emitted")
assert(#sent == 1, "client kill report sent")
assert(sent[1].module == "PsychopatzCore", "core report module")
assert(sent[1].command == "ZombieKillReport", "core report command")
assert(sent[1].args.zombieOnlineID == 42, "core report zombie identity")
assert(sent[1].args.nativeZombieKills == 12, "core report native counter")
assert(Detector.GetNativeZombieKills(player) == 12,
    "core exposes the native zombie counter")

local fallbackZombie = {
    kind = "zombie",
    getOnlineID = function() return 43 end,
    getPersistentOutfitID = function() return 100 end,
    getAttackedBy = function() return nil end,
    isDead = function() return true end,
}
handlers.hit(player, fallbackZombie, {}, 1)
handlers.dead(fallbackZombie)
assert(#sent == 2, "client weapon-hit fallback report sent")
assert(sent[2].args.zombieOnlineID == 43,
    "fallback report uses the cached hit zombie")
assert(sent[2].args.killerSource == "weapon_hit_cache",
    "fallback report identifies its source")

print("psychopatz_zombie_kill_detector_client_smoke: ok")
