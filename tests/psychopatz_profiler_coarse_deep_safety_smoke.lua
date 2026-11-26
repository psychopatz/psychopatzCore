local T = require "tests/support/test"
T.addPackagePaths()

local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "mismatch") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, message)
    if not value then
        error(message or "expected truthy value")
    end
end

package.path = table.concat({
    (T.layerRoot("common_shared") .. "?.lua"),
    (T.layerRoot("runtime_shared") .. "?.lua"),
    package.path,
}, ";")

local now = 1000
local writtenConfig = nil
local readerLines = nil

getTimeInMillis = function() return now end
isClient = function() return false end
isServer = function() return false end
Events = {
    EveryOneSecond = { Add = function() end, Remove = function() end },
    OnTick = { Add = function() end, Remove = function() end },
}
getFileReader = function()
    if not readerLines then return nil end
    local index = 0
    return {
        readLine = function()
            index = index + 1
            return readerLines[index]
        end,
        close = function() end,
    }
end
getFileWriter = function()
    return {
        write = function(_, value) writtenConfig = value end,
        close = function() end,
    }
end

-- 1. Verify strict OFF default.
PsychopatzCore = nil
PSYCHOPATZ_PROFILER_MODE = nil
PSYCHOPATZ_PROFILER_PERFORMANCE_DEPTH = nil
PSYCHOPATZ_PROFILER_DEEP_DURATION_MS = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
equal(Bootstrap.Initialize(), false, "profiler must default OFF")
equal(package.loaded["PsychopatzCore/Profiler/PsychopatzProfiler"], nil,
    "OFF mode must not load profiler backend")
equal(Bootstrap.GetPerformanceDepth(), "off", "OFF performance depth")

-- 2. Verify persisted config with performance_depth=deep downgrades to coarse.
readerLines = {
    "config_version=2",
    "mode=DETAILED",
    "capture=performance",
    "performance_depth=deep",
    "deep_duration_ms=15000",
}
local persisted = Bootstrap.ReadConfiguredConfig()
equal(persisted.mode, "DETAILED", "persisted mode")
equal(persisted.performanceDepth, "coarse", "persisted deep must downgrade to coarse")
equal(persisted.persistedDeepDowngraded, true, "persisted deep downgrade marker")
equal(persisted.fingerprint, "v2|DETAILED|performance|1000|60000|5000|selected|",
    "downgraded persisted config keeps canonical v2 fingerprint")
local wrote, writeReason = Bootstrap.WriteConfiguredConfig({
    mode = "DETAILED",
    sections = { "performance" },
    performanceIntervalMs = 1000,
    modDataIntervalMs = 60000,
    npcIntervalMs = 5000,
    npcScope = "selected",
    npcIDs = {},
    performanceDepth = "deep",
    deepDurationMs = 15000,
})
equal(wrote, true, writeReason)
equal(string.find(writtenConfig or "", "performance_depth=deep", 1, true), nil,
    "WriteConfiguredConfig must never persist performance_depth=deep")

-- 3. Verify Bootstrap.Disable updates captureConfig and notifies controllers.
local controllerEvents = {}
local originalDeepFn = function() return "deep" end
local originalCoarseFn = function() return "coarse" end
local holder = { deepFn = originalDeepFn, coarseFn = originalCoarseFn }

Bootstrap.RegisterCaptureController("test.controller", function(config)
    controllerEvents[#controllerEvents + 1] = {
        mode = config.mode,
        depth = config.performanceDepth,
        expired = config.deepExpired == true,
    }
    local Profiler = PsychopatzCore and PsychopatzCore.Profiler
    if not Profiler or not Profiler.IsRunning or not Profiler.IsRunning()
        or config.mode == "OFF"
    then
        holder.deepFn = originalDeepFn
        holder.coarseFn = originalCoarseFn
        return true
    end
    if not Profiler.IsDeepPerformanceEnabled() then
        holder.deepFn = originalDeepFn
    end
    if Profiler.IsSectionEnabled("performance") then
        if holder.coarseFn == originalCoarseFn then
            holder.coarseFn = Profiler.Wrap("Test.Coarse", originalCoarseFn, { depth = "coarse" })
        end
        if Profiler.IsDeepPerformanceEnabled() and holder.deepFn == originalDeepFn then
            holder.deepFn = Profiler.Wrap("Test.Deep", originalDeepFn, { depth = "deep" })
            Profiler.RegisterDeepStopHook("test.deep", function()
                holder.deepFn = originalDeepFn
            end)
        end
    end
    return true
end)

local appliedCoarse = Bootstrap.ApplyCaptureConfig({
    mode = "BASIC",
    capture = { "performance" },
})
equal(appliedCoarse.applied, true, "coarse capture apply")
equal(appliedCoarse.performance_depth, "coarse", "default depth is coarse")
equal(PsychopatzCore.Profiler.GetPerformanceDepth(), "coarse", "running depth is coarse")
equal(PsychopatzCore.Profiler.IsDeepPerformanceEnabled(), false, "deep must be false in coarse")
truthy(holder.coarseFn ~= originalCoarseFn, "coarse wrapper should be installed")
equal(holder.deepFn, originalDeepFn, "deep wrapper must not install in coarse mode")

