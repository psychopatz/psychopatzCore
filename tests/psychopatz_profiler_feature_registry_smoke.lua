local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "mismatch") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

getFileReader = function() return nil end
PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.Initialize()
local Registry = require "PsychopatzCore/Profiler/PsychopatzProfilerFeatureRegistry"
local installs, samples, snapshots, cleanups = 0, 0, 0, 0

equal(Registry.Register({
    id = "ExampleFeature", namespace = "Example", displayName = "Example Feature",
    sections = { "performance", "npc" },
    install = function()
        installs = installs + 1
        return function() cleanups = cleanups + 1 end
    end,
    samplers = {{ id = "state", section = "performance", callback = function(api)
        samples = samples + 1
        api.SetGauge("Example.State.Count", samples)
    end }},
    snapshotProviders = {{ id = "Example.npc", section = "npc", intervalMs = 1000,
        callback = function() snapshots = snapshots + 1 return { count = snapshots } end }},
}), true, "feature registration")

equal(Registry.IsActive("ExampleFeature"), false, "OFF feature must remain dormant")
equal(installs, 0, "OFF feature installed work")
equal(samples, 0, "OFF feature sampled")

local now = 0
package.loaded["PsychopatzCore/Profiler/PsychopatzProfilerPZAdapter"] = {
    nowMs = function() return now end,
    addSampleCallback = function() return true end,
    removeSampleCallback = function() return true end,
    sourceType = function() return "test" end,
}
Bootstrap.ApplyCaptureConfig({ mode = "DETAILED", capture = { "performance", "npc" } })
local Profiler = PsychopatzCore.Profiler
equal(Registry.IsActive("ExampleFeature"), true, "enabled feature inactive")
equal(installs, 1, "feature install count")
now = 1000
Profiler.Sample(now)
equal(samples, 1, "registered sampler did not run")
local snapshot = Profiler.BuildSnapshot()
equal(snapshot.diagnostics["Example.npc"].count, 1, "snapshot provider missing")

Bootstrap.ApplyCaptureConfig({ mode = "OFF", capture = {} })
equal(Registry.IsActive("ExampleFeature"), false, "disabled feature remained active")
equal(cleanups, 1, "feature cleanup count")

print("psychopatz profiler feature registry: ok")
