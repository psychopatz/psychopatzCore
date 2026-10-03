local Core = PsychopatzCore
local Debug = Core.Debug
local DebugHub = Core.DebugHub
local Translation = Core.Translation

local function tr(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

local DebugTraceWindow
local function openDebugTrace()
    if not DebugTraceWindow then
        local loaded, module = pcall(require,
            "PsychopatzCore/UI/PsychopatzDebugTraceWindow")
        if not loaded then
            if print then print("[PsychopatzCore.DebugTrace] " .. tostring(module)) end
            return nil
        end
        DebugTraceWindow = module
    end
    return DebugTraceWindow.Open()
end

-- Preview registration is intentionally cheap at startup. The UI window,
-- renderer, and ISUI drawer are loaded only when the tool is launched.
local Preview = require "PsychopatzCore/Preview/PC_Preview"
local PreviewHub
local function openPreviewHub()
    if not PreviewHub then
        local loaded, module = pcall(require,
            "PsychopatzCore/Preview/PC_PreviewHub")
        if not loaded then
            if print then
                print("[PsychopatzCore.Preview] " .. tostring(module))
            end
            return nil
        end
        PreviewHub = module
    end
    return PreviewHub.Open()
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.preview",
        source = "PsychopatzCore",
        order = 25,
        title = tr("UI_PsychopatzPreview_Title", "Preview Hub"),
        description = tr("UI_PsychopatzPreview_Description",
            "Inspect registered client-local perception previews."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
                and #Preview.ListProviders() > 0
        end,
        action = function()
            return openPreviewHub()
        end,
    })
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.worldMetadata",
        source = "PsychopatzCore",
        order = 30,
        title = tr("UI_PsychopatzWorldMetadata_Title",
            "Export World Place Metadata"),
        description = tr("UI_PsychopatzWorldMetadata_Description",
            "Export deduplicated zones, buildings, rooms, sizes, and structural features for downstream tagging."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
                and type(getWorld) == "function"
        end,
        action = function()
            local loaded, window = pcall(require,
                "PsychopatzCore/UI/PsychopatzWorldMetadataWindow")
            if not loaded then
                print("[PsychopatzCore.WorldMetadata] window failed: "
                    .. tostring(window))
                return nil
            end
            return window.Open()
        end,
    })
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.runtimeTrace",
        source = "PsychopatzCore",
        order = 5,
        title = tr("UI_PsychopatzDebug_RuntimeTrace_Title", "Runtime Debug Trace"),
        description = tr("UI_PsychopatzDebug_RuntimeTrace_Description",
            "Inspect opt-in structured runtime events from any mod."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
        end,
        action = function()
            return openDebugTrace()
        end,
    })
end

local DebugSettingsWindow
local function openDebugSettings()
    if not DebugSettingsWindow then
        local loaded, module = pcall(require,
            "PsychopatzCore/UI/PsychopatzDebugSettingsWindow")
        if not loaded then
            if print then print("[PsychopatzCore.DebugSettings] " .. tostring(module)) end
            return nil
        end
        DebugSettingsWindow = module
    end
    return DebugSettingsWindow.Open()
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.debugSettings",
        source = "PsychopatzCore",
        order = 10,
        title = tr("UI_PsychopatzDebug_Settings_Title", "Debug Settings"),
        description = tr("UI_PsychopatzDebug_Settings_Description",
            "Enable or disable persisted diagnostic instrumentation."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
        end,
        action = function()
            return openDebugSettings()
        end,
    })
end

local TranslationCoverageWindow
local function openTranslationCoverage()
    if not TranslationCoverageWindow then
        local loaded, module = pcall(require,
            "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow")
        if not loaded then
            if print then
                print("[PsychopatzCore.TranslationCoverage] "
                    .. tostring(module))
            end
            return nil
        end
        TranslationCoverageWindow = module
    end
    return TranslationCoverageWindow.Open()
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.translationCoverage",
        source = "PsychopatzCore",
        order = 20,
        title = tr("UI_PsychopatzDebugHub_TranslationCoverage_Title",
            "Translation Coverage"),
        description = tr(
            "UI_PsychopatzDebugHub_TranslationCoverage_Description",
            "Find missing, untranslated, and extra keys in registered catalogs."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
        end,
        action = function()
            return openTranslationCoverage()
        end,
    })
end

return Core
