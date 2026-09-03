require "ISUI/ISTextEntryBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"

local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

PsychopatzItemTypeLedgerWindow = PsychopatzWindow:derive(
    "PsychopatzItemTypeLedgerWindow"
)

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function drawLedgerRow(list, y, entry, alternate)
    local row = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    local status = row.gap and "GAP" or row.available and "AVAILABLE" or "MISSING"
    local statusColor = row.available and "success"
        or row.gap and "warning" or "danger"
    list:drawText(tostring(row.id or "-"), 10, y + 8,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.fullType or "<unassigned>",
        UIFont.Small, math.max(80, list:getWidth() - 190)),
        72, y + 8, text.r, text.g, text.b, text.a, UIFont.Small)
    UI.DrawBadge(list, status, list:getWidth() - 10, y + 5, statusColor)
    return y + list.itemheight
end

function PsychopatzItemTypeLedgerWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function PsychopatzItemTypeLedgerWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.search = ISTextEntryBox:new("", 0, 0, 100, 28)
    self.search:initialise()
    self.search:instantiate()
    if self.search.setClearButton then self.search:setClearButton(true) end
    self.search.onTextChange = function() self:rebuildLedger() end
    self:addChild(self.search)
    self.filterMode = "all"
    self.filterButton = UI.CreateButton(self, {
        id = "filter",
        title = "Show: All",
        target = self,
        onclick = PsychopatzItemTypeLedgerWindow.onFilter,
        variant = "quiet",
    })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = "Refresh",
        target = self,
        onclick = PsychopatzItemTypeLedgerWindow.onRefresh,
        variant = "quiet",
    })
    self.scanButton = UI.CreateButton(self, {
        id = "scan",
        title = "Refresh Script Availability",
        target = self,
        onclick = PsychopatzItemTypeLedgerWindow.onScan,
        variant = "primary",
    })
    self.ledgerList = UI.CreateList(self, {
        itemHeight = Layout.Pixels(30, self.uiScale),
        doDrawItem = drawLedgerRow,
    })
    self:requestResponsiveLayout(true)
    self:rebuildLedger()
end

function PsychopatzItemTypeLedgerWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 126, bottom = 12 })
    local gap = Layout.Pixels(6, self.uiScale)
    local controlHeight = Layout.Pixels(28, self.uiScale)
    local toolbarY = rect.y - Layout.Pixels(90, self.uiScale)
    local compact = Layout.IsCompact(rect.width,
        Layout.Pixels(820, self.uiScale))
    local searchWidth = compact and rect.width
        or math.max(Layout.Pixels(140, self.uiScale),
            math.floor(rect.width * 0.42))
    Layout.SetBounds(self.search, rect.x, toolbarY, searchWidth, controlHeight)
    local controls = { self.filterButton, self.refreshButton, self.scanButton }
    local controlsX = compact and rect.x or rect.x + searchWidth + gap
    local controlsY = compact and toolbarY + controlHeight + gap or toolbarY
    Layout.Flow(controls, {
        x = controlsX,
        y = controlsY,
        width = compact and rect.width
            or math.max(1, rect.width - searchWidth - gap),
    }, { scale = self.uiScale, gap = 5, minWidth = 76 })
    Layout.SetBounds(self.ledgerList, rect.x, rect.y, rect.width, rect.height)
end

function PsychopatzItemTypeLedgerWindow:onFilter(button)
    local nextMode = { all = "missing", missing = "available", available = "all" }
    self.filterMode = nextMode[self.filterMode] or "all"
    button:setTitle("Show: " .. string.upper(self.filterMode))
    self:rebuildLedger()
end

function PsychopatzItemTypeLedgerWindow:onRefresh()
    self:rebuildLedger()
end

function PsychopatzItemTypeLedgerWindow:onScan()
    Types.refreshScriptAvailability()
    self:rebuildLedger()
end

function PsychopatzItemTypeLedgerWindow:rebuildLedger()
    if not self.ledgerList then return end
    self.snapshot = Types.getDebugSnapshot()
    local search = lower(self.search and self.search:getText() or "")
    self.ledgerList:clear()
    for _, row in ipairs(self.snapshot.entries or {}) do
        local statusMatches = self.filterMode == "all"
            or self.filterMode == "missing" and not row.available
            or self.filterMode == "available" and row.available
        local searchMatches = search == ""
            or string.find(lower(row.fullType), search, 1, true)
            or string.find(tostring(row.id), search, 1, true)
        if statusMatches and searchMatches then
            self.ledgerList:addItem(row.fullType or "<unassigned>", row)
        end
    end
end

function PsychopatzItemTypeLedgerWindow:render()
    PsychopatzWindow.render(self)
    local rect = self:getContentRect({ top = 126, bottom = 12 })
    local snapshot = self.snapshot or Types.getDebugSnapshot()
    local summary = string.format(
        "REV %d  |  NEXT %d  |  LEDGER %d  |  CATALOG %d  |  MISSING %d  |  GAPS %d",
        snapshot.revision or 0, snapshot.nextId or 1,
        snapshot.registeredCount or 0, snapshot.catalogCount or 0,
        snapshot.unavailableCount or 0, snapshot.gapCount or 0)
    local suffix = rect.width >= Layout.Pixels(900, self.uiScale)
        and summary or string.format("LEDGER %d  |  MISSING %d  |  GAPS %d",
            snapshot.registeredCount or 0,
            snapshot.unavailableCount or 0, snapshot.gapCount or 0)
    UI.DrawSectionTitle(self, "APPEND-ONLY ITEM TYPE LEDGER",
        rect.x, rect.y - Layout.Pixels(22, self.uiScale), rect.width, suffix)
end

function PsychopatzItemTypeLedgerWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    PsychopatzItemTypeLedgerWindow.instance = nil
end

function PsychopatzItemTypeLedgerWindow.Open()
    if PsychopatzItemTypeLedgerWindow.instance then
        local window = PsychopatzItemTypeLedgerWindow.instance
        window:setVisible(true)
        window:bringToTop()
        window:rebuildLedger()
        return window
    end
    local window = UI.NewWindow(PsychopatzItemTypeLedgerWindow, {
        title = "PsychopatzCore Item Type Ledger",
        persistenceKey = "PsychopatzCore.ItemTypeLedger",
        resizable = true,
        responsiveSpec = {
            width = 920,
            height = 620,
            minWidth = 620,
            minHeight = 420,
            maxWidth = 1280,
            maxHeight = 860,
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    PsychopatzItemTypeLedgerWindow.instance = window
    return window
end

PsychopatzCore.DebugHub.RegisterTool({
    id = "psychopatz.inventory.itemTypeLedger",
    source = "PsychopatzCore",
    order = 80,
    title = "Item Type Ledger",
    description = "Inspect numeric item IDs, script availability, revision, missing types, and ledger gaps.",
    action = function() PsychopatzItemTypeLedgerWindow.Open() end,
})

return PsychopatzItemTypeLedgerWindow
