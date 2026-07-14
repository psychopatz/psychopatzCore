require "ISUI/ISPanel"
require "ISUI/ISUI3DModel"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout

PsychopatzPortraitPanel = ISPanel:derive("PsychopatzPortraitPanel")
UI.PortraitPanel = PsychopatzPortraitPanel

local descriptorCache = {}
local descriptorClock = 0
local DESCRIPTOR_CACHE_LIMIT = 64

local function safeCall(target, methodName, ...)
    local method = target and target[methodName] or nil
    if type(method) ~= "function" then return false, nil end
    local ok, result = pcall(method, target, ...)
    return ok, result
end

local function createItem(fullType)
    if not fullType or fullType == "" then return nil end
    if instanceItem then
        local ok, item = pcall(instanceItem, fullType)
        if ok and item then return item end
    end
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if ok and item then return item end
    end
    return nil
end

local function stableMapSignature(values)
    local keys = {}
    local parts = {}
    local key
    local i
    for key, _ in pairs(type(values) == "table" and values or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)
    for i = 1, #keys do
        parts[#parts + 1] = tostring(keys[i]) .. "=" .. tostring(values[keys[i]] or "")
    end
    return table.concat(parts, ";")
end

local function stableArraySignature(values)
    local parts = {}
    local i
    for i = 1, #(type(values) == "table" and values or {}) do
        parts[#parts + 1] = tostring(values[i] or "")
    end
    return table.concat(parts, ";")
end

local function descriptorKey(spec)
    local appearance = type(spec and spec.appearance) == "table" and spec.appearance or {}
    local equipment = type(spec and spec.equipment) == "table" and spec.equipment or {}
    local hairColor = type(appearance.hairColor) == "table" and appearance.hairColor or {}
    return table.concat({
        tostring(spec and spec.id or ""),
        tostring(spec and spec.identitySeed or 1),
        tostring(spec and spec.isFemale == true),
        tostring(appearance.skinTexture or ""),
        tostring(appearance.hairModel or ""),
        tostring(appearance.beardModel or ""),
        tostring(hairColor.r or ""),
        tostring(hairColor.g or ""),
        tostring(hairColor.b or ""),
        stableArraySignature(appearance.outfitItems),
        stableMapSignature(equipment.worn),
    }, "|")
end

local function cacheDescriptor(key, descriptor)
    local count = 0
    local oldestKey
    local oldestAt
    local cacheKey
    local entry
    descriptorClock = descriptorClock + 1
    descriptorCache[key] = { descriptor = descriptor, touchedAt = descriptorClock }
    for cacheKey, entry in pairs(descriptorCache) do
        count = count + 1
        if oldestAt == nil or (tonumber(entry.touchedAt) or 0) < oldestAt then
            oldestAt = tonumber(entry.touchedAt) or 0
            oldestKey = cacheKey
        end
    end
    if count > DESCRIPTOR_CACHE_LIMIT and oldestKey then
        descriptorCache[oldestKey] = nil
    end
end

local function createSurvivorDescriptor()
    local ok
    local descriptor
    if not SurvivorFactory or not SurvivorFactory.CreateSurvivor then return nil end
    if SurvivorType and SurvivorType.Neutral then
        ok, descriptor = pcall(SurvivorFactory.CreateSurvivor, SurvivorType.Neutral, false)
        if ok and descriptor then return descriptor end
    end
    ok, descriptor = pcall(SurvivorFactory.CreateSurvivor)
    return ok and descriptor or nil
end

local function applyColor(humanVisual, color)
    local immutable
    if not humanVisual or type(color) ~= "table" or not ImmutableColor then return end
    local ok
    ok, immutable = pcall(
        ImmutableColor.new,
        tonumber(color.r) or 0.2,
        tonumber(color.g) or 0.1,
        tonumber(color.b) or 0.1,
        tonumber(color.a) or 1
    )
    if not ok or not immutable then return end
    safeCall(humanVisual, "setHairColor", immutable)
    safeCall(humanVisual, "setBeardColor", immutable)
end

local function addWornItem(wornItems, fullType, explicitLocation)
    local item = createItem(fullType)
    local location
    if not wornItems or not item then return false end
    location = explicitLocation
    if not location or location == "" then
        local _, resolved = safeCall(item, "getBodyLocation")
        location = resolved
    end
    if not location or location == "" then return false end
    if wornItems.setItem then
        local ok = pcall(wornItems.setItem, wornItems, tostring(location), item)
        return ok
    end
    return false
end

local function buildDescriptor(spec)
    local key = descriptorKey(spec)
    local cached = descriptorCache[key]
    local descriptor
    local appearance
    local equipment
    local humanVisual
    local wornItems
    local location
    local fullType
    local i
    if cached and cached.descriptor then
        cached.touchedAt = descriptorClock + 1
        descriptorClock = cached.touchedAt
        return cached.descriptor, key
    end

    descriptor = createSurvivorDescriptor()
    if not descriptor then return nil, key end
    appearance = type(spec and spec.appearance) == "table" and spec.appearance or {}
    equipment = type(spec and spec.equipment) == "table" and spec.equipment or {}
    safeCall(descriptor, "setFemale", spec and spec.isFemale == true)
    local _, resolvedVisual = safeCall(descriptor, "getHumanVisual")
    humanVisual = resolvedVisual
    if humanVisual then
        safeCall(humanVisual, "setSkinTextureName", appearance.skinTexture
            or (spec and spec.isFemale and "FemaleBody01" or "MaleBody01"))
        if appearance.hairModel then safeCall(humanVisual, "setHairModel", appearance.hairModel) end
        safeCall(humanVisual, "setBeardModel", spec and spec.isFemale and "" or (appearance.beardModel or ""))
        applyColor(humanVisual, appearance.hairColor)
        safeCall(humanVisual, "removeBlood")
        safeCall(humanVisual, "removeDirt")
    end

    local _, resolvedWorn = safeCall(descriptor, "getWornItems")
    wornItems = resolvedWorn
    if wornItems then
        safeCall(wornItems, "clear")
        for i = 1, #(type(appearance.outfitItems) == "table" and appearance.outfitItems or {}) do
            addWornItem(wornItems, appearance.outfitItems[i], nil)
        end
        for location, fullType in pairs(type(equipment.worn) == "table" and equipment.worn or {}) do
            addWornItem(wornItems, fullType, location)
        end
    end
    safeCall(descriptor, "resetModel")
    cacheDescriptor(key, descriptor)
    return descriptor, key
end

local function isRenderableCharacter(character)
    if not character then return false end
    local ok, visual = safeCall(character, "getHumanVisual")
    return ok and visual ~= nil
end

function PsychopatzPortraitPanel:initialise()
    ISPanel.initialise(self)
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    self.avatarBackground = getTexture and getTexture("media/ui/avatarBackgroundWhite.png") or nil
end

function PsychopatzPortraitPanel:createChildren()
    ISPanel.createChildren(self)
    self:ensureModelView()
end

function PsychopatzPortraitPanel:ensureModelView()
    if self.modelView then return self.modelView end
    self.modelView = ISUI3DModel:new(2, 2, math.max(1, self.width - 4), math.max(1, self.height - 4))
    self.modelView:initialise()
    self.modelView:instantiate()
    self.modelView:setAnchorLeft(true)
    self.modelView:setAnchorRight(true)
    self.modelView:setAnchorTop(true)
    self.modelView:setAnchorBottom(true)
    self:addChild(self.modelView)
    pcall(function() self.modelView:setAnimSetName(self.animSetName or "zombie") end)
    self:applyViewState()
    return self.modelView
end

function PsychopatzPortraitPanel:applyViewState()
    local model = self.modelView
    if not model or not model.javaObject then return end
    pcall(function() model:setState(self.stateName or "idle") end)
    pcall(function() model:setDirection(self.direction or (IsoDirections and IsoDirections.S)) end)
    pcall(function() model:setIsometric(self.isometric == true) end)
    pcall(function() model:setDoRandomExtAnimations(false) end)
    pcall(function() model:setZoom(tonumber(self.zoom) or 14) end)
    pcall(function() model:setXOffset(tonumber(self.xOffset) or 0) end)
    pcall(function() model:setYOffset(tonumber(self.yOffset) or -0.85) end)
    pcall(function() model:setVariable("bMoving", "false") end)
    pcall(function() model:setVariable("isMoving", "false") end)
    pcall(function() model:setVariable("Speed", "0.0") end)
    pcall(function() model:setVariable("MovementSpeed", "0.0") end)
    pcall(function() model.javaObject:setAnimate(self.animate ~= false) end)
end

function PsychopatzPortraitPanel:setTarget(character, spec, force)
    local key
    local descriptor
    spec = type(spec) == "table" and spec or {}
    key = tostring(spec.key or descriptorKey(spec)) .. "|" .. tostring(character or "descriptor")
    if force ~= true and self.targetKey == key then return true end
    self.targetKey = key
    self.targetCharacter = character
    self.targetSpec = spec
    local model = self:ensureModelView()
    if not model then return false end
    if model.javaObject and model.javaObject.clearVariables then
        pcall(model.javaObject.clearVariables, model.javaObject)
    end
    if isRenderableCharacter(character) then
        pcall(function() model:setCharacter(character) end)
        self.targetMode = "character"
    else
        descriptor = buildDescriptor(spec)
        if descriptor then
            pcall(function() model:setCharacter(nil) end)
            pcall(function() model:setSurvivorDesc(descriptor) end)
            self.targetMode = "descriptor"
        elseif spec.outfit then
            pcall(function() model:setOutfitName(spec.outfit, spec.isFemale == true, false) end)
            self.targetMode = "outfit"
        else
            return false
        end
    end
    self:applyViewState()
    return true
end

function PsychopatzPortraitPanel:setPortraitBounds(x, y, width, height)
    Layout.SetBounds(self, x, y, width, height)
    if self.modelView then
        Layout.SetBounds(self.modelView, 2, 2, math.max(1, width - 4), math.max(1, height - 4))
    end
end

function PsychopatzPortraitPanel:prerender()
    ISPanel.prerender(self)
    if self.avatarBackground then
        self:drawTextureScaled(self.avatarBackground, 2, 2, math.max(1, self.width - 4), math.max(1, self.height - 4), 1, 0.4, 0.4, 0.4)
    else
        self:drawRect(2, 2, math.max(1, self.width - 4), math.max(1, self.height - 4), 1, 0.28, 0.28, 0.28)
    end
    self:drawRectBorder(0, 0, self.width, self.height, 1, 0.3, 0.3, 0.3)
end

function PsychopatzPortraitPanel:new(x, y, width, height, options)
    local o = ISPanel:new(x, y, width, height)
    options = options or {}
    setmetatable(o, self)
    self.__index = self
    o.zoom = tonumber(options.zoom) or 14
    o.xOffset = tonumber(options.xOffset) or 0
    o.yOffset = tonumber(options.yOffset) or -0.85
    o.direction = options.direction or (IsoDirections and IsoDirections.S)
    o.isometric = options.isometric == true
    o.animate = options.animate ~= false
    o.animSetName = options.animSetName or "zombie"
    o.stateName = options.stateName or "idle"
    return o
end

return PsychopatzPortraitPanel
