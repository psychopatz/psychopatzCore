local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = ROOT .. "?.lua;" .. package.path

local Panel = {}
Panel.__index = Panel
function Panel:createChildren() end
function Panel:addChild(child)
    self.children = self.children or {}
    self.children[#self.children + 1] = child
end

function Panel:derive()
    local child = {}
    setmetatable(child, { __index = self })
    child.__index = child
    return child
end

function Panel:new(x, y, width, height)
    local object = {
        x = x, y = y, width = width, height = height,
    }
    setmetatable(object, self)
    return object
end

package.preload["ISUI/ISPanel"] = function()
    ISPanel = Panel
    return Panel
end

local Portrait = {
    new = function(_, x, y, width, height)
        return {
            x = x, y = y, width = width, height = height,
            initialise = function() end,
            instantiate = function() end,
            setTarget = function() return true end,
        }
    end,
}

PsychopatzCore = { UI = { PortraitPanel = Portrait } }
package.preload[
    "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
] = function()
    return Portrait
end

local Card = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHoverCard"
local card = Card:new(0, 0, 128, { nameHeight = 24 })
card:createChildren()
card:setContext(
    { actorID = "actor:hover:one", providerState = "abstract" },
    {
        hoverMetadata = {
            name = "Trader Ada",
            factionName = "Northstar Caravan",
            role = "trader",
            presence = "abstract",
            factionBadge = { glyph = "N" },
            actorIcon = { glyph = "T" },
        },
    }
)
assert(card.contextName == "Trader Ada", "hover card lost actor name")
assert(card.contextPresence == "ABSTRACT",
    "hover card did not normalize abstract presence")
assert(card.contextFactionGlyph == "N",
    "hover card lost faction badge glyph")
assert(card.contextRoleGlyph == "T",
    "hover card lost trader icon glyph")
assert(card:setTarget(nil, { actorID = "actor:hover:one" }) == true,
    "hover card did not delegate the canonical portrait target")

print("psychopatz_survivor_world_map_hover_card_smoke: PASS")
