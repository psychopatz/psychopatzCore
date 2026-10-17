-- Opt-in Radio OS diagnostics. Disabled paths must not read clocks, inspect
-- textures, allocate snapshots, or write logs.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local Core = PsychopatzCore
local OS = Core.RadioOS
local Diagnostics = OS.Diagnostics or {}
OS.Diagnostics = Diagnostics

local DebugSettings = Core.DebugSettings
if not DebugSettings and type(require) == "function" then
    pcall(require, "PsychopatzCore/Debug/PsychopatzDebugSettings")
    DebugSettings = Core.DebugSettings
end

local DebugTrace = Core.DebugTrace
if not DebugTrace and type(require) == "function" then
    pcall(require, "PsychopatzCore/Debug/PsychopatzDebugTrace")
    DebugTrace = Core.DebugTrace
end

local PRESENTATION_SETTING = "PsychopatzCore.RadioOS.PresentationDiagnostics"
local PERFORMANCE_SETTING = "PsychopatzCore.RadioOS.PerformanceDiagnostics"
local LAYOUT_INSPECTOR_SETTING = "PsychopatzCore.RadioOS.LayoutInspector"
local COMPOSITOR_SETTING = "PsychopatzCore.RadioOS.CompositorOverlay"
local SOURCE = "PsychopatzCore.RadioOS"
local MAX_EVENTS = 96

Diagnostics.PRESENTATION_SETTING = PRESENTATION_SETTING
Diagnostics.PERFORMANCE_SETTING = PERFORMANCE_SETTING
Diagnostics.LAYOUT_INSPECTOR_SETTING = LAYOUT_INSPECTOR_SETTING
Diagnostics.COMPOSITOR_SETTING = COMPOSITOR_SETTING
Diagnostics.SOURCE = SOURCE
Diagnostics.presentationEnabled = Diagnostics.presentationEnabled == true
Diagnostics.performanceEnabled = Diagnostics.performanceEnabled == true
Diagnostics.layoutInspectorEnabled = Diagnostics.layoutInspectorEnabled == true
Diagnostics.events = Diagnostics.events or {}
Diagnostics.sequence = tonumber(Diagnostics.sequence) or 0
Diagnostics.windowSequence = tonumber(Diagnostics.windowSequence) or 0

local function nowMs()
    if type(getTimeInMillis) == "function" then
        return tonumber(getTimeInMillis())
    end
    return nil
end

local function bounded(value, limit)
    local text = tostring(value or "")
    limit = limit or 160
    if #text <= limit then return text end
    return string.sub(text, 1, math.max(1, limit - 3)) .. "..."
end

local function scalarCopy(data)
    local output = {}
    for key, value in pairs(type(data) == "table" and data or {}) do
        local valueType = type(value)
        if valueType == "number" or valueType == "boolean"
            or valueType == "string"
        then
            output[tostring(key)] = valueType == "string"
                and bounded(value, 180) or value
        elseif value ~= nil then
            output[tostring(key)] = "[" .. valueType .. "]"
        end
    end
    return output
end

