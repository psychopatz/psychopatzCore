local ROOT = "Contents/mods/PsychopatzCore/42.16/media/lua/client/PsychopatzCore/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

package.preload["ISUI/ISPanel"] = function() return true end
package.preload["ISUI/ISUI3DModel"] = function() return true end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] = function() return true end

local Panel = {}
Panel.__index = Panel
function Panel:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function Panel:new(x, y, width, height)
    return setmetatable({ x = x, y = y, width = width, height = height, children = {} }, self)
end
function Panel:initialise() end
function Panel:createChildren() end
function Panel:prerender() end
function Panel:addChild(child) self.children[#self.children + 1] = child end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
ISPanel = Panel

local lastModel
ISUI3DModel = {
    new = function(_, x, y, width, height)
        local model = Panel:new(x, y, width, height)
        model.javaObject = {
            clearVariables = function() end,
            setAnimate = function() end,
        }
        function model:instantiate() end
        function model:setAnchorLeft() end
        function model:setAnchorRight() end
        function model:setAnchorTop() end
        function model:setAnchorBottom() end
        function model:setAnimSetName(value) self.animSet = value end
        function model:setState(value) self.state = value end
        function model:setDirection(value) self.direction = value end
        function model:setIsometric(value) self.isometric = value end
        function model:setDoRandomExtAnimations() end
        function model:setZoom(value) self.zoom = value end
        function model:setXOffset(value) self.xOffset = value end
        function model:setYOffset(value) self.yOffset = value end
        function model:setVariable() end
        function model:setCharacter(value) self.character = value end
        function model:setSurvivorDesc(value) self.descriptor = value end
        lastModel = model
        return model
    end,
}

PsychopatzCore = {
    UI = {
        Layout = {
            SetBounds = function(element, x, y, width, height)
                element:setX(x)
                element:setY(y)
                element:setWidth(width)
                element:setHeight(height)
            end,
        },
    },
}

IsoDirections = { S = "south" }
getTexture = function() return nil end
ImmutableColor = { new = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end }

local bodyLocations = {}
ResourceLocation = {
    of = function(value)
        return { id = tostring(value) }
    end,
}
ItemBodyLocation = {
    get = function(resource)
        local id = resource and resource.id or ""
        bodyLocations[id] = bodyLocations[id] or setmetatable({ id = id }, {
            __tostring = function(value) return value.id end,
        })
        return bodyLocations[id]
    end,
}

local worn = { values = {} }
function worn:clear() self.values = {} end
function worn:setItem(location, item)
    assert(type(location) ~= "string", "Build 42 portrait requires typed ItemBodyLocation")
    self.values[tostring(location)] = item
end

local visual = {}
function visual:setSkinTextureName(value) self.skin = value end
function visual:setHairModel(value) self.hair = value end
function visual:setBeardModel(value) self.beard = value end
function visual:setHairColor(value) self.hairColor = value end
function visual:setBeardColor(value) self.beardColor = value end
function visual:removeBlood() end
function visual:removeDirt() end

local descriptor = {}
function descriptor:setFemale(value) self.female = value end
function descriptor:getHumanVisual() return visual end
function descriptor:getWornItems() return worn end
function descriptor:resetModel() self.reset = true end

SurvivorType = { Neutral = "neutral" }
SurvivorFactory = { CreateSurvivor = function() return descriptor end }
instanceItem = function(fullType)
    return {
        fullType = fullType,
        getBodyLocation = function() return "Shirt" end,
    }
end

dofile(ROOT .. "UI/Components/PsychopatzPortraitPanel.lua")

local panel = PsychopatzCore.UI.PortraitPanel:new(0, 0, 130, 260)
panel:initialise()
panel:createChildren()
assertEqual(lastModel.zoom, 14, "portrait zoom")
assertEqual(lastModel.state, "idle", "portrait state")
assertEqual(lastModel.direction, "south", "portrait direction")

assert(panel:setTarget(nil, {
    id = "npc_portrait",
    identitySeed = 10,
    isFemale = true,
    appearance = { hairModel = "Long", outfitItems = { "Base.Shirt" } },
    equipment = { worn = { Jacket = "Base.Jacket" } },
}), "descriptor target failed")
assertEqual(lastModel.descriptor, descriptor, "descriptor applied")
assertEqual(descriptor.female, true, "descriptor gender")
assertEqual(visual.hair, "Long", "descriptor hair")
assertEqual(worn.values.Jacket.fullType, "Base.Jacket", "equipment clothing applied")

local character = { getHumanVisual = function() return visual end }
assert(panel:setTarget(character, { id = "npc_live", key = "live" }), "live target failed")
assertEqual(lastModel.character, character, "live character applied")

local uprightPanel = PsychopatzCore.UI.PortraitPanel:new(0, 0, 130, 260, {
    zoom = -3,
    yOffset = 0,
    animSetName = false,
})
uprightPanel:initialise()
uprightPanel:createChildren()
assertEqual(lastModel.animSet, nil, "vanilla human anim set remains untouched")
assertEqual(lastModel.zoom, -3, "full-body portrait zoom")
assertEqual(lastModel.yOffset, 0, "full-body portrait vertical offset")
assert(uprightPanel:setTarget(character, {
    id = "npc_upright",
    key = "upright",
    preferDescriptor = true,
    appearance = { hairModel = "Long" },
    equipment = { worn = {} },
}), "descriptor-first target failed")
assertEqual(uprightPanel.targetMode, "descriptor", "descriptor-first target mode")
assertEqual(lastModel.character, nil, "live IsoZombie is not used by descriptor-first portrait")
assertEqual(lastModel.descriptor, descriptor, "upright descriptor applied")

panel:setPortraitBounds(3, 4, 150, 300)
assertEqual(panel.width, 150, "responsive portrait width")
assertEqual(panel.modelView.width, 146, "responsive model width")

print("psychopatz_portrait_smoke: ok")
