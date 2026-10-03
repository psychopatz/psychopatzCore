local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

PsychopatzCore = {
    Translation = {
        GetKey = function(key, fallback) return fallback or key end,
        FormatKey = function(_, fallback) return fallback end,
    },
}
CustomTranslationManager = {
    getLanguage = function() return "TL" end,
}

local Model = dofile(CLIENT
    .. "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow_Model.lua")
local missing = { status = "missing_key", key = "UI_Missing" }
local translated = { status = "translated", key = "UI_Hello" }

assert(Model.MatchesFilter(missing, "needs"),
    "needs filter dropped a missing key")
assert(not Model.MatchesFilter(translated, "needs"),
    "needs filter included translated content")
assert(Model.MatchesFilter(translated, "all"),
    "all filter dropped translated content")
assert(Model.MatchesSearch({ modID = "Core", systemName = "UI",
    key = "UI_Hello", status = "translated" }, "hello"),
    "search did not match a key")
assert(Model.DisplayValue(nil) == "-", "nil display value changed")
assert(Model.CurrentLanguage(CustomTranslationManager) == "TL",
    "language provider was not used")
assert(Model.EmptySnapshot(CustomTranslationManager).language == "TL",
    "empty snapshot language changed")

print("psychopatz_translation_coverage_model_smoke: ok")
