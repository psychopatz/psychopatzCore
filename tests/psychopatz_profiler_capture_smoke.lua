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

local lines = {
    "config_version=2", "mode=DETAILED", "capture=performance,npc",
    "performance_interval_ms=750", "moddata_interval_ms=60000",
    "npc_interval_ms=5000", "npc_scope=selected", "npc_ids=npc_b,npc_a",
}
getFileReader = function()
    local index = 0
    return {
        readLine = function()
            index = index + 1
            return lines[index]
        end,
        close = function() end,
    }
end
local writtenPath
local writtenConfig
getFileWriter = function(path)
    writtenPath = path
    return {
        write = function(_, value) writtenConfig = value end,
        close = function() end,
    }
end

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local config = Bootstrap.ReadConfiguredConfig()
equal(config.enabled.performance, true, "performance capture")
equal(config.enabled.moddata, nil, "ModData capture must remain disabled")
equal(config.enabled.npc, true, "NPC capture")
equal(config.fingerprint, "v2|DETAILED|performance,npc|750|60000|5000|selected|npc_a,npc_b",
    "canonical config fingerprint")
local saved, saveReason = Bootstrap.WriteConfiguredConfig(config)
equal(saved, true, "runtime config persistence")
equal(saveReason, nil, "runtime config persistence reason")
equal(writtenPath, "PsychopatzCore_Profiler.txt", "shared config path")
equal(writtenConfig, table.concat({
    "config_version=2", "mode=DETAILED", "capture=performance,npc",
    "performance_interval_ms=750", "moddata_interval_ms=60000",
    "npc_interval_ms=5000", "npc_scope=selected", "npc_ids=npc_b,npc_a", "",
}, "\n"), "shared config serialization")

Bootstrap.mode = "DETAILED"
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
local now = 100
local providerCalls = 0
Profiler.Start("DETAILED", { nowMs = function() return now end }, {
    snapshotEnabled = false,
    capture = { performance = true, moddata = true, npc = false },
    runtime = { id = "boot-test", configFingerprint = config.fingerprint,
        capture = { performance = true, moddata = true, npc = false } },
})
equal(Profiler.RegisterSnapshotProvider("disabled", function()
    providerCalls = providerCalls + 1
    return { bad = true }
end, { section = "npc" }), false, "disabled provider registration")
equal(Profiler.RegisterSnapshotProvider("moddata", function()
    providerCalls = providerCalls + 1
    return { calls = providerCalls }
end, { section = "moddata", intervalMs = 1000 }), true, "enabled provider registration")
local snapshot = Profiler.BuildSnapshot()
equal(providerCalls, 1, "enabled provider first capture")
now = 500
snapshot = Profiler.BuildSnapshot()
equal(providerCalls, 1, "provider ignored interval")
equal(snapshot.diagnostics.moddata.calls, 1, "provider cache missing")
now = 1200
Profiler.BuildSnapshot()
equal(providerCalls, 2, "provider did not refresh after interval")
equal(snapshot.runtime.id, "boot-test", "runtime identity")
equal(snapshot.runtime.configFingerprint, config.fingerprint, "applied fingerprint")
Profiler.Stop()

print("psychopatz profiler capture: ok")
