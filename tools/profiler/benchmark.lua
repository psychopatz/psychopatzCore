-- Desktop-Lua microbenchmark. This measures profiler call cost, not PZ engine load.
package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    package.path,
}, ";")

PsychopatzCore = nil
PsychopatzCore = { ProfilerBootstrap = { IsEnabled = function() return true end } }
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
local iterations = tonumber(arg and arg[1]) or 500000
local clock = 0
local adapter = {
    nowMs = function() clock = clock + 0.001; return clock end,
    addSampleCallback = function() end,
    removeSampleCallback = function() end,
    sourceType = function() return "benchmark" end,
}

local function workload(value) return value + 1 end
local function run(callback)
    local value = 0
    local started = os.clock()
    for _ = 1, iterations do value = callback(value) end
    return os.clock() - started, value
end

local baseline = run(workload)
print(string.format("OFF/direct: %.3f us/call", baseline * 1000000 / iterations))
for _, mode in ipairs({ "BASIC", "DETAILED" }) do
    Profiler.Start(mode, adapter, { snapshotEnabled = false })
    local wrapped = Profiler.Wrap("Benchmark.Work", workload)
    local elapsed = run(wrapped)
    print(string.format("%s/wrapped: %.3f us/call (incremental %.3f us/call)",
        mode, elapsed * 1000000 / iterations,
        (elapsed - baseline) * 1000000 / iterations))
    Profiler.Stop()
end
