require "ISUI/ISButton"
require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"
local VirtualizedList = require "PsychopatzCore/UI/Components/PsychopatzVirtualizedList"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local variants = {
    default = { background = "surfaceRaised", border = "borderStrong", text = "text" },
    primary = { background = "accentDark", border = "accent", text = "text" },
    selected = { background = "accentDark", border = "accent", text = "text" },
    success = { background = "surfaceRaised", border = "success", text = "success" },
    warning = { background = "surfaceRaised", border = "warning", text = "warning" },
    danger = { background = "surfaceRaised", border = "danger", text = "danger" },
    quiet = { background = "surface", border = "border", text = "textMuted" },
}

function UI.StyleButton(button, variant)
    if not button then return button end
    local style = variants[variant or "default"] or variants.default
    button.psychopatzVariant = variant or "default"
    button.backgroundColor = Theme.Color(style.background)
    button.backgroundColorMouseOver = Theme.Color("surfaceHover")
    button.borderColor = Theme.Color(style.border)
    button.textColor = Theme.Color(style.text)
    return button
end

function UI.SetButtonVariant(button, variant)
    return UI.StyleButton(button, variant)
end

function UI.CreateButton(parent, definition)
    definition = definition or {}
    local button = ISButton:new(
        0,
        0,
        1,
        1,
        tostring(definition.title or ""),
        definition.target or parent,
        definition.onclick
    )
    button.internal = definition.id
    button.psychopatzPreferredWidth = definition.width
    button:initialise()
    button:instantiate()
    if definition.font and button.setFont then button:setFont(definition.font) end
    if definition.image and button.setImage and UI.ImageResolver then
        local image = UI.ImageResolver.Resolve(definition.image)
        if image then button:setImage(image) end
    end
    UI.StyleButton(button, definition.variant)
    if parent then parent:addChild(button) end
    return button
end

function UI.CreatePanel(parent)
    local panel = ISPanel:new(0, 0, 1, 1)
    panel:initialise()
    panel:instantiate()
    panel.backgroundColor = Theme.Color("surface")
    panel.borderColor = Theme.Color("border")
    if parent then parent:addChild(panel) end
    return panel
end

function UI.CreateList(parent, options)
    options = options or {}
    local list = ISScrollingListBox:new(0, 0, 1, 1)
    local baseDrawItem
    list:initialise()
    list:instantiate()
    list.itemheight = options.itemHeight or Layout.Pixels(28)
    list.drawBorder = options.drawBorder ~= false
    list.backgroundColor = Theme.Color("surface")
    list.borderColor = Theme.Color("border")
    if options.drawItemContent then
        baseDrawItem = options.doDrawItem or list.doDrawItem
        list.psychopatzBaseDrawItem = baseDrawItem
        list.psychopatzDrawItemContent = options.drawItemContent
        list.doDrawItem = function(self, y, item, alternate)
            local nextY = self.psychopatzBaseDrawItem(self, y, item, alternate)
            self.psychopatzDrawItemContent(self, y, item, alternate)
            return nextY or (y + self.itemheight)
        end
    elseif options.doDrawItem then
        list.doDrawItem = options.doDrawItem
    end
    -- Core lists use a fixed row height by default, which lets the shared
    -- list component render only the visible rows. Set virtualized=false for
    -- a list whose draw callback intentionally returns variable row heights.
    if options.virtualized ~= false then
        VirtualizedList.Install(list)
    end
    if parent then parent:addChild(list) end
    return list
end

function UI.DrawSurface(element, x, y, width, height, raised)
    local color = Theme.colors[raised and "surfaceRaised" or "surface"]
    local border = Theme.colors.border
    element:drawRect(x, y, width, height, color.a, color.r, color.g, color.b)
    element:drawRectBorder(x, y, width, height, border.a, border.r, border.g, border.b)
end

function UI.DrawSectionTitle(element, title, x, y, width, suffix)
    local color = Theme.colors.textMuted
    local accent = Theme.colors.accent
    local font = Theme.Font(element.uiScale)
    element:drawRect(x, y + Theme.FontHeight(font) + 3, width, 1, 0.7, accent.r, accent.g, accent.b)
    local suffixText = suffix and tostring(suffix) or ""
    local suffixWidth = suffixText ~= "" and Theme.TextWidth(font, suffixText) or 0
    local titleWidth = math.max(0, width - suffixWidth - (suffixText ~= "" and 12 or 0))
    element:drawText(Layout.Ellipsize(title, font, titleWidth), x, y,
        color.r, color.g, color.b, color.a, font)
    if suffixText ~= "" then
        element:drawText(suffixText, x + width - suffixWidth, y,
            color.r, color.g, color.b, color.a, font)
    end
end

function UI.DrawListSelection(list, y, height, selected, alternate)
    local color
    if selected then
        color = Theme.colors.accentDark
        list:drawRect(0, y, list:getWidth(), height, 0.9, color.r, color.g, color.b)
        color = Theme.colors.accent
        list:drawRect(0, y, 3, height, 1, color.r, color.g, color.b)
    elseif alternate then
        color = Theme.colors.surfaceRaised
        list:drawRect(0, y, list:getWidth(), height, 0.38, color.r, color.g, color.b)
    end
end

function UI.DrawBadge(element, value, right, y, colorName)
    local font = UIFont.Small
    local text = string.upper(tostring(value or ""))
    local width = Theme.TextWidth(font, text) + 12
    local height = Theme.FontHeight(font) + 4
    local x = right - width
    local color = Theme.colors[colorName or "accent"] or Theme.colors.accent
    element:drawRect(x, y, width, height, 0.2, color.r, color.g, color.b)
    element:drawRectBorder(x, y, width, height, 0.85, color.r, color.g, color.b)
    element:drawText(text, x + 6, y + 2, color.r, color.g, color.b, 1, font)
    return width
end

return UI
