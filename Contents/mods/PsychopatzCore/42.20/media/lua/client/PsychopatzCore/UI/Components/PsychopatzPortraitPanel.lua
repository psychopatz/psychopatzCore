require "ISUI/ISPanel"
require "ISUI/ISUI3DModel"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local CRT_TEXTURE_PATH = "media/ui/Effects/crt.png"

local function normalizeScreenVariant(value)
    if value == nil then return nil end
    value = string.lower(tostring(value))
    if value == "crt" or value == "screen" then return "crt" end
    if value == "subtle" or value == "default" or value == "clean" then
        return "subtle"
    end
    if value == "none" or value == "off" then return "none" end
    return nil
end

PsychopatzPortraitPanel = ISPanel:derive("PsychopatzPortraitPanel")
UI.PortraitPanel = PsychopatzPortraitPanel

local PsychopatzPortraitModel = ISUI3DModel:derive(
    "PsychopatzPortraitModel"
)

function PsychopatzPortraitModel:prerender()
    if self.animateEnabled == false then
        if self.javaObject then self.javaObject:setAnimate(false) end
        return
    end
    ISUI3DModel.prerender(self)
end

local descriptorCache = {}
local descriptorClock = 0
local DESCRIPTOR_CACHE_LIMIT = 64
local FACE_LOCATION_HINTS = {
    "hat", "head", "eyes", "glasses", "mask", "neck", "scarf",
    "ears", "earring", "nose",
}

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

