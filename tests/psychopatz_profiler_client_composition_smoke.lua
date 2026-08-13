local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "mismatch") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.19/media/lua/client/?.lua",
    package.path,
}, ";")

local sampleAdds = 0
local sampleRemoves = 0
local commandAdds = 0
local commandRemoves = 0
local toolsRegistered = 0
local toolsRemoved = 0

-- Single-player still owns the client/UI profiler role even though PZ reports
-- neither network role.
isClient = function() return false end
isServer = function() return false end
getFileReader = function() return nil end
getTimeInMillis = function() return 100 end
getText = function(key) return key end
getPlayer = function() return nil end
Events = {
    EveryOneSecond = {
        Add = function() sampleAdds = sampleAdds + 1 end,
        Remove = function() sampleRemoves = sampleRemoves + 1 end,
    },
    OnServerCommand = {
        Add = function() commandAdds = commandAdds + 1 end,
        Remove = function() commandRemoves = commandRemoves + 1 end,
    },
}

package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] = function()
    PsychopatzCore.DebugHub = {
        RegisterTool = function() toolsRegistered = toolsRegistered + 1 end,
        UnregisterTool = function() toolsRemoved = toolsRemoved + 1 end,
    }
    return PsychopatzCore.DebugHub
end

PsychopatzCore = { COMMAND_MODULE = "PsychopatzCore" }
require "PsychopatzCore/Runtime/PC_RuntimeRole"
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"

equal(Bootstrap.Initialize(), false, "profiler must default off")
require "PsychopatzCore/00_PsychopatzCore_Client_Init"
equal(sampleAdds, 0, "disabled profiler installed a sampler")
equal(commandAdds, 0, "disabled profiler installed client networking")
equal(toolsRegistered, 0, "disabled profiler registered UI")
equal(package.loaded["PsychopatzCore/Profiler/PsychopatzProfilerClient"], nil,
    "disabled composition loaded the client implementation")

local Profiler = Bootstrap.Enable("BASIC")
equal(type(Profiler), "table", "runtime enable failed")
equal(sampleAdds, 1, "profiler sampler was not installed")
equal(commandAdds, 1, "client profiler transport was not installed")
equal(toolsRegistered, 1, "profiler tool was not registered")

Bootstrap.Disable()
equal(sampleRemoves, 1, "profiler sampler was not removed")
equal(commandRemoves, 1, "client profiler transport was not removed")
equal(toolsRemoved, 1, "profiler tool was not removed")

print("psychopatz profiler client composition: ok")
