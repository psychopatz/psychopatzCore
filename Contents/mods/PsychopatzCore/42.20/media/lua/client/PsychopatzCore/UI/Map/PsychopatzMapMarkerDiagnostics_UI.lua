-- Small, bounded read-only inspector for the shared map-marker diagnostic
-- contract. It is opened only from the authorized map Debug menu.

require "ISUI/ISPanel"
require "ISUI/ISButton"

local Diagnostics = require
    "PsychopatzCore/UI/Map/PsychopatzMapMarkerDiagnostics"

PsychopatzMapMarkerDiagnosticsWindow =
    ISPanel:derive("PsychopatzMapMarkerDiagnosticsWindow")

local Window = PsychopatzMapMarkerDiagnosticsWindow

local function text(key, fallback)
    local core = PsychopatzCore and PsychopatzCore.Translation
    if core and type(core.GetKey) == "function" then
        local value = core.GetKey(key, fallback)
        if type(value) == "string" and value ~= "" then return value end
    end
    return fallback or key
end

function Window:initialise()
    ISPanel.initialise(self)
end

function Window:createChildren()
    ISPanel.createChildren(self)
    self.closeButton = ISButton:new(
        18, self.height - 42, self.width - 36, 32,
        text("UI_PsychopatzMapTools_Close", "Close"),
        self, Window.onButton
    )
    self.closeButton.internal = "CLOSE"
    if self.closeButton.initialise then self.closeButton:initialise() end
    if self.closeButton.instantiate then self.closeButton:instantiate() end
    self:addChild(self.closeButton)
    self:refreshRows()
end

function Window:refreshRows()
    self.rows = Diagnostics.List()
    self.summary = Diagnostics.Summarize(self.rows)
    self.lastRefreshAt = getTimestampMs and tonumber(getTimestampMs())
        or getTimeInMillis and tonumber(getTimeInMillis()) or 0
end

function Window:onButton(button)
    if button and button.internal == "CLOSE" then
        self:close()
        return true
    end
    return false
end

function Window:prerender()
    ISPanel.prerender(self)
    local now = getTimestampMs and tonumber(getTimestampMs())
        or getTimeInMillis and tonumber(getTimeInMillis()) or 0
    if now == 0 or now - (tonumber(self.lastRefreshAt) or 0) >= 500 then
        self:refreshRows()
    end
    self:drawRect(0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028)
    self:drawRectBorder(0, 0, self.width, self.height,
        0.96, 0.28, 0.65, 0.92)
    self:drawTextCentre(
        text("UI_PsychopatzMapTools_MarkerDiagnostics_Title",
            "Map Marker Diagnostics"),
        self.width / 2, 14, 0.95, 0.95, 0.95, 1, UIFont.Medium)
    local summary = self.summary or { total = 0, errors = 0 }
    self:drawText(
        "Rows: " .. tostring(summary.total)
            .. "  Errors: " .. tostring(summary.errors or 0),
        18, 40, 0.72, 0.76, 0.82, 1, UIFont.Small)
    local y = 62
    local maxRows = math.floor((self.height - 112) / 18)
    for index = 1, math.min(#(self.rows or {}), maxRows) do
        local row = self.rows[index]
        local position = row.position or {}
        local coordinates = tonumber(position.x) and tonumber(position.y)
            and (" @ " .. math.floor(position.x) .. ","
                .. math.floor(position.y)) or ""
        local line = string.upper(tostring(row.kind)) .. "  "
            .. tostring(row.id) .. "  [" .. tostring(row.presence)
            .. "]" .. coordinates
        self:drawText(line, 18, y, 0.88, 0.88, 0.88, 1, UIFont.Small)
        y = y + 18
    end
    if #(self.rows or {}) == 0 then
        local emptyText = type(getText) == "function"
            and getText("UI_PsychopatzMapTools_MarkerDiagnostics_Empty")
            or text("UI_PsychopatzMapTools_MarkerDiagnostics_Empty")
        self:drawText(emptyText,
            18, y, 0.88, 0.88, 0.88, 1, UIFont.Small)
    end
end

function Window:close()
    if self.setCapture then self:setCapture(false) end
    if self.setVisible then self:setVisible(false) end
    if self.removeFromUIManager then self:removeFromUIManager() end
    if Window.instance == self then Window.instance = nil end
    Diagnostics.SetEnabled(false)
end

function Window:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.rows = {}
    object.summary = { total = 0, errors = 0 }
    object.moveWithMouse = true
    return object
end

function Window.Open()
    if Window.instance then
        Window.instance:bringToTop()
        return Window.instance
    end
    local width, height = 760, 520
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local modal = Window:new(
        math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2), width, height)
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    if modal.setAlwaysOnTop then modal:setAlwaysOnTop(true) end
    if modal.setCapture then modal:setCapture(true) end
    modal:bringToTop()
    Window.instance = modal
    return modal
end

function Window.Close()
    if Window.instance then
        Window.instance:close()
        return true
    end
    return false
end

return Window
