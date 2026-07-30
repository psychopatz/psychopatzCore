local FILE =
    "Contents/mods/PsychopatzCore/common/media/lua/client/"
    .. "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local registeredSettings
local registeredTool
local toggledID
local store = {
    loaded = true,
    Get = function(_, _, fallback) return fallback end,
    Set = function(_, _, value) return value end,
}

PsychopatzCore = {
    Conversation = {},
    Settings = {
        Open = function() return store end,
    },
    InGameSettings = {
        Register = function(definition)
            registeredSettings = definition
            return definition
        end,
        Open = function(id) return id end,
        Toggle = function(id)
            toggledID = id
            return id
        end,
    },
    DebugHub = {
        RegisterTool = function(definition)
            registeredTool = definition
            return definition
        end,
    },
}

package.preload["PsychopatzCore/Settings/PsychopatzSettings"] =
    function() return PsychopatzCore.Settings end
package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] =
    function() return PsychopatzCore.DebugHub end
package.preload["PsychopatzCore/UI/PsychopatzSettingsWindow"] =
    function() return PsychopatzCore.InGameSettings end

getText = function(key)
    local values = {
        UI_PsychopatzConversation_SettingsTitle = "Conversation UI Settings",
        UI_PsychopatzConversation_DebugToolTitle = "Conversation UI Settings",
        UI_PsychopatzConversation_DebugToolDescription = "Description",
    }
    return values[key] or key
end

dofile(FILE)

assertEqual(registeredSettings.id, "PsychopatzConversation",
    "settings form registration")
assertEqual(registeredTool.id, "psychopatz.conversationSettings",
    "conversation debug-hub tool")
registeredTool.action()
assertEqual(toggledID, "PsychopatzConversation",
    "debug-hub tool opens conversation settings")

print("psychopatz_conversation_settings_location_smoke: ok")
