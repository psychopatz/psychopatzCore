require "PsychopatzCore/Settings/PsychopatzSettings"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/UI/PsychopatzSettingsWindow"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings or {}
Conversation.Settings = Settings
local CoreTranslation = PsychopatzCore.Translation

Settings.defaults = Settings.defaults or {
    crtEnabled = false,
    animationScale = 1.0,
    typingCharactersPerSecond = 38,
    typingMinimumMs = 320,
    typingMaximumMs = 1800,
    conversationOpacitySchema = 0,
    conversationOpacityBase = 0.82,
    portraitSurfaceOpacityLift = 0.10,
    portraitDetailOpacityLift = 0.18,
    historySurfaceOpacityLift = 0.00,
    historyDetailOpacityLift = 0.18,
    relationshipSurfaceOpacityLift = 0.00,
    relationshipDetailOpacityLift = 0.18,
    choicesSurfaceOpacityLift = 0.00,
    choicesDetailOpacityLift = 0.18,
    llmInputSurfaceOpacityLift = 0.00,
    llmInputDetailOpacityLift = 0.18,
    -- Legacy absolute values remain in the schema for one-time migration.
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

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function migrateOpacitySettings()
    local store = Settings.store
    local schema = tonumber(store:Get("conversationOpacitySchema", 0)) or 0
    if schema >= 2 then return end

    local base = tonumber(store:Get("conversationOpacityBase", 0.82)) or 0.82
    local migrations = {
        { "portraitBackgroundOpacity", "portraitSurfaceOpacityLift" },
        { "portraitContentOpacity", "portraitDetailOpacityLift" },
        { "historyBackgroundOpacity", "historySurfaceOpacityLift" },
        { "historyContentOpacity", "historyDetailOpacityLift" },
        { "choicesBackgroundOpacity", "choicesSurfaceOpacityLift" },
        { "choicesContentOpacity", "choicesDetailOpacityLift" },
    }
    for _, migration in ipairs(migrations) do
        local legacy = tonumber(store:Get(migration[1], nil))
        if legacy ~= nil then
            store:Set(migration[2], clamp(legacy - base, 0, 0.25), false)
        end
    end
    store:Set("conversationOpacitySchema", 2, false)
    store:Save()
end

function Settings.EnsureLoaded()
    if not Settings.store.loaded then Settings.store:Load() end
    if not Settings.opacityMigrationChecked then
        migrateOpacitySettings()
        Settings.opacityMigrationChecked = true
    end
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
            if maximum <= 2 then return string.format("%.2f", tonumber(value) or 0) end
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
            slider("portraitSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingPortraitSurfaceLift"), 0, 0.25, 0.01),
            slider("portraitDetailOpacityLift", tr("UI_PsychopatzConversation_SettingPortraitDetailLift"), 0, 0.25, 0.01),
            slider("historySurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingHistorySurfaceLift"), 0, 0.25, 0.01),
            slider("historyDetailOpacityLift", tr("UI_PsychopatzConversation_SettingHistoryDetailLift"), 0, 0.25, 0.01),
            slider("relationshipSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingRelationshipSurfaceLift"), 0, 0.25, 0.01),
            slider("relationshipDetailOpacityLift", tr("UI_PsychopatzConversation_SettingRelationshipDetailLift"), 0, 0.25, 0.01),
            slider("choicesSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingChoicesSurfaceLift"), 0, 0.25, 0.01),
            slider("choicesDetailOpacityLift", tr("UI_PsychopatzConversation_SettingChoicesDetailLift"), 0, 0.25, 0.01),
            slider("llmInputSurfaceOpacityLift", tr("UI_PsychopatzConversation_SettingLLMInputSurfaceLift"), 0, 0.25, 0.01),
            slider("llmInputDetailOpacityLift", tr("UI_PsychopatzConversation_SettingLLMInputDetailLift"), 0, 0.25, 0.01),
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
