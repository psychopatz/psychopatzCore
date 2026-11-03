require "PsychopatzCore/00_PsychopatzCore_Init"

local Projection = require "PsychopatzCore/Actors/PsychopatzActorProjection"

PsychopatzCore.ActorProjectionClient =
    PsychopatzCore.ActorProjectionClient or {}

local Client = PsychopatzCore.ActorProjectionClient
Client.Store = Client.Store or Projection.ClientStore
Client.LastResult = Client.LastResult or nil

Client.COMMAND_SNAPSHOT = "ActorProjectionSnapshot"
Client.COMMAND_REQUEST = "ActorProjectionRequest"

local function commandModule()
    return PsychopatzCore.COMMAND_MODULE or "PsychopatzCore"
end

local function localPlayer()
    return getSpecificPlayer and getSpecificPlayer(0)
        or (getPlayer and getPlayer() or nil)
end

function Client.Request(sourceID)
    local player = localPlayer()
    if not player or type(sendClientCommand) ~= "function" then
        return false, "client_transport_unavailable"
    end
    local args = {}
    if sourceID and tostring(sourceID) ~= "" then
        args.sourceID = tostring(sourceID)
    end
    sendClientCommand(player, commandModule(), Client.COMMAND_REQUEST, args)
    return true
end

function Client.Get(actorID)
    return Client.Store:Get(actorID)
end

function Client.List(sourceID)
    return Client.Store:List(sourceID)
end

function Client.GetSourceRevision(sourceID)
    sourceID = tostring(sourceID or "")
    return tonumber(Client.Store.sourceRevisions[sourceID]) or -1
end

function Client.ApplySnapshot(payload)
    local ok, reason = Client.Store:ApplySnapshot(payload)
    Client.LastResult = {
        accepted = ok == true,
        reason = reason,
        sourceID = payload and payload.sourceID or nil,
        snapshotRevision = payload and payload.snapshotRevision or nil,
    }
    return ok, reason
end

local function onServerCommand(module, command, args)
    if module ~= commandModule() or command ~= Client.COMMAND_SNAPSHOT then
        return
    end
    Client.ApplySnapshot(args)
end

local function requestAll()
    Client.Request(nil)
end

if Events and Events.OnServerCommand and Events.OnServerCommand.Add
    and not Client._serverHook
then
    Client._serverHook = true
    Events.OnServerCommand.Add(onServerCommand)
end

if Events and Events.OnGameStart and Events.OnGameStart.Add
    and not Client._gameStartHook
then
    Client._gameStartHook = true
    Events.OnGameStart.Add(requestAll)
end

if Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add
    and not Client._createPlayerHook
then
    Client._createPlayerHook = true
    Events.OnCreatePlayer.Add(function() requestAll() end)
end

return Client
