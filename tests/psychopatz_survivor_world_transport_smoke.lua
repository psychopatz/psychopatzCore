local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local SERVER = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = table.concat({
    COMMON .. "?.lua",
    SERVER .. "?.lua",
    CLIENT .. "?.lua",
    package.path,
}, ";")

isClient = function() return false end
isServer = function() return true end

local player = {
    getUsername = function() return "transport-user" end,
}
getSpecificPlayer = function() return player end
getPlayer = function() return player end
getGameTime = function()
    return {
        getWorldAgeHours = function() return 20 end,
    }
end

local roots = {}
ModData = {
    get = function(key) return roots[key] end,
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
}

local serverHandlers = {}
local clientHandlers = {}
Events = {
    OnClientCommand = {
        Add = function(fn)
            serverHandlers[#serverHandlers + 1] = fn
        end,
    },
    OnServerCommand = {
        Add = function(fn)
            clientHandlers[#clientHandlers + 1] = fn
        end,
    },
    OnGameStart = { Add = function() end },
    OnCreatePlayer = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.COMMAND_MODULE = "PsychopatzCore"
PsychopatzCore.Debug = {
    CanUse = function() return true end,
}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] =
    function() return PsychopatzCore end

sendServerCommand = function(target, module, command, args)
    assert(target == player, "wrong discovery/projection target")
    for _, fn in ipairs(clientHandlers) do
        fn(module, command, args)
    end
end
sendClientCommand = function(current, module, command, args)
    assert(current == player, "wrong local player")
    for _, fn in ipairs(serverHandlers) do
        fn(module, command, current, args)
    end
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
Actors.DefaultRegistry = Actors.NewRegistry()
PsychopatzCore.Actors = Actors

local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
World.RuntimeStore.ResetForTests()
local registry = assert(World.ActivateRuntime({
    worldSeed = 2026,
}))
local plan = assert(World.Bootstrap.BuildPlan({
    seedString = "transport-fixture",
    anchor = { x = 7000, y = 8000, z = 0 },
    communityCount = 3,
    groupCount = 3,
}))
assert(World.Bootstrap.Commit(
    registry,
    plan,
    Actors.DefaultRegistry
))
assert(World.RuntimeStore.MarkDirty("transport_fixture"))

require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldProjectionServer"
local DiscoveryServer = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiscoveryServer"
local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"

assert(Client.RequestActors())
local actors = Client.ListActors(true)
assert(#actors == Actors.DefaultRegistry:Count(),
    "SurvivorWorld actor projection transport incomplete")
assert(actors[1].groupID or actors[1].communityID,
    "world context missing from transported actor")

assert(Client.RequestDiscovery())
assert(Client.GetDiscoverySnapshot().state == "known",
    "initial discovery snapshot missing")
assert(#Client.GetDiscoverySnapshot().entities == 0,
    "new player should not know world entities")

assert(Client.DiscoveryAction(
    "debug_discover_all",
    {
        scope = "communities",
        phase = World.Discovery.PHASE_LOCATED,
    }
))
local snapshot = Client.GetDiscoverySnapshot()
assert(#snapshot.entities == 3,
    "discover-all did not return all Core communities")
for _, entity in ipairs(snapshot.entities) do
    assert(entity.kind == "community",
        "discover-all scope leaked non-community entity")
    assert(entity.phase == World.Discovery.PHASE_LOCATED,
        "discover-all phase mismatch")
end

local stored = registry:GetDiscovery()
assert(stored.players["player:transport-user"],
    "server discovery action did not persist in Core world")
assert(World.RuntimeStore.Dirty == true,
    "discovery action did not dirty Core RuntimeStore")

assert(DiscoveryServer.ResolvePlayerKey(player)
    == "player:transport-user",
    "fallback player discovery key changed")

print("psychopatz_survivor_world_transport_smoke: PASS")
