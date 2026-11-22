-- Project Zomboid engine adapter for PsychopatzCore vanilla world events.
-- Translates authoritative PZ runtime callbacks and coarse state checks into
-- normalized PsychopatzCore.VanillaEventObserver observations.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero OnTick loops.

local Observer = require "PsychopatzCore/WorldEvents/PsychopatzVanillaEventObserver"
local ScopedWorldEvents = require "PsychopatzCore/WorldEvents/PsychopatzScopedWorldEvents"
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

PsychopatzCore = PsychopatzCore or {}
local Adapter = PsychopatzCore.WorldEventAdapter or {}
PsychopatzCore.WorldEventAdapter = Adapter

Adapter.SCHEMA = "PsychopatzCore.PZWorldEventAdapter"
Adapter.SCHEMA_VERSION = 1

local function finite(value, fallback)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return fallback
    end
    return num
end

local function isAuthorityAllowed(opts)
    if type(opts) == "table" and opts.force == true then return true end
    if RuntimeRole and type(RuntimeRole.AllowsServerCode) == "function" then
        return RuntimeRole.AllowsServerCode()
    end
    return true
end

local function objectOrNil(value)
    local kind = type(value)
    if kind == "table" or kind == "userdata" then return value end
    return nil
end

local function currentGameTime(opts)
    if type(opts) == "table" and opts.gameTime ~= nil then return objectOrNil(opts.gameTime) end
    if type(getGameTime) == "function" then return objectOrNil(getGameTime()) end
    return nil
end

local function currentSandbox(opts)
    if type(opts) == "table" and opts.sandbox ~= nil then return objectOrNil(opts.sandbox) end
    if type(getSandboxOptions) == "function" then return objectOrNil(getSandboxOptions()) end
    if type(SandboxOptions) == "table" and type(SandboxOptions.getInstance) == "function" then
        return objectOrNil(SandboxOptions:getInstance())
    end
    return nil
end

local function currentWorld(opts)
    if type(opts) == "table" and opts.world ~= nil then return objectOrNil(opts.world) end
    if type(getWorld) == "function" then return objectOrNil(getWorld()) end
    if type(IsoWorld) == "table" then return objectOrNil(IsoWorld.instance) end
    return nil
end

function Adapter.CurrentWorldHours(opts)
    if type(opts) == "table" and finite(opts.nowHours or opts.now, nil) ~= nil then
        return math.max(0, finite(opts.nowHours or opts.now, 0))
    end
    local gt = currentGameTime(opts)
    if gt and type(gt.getWorldAgeHours) == "function" then
        return math.max(0, finite(gt:getWorldAgeHours(), 0))
    end
    return 0
end

function Adapter.ReadUtilityAuthority(opts)
    opts = type(opts) == "table" and opts or {}
    local world = currentWorld(opts)
    local sb = currentSandbox(opts)
    local gt = currentGameTime(opts)

    local worldDays = finite(opts.worldDays, nil)
    if worldDays == nil and gt then
        if type(gt.getWorldAgeDaysSinceBegin) == "function" then
            worldDays = finite(gt:getWorldAgeDaysSinceBegin(), nil)
        elseif type(gt.getWorldAgeHours) == "function" then
            local hrs = finite(gt:getWorldAgeHours(), nil)
            if hrs ~= nil then worldDays = hrs / 24 end
        end
    end

    -- 1. Electricity authority (IsoWorld:isHydroPowerOn + SandboxOptions:doesPowerGridExist)
    local powerKnown = false
    local powerOn = nil
    local powerSource = "unavailable"
    if type(opts.powerOn) == "boolean" then
        powerKnown = true
        powerOn = opts.powerOn
        powerSource = "injected_override"
    else
        local hasHydro = world ~= nil and type(world.isHydroPowerOn) == "function"
        local hasGrid = sb ~= nil and type(sb.doesPowerGridExist) == "function"
        if hasHydro or hasGrid then
            powerKnown = true
            local hydroState = true
            if hasHydro then
                hydroState = (world:isHydroPowerOn() == true)
            end
            local gridState = true
            if hasGrid then
                gridState = (sb:doesPowerGridExist() == true)
            end
            powerOn = hydroState and gridState
            powerSource = hasGrid and "SandboxOptions:doesPowerGridExist" or "IsoWorld:isHydroPowerOn"
        end
    end

    -- 2. Water authority (SandboxOptions:getWaterShutModifier vs GameTime worldDays)
    local waterKnown = false
    local waterOn = nil
    local waterShutDay = nil
    local waterSource = "unavailable"
    if type(opts.waterOn) == "boolean" then
        waterKnown = true
        waterOn = opts.waterOn
        waterSource = "injected_override"
    elseif sb ~= nil and type(sb.getWaterShutModifier) == "function" and worldDays ~= nil then
        waterShutDay = finite(sb:getWaterShutModifier(), nil)
        if waterShutDay ~= nil then
            waterKnown = true
            waterOn = (waterShutDay < 0) or (worldDays < waterShutDay)
            waterSource = "SandboxOptions:getWaterShutModifier"
        end
    end

    return {
        power = {
            known = powerKnown,
            on = powerOn,
            source = powerSource,
        },
        water = {
            known = waterKnown,
            on = waterOn,
            shutDay = waterShutDay,
            worldDays = worldDays,
            source = waterSource,
        },
        worldDays = worldDays,
    }
end

