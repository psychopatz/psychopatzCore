-- Project Zomboid engine adapter for PsychopatzCore vanilla world events.
-- Translates authoritative PZ runtime callbacks and coarse state checks into
-- normalized PsychopatzCore.VanillaEventObserver observations.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero OnTick loops.

local Observer = require "PsychopatzCore/WorldEvents/PsychopatzVanillaEventObserver"
local ScopedWorldEvents = require "PsychopatzCore/WorldEvents/PsychopatzScopedWorldEvents"
local Location = require "PsychopatzCore/WorldEvents/PsychopatzWorldEventLocation"
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

function Adapter.ReadHelicopterAuthority(opts)
    opts = type(opts) == "table" and opts or {}
    local heli = objectOrNil(opts.helicopter)
    if not heli then
        local world = currentWorld(opts)
        if world then
            heli = objectOrNil(world.helicopter)
            if not heli and type(world.getHelicopter) == "function" then
                heli = objectOrNil(world:getHelicopter())
            end
        end
    end
    if not heli then
        return { known = false, reason = "helicopter_authority_unavailable" }
    end

    local active = false
    if type(heli.isActive) == "function" then
        active = heli:isActive() == true
    elseif type(heli.active) == "boolean" then
        active = heli.active == true
    else
        return { known = false, reason = "helicopter_active_state_unavailable" }
    end

    local hx = finite(heli.x, nil)
    if hx == nil and type(heli.getX) == "function" then
        hx = finite(heli:getX(), nil)
    end
    local hy = finite(heli.y, nil)
    if hy == nil and type(heli.getY) == "function" then
        hy = finite(heli:getY(), nil)
    end
    return {
        known = true,
        active = active,
        x = hx,
        y = hy,
    }
end

local function appendRouteSample(summary, label, sampleCount)
    local cleanLabel = tostring(label or "")
    if cleanLabel == "" then return summary end
    if sampleCount > Observer.MAX_EPISODE_SAMPLES then
        return summary
    end
    if not summary or summary == "" then
        return string.sub(cleanLabel, 1, 140)
    end
    if #summary >= 140 then
        return summary
    end
    local joined = summary .. " -> " .. cleanLabel
    if #joined > 150 then
        return summary
    end
    return joined
end

