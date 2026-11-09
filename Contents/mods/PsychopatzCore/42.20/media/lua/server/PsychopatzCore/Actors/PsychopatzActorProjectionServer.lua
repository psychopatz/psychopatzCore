require "PsychopatzCore/00_PsychopatzCore_Init"

local Projection = require "PsychopatzCore/Actors/PsychopatzActorProjection"

PsychopatzCore.ActorProjectionSync = PsychopatzCore.ActorProjectionSync or {}
local Sync = PsychopatzCore.ActorProjectionSync

Sync.COMMAND_SNAPSHOT = "ActorProjectionSnapshot"
Sync.COMMAND_REQUEST = "ActorProjectionRequest"
Sync.Providers = Sync.Providers or {}
Sync.Revisions = Sync.Revisions or {}
Sync.Dirty = Sync.Dirty == true
Sync.LastDirtyReason = Sync.LastDirtyReason or nil

local function commandModule()
    return PsychopatzCore.COMMAND_MODULE or "PsychopatzCore"
end

local function localPlayer(player)
    local current = getSpecificPlayer and getSpecificPlayer(0) or nil
    return current ~= nil and current == player
end

local function send(player, payload)
    if localPlayer(player) and type(triggerEvent) == "function" then
        triggerEvent("OnServerCommand", commandModule(),
            Sync.COMMAND_SNAPSHOT, payload)
        return true
    end
    if player and type(sendServerCommand) == "function" then
        sendServerCommand(player, commandModule(),
            Sync.COMMAND_SNAPSHOT, payload)
        return true
    end
    if type(triggerEvent) == "function"
        and (not isServer or not isServer())
    then
        triggerEvent("OnServerCommand", commandModule(),
            Sync.COMMAND_SNAPSHOT, payload)
        return true
    end
    return false
end

local function eachPlayer(callback)
    if isServer and isServer() and getOnlinePlayers then
        local players = getOnlinePlayers()
        if players and type(players.size) == "function"
            and type(players.get) == "function"
        then
            for index = 0, players:size() - 1 do
                callback(players:get(index))
            end
            return
        elseif type(players) == "table" then
            for _, player in ipairs(players) do callback(player) end
            return
        end
    end
    if getSpecificPlayer then
        local player = getSpecificPlayer(0)
        if player then callback(player) end
    end
end

function Sync.MarkDirty(reason)
    Sync.Dirty = true
    Sync.LastDirtyReason = tostring(reason or "unspecified")
    return true
end

function Sync.ConsumeDirty()
    if Sync.Dirty ~= true then return false end
    Sync.Dirty = false
    Sync.LastDirtyReason = nil
    return true
end

function Sync.IsDirty()
    return Sync.Dirty == true
end

function Sync.RegisterProvider(sourceID, provider)
    sourceID = tostring(sourceID or "")
    if sourceID == "" or type(provider) ~= "table"
        or type(provider.BuildEntries) ~= "function"
    then
        return false, "invalid_projection_provider"
    end
    Sync.Providers[sourceID] = provider
    Sync.Revisions[sourceID] = Sync.Revisions[sourceID] or 0
    return true
end

function Sync.UnregisterProvider(sourceID)
    sourceID = tostring(sourceID or "")
    if sourceID == "" or not Sync.Providers[sourceID] then return false end
    Sync.Providers[sourceID] = nil
    return true
end

function Sync.BuildSnapshot(sourceID, player, increment)
    sourceID = tostring(sourceID or "")
    local provider = Sync.Providers[sourceID]
    if not provider then return nil, "projection_provider_not_found" end

    local ok, entries = pcall(provider.BuildEntries, player)
    if not ok then return nil, "projection_provider_failed:" .. tostring(entries) end
    entries = type(entries) == "table" and entries or {}
    if #entries > Projection.MAX_ENTRIES then
        return nil, "projection_capacity_exceeded"
    end

    if increment ~= false then
        Sync.Revisions[sourceID] =
            (tonumber(Sync.Revisions[sourceID]) or 0) + 1
    end

    local payload = {
        schema = Projection.SCHEMA,
        schemaVersion = Projection.SCHEMA_VERSION,
        sourceID = sourceID,
        snapshotRevision = tonumber(Sync.Revisions[sourceID]) or 0,
        entries = entries,
    }
    payload.payloadBytes = 0
    local bytes, byteReason = Projection.MeasureSnapshotBytes(payload)
    if not bytes then return nil, byteReason end
    payload.payloadBytes = bytes
    local finalBytes
    finalBytes, byteReason = Projection.MeasureSnapshotBytes(payload)
    if not finalBytes then return nil, byteReason end
    if finalBytes > Projection.MAX_SNAPSHOT_BYTES then
        return nil, "projection_payload_too_large"
    end
    payload.payloadBytes = finalBytes
    return payload
end

function Sync.Send(player, sourceID, increment)
    local payload, reason = Sync.BuildSnapshot(sourceID, player, increment)
    if not payload then return false, reason end
    return send(player, payload), payload
end

function Sync.Broadcast(sourceID)
    local sent = 0
    eachPlayer(function(player)
        local ok = Sync.Send(player, sourceID, true)
        if ok then sent = sent + 1 end
    end)
    return sent
end

function Sync.BroadcastAll()
    local total = 0
    for sourceID in pairs(Sync.Providers) do
        total = total + Sync.Broadcast(sourceID)
    end
    return total
end

local function onClientCommand(module, command, player, args)
    if module ~= commandModule() or command ~= Sync.COMMAND_REQUEST then
        return
    end
    args = type(args) == "table" and args or {}
    local sourceID = tostring(args.sourceID or "")
    if sourceID ~= "" then
        Sync.Send(player, sourceID, false)
        return
    end
    for id in pairs(Sync.Providers) do
        Sync.Send(player, id, false)
    end
end

if Events and Events.OnClientCommand and Events.OnClientCommand.Add
    and not Sync._serverRequestHook
then
    Sync._serverRequestHook = true
    Events.OnClientCommand.Add(onClientCommand)
end

return Sync
