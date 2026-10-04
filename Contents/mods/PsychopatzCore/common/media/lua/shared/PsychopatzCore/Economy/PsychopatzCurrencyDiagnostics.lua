-- Opt-in, bounded diagnostics for currency mutations.
-- The disabled path is intentionally only a boolean check.
PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Diagnostics = Core.CurrencyDiagnostics or {}
Core.CurrencyDiagnostics = Diagnostics

local SETTING_ID = "PsychopatzCore.CurrencyAudit"
local SOURCE = "PsychopatzCore.Currency"
local MAX_STRING = 160

Diagnostics.SETTING_ID = SETTING_ID
Diagnostics.Enabled = Diagnostics.Enabled == true
Diagnostics.Sequence = tonumber(Diagnostics.Sequence) or 0

local function bounded(value)
    local output = tostring(value or "")
    if #output <= MAX_STRING then return output end
    return string.sub(output, 1, MAX_STRING - 3) .. "..."
end

local function settingsObject()
    local settings = Core.DebugSettings
    if settings and type(settings.Register) == "function" then
        return settings
    end
    if type(require) == "function" then
        pcall(require, "PsychopatzCore/Debug/PsychopatzDebugSettings")
    end
    return Core.DebugSettings
end

function Diagnostics.IsEnabled()
    return Diagnostics.Enabled == true
end

function Diagnostics.SetEnabled(enabled)
    Diagnostics.Enabled = enabled == true
    return Diagnostics.Enabled
end

function Diagnostics.Begin(operation)
    if not Diagnostics.IsEnabled() then return nil end
    Diagnostics.Sequence = Diagnostics.Sequence + 1
    local operationID = tostring(operation or "currency") .. "-"
        .. tostring(Diagnostics.Sequence)
    Diagnostics.Record(operationID, "begin", {
        operation = operation,
    })
    return operationID
end

function Diagnostics.Record(operationID, phase, data)
    if not Diagnostics.IsEnabled() or not operationID then return false end
    data = type(data) == "table" and data or {}
    local fields = {
        "currency_audit",
        "op=" .. bounded(operationID),
        "phase=" .. bounded(phase),
    }
    for key, value in pairs(data) do
        if value ~= nil then
            fields[#fields + 1] = tostring(key) .. "=" .. bounded(value)
        end
    end
    local message = table.concat(fields, " ")
    local trace = Core.DebugTrace
    if trace and type(trace.Record) == "function" then
        trace.Record({
            source = SOURCE,
            event = "currency." .. bounded(phase),
            requestID = tostring(operationID),
            data = data,
        })
    end
    if type(print) == "function" then
        print("[PsychopatzCore][CurrencyAudit] " .. message)
    end
    return true
end

function Diagnostics.Snapshot(operationID, phase, snapshot)
    if not Diagnostics.IsEnabled() or not operationID then return false end
    snapshot = type(snapshot) == "table" and snapshot or {}
    return Diagnostics.Record(operationID, phase, {
        units = snapshot.units,
        loose = snapshot.loose,
        bundles = snapshot.bundles,
        itemCount = snapshot.itemCount,
    })
end

local function registerSetting()
    local settings = settingsObject()
    if not settings or type(settings.Register) ~= "function" then
        return false
    end
    settings.Register({
        id = SETTING_ID,
        source = "PsychopatzCore.Currency",
        order = 168,
        title = "Currency conversion audit",
        description = "Logs currency conversion phases, counts, and rollback verification.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SetEnabled(enabled)
        end,
    })
    if type(settings.IsEnabled) == "function" then
        Diagnostics.SetEnabled(settings.IsEnabled(SETTING_ID) == true)
    end
    return true
end

registerSetting()

return Diagnostics
