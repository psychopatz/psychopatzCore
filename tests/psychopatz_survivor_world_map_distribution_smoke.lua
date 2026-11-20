-- Comprehensive test for unified PsychopatzCore SurvivorWorld map & packet
-- distribution (SP + MP): many visible NPCs, moving NPCs, hidden/undiscovered
-- visibility culling, unchanged-skip, sub-quantum jitter suppression, and
-- targeted per-player delivery.

local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local SERVER = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = table.concat({
    COMMON .. "?.lua",
    SERVER .. "?.lua",
    CLIENT .. "?.lua",
    package.path,
}, ";")

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal")
            .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local serverMode = true
isClient = function() return false end
isServer = function() return serverMode end

local currentMs = 1000
getTimestampMs = function() return currentMs end
getGameTime = function()
    return { getWorldAgeHours = function() return 24 end }
end

local playerA = {
    getOnlineID = function() return 1 end,
    getUsername = function() return "alice" end,
    getX = function() return 1000 end,
    getY = function() return 1000 end,
}
local playerB = {
    getOnlineID = function() return 2 end,
    getUsername = function() return "bob" end,
    getX = function() return 9000 end,
    getY = function() return 9000 end,
}
local onlinePlayers = { playerA, playerB }
getOnlinePlayers = function() return onlinePlayers end
local activeLocalPlayer = playerA
getSpecificPlayer = function() return activeLocalPlayer end
getPlayer = function() return activeLocalPlayer end

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
        Add = function(fn) serverHandlers[#serverHandlers + 1] = fn end,
    },
    OnServerCommand = {
        Add = function(fn) clientHandlers[#clientHandlers + 1] = fn end,
    },
    OnGameStart = { Add = function() end },
    OnCreatePlayer = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.COMMAND_MODULE = "PsychopatzCore"
PsychopatzCore.Debug = { CanUse = function() return false end }
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] =
    function() return PsychopatzCore end

local packetsByPlayer = { alice = 0, bob = 0 }
local lastPayloadByPlayer = {}
sendServerCommand = function(target, module, command, args)
    local name = target:getUsername()
    packetsByPlayer[name] = (packetsByPlayer[name] or 0) + 1
    lastPayloadByPlayer[name] = args
    if target == activeLocalPlayer then
        for _, fn in ipairs(clientHandlers) do
            fn(module, command, args)
        end
    end
end
triggerEvent = function(eventName, module, command, args)
    if eventName == "OnServerCommand" then
        local name = activeLocalPlayer:getUsername()
        packetsByPlayer[name] = (packetsByPlayer[name] or 0) + 1
        lastPayloadByPlayer[name] = args
        for _, fn in ipairs(clientHandlers) do
            fn(module, command, args)
        end
    end
end
sendClientCommand = function(player, module, command, args)
    for _, fn in ipairs(serverHandlers) do
        fn(module, command, player, args)
    end
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
Actors.DefaultRegistry = Actors.NewRegistry()
PsychopatzCore.Actors = Actors

local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
World.RuntimeStore.ResetForTests()
local registry = assert(World.ActivateRuntime({ worldSeed = 9001 }))
assert(registry:UpsertFaction({
    id = "faction_visible_a",
    name = "Alice Survivors",
    archetypeID = "settler",
}))
assert(registry:UpsertFaction({
    id = "faction_visible_b",
    name = "Bob Survivors",
    archetypeID = "settler",
}))
assert(registry:UpsertFaction({
    id = "faction_hidden",
    name = "Hidden Nomads",
    archetypeID = "wanderer",
}))

local function addActor(id, factionID, x, y)
    local actor = assert(Actors.DefaultRegistry:Create({
        actorId = id,
        ownerMod = "ProjectHoomans",
        identity = { displayName = "NPC " .. id },
        providerLease = {
            owner = "ProjectHoomans",
            provider = "ProjectHoomans",
            state = "materialized",
            bodyID = "body:" .. id,
        },
        world = {
            location = {
                position = { x = x, y = y, z = 0 },
            },
        },
        extensions = {
            ["PsychopatzCore.SurvivorWorld"] = {
                factionID = factionID,
            },
        },
    }))
    return actor
end

-- 60 actors near Player A (1000, 1000)
for i = 1, 60 do
    addActor("actor_a_" .. tostring(i), "faction_visible_a",
        1000 + (i % 10) * 4, 1000 + math.floor(i / 10) * 4)
end
-- 10 actors near Player B (9000, 9000)
for i = 1, 10 do
    addActor("actor_b_" .. tostring(i), "faction_visible_b",
        9000 + i * 3, 9000 + i * 2)
end
-- 30 hidden distant actors at (5000, 5000) (out of range for both A and B)
for i = 1, 30 do
    addActor("actor_hidden_" .. tostring(i), "faction_hidden",
        5000 + i * 2, 5000 + i * 2)
end

