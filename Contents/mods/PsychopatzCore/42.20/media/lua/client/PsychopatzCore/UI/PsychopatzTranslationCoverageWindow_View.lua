local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Manager = CustomTranslationManager
local Diagnostics = PsychopatzCore.TranslationDiagnostics
local Model = require
    "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow_Model"
local Window = PsychopatzTranslationCoverageWindow

local function selectedItem(list)
    if not list or not list.getItem then return nil end
    local row = list:getItem()
    local wrapper = row and row.item or nil
    if wrapper and wrapper.kind == "item" then return wrapper.item end
    return nil
end

local function drawCoverageItem(list, y, entry, alternate)
    local wrapper = entry.item or {}
    local row = wrapper.item or {}
    local height = entry.height or list.itemheight
    UI.DrawListSelection(list, y, height,
        list.selected == entry.index, alternate)
    local badgeWidth = UI.DrawBadge(list, Model.StatusLabel(row.status),
        list:getWidth() - 10, y + 5, Model.StatusColor(row.status))
    local available = math.max(80, list:getWidth() - badgeWidth - 30)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(Layout.Ellipsize(Model.DisplayValue(row.key), UIFont.Small,
        available), 10, y + 6,
        text.r, text.g, text.b, text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(Model.DisplayValue(row.currentValue), UIFont.Small,
        available), 10, y + 27,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + height
end

local function currentLanguage()
    return Model.CurrentLanguage(Manager)
end

function Window:createChildren()
    UI.Window.createChildren(self)
    self.search = ISTextEntryBox:new("", 0, 0, 100, 28)
    self.search:initialise()
    self.search:instantiate()
    if self.search.setClearButton then self.search:setClearButton(true) end
    self.search.onTextChange = function() self:rebuildCoverage(false) end
    self:addChild(self.search)

    self.filterMode = "needs"
    self.filterButton = UI.CreateButton(self, {
        id = "filter", title = Model.FilterButtonLabel(self.filterMode),
        target = self, onclick = Window.onFilter, variant = "quiet",
    })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = Model.Translate(
            "UI_PsychopatzDebug_TranslationCoverage_Refresh", "Refresh"),
        target = self, onclick = Window.onRefresh, variant = "primary",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = Model.Translate(
            "UI_PsychopatzDebug_TranslationCoverage_Close", "Close"),
        target = self, onclick = Window.close, variant = "quiet",
    })

    self.coverageList = UI.CreateCategorizedList(self, {
        itemHeight = 52,
        categoryHeight = 30,
        expandedByDefault = true,
        getCategoryPath = function(row) return { row.modID, row.systemName } end,
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

function Window:onResponsiveLayout()
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
        x = controlsX, y = controlsY,
        width = compact and rect.width
            or math.max(1, rect.width - searchWidth - gap),
    }, { scale = self.uiScale, gap = 5, minWidth = 110 })
    local listWidth = math.floor((rect.width - gap) * 0.56)
    Layout.SetBounds(self.coverageList, rect.x, rect.y,
        listWidth, rect.height)
    Layout.SetBounds(self.details, rect.x + listWidth + gap, rect.y,
        rect.width - listWidth - gap, rect.height)
    Layout.Flow({ self.closeButton }, {
        x = rect.x, y = rect.y + rect.height + gap, width = rect.width,
    }, { scale = self.uiScale, minWidth = 110 })
end

function Window:selectRow(previousID)
    local selected = nil
    for index, row in ipairs(self.coverageList.items or {}) do
        local wrapper = row.item
        if wrapper and wrapper.kind == "item" then
            if previousID and wrapper.item and wrapper.item.id == previousID then
                selected = index
                break
            end
            if not selected then selected = index end
        end
    end
    self.coverageList.selected = selected or 0
end

function Window:rebuildCoverage(force)
    if not self.coverageList then return end
    local previousID = self.selectedID
    local revision = Diagnostics
        and type(Diagnostics.GetCoverageRevision) == "function"
        and Diagnostics.GetCoverageRevision() or self.lastRevision
    local needsScan = force == true or not self.snapshot
    if not needsScan and self.snapshot then
        needsScan = revision ~= self.lastRevision
            or currentLanguage() ~= self.snapshot.language
    end
    if needsScan then
        local snapshot = Diagnostics
            and type(Diagnostics.GetCoverageSnapshot) == "function"
            and Diagnostics.GetCoverageSnapshot(currentLanguage())
            or Model.EmptySnapshot(Manager)
        self.snapshot = snapshot or Model.EmptySnapshot(Manager)
    end
    self.lastRevision = self.snapshot.revision or 0
    local search = Model.Lower(self.search and self.search:getText() or "")
    local filtered = {}
    for _, row in ipairs(self.snapshot.entries or {}) do
        if Model.MatchesFilter(row, self.filterMode)
            and Model.MatchesSearch(row, search)
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

function Window:onFilter()
    local current = 1
    for index, mode in ipairs(Model.FILTER_ORDER) do
        if mode == self.filterMode then current = index break end
    end
    current = current + 1
    if current > #Model.FILTER_ORDER then current = 1 end
    self.filterMode = Model.FILTER_ORDER[current]
    self.filterButton:setTitle(Model.FilterButtonLabel(self.filterMode))
    self:rebuildCoverage(false)
end

function Window:onRefresh()
    self:rebuildCoverage(true)
end

return Window
