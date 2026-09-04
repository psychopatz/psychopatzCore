local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON_CLIENT = "Contents/mods/PsychopatzCore/common/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. COMMON_CLIENT .. "?.lua;" .. package.path

local function truthy(value, message)
    assert(value, message)
end

local function falsy(value, message)
    assert(not value, message)
end

local function equal(actual, expected, message)
    assert(actual == expected,
        string.format("%s (expected %s, got %s)", message, tostring(expected), tostring(actual)))
end

local store = {
    loaded = true,
    values = { playerSpeechTTS = false },
    Get = function(self, key, fallback)
        local value = self.values[key]
        return value == nil and fallback or value
    end,
    Set = function(self, key, value)
        self.values[key] = value
        return value
    end,
}
PsychopatzCore = {
    Settings = {
        Open = function() return store end,
    },
    InGameSettings = {
        Register = function(definition)
            PsychopatzCore.audioDefinition = definition
            return definition
        end,
        Open = function(id) return id end,
        Toggle = function(id) return id end,
    },
    DebugHub = {
        RegisterTool = function(definition)
            PsychopatzCore.audioTool = definition
            return true
        end,
    },
}

package.preload["PsychopatzCore/Settings/PsychopatzSettings"] = function()
    return PsychopatzCore.Settings
end
package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] = function()
    return PsychopatzCore.DebugHub
end
package.preload["PsychopatzCore/UI/PsychopatzSettingsWindow"] = function()
    return PsychopatzCore.InGameSettings
end

dofile(COMMON_CLIENT .. "PsychopatzCore/UI/PsychopatzAudioSettings.lua")
local Audio = PsychopatzCore.Audio
falsy(Audio.IsPlayerSpeechEnabled(), "player speech defaults to disabled")
truthy(PsychopatzCore.audioDefinition, "audio settings were registered")
equal(PsychopatzCore.audioDefinition.id, "PsychopatzAudio", "audio settings use the Core registry")
truthy(PsychopatzCore.audioTool, "audio settings were exposed to the debug hub")
equal(PsychopatzCore.audioTool.source, "Sounds", "audio tool is grouped under Sounds")
Audio.Set("playerSpeechTTS", true)
truthy(Audio.IsPlayerSpeechEnabled(), "player speech setting persists in the Core store")

print("psychopatz_audio_settings_smoke: ok")
