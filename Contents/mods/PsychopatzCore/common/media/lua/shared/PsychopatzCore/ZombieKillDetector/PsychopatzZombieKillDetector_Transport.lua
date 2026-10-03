PsychopatzCore = PsychopatzCore or {}
local Detector = PsychopatzCore.ZombieKillDetector
local Internal = Detector.Internal

local Validation = require
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_TransportValidation"
local Context = require
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_TransportContext"

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
    if module ~= Detector.COMMAND_MODULE
        or command ~= Detector.COMMAND
    then
        return false
    end

    local valid, targetOrReason = Validation.ValidateTarget(player, args)
    if not valid then return false, targetOrReason end

    local ready, dedupeOrReason = Validation.PrepareDedupe(
        player, targetOrReason, args)
    if not ready then return false, dedupeOrReason end

    local context = Context.Build(
        player,
        targetOrReason,
        args
    )
    local accepted, result, reason = Internal.DispatchServerKill(
        player,
        targetOrReason.zombie,
        context
    )
    if accepted then
        Detector.ClientKillReports[dedupeOrReason.reportKey] =
            dedupeOrReason.now
    end
    Context.AuditDispatch(
        player,
        args,
        context,
        dedupeOrReason,
        accepted,
        result,
        reason
    )
    return accepted, reason or result
end

return Detector
