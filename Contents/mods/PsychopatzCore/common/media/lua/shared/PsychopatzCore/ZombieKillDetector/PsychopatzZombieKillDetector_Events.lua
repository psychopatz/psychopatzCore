PsychopatzCore = PsychopatzCore or {}
local Detector = PsychopatzCore.ZombieKillDetector
local Internal = Detector.Internal
local RecentPlayerHits = setmetatable({}, { __mode = "k" })
local HIT_CACHE_TTL_MS = 3000

local function resolveKiller(zombie)
    local killer = Internal.Call(zombie, "getAttackedBy")
    local cached = RecentPlayerHits[zombie]
    local now
    local source = "engine_attacked_by"
    RecentPlayerHits[zombie] = nil
    if not Internal.IsPlayer(killer) and cached then
        now = Internal.Now()
        if now == 0
            or cached.occurredAt == 0
            or now - cached.occurredAt <= HIT_CACHE_TTL_MS
        then
            killer = cached.attacker
            source = "weapon_hit_cache"
        end
    end
    return killer, source
end

local DEATH_PRUNE_INTERVAL_MS = 30000

function Internal.DispatchServerKill(killer, zombie, context)
    local accepted
    local result
    local reason
    local threatID = Internal.ThreatIDFor(zombie)
    local now = Internal.Now()
    if Internal._nextPruneAt == nil or now >= Internal._nextPruneAt then
        Internal._nextPruneAt = now + DEATH_PRUNE_INTERVAL_MS
        Internal.Prune(now)
    end
    accepted, result, reason = Internal.Notify(
        "onServerKill",
        killer,
        zombie,
        context
    )
    if accepted and threatID then
        Detector.ProcessedThreatDeaths[tostring(threatID)] = now
    end
    return accepted, result, reason
end

function Internal.OnWeaponHitCharacter(attacker, target, weapon, damage)
    local context
    local result
    local reason
    if not Internal.IsPlayer(attacker) or not Internal.IsZombie(target) then
        return
    end
    if Internal.IsPureClient() then
        if Internal.IsLocalPlayer(attacker) then
            RecentPlayerHits[target] = {
                attacker = attacker,
                occurredAt = Internal.Now(),
            }
        end
        context = Internal.BuildContext(attacker, target, "weapon_hit")
        context.weapon = weapon
        context.damage = damage
        Internal.Notify("onClientHit", attacker, target, context)
    else
        -- Authority runtimes may receive OnZombieDead after the engine has
        -- cleared getAttackedBy(). Keep the authoritative hit identity as the
        -- short-lived fallback for SP, listen servers, and dedicated servers.
        RecentPlayerHits[target] = {
            attacker = attacker,
            occurredAt = Internal.Now(),
        }
        context = Internal.BuildContext(attacker, target, "weapon_hit")
        context.weapon = weapon
        context.damage = damage
        _, result, reason = Internal.Notify(
            "onServerHit",
            attacker,
            target,
            context
        )
    end
    if Detector.AuditEnabled == true then
        Internal.Audit({
            "event=OnWeaponHitCharacter",
            "runtime=" .. Internal.RuntimeRole(),
            "result=" .. tostring(result or "observed"),
            "reason=" .. tostring(reason or "nil"),
            "attackerOnlineID="
                .. tostring(Internal.Call(attacker, "getOnlineID") or "nil"),
            "zombieOnlineID="
                .. tostring(Internal.Call(target, "getOnlineID") or "nil"),
        })
    end
    return result, reason
end

function Internal.OnZombieDead(zombie)
    local killer
    local killerSource
    local killerIsPlayer
    local context
    local reportResult = false
    local reportReason = "not_player_kill"
    local accepted
    local result
    local reason
    if not Internal.IsZombie(zombie) then
        return
    end
    killer, killerSource = resolveKiller(zombie)
    killerIsPlayer = Internal.IsPlayer(killer)
    if not killerIsPlayer and Detector.AuditEnabled ~= true then
        return false, "not_player_kill"
    end
    context = Internal.BuildContext(killer, zombie, "zombie_death")
    context.killerSource = killerSource
    context.playerKillCandidate = killerIsPlayer
    context.zombieDead = Internal.Call(zombie, "isDead")
    context.zombieOnKillDone = Internal.Call(zombie, "isOnKillDone")
    if killerIsPlayer and Internal.IsPureClient() then
        if Internal.IsLocalPlayer(killer) then
            reportResult, reportReason = Internal.ReportClientKill(
                killer,
                zombie,
                context
            )
            context.clientReport = reportResult
            context.clientReportReason = reportReason
            Internal.Notify("onClientKill", killer, zombie, context)
        else
            reportReason = "not_local_killer"
        end
    elseif killerIsPlayer and Internal.IsAuthority() then
        reportReason = "authority_runtime"
        accepted, result, reason = Internal.DispatchServerKill(
            killer,
            zombie,
            context
        )
        context.relationshipDispatch = accepted
        context.relationshipResult = result
        context.relationshipReason = reason
    end
    if Detector.AuditEnabled == true then
        Internal.Audit({
            "event=OnZombieDead",
            "runtime=" .. Internal.RuntimeRole(),
            "result=observed",
            "playerKillCandidate=" .. tostring(killerIsPlayer),
            "killerSource=" .. tostring(killerSource),
            "nativeZombieKills="
                .. tostring(Internal.Call(killer, "getZombieKills") or "nil"),
            "zombieDead=" .. tostring(context.zombieDead),
            "zombieOnKillDone=" .. tostring(context.zombieOnKillDone),
            "clientReport=" .. tostring(reportResult),
            "clientReportReason=" .. tostring(reportReason),
        })
    end
    return accepted, reason or result
end

function Internal.Install()
    if Detector.HooksInstalled then
        return true
    end
    if not Events then
        return false
    end
    if Events.OnWeaponHitCharacter then
        Events.OnWeaponHitCharacter.Add(Internal.OnWeaponHitCharacter)
        Detector.WeaponHitHookRegistered = true
    end
    if Events.OnZombieDead then
        Events.OnZombieDead.Add(Internal.OnZombieDead)
        Detector.ZombieDeadHookRegistered = true
    end
    if Internal.IsAuthority() and Events.OnClientCommand then
        Events.OnClientCommand.Add(Internal.HandleClientCommand)
        Detector.ClientCommandHookRegistered = true
    end
    Detector.HooksInstalled = true
    Internal.Audit({
        "event=registration",
        "runtime=" .. Internal.RuntimeRole(),
        "weaponHitHook=" .. tostring(Detector.WeaponHitHookRegistered == true),
        "zombieDeadHook=" .. tostring(Detector.ZombieDeadHookRegistered == true),
        "clientCommandHook="
            .. tostring(Detector.ClientCommandHookRegistered == true),
    })
    return true
end

return Detector
