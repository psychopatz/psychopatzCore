-- Unified client-aware Time & Date formatting, calendar, time-of-day band,
-- relative-time, and watchless sky-estimation utility for all Psychopatz mods.
-- Respects PZ's native 24-hour (military) vs 12-hour (AM/PM) clock option via
-- getCore():getOptionClock24Hour(). Kahlua2-safe Lua 5.1.
PsychopatzCore = PsychopatzCore or {}
local TimeFormat = PsychopatzCore.TimeFormat or {}
PsychopatzCore.TimeFormat = TimeFormat
PsychopatzCore.DateTime = TimeFormat

TimeFormat.VERSION = 2

TimeFormat.MONTH_NAMES = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
}

function TimeFormat.Is24HourClock(override)
    if type(override) == "boolean" then
        return override
    end
    if type(getCore) == "function" then
        local okCore, core = pcall(getCore)
        if okCore and core and type(core.getOptionClock24Hour) == "function" then
            local okOpt, is24 = pcall(core.getOptionClock24Hour, core)
            if okOpt and type(is24) == "boolean" then
                return is24
            end
        end
    end
    return false
end

function TimeFormat.GetMonthName(month)
    local m = math.floor(tonumber(month) or 0)
    return TimeFormat.MONTH_NAMES[m]
end

function TimeFormat.FormatClock(hour, minute, opts)
    local h = tonumber(hour)
    if h == nil then return nil end
    local m = math.floor(tonumber(minute) or 0) % 60
    if m < 0 then m = 0 end
    h = math.floor(h) % 24
    if h < 0 then h = h + 24 end

    local use24 = TimeFormat.Is24HourClock(type(opts) == "table" and opts.use24Hour or nil)
    if use24 then
        return string.format("%02d:%02d", h, m)
    end
    local suffix = h >= 12 and "PM" or "AM"
    local displayHour = h % 12
    if displayHour == 0 then displayHour = 12 end
    return string.format("%d:%02d %s", displayHour, m, suffix)
end

function TimeFormat.FormatClockSentence(hour, minute, opts)
    local clock = TimeFormat.FormatClock(hour, minute, opts)
    if not clock then return nil end
    return "It's " .. clock .. "."
end

function TimeFormat.FormatDayClock(worldMinute, opts)
    local wm = math.max(0, math.floor(tonumber(worldMinute) or 0))
    local day = math.floor(wm / 1440) + 1
    local minuteOfDay = wm % 1440
    local clock = TimeFormat.FormatClock(math.floor(minuteOfDay / 60), minuteOfDay % 60, opts)
    return string.format("D%d %s", day, clock or "00:00")
end

function TimeFormat.FormatDate(year, month, day)
    local y = math.floor(tonumber(year) or 0)
    local m = math.floor(tonumber(month) or 0)
    local d = math.floor(tonumber(day) or 0)
    local monthName = TimeFormat.MONTH_NAMES[m]
    if y <= 0 or not monthName or d < 1 or d > 31 then return nil end
    return string.format("%s %d, %d", monthName, d, y)
end

function TimeFormat.FormatDateSentence(year, month, day, gameDay)
    local dateStr = TimeFormat.FormatDate(year, month, day)
    if dateStr then
        return "It's " .. dateStr .. "."
    end
    if tonumber(gameDay) ~= nil then
        return "It's day " .. tostring(math.floor(tonumber(gameDay))) .. "."
    end
    return nil
end

function TimeFormat.FormatDateTime(year, month, day, hour, minute, opts)
    opts = type(opts) == "table" and opts or {}
    local dateStr = TimeFormat.FormatDate(year, month, day)
    local clockStr = TimeFormat.FormatClock(hour, minute, opts)
    if not dateStr then
        if opts.gameDay ~= nil and clockStr then
            return string.format("Day %d, %s", math.floor(tonumber(opts.gameDay) or 1), clockStr)
        end
        return clockStr
    end
    if not clockStr then return dateStr end
    if opts.gameDay ~= nil then
        return string.format("%s (Day %d, %s)", dateStr, math.floor(tonumber(opts.gameDay) or 1), clockStr)
    end
    return string.format("%s, %s", dateStr, clockStr)
