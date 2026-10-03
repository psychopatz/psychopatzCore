PsychopatzCore = PsychopatzCore or {}
local Detector = PsychopatzCore.ZombieKillDetector
local Internal = Detector.Internal
local Validation = {}

function Validation.Reject(reason, player, args)
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

function Validation.ValidateTarget(player, args)
    if not player or type(args) ~= "table" then
        return Validation.Reject("invalid_report", player, args)
    end
    if not Internal.IsPlayer(player) then
        return Validation.Reject("sender_not_player", player, args)
    end
    if args.killerOnlineID ~= nil
        and Internal.Call(player, "getOnlineID") ~= nil
        and tonumber(Internal.Call(player, "getOnlineID"))
            ~= tonumber(args.killerOnlineID)
    then
        return Validation.Reject("killer_mismatch", player, args)
    end

    local onlineID = tonumber(args.zombieOnlineID)
    if not onlineID or onlineID < 0 then
        return Validation.Reject("missing_zombie_online_id", player, args)
    end
    local zombie = Internal.FindZombieByOnlineID(onlineID)
    if not Internal.IsZombie(zombie) then
        return Validation.Reject("zombie_unavailable", player, args)
    end
    local currentOnlineID = Internal.GetZombieOnlineID(zombie)
    if currentOnlineID == nil or currentOnlineID ~= onlineID then
        return Validation.Reject("online_id_mismatch", player, args)
    end

    local currentInstanceID = Internal.Call(zombie, "getPersistentOutfitID")
    if args.bodyInstanceID ~= nil and currentInstanceID ~= nil
        and tostring(args.bodyInstanceID) ~= tostring(currentInstanceID)
    then
        return Validation.Reject("instance_id_mismatch", player, args)
    end

    local dead = Internal.Call(zombie, "isDead")
    local health = tonumber(Internal.Call(zombie, "getHealth"))
    if dead ~= true and (health == nil or health > 0) then
        return Validation.Reject("target_not_dead", player, args)
    end

    local engineKiller = Internal.Call(zombie, "getAttackedBy")
    if Internal.IsPlayer(engineKiller) and engineKiller ~= player then
        return Validation.Reject("engine_killer_mismatch", player, args)
    end
    return true, {
        onlineID = onlineID,
        zombie = zombie,
        currentOnlineID = currentOnlineID,
        currentInstanceID = currentInstanceID,
    }
end

function Validation.PrepareDedupe(player, target, args)
    local threatID = Internal.ThreatIDFor(target.zombie)
    local playerKey = Internal.PlayerKey(player)
    if not threatID or not playerKey then
        return Validation.Reject("identity_unavailable", player, args)
    end

    threatID = tostring(threatID)
    local now = Internal.Now()
    Internal.Prune(now)
    local previous = Detector.ProcessedThreatDeaths[threatID]
    if previous and now - (tonumber(previous) or 0)
        < Internal.DEATH_DEDUPE_TTL_MS
    then
        return Validation.Reject("duplicate_server_death", player, args)
    end

    local reportKey = tostring(playerKey) .. ":" .. threatID
    previous = Detector.ClientKillReports[reportKey]
    if previous and now - (tonumber(previous) or 0)
        < Internal.REPORT_TTL_MS
    then
        return Validation.Reject("duplicate_report", player, args)
    end
    return true, {
        threatID = threatID,
        playerKey = playerKey,
        now = now,
        reportKey = reportKey,
    }
end

return Validation
