require "PsychopatzCore/Settings/PsychopatzSettings"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/UI/PsychopatzSettingsWindow"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings or {}
Conversation.Settings = Settings

Settings.defaults = Settings.defaults or {
    crtEnabled = true,
    animationScale = 1.0,
    typingCharactersPerSecond = 38,
    typingMinimumMs = 320,
    typingMaximumMs = 1800,
    portraitBackgroundOpacity = 0.92,
    portraitContentOpacity = 1.0,
    historyBackgroundOpacity = 0.82,
    historyContentOpacity = 1.0,
    choicesBackgroundOpacity = 0.82,
    choicesContentOpacity = 1.0,
    showEditorButton = true,
    layout_portrait_x = 0.08,
    layout_portrait_y = 0.12,
    layout_portrait_w = 0.24,
    layout_portrait_h = 0.37,
    layout_relationship_x = 0.08,
    layout_relationship_y = 0.51,
    layout_relationship_w = 0.16,
    layout_relationship_h = 0.35,
    layout_history_x = 0.40,
    layout_history_y = 0.13,
    layout_history_w = 0.50,
    layout_history_h = 0.41,
    layout_choices_x = 0.26,
    layout_choices_y = 0.64,
    layout_choices_w = 0.43,
    layout_choices_h = 0.27,
    historySafetyLimit = 512,
    closeConversationOnDanger = true,
    maximumConversationDistance = 5.5,
    conversationDangerRadius = 8.0,
}

Settings.store = Settings.store or PsychopatzCore.Settings.Open("Conversation", {
    fileName = "PsychopatzCore_Conversation.txt",
    defaults = Settings.defaults,
})

function Settings.EnsureLoaded()
    if not Settings.store.loaded then Settings.store:Load() end
    return Settings.store
end

function Settings.Get(key, fallback)
    Settings.EnsureLoaded()
    local defaultValue = Settings.defaults[key]
    if defaultValue == nil then defaultValue = fallback end
    return Settings.store:Get(key, defaultValue)
end

function Settings.Set(key, value, save)
    Settings.EnsureLoaded()
    return Settings.store:Set(key, value, save ~= false)
end

local function tr(key)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value or key
end

local function slider(id, label, minimum, maximum, step)
    return {
        id = id,
        key = id,
        type = "slider",
        label = label,
        min = minimum,
        max = maximum,
        step = step,
        format = function(value)
            if maximum <= 2 then return string.format("%.2f", tonumber(value) or 0) end
            return tostring(math.floor((tonumber(value) or 0) + 0.5))
        end,
    }
end

if PsychopatzCore.InGameSettings and not Settings.registered then
    PsychopatzCore.InGameSettings.Register({
        id = "PsychopatzConversation",
        title = getText("UI_PsychopatzConversation_SettingsTitle"),
        store = Settings.store,
        controls = {
            { id = "crtEnabled", key = "crtEnabled", type = "boolean", label = getText("UI_PsychopatzConversation_SettingCRT") },
            slider("animationScale", tr("UI_PsychopatzConversation_SettingAnimation"), 0.25, 2.0, 0.05),
            slider("typingCharactersPerSecond", tr("UI_PsychopatzConversation_SettingTypingSpeed"), 10, 120, 1),
            slider("typingMinimumMs", tr("UI_PsychopatzConversation_SettingMinimumDelay"), 0, 1500, 50),
            slider("typingMaximumMs", tr("UI_PsychopatzConversation_SettingMaximumDelay"), 250, 5000, 50),
            { id = "closeConversationOnDanger", key = "closeConversationOnDanger", type = "boolean", label = getText("UI_PsychopatzConversation_SettingCloseOnDanger") },
            slider("maximumConversationDistance", tr("UI_PsychopatzConversation_SettingMaximumDistance"), 2, 12, 0.5),
            slider("conversationDangerRadius", tr("UI_PsychopatzConversation_SettingDangerRadius"), 2, 20, 0.5),
            slider("portraitBackgroundOpacity", tr("UI_PsychopatzConversation_SettingPortraitBackground"), 0, 1, 0.05),
            slider("portraitContentOpacity", tr("UI_PsychopatzConversation_SettingPortraitContent"), 0, 1, 0.05),
            slider("historyBackgroundOpacity", tr("UI_PsychopatzConversation_SettingHistoryBackground"), 0, 1, 0.05),
            slider("historyContentOpacity", tr("UI_PsychopatzConversation_SettingHistoryContent"), 0, 1, 0.05),
            slider("choicesBackgroundOpacity", tr("UI_PsychopatzConversation_SettingChoicesBackground"), 0, 1, 0.05),
            slider("choicesContentOpacity", tr("UI_PsychopatzConversation_SettingChoicesContent"), 0, 1, 0.05),
            { id = "showEditorButton", key = "showEditorButton", type = "boolean", label = getText("UI_PsychopatzConversation_SettingEditorButton") },
            {
                id = "editLayout",
                type = "action",
                label = getText("UI_PsychopatzConversation_SettingOpenEditor"),
                action = function()
                    if Conversation.OpenLayoutEditor then Conversation.OpenLayoutEditor() end
                end,
            },
            {
                id = "preview",
                type = "action",
                label = getText("UI_PsychopatzConversation_SettingPreview"),
                action = function()
                    if Conversation.OpenPreview then Conversation.OpenPreview() end
                end,
            },
            {
                id = "resetLayout",
                type = "action",
                label = getText("UI_PsychopatzConversation_SettingReset"),
                variant = "danger",
                action = function()
                    if Conversation.Layout and Conversation.Layout.ResetAll then
                        Conversation.Layout.ResetAll(true)
                    end
                end,
            },
        },
        window = {
            width = 660,
            height = 760,
            minWidth = 520,
            minHeight = 620,
            maxWidth = 820,
            maxHeight = 900,
        },
    })
    Settings.registered = true
end

function Settings.Open()
    return PsychopatzCore.InGameSettings
        and PsychopatzCore.InGameSettings.Open("PsychopatzConversation")
        or nil
end

function Settings.Toggle()
    return PsychopatzCore.InGameSettings
        and PsychopatzCore.InGameSettings.Toggle("PsychopatzConversation")
        or nil
end

if PsychopatzCore.DebugHub
    and not Settings.debugHubRegistered
then
    PsychopatzCore.DebugHub.RegisterTool({
        id = "psychopatz.conversationSettings",
        source = "PsychopatzCore",
        order = 120,
        title = tr(
            "UI_PsychopatzConversation_DebugToolTitle"
        ),
        description = tr(
            "UI_PsychopatzConversation_DebugToolDescription"
        ),
        available = function()
            return Settings.Toggle ~= nil
        end,
        action = function()
            Settings.Toggle()
        end,
    })
    Settings.debugHubRegistered = true
end

return Settings