end

function TimeFormat.FormatISO(year, month, day, hour, minute)
    local y = math.floor(tonumber(year) or 0)
    local m = math.floor(tonumber(month) or 0)
    local d = math.floor(tonumber(day) or 0)
    if y <= 0 or m < 1 or m > 12 or d < 1 or d > 31 then return nil end
    local h = math.max(0, math.min(23, math.floor(tonumber(hour) or 0)))
    local min = math.max(0, math.min(59, math.floor(tonumber(minute) or 0)))
    return string.format("%04d-%02d-%02dT%02d:%02d:00", y, m, d, h, min)
end

function TimeFormat.FormatWorldTime(world, opts)
    local time = type(world) == "table" and (world.time or world) or nil
    if type(time) ~= "table" or time.available == false then return nil end
    local hour = tonumber(time.hour or time.hour24)
    local minute = tonumber(time.minute or time.minutes) or 0
    if hour == nil then return nil end
    return TimeFormat.FormatClock(hour, minute, opts)
end

function TimeFormat.SnapshotFromGameTime(gt)
    gt = gt or (type(getGameTime) == "function" and getGameTime()) or nil
    if not gt then return nil end
    local function readNum(method)
        if type(gt[method]) ~= "function" then return nil end
        local ok, val = pcall(gt[method], gt)
        return ok and tonumber(val) or nil
    end
    local year = readNum("getYear")
    local month = readNum("getMonth")
    local day = readNum("getDay")
    local hour = readNum("getHour")
    local minute = readNum("getMinutes") or 0
    local age = readNum("getWorldAgeHours") or 0
    local tod = readNum("getTimeOfDay") or ((hour or 0) + (minute / 60))
    return {
        year = year and math.floor(year) or nil,
        month = month and (math.floor(month) + 1) or nil, -- PZ getMonth() is 0-indexed
        day = day and (math.floor(day) + 1) or nil,       -- PZ getDay() is 0-indexed
        hour = hour and (math.floor(hour) % 24) or 0,
        minute = math.floor(minute) % 60,
        worldAgeHours = age,
        gameDay = math.floor(age / 24) + 1,
        timeOfDay = tod,
    }
end

function TimeFormat.ResolveTimeBand(hour)
    hour = tonumber(hour)
    if not hour then return "day" end
    hour = math.floor(hour) % 24
    if hour < 5 or hour >= 21 then return "night"
    elseif hour < 7 then return "dawn"
    elseif hour < 12 then return "morning"
    elseif hour < 18 then return "afternoon"
    else return "dusk" end
end

function TimeFormat.EstimateFromHour(hour)
    hour = tonumber(hour)
    if not hour then return "hard to tell without a watch", true end
    hour = math.floor(hour) % 24
    if hour < 5 then return "past midnight, still deep into the night", true
    elseif hour < 7 then return "around dawn", false
    elseif hour < 10 then return "early morning", false
    elseif hour < 12 then return "late morning, getting close to noon", false
    elseif hour < 14 then return "around noon", false
    elseif hour < 17 then return "mid-afternoon", false
    elseif hour < 19 then return "late afternoon, sun's getting low", false
    elseif hour < 21 then return "around dusk", false
    else return "late at night", true end
end

function TimeFormat.FormatRelativeHours(deltaHours)
    local d = tonumber(deltaHours)
    if not d or d < 0 then return "recently" end
    if d < 1 then return "just now"
    elseif d < 6 then return "earlier today"
    elseif d < 24 then return "a few hours ago"
    elseif d < 48 then return "yesterday"
    else return tostring(math.floor(d / 24)) .. " days ago" end
end

return TimeFormat