Bootstrap.Disable()
equal(Bootstrap.GetMode(), "OFF", "Disable sets Bootstrap.mode OFF")
equal(Bootstrap.GetCaptureConfig().mode, "OFF", "Disable updates captureConfig.mode OFF")
equal(Bootstrap.IsSectionEnabled("performance"), false, "Disable clears active performance section")
equal(Bootstrap.GetPerformanceDepth(), "off", "Disable sets performance depth off")
equal(holder.coarseFn, originalCoarseFn, "Disable restores coarse wrapper")
equal(holder.deepFn, originalDeepFn, "Disable restores deep wrapper")
equal(controllerEvents[#controllerEvents].mode, "OFF", "Disable notifies controllers with OFF")

-- 4. Verify explicit deep opt-in, duration clamping, snapshot labels, and Sample expiry.
local lowClamp = Bootstrap.BuildConfig({
    mode = "DETAILED",
    capture = "performance",
    performance_depth = "deep",
    deep_duration_ms = 100,
})
equal(lowClamp.deepDurationMs, 5000, "deep duration lower clamp")
local highClamp = Bootstrap.BuildConfig({
    mode = "DETAILED",
    capture = "performance",
    performance_depth = "deep",
    deep_duration_ms = 9999999,
})
equal(highClamp.deepDurationMs, 300000, "deep duration upper clamp")

local deepApply = Bootstrap.ApplyCaptureConfig({
    mode = "DETAILED",
    capture = { "performance" },
    performance_depth = "deep",
    deep_duration_ms = 10000,
})
equal(deepApply.applied, true, "deep apply")
equal(deepApply.performance_depth, "deep", "deep applied depth")
equal(deepApply.deep_duration_ms, 10000, "deep applied duration")
equal(deepApply.deep_expires_at_ms, 11000, "deep expiry deadline")

local Profiler = PsychopatzCore.Profiler
equal(Profiler.GetPerformanceDepth(), "deep", "active profiler depth is deep")
equal(Profiler.IsDeepPerformanceEnabled(), true, "deep enabled")
truthy(holder.coarseFn ~= originalCoarseFn, "coarse wrapper installed under deep")
truthy(holder.deepFn ~= originalDeepFn, "deep wrapper installed under deep")
equal(holder.deepFn(), "deep", "wrapped deep callback preserves return")
equal(holder.coarseFn(), "coarse", "wrapped coarse callback preserves return")

local deepSnapshot = Profiler.BuildSnapshot()
equal(deepSnapshot.runtime.instrumentation.performanceDepth, "deep", "snapshot deep depth")
equal(deepSnapshot.runtime.instrumentation.deepInstrumented, true, "snapshot deepInstrumented")
equal(deepSnapshot.runtime.instrumentation.timingLabel, "deep_instrumented_diagnostic_only",
    "snapshot deep timing label")

now = 11000
Profiler.Sample(1000)
equal(Profiler.IsRunning(), true, "deep expiry keeps coarse profiler session running")
equal(Profiler.GetPerformanceDepth(), "coarse", "deep expiry downgrades to coarse")
equal(Profiler.IsDeepPerformanceEnabled(), false, "deep disabled after expiry")
equal(holder.deepFn, originalDeepFn, "deep wrapper restored on expiry")
truthy(holder.coarseFn ~= originalCoarseFn, "coarse wrapper remains active after deep expiry")
equal(Bootstrap.GetPerformanceDepth(), "coarse", "Bootstrap depth updated after expiry")

local expiredSnapshot = Profiler.BuildSnapshot()
equal(expiredSnapshot.runtime.instrumentation.deepInstrumented, false, "post-expiry deepInstrumented false")
equal(expiredSnapshot.runtime.instrumentation.deepExpired, true, "post-expiry deepExpired marker")
equal(expiredSnapshot.runtime.instrumentation.timingLabel, "coarse_sampled", "post-expiry timing label")

-- 5. Verify expiry via a deep Wrap call directly (without waiting for Sample).
now = 12000
Bootstrap.ApplyCaptureConfig({
    mode = "DETAILED",
    capture = { "performance" },
    performance_depth = "deep",
    deep_duration_ms = 5000,
})
truthy(holder.deepFn ~= originalDeepFn, "second deep wrapper installed")
local savedDeepWrapper = holder.deepFn
now = 17000
equal(savedDeepWrapper(), "deep", "expired deep wrapper still returns callback result")
equal(Profiler.GetPerformanceDepth(), "coarse", "deep wrapper invocation triggers expiry")
equal(holder.deepFn, originalDeepFn, "deep wrapper invocation restores deep target")
equal(savedDeepWrapper(), "deep", "stale deep wrapper closure bypasses safely")

Bootstrap.Disable()
equal(holder.coarseFn, originalCoarseFn, "final Disable restores coarse wrapper")

print("psychopatz profiler coarse deep safety: ok")
