-- Provider-neutral weather & time-of-day travel speed and shelter evaluator
-- for PsychopatzCore SurvivorWorld. Shared by DynamicTrading (DTAbstract),
-- ProjectHoomans, and any future World Events / Weather mods.

local Conditions = {}

Conditions.NIGHT_START_HOUR = 21.0
Conditions.NIGHT_END_HOUR = 5.5
Conditions.NIGHT_SPEED_MULT = 0.78
Conditions.RAIN_MAX_PENALTY = 0.22
Conditions.FOG_MAX_PENALTY = 0.12
Conditions.MIN_SPEED_MULT = 0.55

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, tonumber(v) or lo))
end

function Conditions.SampleEnvironment(overrides)
    overrides = type(overrides) == "table" and overrides or nil
    local timeOfDay = overrides and tonumber(overrides.timeOfDay) or nil
    if timeOfDay == nil then
        local gt = getGameTime and getGameTime() or nil
        if gt and type(gt.getTimeOfDay) == "function" then
            local ok, val = pcall(gt.getTimeOfDay, gt)
            if ok and tonumber(val) then timeOfDay = tonumber(val) end
        end
    end
    timeOfDay = tonumber(timeOfDay) or 12.0

    local rain = overrides and tonumber(overrides.rainIntensity) or nil
    local fog = overrides and tonumber(overrides.fogIntensity) or nil
    local storm = overrides and overrides.isStorm or nil
    if rain == nil or fog == nil or storm == nil then
        local cm = getClimateManager and getClimateManager() or nil
        if cm then
            if rain == nil and type(cm.getPrecipitationIntensity) == "function" then
                local ok, val = pcall(cm.getPrecipitationIntensity, cm)
                if ok and tonumber(val) then rain = tonumber(val) end
            end
            if fog == nil and type(cm.getFogIntensity) == "function" then
                local ok, val = pcall(cm.getFogIntensity, cm)
                if ok and tonumber(val) then fog = tonumber(val) end
            end
            if storm == nil and type(cm.getWeatherPeriod) == "function" then
                local ok, wp = pcall(cm.getWeatherPeriod, cm)
                if ok and wp and type(wp.isRunning) == "function" then
                    local okR, running = pcall(wp.isRunning, wp)
                    if okR and running == true and type(wp.isTropicalStorm) == "function" then
                        local okT, ts = pcall(wp.isTropicalStorm, wp)
                        storm = okT and ts == true or false
                    end
                end
            end
        end
    end

    return {
        timeOfDay = timeOfDay,
        rainIntensity = clamp(rain or 0, 0, 1),
        fogIntensity = clamp(fog or 0, 0, 1),
        isStorm = storm == true,
    }
end

function Conditions.Evaluate(overrides)
    local env = Conditions.SampleEnvironment(overrides)
    local isNight = env.timeOfDay >= Conditions.NIGHT_START_HOUR
        or env.timeOfDay < Conditions.NIGHT_END_HOUR
    local mult = 1.0
    local reason = "clear"

    if isNight then
        mult = mult * Conditions.NIGHT_SPEED_MULT
        reason = "night"
    end
    if env.rainIntensity > 0.1 then
        mult = mult * (1.0 - env.rainIntensity * Conditions.RAIN_MAX_PENALTY)
        reason = env.rainIntensity >= 0.7 and "heavy_rain" or "rain"
    end
    if env.fogIntensity > 0.25 then
        mult = mult * (1.0 - env.fogIntensity * Conditions.FOG_MAX_PENALTY)
        if reason == "clear" then reason = "fog" end
    end
    if env.isStorm then
        mult = mult * 0.80
        reason = "storm"
    end

    mult = clamp(mult, Conditions.MIN_SPEED_MULT, 1.0)
    local shouldSeekShelter = env.isStorm
        or env.rainIntensity >= 0.75
        or (isNight and env.rainIntensity >= 0.35)

    return {
        speedMultiplier = mult,
        shouldSeekShelter = shouldSeekShelter,
        isNight = isNight,
        reason = reason,
        env = env,
    }
end

function Conditions.HoursUntilDawn(timeOfDay)
    local h = clamp(timeOfDay, 0, 24)
    if h >= Conditions.NIGHT_START_HOUR then
        return (24.0 - h) + Conditions.NIGHT_END_HOUR
    end
    if h < Conditions.NIGHT_END_HOUR then
        return Conditions.NIGHT_END_HOUR - h
    end
    return 0
end

-- Archetype-aware travel & camping evaluation:
-- Traders, Scavengers, Refugees, and Colonists camp until dawn on clear nights;
-- Looters/Raiders/Bandits are nocturnal and only shelter during heavy storms.
function Conditions.EvaluateForArchetype(archetype, overrides)
    local base = Conditions.Evaluate(overrides)
    local arch = string.upper(tostring(archetype or "DEFAULT"))
    local isNocturnal = arch == "LOOTER" or arch == "RAIDER" or arch == "BANDIT"
    local shouldCampNight = false
    local recommendedWaitHours = 0

    if base.isNight and not isNocturnal then
        shouldCampNight = true
        base.shouldSeekShelter = true
        recommendedWaitHours = math.max(
            1.0,
            math.min(8.5, Conditions.HoursUntilDawn(base.env.timeOfDay))
        )
        if base.reason == "clear" or base.reason == "night" then
            base.reason = "night_camp"
        end
    elseif base.shouldSeekShelter then
        recommendedWaitHours = 1.5
    end

    base.archetype = arch
    base.isNocturnal = isNocturnal
    base.shouldCampNight = shouldCampNight
    base.recommendedWaitHours = recommendedWaitHours
    return base
end

return Conditions
