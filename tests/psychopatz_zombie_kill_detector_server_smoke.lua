local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local handlers = {}
local serverHits = 0
local serverKills = 0
local zombies = {}

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

isClient = function() return false end
isServer = function() return true end
instanceof = function(value, className)
    return (className == "IsoPlayer" and value.kind == "player")
        or (className == "IsoZombie" and value.kind == "zombie")
end

local player = {
    kind = "player",
    getOnlineID = function() return 7 end,
    getUsername = function() return "server" end,
    getZombieKills = function() return 12 end,
}
local nativeZombie = {
    kind = "zombie",
    getOnlineID = function() return 42 end,
    getPersistentOutfitID = function() return 99 end,
    getAttackedBy = function() return player end,
    isDead = function() return true end,
    getHealth = function() return 0 end,
}
local reportedZombie = {
    kind = "zombie",
    getOnlineID = function() return 43 end,
    getPersistentOutfitID = function() return 100 end,
    getAttackedBy = function() return nil end,
    isDead = function() return true end,
    getHealth = function() return 0 end,
}
local singlePlayerZombie = {
    kind = "zombie",
    getOnlineID = function() return -1 end,
    getPersistentOutfitID = function() return 101 end,
    getAttackedBy = function() return nil end,
    isDead = function() return true end,
    getHealth = function() return 0 end,
}
zombies = { nativeZombie, reportedZombie }

local zombieList = {
    size = function() return #zombies end,
    get = function(_, index) return zombies[index + 1] end,
}
getCell = function()
    return { getZombieList = function() return zombieList end }
end

PsychopatzCore = {
    COMMAND_MODULE = "PsychopatzCore",
}

local Detector = dofile(
    ROOT .. "PsychopatzCore/ZombieKillDetector/"
        .. "PsychopatzZombieKillDetector.lua"
)
Detector.RegisterConsumer("CoreServerSmoke", {
    onServerHit = function() serverHits = serverHits + 1 end,
    onServerKill = function(_, _, context)
        serverKills = serverKills + 1
        assert(context and context.source, "server kill context source")
        return true, "accepted"
    end,
})

assert(handlers.hit and handlers.dead and handlers.command,
    "core server hooks registered")
handlers.hit(player, nativeZombie, {}, 1)
handlers.dead(nativeZombie)
assert(serverHits == 1, "server hit callback emitted")
assert(serverKills == 1, "server native kill callback emitted")

-- Single-player can clear getAttackedBy before OnZombieDead. The authority
-- hit cache must preserve the player identity for the death callback.
isClient = function() return false end
isServer = function() return false end
handlers.hit(player, singlePlayerZombie, {}, 1)
handlers.dead(singlePlayerZombie)
assert(serverHits == 2, "single-player hit callback emitted")
assert(serverKills == 2,
    "single-player kill uses the authoritative hit fallback")

isServer = function() return true end

local report = {
    zombieOnlineID = 43,
    bodyInstanceID = 100,
    killerOnlineID = 7,
    nativeZombieKills = 13,
}
local accepted, reason = handlers.command(
    "PsychopatzCore",
    "ZombieKillReport",
    player,
    report
)
assert(accepted == true and reason == "accepted",
    "server accepts the validated core report")
assert(serverKills == 3, "server report callback emitted")

local duplicate, duplicateReason = handlers.command(
    "PsychopatzCore",
    "ZombieKillReport",
    player,
    report
)
assert(duplicate == false and duplicateReason == "duplicate_server_death",
    "server suppresses duplicate reports")
assert(serverKills == 3, "duplicate report did not emit another kill")

local invalid, invalidReason = handlers.command(
    "WrongModule",
    "ZombieKillReport",
    player,
    report
)
assert(invalid == false and invalidReason == nil,
    "unrelated commands are ignored")

print("psychopatz_zombie_kill_detector_server_smoke: ok")
