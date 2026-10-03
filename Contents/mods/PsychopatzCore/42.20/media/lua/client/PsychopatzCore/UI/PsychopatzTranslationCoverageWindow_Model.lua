local Translation = PsychopatzCore.Translation

local Model = {}

Model.NEEDS_TRANSLATION = {
    missing_key = true,
    missing_catalog = true,
    same_as_english = true,
    missing_english_catalog = true,
}

Model.FILTER_ORDER = {
    "needs",
    "all",
    "missing_key",
    "missing_catalog",
    "same_as_english",
    "extra_key",
    "translated",
    "english",
    "missing_english_catalog",
}

Model.FILTER_KEYS = {
    needs = "UI_PsychopatzDebug_TranslationCoverage_FilterNeeds",
    all = "UI_PsychopatzDebug_TranslationCoverage_FilterAll",
    missing_key = "UI_PsychopatzDebug_TranslationCoverage_FilterMissingKey",
    missing_catalog = "UI_PsychopatzDebug_TranslationCoverage_FilterMissingCatalog",
    same_as_english = "UI_PsychopatzDebug_TranslationCoverage_FilterSameEnglish",
    extra_key = "UI_PsychopatzDebug_TranslationCoverage_FilterExtraKey",
    translated = "UI_PsychopatzDebug_TranslationCoverage_FilterTranslated",
    english = "UI_PsychopatzDebug_TranslationCoverage_FilterEnglish",
    missing_english_catalog =
        "UI_PsychopatzDebug_TranslationCoverage_FilterEnglishCatalog",
}

Model.STATUS_KEYS = {
    translated = "UI_PsychopatzDebug_TranslationCoverage_StatusTranslated",
    missing_key = "UI_PsychopatzDebug_TranslationCoverage_StatusMissingKey",
    missing_catalog =
        "UI_PsychopatzDebug_TranslationCoverage_StatusMissingCatalog",
    same_as_english =
        "UI_PsychopatzDebug_TranslationCoverage_StatusSameEnglish",
    extra_key = "UI_PsychopatzDebug_TranslationCoverage_StatusExtraKey",
    english = "UI_PsychopatzDebug_TranslationCoverage_StatusEnglish",
    missing_english_catalog =
        "UI_PsychopatzDebug_TranslationCoverage_StatusMissingEnglishCatalog",
}

function Model.Translate(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

function Model.Format(key, fallback, args)
    local value = fallback
    if Translation and Translation.FormatKey then
        value = Translation.FormatKey(key, fallback, args) or fallback
    end
    args = args or {}
    local ok, formatted = pcall(string.format, value,
        args[1], args[2], args[3], args[4])
    return ok and formatted or value
end

function Model.Lower(value)
    return string.lower(tostring(value or ""))
end

function Model.DisplayValue(value)
    if value == nil or tostring(value) == "" then return "-" end
    return tostring(value)
end

function Model.StatusLabel(status)
    return Model.Translate(Model.STATUS_KEYS[status],
        string.upper(tostring(status or "unknown")))
end

function Model.FilterLabel(mode)
    return Model.Translate(Model.FILTER_KEYS[mode],
        string.upper(tostring(mode or "all")))
end

function Model.FilterButtonLabel(mode)
    return Model.Format("UI_PsychopatzDebug_TranslationCoverage_Filter",
        "Show: %s", { Model.FilterLabel(mode) })
end

function Model.StatusColor(status)
    if status == "missing_key"
        or status == "missing_catalog"
        or status == "missing_english_catalog"
    then
        return "danger"
    end
    if status == "same_as_english" then return "warning" end
    if status == "translated" or status == "english" then
        return "success"
    end
    return "accent"
end

function Model.MatchesSearch(row, search)
    if search == "" then return true end
    local values = {
        row.modID,
        row.systemName,
        row.key,
        row.englishValue,
        row.localizedValue,
        row.currentValue,
        row.status,
    }
    for _, value in ipairs(values) do
        if string.find(Model.Lower(value), search, 1, true) then
            return true
        end
    end
    return false
end

function Model.MatchesFilter(row, mode)
    if mode == "needs" then return Model.NEEDS_TRANSLATION[row.status] == true end
    if mode == "all" then return true end
    return row.status == mode
end

function Model.CurrentLanguage(manager)
    if manager and type(manager.getLanguage) == "function" then
        return manager.getLanguage()
    end
    return "EN"
end

function Model.EmptySnapshot(manager)
    return {
        language = Model.CurrentLanguage(manager),
        revision = 0,
        entries = {},
        systems = {},
        counts = { total = 0 },
        runtimeWarnings = {},
    }
end

return Model
