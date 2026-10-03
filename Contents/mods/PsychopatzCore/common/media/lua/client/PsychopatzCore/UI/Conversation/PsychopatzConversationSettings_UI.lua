require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/UI/PsychopatzSettingsWindow"

local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings
local CoreTranslation = PsychopatzCore.Translation

local function tr(key, fallback)
    if CoreTranslation and CoreTranslation.GetKey then
        return CoreTranslation.GetKey(key, fallback)
    end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value or fallback or key
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
            if maximum <= 2 then
                return string.format("%.2f", tonumber(value) or 0)
            end
            return tostring(math.floor((tonumber(value) or 0) + 0.5))
        end,
    }
end

if PsychopatzCore.InGameSettings and not Settings.registered then
    PsychopatzCore.InGameSettings.Register({
        id = "PsychopatzConversation",
        title = tr("UI_PsychopatzConversation_SettingsTitle"),
        store = Settings.store,
        controls = {
            { id = "crtEnabled", key = "crtEnabled", type = "boolean", label = tr("UI_PsychopatzConversation_SettingCRT") },
            slider("animationScale", tr("UI_PsychopatzConversation_SettingAnimation"), 0.25, 2.0, 0.05),
            slider("typingCharactersPerSecond", tr("UI_PsychopatzConversation_SettingTypingSpeed"), 10, 120, 1),
            slider("typingMinimumMs", tr("UI_PsychopatzConversation_SettingMinimumDelay"), 0, 1500, 50),
            slider("typingMaximumMs", tr("UI_PsychopatzConversation_SettingMaximumDelay"), 250, 5000, 50),
            { id = "closeConversationOnDanger", key = "closeConversationOnDanger", type = "boolean", label = tr("UI_PsychopatzConversation_SettingCloseOnDanger") },
            slider("maximumConversationDistance", tr("UI_PsychopatzConversation_SettingMaximumDistance"), 2, 12, 0.5),
            slider("conversationDangerRadius", tr("UI_PsychopatzConversation_SettingDangerRadius"), 2, 20, 0.5),
            slider("conversationOpacityBase", tr("UI_PsychopatzConversation_SettingOpacityBase"), 0, 1, 0.05),
            slider("portraitSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingPortraitSurfaceLift"), -1, 1, 0.01),
            slider("portraitDetailOpacityLift", tr("UI_PsychopatzConversation_SettingPortraitDetailLift"), -1, 1, 0.01),
            slider("historySurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingHistorySurfaceLift"), -1, 1, 0.01),
            slider("historyDetailOpacityLift", tr("UI_PsychopatzConversation_SettingHistoryDetailLift"), -1, 1, 0.01),
            slider("relationshipSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingRelationshipSurfaceLift"), -1, 1, 0.01),
            slider("relationshipDetailOpacityLift", tr("UI_PsychopatzConversation_SettingRelationshipDetailLift"), -1, 1, 0.01),
            slider("choicesSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingChoicesSurfaceLift"), -1, 1, 0.01),
            slider("choicesDetailOpacityLift", tr("UI_PsychopatzConversation_SettingChoicesDetailLift"), -1, 1, 0.01),
            slider("llmInputSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingLLMInputSurfaceLift"), -1, 1, 0.01),
            slider("llmInputDetailOpacityLift", tr("UI_PsychopatzConversation_SettingLLMInputDetailLift"), -1, 1, 0.01),
            { id = "showEditorButton", key = "showEditorButton", type = "boolean", label = tr("UI_PsychopatzConversation_SettingEditorButton") },
            {
                id = "editLayout",
                type = "action",
                label = tr("UI_PsychopatzConversation_SettingOpenEditor"),
                action = function()
                    if Conversation.OpenLayoutEditor then Conversation.OpenLayoutEditor() end
                end,
            },
            {
                id = "preview",
                type = "action",
                label = tr("UI_PsychopatzConversation_SettingPreview"),
                action = function()
                    if Conversation.OpenPreview then Conversation.OpenPreview() end
                end,
            },
            {
                id = "resetLayout",
                type = "action",
                label = tr("UI_PsychopatzConversation_SettingReset"),
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
        title = tr("UI_PsychopatzConversation_DebugToolTitle"),
        description = tr("UI_PsychopatzConversation_DebugToolDescription"),
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