local function formatData(data)
    local keys = {}
    for key, _ in pairs(data or {}) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    local fields = {}
    for _, key in ipairs(keys) do
        fields[#fields + 1] = key .. "=" .. tostring(data[key])
    end
    return table.concat(fields, " ")
end

function Diagnostics.IsPresentationEnabled()
    return Diagnostics.presentationEnabled == true
end

function Diagnostics.IsPerformanceEnabled()
    return Diagnostics.performanceEnabled == true
end

function Diagnostics.IsLayoutInspectorEnabled()
    return Diagnostics.layoutInspectorEnabled == true
end

function Diagnostics.SetPresentationEnabled(enabled)
    Diagnostics.presentationEnabled = enabled == true
    return Diagnostics.presentationEnabled
end

function Diagnostics.SetPerformanceEnabled(enabled)
    Diagnostics.performanceEnabled = enabled == true
    if type(Diagnostics.ResetPerformance) == "function" then
        Diagnostics.ResetPerformance()
    end
    return Diagnostics.performanceEnabled
end

function Diagnostics.SetLayoutInspectorEnabled(enabled)
    Diagnostics.layoutInspectorEnabled = enabled == true
    return Diagnostics.layoutInspectorEnabled
end

function Diagnostics.Clear()
    Diagnostics.events = {}
    Diagnostics.sequence = 0
    if type(Diagnostics.ResetPerformance) == "function" then
        Diagnostics.ResetPerformance()
    end
end

local function recordToTrace(event, data)
    if not DebugTrace or type(DebugTrace.Record) ~= "function" then
        return
    end
    if type(DebugTrace.IsEnabled) == "function"
        and not DebugTrace.IsEnabled()
    then
        return
    end
    DebugTrace.Record({
        source = SOURCE,
        event = "radio_os." .. tostring(event),
        data = data,
    })
end

local function record(event, data, kind, printToConsole)
    if kind == "performance" then
        if not Diagnostics.IsPerformanceEnabled() then return false end
    elseif not Diagnostics.IsPresentationEnabled() then
        return false
    end

    Diagnostics.sequence = Diagnostics.sequence + 1
    local safeData = scalarCopy(data)
    local entry = {
        id = Diagnostics.sequence,
        timestamp = nowMs() or 0,
        kind = kind or "presentation",
        event = tostring(event or "event"),
        data = safeData,
    }
    Diagnostics.events[#Diagnostics.events + 1] = entry
    while #Diagnostics.events > MAX_EVENTS do
        table.remove(Diagnostics.events, 1)
    end

    recordToTrace(entry.event, safeData)
    if printToConsole ~= false and type(print) == "function" then
        print("[PsychopatzCore][RadioOS][Diag] " .. entry.event
            .. " " .. formatData(safeData))
    end
    return true
end

function Diagnostics.RecordPresentation(event, data, options)
    options = type(options) == "table" and options or {}
    return record(event, data, "presentation", options.print ~= false)
end

function Diagnostics.RecordPerformance(event, data, options)
    options = type(options) == "table" and options or {}
    return record(event, data, "performance", options.print ~= false)
end

local function registerSettings()
    if not DebugSettings or type(DebugSettings.Register) ~= "function" then
        return false
    end
    DebugSettings.Register({
        id = PRESENTATION_SETTING,
        source = "PsychopatzCore.RadioOS",
        order = 210,
        title = "Radio OS presentation diagnostics",
        description = "Records bounded Radio OS lifecycle, clipping, hit-test, and swipe decisions.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SetPresentationEnabled(enabled)
        end,
    })
    DebugSettings.Register({
        id = COMPOSITOR_SETTING,
        source = "PsychopatzCore.RadioOS",
        order = 230,
        title = "Radio OS compositor overlay",
        description = "Draws the Radio OS shell, LCD, clip, and physical hitbox boundaries.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            if type(OS.SetCompositorDebug) == "function" then
                OS.SetCompositorDebug(enabled == true)
            end
        end,
    })
    DebugSettings.Register({
        id = LAYOUT_INSPECTOR_SETTING,
        source = "PsychopatzCore.RadioOS",
        order = 220,
        title = "Radio OS absolute layout inspector",
        description = "Shows debug-only pixel X/Y fields for testing off-screen window coordinates.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SetLayoutInspectorEnabled(enabled)
        end,
    })
    return true
end

registerSettings()

if type(require) == "function" then
    local interactionLoaded, interactionReason = pcall(require,
        "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDiagnostics_Interaction")
    if not interactionLoaded and type(print) == "function" then
        print("[PsychopatzCore][RadioOS] interaction diagnostics unavailable: "
            .. tostring(interactionReason))
    end
    local performanceLoaded, performanceReason = pcall(require,
        "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDiagnostics_Performance")
    if not performanceLoaded and type(print) == "function" then
        print("[PsychopatzCore][RadioOS] performance diagnostics unavailable: "
            .. tostring(performanceReason))
    end
end

return Diagnostics
