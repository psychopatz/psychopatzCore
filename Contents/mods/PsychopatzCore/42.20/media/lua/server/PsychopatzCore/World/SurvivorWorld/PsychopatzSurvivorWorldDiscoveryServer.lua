require "PsychopatzCore/00_PsychopatzCore_Init"

local SurvivorWorld = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"

PsychopatzCore.SurvivorWorldDiscoveryServer =
    PsychopatzCore.SurvivorWorldDiscoveryServer or {}

local Server = PsychopatzCore.SurvivorWorldDiscoveryServer
local Discovery = SurvivorWorld.Discovery

Server.COMMAND_SNAPSHOT = "SurvivorWorldDiscoverySnapshot"
Server.COMMAND_REQUEST = "SurvivorWorldDiscoveryRequest"
Server.COMMAND_ACTION = "SurvivorWorldDiscoveryAction"
Server.Resolvers = Server.Resolvers or {}

local function commandModule()
    return PsychopatzCore.COMMAND_MODULE or "PsychopatzCore"
end

local function worldHour()
    local time = getGameTime and getGameTime() or nil
    return time and type(time.getWorldAgeHours) == "function"
        and math.max(
            0,
            tonumber(time:getWorldAgeHours()) or 0
        )
        or 0
end

function Server.RegisterPlayerKeyResolver(id, definition)
    id = tostring(id or "")
    if id == ""
        or type(definition) ~= "table"
        or type(definition.resolve) ~= "function"
    then
        return false, "invalid_player_key_resolver"
    end
    Server.Resolvers[id] = {
        priority = tonumber(definition.priority) or 100,
        resolve = definition.resolve,
    }
    return true
end

function Server.UnregisterPlayerKeyResolver(id)
    id = tostring(id or "")
    if id == "" or not Server.Resolvers[id] then
        return false
    end
    Server.Resolvers[id] = nil
    return true
end

local function resolverList()
    local output = {}
    for id, definition in pairs(Server.Resolvers) do
        output[#output + 1] = {
            id = id,
            priority = tonumber(definition.priority) or 100,
            resolve = definition.resolve,
        }
    end
    table.sort(output, function(left, right)
        if left.priority == right.priority then
            return left.id < right.id
        end
        return left.priority > right.priority
    end)
    return output
end

local function fallbackPlayerKey(player)
    if not player then return nil end
    local username = type(player.getUsername) == "function"
        and player:getUsername() or nil
    if username and tostring(username) ~= "" then
        return "player:" .. tostring(username)
    end
    local onlineID = type(player.getOnlineID) == "function"
        and player:getOnlineID() or nil
    if onlineID ~= nil then
        return "player:online:" .. tostring(onlineID)
    end
    return nil
end

function Server.ResolvePlayerKey(player)
    for _, definition in ipairs(resolverList()) do
        local ok, value = pcall(
            definition.resolve,
            player
        )
        if ok and value ~= nil and tostring(value) ~= "" then
            return tostring(value), definition.id
        end
    end
    local fallback = fallbackPlayerKey(player)
    return fallback, fallback and "core_fallback"
        or "player_identity_unavailable"
end

local function send(player, snapshot)
    if not player or type(snapshot) ~= "table" then
        return false
    end
    if getSpecificPlayer
        and getSpecificPlayer(0) == player
        and type(triggerEvent) == "function"
    then
        triggerEvent(
            "OnServerCommand",
            commandModule(),
            Server.COMMAND_SNAPSHOT,
            snapshot
        )
        return true
    end
    if type(sendServerCommand) == "function" then
        sendServerCommand(
            player,
            commandModule(),
            Server.COMMAND_SNAPSHOT,
            snapshot
        )
        return true
    end
    return false
end

function Server.BuildSnapshot(player)
    local registry =
        SurvivorWorld.GetRuntimeRegistry()
    if not registry then
        return nil, "survivor_world_inactive"
    end
    local key, reason =
        Server.ResolvePlayerKey(player)
    if not key then return nil, reason end
    return Discovery.BuildSnapshot(
        registry,
        key,
        worldHour()
    )
end

function Server.Send(player)
    local snapshot, reason =
        Server.BuildSnapshot(player)
    if not snapshot then return false, reason end
    return send(player, snapshot), snapshot
end

local function canDebug(player)
    return PsychopatzCore
        and PsychopatzCore.Debug
        and type(PsychopatzCore.Debug.CanUse) == "function"
        and PsychopatzCore.Debug.CanUse(player) == true
end

local function markDirty(reason)
    local ok, failure =
        SurvivorWorld.RuntimeStore.MarkDirty(reason)
    if ok == false then return false, failure end
    return true
end

function Server.ApplyAction(player, action, args)
    local registry =
        SurvivorWorld.GetRuntimeRegistry()
    if not registry then
        return false, "survivor_world_inactive"
    end
    local key, keyReason =
        Server.ResolvePlayerKey(player)
    if not key then return false, keyReason end

    action = tostring(action or "")
    args = type(args) == "table" and args or {}
    local now = worldHour()
    local result
    local reason
    local changed

    if action == "debug_reset" then
        if not canDebug(player) then
            return false, "not_authorized"
        end
        result, reason, changed =
            Discovery.ResetPlayer(registry, key)
    elseif action == "debug_reset_entity" then
        if not canDebug(player) then
            return false, "not_authorized"
        end
        result, reason, changed =
            Discovery.ResetEntity(
                registry,
                key,
                args.kind,
                args.entityID
            )
    elseif action == "debug_discover_all" then
        if not canDebug(player) then
            return false, "not_authorized"
        end
        result, reason = Discovery.DiscoverAll(
            registry,
            key,
            args.scope or "all",
            args.phase or Discovery.PHASE_LOCATED,
            "debug",
            now
        )
        changed = tonumber(result) and result > 0
    elseif action == "set_phase" then
        result, reason, changed =
            Discovery.SetPhase(
                registry,
                key,
                args.kind,
                args.entityID,
                args.phase,
                args.source or "adopter",
                now
            )
    elseif action == "mark_contacted" then
        result, reason, changed =
            Discovery.MarkContacted(
                registry,
                key,
                args.kind,
                args.entityID,
                args.source or "contact",
                now
            )
    elseif action == "mark_arrived" then
        result, reason, changed =
            Discovery.MarkArrived(
                registry,
                key,
                args.kind,
                args.entityID,
                args.presenceStatus,
                args.source or "traversal",
                now
            )
    else
        return false, "unsupported_discovery_action"
    end

    if changed then
        local dirty, dirtyReason =
            markDirty("survivor_world_discovery_" .. action)
        if dirty == false then return false, dirtyReason end
    end

    Server.Send(player)
    return true, reason, result
end

local function onClientCommand(module, command, player, args)
    if module ~= commandModule() then return end
    if command == Server.COMMAND_REQUEST then
        Server.Send(player)
        return
    end
    if command == Server.COMMAND_ACTION then
        args = type(args) == "table" and args or {}
        Server.ApplyAction(
            player,
            args.action,
            args.args
        )
    end
end

if Events and Events.OnClientCommand
    and type(Events.OnClientCommand.Add) == "function"
    and not Server._clientCommandHook
then
    Server._clientCommandHook = true
    Events.OnClientCommand.Add(onClientCommand)
end

return Server
