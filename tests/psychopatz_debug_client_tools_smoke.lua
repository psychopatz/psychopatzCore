local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local definitions = {}
PsychopatzCore = {
    Debug = {
        CanUse = function() return true end,
    },
    DebugHub = {
        RegisterTool = function(definition)
            definitions[definition.id] = definition
            return true
        end,
    },
    Translation = {
        GetKey = function(_, key, fallback) return fallback or key end,
    },
}

package.preload["PsychopatzCore/Preview/PC_Preview"] = function()
    return {
        ListProviders = function()
            return { "sample" }
        end,
    }
end

getPlayer = function() return {} end
dofile(CLIENT .. "PsychopatzCore/Debug/PsychopatzDebugClient_Tools.lua")

local expected = {
    ["psychopatz.preview"] = 25,
    ["psychopatz.worldMetadata"] = 30,
    ["psychopatz.runtimeTrace"] = 5,
    ["psychopatz.debugSettings"] = 10,
    ["psychopatz.translationCoverage"] = 20,
}
local count = 0
for id, order in pairs(expected) do
    assert(definitions[id], "missing debug tool: " .. id)
    assert(definitions[id].order == order, "debug tool order changed: " .. id)
    count = count + 1
end
assert(count == 5, "unexpected debug tool registration count")

print("psychopatz_debug_client_tools_smoke: ok")
