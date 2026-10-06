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

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function migrateOpacitySettings()
    local store = Settings.store
    local schema = tonumber(store:Get("conversationOpacitySchema", 0)) or 0
    if schema >= 4 then return end

    local base = tonumber(store:Get("conversationOpacityBase", 0.82)) or 0.82
    if schema < 2 then
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
                store:Set(migration[2], clamp(legacy - base, -1, 1), false)
            end
        end
    end

    -- Schema 2 already stored both lifts relative to the global base. Schema
    -- 3 changed only the detail lift to be surface-relative.
    -- Schema 4 decouples content from the panel again. Convert schema 3's
    -- surface-relative detail lift back to a global-base-relative lift so
    -- the effective content opacity is preserved during the upgrade.
    if schema == 3 then
        local parts = { "portrait", "history", "relationship", "choices", "llmInput" }
        for _, partID in ipairs(parts) do
            local surface = tonumber(store:Get(
                partID .. "SurfaceOpacityLift", 0)) or 0
            local detail = tonumber(store:Get(
                partID .. "DetailOpacityLift", 0.18)) or 0.18
            store:Set(
                partID .. "DetailOpacityLift",
                clamp(surface + detail, -1, 1),
                false
            )
        end
    end
    store:Set("conversationOpacitySchema", 4, false)
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

require "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings_UI"

return Settings
