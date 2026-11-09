-- Compact map-debug presentation.  Actions remain registered in Core's
-- provider-neutral Debug Hub registry; this file owns only the map UI.

require "ISUI/ISPanel"
require "ISUI/ISButton"

local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapDebugMenu"

local function text(key, fallback)
    local core = PsychopatzCore and PsychopatzCore.Translation
    if core and type(core.GetKey) == "function" then
        local ok, value = pcall(core.GetKey, key, fallback)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end
    if type(getText) == "function" then
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string"
            and value ~= "" and value ~= key then
            return value
        end
    end
    return fallback or key
end

local function addButton(panel, entry, y)
    local button = ISButton:new(
        18, y, panel.width - 36, 32, "", panel,
        PsychopatzMapDebugWindow.onButton
    )
    button.internal = entry.id
    button.entry = entry
    if button.initialise then button:initialise() end
    if button.instantiate then button:instantiate() end
    panel:addChild(button)
    return button
end

PsychopatzMapDebugWindow = ISPanel:derive("PsychopatzMapDebugWindow")

function PsychopatzMapDebugWindow:initialise()
    ISPanel.initialise(self)
end

function PsychopatzMapDebugWindow:createChildren()
    ISPanel.createChildren(self)
    self.entryButtons = {}
    self.closeButton = ISButton:new(
        18, 0, self.width - 36, 32,
        text("UI_PsychopatzMapTools_Close", "Close"),
        self, PsychopatzMapDebugWindow.onButton
    )
    self.closeButton.internal = "CLOSE"
    if self.closeButton.initialise then self.closeButton:initialise() end
    if self.closeButton.instantiate then self.closeButton:instantiate() end
    self:addChild(self.closeButton)
    self:syncButtons()
end

function PsychopatzMapDebugWindow:syncButtons()
    if not self.entryButtons then return end

    local y = 62
    local seen = {}
    for _, entry in ipairs(Menu.List()) do
        seen[entry.id] = true
        local button = self.entryButtons[entry.id]
        if not button then
            button = addButton(self, entry, y)
            self.entryButtons[entry.id] = button
        end

        local visible = Menu.IsEntryVisible(entry)
        if button.setVisible then button:setVisible(visible)
        else button.visible = visible end
        if visible then
            if button.setY then button:setY(y) else button.y = y end
            y = y + 38
        end

        local title = tostring(Menu.Resolve(entry, "title", entry.id))
        if button.setTitle then button:setTitle(title)
        else button.title = title end
        local enabled = Menu.IsEntryEnabled(entry)
        if button.setEnable then button:setEnable(enabled)
        else button.enable = enabled end
        button.tooltip = Menu.Resolve(entry, "tooltip", nil)
    end

    for id, button in pairs(self.entryButtons) do
        if not seen[id] then
            if button.setVisible then button:setVisible(false)
            else button.visible = false end
        end
    end

    if self.closeButton.setY then self.closeButton:setY(y)
    else self.closeButton.y = y end
    local desiredHeight = y + 32 + 8
    if self.setHeight then self:setHeight(desiredHeight)
    else self.height = math.max(self.height or 0, desiredHeight) end
end

function PsychopatzMapDebugWindow:onButton(button)
    local id = button and button.internal or ""
    if id == "CLOSE" then
        self:close()
        return true
    end

    local entry = Menu.Get(id)
    if not entry or not Menu.IsEntryVisible(entry)
        or not Menu.IsEntryEnabled(entry) then
        return false
    end

    local ok, result = pcall(entry.action)
    self:syncButtons()
    if not ok then
        if PsychopatzCore and PsychopatzCore.LogWarn then
            PsychopatzCore.LogWarn(
                "Map debug entry failed id=" .. tostring(id)
                    .. " error=" .. tostring(result)
            )
        end
        return false
    end
    return result ~= false
end

function PsychopatzMapDebugWindow:prerender()
    ISPanel.prerender(self)
    self:syncButtons()
    self:drawRect(0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028)
    self:drawRectBorder(0, 0, self.width, self.height,
        0.96, 0.28, 0.65, 0.92)
    self:drawTextCentre(
        text("UI_PsychopatzMapTools_DebugWindow_Title", "Map Debug Tools"),
        self.width / 2, 14, 0.95, 0.95, 0.95, 1, UIFont.Medium
    )
    self:drawTextCentre(
        text("UI_PsychopatzMapTools_DebugSection",
            "Toggle map diagnostics and run discovery tools."),
        self.width / 2, 39, 0.72, 0.76, 0.82, 1, UIFont.Small
    )
end

function PsychopatzMapDebugWindow:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if Menu.instance == self then Menu.instance = nil end
    if PsychopatzMapDebugWindow.instance == self then
        PsychopatzMapDebugWindow.instance = nil
    end
end

function PsychopatzMapDebugWindow:new(x, y, width, height, map)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.map = map
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object.moveWithMouse = true
    return object
end

function PsychopatzMapDebugWindow.Open(map)
    local existing = PsychopatzMapDebugWindow.instance
    if existing then
        local visible = existing.visible ~= false
        if type(existing.isVisible) == "function" then
            visible = existing:isVisible() == true
        end
        if visible then
            existing.map = map or existing.map
            existing:syncButtons()
            existing:bringToTop()
            return existing
        end
        existing:close()
    end

    local width, height = 430, 170
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local modal = PsychopatzMapDebugWindow:new(
        math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2),
        width, height, map
    )
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    if modal.setAlwaysOnTop then modal:setAlwaysOnTop(true) end
    if modal.setCapture then modal:setCapture(true) end
    modal:bringToTop()
    PsychopatzMapDebugWindow.instance = modal
    Menu.instance = modal
    return modal
end

return PsychopatzMapDebugWindow