-- Register a proximity visibility filter (simulating SP/MP server visibility culling)
local VISIBILITY_RADIUS = 150
assert(World.Presentation.RegisterEntryFilter("test:proximity_visibility", {
    filter = function(entry, _, _, player)
        if not player then return true end
        local dx = entry.position.x - player:getX()
        local dy = entry.position.y - player:getY()
        return (dx * dx + dy * dy) <= (VISIBILITY_RADIUS * VISIBILITY_RADIUS)
    end,
}))

local Sync = require
    "PsychopatzCore/Actors/PsychopatzActorProjectionServer"
local ProjServer = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldProjectionServer"
local SwClient = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"

Sync.ResetForTests()

-- 1. MP initial broadcast: each player gets ONLY its visible actors
local sentCount = ProjServer.Publish()
equal(sentCount, 2, "MP initial broadcast should reach both players")
equal(packetsByPlayer.alice, 1, "alice initial packet count")
equal(packetsByPlayer.bob, 1, "bob initial packet count")
equal(#lastPayloadByPlayer.alice.entries, 60,
    "alice must receive exactly 60 visible actors (not hidden or bob's)")
equal(#lastPayloadByPlayer.bob.entries, 10,
    "bob must receive exactly 10 visible actors (not hidden or alice's)")
equal(#SwClient.ListActors(true), 60,
    "alice client store populated with 60 visible actors")

-- 2. Unchanged broadcast: 0 packets sent to both players
local redundantSent = ProjServer.Publish()
equal(redundantSent, 0, "unchanged broadcast must send 0 packets")
equal(packetsByPlayer.alice, 1, "alice packet count unchanged")
equal(packetsByPlayer.bob, 1, "bob packet count unchanged")

-- 3. Periodic client poll with knownRevision when nothing changed: 0 server packets
currentMs = 2500
SwClient.RequestActorsIfDue(1000)
equal(packetsByPlayer.alice, 1,
    "periodic client poll with matching revision & digest must send 0 packets")

local livePositions = {}
assert(World.Presentation.RegisterPositionProvider("test:live_positions", {
    priority = 500,
    resolve = function(actor)
        return livePositions[actor.actorId]
    end,
}))

-- 4. Sub-quantum jitter (0.1 tiles < 0.5 quantum): 0 packets sent
local actorA1 = assert(Actors.DefaultRegistry:Get("actor_a_1"))
local baseA1X = actorA1.world.location.position.x
local baseA1Y = actorA1.world.location.position.y
livePositions["actor_a_1"] = { x = baseA1X + 0.1, y = baseA1Y, z = 0 }
equal(ProjServer.Publish(), 0, "sub-quantum jitter must send 0 packets")

-- 5. Hidden NPC moves 50 tiles (still invisible to both A and B): 0 packets!
livePositions["actor_hidden_1"] = { x = 5050, y = 5050, z = 0 }
equal(ProjServer.Publish(), 0,
    "moving invisible NPC must send 0 packets to all clients")

-- 6. Visible NPC near Alice moves 5 tiles: ONLY Alice receives a packet!
livePositions["actor_a_1"] = { x = baseA1X + 5, y = baseA1Y, z = 0 }
equal(ProjServer.Publish(), 1,
    "moving NPC near Alice must send packet ONLY to Alice")
equal(packetsByPlayer.alice, 2, "alice received movement update")
equal(packetsByPlayer.bob, 1, "bob received 0 packets for Alice's NPC")

-- 7. Hidden NPC enters Bob's visibility radius: ONLY Bob receives a packet!
livePositions["actor_hidden_1"] = { x = 9010, y = 9010, z = 0 }
equal(ProjServer.Publish(), 1,
    "NPC entering Bob's visibility must send packet ONLY to Bob")
equal(packetsByPlayer.alice, 2, "alice unaffected by Bob's new NPC")
equal(packetsByPlayer.bob, 2, "bob received update with newly visible NPC")
equal(#lastPayloadByPlayer.bob.entries, 11,
    "bob now sees 11 actors")

-- 8. SP mode check (isServer() == false, local player via triggerEvent)
serverMode = false
activeLocalPlayer = playerA
Sync.ResetForTests()
packetsByPlayer.alice = 0
equal(ProjServer.Publish(), 1, "SP initial publish sends 1 local snapshot")
equal(packetsByPlayer.alice, 1, "SP local player received snapshot")
equal(ProjServer.Publish(), 0, "SP unchanged publish sends 0 snapshots")
livePositions["actor_a_1"] = { x = baseA1X + 5, y = baseA1Y + 4, z = 0 }
equal(ProjServer.Publish(), 1, "SP moving visible NPC sends 1 update")

-- Cleanup filter/provider so they don't leak if required in a shared runner
World.Presentation.UnregisterPositionProvider("test:live_positions")
World.Presentation.UnregisterEntryFilter("test:proximity_visibility")

print("psychopatz_survivor_world_map_distribution_smoke: PASS")
