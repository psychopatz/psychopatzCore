require "ISUI/ISTextEntryBox"
require "ISUI/ISRichTextPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/Translation/PsychopatzCoreTranslationDiagnostics"

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Debug = PsychopatzCore.Debug
local Diagnostics = PsychopatzCore.TranslationDiagnostics
local Manager = CustomTranslationManager
local Model = require
    "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow_Model"

PsychopatzTranslationCoverageWindow = UI.Window:derive(
    "PsychopatzTranslationCoverageWindow"
)
PsychopatzTranslationCoverageWindow.instance = nil

require "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow_View"
require "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow_Details"

function PsychopatzTranslationCoverageWindow:initialise()
    UI.Window.initialise(self)
end

function PsychopatzTranslationCoverageWindow:render()
    UI.Window.render(self)
    local rect = self:getContentRect({ top = 126, bottom = 44 })
    local counts = self.snapshot and self.snapshot.counts or {}
    local missing = (counts.missing_key or 0)
        + (counts.missing_catalog or 0)
        + (counts.missing_english_catalog or 0)
    local review = counts.same_as_english or 0
    local translated = counts.translated or 0
    local extra = counts.extra_key or 0
    local summary = Model.Format(
        "UI_PsychopatzDebug_TranslationCoverage_Summary",
        "%d missing | %d review | %d translated | %d extra",
        { missing, review, translated, extra })
    local languageLabel = Model.Format(
        "UI_PsychopatzDebug_TranslationCoverage_Language",
        "Language: %s", {
            tostring(self.snapshot and self.snapshot.language or "EN"),
        })
    summary = languageLabel .. "  |  " .. summary
    if self.snapshot and self.snapshot.truncated then
        summary = summary .. "  " .. Model.Format(
            "UI_PsychopatzDebug_TranslationCoverage_Truncated",
            "Showing %d of %d entries.", {
                self.snapshot.entryCount or 0,
                counts.total or 0,
            })
    end
    UI.DrawSectionTitle(self,
        Model.Translate("UI_PsychopatzDebug_TranslationCoverage_Section",
            "TRANSLATION COVERAGE"),
        rect.x, rect.y - Layout.Pixels(22, self.uiScale), rect.width,
        summary)
end

function PsychopatzTranslationCoverageWindow:prerender()
    if self.snapshot and Diagnostics then
        local revision = type(Diagnostics.GetCoverageRevision) == "function"
            and Diagnostics.GetCoverageRevision() or self.lastRevision
        if revision ~= self.lastRevision
            or Model.CurrentLanguage(Manager) ~= self.snapshot.language
        then
            self:rebuildCoverage(true)
        end
    end
    UI.Window.prerender(self)
end

function PsychopatzTranslationCoverageWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if PsychopatzTranslationCoverageWindow.instance == self then
        PsychopatzTranslationCoverageWindow.instance = nil
    end
end

function PsychopatzTranslationCoverageWindow.Open()
    local player = getPlayer and getPlayer() or nil
    if not Debug or type(Debug.CanUse) ~= "function"
        or not Debug.CanUse(player)
    then
        return nil
    end

    local window = PsychopatzTranslationCoverageWindow.instance
    if window then
        window:setVisible(true)
        window:bringToTop()
        window:rebuildCoverage(true)
        return window
    end

    window = UI.NewWindow(PsychopatzTranslationCoverageWindow, {
        title = Model.Translate("UI_PsychopatzDebug_TranslationCoverage_Title",
            "Translation Coverage"),
        persistenceKey = "PsychopatzCore.TranslationCoverage",
        resizable = true,
        responsiveSpec = {
            width = 1120,
            height = 680,
            minWidth = 720,
            minHeight = 460,
            maxWidth = 1500,
            maxHeight = 960,
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:bringToTop()
    PsychopatzTranslationCoverageWindow.instance = window
    return window
end

function PsychopatzTranslationCoverageWindow.Toggle()
    if PsychopatzTranslationCoverageWindow.instance then
        PsychopatzTranslationCoverageWindow.instance:close()
        return nil
    end
    return PsychopatzTranslationCoverageWindow.Open()
end

return PsychopatzTranslationCoverageWindow
