-- Shared world-map tools menu presentation.

require "ISUI/ISPanel"
require "ISUI/ISButton"

local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu_Registry"

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
        PsychopatzMapToolsWindow.onButton
    )
    button.internal = entry.id
    button.entry = entry
    local iconPath = Menu.Resolve(entry, "icon", nil)
    if iconPath and type(getTexture) == "function" then
        local icon = type(iconPath) == "string"
            and getTexture(iconPath) or iconPath
        if icon then
            button.iconTexture = icon
            button.joypadTextureWH = tonumber(
                Menu.Resolve(entry, "iconSize", 20)
            ) or 20
        end
    end
    if button.initialise then button:initialise() end
    if button.instantiate then button:instantiate() end
    panel:addChild(button)
    return button
end

PsychopatzMapToolsWindow = ISPanel:derive("PsychopatzMapToolsWindow")

function PsychopatzMapToolsWindow:initialise()
    ISPanel.initialise(self)
end

function PsychopatzMapToolsWindow:createChildren()
    ISPanel.createChildren(self)
    self.entryButtons = {}
    self.closeButton = ISButton:new(
        18, 0, self.width - 36, 32,
        text("UI_PsychopatzMapTools_Close", "Close"),
        self, PsychopatzMapToolsWindow.onButton
    )
    self.closeButton.internal = "CLOSE"
    if self.closeButton.initialise then self.closeButton:initialise() end
    if self.closeButton.instantiate then self.closeButton:instantiate() end
    self:addChild(self.closeButton)
    self:syncButtons()
end

function PsychopatzMapToolsWindow:syncButtons()
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
        local enabled = Menu.Resolve(entry, "enabled", true) ~= false
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
    self.closeY = y
    local desiredHeight = y + 32 + 8
    if self.setHeight then self:setHeight(desiredHeight)
    else self.height = math.max(self.height or 0, desiredHeight) end
end

function PsychopatzMapToolsWindow:onButton(button)
    local id = button and button.internal or ""
    if id == "CLOSE" then
        self:close()
        return true
    end

    local entry = Menu.EntriesByID[id]
    if not entry or not Menu.IsEntryVisible(entry)
        or Menu.Resolve(entry, "enabled", true) == false then
        return false
    end
    local ok, result = pcall(entry.onActivate, self.map)
    self:syncButtons()
    if not ok then
        if PsychopatzCore and PsychopatzCore.LogWarn then
            PsychopatzCore.LogWarn(
                "Map tools entry failed id=" .. tostring(id)
                    .. " error=" .. tostring(result)
            )
        end
        return false
    end
    return result ~= false
end

function PsychopatzMapToolsWindow:prerender()
    ISPanel.prerender(self)
    self:syncButtons()
    self:drawRect(0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028)
    self:drawRectBorder(0, 0, self.width, self.height,
        0.96, 0.28, 0.65, 0.92)
    self:drawTextCentre(
        text("UI_PsychopatzMapTools_Title", "Map Tools"),
        self.width / 2, 14, 0.95, 0.95, 0.95, 1, UIFont.Medium
    )
    self:drawTextCentre(
        text("UI_PsychopatzMapTools_Hint",
            "Shared map controls and provider tools."),
        self.width / 2, 39, 0.72, 0.76, 0.82, 1, UIFont.Small
    )
end

function PsychopatzMapToolsWindow:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if Menu.instance == self then Menu.instance = nil end
end

function PsychopatzMapToolsWindow:new(x, y, width, height, map)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.map = map
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object.moveWithMouse = true
    return object
end

function Menu.Open(map)
    if Menu.instance then
        Menu.instance.map = map or Menu.instance.map
        Menu.instance:syncButtons()
        Menu.instance:bringToTop()
        return Menu.instance
    end

    local width, height = 430, 170
    local screenWidth = getCore and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore():getScreenHeight() or 720
    local modal = PsychopatzMapToolsWindow:new(
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
    Menu.instance = modal
    return modal
end

function Menu.Close()
    for _, entry in ipairs(Menu.List()) do
        if type(entry.onMapClose) == "function" then
            pcall(entry.onMapClose)
        end
    end
    if Menu.instance then Menu.instance:close() end
end

return Menu
