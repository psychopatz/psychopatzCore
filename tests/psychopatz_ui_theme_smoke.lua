local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/Core/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PsychopatzCore = { UI = {} }
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return true
end
local values = {}
local themeStore = {
    loaded = true,
    Get = function(_, key, fallback) return values[key] or fallback end,
    Set = function(_, key, value) values[key] = value return value end,
}
PsychopatzCore.Settings = {
    Open = function() return themeStore end,
}
package.preload["PsychopatzCore/Settings/PsychopatzSettings"] = function()
    return PsychopatzCore.Settings
end
local Theme = dofile(ROOT .. "PsychopatzUITheme.lua")

equal(Theme.GetPresetID(), "cyan", "default theme preset")
local revision = Theme.GetRevision()
equal(Theme.SetPreset("green"), "green", "theme preset selection")
equal(Theme.GetPresetID(), "green", "selected theme preset")
equal(Theme.GetRevision(), revision + 1, "theme revision increments")
equal(Theme.colors.accent.g, 0.82, "selected theme accent")
equal(values.themePreset, "green", "theme preset persisted")
equal(Theme.SetPreset("not-a-preset"), "cyan", "invalid theme falls back")
equal(Theme.GetPresetID(), "cyan", "fallback theme preset")
Theme.Reset()
equal(Theme.GetPresetID(), "cyan", "theme reset")

print("psychopatz_ui_theme_smoke: ok")
