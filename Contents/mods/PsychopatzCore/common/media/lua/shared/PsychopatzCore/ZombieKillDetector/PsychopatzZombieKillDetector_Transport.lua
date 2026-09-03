PsychopatzCore = PsychopatzCore or {}
local Detector = PsychopatzCore.ZombieKillDetector
local Internal = Detector.Internal

local function reject(reason, player, args)
    Internal.Audit({
        "event=ZombieKillReport",
        "phase=validation",
        "result=false",
        "reason=" .. tostring(reason),
        "killerOnlineID="
            .. tostring(Internal.Call(player, "getOnlineID") or "nil"),
        "zombieOnlineID="
            .. tostring(args and args.zombieOnlineID or "nil"),
    })
    return false, reason
end

function Internal.ReportClientKill(killer, zombie, context)
    local onlineID
    local killerOnlineID
    local playerKey
    local reportKey
    local now
    local previous
    local payload
    local ok
    if not Internal.IsPureClient() then
        return false, "authority_runtime"
    end
    if not Internal.IsLocalPlayer(killer) then
        return false, "not_local_killer"
    end
    if not sendClientCommand then
        return false, "send_unavailable"
    end
    onlineID = Internal.GetZombieOnlineID(zombie)
    if onlineID == nil then
        return false, "missing_zombie_online_id"
    end
    now = Internal.Now()
    playerKey = Internal.PlayerKey(killer)
    reportKey = tostring(playerKey or killer) .. ":" .. tostring(onlineID)
    previous = Detector.ClientKillReports[reportKey]
    if previous and now - (tonumber(previous) or 0)
        < Internal.REPORT_TTL_MS
    then
        return false, "duplicate_client_report"
    end
    killerOnlineID = Internal.Call(killer, "getOnlineID")
    payload = {
        zombieOnlineID = onlineID,
        bodyInstanceID = Internal.Call(zombie, "getPersistentOutfitID"),
        killerOnlineID = killerOnlineID,
        nativeZombieKills = Internal.Call(killer, "getZombieKills"),
        zombieX = Internal.Call(zombie, "getX"),
        zombieY = Internal.Call(zombie, "getY"),
        zombieZ = Internal.Call(zombie, "getZ"),
        killerSource = context and context.killerSource or nil,
    }
    ok = pcall(
        sendClientCommand,
        killer,
        Detector.COMMAND_MODULE,
        Detector.COMMAND,
        payload
    )
    if not ok then
        return false, "send_failed"
    end
    Detector.ClientKillReports[reportKey] = now
    return true, "sent"
end

function Internal.HandleClientCommand(module, command, player, args)
    local onlineID
    local zombie
    local currentOnlineID
    local currentInstanceID
    local dead
    local health
    local engineKiller
    local threatID
    local playerKey
    local reportKey
    local now
    local previous
    local context
    local accepted
    local result
    local reason
    if module ~= Detector.COMMAND_MODULE
        or command ~= Detector.COMMAND
    then
        return false
    end
    if not player or type(args) ~= "table" then
        return reject("invalid_report", player, args)
    end
    if not Internal.IsPlayer(player) then
        return reject("sender_not_player", player, args)
    end
    if args.killerOnlineID ~= nil
        and Internal.Call(player, "getOnlineID") ~= nil
        and tonumber(Internal.Call(player, "getOnlineID"))
            ~= tonumber(args.killerOnlineID)
    then
        return reject("killer_mismatch", player, args)
    end
    onlineID = tonumber(args.zombieOnlineID)
    if not onlineID or onlineID < 0 then
        return reject("missing_zombie_online_id", player, args)
    end
    zombie = Internal.FindZombieByOnlineID(onlineID)
    if not Internal.IsZombie(zombie) then
        return reject("zombie_unavailable", player, args)
    end
    currentOnlineID = Internal.GetZombieOnlineID(zombie)
    if currentOnlineID == nil or currentOnlineID ~= onlineID then
        return reject("online_id_mismatch", player, args)
    end
    currentInstanceID = Internal.Call(zombie, "getPersistentOutfitID")
    if args.bodyInstanceID ~= nil and currentInstanceID ~= nil
        and tostring(args.bodyInstanceID) ~= tostring(currentInstanceID)
    then
        return reject("instance_id_mismatch", player, args)
    end
    dead = Internal.Call(zombie, "isDead")
    health = tonumber(Internal.Call(zombie, "getHealth"))
    if dead ~= true and (health == nil or health > 0) then
        return reject("target_not_dead", player, args)
    end
    engineKiller = Internal.Call(zombie, "getAttackedBy")
    if Internal.IsPlayer(engineKiller) and engineKiller ~= player then
        return reject("engine_killer_mismatch", player, args)
    end
    threatID = Internal.ThreatIDFor(zombie)
    playerKey = Internal.PlayerKey(player)
    if not threatID or not playerKey then
        return reject("identity_unavailable", player, args)
    end
    threatID = tostring(threatID)
    now = Internal.Now()
    Internal.Prune(now)
    previous = Detector.ProcessedThreatDeaths[threatID]
    if previous and now - (tonumber(previous) or 0)
        < Internal.DEATH_DEDUPE_TTL_MS
    then
        return reject("duplicate_server_death", player, args)
    end
    reportKey = tostring(playerKey) .. ":" .. threatID
    previous = Detector.ClientKillReports[reportKey]
    if previous and now - (tonumber(previous) or 0)
        < Internal.REPORT_TTL_MS
    then
        return reject("duplicate_report", player, args)
    end
    context = {
        source = "client_report",
        runtime = Internal.RuntimeRole(),
        killerOnlineID = Internal.Call(player, "getOnlineID"),
        killerUsername = Internal.Call(player, "getUsername"),
        zombieOnlineID = currentOnlineID,
        bodyInstanceID = currentInstanceID,
        nativeZombieKills = args.nativeZombieKills,
        serverNativeZombieKills = Internal.Call(player, "getZombieKills"),
        clientReport = true,
        clientReportReason = "accepted",
        zombieX = Internal.Call(zombie, "getX"),
        zombieY = Internal.Call(zombie, "getY"),
        zombieZ = Internal.Call(zombie, "getZ"),
    }
    accepted, result, reason = Internal.DispatchServerKill(
        player,
        zombie,
        context
    )
    if accepted then
        Detector.ClientKillReports[reportKey] = now
    end
    Internal.Audit({
        "event=ZombieKillReport",
        "phase=relationship_dispatch",
        "result=" .. tostring(accepted),
        "reason=" .. tostring(reason or result or "nil"),
        "playerKey=" .. tostring(playerKey),
        "threatID=" .. threatID,
        "killerOnlineID="
            .. tostring(Internal.Call(player, "getOnlineID") or "nil"),
        "serverNativeZombieKills="
            .. tostring(Internal.Call(player, "getZombieKills") or "nil"),
        "clientNativeZombieKills="
            .. tostring(args.nativeZombieKills or "nil"),
    })
    return accepted, reason or result
end

return Detector
