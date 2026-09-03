local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua",
    package.path,
}, ";")

local rawNow = 100
getTimeInMillis = function() return rawNow end
local selectedEvent
local function makeEvent(name)
    return {
        Add = function() selectedEvent = name end,
        Remove = function() end,
    }
end
Events = {
    OnTick = makeEvent("OnTick"),
    EveryOneSecond = makeEvent("EveryOneSecond"),
}

local Adapter = require "PsychopatzCore/Profiler/PsychopatzProfilerPZAdapter"
Adapter._callbacks, Adapter._lastNowMs = {}, nil
assertEqual(Adapter.nowMs(), 100, "adapter clock")
rawNow = 90
assertEqual(Adapter.nowMs(), 100, "backward clock clamp")
Adapter._lastNowMs = nil
getGameTime = function()
    return { getServerTimeMills = function() return 500 end }
end
assertEqual(Adapter.nowMs(), 500, "monotonic game clock")
getGameTime = nil

local callback = function() end
Adapter.addSampleCallback(callback, 250)
assertEqual(selectedEvent, "OnTick", "sub-second sampling uses ticks")
Adapter.removeSampleCallback(callback)
Adapter.addSampleCallback(callback, 1000)
assertEqual(selectedEvent, "EveryOneSecond", "one-second sampling uses bounded event")
Adapter.onStop()

getAverageFPS = function() return 58 end
getCPUTime = function() return 7 end
getGPUTime = function() return 8 end
getCPUWait = function() return 1 end
getGPUWait = function() return 2 end
getPerformance = function()
    return {
        getLockFPS = function() return 60 end,
        getLightingFPS = function() return 15 end,
        getUIRenderFPS = function() return 60 end,
    }
end
getPerformanceLocal = function() return { ["memory-used"] = 123 } end
getNetworkLocal = function() return { ["received-packets"] = 9 } end
getGameLocal = function() return { players = 1 } end

PsychopatzCore = { ProfilerBootstrap = { IsEnabled = function() return true end } }
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
Profiler.Start("BASIC", Adapter, { snapshotEnabled = false })
assertEqual(Adapter.installEngineMetrics(Profiler), true, "base-game sampler installed")
Profiler.Sample(1000)
assertEqual(Profiler.GetState().metrics["ProjectZomboid.Frame.CPUTimeMs"].value, 7,
    "base-game frame gauge")
assertEqual(Profiler.GetState().metrics["ProjectZomboid.Statistics.Performance.memory-used"].value, 123,
    "base-game performance statistic")
assertEqual(Profiler.GetState().metrics["ProjectZomboid.Statistics.Network.received-packets"].value, 9,
    "base-game network statistic")
assertEqual(Profiler.GetState().metrics["ProjectZomboid.Statistics.Game.players"].value, 1,
    "base-game game statistic")
Profiler.Stop()

print("psychopatz profiler adapter: ok")
