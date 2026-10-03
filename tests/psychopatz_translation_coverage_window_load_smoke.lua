local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local WindowBase = {}
WindowBase.__index = WindowBase
function WindowBase:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end

PsychopatzCore = {
    UI = {
        Layout = {},
        Theme = {},
        Window = WindowBase,
    },
    Debug = { CanUse = function() return false end },
    Translation = {
        GetKey = function(key, fallback) return fallback or key end,
        FormatKey = function(_, fallback) return fallback end,
    },
    TranslationDiagnostics = {},
}
CustomTranslationManager = { getLanguage = function() return "EN" end }

package.preload["ISUI/ISTextEntryBox"] = function() return true end
package.preload["ISUI/ISRichTextPanel"] = function() return true end
package.preload["PsychopatzCore/UI/PsychopatzUI"] =
    function() return PsychopatzCore.UI end
package.preload["PsychopatzCore/Translation/PsychopatzCoreTranslationDiagnostics"] =
    function() return PsychopatzCore.TranslationDiagnostics end

dofile(CLIENT .. "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow.lua")
assert(type(PsychopatzTranslationCoverageWindow.Open) == "function",
    "coverage window public Open method was not installed")
assert(PsychopatzTranslationCoverageWindow.Open() == nil,
    "unauthorized coverage window unexpectedly opened")

print("psychopatz_translation_coverage_window_load_smoke: ok")