local function reconcileUtilityDomain(domainKey, authState, nowHours, cfg, opts)
    if not authState or authState.known ~= true then
        return nil, domainKey .. "_authority_unknown"
    end
    local prev = Observer.GetUtilityState(domainKey)
    local isOn = authState.on == true
    local wasCutoffEmitted = type(prev) == "table" and prev.cutoffEmitted == true

    if not isOn and not wasCutoffEmitted then
        local result, err = Observer.Observe({
            eventID = cfg.eventID,
            factID = cfg.factID,
            semanticType = cfg.cutoffSemanticType,
            factKind = "utility.state",
            sourceKind = "utility",
            vanillaSourceID = cfg.vanillaSourceID,
            phase = "transition",
            retention = "historical",
            provenance = "environmental",
            scope = "global",
            scopeID = "global",
            occurredAt = nowHours,
            observedAt = nowHours,
            severity = cfg.severity,
            salience = 0.9,
            subject = { id = "world:" .. domainKey, kind = "world_state" },
            effects = cfg.effects,
            metadata = {
                utility = domainKey,
                status = "off",
                authoritySource = authState.source,
            },
            payload = {
                utility = domainKey,
                status = "off",
                previousStatus = prev and (prev.on and "on" or "off") or "unknown",
                authoritySource = authState.source,
            },
        }, opts)
        if result then
            Observer.SetUtilityState(domainKey, {
                known = true,
                on = false,
                cutoffEmitted = true,
                changedAt = nowHours,
            })
        end
        return result, err
    elseif isOn and wasCutoffEmitted then
        local result, err = Observer.Observe({
            eventID = cfg.eventID,
            factID = cfg.factID,
            semanticType = cfg.restoreSemanticType,
            factKind = "utility.state",
            sourceKind = "utility",
            vanillaSourceID = cfg.vanillaSourceID,
            phase = "end",
            endReason = "utility_restored",
            retention = "historical",
            provenance = "environmental",
            scope = "global",
            scopeID = "global",
            occurredAt = nowHours,
            observedAt = nowHours,
            severity = 0.2,
            salience = 0.6,
            subject = { id = "world:" .. domainKey, kind = "world_state" },
            payload = {
                utility = domainKey,
                status = "on",
                previousStatus = "off",
                authoritySource = authState.source,
            },
        }, opts)
        if result then
            Observer.SetUtilityState(domainKey, {
                known = true,
                on = true,
                cutoffEmitted = false,
                changedAt = nowHours,
            })
        end
        return result, err
    end

    if type(prev) ~= "table" or prev.on ~= isOn or prev.known ~= true then
        Observer.SetUtilityState(domainKey, {
            known = true,
            on = isOn,
            cutoffEmitted = wasCutoffEmitted,
            changedAt = nowHours,
        })
    end
    return nil, "unchanged"
end

function Adapter.ObserveUtilities(nowHours, opts)
    if not isAuthorityAllowed(opts) then
        return nil, "server_authority_required"
    end
    nowHours = finite(nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local auth = Adapter.ReadUtilityAuthority(opts)
    local results = {}

    local powerRes, powerStatus = reconcileUtilityDomain("electricity", auth.power, nowHours, {
        eventID = "core:utility:electricity_cutoff",
        factID = "fact:core:utility.electricity_cutoff:global",
        cutoffSemanticType = "utility.electricity_cutoff",
        restoreSemanticType = "utility.electricity_restored",
        vanillaSourceID = "OnElectricityChanged",
        severity = 0.80,
        effects = {
            tradeScarcity = 0.25,
            moralePressure = 0.20,
        },
    }, opts)
    if powerRes then results[#results + 1] = powerRes end

    local waterRes, waterStatus = reconcileUtilityDomain("water", auth.water, nowHours, {
        eventID = "core:utility:water_cutoff",
        factID = "fact:core:utility.water_cutoff:global",
        cutoffSemanticType = "utility.water_cutoff",
        restoreSemanticType = "utility.water_restored",
        vanillaSourceID = "WaterShutModifier",
        severity = 0.80,
        effects = {
            foodAvailabilityPressure = 0.20,
            medicalDemand = 0.15,
            tradeScarcity = 0.25,
        },
    }, opts)
    if waterRes then results[#results + 1] = waterRes end

    return results, {
        electricity = powerStatus,
        water = waterStatus,
        authority = auth,
    }
end

function Adapter.OnElectricityChanged()
    return Adapter.ObserveUtilities(Adapter.CurrentWorldHours())
end

function Adapter.PumpCoarse(nowHours, opts)
    if not isAuthorityAllowed(opts) then
        return nil, "server_authority_required"
    end
    nowHours = finite(nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local utilityResults = Adapter.ObserveUtilities(nowHours, opts)
    return {
        nowHours = nowHours,
        utilities = utilityResults or {},
    }
end

function Adapter.InstallHooks()
    if Adapter._hooksInstalled then return true end
    if type(Events) ~= "table" then return false, "events_unavailable" end
    if not isAuthorityAllowed() then return false, "server_authority_required" end
    Adapter._hooksInstalled = true

    if type(Events.OnElectricityChanged) == "table"
        and type(Events.OnElectricityChanged.Add) == "function"
    then
        Events.OnElectricityChanged.Add(function()
            Adapter.OnElectricityChanged()
        end)
    end
    if type(Events.OnGameStart) == "table" and type(Events.OnGameStart.Add) == "function" then
        Events.OnGameStart.Add(function()
            Adapter.PumpCoarse()
        end)
    end
    if type(Events.EveryHours) == "table" and type(Events.EveryHours.Add) == "function" then
        Events.EveryHours.Add(function()
            Adapter.PumpCoarse()
        end)
    end
    return true
end

Adapter.InstallHooks()

return Adapter
