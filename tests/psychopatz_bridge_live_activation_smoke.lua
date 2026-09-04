local function equal(actual, expected, message)
    if actual ~= expected then error((message or "mismatch") .. ": expected="
        .. tostring(expected) .. " actual=" .. tostring(actual)) end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua", package.path,
}, ";")

local bridgeEnabled = false
getFileReader = function(name)
    if name ~= "PsychopatzCore_Bridge.txt" then return nil end
    local lines = { "config_version=1", "bridge_enabled=" .. tostring(bridgeEnabled) }
    local index = 0
    return { readLine = function() index = index + 1 return lines[index] end,
        close = function() end }
end
getTimeInMillis = function() return 5000 end
Events = {
    OnTick = { Add = function() end, Remove = function() end },
    OnGameExit = { Add = function() end, Remove = function() end },
}

local activationCallback = nil
local unregistered = nil
local Profiler = {
    IsRunning = function() return true end,
    IsSectionEnabled = function(section) return section == "performance" end,
    RegisterSampler = function(id, callback)
        activationCallback = callback
        return id == "PsychopatzCore.bridgeActivation"
    end,
    UnregisterSampler = function(id) unregistered = id return true end,
}
local Runtime = { GetRuntimeMetadata = function() return { id = "live-runtime" } end,
    ApplyCaptureConfig = function() return { applied = true } end }
local Transport = { SLOT_COUNT = 16, WriteRuntime = function() return true end,
    ReadRequest = function() return nil end, WriteResponse = function() return true end }

PsychopatzCore = { Profiler = Profiler, ProfilerBootstrap = Runtime }
package.loaded["PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"] = Runtime
package.loaded["PsychopatzCore/Bridge/PsychopatzBridgeFileTransport"] = Transport

local Bootstrap = require "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap"
equal(Bootstrap.Initialize(), false, "disabled bridge activated")
equal(type(activationCallback), "function", "active profiler did not install bridge probe")

bridgeEnabled = true
activationCallback()
equal(Bootstrap.IsEnabled(), true, "bridge did not activate after config change")
equal(unregistered, "PsychopatzCore.bridgeActivation", "activation probe remained registered")
local capabilities = PsychopatzCore.Bridge.GetCapabilities()
equal(capabilities["psychopatzcore.profiler"] ~= nil, true,
    "profiler live configuration command was not composed")

print("psychopatz bridge live activation: ok")
