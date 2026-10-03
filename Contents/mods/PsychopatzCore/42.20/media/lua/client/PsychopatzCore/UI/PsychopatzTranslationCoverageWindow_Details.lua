local Model = require
    "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow_Model"
local Window = PsychopatzTranslationCoverageWindow

function Window:refreshDetails(row)
    local entry = row
    if not entry and self.coverageList and self.coverageList.getItem then
        local selected = self.coverageList:getItem()
        local wrapper = selected and selected.item or nil
        entry = wrapper and wrapper.kind == "item" and wrapper.item or nil
    end
    if entry then self.selectedID = entry.id end
    local content
    if not entry then
        content = Model.Translate(
            "UI_PsychopatzDebug_TranslationCoverage_Empty",
            "No catalog entries match this filter.")
    else
        local lines = {
            Model.Format("UI_PsychopatzDebug_TranslationCoverage_DetailKey",
                "Key: %s", { Model.DisplayValue(entry.key) }),
            Model.Format("UI_PsychopatzDebug_TranslationCoverage_DetailSystem",
                "System: %s", { tostring(entry.modID) .. "/"
                    .. tostring(entry.systemName) }),
            Model.Format("UI_PsychopatzDebug_TranslationCoverage_DetailStatus",
                "Status: %s", { Model.StatusLabel(entry.status) }),
            "",
            Model.Format("UI_PsychopatzDebug_TranslationCoverage_DetailEnglish",
                "English: %s", { Model.DisplayValue(entry.englishValue) }),
            Model.Format("UI_PsychopatzDebug_TranslationCoverage_DetailCurrent",
                "Current (%s): %s", {
                    tostring(self.snapshot and self.snapshot.language or "EN"),
                    Model.DisplayValue(entry.currentValue),
                }),
            Model.Format("UI_PsychopatzDebug_TranslationCoverage_DetailEnglishPath",
                "English catalog: %s", { Model.DisplayValue(entry.englishPath) }),
            Model.Format("UI_PsychopatzDebug_TranslationCoverage_DetailLocalizedPath",
                "Active catalog: %s", { Model.DisplayValue(entry.localizedPath) }),
        }
        if entry.detail then
            lines[#lines + 1] = Model.Format(
                "UI_PsychopatzDebug_TranslationCoverage_DetailDiagnostic",
                "Diagnostic: %s", { tostring(entry.detail) })
        end
        local observed = {}
        for _, warning in ipairs(self.snapshot
            and self.snapshot.runtimeWarnings or {}) do
            if warning.modID == entry.modID
                and warning.systemName == entry.systemName
                and warning.key == entry.key
            then
                observed[#observed + 1] = tostring(warning.reason)
            end
        end
        if #observed > 0 then
            lines[#lines + 1] = Model.Format(
                "UI_PsychopatzDebug_TranslationCoverage_DetailRuntime",
                "Runtime observation: %s", { table.concat(observed, ", ") })
        end
        content = table.concat(lines, "\n")
    end
    self.details.text = content
    self.details:paginate()
end

return Window
