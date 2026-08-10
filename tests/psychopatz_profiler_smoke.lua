local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function assertTrue(value, message)
    if not value then error(message or "expected true") end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua",
    package.path,
}, ";")

PsychopatzCore = nil
PSYCHOPATZ_PROFILER_MODE = nil
getFileReader = nil

local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
assertEqual(Bootstrap.Initialize(), false, "profiler defaults OFF")
assertEqual(package.loaded["PsychopatzCore/Profiler/PsychopatzProfiler"], nil, "OFF does not require backend")
assertEqual(PsychopatzCore.Profiler, nil, "OFF has no metric registry")

Bootstrap.mode = "DETAILED"
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
local clock = 0
local added, removed, writes = 0, 0, 0
local callback
local adapter = {
    nowMs = function() return clock end,
    sourceType = function() return "test" end,
    addSampleCallback = function(value) callback = value; added = added + 1 end,
    removeSampleCallback = function(value) if callback == value then callback = nil end; removed = removed + 1 end,
    writeSnapshot = function(json) writes = writes + 1; assertTrue(string.find(json, '"profilerVersion":1', 1, true) ~= nil); return true end,
}

Profiler.Start("DETAILED", adapter, { historyCapacity = 3, snapshotEnabled = true })
assertTrue(Profiler.IsRunning())
assertEqual(added, 1, "one callback registered")
assertTrue(Profiler.RegisterNamespace("ExampleMod", { displayName = "Example Mod" }))

Profiler.Increment("ExampleMod.Events.Total", 3)
Profiler.Decrement("ExampleMod.Events.Total", 1)
assertEqual(Profiler.GetMetrics("counter")[1].value, 2, "counter math")
Profiler.SetGauge("ExampleMod.Cache.Size", 10)
Profiler.RecordRate("ExampleMod.Network.Packets", 5)
Profiler.Begin("ExampleMod.System.Update")
clock = clock + 4
Profiler.Finish("ExampleMod.System.Update")

clock = 1000
Profiler.Sample(1000)
local timer = Profiler.GetMetrics("timer")[1]
assertEqual(timer.calls, 1, "timer call count")
assertEqual(timer.totalMs, 4, "timer total")
assertEqual(timer.callsPerSec, 1, "timer rate")
assertEqual(timer.msPerSec, 4, "timer ms/sec")
assertEqual(Profiler.GetMetrics("rate")[1].perSec, 5, "event rate")
assertEqual(writes, 1, "detailed snapshot write")

for index = 1, 5 do
    Profiler.SetGauge("ExampleMod.Cache.Size", index * 10)
    clock = clock + 1000
    Profiler.Sample(1000)
end
local gauge = Profiler.GetMetrics("gauge", "ExampleMod")[1]
assertEqual(gauge.history.count, 3, "ring remains bounded")
assertEqual(#gauge.history.values, 3, "ring backing array remains bounded")
assertEqual(Profiler.SplitName("ExampleMod.Cache.Size"), "ExampleMod", "namespace parsing")
assertEqual(Profiler.BuildSnapshot().profilerVersion, 1, "snapshot version")

local stopped = 0
Profiler.RegisterStopHook("test", function() stopped = stopped + 1 end)
Profiler.Stop()
assertEqual(stopped, 1, "stop hooks run")
assertEqual(removed, 1, "callback removed")
assertEqual(Profiler.GetState(), nil, "runtime state released")

for _ = 1, 2 do
    Profiler.Start("BASIC", adapter, { snapshotEnabled = false })
    assertEqual(Profiler.GetState().metrics ~= nil, true)
    Profiler.Stop()
    assertEqual(Profiler.GetState(), nil, "repeat lifecycle releases state")
end
assertEqual(added, 3, "no duplicate starts")
assertEqual(removed, 3, "every callback removed")

print("psychopatz profiler smoke: ok")
