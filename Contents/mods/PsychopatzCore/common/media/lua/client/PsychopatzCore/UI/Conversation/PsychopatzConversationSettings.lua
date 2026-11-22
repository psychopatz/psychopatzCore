require "PsychopatzCore/Settings/PsychopatzSettings"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings or {}
Conversation.Settings = Settings

Settings.defaults = Settings.defaults or {
    crtEnabled = false,
    animationScale = 1.0,
    typingCharactersPerSecond = 38,
    typingMinimumMs = 320,
    typingMaximumMs = 1800,
    conversationOpacitySchema = 4,
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
    showEditorButton = true,
    showRuntimeDebug = false,
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

require "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings_UI"

return Settings
