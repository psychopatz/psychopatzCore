require "PsychopatzCore/Settings/PsychopatzSettings"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/UI/PsychopatzSettingsWindow"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Audio = PsychopatzCore.Audio or {}

local Audio = PsychopatzCore.Audio
local Settings = PsychopatzCore.Settings

Audio.defaults = Audio.defaults or {
    playerSpeechTTS = false,
}

Audio.store = Audio.store or Settings.Open("Audio", {
    fileName = "PsychopatzCore_Audio.txt",
    defaults = Audio.defaults,
})

function Audio.EnsureSettingsLoaded()
    if not Audio.store.loaded then Audio.store:Load() end
    return Audio.store
end

function Audio.Get(key, fallback)
    Audio.EnsureSettingsLoaded()
    local defaultValue = Audio.defaults[key]
    if defaultValue == nil then defaultValue = fallback end
    return Audio.store:Get(key, defaultValue)
end

function Audio.Set(key, value, save)
    Audio.EnsureSettingsLoaded()
    return Audio.store:Set(key, value, save ~= false)
end

function Audio.IsPlayerSpeechEnabled()
    return Audio.Get("playerSpeechTTS", false) == true
end

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

if PsychopatzCore.InGameSettings and not Audio.settingsRegistered then
    PsychopatzCore.InGameSettings.Register({
        id = "PsychopatzAudio",
        title = tr("UI_PsychopatzCore_AudioSettingsTitle", "Sounds"),
        store = Audio.store,
        controls = {
            {
                id = "playerSpeechTTS",
                key = "playerSpeechTTS",
                type = "boolean",
                label = tr(
                    "UI_PsychopatzCore_SettingPlayerSpeechTTS",
                    "Speak player dialogue with TTS"
                ),
            },
        },
        window = {
            width = 560,
            height = 250,
            minWidth = 440,
            minHeight = 220,
            maxWidth = 760,
            maxHeight = 360,
        },
    })
    Audio.settingsRegistered = true
end

function Audio.OpenSettings()
    return PsychopatzCore.InGameSettings
        and PsychopatzCore.InGameSettings.Open("PsychopatzAudio")
        or nil
end

function Audio.ToggleSettings()
    return PsychopatzCore.InGameSettings
        and PsychopatzCore.InGameSettings.Toggle("PsychopatzAudio")
        or nil
end

if PsychopatzCore.DebugHub and not Audio.debugHubRegistered then
    PsychopatzCore.DebugHub.RegisterTool({
        id = "psychopatz.audioSettings",
        source = "Sounds",
        order = 10,
        title = tr("UI_PsychopatzCore_AudioSettingsTitle", "Sound settings"),
        description = tr(
            "UI_PsychopatzCore_AudioSettingsDescription",
            "Enable optional player dialogue TTS and inspect voice playback settings."
        ),
        available = function()
            return Audio.ToggleSettings ~= nil
        end,
        action = function()
            return Audio.ToggleSettings()
        end,
    })
    Audio.debugHubRegistered = true
end

return Audio
