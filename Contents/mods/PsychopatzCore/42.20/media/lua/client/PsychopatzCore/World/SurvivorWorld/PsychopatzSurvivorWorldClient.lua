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
Client.ACTOR_PRESENTATION_REFRESH_MS = 500
Client.DEFAULT_DISCOVERY_REFRESH_MS = 10000
Client.LastActorRequestAt = Client.LastActorRequestAt or nil
Client.LastDiscoveryRequestAt = Client.LastDiscoveryRequestAt or nil
Client.ActorKnowledgeProviders = Client.ActorKnowledgeProviders or {}
Client.ActorKnowledgeRequestAt = Client.ActorKnowledgeRequestAt or {}
Client.ACTOR_KNOWLEDGE_REQUEST_MS = 2000
Client.ActorPresentationCache = Client.ActorPresentationCache or nil

local function nowMs()
    if type(getTimestampMs) == "function" then
        local value = getTimestampMs()
        if tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        local value = getTimeInMillis()
        if tonumber(value) then return tonumber(value) end
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

-- Explicit inspection state shared by all map adopters. It never grants
-- discovery/identity facts and is checked again when permissions change.
function Client.CanUseDebugPresentation()
    local debugAPI = PsychopatzCore.Debug
    return debugAPI and type(debugAPI.CanUse) == "function"
        and debugAPI.CanUse(localPlayer()) == true or false
end

function Client.SetDebugPresentationEnabled(enabled)
    if enabled == true and not Client.CanUseDebugPresentation() then
        return false, "not_authorized"
    end
    Client.DebugPresentationEnabled = enabled == true
    return true
end

function Client.IsDebugPresentationEnabled()
    return Client.DebugPresentationEnabled == true
        and Client.CanUseDebugPresentation()
end

