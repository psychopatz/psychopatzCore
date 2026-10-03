require "PsychopatzCore/Settings/PsychopatzSettings"

PsychopatzCore.UI = PsychopatzCore.UI or {}

local Theme = PsychopatzCore.UI.Theme or {}
PsychopatzCore.UI.Theme = Theme
local Translation = PsychopatzCore.Translation
local ThemeStore = PsychopatzCore.Settings.Open("UI", {
    fileName = "PsychopatzCore_UI.txt",
    defaults = { themePreset = "cyan" },
})
local Palette = require
    "PsychopatzCore/UI/Core/PsychopatzUITheme_Palette"
local State = require
    "PsychopatzCore/UI/Core/PsychopatzUITheme_State"
local Typography = require
    "PsychopatzCore/UI/Core/PsychopatzUITheme_Typography"

local palette = Palette.Create()
Theme.DefaultPreset = palette.defaultPreset
Theme.presets = palette.presets
Theme.colors = palette.colors
Theme.metrics = palette.metrics
Theme.revision = Theme.revision or 0

State.Install(Theme, ThemeStore, Translation)
Typography.Install(Theme)

State.EnsureLoaded(ThemeStore)
State.ApplyPreset(Theme, Theme.GetPresetID(), false)

return Theme
