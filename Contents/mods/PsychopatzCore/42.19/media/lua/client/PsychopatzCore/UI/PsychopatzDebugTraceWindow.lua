require "ISUI/ISRichTextPanel"
require "PsychopatzCore/UI/PsychopatzUI"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Trace = PsychopatzCore.DebugTrace

PsychopatzDebugTraceWindow = UI.Window:derive("PsychopatzDebugTraceWindow")
PsychopatzDebugTraceWindow.instance = nil

local function textValue(value)
    if value == nil then return "null" end
    if type(value) == "string" then
        return string.format("%q", value)
    end
    if type(value) == "boolean" then return value and "true" or "false" end
    return tostring(value)
end

local function sortedKeys(value)
    local keys = {}
    for key in pairs(value or {}) do
        keys[#keys + 1] = { key = key, label = tostring(key) }
    end
    table.sort(keys, function(left, right)
        return left.label < right.label
    end)
    return keys
end

local function formatValue(value, indent, depth)
    local valueType = type(value)
    if valueType ~= "table" then return textValue(value) end
    if depth >= 5 then return "{ [depth-limit] }" end

    local keys = sortedKeys(value)
    if #keys == 0 then return "{}" end
    local lines = { "{" }
    local padding = string.rep("  ", indent + 1)
    for _, key in ipairs(keys) do
        lines[#lines + 1] = padding .. textValue(key.label) .. " = "
            .. formatValue(value[key.key], indent + 1, depth + 1) .. ","
    end
    lines[#lines + 1] = string.rep("  ", indent) .. "}"
    return table.concat(lines, "\n")
end

local function entryLabel(entry)
    local source = tostring(entry.source or "unknown")
    local event = tostring(entry.event or "event")
    local requestID = tostring(entry.requestID or "")
    if requestID ~= "" then
        requestID = " | " .. string.sub(requestID, 1, 34)
    end
    return string.format("%s · %s%s", source, event, requestID)
end

local function drawEntry(list, y, row, alternate)
    local entry = row.item
    local selected = list.selected == row.index
    UI.DrawListSelection(list, y, list.itemheight, selected, alternate)
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(Layout.Ellipsize(entryLabel(entry), UIFont.Small,
        list:getWidth() - 16), 8, y + 6,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText("#" .. tostring(entry.id or "?") .. "  "
        .. tostring(entry.timestamp or ""), 8, y + 26,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

function PsychopatzDebugTraceWindow:initialise()
    UI.Window.initialise(self)
end

function PsychopatzDebugTraceWindow:createChildren()
    UI.Window.createChildren(self)
    self.eventList = UI.CreateList(self, {
        itemHeight = Layout.Pixels(46, self.uiScale),
        doDrawItem = drawEntry,
    })
    self.eventList.onMouseDown = function(list, x, y)
        local result = ISScrollingListBox.onMouseDown(list, x, y)
        self:refreshDetails()
        return result
    end

    self.details = ISRichTextPanel:new(0, 0, 1, 1)
    self.details:initialise()
    self.details.backgroundColor = Theme.Color("surface")
    self.details.borderColor = Theme.Color("border")
    self.details.autosetheight = false
    self.details.clip = true
    self.details.marginLeft = Layout.Pixels(8, self.uiScale)
    self.details.marginTop = Layout.Pixels(8, self.uiScale)
    self.details.marginBottom = Layout.Pixels(8, self.uiScale)
    self.details:addScrollBars()
    self:addChild(self.details)

    self.captureButton = UI.CreateButton(self, {
        id = "capture", title = "Capture: OFF", target = self,
        onclick = PsychopatzDebugTraceWindow.onCapture,
        variant = "quiet",
    })
    self.clearButton = UI.CreateButton(self, {
        id = "clear", title = "Clear", target = self,
        onclick = PsychopatzDebugTraceWindow.onClear,
        variant = "danger",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close", title = "Close", target = self,
        onclick = PsychopatzDebugTraceWindow.close,
        variant = "quiet",
    })
    self.lastRevision = -1
    self.selectedID = nil
    self:requestResponsiveLayout(true)
    self:refreshEntries(true)
end

function PsychopatzDebugTraceWindow:onResponsiveLayout()
    if not self.eventList then return end
    local rect = self:getContentRect({ top = 70, bottom = 44 })
    local gap = Layout.Pixels(8, self.uiScale)
    local leftWidth = math.floor(rect.width * 0.38)
    Layout.SetBounds(self.eventList, rect.x, rect.y, leftWidth, rect.height)
    Layout.SetBounds(self.details, rect.x + leftWidth + gap, rect.y,
        rect.width - leftWidth - gap, rect.height)
    local buttons = { self.captureButton, self.clearButton, self.closeButton }
    Layout.Flow(buttons, {
        x = rect.x, y = rect.y + rect.height + Layout.Pixels(8, self.uiScale),
        width = rect.width,
    }, { scale = self.uiScale, minWidth = 110 })
end

function PsychopatzDebugTraceWindow:refreshEntries(force)
    local revision = Trace.GetRevision()
    if not force and revision == self.lastRevision then return end
    self.lastRevision = revision
    local previousID = self.selectedID
    self.eventList:clear()
    local entries = Trace.GetEntries()
    for index, entry in ipairs(entries or {}) do
        self.eventList:addItem(entryLabel(entry), entry)
        if previousID and entry.id == previousID then
            self.eventList.selected = index
        end
    end
    if (self.eventList.selected or 0) < 1 and #self.eventList.items > 0 then
        self.eventList.selected = #self.eventList.items
    end
    self:refreshDetails()
end

function PsychopatzDebugTraceWindow:refreshDetails()
    local row = self.eventList and self.eventList:getItem() or nil
    local entry = row and row.item or nil
    self.selectedID = entry and entry.id or nil
    local content
    if entry then
        content = table.concat({
            "id = " .. tostring(entry.id),
            "timestamp = " .. tostring(entry.timestamp),
            "source = " .. tostring(entry.source),
            "event = " .. tostring(entry.event),
            "requestID = " .. tostring(entry.requestID or ""),
            "data = " .. formatValue(entry.data, 0, 0),
        }, "\n")
    else
        content = "No trace events. Enable capture, then perform the action you want to inspect."
    end
    self.details.text = content
    self.details:paginate()
end

function PsychopatzDebugTraceWindow:onCapture()
    Trace.SetEnabled(not Trace.IsEnabled())
    self:refreshEntries(true)
    self:requestResponsiveLayout(true)
end

function PsychopatzDebugTraceWindow:onClear()
    Trace.Clear()
    self:refreshEntries(true)
end

function PsychopatzDebugTraceWindow:render()
    UI.Window.render(self)
    local rect = self:getContentRect({ top = 32, bottom = 10 })
    local color = Theme.colors.textMuted
    local status = Trace.IsEnabled() and "Capture is live; events stay in memory only."
        or "Capture is OFF; no payloads are copied or retained."
    self:drawText(status, rect.x, rect.y - Layout.Pixels(24, self.uiScale),
        color.r, color.g, color.b, color.a, UIFont.Small)
    self.captureButton:setTitle(Trace.IsEnabled() and "Capture: ON" or "Capture: OFF")
    UI.DrawSectionTitle(self, "Runtime trace", rect.x,
        rect.y - Layout.Pixels(44, self.uiScale), rect.width,
        tostring(#(Trace.GetEntries() or {})))
end

function PsychopatzDebugTraceWindow:prerender()
    self:refreshEntries(false)
    UI.Window.prerender(self)
end

function PsychopatzDebugTraceWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    PsychopatzDebugTraceWindow.instance = nil
end

function PsychopatzDebugTraceWindow:new(x, y, width, height, options)
    local object = UI.Window.new(self, x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function PsychopatzDebugTraceWindow.Open()
    local window = PsychopatzDebugTraceWindow.instance
    if window then
        window:setVisible(true)
        window:bringToTop()
        window:refreshEntries(true)
        return window
    end
    window = UI.NewWindow(PsychopatzDebugTraceWindow, {
        title = "Psychopatz Runtime Debug Trace",
        resizable = true,
        responsiveSpec = {
            width = 1040, height = 680,
            minWidth = 700, minHeight = 440,
            maxWidth = 1600, maxHeight = 1000,
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:bringToTop()
    PsychopatzDebugTraceWindow.instance = window
    return window
end

function PsychopatzDebugTraceWindow.Toggle()
    if PsychopatzDebugTraceWindow.instance then
        PsychopatzDebugTraceWindow.instance:close()
        return nil
    end
    return PsychopatzDebugTraceWindow.Open()
end

return PsychopatzDebugTraceWindow
