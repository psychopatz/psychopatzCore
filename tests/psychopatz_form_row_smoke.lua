local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/"

local Base = {}
Base.__index = Base
function Base:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function Base:new(x, y, width, height)
    return setmetatable({ x = x, y = y, width = width, height = height }, self)
end
function Base:initialise() end
function Base:instantiate() self.javaObject = self.javaObject or {} end
function Base:addChild(child) child.parent = self end
function Base:getX() return self.x end
function Base:getY() return self.y end
function Base:getWidth() return self.width end
function Base:getHeight() return self.height end
function Base:setX(value) self.x = value end
function Base:setY(value) self.y = value end
function Base:setWidth(value) self.width = value end
function Base:setHeight(value) self.height = value end

ISPanel = Base
UIFont = { Small = 1 }
ISLabel = {}
function ISLabel:new(x, y, height, name)
    return setmetatable({ x = x, y = y, width = #tostring(name or ""),
        height = height, name = name }, { __index = Base })
end

PsychopatzCore = {
    UI = {
        Theme = {
            colors = {
                text = { r = 1, g = 1, b = 1, a = 1 },
                textMuted = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
                transparent = { r = 0, g = 0, b = 0, a = 0 },
            },
            Color = function(_, name)
                return PsychopatzCore.UI.Theme.colors[name]
            end,
            FontHeight = function() return 14 end,
        },
        Layout = {
            Scale = function() return 1 end,
            Pixels = function(value) return math.floor(value + 0.5) end,
            SetBounds = function(element, x, y, width, height)
                element:setX(x)
                element:setY(y)
                element:setWidth(width)
                element:setHeight(height)
            end,
        },
    },
}
local UI = PsychopatzCore.UI
UI.SetLabelText = function(label, value) label.name = tostring(value) end
package.preload["ISUI/ISPanel"] = function() return true end
package.preload["ISUI/ISLabel"] = function() return true end
package.preload["PsychopatzCore/UI/Core/PsychopatzUITheme"] =
    function() return UI.Theme end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] =
    function() return UI.Layout end
package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] =
    function() return UI end

dofile(ROOT .. "Components/PsychopatzFormRow.lua")
local parent = Base:new(0, 0, 400, 300)
parent:instantiate()
local row = UI.CreateFormRow(parent, {
    id = "test-row",
    label = "Opacity",
    valueLabel = true,
    valueText = "46%",
    createControl = function(container)
        local control = Base:new(0, 0, 1, 1)
        control:initialise()
        container:addChild(control)
        return control
    end,
})
row:place(0, 0, 300, 29, {
    scale = 1, labelWidth = 100, valueWidth = 48,
    gap = 8, controlHeight = 26,
})
assert(row.control.x == 108, "form control x changed")
assert(row.valueLabel.x == 252, "form value label x changed")
UI.SetLabelText(row.valueLabel, "100%")
assert(row.valueLabel.x == 252,
    "dynamic form label escaped its assigned row bounds")

row:place(0, 0, 300, 29, {
    scale = 1.25, labelWidth = 100, valueWidth = 48,
    gap = 8, controlHeight = 26,
})
assert(row.uiScale == 1.25, "form row scale update")
assert(row.control.uiScale == 1.25, "form control scale propagation")

UI.Theme.Font = function() return UIFont.Small end
UI.Theme.TextWidth = function(_, value)
    return #tostring(value or "") * 7
end
UI.Layout.Ellipsize = function(value, _, width)
    if #tostring(value or "") * 7 <= width then return value end
    return "..."
end
local longRow = UI.CreateFormRow(parent, {
    id = "long-row",
    label = "Minimum reply delay (milliseconds)",
    createControl = function(container)
        local control = Base:new(0, 0, 1, 1)
        control:initialise()
        container:addChild(control)
        return control
    end,
})
longRow:place(0, 0, 300, 29, {
    scale = 1, labelWidth = 100, gap = 8, controlHeight = 26,
})
assert(longRow.lastLayout.labelWidth > 100,
    "long form label did not receive responsive width")
assert(longRow.control.x > 108,
    "long form label still overlaps its control")

print("psychopatz_form_row_smoke: ok")
