require "ISUI/ISPanel"

local Model = require
    "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel"

PsychopatzCore = PsychopatzCore or {}

ISPsychopatzInventoryTooltip = ISPanel:derive(
    "ISPsychopatzInventoryTooltip")

local COLORS = {
    normal = { r = 0.86, g = 0.86, b = 0.86 },
    accent = { r = 0.42, g = 0.82, b = 1.00 },
    warning = { r = 1.00, g = 0.70, b = 0.24 },
    danger = { r = 1.00, g = 0.40, b = 0.36 },
    fluid = { r = 0.45, g = 0.84, b = 0.96 },
    label = { r = 0.68, g = 0.70, b = 0.74 },
}

local function colorFor(tone)
    return COLORS[tone] or COLORS.normal
end

local function screenSize()
    local core = getCore and getCore() or nil
    if core then return core:getScreenWidth(), core:getScreenHeight() end
    return 1920, 1080
end

local function overlaps(left, top, width, height, other)
    return left < other.x + other.width and left + width > other.x
        and top < other.y + other.height and top + height > other.y
end

function ISPsychopatzInventoryTooltip:initialise()
    ISPanel.initialise(self)
end

local function measureText(manager, value)
    local text = tostring(value or "")
    local ok
    local measured
    if manager and manager.MeasureStringX and UIFont then
        ok, measured = pcall(manager.MeasureStringX, manager,
            UIFont.Small, text)
        if ok and tonumber(measured) then return math.max(0, measured) end
    end
    return #text * 7
end

local function fontLineHeight(manager)
    local font
    local ok
    local value
    if manager and manager.getFontFromEnum and UIFont then
        ok, font = pcall(manager.getFontFromEnum, manager, UIFont.Small)
        if ok and font and font.getLineHeight then
            ok, value = pcall(font.getLineHeight, font)
            if ok and tonumber(value) and value > 0 then
                return math.max(1, math.floor(value))
            end
        end
    end
    return 18
end

local function setDimension(object, method, field, value)
    if object and type(object[method]) == "function" then
        object[method](object, value)
    elseif object then
        object[field] = value
    end
end

function ISPsychopatzInventoryTooltip:layoutModel()
    local model = self.model
    local manager = getTextManager and getTextManager() or nil
    local labelWidth = 0
    local valueWidth = 0
    local titleWidth = 0
    local lineHeight = fontLineHeight(manager)
    local horizontalPadding = 20
    local columnGap = 20
    local minimumWidth = 180
    local screenWidth
    local maximumWidth
    local desiredWidth
    local height = 8
    if not model then return end
    titleWidth = measureText(manager, model.title)
    for index = 1, #model.lines do
        local line = model.lines[index]
        local label = tostring(line.label or "")
        local value = tostring(line.value or "")
        labelWidth = math.max(labelWidth, measureText(manager, label))
        if not line.section then
            valueWidth = math.max(valueWidth, measureText(manager, value))
        end
    end

    -- Width is driven by the longest rendered content. The cap keeps a
    -- translated/modded value from covering the whole screen, while the
    -- minimum only protects the two-column layout when an item is sparse.
    screenWidth = screenSize()
    maximumWidth = math.max(minimumWidth,
        math.min(520, math.max(minimumWidth, screenWidth - 24)))
    desiredWidth = math.max(titleWidth,
        labelWidth + valueWidth + columnGap) + horizontalPadding
    desiredWidth = math.max(minimumWidth,
        math.min(maximumWidth, math.ceil(desiredWidth)))
    setDimension(self, "setWidth", "width", desiredWidth)

    height = height + lineHeight + 6
    for index = 1, #model.lines do
        local line = model.lines[index]
        if line.section then
            height = height + lineHeight + 5
        elseif line.progress ~= nil then
            -- Progress bars are rendered below the text so long values never
            -- collide with their own bar.
            height = height + lineHeight + 10
        else
            height = height + lineHeight + 2
        end
    end
    setDimension(self, "setHeight", "height", math.max(40, height + 6))
    self.labelColumnWidth = labelWidth
end

function ISPsychopatzInventoryTooltip:setModel(model)
    self.model = model
    self.signature = nil
    self:layoutModel()
end

function ISPsychopatzInventoryTooltip:hide()
    self.model = nil
    self.signature = nil
    self.anchorList = nil
    self.anchorIndex = nil
    self:setVisible(false)
    if self.removeFromUIManager then self:removeFromUIManager() end
end

function ISPsychopatzInventoryTooltip:show(row, player, list, index)
    local model = self.modelProvider or Model
    local options = self.modelOptions or {}
    local signature = model.StateSignature(row, player, true, options)
    if self.signature ~= signature or not self.model then
        self:setModel(model.Build(row, player, options))
        self.signature = signature
    end
    if not self.model then
        self:hide()
        return false
    end
    self.anchorList = list
    self.anchorIndex = index
    if not self:getIsVisible() then
        self:addToUIManager()
        self:setVisible(true)
        self:bringToTop()
    end
    self:updatePosition()
    return true
