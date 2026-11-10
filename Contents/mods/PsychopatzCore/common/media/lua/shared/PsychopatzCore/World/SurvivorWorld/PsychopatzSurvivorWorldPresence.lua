-- Core-owned SurvivorWorld presence and debug handoff coordinator.
--
-- Core owns the debug gate, session override ledger, provider selection, and
-- canonical actor lease commit. Provider adapters only create/remove their
-- physical representation and may add provider-specific rollback work.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Settings = require "PsychopatzCore/Debug/PsychopatzDebugSettings"

PsychopatzCore = PsychopatzCore or {}

local Presence = PsychopatzCore.SurvivorWorldPresence or {}
PsychopatzCore.SurvivorWorldPresence = Presence

Presence.COMMAND = Presence.COMMAND or "SurvivorWorldPresenceDebug"
Presence.SETTING_ID = Presence.SETTING_ID
    or "PsychopatzCore.SurvivorWorldPresenceOverride"
Presence.MAX_DIAGNOSTIC_ROWS = 128
Presence.Providers = Presence.Providers or {}
Presence.Session = Presence.Session or {}

if not Presence._settingRegistered then
    Settings.Register({
        id = Presence.SETTING_ID,
        source = "PsychopatzCore",
        title = "SurvivorWorld presence override",
        description = "Allow the gated map debug action to materialize one selected Core actor.",
        order = 260,
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function()
            return true
        end,
    })
    Presence._settingRegistered = true
end

local function actorService()
    if not PsychopatzCore.Actors then
        require "PsychopatzCore/Actors/PsychopatzActors"
    end
    return PsychopatzCore.Actors
end

local function registry()
    local service = actorService()
    return service and service.DefaultRegistry or nil
end

local function actorID(value)
    if type(value) == "table" then
        value = value.actorID or value.actorId or value.id
    end
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function worldAge()
    local time = getGameTime and getGameTime() or nil
    if time and type(time.getWorldAgeHours) == "function" then
        return math.max(0, tonumber(time:getWorldAgeHours()) or 0)
    end
    return 0
end

local function providerLease(actor)
    return type(actor) == "table"
        and type(actor.providerLease) == "table"
        and actor.providerLease or {}
end

local function activeLease(lease)
    return lease.state == "abstract" or lease.state == "materialized"
end