local function stableValueSignature(value, depth)
    local keys = {}
    local parts = {}
    local index
    local key
    depth = tonumber(depth) or 0
    if type(value) ~= "table" then return tostring(value or "") end
    if depth > 4 then return "[depth]" end
    for key, _ in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    for index = 1, #keys do
        key = keys[index]
        parts[#parts + 1] = tostring(key) .. "="
            .. stableValueSignature(value[key], depth + 1)
    end
    return "{" .. table.concat(parts, ";") .. "}"
end

local function isFaceLocation(location)
    local normalized = string.lower(tostring(location or ""))
    local i
    for i = 1, #FACE_LOCATION_HINTS do
        if string.find(normalized, FACE_LOCATION_HINTS[i], 1, true) then
            return true
        end
    end
    return false
end

local function portraitWornItems(spec)
    local equipment = type(spec and spec.equipment) == "table"
        and spec.equipment or {}
    local worn = type(equipment.worn) == "table" and equipment.worn or {}
    local filtered
    local location
    local fullType
    if spec and (spec.includeCurrentClothing == true
        or spec.clothingMode == "current")
    then
        return worn
    end
    if spec and spec.faceOnly ~= true then
        return worn
    end
    filtered = {}
    for location, fullType in pairs(worn) do
        if isFaceLocation(location) then
            filtered[location] = fullType
        end
    end
    return filtered
end

local function portraitWornVisuals(spec)
    local equipment = type(spec and spec.equipment) == "table"
        and spec.equipment or {}
    return type(equipment.wornVisuals) == "table"
        and equipment.wornVisuals or {}
end

local function descriptorKey(spec)
    local appearance = type(spec and spec.appearance) == "table" and spec.appearance or {}
    local hairColor = type(appearance.hairColor) == "table" and appearance.hairColor or {}
    local skinColor = type(appearance.skinColor) == "table" and appearance.skinColor or {}
    return table.concat({
        tostring(spec and spec.id or ""),
        tostring(spec and spec.identitySeed or 1),
        tostring(spec and spec.isFemale == true),
        tostring(spec and spec.faceOnly == true),
        tostring(appearance.outfitMode or ""),
        tostring(appearance.outfit or ""),
        tostring(appearance.skinTexture or ""),
        tostring(skinColor.r or ""),
        tostring(skinColor.g or ""),
        tostring(skinColor.b or ""),
        tostring(appearance.hairModel or ""),
        tostring(appearance.beardModel or ""),
        tostring(hairColor.r or ""),
        tostring(hairColor.g or ""),
        tostring(hairColor.b or ""),
        spec and spec.faceOnly == true
            and spec.includeCurrentClothing ~= true
            and "" or stableArraySignature(appearance.outfitItems),
        stableValueSignature(appearance.outfitItemSpecs),
        stableMapSignature(portraitWornItems(spec)),
        stableValueSignature(portraitWornVisuals(spec)),
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

local function applySkinColor(humanVisual, color)
    local immutable
    if not humanVisual or type(color) ~= "table" or not ImmutableColor then
        return
    end
    local ok
    ok, immutable = pcall(
        ImmutableColor.new,
        tonumber(color.r) or 0.2,
        tonumber(color.g) or 0.1,
        tonumber(color.b) or 0.1,
        tonumber(color.a) or 1
    )
    if ok and immutable then
        safeCall(humanVisual, "setSkinColor", immutable)
    end
end

local function resolveBodyLocation(location)
    local ok
    local resource
    local resolved
    if location == nil or tostring(location) == "" then return nil end
    if ItemBodyLocation and ItemBodyLocation.get
        and ResourceLocation and ResourceLocation.of
    then
        ok, resource = pcall(ResourceLocation.of, tostring(location))
        if not ok or not resource then return nil end
        ok, resolved = pcall(ItemBodyLocation.get, resource)
        return ok and resolved or nil
    end
    -- Compatibility fallback for older builds where WornItems accepted the
    -- legacy string location directly.
    return location
end

local function addWornItem(wornItems, fullType, explicitLocation, visualState)
    local item = createItem(fullType)
    local location
    local equipment
    if not wornItems or not item then return false end
    equipment = PNC and PNC.Equipment or nil
    if visualState and equipment and equipment.Internal
        and equipment.Internal.applyItemVisualState
    then
        pcall(
            equipment.Internal.applyItemVisualState,
            item,
            visualState
        )
    end
    location = explicitLocation
    if not location or location == "" then
        local _, resolved = safeCall(item, "getBodyLocation")
        location = resolved
    end
    if not location or location == "" then return false end
    location = resolveBodyLocation(location)
    if not location then return false end
    if wornItems.setItem then
        local ok = pcall(wornItems.setItem, wornItems, location, item)
        return ok
    end
    return false
end

local function buildDescriptor(spec)
    local key = descriptorKey(spec)
    local cached = descriptorCache[key]
    local descriptor
    local appearance
    local wornSpec
    local humanVisual
    local wornItems
    local wornVisuals
    local hasWornItem
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
    wornSpec = portraitWornItems(spec)
    wornVisuals = portraitWornVisuals(spec)
    safeCall(descriptor, "setFemale", spec and spec.isFemale == true)
    local _, resolvedVisual = safeCall(descriptor, "getHumanVisual")
    humanVisual = resolvedVisual
    if humanVisual then
        safeCall(humanVisual, "setSkinTextureName", appearance.skinTexture
            or (spec and spec.isFemale and "FemaleBody01" or "MaleBody01"))
        applySkinColor(humanVisual, appearance.skinColor)
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
        if appearance.outfitMode == "item" and appearance.outfit then
            safeCall(descriptor, "dressInNamedOutfit", appearance.outfit)
        end
        hasWornItem = false
        for _, _ in pairs(wornSpec) do
            hasWornItem = true
            break
        end
        if spec and (spec.faceOnly ~= true or not hasWornItem) then
            if type(appearance.outfitItemSpecs) == "table"
                and #appearance.outfitItemSpecs > 0
            then
                for i = 1, #appearance.outfitItemSpecs do
                    local itemSpec = appearance.outfitItemSpecs[i]
                    local itemType = itemSpec and itemSpec.type
                    local itemState = itemSpec and itemSpec.itemState
                    local visualState
                    if PNC and PNC.Equipment
                        and PNC.Equipment.VisualStateFromItemState
                    then
                        visualState = PNC.Equipment.VisualStateFromItemState(
                            itemState, itemType)
                    end
                    if itemType then
                        addWornItem(wornItems, itemType,
                            itemSpec.wornSlot, visualState)
                    end
                end
            else
                for i = 1, #(type(appearance.outfitItems) == "table"
                    and appearance.outfitItems or {}) do
                    addWornItem(wornItems, appearance.outfitItems[i], nil)
                end
            end
        end
        for location, fullType in pairs(wornSpec) do
            addWornItem(wornItems, fullType, location, wornVisuals[location])
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
    -- This component draws its optional background and border itself below.
    -- Disable ISPanel's default pass so transparent portraits do not retain
    -- the stock one-pixel edge and opaque portraits are not drawn twice.
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    self.avatarBackground = self.showBackground
        and getTexture
        and getTexture("media/ui/avatarBackgroundWhite.png")
        or nil
    self.crtTexture = getTexture and getTexture(CRT_TEXTURE_PATH) or nil
end

function PsychopatzPortraitPanel:createChildren()
    ISPanel.createChildren(self)
    self:ensureModelView()
end

function PsychopatzPortraitPanel:ensureModelView()
    local padding = tonumber(self.padding) or 2
    if self.modelView then return self.modelView end
    self.modelView = PsychopatzPortraitModel:new(
        padding,
        padding,
        math.max(1, self.width - padding * 2),
        math.max(1, self.height - padding * 2)
    )
    self.modelView:initialise()
    self.modelView:instantiate()
    self.modelView.animateEnabled = self.animate ~= false
    self.modelView:setAnchorLeft(true)
    self.modelView:setAnchorRight(true)
    self.modelView:setAnchorTop(true)
    self.modelView:setAnchorBottom(true)
    self:addChild(self.modelView)
    -- A false anim-set value deliberately leaves the model on the engine's
    -- normal human avatar set. Descriptor-backed survivor portraits use this
    -- to avoid inheriting the slouched zombie posture.
    if self.animSetName then
        pcall(function() self.modelView:setAnimSetName(self.animSetName) end)
    end
    self:applyViewState()
    self:applyModelVisibility(self.contentOpacity)
    return self.modelView
end

function PsychopatzPortraitPanel:applyModelVisibility(value)
    local alpha = math.max(0, math.min(1, tonumber(value) or 1))
    local model = self.modelView
    if not model then return end
    local visible = alpha > 0.001
    if self.modelVisibilityApplied ~= visible then
        -- Java Engine Ground Truth: UI3DModel inherits UIElement.setVisible
        -- but exposes no setAlpha or setColor method in Build 42.20.
        model:setVisible(visible)
        self.modelVisibilityApplied = visible
    end
end

function PsychopatzPortraitPanel:setContentOpacity(value)
    self.contentOpacity = math.max(0, math.min(1, tonumber(value) or 1))
    self:applyModelVisibility(self.contentOpacity)
end

function PsychopatzPortraitPanel:applyViewState()
    local model = self.modelView
    if not model or not model.javaObject then return end
    model.animateEnabled = self.animate ~= false
    pcall(function() model:setState(self.stateName or "idle") end)
    pcall(function() model:setDirection(self.direction or (IsoDirections and IsoDirections.S)) end)
    pcall(function() model:setIsometric(self.isometric == true) end)
    pcall(function() model:setDoRandomExtAnimations(false) end)
    pcall(function() model:setZoom(tonumber(self.zoom) or 14) end)
    pcall(function() model:setXOffset(tonumber(self.xOffset) or 0) end)
    pcall(function() model:setYOffset(tonumber(self.yOffset) or -0.85) end)
    if self.portraitAnimationEnabled then
        self:applyAnimationVariables()
    else
        pcall(function() model:setVariable("bMoving", "false") end)
        pcall(function() model:setVariable("isMoving", "false") end)
        pcall(function() model:setVariable("Speed", "0.0") end)
        pcall(function() model:setVariable("MovementSpeed", "0.0") end)
    end
    pcall(function() model.javaObject:setAnimate(self.animate ~= false) end)
end

function PsychopatzPortraitPanel:applyAnimationVariables(state)
    local model = self.modelView
    if not model or not model.javaObject then return end
    state = tostring(state or self.portraitAnimationState or "idle")
    pcall(function() model:setVariable("PNCPortrait", "true") end)
    pcall(function() model:setVariable("PNCPortraitState", state) end)
    pcall(function() model:setVariable("bMoving", "false") end)
    pcall(function() model:setVariable("isMoving", "false") end)
    pcall(function() model:setVariable("Speed", "0.0") end)
    pcall(function() model:setVariable("MovementSpeed", "0.0") end)
    pcall(function() model:setVariable("WalkSpeed", "0.0") end)
    pcall(function() model:setVariable("RunSpeed", "0.0") end)
    pcall(function() model:setState("idle") end)
end

function PsychopatzPortraitPanel:setScreenVariant(variant)
    self.screenVariant = normalizeScreenVariant(variant)
end

function PsychopatzPortraitPanel:getScreenVariant()
    return self.screenVariant or "subtle"
end

function PsychopatzPortraitPanel:refreshAnimationState(current)
    local now = tonumber(current)
        or (getTimeInMillis and getTimeInMillis() or 0)
    local state = "idle"
    if self.portraitAnimationEnabled ~= true then return end
    if self.portraitAnimationUntil
        and now < self.portraitAnimationUntil
    then
        state = self.portraitAnimationState or "idle"
    elseif self.speechAnimationUntil and now < self.speechAnimationUntil then
        state = "speech"
    end
    if self.portraitAnimationUntil and now >= self.portraitAnimationUntil then
        self.portraitAnimationUntil = nil
        self.portraitAnimationState = nil
    end
    if self.modelView and self.animationAppliedState ~= state then
        self.animationAppliedState = state
        self:applyAnimationVariables(state)
    end
end

-- Conversation views can use this lightweight pulse without owning or
-- replacing the portrait renderer. It keeps the reusable model component
-- suitable for map cards and other static consumers.
function PsychopatzPortraitPanel:pulseSpeech(text)
    local duration = math.max(280, math.min(1200, #tostring(text or "") * 18))
    local current = getTimeInMillis and getTimeInMillis() or 0
    self.speechPulseStartedAt = current
    self.speechPulseUntil = current + duration
    if self.portraitAnimationEnabled then
        self.speechAnimationUntil = current + duration
    end
    self:refreshAnimationState(current)
end

function PsychopatzPortraitPanel:playAnimation(animationID, durationMs)
    local animation = tostring(animationID or "")
    local state
    local current
    if self.portraitAnimationEnabled ~= true then return false end
    if animation == "greeting.wavehi" or animation == "wavehi" then
        state = "wavehi"
    elseif animation == "reaction.thumbsdown" or animation == "thumbsdown" then
        state = "thumbsdown"
    else
        return false
    end
    current = getTimeInMillis and getTimeInMillis() or 0
    self.portraitAnimationState = state
    self.portraitAnimationUntil = current
        + math.max(400, tonumber(durationMs) or 2200)
    self:refreshAnimationState(current)
    return true
end

function PsychopatzPortraitPanel:setTarget(character, spec, force)
    local key
    local descriptor
    local descriptorFirst
    spec = type(spec) == "table" and spec or {}
    if self.faceOnly == true and spec.faceOnly == nil then
        spec.faceOnly = true
    end
    descriptorFirst = spec.preferDescriptor == true
    key = table.concat({
        tostring(spec.key or descriptorKey(spec)),
        tostring(descriptorFirst and "descriptor" or (character or "descriptor")),
    }, "|")
    if force ~= true and self.targetKey == key then return true end
    self.targetKey = key
    self.targetCharacter = character
    self.targetSpec = spec
    self.speechAnimationUntil = nil
    self.portraitAnimationUntil = nil
    self.portraitAnimationState = nil
    self.animationAppliedState = nil
    local model = self:ensureModelView()
    if not model then return false end
    if model.javaObject and model.javaObject.clearVariables then
        pcall(model.javaObject.clearVariables, model.javaObject)
    end
    if not descriptorFirst and isRenderableCharacter(character) then
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
    local padding = tonumber(self.padding) or 2
    Layout.SetBounds(self, x, y, width, height)
    if self.modelView then
        Layout.SetBounds(
            self.modelView,
            padding,
            padding,
            math.max(1, width - padding * 2),
            math.max(1, height - padding * 2)
        )
    end
end

function PsychopatzPortraitPanel:prerender()
    local padding = tonumber(self.padding) or 2
    local current = getTimeInMillis and getTimeInMillis() or 0
    self:applyModelVisibility(self.contentOpacity)
    if (tonumber(self.contentOpacity) or 1) <= 0.001 then return end
    self:refreshAnimationState(current)
    if self.modelView and self.speechPulseUntil
        and current < self.speechPulseUntil
    then
        local phase = (current - (self.speechPulseStartedAt or current)) / 90
        local offset = (tonumber(self.yOffset) or -0.85) + math.sin(phase) * 0.025
        pcall(function() self.modelView:setYOffset(offset) end)
    elseif self.modelView and self.speechPulseUntil then
        self.speechPulseUntil = nil
        pcall(function()
            self.modelView:setYOffset(tonumber(self.yOffset) or -0.85)
        end)
    end
    ISPanel.prerender(self)
    if self.showBackground then
        if self.avatarBackground then
            self:drawTextureScaled(
                self.avatarBackground,
                padding,
                padding,
                math.max(1, self.width - padding * 2),
                math.max(1, self.height - padding * 2),
                1,
                0.4,
                0.4,
                0.4
            )
        else
            self:drawRect(
                padding,
                padding,
                math.max(1, self.width - padding * 2),
                math.max(1, self.height - padding * 2),
                1,
                0.28,
                0.28,
                0.28
            )
        end
    end
    if self.showBorder then
        self:drawRectBorder(
            0,
            0,
            self.width,
            self.height,
            1,
            0.3,
            0.3,
            0.3
        )
    end
end

function PsychopatzPortraitPanel:render()
    -- UI3DModel can retain its viewport clear surface even after the model
    -- itself is hidden.  A fully transparent content layer must skip the
    -- child renderer as well, otherwise it leaves an opaque black rectangle.
    if (tonumber(self.contentOpacity) or 1) <= 0.001 then return end
    local padding = tonumber(self.padding) or 2
    local width = math.max(1, self.width - padding * 2)
    local height = math.max(1, self.height - padding * 2)
    local variant = self:getScreenVariant()
    local alpha
    local time
    local offsetX = padding
    local offsetY = padding

    ISPanel.render(self)
    if variant == "none" or not self.crtTexture then return end
    if variant == "crt" then
        time = tonumber(getTimeInMillis and getTimeInMillis() or 0) or 0
        alpha = tonumber(self.crtOpacity) or 0.52
        alpha = alpha * (0.91 + math.sin(time / 83) * 0.055
            + math.sin(time / 211) * 0.035)
        offsetX = offsetX + math.floor(math.sin(time / 127) * 1.5)
        offsetY = offsetY + math.floor(math.sin(time / 173) * 1.0)
    else
        alpha = tonumber(self.subtleOpacity) or 0.18
    end
    alpha = alpha * (tonumber(self.contentOpacity) or 1)
    alpha = math.max(0, math.min(1, alpha))
    self:drawTextureScaled(
        self.crtTexture,
        offsetX,
        offsetY,
        width,
        height,
        alpha,
        1,
        1,
        1
    )
    if variant == "crt" then
        local scanY = padding + math.floor((time / 7) % height)
        self:drawRect(padding, scanY, width, 2, alpha * 0.24,
            0.42, 0.88, 0.78)
    end
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
    o.portraitAnimationEnabled = options.portraitAnimation == true
    o.faceOnly = options.faceOnly == true
    o.showBackground = options.showBackground ~= false
    o.showBorder = options.showBorder ~= false
    o.padding = math.max(0, tonumber(options.padding) or 2)
    o.screenVariant = normalizeScreenVariant(options.screenVariant)
    o.subtleOpacity = math.max(0, math.min(1,
        tonumber(options.subtleOpacity) or 0.18))
    o.crtOpacity = math.max(0, math.min(1,
        tonumber(options.crtOpacity) or 0.52))
    o.contentOpacity = 1
    o.modelVisibilityApplied = nil
    if options.animSetName == nil then
        o.animSetName = "zombie"
    else
        o.animSetName = options.animSetName
    end
    o.stateName = options.stateName or "idle"
    return o
end

function UI.GetPortraitDescriptorCacheSize()
    local count = 0
    for _, _ in pairs(descriptorCache) do
        count = count + 1
    end
    return count
end

return PsychopatzPortraitPanel
