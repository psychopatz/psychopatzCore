local T = require "tests/support/test"
T.addPackagePaths()

local callbackCount = 0
package.path = table.concat({
    (T.layerRoot("common_shared") .. "?.lua"),
    (T.layerRoot("runtime_shared") .. "?.lua"), package.path,
}, ";")
Events = { OnTick = { Add = function() callbackCount = callbackCount + 1 end } }
getFileReader = function(name)
    if name ~= "PsychopatzCore_Bridge.txt" then return nil end
    local lines, index = { "config_version=1", "bridge_enabled=false" }, 0
    return { readLine = function() index = index + 1; return lines[index] end,
        close = function() end }
end
PsychopatzCore = {}
local Bootstrap = require "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap"
assert(Bootstrap.Initialize() == false, "disabled bridge initialized")
assert(callbackCount == 0, "disabled bridge registered update callback")
assert(package.loaded["PsychopatzCore/Bridge/PsychopatzBridge"] == nil,
    "disabled bridge loaded runtime backend")
print("psychopatz bridge OFF gate: ok")
