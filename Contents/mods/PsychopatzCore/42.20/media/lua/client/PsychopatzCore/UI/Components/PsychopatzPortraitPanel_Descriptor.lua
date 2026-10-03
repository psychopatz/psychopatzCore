local Support = require
    "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_DescriptorSupport"

local safeCall = Support.SafeCall

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
    if not humanVisual or type(color) ~= "table" or not ImmutableColor then return end
    local immutable = ImmutableColor.new(
        tonumber(color.r) or 0.2,
        tonumber(color.g) or 0.1,
        tonumber(color.b) or 0.1,
        tonumber(color.a) or 1
    )
    if not immutable then return end
    safeCall(humanVisual, "setHairColor", immutable)
    safeCall(humanVisual, "setBeardColor", immutable)
end

local function applySkinColor(humanVisual, color)
    if not humanVisual or type(color) ~= "table" or not ImmutableColor then
        return
    end
    local immutable = ImmutableColor.new(
        tonumber(color.r) or 0.2,
        tonumber(color.g) or 0.1,
        tonumber(color.b) or 0.1,
        tonumber(color.a) or 1
    )
    if immutable then safeCall(humanVisual, "setSkinColor", immutable) end
end

local function resolveBodyLocation(location)
    local raw = tostring(location or "")
    if raw == "" then return nil end
    if ItemBodyLocation and ItemBodyLocation.get
        and ResourceLocation and ResourceLocation.of
    then
        local separator = string.find(raw, ":", 1, true)
        if separator and (separator == 1 or separator == #raw) then return nil end
        return ItemBodyLocation.get(ResourceLocation.of(raw))
    end
    -- Compatibility fallback for older builds where WornItems accepted the
    -- legacy string location directly.
    return location
end

local function addWornItem(wornItems, fullType, explicitLocation, visualState)
    local item = Support.CreateItem(fullType)
    if not wornItems or not item then return false end
    local equipment = PNC and PNC.Equipment or nil
    if visualState and equipment and equipment.Internal
        and equipment.Internal.applyItemVisualState
    then
        pcall(equipment.Internal.applyItemVisualState, item, visualState)
    end
    local location = explicitLocation
    if not location or location == "" then
        local _, resolved = safeCall(item, "getBodyLocation")
        location = resolved
    end
    location = resolveBodyLocation(location)
    if not location or not wornItems.setItem then return false end
    wornItems:setItem(location, item)
    return true
end

local function buildDescriptor(spec)
    local key = Support.Key(spec)
    local cached = Support.Lookup(key)
    if cached then return cached, key end

    local descriptor = createSurvivorDescriptor()
    if not descriptor then return nil, key end
    local appearance = type(spec and spec.appearance) == "table" and spec.appearance or {}
    local wornSpec = Support.WornItems(spec)
    local wornVisuals = Support.WornVisuals(spec)
    safeCall(descriptor, "setFemale", spec and spec.isFemale == true)
    local _, humanVisual = safeCall(descriptor, "getHumanVisual")
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

    local _, wornItems = safeCall(descriptor, "getWornItems")
    if wornItems then
        safeCall(wornItems, "clear")
        if appearance.outfitMode == "item" and appearance.outfit then
            safeCall(descriptor, "dressInNamedOutfit", appearance.outfit)
        end
        local hasWornItem = false
        for _, _ in pairs(wornSpec) do hasWornItem = true break end
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
    Support.Store(key, descriptor)
    return descriptor, key
end

local function isRenderableCharacter(character)
    if not character then return false end
    local ok, visual = safeCall(character, "getHumanVisual")
    return ok and visual ~= nil
end

return {
    Model = Support.Model,
    Build = buildDescriptor,
    Key = Support.Key,
    IsRenderableCharacter = isRenderableCharacter,
    CacheSize = Support.Size,
}