function Adapter.ObserveHelicopter(nowHours, opts)
    if not isAuthorityAllowed(opts) then
        return nil, "server_authority_required"
    end
    opts = type(opts) == "table" and opts or {}
    nowHours = finite(nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local auth = Adapter.ReadHelicopterAuthority(opts)
    if not auth.known then
        return nil, auth.reason
    end

    local state = Observer.GetHelicopterState()
    local wasActive = state.active == true
    local nowActive = auth.active == true

    if not wasActive and not nowActive then
        return nil, "helicopter_inactive"
    end

    if wasActive and not nowActive then
        local nextRev = (tonumber(state.revision) or 1) + 1
        local lastLoc = state.lastLocation
        local obsRes, obsErr = Observer.Observe({
            eventID = state.eventID,
            factID = state.factID,
            semanticType = "world.helicopter_overflight",
            factKind = "world.helicopter_overflight",
            sourceKind = "helicopter",
            vanillaSourceID = "IsoWorld.helicopter",
            phase = "end",
            endReason = "helicopter_departed",
            retention = "historical",
            provenance = "environmental",
            preferredScope = (lastLoc and lastLoc.regionID) and "region" or "local_area",
            locationRef = lastLoc,
            occurredAt = tonumber(state.startedAt) or nowHours,
            observedAt = nowHours,
            revision = nextRev,
            severity = 0.50,
            salience = 0.75,
            subject = { id = "world:helicopter", kind = "world_event" },
            payload = {
                semanticType = "world.helicopter_overflight",
                phase = "ended",
                episodeSeq = state.episodeSeq,
                locationLabel = (lastLoc and lastLoc.label) or state.startLabel or "area",
                startAreaID = state.startAreaID,
                latestAreaID = state.lastAreaID,
                sampleCount = state.sampleCount or 1,
                routeSummary = state.routeSummary or state.startLabel or "area",
            },
        }, opts)
        Observer.SetHelicopterState({
            active = false,
            episodeSeq = state.episodeSeq or 0,
            endedAt = nowHours,
        })
        return {
            action = "ended",
            eventID = state.eventID,
            factID = state.factID,
            locationRef = lastLoc,
            result = obsRes,
            err = obsErr,
        }
    end

    -- Helicopter is currently active (either newly started or ongoing)
    if auth.x == nil or auth.y == nil then
        return nil, "helicopter_coordinates_unavailable"
    end
    local bx, by = Location.QuantizeArea(auth.x, auth.y)
    local bucketKey = tostring(bx) .. "_" .. tostring(by)

    if wasActive and state.lastBucketKey == bucketKey then
        return nil, "same_coarse_region"
    end

    local locRef, locErr = Location.Resolve(auth.x, auth.y, 0, opts)
    if not locRef then
        return nil, locErr or "helicopter_location_resolution_failed"
    end

    if wasActive and state.lastAreaID == locRef.localAreaID then
        state.lastBucketKey = bucketKey
        Observer.SetHelicopterState(state)
        return nil, "same_coarse_region"
    end

    if not wasActive then
        local seq = (tonumber(state.episodeSeq) or 0) + 1
        local eventID = "core:helicopter:episode:" .. tostring(seq)
        local factID = "fact:core:world.helicopter_overflight:" .. tostring(seq)
        local obsRes, obsErr = Observer.Observe({
            eventID = eventID,
            factID = factID,
            semanticType = "world.helicopter_overflight",
            factKind = "world.helicopter_overflight",
            sourceKind = "helicopter",
            vanillaSourceID = "IsoWorld.helicopter",
            phase = "start",
            retention = "historical",
            provenance = "environmental",
            preferredScope = locRef.regionID and "region" or "local_area",
            locationRef = locRef,
            occurredAt = nowHours,
            observedAt = nowHours,
            durationHours = 12,
            factTTLHours = 72,
            revision = 1,
            severity = 0.70,
            salience = 0.85,
            subject = { id = "world:helicopter", kind = "world_event" },
            effects = {
                travelRisk = 0.35,
                caravanRisk = 0.40,
                hostileActivityMultiplier = 1.20,
                moralePressure = 0.15,
            },
            metadata = {
                episodeSeq = seq,
                startAreaID = locRef.localAreaID,
                latestAreaID = locRef.localAreaID,
                sampleCount = 1,
            },
            payload = {
                semanticType = "world.helicopter_overflight",
                phase = "active",
                episodeSeq = seq,
                locationLabel = locRef.label,
                startAreaID = locRef.localAreaID,
                latestAreaID = locRef.localAreaID,
                sampleCount = 1,
                routeSummary = locRef.label,
            },
        }, opts)
        Observer.SetHelicopterState({
            active = true,
            episodeSeq = seq,
            eventID = eventID,
            factID = factID,
            startAreaID = locRef.localAreaID,
            startLabel = locRef.label,
            lastAreaID = locRef.localAreaID,
            lastBucketKey = bucketKey,
            lastLocation = locRef,
            sampleCount = 1,
            routeSummary = locRef.label,
            revision = 1,
            startedAt = nowHours,
        })
        return {
            action = "started",
            eventID = eventID,
            factID = factID,
            locationRef = locRef,
            x = auth.x,
            y = auth.y,
            result = obsRes,
            err = obsErr,
        }
    end

    -- Meaningful coarse location transition while active
    local sampleCount = (tonumber(state.sampleCount) or 1) + 1
    local storedSamples = math.min(Observer.MAX_EPISODE_SAMPLES, sampleCount)
    local nextRev = (tonumber(state.revision) or 1) + 1
    local routeSummary = appendRouteSample(state.routeSummary, locRef.label, sampleCount)
    local obsRes, obsErr = Observer.Observe({
        eventID = state.eventID,
        factID = state.factID,
        semanticType = "world.helicopter_overflight",
        factKind = "world.helicopter_overflight",
        sourceKind = "helicopter",
        vanillaSourceID = "IsoWorld.helicopter",
        phase = "update",
        retention = "historical",
        provenance = "environmental",
        preferredScope = locRef.regionID and "region" or "local_area",
        locationRef = locRef,
        occurredAt = tonumber(state.startedAt) or nowHours,
        observedAt = nowHours,
        durationHours = 12,
        factTTLHours = 72,
        revision = nextRev,
        severity = 0.70,
        salience = 0.85,
        subject = { id = "world:helicopter", kind = "world_event" },
        effects = {
            travelRisk = 0.35,
            caravanRisk = 0.40,
            hostileActivityMultiplier = 1.20,
            moralePressure = 0.15,
        },
        metadata = {
            episodeSeq = state.episodeSeq,
            startAreaID = state.startAreaID,
            latestAreaID = locRef.localAreaID,
            sampleCount = storedSamples,
        },
        payload = {
            semanticType = "world.helicopter_overflight",
            phase = "active",
            episodeSeq = state.episodeSeq,
            locationLabel = locRef.label,
            startAreaID = state.startAreaID,
            latestAreaID = locRef.localAreaID,
            sampleCount = storedSamples,
            routeSummary = routeSummary,
        },
    }, opts)
    Observer.SetHelicopterState({
        active = true,
        episodeSeq = state.episodeSeq,
        eventID = state.eventID,
        factID = state.factID,
        startAreaID = state.startAreaID,
        startLabel = state.startLabel,
        lastAreaID = locRef.localAreaID,
        lastBucketKey = bucketKey,
        lastLocation = locRef,
        sampleCount = storedSamples,
        routeSummary = routeSummary,
        revision = nextRev,
        startedAt = state.startedAt,
    })
    return {
        action = "updated",
        eventID = state.eventID,
        factID = state.factID,
        locationRef = locRef,
        x = auth.x,
        y = auth.y,
        sampleCount = storedSamples,
        result = obsRes,
        err = obsErr,
    }
end

Adapter.AMBIENT_SOUND_RULES = {
    MetaAssaultRifle1 = {
        semanticType = "ambient.gunfire",
        weaponClass = "rifle",
        retention = "historical",
        durationHours = 6,
        factTTLHours = 24,
        cooldownHours = 0.25,
        severity = 0.65,
        salience = 0.80,
        effects = { travelRisk = 0.25, caravanRisk = 0.25 },
    },
    MetaPistol1 = {
        semanticType = "ambient.gunfire",
        weaponClass = "pistol",
        retention = "historical",
        durationHours = 6,
        factTTLHours = 24,
        cooldownHours = 0.25,
        severity = 0.55,
        salience = 0.75,
        effects = { travelRisk = 0.20, caravanRisk = 0.20 },
    },
    MetaPistol2 = {
        semanticType = "ambient.gunfire",
        weaponClass = "pistol",
        retention = "historical",
        durationHours = 6,
        factTTLHours = 24,
        cooldownHours = 0.25,
        severity = 0.55,
        salience = 0.75,
        effects = { travelRisk = 0.20, caravanRisk = 0.20 },
    },
    MetaPistol3 = {
        semanticType = "ambient.gunfire",
        weaponClass = "pistol",
        retention = "historical",
        durationHours = 6,
        factTTLHours = 24,
        cooldownHours = 0.25,
        severity = 0.55,
        salience = 0.75,
        effects = { travelRisk = 0.20, caravanRisk = 0.20 },
    },
    MetaShotgun1 = {
        semanticType = "ambient.gunfire",
        weaponClass = "shotgun",
        retention = "historical",
        durationHours = 6,
        factTTLHours = 24,
        cooldownHours = 0.25,
        severity = 0.65,
        salience = 0.80,
        effects = { travelRisk = 0.25, caravanRisk = 0.25 },
    },
    MetaScream = {
        semanticType = "ambient.scream",
        retention = "historical",
        durationHours = 4,
        factTTLHours = 18,
        cooldownHours = 0.25,
        severity = 0.50,
        salience = 0.70,
        effects = { travelRisk = 0.15, moralePressure = 0.10 },
    },
    burglar2 = {
        semanticType = "world.house_alarm",
        retention = "historical",
        durationHours = 3,
        factTTLHours = 18,
        cooldownHours = 0.25,
        severity = 0.55,
        salience = 0.75,
        effects = { travelRisk = 0.20, hostileActivityMultiplier = 1.25 },
    },
    MetaDogBark = {
        semanticType = "ambient.dog_bark",
        subkind = "dog_bark",
        retention = "ephemeral",
        severity = 0.20,
        salience = 0.25,
    },
    MetaOwl = {
        semanticType = "ambient.wildlife",
        subkind = "owl",
        retention = "ephemeral",
        severity = 0.10,
        salience = 0.15,
    },
    MetaWolfHowl = {
        semanticType = "ambient.wildlife",
        subkind = "wolf_howl",
        retention = "ephemeral",
        severity = 0.25,
        salience = 0.30,
    },
}

local function safeString(value, limit)
    if type(value) ~= "string" and type(value) ~= "number" then return nil end
    local text = tostring(value)
    if text == "" then return nil end
    if #text > (limit or 96) then text = string.sub(text, 1, limit or 96) end
    return text
end

local function emitHouseAlarm(x, y, z, vanillaSourceID, nowHours, opts)
    local nx, ny = finite(x, nil), finite(y, nil)
    if nx == nil or ny == nil then return nil, "alarm_coordinates_required" end
    local locRef, locErr = Location.Resolve(nx, ny, finite(z, 0) or 0, opts)
    if not locRef then return nil, locErr end
    local areaID = locRef.localAreaID or locRef.regionID or "area"
    local hourBucket = math.floor(nowHours * 4)
    return Observer.Observe({
        eventID = "core:world:house_alarm:" .. areaID,
        factID = "fact:core:world.house_alarm:" .. areaID .. ":" .. tostring(hourBucket),
        semanticType = "world.house_alarm",
        factKind = "world.house_alarm",
        sourceKind = "world_alarm",
        vanillaSourceID = vanillaSourceID or "Alarm",
        phase = "instant",
        retention = "historical",
        provenance = "environmental",
        preferredScope = "local_area",
        locationRef = locRef,
        occurredAt = nowHours,
        observedAt = nowHours,
        durationHours = 3,
        factTTLHours = 18,
        cooldownHours = 0.25,
        cooldownKey = "world.house_alarm:" .. areaID,
        severity = 0.55,
        salience = 0.75,
        subject = { id = "world:alarm:" .. areaID, kind = "local_area" },
        effects = { travelRisk = 0.20, hostileActivityMultiplier = 1.25 },
        metadata = {
            x = math.floor(nx),
            y = math.floor(ny),
            hearingRadius = 600,
        },
        payload = {
            x = math.floor(nx),
            y = math.floor(ny),
            hearingRadius = 600,
        },
    }, opts)
end

function Adapter.OnAmbientSound(name, x, y, opts)
    if not isAuthorityAllowed(opts) then return nil, "server_authority_required" end
    opts = type(opts) == "table" and opts or {}
    local nx, ny = finite(x, nil), finite(y, nil)
    if nx == nil or ny == nil then return nil, "ambient_coordinates_required" end
    local nowHours = finite(opts.nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local rawName = tostring(name or "")

    if rawName == "" then
        return Observer.Observe({
            semanticType = "weather.thunder",
            sourceKind = "ambient_meta",
            vanillaSourceID = "thunder_ambient",
            phase = "instant",
            retention = "ephemeral",
            provenance = "environmental",
            x = nx,
            y = ny,
            occurredAt = nowHours,
            observedAt = nowHours,
            severity = 0.25,
            salience = 0.25,
        }, opts)
    end

    local rule = Adapter.AMBIENT_SOUND_RULES[rawName]
    if not rule then
        return Observer.Observe({
            semanticType = "ambient.unknown",
            sourceKind = "ambient_meta",
            vanillaSourceID = rawName,
            phase = "instant",
            retention = "ephemeral",
            provenance = "environmental",
            x = nx,
            y = ny,
            occurredAt = nowHours,
            observedAt = nowHours,
            severity = 0.15,
            salience = 0.15,
        }, opts)
    end

    if rule.semanticType == "world.house_alarm" then
        return emitHouseAlarm(nx, ny, 0, rawName, nowHours, opts)
    end

    if rule.retention == "ephemeral" then
        return Observer.Observe({
            semanticType = rule.semanticType,
            sourceKind = "ambient_meta",
            vanillaSourceID = rawName,
            phase = "instant",
            retention = "ephemeral",
            provenance = "environmental",
            x = nx,
            y = ny,
            occurredAt = nowHours,
            observedAt = nowHours,
            severity = rule.severity,
            salience = rule.salience,
            metadata = rule.subkind and { subkind = rule.subkind } or nil,
        }, opts)
    end

    local locRef, locErr = Location.Resolve(nx, ny, 0, opts)
    if not locRef then return nil, locErr end
    local areaID = locRef.localAreaID or locRef.regionID or "area"
    local bucket = math.floor(nowHours * 4)
    return Observer.Observe({
        eventID = "core:" .. rule.semanticType .. ":" .. areaID .. ":" .. tostring(bucket),
        factID = "fact:core:" .. rule.semanticType .. ":" .. areaID .. ":" .. tostring(bucket),
        semanticType = rule.semanticType,
        factKind = rule.semanticType,
        sourceKind = "ambient_meta",
        vanillaSourceID = rawName,
        phase = "instant",
        retention = rule.retention,
        provenance = "environmental",
        preferredScope = "local_area",
        locationRef = locRef,
        occurredAt = nowHours,
        observedAt = nowHours,
        durationHours = rule.durationHours,
        factTTLHours = rule.factTTLHours,
        cooldownHours = rule.cooldownHours,
        cooldownKey = rule.semanticType .. ":" .. areaID,
        severity = rule.severity,
        salience = rule.salience,
        subject = { id = rule.semanticType .. ":" .. areaID, kind = "local_area" },
        effects = rule.effects,
        metadata = {
            weaponClass = rule.weaponClass,
            x = math.floor(nx),
            y = math.floor(ny),
        },
        payload = {
            weaponClass = rule.weaponClass,
            x = math.floor(nx),
            y = math.floor(ny),
            hearingRadius = 700,
        },
    }, opts)
end

function Adapter.OnWorldSound(x, y, z, _radius, _volume, source, opts)
    -- O(1) fast guard: reject non-Alarm world sounds immediately on line 1.
    if source == nil then return nil, "ignored_non_alarm" end
    local isAlarm = false
    if type(instanceof) == "function" and instanceof(source, "Alarm") == true then
        isAlarm = true
    elseif type(typeof) == "function" and typeof(source) == "Alarm" then
        isAlarm = true
    elseif type(getClassSimpleName) == "function" and getClassSimpleName(source) == "Alarm" then
        isAlarm = true
    elseif type(source) == "table" and (source._class == "Alarm" or source.isAlarm == true) then
        isAlarm = true
    end
    if not isAlarm then return nil, "ignored_non_alarm" end
    if not isAuthorityAllowed(opts) then return nil, "server_authority_required" end
    opts = type(opts) == "table" and opts or {}
    local nowHours = finite(opts.nowHours, nil) or Adapter.CurrentWorldHours(opts)
    return emitHouseAlarm(x, y, z, "Alarm", nowHours, opts)
end

local function inspectWeatherPeriod(wp)
    local obj = objectOrNil(wp)
    if not obj then return false, 0, "unknown" end
    local isBliz = (type(obj.isBlizzard) == "function" and obj:isBlizzard() == true)
        or (obj.isBlizzard == true)
    local isTrop = (type(obj.isTropicalStorm) == "function" and obj:isTropicalStorm() == true)
        or (obj.isTropicalStorm == true)
    local isThunder = (type(obj.isThunderStorm) == "function" and obj:isThunderStorm() == true)
        or (obj.isThunderStorm == true)
    local strength = finite(type(obj.getCurrentStrength) == "function" and obj:getCurrentStrength()
        or obj.strength, 0) or 0
    local severe = isBliz or isTrop or (isThunder and strength >= 0.70)
    local stormKind = isBliz and "blizzard" or isTrop and "tropical_storm"
        or isThunder and "thunderstorm" or "rain"
    return severe, strength, stormKind
end

local function resolveWeatherLocation(opts)
    if finite(opts.x, nil) ~= nil and finite(opts.y, nil) ~= nil then
        return Location.Resolve(opts.x, opts.y, 0, opts)
    end
    local px, py = nil, nil
    if type(getPlayer) == "function" then
        local p = objectOrNil(getPlayer())
        if p and type(p.getX) == "function" and type(p.getY) == "function" then
            px, py = finite(p:getX(), nil), finite(p:getY(), nil)
        end
    end
    if px ~= nil and py ~= nil then
        return Location.Resolve(px, py, 0, opts)
    end
    return Location.Resolve(nil, nil, 0, {
        regionID = opts.regionID or "region:knox_county",
        label = opts.regionLabel or "Knox County",
        kind = "region",
    })
end

function Adapter.OnWeatherPeriodEvent(phaseName, weatherPeriod, opts)
    if not isAuthorityAllowed(opts) then return nil, "server_authority_required" end
    opts = type(opts) == "table" and opts or {}
    local nowHours = finite(opts.nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local severe, strength, stormKind = inspectWeatherPeriod(weatherPeriod)
    local locRef = resolveWeatherLocation(opts)

    if not severe and phaseName ~= "end" then
        return Observer.Observe({
            semanticType = "weather.precipitation",
            sourceKind = "weather",
            vanillaSourceID = "WeatherPeriod",
            phase = phaseName == "start" and "start" or "update",
            retention = "ephemeral",
            provenance = "environmental",
            preferredScope = "region",
            locationRef = locRef,
            occurredAt = nowHours,
            observedAt = nowHours,
            severity = math.max(0.1, math.min(1, strength)),
            salience = 0.2,
            metadata = { stormKind = stormKind },
        }, opts)
    end

    if phaseName == "end" and not ScopedWorldEvents.Get("core:weather:severe_storm:" .. tostring(locRef.regionID)) then
        return nil, "no_active_severe_storm"
    end

    local regionID = locRef.regionID or "region:knox_county"
    return Observer.Observe({
        eventID = "core:weather:severe_storm:" .. regionID,
        factID = "fact:core:weather.severe_storm:" .. regionID .. ":" .. tostring(math.floor(nowHours / 24)),
        semanticType = "weather.severe_storm",
        factKind = "weather.severe_storm",
        sourceKind = "weather",
        vanillaSourceID = "WeatherPeriod." .. stormKind,
        phase = phaseName,
        endReason = phaseName == "end" and "weather_period_ended" or nil,
        retention = "historical",
        provenance = "environmental",
        preferredScope = "region",
        locationRef = locRef,
        occurredAt = nowHours,
        observedAt = nowHours,
        durationHours = 24,
        factTTLHours = 36,
        severity = math.max(0.55, math.min(1, strength)),
        salience = 0.75,
        subject = { id = "weather:" .. stormKind, kind = "region" },
        effects = {
            travelRisk = 0.35,
            caravanRisk = 0.30,
            scavengingYieldMultiplier = 0.85,
            moralePressure = 0.20,
        },
        payload = {
            stormKind = stormKind,
            strength = math.floor(strength * 100) / 100,
        },
    }, opts)
end

function Adapter.OnThunderEvent(x, y, _doStrike, _doLightning, _doRumble, opts)
    if not isAuthorityAllowed(opts) then return nil, "server_authority_required" end
    opts = type(opts) == "table" and opts or {}
    local nx, ny = finite(x, nil), finite(y, nil)
    if nx == nil or ny == nil then return nil, "thunder_coordinates_required" end
    local nowHours = finite(opts.nowHours, nil) or Adapter.CurrentWorldHours(opts)
    return Observer.Observe({
        semanticType = "weather.thunder",
        sourceKind = "weather",
        vanillaSourceID = "OnThunderEvent",
        phase = "instant",
        retention = "ephemeral",
        provenance = "environmental",
        x = nx,
        y = ny,
        occurredAt = nowHours,
        observedAt = nowHours,
        severity = 0.25,
        salience = 0.20,
    }, opts)
end

function Adapter.OnDeviceText(guid, codes, x, y, z, _line, _device, opts)
    if not isAuthorityAllowed(opts) then return nil, "server_authority_required" end
    opts = type(opts) == "table" and opts or {}
    local cleanGuid = safeString(guid, 64)
    local cleanCodes = safeString(codes, 96)
    if not cleanGuid and not opts.channelID then
        return nil, "broadcast_metadata_absent"
    end
    local nowHours = finite(opts.nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local channelKey = safeString(opts.channelID or cleanGuid, 64) or "broadcast"
    local locRef = (finite(x, nil) ~= nil and finite(y, nil) ~= nil)
        and Location.Resolve(x, y, finite(z, 0) or 0, opts)
        or Location.Resolve(nil, nil, 0, {
            regionID = opts.regionID or "region:knox_radio",
            label = opts.regionLabel or "Emergency Broadcast",
            kind = "region",
        })
    return Observer.Observe({
        eventID = "core:media:broadcast:" .. channelKey,
        factID = "fact:core:media.broadcast:" .. channelKey .. ":" .. tostring(math.floor(nowHours / 2)),
        semanticType = "media.broadcast",
        factKind = "media.broadcast",
        sourceKind = "radio_broadcast",
        vanillaSourceID = cleanGuid or channelKey,
        phase = "instant",
        retention = "historical",
        provenance = "radio",
        registerScoped = false,
        preferredScope = "region",
        locationRef = locRef,
        occurredAt = nowHours,
        observedAt = nowHours,
        factTTLHours = 24,
        cooldownHours = 2.0,
        cooldownKey = "media.broadcast:" .. channelKey,
        severity = 0.35,
        salience = 0.55,
        subject = { id = "radio:" .. channelKey, kind = "broadcast" },
        payload = {
            channelID = channelKey,
            codes = cleanCodes,
        },
    }, opts)
end

function Adapter.OnNewFire(fire, opts)
    if not isAuthorityAllowed(opts) then return nil, "server_authority_required" end
    opts = type(opts) == "table" and opts or {}
    local obj = objectOrNil(fire)
    local fx, fy, fz = finite(opts.x, nil), finite(opts.y, nil), finite(opts.z, 0) or 0
    if (fx == nil or fy == nil) and obj then
        if type(obj.getSquare) == "function" then
            local sq = objectOrNil(obj:getSquare())
            if sq and type(sq.getX) == "function" and type(sq.getY) == "function" then
                fx, fy = finite(sq:getX(), nil), finite(sq:getY(), nil)
                fz = type(sq.getZ) == "function" and (finite(sq:getZ(), 0) or 0) or 0
            end
        elseif finite(obj.x, nil) ~= nil and finite(obj.y, nil) ~= nil then
            fx, fy = finite(obj.x, nil), finite(obj.y, nil)
        end
    end
    if fx == nil or fy == nil then return nil, "fire_coordinates_required" end
    local nowHours = finite(opts.nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local locRef, locErr = Location.Resolve(fx, fy, fz, opts)
    if not locRef then return nil, locErr end
    local areaID = locRef.localAreaID or locRef.regionID or "area"
    return Observer.Observe({
        eventID = "core:world:fire:" .. areaID,
        factID = "fact:core:world.fire_hazard:" .. areaID .. ":" .. tostring(math.floor(nowHours)),
        semanticType = "world.fire_hazard",
        factKind = "world.fire_hazard",
        sourceKind = "world_hazard",
        vanillaSourceID = "OnNewFire",
        phase = "instant",
        retention = "historical",
        provenance = "environmental",
        preferredScope = "local_area",
        locationRef = locRef,
        occurredAt = nowHours,
        observedAt = nowHours,
        durationHours = 4,
        factTTLHours = 12,
        cooldownHours = 1.0,
        cooldownKey = "world.fire_hazard:" .. areaID,
        severity = 0.55,
        salience = 0.65,
        subject = { id = "fire:" .. areaID, kind = "local_area" },
        effects = { travelRisk = 0.15 },
        payload = { x = math.floor(fx), y = math.floor(fy) },
    }, opts)
end

function Adapter.ObserveSeason(nowHours, opts)
    if not isAuthorityAllowed(opts) then return nil, "server_authority_required" end
    opts = type(opts) == "table" and opts or {}
    nowHours = finite(nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local cm = objectOrNil(opts.climateManager)
    if not cm and type(getClimateManager) == "function" then
        cm = objectOrNil(getClimateManager())
    end
    if not cm or type(cm.getSeasonName) ~= "function" then
        return nil, "season_authority_unavailable"
    end
    local seasonName = safeString(cm:getSeasonName(), 32)
    if not seasonName or seasonName == "unknown" then
        return nil, "season_unknown"
    end
    local prev = Observer.GetUtilityState("season")
    if type(prev) == "table" and prev.name == seasonName then
        return nil, "unchanged"
    end
    local hadPrev = type(prev) == "table" and type(prev.name) == "string"
    Observer.SetUtilityState("season", { name = seasonName, changedAt = nowHours })
    if not hadPrev then
        return nil, "initial_season_recorded"
    end
    local locRef = resolveWeatherLocation(opts)
    local regionID = locRef.regionID or "region:knox_weather"
    return Observer.Observe({
        eventID = "core:weather:season:" .. regionID,
        factID = "fact:core:weather.season_transition:" .. regionID .. ":" .. seasonName,
        semanticType = "weather.season_transition",
        factKind = "weather.season_transition",
        sourceKind = "weather",
        vanillaSourceID = "ClimateManager:getSeasonName",
        phase = "transition",
        retention = "historical",
        provenance = "environmental",
        preferredScope = "region",
        locationRef = locRef,
        occurredAt = nowHours,
        observedAt = nowHours,
        durationHours = 120,
        factTTLHours = 240,
        severity = 0.30,
        salience = 0.50,
        subject = { id = "season:" .. seasonName, kind = "region" },
        payload = {
            season = seasonName,
            previousSeason = prev.name,
        },
    }, opts)
end

function Adapter.PumpCoarse(nowHours, opts)
    if not isAuthorityAllowed(opts) then
        return nil, "server_authority_required"
    end
    nowHours = finite(nowHours, nil) or Adapter.CurrentWorldHours(opts)
    local utilityResults = Adapter.ObserveUtilities(nowHours, opts)
    local heliResult, heliStatus = Adapter.ObserveHelicopter(nowHours, opts)
    local seasonResult, seasonStatus = Adapter.ObserveSeason(nowHours, opts)
    return {
        nowHours = nowHours,
        utilities = utilityResults or {},
        helicopter = heliResult,
        helicopterStatus = heliStatus,
        season = seasonResult,
        seasonStatus = seasonStatus,
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
    if type(Events.EveryTenMinutes) == "table" and type(Events.EveryTenMinutes.Add) == "function" then
        Events.EveryTenMinutes.Add(function()
            Adapter.ObserveHelicopter()
        end)
    end
    if type(Events.OnAmbientSound) == "table" and type(Events.OnAmbientSound.Add) == "function" then
        Events.OnAmbientSound.Add(function(name, x, y)
            Adapter.OnAmbientSound(name, x, y)
        end)
    end
    if type(Events.OnWorldSound) == "table" and type(Events.OnWorldSound.Add) == "function" then
        Events.OnWorldSound.Add(function(x, y, z, radius, volume, source)
            Adapter.OnWorldSound(x, y, z, radius, volume, source)
        end)
    end
    if type(Events.OnWeatherPeriodStart) == "table" and type(Events.OnWeatherPeriodStart.Add) == "function" then
        Events.OnWeatherPeriodStart.Add(function(wp)
            Adapter.OnWeatherPeriodEvent("start", wp)
        end)
    end
    if type(Events.OnWeatherPeriodStage) == "table" and type(Events.OnWeatherPeriodStage.Add) == "function" then
        Events.OnWeatherPeriodStage.Add(function(wp)
            Adapter.OnWeatherPeriodEvent("update", wp)
        end)
    end
    if type(Events.OnWeatherPeriodComplete) == "table" and type(Events.OnWeatherPeriodComplete.Add) == "function" then
        Events.OnWeatherPeriodComplete.Add(function(wp)
            Adapter.OnWeatherPeriodEvent("end", wp)
        end)
    end
    if type(Events.OnWeatherPeriodStop) == "table" and type(Events.OnWeatherPeriodStop.Add) == "function" then
        Events.OnWeatherPeriodStop.Add(function(wp)
            Adapter.OnWeatherPeriodEvent("end", wp)
        end)
    end
    if type(Events.OnThunderEvent) == "table" and type(Events.OnThunderEvent.Add) == "function" then
        Events.OnThunderEvent.Add(function(x, y, doStrike, doLightning, doRumble)
            Adapter.OnThunderEvent(x, y, doStrike, doLightning, doRumble)
        end)
    end
    if type(Events.OnDeviceText) == "table" and type(Events.OnDeviceText.Add) == "function" then
        Events.OnDeviceText.Add(function(guid, codes, x, y, z, line, device)
            Adapter.OnDeviceText(guid, codes, x, y, z, line, device)
        end)
    end
    if type(Events.OnNewFire) == "table" and type(Events.OnNewFire.Add) == "function" then
        Events.OnNewFire.Add(function(fire)
            Adapter.OnNewFire(fire)
        end)
    end
    return true
end

Adapter.InstallHooks()

return Adapter
