local ROOT =
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/"
package.path = "Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua;" .. package.path

local portraitAnimationAssets = {
    {
        path = "Contents/mods/PsychopatzCore/common/media/AnimSets/zombie/idle/PNC_PortraitIdle.xml",
        animation = "Bob_Idle",
        state = "idle",
    },
    {
        path = "Contents/mods/PsychopatzCore/common/media/AnimSets/zombie/idle/PNC_PortraitSpeech.xml",
        animation = "Bob_Idle",
        state = "speech",
    },
    {
        path = "Contents/mods/PsychopatzCore/common/media/AnimSets/zombie/idle/PNC_PortraitGreetingWaveHi.xml",
        animation = "Bob_EmoteWaveHi",
        state = "wavehi",
    },
    {
        path = "Contents/mods/PsychopatzCore/common/media/AnimSets/zombie/idle/PNC_PortraitDeclineThumbsDown.xml",
        animation = "Bob_EmoteThumbsDown",
        state = "thumbsdown",
    },
}
for _, asset in ipairs(portraitAnimationAssets) do
    local file = io.open(asset.path, "r")
    if not file then
        error("Core is missing the shared portrait animation asset: " .. asset.path)
    end
    local xml = file:read("*a")
    file:close()
    if not string.find(xml, asset.animation, 1, true)
        or not string.find(xml, "PNCPortraitState", 1, true)
        or not string.find(xml, asset.state, 1, true)
    then
        error("Core portrait animation asset is not bound to the shared portrait state: " .. asset.path)
    end
