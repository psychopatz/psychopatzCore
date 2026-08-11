PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Inventory = PsychopatzCore.Inventory or {}

local Metrics = { values = {} }

function Metrics.increment(name, amount)
    amount = tonumber(amount) or 1
    Metrics.values[name] = (Metrics.values[name] or 0) + amount
    local profiler = PsychopatzCore.Profiler
    if profiler and profiler.IsRunning and profiler.IsRunning() then
        profiler.Increment("Inventory." .. name, amount)
    end
end

function Metrics.gauge(name, value)
    Metrics.values[name] = tonumber(value) or 0
    local profiler = PsychopatzCore.Profiler
    if profiler and profiler.IsRunning and profiler.IsRunning() then
        profiler.SetGauge("Inventory." .. name, value)
    end
end

function Metrics.snapshot()
    local output = {}
    for key, value in pairs(Metrics.values) do output[key] = value end
    local logical = output.logicalItemCount or 0
    local records = output.serializedRecordCount or 0
    output.compressionRatio = records > 0 and logical / records or 0
    return output
end

PsychopatzCore.Inventory.Metrics = Metrics
return Metrics
