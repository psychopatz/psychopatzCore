require "PsychopatzCore/00_PsychopatzCore_Init"

local ProjectionClient = require
    "PsychopatzCore/Actors/PsychopatzActorProjectionClient"
local Presentation = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresentation"

PsychopatzCore.SurvivorWorldClient =
    PsychopatzCore.SurvivorWorldClient or {}

local Client = PsychopatzCore.SurvivorWorldClient

Client.SOURCE_ID = "SurvivorWorld"
Client.COMMAND_DISCOVERY_SNAPSHOT =
    "SurvivorWorldDiscoverySnapshot"
Client.COMMAND_DISCOVERY_REQUEST =
    "SurvivorWorldDiscoveryRequest"
Client.COMMAND_DISCOVERY_ACTION =
    "SurvivorWorldDiscoveryAction"

Client.DiscoverySnapshot =
    Client.DiscoverySnapshot or {
        state = "unknown",
        entities = {},
        revision = 0,
    }
Client.Selection =
    Client.Selection or Presentation.NewSelection()

local function commandModule()
    return PsychopatzCore.COMMAND_MODULE or "PsychopatzCore"
end

local function localPlayer()
    return getSpecificPlayer and getSpecificPlayer(0)
        or (getPlayer and getPlayer() or nil)
end

function Client.RequestActors()
    return ProjectionClient.Request(Client.SOURCE_ID)
end

function Client.ListActors(raw)
    local entries =
        ProjectionClient.List(Client.SOURCE_ID)
    if raw == true then return entries end
    return Presentation.SpreadOverlaps(entries)
end

function Client.GetActor(actorID)
    return ProjectionClient.Get(actorID)
end

function Client.RequestDiscovery()
    local player = localPlayer()
    if not player or type(sendClientCommand) ~= "function" then
        return false, "client_transport_unavailable"
    end
    sendClientCommand(
        player,
        commandModule(),
        Client.COMMAND_DISCOVERY_REQUEST,
        {}
    )
    return true
end

function Client.DiscoveryAction(action, args)
    local player = localPlayer()
    if not player or type(sendClientCommand) ~= "function" then
        return false, "client_transport_unavailable"
    end
    sendClientCommand(
        player,
        commandModule(),
        Client.COMMAND_DISCOVERY_ACTION,
        {
            action = tostring(action or ""),
            args = type(args) == "table"
                and args or {},
        }
    )
    return true
end

function Client.GetDiscoverySnapshot()
    return Client.DiscoverySnapshot
end

function Client.FindDiscovery(kind, entityID)
    kind = tostring(kind or "")
    if kind == "settlement" then kind = "community" end
    if kind == "mobile_group" then kind = "group" end
    entityID = tostring(entityID or "")
    for _, entity in ipairs(
        Client.DiscoverySnapshot.entities or {}
    ) do
        if tostring(entity.kind or "") == kind
            and tostring(entity.entityID or "") == entityID
        then
            return entity
        end
    end
    return nil
end

function Client.SetSelected(actorID)
    Client.Selection =
        Presentation.SelectActor(
            Client.Selection,
            actorID
        )
    return Client.Selection
end

function Client.SetHighlighted(actorID)
    Client.Selection =
        Presentation.HighlightActor(
            Client.Selection,
            actorID
        )
    return Client.Selection
end

function Client.SetTracked(actorID)
    Client.Selection =
        Presentation.TrackActor(
            Client.Selection,
            actorID
        )
    return Client.Selection
end

function Client.GetTracked()
    return Presentation.ResolveTracked(
        Client.ListActors(true),
        Client.Selection
    )
end

local function applyDiscovery(args)
    args = type(args) == "table" and args or {}
    Client.DiscoverySnapshot = args
    return true
end

local function onServerCommand(module, command, args)
    if module ~= commandModule()
        or command
            ~= Client.COMMAND_DISCOVERY_SNAPSHOT
    then
        return
    end
    applyDiscovery(args)
end

local function requestInitial()
    Client.RequestActors()
    Client.RequestDiscovery()
end

if Events and Events.OnServerCommand
    and type(Events.OnServerCommand.Add) == "function"
    and not Client._serverHook
then
    Client._serverHook = true
    Events.OnServerCommand.Add(onServerCommand)
end

if Events and Events.OnGameStart
    and type(Events.OnGameStart.Add) == "function"
    and not Client._gameStartHook
then
    Client._gameStartHook = true
    Events.OnGameStart.Add(requestInitial)
end

if Events and Events.OnCreatePlayer
    and type(Events.OnCreatePlayer.Add) == "function"
    and not Client._createPlayerHook
then
    Client._createPlayerHook = true
    Events.OnCreatePlayer.Add(requestInitial)
end

return Client
