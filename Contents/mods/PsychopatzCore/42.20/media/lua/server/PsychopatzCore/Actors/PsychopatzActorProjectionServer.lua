require "PsychopatzCore/00_PsychopatzCore_Init"

local Projection = require "PsychopatzCore/Actors/PsychopatzActorProjection"

PsychopatzCore.ActorProjectionSync = PsychopatzCore.ActorProjectionSync or {}
local Sync = PsychopatzCore.ActorProjectionSync

Sync.COMMAND_SNAPSHOT = "ActorProjectionSnapshot"
Sync.COMMAND_REQUEST = "ActorProjectionRequest"
Sync.Providers = Sync.Providers or {}
Sync.Revisions = Sync.Revisions or {}
Sync.LastSentByPlayer = Sync.LastSentByPlayer or {}
Sync.POSITION_QUANTUM = tonumber(Sync.POSITION_QUANTUM) or 0.5
Sync.Dirty = Sync.Dirty == true
Sync.LastDirtyReason = Sync.LastDirtyReason or nil

local function playerCacheKey(player)
    if type(player) ~= "table" and type(player) ~= "userdata" then
        return "local"
    end
    if type(player.getOnlineID) == "function" then
        local ok, id = pcall(player.getOnlineID, player)
        if ok and tonumber(id) ~= nil and tonumber(id) >= 0 then
            return "online:" .. tostring(math.floor(tonumber(id)))
        end
    end
    if type(player.getUsername) == "function" then
        local ok, name = pcall(player.getUsername, player)
        if ok and type(name) == "string" and name ~= "" then
            return "user:" .. name
        end
    end
    return tostring(player)
end

local function quantize(value, quantum)
    value = tonumber(value) or 0
    quantum = (tonumber(quantum) or 0.5)
    if quantum <= 0 then return value end
    return math.floor(value / quantum + 0.5)
end

local function entriesDigest(entries)
    local quantum = Sync.POSITION_QUANTUM
    local parts = { tostring(#entries) }
    for index = 1, #entries do
        local e = entries[index]
        local pos = type(e) == "table" and e.position or nil
        local journey = type(e) == "table" and e.journey or nil
        parts[#parts + 1] = tostring(e.actorID or "")
            .. "|" .. tostring(e.revision or 0)
            .. "|" .. tostring(e.providerState or "")
            .. "|" .. tostring(e.factionID or "")
            .. "|" .. tostring(e.label or "")
            .. "|" .. tostring(quantize(pos and pos.x, quantum))
            .. "," .. tostring(quantize(pos and pos.y, quantum))
            .. "," .. tostring(quantize(pos and pos.z, 1))
            .. "|" .. tostring(journey and journey.state or "")
            .. ":" .. tostring(
                journey and quantize(journey.distanceTravelled, quantum) or ""
            )
    end
    return table.concat(parts, ";")
end

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

local function buildSnapshotFromEntries(sourceID, entries, increment)
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
        payloadBytes = 0,
    }
    -- Measure once with payloadBytes=0 ("0" is 1 byte) and adjust for the
    -- final digit width so we avoid double Json.Encode on every send.
    local baseBytes, byteReason = Projection.MeasureSnapshotBytes(payload)
    if not baseBytes then return nil, byteReason end
    local digits = #tostring(baseBytes)
    local finalBytes = baseBytes + (digits - 1)
    if #tostring(finalBytes) > digits then
        finalBytes = finalBytes + 1
    end
    if finalBytes > Projection.MAX_SNAPSHOT_BYTES then
        return nil, "projection_payload_too_large"
    end
    payload.payloadBytes = finalBytes
    return payload
end

function Sync.BuildSnapshot(sourceID, player, increment)
    sourceID = tostring(sourceID or "")
    local provider = Sync.Providers[sourceID]
    if not provider then return nil, "projection_provider_not_found" end

    local ok, entries = pcall(provider.BuildEntries, player)
    if not ok then
        return nil, "projection_provider_failed:" .. tostring(entries)
    end
    entries = type(entries) == "table" and entries or {}
    return buildSnapshotFromEntries(sourceID, entries, increment)
end

function Sync.Send(player, sourceID, increment, options)
    sourceID = tostring(sourceID or "")
    local provider = Sync.Providers[sourceID]
    if not provider then return false, "projection_provider_not_found" end

    local ok, entries = pcall(provider.BuildEntries, player)
    if not ok then
        return false, "projection_provider_failed:" .. tostring(entries)
    end
    entries = type(entries) == "table" and entries or {}

    options = type(options) == "table" and options or {}
    local pKey = playerCacheKey(player)
    local sourceCache = Sync.LastSentByPlayer[sourceID]
    local previous = sourceCache and sourceCache[pKey] or nil
    local digest = entriesDigest(entries)
    local knownRevision = tonumber(options.knownRevision)
    local unchanged = previous ~= nil and previous.digest == digest
    if unchanged and options.force ~= true then
        if options.skipUnchanged == true
            or (knownRevision ~= nil and knownRevision == previous.revision)
        then
            return false, "unchanged"
        end
    end

    local payload, reason = buildSnapshotFromEntries(
        sourceID,
        entries,
        increment
    )
    if not payload then return false, reason end

    local sent = send(player, payload)
    if sent then
        Sync.LastSentByPlayer[sourceID] = sourceCache or {}
        Sync.LastSentByPlayer[sourceID][pKey] = {
            digest = digest,
            revision = payload.snapshotRevision,
            count = #entries,
        }
    end
    return sent, payload
end

function Sync.Broadcast(sourceID, options)
    options = type(options) == "table" and options or {}
    local sendOptions = {
        skipUnchanged = options.force ~= true,
        force = options.force == true,
    }
    local sent = 0
    eachPlayer(function(player)
        local ok = Sync.Send(player, sourceID, true, sendOptions)
        if ok then sent = sent + 1 end
    end)
    return sent
end

function Sync.BroadcastAll(options)
    local total = 0
    for sourceID in pairs(Sync.Providers) do
        total = total + Sync.Broadcast(sourceID, options)
    end
    return total
end

function Sync.ResetForTests()
    Sync.LastSentByPlayer = {}
    Sync.Dirty = false
    Sync.LastDirtyReason = nil
    return true
end

local function onClientCommand(module, command, player, args)
    if module ~= commandModule() or command ~= Sync.COMMAND_REQUEST then
        return
    end
    args = type(args) == "table" and args or {}
    local sourceID = tostring(args.sourceID or "")
    local sendOptions = {
        knownRevision = tonumber(args.knownRevision),
    }
    if sourceID ~= "" then
        Sync.Send(player, sourceID, false, sendOptions)
        return
    end
    for id in pairs(Sync.Providers) do
        Sync.Send(player, id, false, sendOptions)
    end
end

if Events and Events.OnClientCommand and Events.OnClientCommand.Add
    and not Sync._serverRequestHook
then
    Sync._serverRequestHook = true
    Events.OnClientCommand.Add(onClientCommand)
end

return Sync
