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

Client.DEFAULT_ACTOR_REFRESH_MS = 1000
Client.DEFAULT_DISCOVERY_REFRESH_MS = 10000
Client.LastActorRequestAt = Client.LastActorRequestAt or nil
Client.LastDiscoveryRequestAt = Client.LastDiscoveryRequestAt or nil

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return nil
end

local function commandModule()
    return PsychopatzCore.COMMAND_MODULE or "PsychopatzCore"
end

local function localPlayer()
    return getSpecificPlayer and getSpecificPlayer(0)
        or (getPlayer and getPlayer() or nil)
end

function Client.RequestActors()
    local ok, reason = ProjectionClient.Request(Client.SOURCE_ID)
    if ok then Client.LastActorRequestAt = nowMs() end
    return ok, reason
end

function Client.RequestActorsIfDue(intervalMs, force)
    intervalMs = math.max(
        0,
        tonumber(intervalMs) or Client.DEFAULT_ACTOR_REFRESH_MS
    )
    local now = nowMs()
    if force ~= true and now ~= nil
        and Client.LastActorRequestAt ~= nil
        and now - Client.LastActorRequestAt < intervalMs
    then
        return false, "not_due"
    end
    return Client.RequestActors()
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


function Client.GetPortraitSpec(actorOrID)
    local entry = type(actorOrID) == "table"
        and actorOrID
        or Client.GetActor(actorOrID)
    local portrait = entry and entry.portrait or nil
    if type(portrait) ~= "table"
        or type(portrait.face) ~= "table"
    then
        return nil
    end
    local face = portrait.face
    local gender = tostring(
        portrait.gender or face.gender or ""
    ):lower()
    return {
        key = tostring(portrait.actorID or entry.actorID)
            .. ":"
            .. tostring(portrait.schemaVersion or 0),
        actorID = portrait.actorID or entry.actorID,
        identitySeed = portrait.actorID or entry.actorID,
        isFemale = gender == "female"
            or gender == "f",
        preferDescriptor = true,
        faceOnly = true,
        includeCurrentClothing = false,
        appearance = {
            skinTexture = face.skinTexture,
            skinColor = face.skinColor,
            skinTone = face.skinTone,
            hairModel = face.hairModel,
            hairColor = face.hairColor,
            beardModel = face.beardModel,
        },
        equipment = { worn = {} },
    }
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
    Client.LastDiscoveryRequestAt = nowMs()
    return true
end

function Client.RequestDiscoveryIfDue(intervalMs, force)
    intervalMs = math.max(
        0,
        tonumber(intervalMs)
            or Client.DEFAULT_DISCOVERY_REFRESH_MS
    )
    local now = nowMs()
    if force ~= true and now ~= nil
        and Client.LastDiscoveryRequestAt ~= nil
        and now - Client.LastDiscoveryRequestAt < intervalMs
    then
        return false, "not_due"
    end
    return Client.RequestDiscovery()
end

function Client.RefreshIfDue(options)
    options = type(options) == "table" and options or {}
    local actorOK, actorReason = Client.RequestActorsIfDue(
        options.actorIntervalMs,
        options.force == true
    )
    local discoveryOK, discoveryReason =
        Client.RequestDiscoveryIfDue(
            options.discoveryIntervalMs,
            options.force == true
        )
    return {
        actors = actorOK == true,
        actorReason = actorReason,
        discovery = discoveryOK == true,
        discoveryReason = discoveryReason,
    }
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
