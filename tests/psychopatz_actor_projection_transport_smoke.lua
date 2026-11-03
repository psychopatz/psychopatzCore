local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local SERVER = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = table.concat({
    COMMON .. "?.lua",
    SERVER .. "?.lua",
    CLIENT .. "?.lua",
    package.path,
}, ";")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Projection = Actors.Projection
Projection.ClientStore = Projection.NewStore()

local player = { id = "player:projection" }
getSpecificPlayer = function() return player end
getPlayer = function() return player end
isServer = function() return true end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.COMMAND_MODULE = "PsychopatzCore"
PsychopatzCore.Actors = Actors
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] =
    function() return PsychopatzCore end

local serverHandlers = {}
local clientHandlers = {}
local createPlayerHandlers = {}
Events = {
    OnClientCommand = {
        Add = function(callback) serverHandlers[#serverHandlers + 1] = callback end,
    },
    OnServerCommand = {
        Add = function(callback) clientHandlers[#clientHandlers + 1] = callback end,
    },
    OnGameStart = { Add = function() end },
    OnCreatePlayer = {
        Add = function(callback)
            createPlayerHandlers[#createPlayerHandlers + 1] = callback
        end,
    },
}

local serverPayloads = {}
sendServerCommand = function(target, module, command, args)
    assert(target == player, "projection sent to wrong player")
    serverPayloads[#serverPayloads + 1] = args
    for _, callback in ipairs(clientHandlers) do
        callback(module, command, args)
    end
end

sendClientCommand = function(current, module, command, args)
    assert(current == player, "projection request omitted local player")
    for _, callback in ipairs(serverHandlers) do
        callback(module, command, current, args)
    end
end

local authority = Actors.NewRegistry()
local actor = assert(authority:Create({
    actorId = "actor:projection:transport",
    identitySeed = "projection-transport",
    world = { position = { x = 20, y = 40, z = 0 } },
}))

local serverPositionX = 20
local Sync =
    require "PsychopatzCore/Actors/PsychopatzActorProjectionServer"
assert(Sync.RegisterProvider("fixture", {
    BuildEntries = function()
        local current = authority:Get(actor.actorId)
        local projected = assert(Projection.ProjectActor(current, 0, {
            sourceID = "fixture",
            provider = "DTAbstract",
            providerState = "abstract",
        }))
        projected.position.x = serverPositionX
        return { projected }
    end,
}))

local Client =
    require "PsychopatzCore/Actors/PsychopatzActorProjectionClient"

-- Real client request routes through the registered server command handler.
assert(Client.Request("fixture"))
local first = assert(Client.Get(actor.actorId))
assert(first.position.x == 20, "initial transport projection failed")
assert(#serverPayloads == 1, "server did not emit projection snapshot")
assert(tonumber(serverPayloads[1].payloadBytes)
    and serverPayloads[1].payloadBytes <= Projection.MAX_SNAPSHOT_BYTES,
    "server snapshot byte bound was not recorded")
local measured = assert(Projection.MeasureSnapshotBytes(serverPayloads[1]))
assert(measured <= Projection.MAX_SNAPSHOT_BYTES,
    "transport payload exceeded byte cap")

-- Oversized provider output is rejected before transport.
assert(Sync.RegisterProvider("oversize", {
    BuildEntries = function()
        return {{
            actorID = "actor:oversize",
            position = { x = 0, y = 0, z = 0 },
            junk = string.rep("x", Projection.MAX_SNAPSHOT_BYTES + 1024),
        }}
    end,
}))
local oversized, oversizedReason =
    Sync.BuildSnapshot("oversize", player, true)
assert(oversized == nil
    and oversizedReason == "projection_payload_too_large",
    "server did not reject oversized projection snapshot")

-- Client independently enforces the same cap.
local clientOversized, clientOversizedReason = Client.ApplySnapshot({
    schema = Projection.SCHEMA,
    schemaVersion = Projection.SCHEMA_VERSION,
    sourceID = "oversize-client",
    snapshotRevision = 1,
    entries = {},
    junk = string.rep("x", Projection.MAX_SNAPSHOT_BYTES + 1024),
})
assert(clientOversized == false
    and clientOversizedReason == "projection_payload_too_large",
    "client did not reject oversized projection snapshot")

-- Authority changes remain invisible until server publishes another revision.
serverPositionX = 75
assert(Client.Get(actor.actorId).position.x == 20,
    "client observed authority change without transport")
assert(Sync.Send(player, "fixture", true))
assert(Client.Get(actor.actorId).position.x == 75,
    "client did not receive updated transport projection")

-- An older snapshot cannot roll the client back.
local stale = serverPayloads[1]
for _, callback in ipairs(clientHandlers) do
    callback("PsychopatzCore", "ActorProjectionSnapshot", stale)
end
assert(Client.Get(actor.actorId).position.x == 75,
    "stale transport payload rolled client backward")

-- Reconnect/player recreation gets a fresh client store and requests a full
-- authoritative resync through the production OnCreatePlayer hook.
Client.Store = Projection.NewStore()
assert(#createPlayerHandlers == 1,
    "client reconnect hook was not registered")
createPlayerHandlers[1]()
local reconnected = assert(Client.Get(actor.actorId),
    "reconnect did not restore actor projection")
assert(reconnected.position.x == 75,
    "reconnect restored stale projection state")

print("psychopatz_actor_projection_transport_smoke: PASS")
