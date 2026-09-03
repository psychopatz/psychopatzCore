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

-- ISLabel:setName() restores the label's originalX before measuring its new
-- text. That is useful for right-aligned native labels, but it moves labels
-- that were positioned later by a responsive layout. Keep dynamic labels
-- inside their assigned layout bounds instead.
function UI.SetLabelText(label, value)
    if not label then return nil end
    local text = tostring(value or "")
    if label.psychopatzFormText == nil then
        label.psychopatzFormText = text
    end
    local x = label.getX and label:getX() or label.x
    local y = label.getY and label:getY() or label.y
    local width = label.getWidth and label:getWidth() or label.width
    local height = label.getHeight and label:getHeight() or label.height
    if label.setNameWithoutMoving then
        label:setNameWithoutMoving(text)
    elseif label.setName then
        label:setName(text)
    else
        label.name = text
    end
    if x ~= nil and label.setX then label:setX(x) end
    if y ~= nil and label.setY then label:setY(y) end
    if width ~= nil and label.setWidth then label:setWidth(width) end
    if height ~= nil and label.setHeight then label:setHeight(height) end
    return label
end

function UI.ApplyButtonTheme(button, definition)
    if not button then return button end
    local style = definition or variants.default
    button.backgroundColor = Theme.Color(style.background or "surface",
        style.backgroundAlpha)
    button.backgroundColorMouseOver = Theme.Color(
        style.hover or "surfaceHover", style.hoverAlpha)
    button.borderColor = Theme.Color(style.border or "border",
        style.borderAlpha)
    button.textColor = Theme.Color(style.text or "text", style.textAlpha)
    return button
end

function UI.StyleButton(button, variant)
    if not button then return button end
    local selected = variant or "default"
    local style = variants[selected] or variants.default
    button.psychopatzVariant = selected
    button.psychopatzThemeOverride = nil
    return UI.ApplyButtonTheme(button, style)
end

-- Custom toolbar controls can retain their native hit behavior while opting
-- into the same live theme refresh as ordinary Core buttons.
function UI.SetButtonTheme(button, definition)
    if not button then return button end
    button.psychopatzThemeOverride = definition or variants.default
    return UI.ApplyButtonTheme(button, button.psychopatzThemeOverride)
end

function UI.SetButtonVariant(button, variant)
    return UI.StyleButton(button, variant)
end

function UI.SetLabelTheme(label, colorName)
    if not label then return label end
    local name = colorName or "text"
    local color = Theme.colors[name] or Theme.colors.text
    label.psychopatzThemeColorName = name
    if label.setColor then label:setColor(color.r, color.g, color.b, color.a) end
    label.r, label.g, label.b, label.a = color.r, color.g, color.b, color.a
    return label
end

local function refreshThemeElement(element, visited)
    if not element or visited[element] then return end
    visited[element] = true
    if element.psychopatzThemeOverride then
        UI.ApplyButtonTheme(element, element.psychopatzThemeOverride)
    elseif element.psychopatzVariant then
        UI.ApplyButtonTheme(element,
            variants[element.psychopatzVariant] or variants.default)
    end
    if element.psychopatzThemeBackgroundName then
        local current = element.backgroundColor
        element.backgroundColor = Theme.Color(
            element.psychopatzThemeBackgroundName, current and current.a)
    end
    if element.psychopatzThemeBorderName then
        local current = element.borderColor
        element.borderColor = Theme.Color(
            element.psychopatzThemeBorderName, current and current.a)
    end
    if element.psychopatzThemeColorName then
        UI.SetLabelTheme(element, element.psychopatzThemeColorName)
    end
    local children = element.getChildren and element:getChildren()
        or element.children
    if type(children) == "table" then
        for _, child in ipairs(children) do
            refreshThemeElement(child, visited)
        end
    end
end

function UI.RefreshTheme(root)
    if not root then return false end
    refreshThemeElement(root, {})
    return true
end

-- ISButton invokes callbacks as onclick(target, button, ...). Core panels
-- commonly need the actual button first, so this adapter keeps that contract
-- explicit and reusable without changing existing native-style callbacks.
function UI.ButtonCallback(callback)
    if type(callback) ~= "function" then return nil end
    return function(target, button, ...)
        local hub = UI.CommandHub
        if hub and hub.Trace then
            local id = button and (button.internal
                or button.commandHubCategory or button.commandHubAction)
                or "<nil>"
            hub.Trace("native_button_callback", "id=" .. tostring(id)
                .. " target=" .. tostring(target ~= nil)
                .. " button=" .. tostring(button ~= nil))
        end
        return callback(button, target, ...)
    end
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
    panel.psychopatzThemeBackgroundName = "surface"
    panel.psychopatzThemeBorderName = "border"
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
    list.psychopatzThemeBackgroundName = "surface"
    list.psychopatzThemeBorderName = "border"
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

function UI.DrawSurface(element, x, y, width, height, raised, opacity)
    local color = Theme.colors[raised and "surfaceRaised" or "surface"]
    local border = Theme.colors.border
    local alpha = tonumber(opacity) or color.a
    element:drawRect(x, y, width, height, alpha, color.r, color.g, color.b)
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