end

function ISPsychopatzInventoryTooltip:updatePosition()
    local list = self.anchorList
    local index = self.anchorIndex
    local mouseX = getMouseX and getMouseX() or 0
    local mouseY = getMouseY and getMouseY() or 0
    local screenWidth, screenHeight = screenSize()
    local x = mouseX + 24
    local y = mouseY + 24
    local rowRect
    if list and index and list.topOfItem and list.getYScroll then
        local top = list:topOfItem(index)
        if top >= 0 then
            rowRect = {
                x = list:getAbsoluteX(),
                y = list:getAbsoluteY() + top + list:getYScroll(),
                width = list:getWidth(),
                height = list.items[index] and list.items[index].height
                    or list.itemheight,
            }
        end
    end
    if x + self.width > screenWidth then x = mouseX - self.width - 12 end
    if y + self.height > screenHeight then y = mouseY - self.height - 12 end
    if rowRect and overlaps(x, y, self.width, self.height, rowRect) then
        local right = rowRect.x + rowRect.width + 8
        local left = rowRect.x - self.width - 8
        local above = rowRect.y - self.height - 8
        if right + self.width <= screenWidth then x = right
        elseif left >= 0 then x = left
        elseif above >= 0 then x, y = rowRect.x, above end
    end
    x = math.max(0, math.min(x, screenWidth - self.width - 1))
    y = math.max(0, math.min(y, screenHeight - self.height - 1))
    self:setX(x)
    self:setY(y)
end

function ISPsychopatzInventoryTooltip:prerender()
    if self.owner and self.owner.isReallyVisible
        and not self.owner:isReallyVisible()
    then
        self:hide()
    end
end

function ISPsychopatzInventoryTooltip:onMouseDownOutside(x, y)
    self:hide()
end

-- Keep the tooltip non-interactive, matching ISToolTipInv behavior.
function ISPsychopatzInventoryTooltip:onMouseDown(x, y) return false end
function ISPsychopatzInventoryTooltip:onMouseUp(x, y) return false end
function ISPsychopatzInventoryTooltip:onRightMouseDown(x, y) return false end
function ISPsychopatzInventoryTooltip:onRightMouseUp(x, y) return false end

function ISPsychopatzInventoryTooltip:render()
    local model = self.model
    local pad = 10
    local y = 8
    local lineHeight = fontLineHeight(getTextManager and getTextManager() or nil)
    if not model then return end
    self:drawRect(0, 0, self.width, self.height,
        0.94, 0.02, 0.02, 0.025)
    self:drawRectBorder(0, 0, self.width, self.height,
        0.94, 0.45, 0.45, 0.48)
    self:drawText(tostring(model.title or "Item"), pad, y,
        1, 0.88, 0.56, 1, UIFont.Small)
    y = y + lineHeight + 6
    for index = 1, #model.lines do
        local line = model.lines[index]
        if line.section then
            self:drawRect(pad, y + 2, self.width - pad * 2, 1,
                0.45, 0.32, 0.34, 0.38)
            self:drawText(string.upper(line.label), pad, y + 4,
                0.66, 0.72, 0.84, 1, UIFont.Small)
            y = y + lineHeight + 5
        else
            local color = colorFor(line.tone)
            self:drawText(tostring(line.label or ""), pad, y,
                COLORS.label.r, COLORS.label.g, COLORS.label.b, 1,
                UIFont.Small)
            self:drawTextRight(tostring(line.value or ""),
                self.width - pad, y, color.r, color.g, color.b, 1, UIFont.Small)
            if line.progress ~= nil then
                local barX = pad
                local barWidth = math.max(20, self.width - pad * 2)
                local barY = y + lineHeight - 3
                self:drawRect(barX, barY, barWidth, 5,
                    0.65, 0.12, 0.12, 0.14)
                self:drawRect(barX, barY,
                    math.floor(barWidth * line.progress), 5,
                    0.85, color.r, color.g, color.b)
                y = y + lineHeight + 10
            else
                y = y + lineHeight + 2
            end
        end
    end
end

function ISPsychopatzInventoryTooltip:new(x, y, width, height, owner, options)
    local object = ISPanel.new(self, x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.owner = owner
    object.modelOptions = type(options) == "table" and options or {}
    object.backgroundColor = { r = 0.02, g = 0.02, b = 0.025, a = 0.94 }
    object.borderColor = { r = 0.45, g = 0.45, b = 0.48, a = 0.94 }
    object.anchorList = nil
    object.anchorIndex = nil
    object.model = nil
    object.signature = nil
    return object
end

PsychopatzCore.UI = PsychopatzCore.UI or {}
PsychopatzCore.UI.InventoryTooltip = ISPsychopatzInventoryTooltip

return ISPsychopatzInventoryTooltip
