local SETTINGS_ROOT =
    "Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/Settings/"
local CONVERSATION_ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local persistedText

getFileWriter = function()
    local chunks = {}
    return {
        write = function(_, value) chunks[#chunks + 1] = tostring(value) end,
        close = function() persistedText = table.concat(chunks) end,
    }
end

getFileReader = function()
    if not persistedText then return nil end
    local lines = {}
    for line in string.gmatch(persistedText, "([^\r\n]+)") do
        lines[#lines + 1] = line
    end
    local index = 0
    return {
        readLine = function()
            index = index + 1
            return lines[index]
        end,
        close = function() end,
    }
end

PsychopatzCore = { Conversation = {} }
Events = nil
getText = function(key) return key end

dofile(SETTINGS_ROOT .. "PsychopatzSettings.lua")
local Settings = PsychopatzCore.Settings

package.preload["PsychopatzCore/Settings/PsychopatzSettings"] =
    function() return Settings end
package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] =
    function() return true end
package.preload["PsychopatzCore/UI/PsychopatzSettingsWindow"] =
    function() return true end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] =
    function() return true end

dofile(CONVERSATION_ROOT .. "PsychopatzConversationSettings.lua")
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"] =
    function() return PsychopatzCore.Conversation.Settings end
dofile(CONVERSATION_ROOT .. "PsychopatzConversationLayout.lua")

local Conversation = PsychopatzCore.Conversation
local Layout = Conversation.Layout
local store = Conversation.Settings.store

assertEqual(store.defaults.layout_portrait_x, Layout.defaults.portrait.x,
    "layout defaults are part of the client store")

Layout.Save("portrait", {
    x = 150,
    y = 80,
    width = 300,
    height = 240,
}, 1000, 800, true)
assert(persistedText:find("layout_portrait_x=0.15", 1, true),
    "portrait position is written to the client file")

-- Reload the same store to model a fresh game session. The layout keys must
-- survive Store:Reset and be accepted by Store:Load, just like other settings.
store.loaded = false
store:Load()
local bounds = Layout.Resolve("portrait", 1000, 800)
assertEqual(bounds.x, 150, "portrait x survives reload")
assertEqual(bounds.y, 80, "portrait y survives reload")
assertEqual(bounds.width, 300, "portrait width survives reload")
assertEqual(bounds.height, 240, "portrait height survives reload")

print("psychopatz_conversation_layout_persistence_smoke: ok")
