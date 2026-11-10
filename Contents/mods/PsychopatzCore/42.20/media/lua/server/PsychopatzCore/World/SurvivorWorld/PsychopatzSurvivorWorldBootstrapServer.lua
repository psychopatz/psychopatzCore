require "PsychopatzCore/00_PsychopatzCore_Init"

local SurvivorWorld = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Bootstrap = SurvivorWorld.Bootstrap

PsychopatzCore.SurvivorWorldBootstrapServer =
    PsychopatzCore.SurvivorWorldBootstrapServer or {}

local Server = PsychopatzCore.SurvivorWorldBootstrapServer

local function pointFromPlayer(player)
    if not player then return nil end
    if type(player.getX) ~= "function"
        or type(player.getY) ~= "function"
    then
        return nil
    end
    return {
        x = tonumber(player:getX()),
        y = tonumber(player:getY()),
        z = type(player.getZ) == "function"
            and tonumber(player:getZ()) or 0,
    }
end

local function firstPlayer()
    if isServer and isServer() and getOnlinePlayers then
        local players = getOnlinePlayers()
        if players and type(players.size) == "function"
            and type(players.get) == "function"
        then
            for index = 0, players:size() - 1 do
                local player = players:get(index)
                local point = pointFromPlayer(player)
                if point then return player, point end
            end
        elseif type(players) == "table" then
            for _, player in ipairs(players) do
                local point = pointFromPlayer(player)
                if point then return player, point end
            end
        end
    end
    if getSpecificPlayer then
        local player = getSpecificPlayer(0)
        local point = pointFromPlayer(player)
        if point then return player, point end
    end
    return nil, nil
end

local function worldAge()
    local time = getGameTime and getGameTime() or nil
    if time and type(time.getWorldAgeHours) == "function" then
        return math.max(0, tonumber(time:getWorldAgeHours()) or 0)
    end
    return 0
end

function Server.EnsureRuntime(spec)
    if Server.Completed == true then
        return SurvivorWorld.GetRuntimeRegistry(),
            Server.LastStatus and Server.LastStatus.reason or "existing"
    end

    spec = type(spec) == "table" and spec or {}
    local anchor = type(spec.anchor) == "table" and spec.anchor or nil
    if not anchor and spec.player then
        anchor = pointFromPlayer(spec.player)
    end
    if not anchor then
        local _, playerPoint = firstPlayer()
        anchor = playerPoint
    end
    if not anchor then
        Server.LastStatus = {
            active = false,
            reason = "survivor_world_bootstrap_anchor_unavailable",
        }
        return nil, Server.LastStatus.reason
    end

    local request = {}
    for key, value in pairs(spec) do request[key] = value end
    request.anchor = anchor
    request.createdAt = tonumber(request.createdAt) or worldAge()

    local registry, reason, result = Bootstrap.EnsureRuntime(request)
    if not registry then
        Server.LastStatus = {
            active = false,
            reason = reason,
        }
        return nil, reason
    end

    Server.Completed = true
    Server.LastStatus = {
        active = true,
        reason = reason,
        result = result,
        counts = registry:Counts(),
    }
    if PsychopatzCore.LogInfo then
        PsychopatzCore.LogInfo(
            "SurvivorWorld bootstrap status=" .. tostring(reason)
                .. " communities=" .. tostring(Server.LastStatus.counts.communities)
                .. " groups=" .. tostring(Server.LastStatus.counts.groups)
        )
    end
    return registry, reason, result
end

function Server.OnServerStarted()
    Server.EnsureRuntime()
end

function Server.OnCreatePlayer(player)
    if Server.Completed ~= true then
        Server.EnsureRuntime({ player = player })
    end
end

if Events and Events.OnServerStarted
    and type(Events.OnServerStarted.Add) == "function"
    and not Server.ServerStartedHookRegistered
then
    Events.OnServerStarted.Add(Server.OnServerStarted)
    Server.ServerStartedHookRegistered = true
end

if Events and Events.OnCreatePlayer
    and type(Events.OnCreatePlayer.Add) == "function"
    and not Server.CreatePlayerHookRegistered
then
    Events.OnCreatePlayer.Add(Server.OnCreatePlayer)
    Server.CreatePlayerHookRegistered = true
end

return Server