function Client.ListActors(raw)
    local entries = ProjectionClient.List(Client.SOURCE_ID)
    if raw == true then return entries end

    local now = nowMs()
    local sourceRevision = ProjectionClient.GetSourceRevision
        and ProjectionClient.GetSourceRevision(Client.SOURCE_ID) or -1
    local cached = Client.ActorPresentationCache
    local refreshMs = math.max(
        0,
        tonumber(Client.ACTOR_PRESENTATION_REFRESH_MS) or 500
    )
    if cached and cached.sourceRevision == sourceRevision
        and now ~= nil and cached.at ~= nil
        and now >= cached.at and now - cached.at < refreshMs
    then
        return cached.entries
    end

    local time = getGameTime and getGameTime() or nil
    local hour = time and time.getWorldAgeHours and time:getWorldAgeHours() or nil
    if hour and Presentation.ProjectActorPosition then
        local projected = {}
        for _, entry in ipairs(entries) do
            local copy = {}
            for key, value in pairs(entry) do copy[key] = value end
            copy.position = Presentation.ProjectActorPosition(entry, hour)
                or entry.position
            projected[#projected + 1] = copy
        end
        entries = projected
    end
    entries = Presentation.SpreadOverlaps(entries)
    Client.ActorPresentationCache = {
        sourceRevision = sourceRevision,
        at = now,
        entries = entries,
    }
    return entries
end

function Client.InvalidateActorPresentationCache()
    Client.ActorPresentationCache = nil
    return true
end

function Client.GetActor(actorID)
    return ProjectionClient.Get(actorID)
end

-- Provider-neutral identity knowledge seam.  Core owns the bounded request
-- lifecycle; an optional provider supplies only its transport/cache adapter.
-- This is deliberately independent of Project Hoomans so DTAbstract can use
-- the same conversation shell with only its canonical Core projection.
function Client.RegisterActorKnowledgeProvider(providerID, adapter)
    providerID = tostring(providerID or "")
    if providerID == "" or type(adapter) ~= "table"
        or (type(adapter.get) ~= "function"
            and type(adapter.request) ~= "function")
    then
        return false, "actor_knowledge_provider_invalid"
    end
    Client.ActorKnowledgeProviders[providerID] = adapter
    return true, providerID
end

local function knowledgeProvider(providerID)
    return Client.ActorKnowledgeProviders[tostring(providerID or "")]
end

local function discoveryFor(projection)
    if type(Client.FindDiscovery) ~= "function"
        or type(projection) ~= "table"
    then
        return nil
    end
    local groupID = tostring(projection.groupID or "")
    if groupID ~= "" then
        local group = Client.FindDiscovery("group", groupID)
        if group then return group end
    end
    local communityID = tostring(projection.communityID or "")
    if communityID ~= "" then
        return Client.FindDiscovery("community", communityID)
    end
    return nil
end

function Client.GetActorKnowledge(actorID, options)
    options = type(options) == "table" and options or {}
    actorID = tostring(actorID or "")
    if actorID == "" then return nil, "actor_required" end
    local projection = Client.GetActor(actorID)
    local providerID = tostring(options.provider
        or projection and projection.provider or "Core")
    local provider = knowledgeProvider(providerID)
    if provider and type(provider.get) == "function" then
        local ok, value = pcall(provider.get, actorID, options)
        if ok and type(value) == "table" then
            value.actorID = actorID
            value.provider = value.provider or providerID
            return value
        end
        -- An unavailable player-knowledge adapter must not fall back to
        -- the actor's raw display name and disclose an unknown identity.
        return nil, "actor_knowledge_unavailable"
    end
    if not projection then return nil, "actor_projection_unavailable" end
    local knownName = projection.displayName
        or projection.label
        or projection.identity and projection.identity.displayName
    local discovery = discoveryFor(projection)
    if discovery or tostring(projection.groupID or "") ~= ""
        or tostring(projection.communityID or "") ~= ""
    then
        local phase = discovery and tonumber(discovery.phase) or 0
        local contacted = phase >= 3
        return {
            actorID = actorID,
            provider = providerID,
            state = contacted and "known" or "unknown",
            nameKnown = contacted and knownName ~= nil
                and knownName ~= "" or false,
            knownName = contacted and knownName or nil,
            factionKnown = contacted and projection.factionID ~= nil
                or false,
            factionID = contacted and projection.factionID or nil,
            factionName = contacted and projection.factionName or nil,
            factionPresentation = contacted
                and projection.factionPresentation or nil,
            discoveryPhase = phase,
            revision = tonumber(projection.revision) or 0,
        }
    end
    return {
        actorID = actorID,
        provider = providerID,
        state = "known",
        nameKnown = knownName ~= nil and knownName ~= "",
        knownName = knownName,
        factionKnown = projection.factionID ~= nil,
        factionID = projection.factionID,
        factionName = projection.factionName,
        factionPresentation = projection.factionPresentation,
        revision = tonumber(projection.revision) or 0,
    }
end

function Client.RequestActorKnowledge(actorID, options)
    options = type(options) == "table" and options or {}
    actorID = tostring(actorID or "")
    if actorID == "" then return false, "actor_required" end
    local projection = Client.GetActor(actorID)
    local providerID = tostring(options.provider
        or projection and projection.provider or "Core")
    local provider = knowledgeProvider(providerID)
    local current = Client.GetActorKnowledge(actorID, {
        provider = providerID,
    })
    if current and (current.pending == true or current.knowledgePending == true
        or current.state == "loading")
    then
        return false, "actor_knowledge_pending"
    end
    if current and current.state == "known"
        and current.nameKnown ~= false
    then
        return true, "actor_knowledge_known"
    end
    if not provider or type(provider.request) ~= "function" then
        return true, "core_projection_used"
    end
    local now = nowMs()
    local last = tonumber(Client.ActorKnowledgeRequestAt[actorID])
    if now ~= nil and last ~= nil
        and now - last < Client.ACTOR_KNOWLEDGE_REQUEST_MS
    then
        return false, "actor_knowledge_request_throttled"
    end
    local ok, accepted, reason = pcall(
        provider.request, actorID, options)
    if not ok then return false, "actor_knowledge_request_failed" end
    if accepted == false then return false, reason end
    Client.ActorKnowledgeRequestAt[actorID] = now or 0
    return true, reason or "actor_knowledge_requested"
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
    local appearance = type(portrait.appearance) == "table"
        and portrait.appearance or {}
    if appearance.skinTexture == nil then
        appearance.skinTexture = face.skinTexture
    end
    if appearance.skinColor == nil then
        appearance.skinColor = face.skinColor
    end
    if appearance.skinTone == nil then
        appearance.skinTone = face.skinTone
    end
    if appearance.hairModel == nil then
        appearance.hairModel = face.hairModel
    end
    if appearance.hairColor == nil then
        appearance.hairColor = face.hairColor
    end
    if appearance.beardModel == nil then
        appearance.beardModel = face.beardModel
    end
    return {
        -- PortraitPanel keys the actual appearance/equipment; actor+schema
        -- alone would retain an old outfit forever after a new projection.
        actorID = portrait.actorID or entry.actorID,
        identitySeed = portrait.actorID or entry.actorID,
        isFemale = gender == "female"
            or gender == "f",
        preferDescriptor = true,
        faceOnly = true,
        includeCurrentClothing = true,
        clothingMode = "current",
        appearance = appearance,
        equipment = type(portrait.equipment) == "table"
            and portrait.equipment or { worn = {} },
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
    local id = Client.Selection and Client.Selection.trackedActorID
    if id == nil or tostring(id) == "" then return nil end
    -- The projection store already indexes actors. Listing here sorted the
    -- whole population on every map frame, including when nothing was tracked.
    local entry = Client.GetActor(id)
    if entry and (entry.sourceID == nil or entry.sourceID == Client.SOURCE_ID) then
        return entry
    end
    return nil
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
    -- ActorProjectionClient already requests all projection sources on
    -- OnGameStart/OnCreatePlayer. Avoid issuing a duplicate SurvivorWorld
    -- actor request here; this client owns only its discovery bootstrap.
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
