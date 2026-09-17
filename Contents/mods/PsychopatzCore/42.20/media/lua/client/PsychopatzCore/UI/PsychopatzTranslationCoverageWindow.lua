require "ISUI/ISTextEntryBox"
require "ISUI/ISRichTextPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/Translation/PsychopatzCoreTranslationDiagnostics"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Debug = PsychopatzCore.Debug
local Manager = CustomTranslationManager
local Diagnostics = PsychopatzCore.TranslationDiagnostics
local Translation = PsychopatzCore.Translation

PsychopatzTranslationCoverageWindow = UI.Window:derive(
    "PsychopatzTranslationCoverageWindow"
)
PsychopatzTranslationCoverageWindow.instance = nil

local NEEDS_TRANSLATION = {
    missing_key = true,
    missing_catalog = true,
    same_as_english = true,
    missing_english_catalog = true,
}

local FILTER_ORDER = {
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

local FILTER_KEYS = {
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

local STATUS_KEYS = {
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

local function tr(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

local function fmt(key, fallback, args)
    local value = fallback
    if Translation and Translation.FormatKey then
        value = Translation.FormatKey(key, fallback, args) or fallback
    end
    args = args or {}
    local ok, formatted = pcall(string.format, value,
        args[1], args[2], args[3], args[4])
    return ok and formatted or value
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function displayValue(value)
    if value == nil or tostring(value) == "" then return "-" end
    return tostring(value)
end

local function statusLabel(status)
    local key = STATUS_KEYS[status]
    return tr(key, string.upper(tostring(status or "unknown")))
end

local function filterLabel(mode)
    return tr(FILTER_KEYS[mode], string.upper(tostring(mode or "all")))
end

local function filterButtonLabel(mode)
    return fmt("UI_PsychopatzDebug_TranslationCoverage_Filter",
        "Show: %s", { filterLabel(mode) })
end

local function statusColor(status)
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

local function selectedItem(list)
    if not list or not list.getItem then return nil end
    local row = list:getItem()
    local wrapper = row and row.item or nil
    if wrapper and wrapper.kind == "item" then
        return wrapper.item
    end
    return nil
end

local function drawCoverageItem(list, y, entry, alternate)
    local wrapper = entry.item or {}
    local row = wrapper.item or {}
    local height = entry.height or list.itemheight
    UI.DrawListSelection(list, y, height,
        list.selected == entry.index, alternate)

    local badgeWidth = UI.DrawBadge(list, statusLabel(row.status),
        list:getWidth() - 10, y + 5, statusColor(row.status))
    local available = math.max(80, list:getWidth() - badgeWidth - 30)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(Layout.Ellipsize(displayValue(row.key), UIFont.Small,
        available), 10, y + 6,
        text.r, text.g, text.b, text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(displayValue(row.currentValue), UIFont.Small,
        available), 10, y + 27,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + height
end

local function coverageMatchesSearch(row, search)
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
        if string.find(lower(value), search, 1, true) then return true end
    end
    return false
end

local function coverageMatchesFilter(row, mode)
    if mode == "needs" then return NEEDS_TRANSLATION[row.status] == true end
    if mode == "all" then return true end
    return row.status == mode
end

local function currentLanguage()
    if Manager and type(Manager.getLanguage) == "function" then
        return Manager.getLanguage()
    end
    return "EN"
end

local function emptySnapshot()
    return {
        language = currentLanguage(),
        revision = 0,
        entries = {},
        systems = {},
        counts = { total = 0 },
        runtimeWarnings = {},
    }
end

function PsychopatzTranslationCoverageWindow:initialise()
    UI.Window.initialise(self)
end

function PsychopatzTranslationCoverageWindow:createChildren()
    UI.Window.createChildren(self)

    self.search = ISTextEntryBox:new("", 0, 0, 100, 28)
    self.search:initialise()
    self.search:instantiate()
    if self.search.setClearButton then self.search:setClearButton(true) end
    self.search.onTextChange = function()
        self:rebuildCoverage(false)
    end
    self:addChild(self.search)

    self.filterMode = "needs"
    self.filterButton = UI.CreateButton(self, {
        id = "filter",
        title = filterButtonLabel(self.filterMode),
        target = self,
        onclick = PsychopatzTranslationCoverageWindow.onFilter,
        variant = "quiet",
    })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = tr("UI_PsychopatzDebug_TranslationCoverage_Refresh", "Refresh"),
        target = self,
        onclick = PsychopatzTranslationCoverageWindow.onRefresh,
        variant = "primary",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PsychopatzDebug_TranslationCoverage_Close", "Close"),
        target = self,
        onclick = PsychopatzTranslationCoverageWindow.close,
        variant = "quiet",
    })

    self.coverageList = UI.CreateCategorizedList(self, {
        itemHeight = 52,
        categoryHeight = 30,
        expandedByDefault = true,
        getCategoryPath = function(row)
            return { row.modID, row.systemName }
        end,
        getItemKey = function(row) return row.id end,
        getItemText = function(row) return row.key end,
        formatCategoryCount = function(count) return tostring(count) end,
        drawItem = drawCoverageItem,
        onItemSelected = function(_, row)
            self.selectedID = row and row.id or nil
            self:refreshDetails(row)
        end,
    })

    self.details = ISRichTextPanel:new(0, 0, 1, 1)
    self.details:initialise()
    self.details.backgroundColor = Theme.Color("surface")
    self.details.borderColor = Theme.Color("border")
    self.details.autosetheight = false
    self.details.clip = true
    self.details.marginLeft = Layout.Pixels(10, self.uiScale)
    self.details.marginTop = Layout.Pixels(10, self.uiScale)
    self.details.marginBottom = Layout.Pixels(10, self.uiScale)
    self.details:addScrollBars()
    self:addChild(self.details)

    self.snapshot = nil
    self.selectedID = nil
    self.lastRevision = -1
    self:requestResponsiveLayout(true)
    self:rebuildCoverage(true)
end

function PsychopatzTranslationCoverageWindow:onResponsiveLayout()
    if not self.coverageList then return end
    local rect = self:getContentRect({ top = 126, bottom = 44 })
    local gap = Layout.Pixels(8, self.uiScale)
    local controlHeight = Layout.Pixels(28, self.uiScale)
    local toolbarY = rect.y - Layout.Pixels(90, self.uiScale)
    local compact = Layout.IsCompact(rect.width,
        Layout.Pixels(840, self.uiScale))
    local searchWidth = compact and rect.width
        or math.max(Layout.Pixels(180, self.uiScale),
            math.floor(rect.width * 0.38))
    Layout.SetBounds(self.search, rect.x, toolbarY,
        searchWidth, controlHeight)

    local toolbarControls = { self.filterButton, self.refreshButton }
    local controlsX = compact and rect.x or rect.x + searchWidth + gap
    local controlsY = compact and toolbarY + controlHeight + gap or toolbarY
    Layout.Flow(toolbarControls, {
        x = controlsX,
        y = controlsY,
        width = compact and rect.width
            or math.max(1, rect.width - searchWidth - gap),
    }, { scale = self.uiScale, gap = 5, minWidth = 110 })

    local listWidth = math.floor((rect.width - gap) * 0.56)
    Layout.SetBounds(self.coverageList, rect.x, rect.y,
        listWidth, rect.height)
    Layout.SetBounds(self.details, rect.x + listWidth + gap, rect.y,
        rect.width - listWidth - gap, rect.height)
    Layout.Flow({ self.closeButton }, {
        x = rect.x,
        y = rect.y + rect.height + gap,
        width = rect.width,
    }, { scale = self.uiScale, minWidth = 110 })
end

function PsychopatzTranslationCoverageWindow:selectRow(previousID)
    local selected = nil
    for index, row in ipairs(self.coverageList.items or {}) do
        local wrapper = row.item
        if wrapper and wrapper.kind == "item" then
            if previousID and wrapper.item
                and wrapper.item.id == previousID
            then
                selected = index
                break
            end
            if not selected then selected = index end
        end
    end
    self.coverageList.selected = selected or 0
end

function PsychopatzTranslationCoverageWindow:refreshDetails(row)
    local entry = row or selectedItem(self.coverageList)
    if entry then self.selectedID = entry.id end

    local content
    if not entry then
        content = tr("UI_PsychopatzDebug_TranslationCoverage_Empty",
            "No catalog entries match this filter.")
    else
        local lines = {
            fmt("UI_PsychopatzDebug_TranslationCoverage_DetailKey",
                "Key: %s", { displayValue(entry.key) }),
            fmt("UI_PsychopatzDebug_TranslationCoverage_DetailSystem",
                "System: %s", { tostring(entry.modID) .. "/"
                    .. tostring(entry.systemName) }),
            fmt("UI_PsychopatzDebug_TranslationCoverage_DetailStatus",
                "Status: %s", { statusLabel(entry.status) }),
            "",
            fmt("UI_PsychopatzDebug_TranslationCoverage_DetailEnglish",
                "English: %s", { displayValue(entry.englishValue) }),
            fmt("UI_PsychopatzDebug_TranslationCoverage_DetailCurrent",
                "Current (%s): %s", {
                    tostring(self.snapshot and self.snapshot.language or "EN"),
                    displayValue(entry.currentValue),
                }),
            fmt("UI_PsychopatzDebug_TranslationCoverage_DetailEnglishPath",
                "English catalog: %s", { displayValue(entry.englishPath) }),
            fmt("UI_PsychopatzDebug_TranslationCoverage_DetailLocalizedPath",
                "Active catalog: %s", { displayValue(entry.localizedPath) }),
        }
        if entry.detail then
            lines[#lines + 1] = fmt(
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
            lines[#lines + 1] = fmt(
                "UI_PsychopatzDebug_TranslationCoverage_DetailRuntime",
                "Runtime observation: %s", { table.concat(observed, ", ") })
        end
        content = table.concat(lines, "\n")
    end
    self.details.text = content
    self.details:paginate()
end

function PsychopatzTranslationCoverageWindow:rebuildCoverage(force)
    if not self.coverageList then return end
    local previousID = self.selectedID
    local revision = Diagnostics
        and type(Diagnostics.GetCoverageRevision) == "function"
        and Diagnostics.GetCoverageRevision()
        or self.lastRevision
    local needsScan = force == true or not self.snapshot
    if not needsScan and self.snapshot then
        needsScan = revision ~= self.lastRevision
            or currentLanguage() ~= self.snapshot.language
    end
    if needsScan then
        local snapshot = Diagnostics
            and type(Diagnostics.GetCoverageSnapshot) == "function"
            and Diagnostics.GetCoverageSnapshot(currentLanguage())
            or emptySnapshot()
        self.snapshot = snapshot or emptySnapshot()
    end
    self.lastRevision = self.snapshot.revision or 0

    local search = lower(self.search and self.search:getText() or "")
    local filtered = {}
    for _, row in ipairs(self.snapshot.entries or {}) do
        if coverageMatchesFilter(row, self.filterMode)
            and coverageMatchesSearch(row, search)
        then
            filtered[#filtered + 1] = row
        end
    end
    self.filteredCount = #filtered
    self.coverageList:setItems(filtered)
    self:selectRow(previousID)
    local selected = selectedItem(self.coverageList)
    self.selectedID = selected and selected.id or nil
    self:refreshDetails(selected)
end

function PsychopatzTranslationCoverageWindow:onFilter()
    local current = 1
    for index, mode in ipairs(FILTER_ORDER) do
        if mode == self.filterMode then current = index break end
    end
    current = current + 1
    if current > #FILTER_ORDER then current = 1 end
    self.filterMode = FILTER_ORDER[current]
    self.filterButton:setTitle(filterButtonLabel(self.filterMode))
    self:rebuildCoverage(false)
end

function PsychopatzTranslationCoverageWindow:onRefresh()
    self:rebuildCoverage(true)
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
    local summary = fmt("UI_PsychopatzDebug_TranslationCoverage_Summary",
        "%d missing | %d review | %d translated | %d extra",
        { missing, review, translated, extra })
    local languageLabel = fmt(
        "UI_PsychopatzDebug_TranslationCoverage_Language",
        "Language: %s", {
            tostring(self.snapshot and self.snapshot.language or "EN"),
        })
    summary = languageLabel .. "  |  " .. summary
    if self.snapshot and self.snapshot.truncated then
        summary = summary .. "  " .. fmt(
            "UI_PsychopatzDebug_TranslationCoverage_Truncated",
            "Showing %d of %d entries.", {
                self.snapshot.entryCount or 0,
                counts.total or 0,
            })
    end
    UI.DrawSectionTitle(self,
        tr("UI_PsychopatzDebug_TranslationCoverage_Section",
            "TRANSLATION COVERAGE"),
        rect.x, rect.y - Layout.Pixels(22, self.uiScale), rect.width,
        summary)
end

function PsychopatzTranslationCoverageWindow:prerender()
    if self.snapshot and Diagnostics then
        local revision = type(Diagnostics.GetCoverageRevision) == "function"
            and Diagnostics.GetCoverageRevision() or self.lastRevision
        if revision ~= self.lastRevision
            or currentLanguage() ~= self.snapshot.language
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
        title = tr("UI_PsychopatzDebug_TranslationCoverage_Title",
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
