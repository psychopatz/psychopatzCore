PsychopatzCore = PsychopatzCore or {}
local Detector = PsychopatzCore.ZombieKillDetector
local Internal = Detector.Internal
local Context = {}

function Context.Build(player, target, args)
    return {
        source = "client_report",
        runtime = Internal.RuntimeRole(),
        killerOnlineID = Internal.Call(player, "getOnlineID"),
        killerUsername = Internal.Call(player, "getUsername"),
        zombieOnlineID = target.currentOnlineID,
        bodyInstanceID = target.currentInstanceID,
        nativeZombieKills = args.nativeZombieKills,
        serverNativeZombieKills = Internal.Call(player, "getZombieKills"),
        clientReport = true,
        clientReportReason = "accepted",
        zombieX = Internal.Call(target.zombie, "getX"),
        zombieY = Internal.Call(target.zombie, "getY"),
        zombieZ = Internal.Call(target.zombie, "getZ"),
    }
end

function Context.AuditDispatch(player, args, context, dedupe, accepted,
    result, reason)
    Internal.Audit({
        "event=ZombieKillReport",
        "phase=relationship_dispatch",
        "result=" .. tostring(accepted),
        "reason=" .. tostring(reason or result or "nil"),
        "playerKey=" .. tostring(dedupe.playerKey),
        "threatID=" .. dedupe.threatID,
        "killerOnlineID="
            .. tostring(Internal.Call(player, "getOnlineID") or "nil"),
        "serverNativeZombieKills="
            .. tostring(Internal.Call(player, "getZombieKills") or "nil"),
        "clientNativeZombieKills="
            .. tostring(args.nativeZombieKills or "nil"),
    })
end

return Context
