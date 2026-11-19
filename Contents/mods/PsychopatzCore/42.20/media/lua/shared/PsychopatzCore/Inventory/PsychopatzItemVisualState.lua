-- Native ItemVisual state and its portable itemState fields.
local VisualState = {}

local function readColor(r, g, b)
    if r == nil and g == nil and b == nil then return nil end
    return { r = tonumber(r), g = tonumber(g), b = tonumber(b) }
end

local function readVisualValue(visual, methodName, ...)
    local method
    local ok
    local value
    if not visual then return nil end
    method = visual[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, visual, ...)
    return ok and value or nil
end

function VisualState.Capture(item, fullType)
    local visual
    local clothingItem
    local tint
    local hue
    local modelIndex
    local customColor
    local color
    if not item then return nil end
    visual = item.getVisual and item:getVisual() or nil
    clothingItem = item.getClothingItem
        and item:getClothingItem() or nil
    if visual and clothingItem and clothingItem.isReady and clothingItem:isReady() then
        -- The no-argument accessors return unresolved indices until the
        -- engine has selected from the loaded asset.
        hue = tonumber(readVisualValue(visual, "getHue", clothingItem))
        readVisualValue(visual, "getBaseTexture", clothingItem)
        readVisualValue(visual, "getTextureChoice", clothingItem)
    end
    if visual then
        hue = hue or tonumber(readVisualValue(visual, "getHue"))
        -- The clothing overload returns the custom RGB whenever it is set.
        -- Keep the underlying tint separate if the visual already owns one.
        tint = readVisualValue(visual, "getTint")
        if not tint and clothingItem then
            tint = readVisualValue(visual, "getTint", clothingItem)
        end
    end
    modelIndex = item.getModelIndex
        and tonumber(item:getModelIndex()) or nil
    customColor = item.isCustomColor
        and item:isCustomColor() == true or false
    if customColor and item.getR and item.getG and item.getB then
        color = readColor(item:getR(), item:getG(), item:getB())
    else
        color = readColor(
            item.getColorRed and item:getColorRed(),
            item.getColorGreen and item:getColorGreen(),
            item.getColorBlue and item:getColorBlue())
    end
    return {
        fullType = fullType
            or item.getFullType
                and tostring(item:getFullType())
            or nil,
        hue = hue and hue >= -1 and hue <= 1 and hue or nil,
        baseTexture = visual and tonumber(readVisualValue(
            visual, "getBaseTexture"
        )) or nil,
        textureChoice = visual and tonumber(readVisualValue(
            visual, "getTextureChoice"
        )) or nil,
        decal = visual and readVisualValue(
            visual, "getDecal", clothingItem
        ) or nil,
        tint = tint and {
            r = tonumber(tint:getRedFloat()),
            g = tonumber(tint:getGreenFloat()),
            b = tonumber(tint:getBlueFloat()),
        } or nil,
        modelIndex = modelIndex,
        customColor = customColor,
        color = color,
    }
end

function VisualState.Read(state, fullType)
    if type(state) ~= "table" or (fullType and state.visualFullType
        and tostring(state.visualFullType) ~= tostring(fullType))
    then
        return nil
    end
    local tint = readColor(state.visualTintR, state.visualTintG, state.visualTintB)
    local color = readColor(state.visualColorR, state.visualColorG, state.visualColorB)
    if not tint and not color and state.visualBaseTexture == nil and state.visualHue == nil
        and state.visualTextureChoice == nil and state.visualDecal == nil
        and state.visualModelIndex == nil and state.visualCustomColor == nil
    then
        return nil
    end
    return {
        fullType = state.visualFullType or fullType,
        baseTexture = tonumber(state.visualBaseTexture),
        hue = tonumber(state.visualHue),
        textureChoice = tonumber(state.visualTextureChoice),
        decal = state.visualDecal ~= nil and tostring(state.visualDecal) or nil,
        tint = tint,
        modelIndex = tonumber(state.visualModelIndex),
        customColor = state.visualCustomColor,
        color = color,
    }
end

