local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "mismatch") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/server/?.lua",
    package.path,
}, ";")

local lines = { "mode=BASIC", "capture=performance" }
local sampleAdds = 0
local commandAdds = 0
local commandRemoves = 0

isClient = function() return false end
isServer = function() return true end
getTimeInMillis = function() return 200 end
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
Events = {
    EveryOneSecond = {
        Add = function() sampleAdds = sampleAdds + 1 end,
        Remove = function() end,
    },
    OnClientCommand = {
        Add = function() commandAdds = commandAdds + 1 end,
        Remove = function() commandRemoves = commandRemoves + 1 end,
    },
}

PsychopatzCore = { COMMAND_MODULE = "PsychopatzCore" }
require "PsychopatzCore/Runtime/PC_RuntimeRole"
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"

equal(Bootstrap.Initialize(), true, "configured profiler did not start")
equal(sampleAdds, 1, "shared profiler sampler was not installed")
equal(commandAdds, 0, "server transport started during shared loading")

require "PsychopatzCore/00_PsychopatzCore_Server_Init"
equal(commandAdds, 1, "server role did not start after server loading")

Bootstrap.Disable()
equal(commandRemoves, 1, "server profiler transport was not removed")

print("psychopatz profiler server composition: ok")
