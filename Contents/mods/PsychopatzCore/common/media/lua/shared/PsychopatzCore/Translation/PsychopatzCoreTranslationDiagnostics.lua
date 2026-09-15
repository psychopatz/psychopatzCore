-- Optional translation fallback diagnostics exposed through Core Debug Settings.

require "PsychopatzCore/Translation/PsychopatzCustomTranslationManager"
require "PsychopatzCore/Debug/PsychopatzDebugSettings"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Manager = CustomTranslationManager
local Translation = Core.Translation
local Settings = Core.DebugSettings
local Diagnostics = Core.TranslationDiagnostics or {}
Core.TranslationDiagnostics = Diagnostics

Diagnostics.SETTING_ID = "PsychopatzCore.TranslationAudit"

local function tr(key, fallback)
    if Translation and type(Translation.GetKey) == "function" then
        return Translation.GetKey(key, fallback)
    end
    return fallback
end

if Settings and type(Settings.Register) == "function" then
    Settings.Register({
        id = Diagnostics.SETTING_ID,
        source = "PsychopatzCore",
        order = 160,
        title = tr("UI_PsychopatzDebugSettings_TranslationAudit_Title",
            "Translation fallback audit"),
        description = tr(
            "UI_PsychopatzDebugSettings_TranslationAudit_Description",
            "Warns when the active language uses an English or key fallback."),
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Manager.SetTranslationAuditEnabled(enabled)
            return true
        end,
    })
end

function Diagnostics.IsEnabled()
    return Manager.IsTranslationAuditEnabled()
end

function Diagnostics.GetSnapshot()
    return Manager.GetTranslationAuditSnapshot()
end

return Diagnostics