function VisualState.Write(state, visual, fullType)
    if type(state) ~= "table" or type(visual) ~= "table" then return false end
    local tint, color = visual.tint, visual.color
    local visualType = visual.fullType or fullType
    state.visualFullType = visualType and tostring(visualType) or nil
    state.visualBaseTexture = tonumber(visual.baseTexture)
    state.visualHue = tonumber(visual.hue)
    state.visualTextureChoice = tonumber(visual.textureChoice)
    state.visualDecal = visual.decal ~= nil and tostring(visual.decal) or nil
    state.visualTintR = tint and tonumber(tint.r) or nil
    state.visualTintG = tint and tonumber(tint.g) or nil
    state.visualTintB = tint and tonumber(tint.b) or nil
    state.visualModelIndex = tonumber(visual.modelIndex)
    state.visualCustomColor = nil
    if type(visual.customColor) == "boolean" then
        state.visualCustomColor = visual.customColor
    end
    state.visualColorR = color and tonumber(color.r) or nil
    state.visualColorG = color and tonumber(color.g) or nil
    state.visualColorB = color and tonumber(color.b) or nil
    return true
end

function VisualState.Apply(item, visualState)
    local visual
    local applied = false
    if not item or type(visualState) ~= "table" then
        return false
    end
    if visualState.fullType ~= nil and item.getFullType
        and tostring(visualState.fullType) ~= tostring(item:getFullType())
    then
        return false
    end
    if visualState.modelIndex ~= nil
        and item.setModelIndex
    then
        item:setModelIndex(
            math.floor(tonumber(visualState.modelIndex) or -1)
        )
        applied = true
    end
    if visualState.color then
        if item.setColorRed and visualState.color.r ~= nil then
            item:setColorRed(tonumber(visualState.color.r) or 1)
            applied = true
        end
        if item.setColorGreen and visualState.color.g ~= nil then
            item:setColorGreen(tonumber(visualState.color.g) or 1)
            applied = true
        end
        if item.setColorBlue and visualState.color.b ~= nil then
            item:setColorBlue(tonumber(visualState.color.b) or 1)
            applied = true
        end
        if visualState.customColor and item.setColor and Color then
            -- ItemVisual:getTint reads InventoryItem:getR/G/B for custom
            -- colors. The separate color channel setters do not update it.
            item:setColor(Color.new(
                tonumber(visualState.color.r) or (item.getR and item:getR()) or 1,
                tonumber(visualState.color.g) or (item.getG and item:getG()) or 1,
                tonumber(visualState.color.b) or (item.getB and item:getB()) or 1, 1))
        end
        if item.setCustomColor then
            item:setCustomColor(visualState.customColor == true)
        end
    end
    visual = item.getVisual and item:getVisual() or nil
    if not visual then return applied end
    if visualState.hue ~= nil and visual.setHue then visual:setHue(visualState.hue) end
    local clothing = item.getClothingItem and item:getClothingItem()
    local function textureIndex(index, choices)
        index = tonumber(index) or -1
        if choices and choices:size() > 0 and (index < 0 or index >= choices:size()) then
            return 0
        end
        return index
    end
    if visualState.baseTexture ~= nil and visual.setBaseTexture then
        visual:setBaseTexture(textureIndex(visualState.baseTexture,
            clothing and clothing.getBaseTextures and clothing:getBaseTextures()))
    end
    if visualState.textureChoice ~= nil and visual.setTextureChoice then
        visual:setTextureChoice(textureIndex(visualState.textureChoice,
            clothing and clothing.getTextureChoices and clothing:getTextureChoices()))
    end
    if visualState.decal ~= nil and visual.setDecal then
        visual:setDecal(tostring(visualState.decal))
    end
    if visualState.tint
        and ImmutableColor
        and visual.setTint
    then
        visual:setTint(ImmutableColor.new(
            tonumber(visualState.tint.r) or 1,
            tonumber(visualState.tint.g) or 1,
            tonumber(visualState.tint.b) or 1,
            1
        ))
    end
    return true
end

return VisualState
