local CLIENT_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;"
    .. package.path

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
function Base:setWidth(value) self.width = value end
function Base:setHeight(value) self.height = value end
function Base:setVisible() end

ISPanel = Base
UIFont = { Small = 1 }
package.preload["ISUI/ISPanel"] = function() return Base end

getCore = function()
    return {
        getScreenWidth = function() return 1920 end,
        getScreenHeight = function() return 1080 end,
    }
end
getTextManager = function()
    return {
        MeasureStringX = function(_, _, value) return #tostring(value) * 8 end,
        getFontFromEnum = function()
            return { getLineHeight = function() return 16 end }
        end,
    }
end

local Tooltip = require
    "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltip"
local tooltip = Tooltip:new(0, 0, 1, 1, nil, {})

tooltip:setModel({ title = "Water Bottle", lines = {
    { label = "Encumbrance", value = "0.1" },
} })
local sparseWidth = tooltip.width
local sparseHeight = tooltip.height

tooltip:setModel({ title = "Water Bottle (Mixed Liquids)", lines = {
    { section = true, label = "Liquids" },
    { label = "Amount", value = "1.00 / 2.00", progress = 0.5 },
    { label = "Water", value = "1.00" },
    { label = "Coffee", value = "1.00 (50%)", progress = 0.5 },
    { section = true, label = "Food" },
    { label = "Condition", value = "3 / 5", progress = 0.6 },
} })
assert(tooltip.width > sparseWidth,
    "tooltip width did not grow with its content")
assert(tooltip.height > sparseHeight,
    "tooltip height did not grow with its sections")
assert(tooltip.width <= 520,
    "tooltip ignored its content-width safety cap")

print("psychopatz_inventory_tooltip_layout_smoke: PASS")