end

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
local panelRenderCount = 0
function Panel:prerender() end
function Panel:render() panelRenderCount = panelRenderCount + 1 end
function Panel:addChild(child) self.children[#self.children + 1] = child end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
ISPanel = Panel

local lastModel
ISUI3DModel = Panel:derive("ISUI3DModel")
function ISUI3DModel:new(x, y, width, height)
    local model = Panel:new(x, y, width, height)
    model.variables = {}
    model.javaObject = {
        clearVariables = function() end,
        setAnimate = function(self, value) self.animated = value end,
    }
    function model:setVisible(value) self.visible = value end
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
    function model:setVariable(name, value)
        self.variables[name] = value
    end
    function model:setCharacter(value) self.character = value end
    function model:setSurvivorDesc(value) self.descriptor = value end
    lastModel = model
    setmetatable(model, self)
    self.__index = self
    return model
end
function ISUI3DModel:prerender()
    self.javaObject:setAnimate(true)
end

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

IsoDirections = { S = "south", N = "north" }
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
        -- Compact actor records use these aliases; Build 42 does not expose
        -- them as native ItemBodyLocation values.
        if id == "Torso_Upper" or id == "Legs" then return nil end
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
function visual:setSkinTextureIndex(value) self.skinIndex = value end
function visual:setSkinColor(value) self.skinColor = value end
function visual:setHairModel(value) self.hair = value end
function visual:setBeardModel(value) self.beard = value end
function visual:setHairColor(value) self.hairColor = value end
function visual:setBeardColor(value) self.beardColor = value end
function visual:removeBlood() end
function visual:removeDirt() end
function visual:addBodyVisualFromItemType(item) self.bodyVisuals[item] = true end

local descriptor = {}
function descriptor:setFemale(value) self.female = value end
function descriptor:getHumanVisual() return visual end
function descriptor:getWornItems() return worn end
function descriptor:resetModel() self.reset = true end

SurvivorType = { Neutral = "neutral" }
SurvivorFactory = { CreateSurvivor = function() return descriptor end }
instanceItem = function(fullType)
    local nativeLocations = {
        ["Base.Shirt"] = "Shirt",
        ["Base.Jacket"] = "Jacket",
        ["Base.Trousers_Suit"] = "Pants",
    }
    return {
        fullType = fullType,
        getBodyLocation = function()
            return nativeLocations[fullType] or "Shirt"
        end,
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
visual.skinColor = { r = .2, g = .1, b = .1 }
assert(panel:setTarget(nil, { id = "native_tone", appearance = { skinTexture = "FemaleBody02" }, isFemale = true }), "native tone target failed")
assertEqual(visual.skinIndex, 1, "native skin index follows the selected tone")
assertEqual(visual.skinColor.r, 1, "native tone removes random factory tint")
assert(panel:setTarget(nil, { id = "legacy_tint", appearance = { skinTexture = "FemaleBody02", skinColor = { r = .4, g = .3, b = .2 } }, isFemale = true }), "custom tint target failed")
assertEqual(visual.skinColor.r, .4, "explicit inherited/custom tint remains respected")

assert(panel:setTarget(nil, {
    id = "npc_native_slot_migration",
    identitySeed = 13,
    preferDescriptor = true,
    appearance = { outfitItems = { "Base.Shirt" } },
    equipment = {
        -- Existing actor records use these compact aliases.  The descriptor
        -- portrait must still render the complete body from them.
        worn = {
            Torso_Upper = "Base.Shirt",
            Legs = "Base.Trousers_Suit",
        },
    },
}), "legacy actor clothing target failed")
assertEqual(worn.values.Shirt.fullType, "Base.Shirt",
    "legacy torso alias normalized to native shirt slot")
assertEqual(worn.values.Pants.fullType, "Base.Trousers_Suit",
    "legacy legs alias normalized to native pants slot")

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

local facePanel = PsychopatzCore.UI.PortraitPanel:new(0, 0, 84, 84, {
    zoom = 16,
    yOffset = -1,
    animSetName = false,
    animate = false,
    portraitAnimation = true,
    faceOnly = true,
    showBackground = false,
    showBorder = false,
    padding = 0,
})
facePanel:initialise()
facePanel:createChildren()
assertEqual(facePanel.avatarBackground, nil,
    "transparent portrait loaded a background texture")
assertEqual(facePanel.background, false,
    "transparent portrait retained the stock ISPanel border")
assertEqual(facePanel.modelView.x, 0,
    "transparent portrait retained background padding")
facePanel.modelView:prerender()
assertEqual(facePanel.modelView.javaObject.animated, false,
    "static portrait animation was re-enabled during prerender")
facePanel:setContentOpacity(0.4)
assertEqual(facePanel.contentOpacity, 0.4,
    "portrait stores content opacity")
assertEqual(facePanel.modelView.visible, true,
    "partially transparent portrait keeps its model visible")
facePanel:setContentOpacity(0)
assertEqual(facePanel.modelView.visible, false,
    "fully transparent portrait hides its 3D model")
panelRenderCount = 0
facePanel:render()
assertEqual(panelRenderCount, 0,
    "fully transparent portrait skips its viewport renderer")
facePanel:setContentOpacity(1)
assertEqual(facePanel.modelView.visible, true,
    "opaque portrait restores its 3D model")
facePanel:render()
assertEqual(panelRenderCount, 1,
    "opaque portrait renders its viewport")
assert(facePanel:setTarget(nil, {
    id = "npc_face",
    identitySeed = 11,
    isFemale = false,
    faceOnly = true,
    appearance = {
        hairModel = "Long",
        outfitItems = { "Base.Shirt" },
    },
    equipment = {
        worn = {
            Hat = "Base.Hat_HardHat",
            Jacket = "Base.Jacket",
        },
    },
}), "face-only descriptor target failed")
assertEqual(worn.values.Hat.fullType, "Base.Hat_HardHat",
    "face-only portrait omitted head equipment")
assertEqual(worn.values.Jacket, nil,
    "face-only portrait retained torso equipment")
assertEqual(worn.values.Shirt, nil,
    "face-only portrait retained outfit clothing")

assert(facePanel:setTarget(nil, {
    id = "npc_current_clothing",
    identitySeed = 12,
    faceOnly = true,
    includeCurrentClothing = true,
    appearance = { outfitItems = { "Base.Shirt" } },
    equipment = {
        worn = {
            Hat = "Base.Hat_HardHat",
            Jacket = "Base.Jacket",
        },
    },
}), "current-clothing descriptor target failed")
assertEqual(worn.values.Jacket.fullType, "Base.Jacket",
    "current-clothing portrait lost torso equipment")
assertEqual(worn.values.Shirt, nil,
    "current-clothing portrait added stale fallback outfit")
assert(facePanel:playAnimation("greeting.wavehi"),
    "portrait greeting animation was rejected")
assertEqual(lastModel.variables.PNCPortraitState, "wavehi",
    "portrait greeting animation did not select its state")
assert(facePanel:playAnimation("reaction.thumbsdown"),
    "portrait decline animation was rejected")
assertEqual(lastModel.variables.PNCPortraitState, "thumbsdown",
    "portrait decline animation did not select its state")

for index = 1, 70 do
    assert(facePanel:setTarget(nil, {
        id = "npc_cache_" .. tostring(index),
        identitySeed = index,
        faceOnly = true,
        appearance = { hairModel = "Long" },
        equipment = { worn = {} },
    }), "bounded portrait cache target failed")
end
assert(PsychopatzCore.UI.GetPortraitDescriptorCacheSize() <= 64,
    "portrait descriptor cache exceeded its hard limit")

panel:setPortraitBounds(3, 4, 150, 300)
assertEqual(panel.width, 150, "responsive portrait width")
assertEqual(panel.modelView.width, 146, "responsive model width")

local originalSpec = uprightPanel.targetSpec
local originalDescriptor = uprightPanel.modelView.descriptor
local cacheSize = PsychopatzCore.UI.GetPortraitDescriptorCacheSize()
assertEqual(uprightPanel:getViewRegion(), nil, 'existing consumers have no forced region view')
uprightPanel.modelView.variables.PNCPortraitState = 'speech'
assert(uprightPanel:setViewRegion('head'), 'named head framing rejected')
assertEqual(uprightPanel.modelView.variables.PNCPortraitState, 'speech', 'camera changes do not reset ongoing portrait animation variables')
assertEqual(uprightPanel.modelView.zoom, 14, 'head framing reaches the reusable native model')
assertEqual(uprightPanel.modelView.yOffset, -.85, 'head camera targets the face')
uprightPanel.zoom = 12
uprightPanel:applyViewState()
assert(uprightPanel:setViewRegion('legs'))
assertEqual(uprightPanel.modelView.yOffset, -.24, 'leg framing targets the lower body')
assert(uprightPanel:setViewRegion('head'))
assertEqual(uprightPanel.modelView.zoom, 12, 'each region remembers user zoom independently')
assert(uprightPanel:setViewRegion('head', true))
assertEqual(uprightPanel.modelView.zoom, 14, 'reset restores the named default camera')
assert(uprightPanel:setViewRegion('left_arm'))
local leftOffset = uprightPanel.modelView.xOffset
assert(uprightPanel:setViewRegion('right_arm'))
assert(leftOffset ~= uprightPanel.modelView.xOffset, 'left and right arm targets have distinct horizontal framing')
assert(uprightPanel:setViewRegion('back'))
assertEqual(uprightPanel.modelView.direction, 'north', 'back view turns toward the backpack')
assertEqual(uprightPanel:setViewRegion('missing_region'), false, 'unknown regions fail without altering the current camera')
assertEqual(uprightPanel:getViewRegion(), 'back', 'invalid region preserves the active frame')
assert(uprightPanel:clearViewRegion())
assertEqual(uprightPanel.modelView.zoom, -3, 'clear restores the original consumer camera')
assertEqual(uprightPanel.modelView.direction, 'south', 'clear restores the original consumer direction')
assertEqual(uprightPanel.targetSpec, originalSpec, 'camera framing never replaces or edits the portrait target')
assertEqual(uprightPanel.modelView.descriptor, originalDescriptor, 'camera framing never rebuilds clothing/identity')
assertEqual(PsychopatzCore.UI.GetPortraitDescriptorCacheSize(), cacheSize, 'changing regions never expands the descriptor cache')
local regionPanel = PsychopatzCore.UI.PortraitPanel:new(0, 0, 100, 200, { viewRegion = 'feet' })
regionPanel:initialise(); regionPanel:createChildren()
assertEqual(regionPanel:getViewRegion(), 'feet', 'constructor supports reusable named views')
assertEqual(regionPanel.modelView.yOffset, -.06, 'constructor applies the region when the native model is created')

local now = 1000
uprightPanel.showBackground, uprightPanel.showBorder = false, false
getTimeInMillis = function() return now end
assert(uprightPanel:setViewRegion('body', true))
assert(uprightPanel:setViewRegion('legs', false, true))
assertEqual(uprightPanel.modelView.yOffset, -.5, 'animation begins at the engine full-body offset')
assertEqual(uprightPanel.modelView.zoom, -3, 'zoom starts at the displayed body view')
now = 1125
uprightPanel:prerender()
local midY = uprightPanel.modelView.yOffset
assert(midY > -.5 and midY < -.24, 'prerender pans between body and legs')
assertEqual(uprightPanel.modelView.zoom, 0, 'zoom eases along with pan')
assert(uprightPanel:setViewRegion('left_arm', false, true))
assertEqual(uprightPanel.modelView.yOffset, midY, 'retargeting starts at the displayed intermediate frame')
now = 1250
uprightPanel:prerender()
assert(uprightPanel.modelView.xOffset > 0 and uprightPanel.modelView.xOffset < .15, 'lateral pan eases toward the arm')
now = 1375
uprightPanel:prerender()
assertEqual(uprightPanel.modelView.xOffset, .15, 'pan finishes at the requested lateral offset')
assertEqual(uprightPanel.cameraTransition, nil, 'completed transition stops updating the model')
assert(uprightPanel:setViewRegion('body', true, true))
now = 1625
uprightPanel:prerender()
assertEqual(uprightPanel.modelView.yOffset, 0, 'return to body restores the native offset sentinel')
assertEqual(uprightPanel.modelView.zoom, -3, 'return to body restores the default zoom')

visual.bodyVisuals = {}
assert(uprightPanel:setTarget(nil, {
    id = "stubble", isFemale = false, faceOnly = true,
    appearance = { hairStubble = true, beardStubble = true },
}))
assertEqual(visual.bodyVisuals["Base.M_Hair_Stubble"], true, "male face includes vanilla scalp stubble")
assertEqual(visual.bodyVisuals["Base.M_Beard_Stubble"], true, "male face includes vanilla beard stubble")
visual.bodyVisuals = {}
assert(uprightPanel:setTarget(nil, {
    id = "stubble", isFemale = true, faceOnly = true,
    appearance = { hairStubble = true, beardStubble = true },
}))
assertEqual(visual.bodyVisuals["Base.F_Hair_Stubble"], true, "female face uses female scalp stubble")
assertEqual(visual.bodyVisuals["Base.M_Beard_Stubble"], nil, "female face skips beard stubble")

assert(uprightPanel:setTarget(nil, {
    id = "chest-hair", appearance = { skinTexture = "MaleBody04", chestHair = true },
}))
assertEqual(visual.skin, "MaleBody04a", "portrait applies chest hair to the selected skin tone")
assert(uprightPanel:setTarget(nil, {
    id = "chest-hair", appearance = { skinTexture = "MaleBody04", chestHair = false },
}))
assertEqual(visual.skin, "MaleBody04", "chest hair alters the descriptor cache key")

local actors = 0
local group = { getOrCreateLocation = function(self, slot)
    return { setAttachmentName = function(_, bone) self[slot] = bone end }
end }
AttachedLocationGroup = { new = function() return group end }
AttachedLocations = { getGroup = function()
    return { getLocation = function(_, slot)
        if slot == "Back" then return { getAttachmentName = function() return "back" end } end
    end }
end }
AttachedItems = { new = function(locations)
    return { group = locations, setItem = function(self, slot, item) self[slot] = item end }
end }
local fixtureBody = {
    setFemale = function(self, value) self.female = value end,
    getHumanVisual = function() return { copyFrom = function(_, from) assertEqual(from, visual) end } end,
    getItemVisuals = function() return {} end,
    setAttachedItems = function(self, items) self.attachments = items end,
}
IsoZombie = { new = function(cell) assertEqual(cell, nil); actors = actors + 1; return fixtureBody end }
function worn:getItemVisuals() end
local testWeapon = { type = "Base.Axe" }
assert(uprightPanel:setTarget(nil, { key = "held", previewHandItems = { primary = testWeapon } }))
assertEqual(uprightPanel.modelView.character, fixtureBody, "held preview binds the detached actor")
assertEqual(fixtureBody.attachments.primary, testWeapon, "primary preview uses the captured native item")
assertEqual(fixtureBody.attachments.group.primary, "Bip01_Prop1")
assertEqual(fixtureBody.attachments.group.secondary, "Bip01_Prop2")
assert(uprightPanel:setTarget(nil, {
    key = "weapon_pose", previewHandItems = { secondary = testWeapon }, previewWeaponPose = "handgun",
}))
assertEqual(uprightPanel.modelView.animSet, "player", "weapon stance uses native player animations")
assertEqual(uprightPanel.modelView.state, "aim", "held weapon renders in an aiming pose")
assertEqual(fixtureBody.attachments.primary, testWeapon, "weapon follows the aiming hand")
assert(uprightPanel:setWeaponPreviewAttacking(true))
assertEqual(uprightPanel.modelView.state, "ranged", "handgun uses the native ranged attack")
uprightPanel:refreshAnimationState(5000)
assertEqual(uprightPanel.modelView.state, "ranged", "generic portrait idle cannot interrupt an attack")
assert(uprightPanel:setWeaponPreviewAttacking(false))
assertEqual(uprightPanel.modelView.state, "aim", "the attack returns to ready stance")
local stowedItem = { type = "Base.Hammer" }
assert(uprightPanel:setTarget(nil, {
    key = "melee_pose", previewHandItems = { primary = testWeapon },
    previewStowedItems = { Back = stowedItem }, previewWeaponPose = "2handed",
}))
assertEqual(fixtureBody.attachments["stowed:Back"], stowedItem, "stowed gear remains visible while holding the weapon")
assertEqual(fixtureBody.attachments.group["stowed:Back"], "back", "stowed gear keeps its native bone")
assert(uprightPanel:setWeaponPreviewAttacking(true))
assertEqual(uprightPanel.modelView.state, "melee", "axe uses the native melee attack")
assert(uprightPanel:setTarget(nil, { key = "stowed", previewStowedItems = { Back = testWeapon } }))
assertEqual(fixtureBody.attachments.primary, nil, "stowed preview clears the hand")
assertEqual(fixtureBody.attachments.Back, testWeapon)
assertEqual(actors, 1, "switching equipment views reuses the detached actor")
assert(uprightPanel:setTarget(nil, { key = "regular" }))
assertEqual(uprightPanel.modelView.character, nil, "ordinary portrait returns to descriptor rendering")

print("psychopatz_portrait_smoke: ok")