local function sortedProviders()
    local output = {}
    for id, definition in pairs(Presence.Providers) do
        output[#output + 1] = {
            id = id,
            priority = tonumber(definition.priority) or 100,
            definition = definition,
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

function Presence.RegisterProvider(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.forceLive) ~= "function"
        or type(definition.release) ~= "function"
    then
        return false, "invalid_presence_provider"
    end
    Presence.Providers[id] = {
        id = id,
        priority = tonumber(definition.priority) or 100,
        canForceLive = type(definition.canForceLive) == "function"
            and definition.canForceLive or nil,
        forceLive = definition.forceLive,
        release = definition.release,
        describe = type(definition.describe) == "function"
            and definition.describe or nil,
    }
    return true, id
end

function Presence.UnregisterProvider(id)
    id = tostring(id or "")
    if id == "" or not Presence.Providers[id] then return false end
    Presence.Providers[id] = nil
    return true
end

function Presence.GetProvider(id)
    return Presence.Providers[tostring(id or "")]
end

function Presence.ListProviders()
    local output = {}
    for _, item in ipairs(sortedProviders()) do
        output[#output + 1] = {
            id = item.id,
            priority = item.priority,
        }
    end
    return output
end

-- Provider callbacks are addon-owned failure boundaries. They are the one
-- place this shared coordinator uses a protected call: a missing or broken
-- optional provider must return a bounded diagnostic instead of taking down
-- the server command path.
local function invoke(definition, method, actor, spec)
    local callback = definition and definition[method]
    if type(callback) ~= "function" then
        return nil, "provider_callback_unavailable"
    end
    local ok, result, reason = pcall(callback, actor, PsychopatzCore, spec)
    if not ok then
        return nil, "provider_callback_failed:" .. tostring(result)
    end
    if result == false or result == nil then
        return nil, tostring(reason or "provider_rejected")
    end
    return result, reason
end

function Presence.IsOverrideEnabled()
    return Settings.IsEnabled(Presence.SETTING_ID) == true
end

function Presence.CanUseDebug(player)
    local debugAccess = PsychopatzCore.Debug
    if not debugAccess or type(debugAccess.CanUse) ~= "function" then
        require "PsychopatzCore/Debug/PsychopatzDebug"
        debugAccess = PsychopatzCore.Debug
    end
    return Presence.IsOverrideEnabled()
        and debugAccess and type(debugAccess.CanUse) == "function"
        and debugAccess.CanUse(player) == true
end

local function resolveActor(id)
    local current = registry()
    if not current or type(current.Get) ~= "function" then
        return nil, "core_actor_registry_unavailable"
    end
    id = actorID(id)
    if not id then return nil, "actor_id_required" end
    local actor = current:Get(id)
    return actor, actor and nil or "core_actor_not_found"
end

local function canUseProvider(definition, actor, spec)
    if not definition.canForceLive then return true end
    local ok, accepted, reason = pcall(
        definition.canForceLive,
        actor,
        PsychopatzCore,
        spec
    )
    if not ok then return false, "provider_can_check_failed" end
    return accepted == true, reason
end

local function chooseProvider(actor, requested, spec)
    local lease = providerLease(actor)
    requested = tostring(requested or "")
    if requested ~= "" then
        local definition = Presence.GetProvider(requested)
        if not definition then return nil, "presence_provider_not_registered" end
        local allowed, reason = canUseProvider(definition, actor, spec)
        return allowed and definition or nil, reason or "provider_unavailable"
    end

    if activeLease(lease) then
        local current = Presence.GetProvider(lease.provider)
        if current then
            local allowed = canUseProvider(current, actor, spec)
            if allowed then return current end
        end
    end

    for _, item in ipairs(sortedProviders()) do
        local allowed = canUseProvider(item.definition, actor, spec)
        if allowed then return item.definition end
    end
    return nil, "no_presence_provider_available"
end

-- Adopt an actor into one bodyless provider lease.  This is deliberately
-- provider-neutral: abstract providers do not create bodies and must use the
-- same Core lease handoff regardless of which addon requested the adoption.
-- A materialized lease is never taken over by this helper.
function Presence.EnsureAbstract(id, spec)
    spec = type(spec) == "table" and spec or {}
    local current = spec.actorRegistry or registry()
    if not current or type(current.Get) ~= "function" then
        return nil, "core_actor_registry_unavailable"
    end
    id = actorID(id)
    if not id then return nil, "actor_id_required" end
    local actor = current:Get(id)
    if not actor then return nil, "core_actor_not_found" end
    local reason

    local provider = tostring(spec.provider or "")
    local owner = tostring(spec.owner or "")
    if provider == "" then return nil, "provider_required" end
    if owner == "" then return nil, "provider_owner_required" end

    local lease = providerLease(actor)
    if lease.state == "materialized" then
        return nil, "body_lease_active"
    end
    if lease.state == "abstract"
        and tostring(lease.provider or "") == provider
        and tostring(lease.owner or "") == owner
    then
        return actor, "already_abstract"
    end

    local Provider = actorService().Provider
    local nextActor
    if lease.state == "abstract" then
        nextActor, reason = Provider.Switch(actor, {
            provider = provider,
            owner = owner,
            handoffFrom = lease.owner,
            authority = "server",
            now = tonumber(spec.now) or worldAge(),
            metadata = spec.metadata,
        })
    else
        nextActor, reason = Provider.Acquire(actor, {
            provider = provider,
            owner = owner,
            authority = "server",
            now = tonumber(spec.now) or worldAge(),
            metadata = spec.metadata,
        })
    end
    if not nextActor then return nil, reason end

    local committed
    committed, reason = current:Commit(
        actor.actorId,
        { providerLease = nextActor.providerLease },
        actor.revision
    )
    if not committed then return nil, reason end
    return committed, "abstract"
end

local function sameLease(left, right)
    left = left or {}
    right = right or {}
    return tostring(left.provider or "") == tostring(right.provider or "")
        and tostring(left.state or "") == tostring(right.state or "")
        and tostring(left.owner or "") == tostring(right.owner or "")
        and tostring(left.bodyID or "") == tostring(right.bodyID or "")
end

local function syncResult(actorIDValue, result)
    local current = registry()
    local canonical = current and current:Get(actorIDValue) or nil
    local resultActor = type(result) == "table" and result.actor or nil
    if not current or not canonical or type(resultActor) ~= "table"
        or type(resultActor.providerLease) ~= "table"
    then
        return canonical, canonical and nil or "core_actor_not_found"
    end
    if sameLease(canonical.providerLease, resultActor.providerLease)
        and resultActor.personalInventory == nil
        and resultActor.world == nil
    then
        return canonical
    end

    local patch = { providerLease = resultActor.providerLease }
    if resultActor.personalInventory ~= nil then
        patch.personalInventory = resultActor.personalInventory
    end
    if resultActor.world ~= nil then patch.world = resultActor.world end
    local committed, reason = current:Commit(
        actorIDValue,
        patch,
        canonical.revision
    )
    return committed, reason
end

local function restoreOriginal(actorIDValue, original)
    if type(original) ~= "table" then return registry():Get(actorIDValue) end
    local current = registry()
    local actor = current and current:Get(actorIDValue) or nil
    if not actor then return nil, "core_actor_not_found" end
    local Provider = actorService().Provider
    local lease, reason = Provider.Normalize(original, actorIDValue)
    if not lease then return nil, reason end
    return current:Commit(actorIDValue, { providerLease = lease }, actor.revision)
end

function Presence.DebugForceLive(player, id, options)
    if not Presence.CanUseDebug(player) then
        return nil, "debug_not_authorized"
    end
    options = type(options) == "table" and options or {}
    local actor, reason = resolveActor(id)
    if not actor then return nil, reason end
    local actorIDValue = actorID(actor)
    local lease = providerLease(actor)
    if lease.state == "materialized" then
        return actor, "already_materialized"
    end
    if Presence.Session[actorIDValue] then
        return actor, "already_debug_overridden"
    end

    local definition
    definition, reason = chooseProvider(actor, options.provider, {
        action = "force_live",
        player = player,
    })
    if not definition then return nil, reason end

    local original = Util.clone(lease)
    local result
    result, reason = invoke(definition, "forceLive", actor, {
        action = "force_live",
        actorID = actorIDValue,
        owner = "PsychopatzCore:debug_presence",
        now = worldAge(),
        player = player,
        reason = "core_debug_force_live",
    })
    if not result then return nil, reason end

    local canonical
    canonical, reason = syncResult(actorIDValue, result)
    if not canonical then return nil, reason end
    local finalLease = providerLease(canonical)
    if finalLease.state ~= "materialized" then
        return nil, "provider_materialization_not_committed"
    end
    Presence.Session[actorIDValue] = {
        originalLease = original,
        provider = definition.id,
        bodyID = finalLease.bodyID,
        startedAt = worldAge(),
    }
    return canonical, "materialized"
end

function Presence.DebugRelease(player, id, options)
    if not Presence.CanUseDebug(player) then
        return nil, "debug_not_authorized"
    end
    options = type(options) == "table" and options or {}
    local actor, reason = resolveActor(id)
    if not actor then return nil, reason end
    local actorIDValue = actorID(actor)
    local lease = providerLease(actor)
    if lease.state ~= "materialized" then
        Presence.Session[actorIDValue] = nil
        return actor, "already_abstract"
    end

    local session = Presence.Session[actorIDValue]
    if not session then
        return nil, "not_debug_override"
    end
    local definition = Presence.GetProvider(
        session.provider or lease.provider
    )
    if not definition then return nil, "presence_provider_unavailable" end
    local result
    result, reason = invoke(definition, "release", actor, {
        action = "force_abstract",
        actorID = actorIDValue,
        owner = "PsychopatzCore:debug_presence",
        now = worldAge(),
        player = player,
        reason = "core_debug_force_abstract",
        bodyID = lease.bodyID,
    })
    if not result then return nil, reason end

    local canonical
    canonical, reason = syncResult(actorIDValue, result)
    if not canonical then return nil, reason end
    if providerLease(canonical).state == "materialized" then
        return nil, "provider_dematerialization_not_committed"
    end
    if session and session.originalLease then
        canonical, reason = restoreOriginal(
            actorIDValue,
            session.originalLease
        )
        if not canonical then return nil, reason end
    end
    Presence.Session[actorIDValue] = nil
    return canonical, "abstract"
end

function Presence.HandleDebugCommand(player, args)
    args = type(args) == "table" and args or {}
    if not Presence.CanUseDebug(player) then
        return false, "debug_not_authorized"
    end
    local action = tostring(args.action or "")
    local id = actorID(args.actorID or args.actorId or args.id)
    if not id then return false, "actor_id_required" end
    if action == "force_live" then
        return Presence.DebugForceLive(player, id, args)
    end
    if action == "force_abstract" or action == "release" then
        return Presence.DebugRelease(player, id, args)
    end
    return false, "presence_debug_action_unknown"
end

function Presence.GetDiagnostics(limit)
    limit = math.max(1, math.min(
        Presence.MAX_DIAGNOSTIC_ROWS,
        math.floor(tonumber(limit) or Presence.MAX_DIAGNOSTIC_ROWS)
    ))
    local current = registry()
    local output = {}
    if not current or type(current.List) ~= "function" then
        return output
    end
    for _, actor in ipairs(current:List()) do
        if #output >= limit then break end
        local lease = providerLease(actor)
        local id = actorID(actor)
        local session = Presence.Session[id]
        output[#output + 1] = {
            actorID = id,
            provider = lease.provider,
            providerState = lease.state,
            bodyID = lease.bodyID,
            owner = lease.owner,
            debugOverride = session ~= nil,
            debugProvider = session and session.provider or nil,
            debugStartedAt = session and session.startedAt or nil,
            adapterRegistered = Presence.GetProvider(lease.provider) ~= nil,
        }
    end
    return output
end

return Presence
