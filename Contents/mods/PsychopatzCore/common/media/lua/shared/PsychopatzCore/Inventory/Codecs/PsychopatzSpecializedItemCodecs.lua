local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Registry = require "PsychopatzCore/Inventory/PsychopatzItemCodecRegistry"
local Support = require "PsychopatzCore/Inventory/Codecs/PsychopatzItemCodecSupport"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Defaults = require
    "PsychopatzCore/Inventory/PsychopatzItemStateDefaults"

local FOOD_OPTIONAL = {
    dangerousUncooked = 1,
    poison = 2,
    poisonDetectionLevel = 4,
    poisonLevelForRecipe = 8,
    poisonPower = 16,
    rottenTime = 32,
    cookedInMicrowave = 64,
    tainted = 128,
    fertilized = 256,
    fertilizedTime = 512,
    heat = 1024,
    lastCookMinute = 2048,
    cookingTime = 4096,
    foodLastAgedHours = 8192,
    foodCreatedAtHours = 16384,
    calories = 32768,
    carbohydrates = 65536,
    proteins = 131072,
    lipids = 262144,
}

local FOOD_OPTIONAL_ORDER = {
    "dangerousUncooked", "poison", "poisonDetectionLevel",
    "poisonLevelForRecipe", "poisonPower", "rottenTime",
    "cookedInMicrowave", "tainted", "fertilized", "fertilizedTime",
    "heat", "lastCookMinute", "cookingTime", "foodLastAgedHours",
    "foodCreatedAtHours", "calories", "carbohydrates", "proteins", "lipids",
}

local function encodeFoodState(food)
    local payload = {
        Util.number(food.age), food.cooked == true, food.burnt == true,
        food.frozen == true, Util.number(food.freezingTime),
        Util.number(food.hungChange), Util.number(food.thirstChange),
    }
    local optionalFlags = 0
    local values = {}
    local key
    local value
    local i
    for i = 1, #FOOD_OPTIONAL_ORDER do
        key = FOOD_OPTIONAL_ORDER[i]
        value = food[key]
        if value ~= nil then
            optionalFlags = optionalFlags + FOOD_OPTIONAL[key]
            values[#values + 1] = value
        end
    end
    if optionalFlags > 0 then
        payload[8] = optionalFlags
        for i = 1, #values do payload[8 + i] = values[i] end
    end
    return payload
end

local function decodeFoodState(payload)
    local output = {}
    local optionalFlags = tonumber(payload[8]) or 0
    local cursor = 9
    local key
    local i
    output.age, output.cooked = payload[1], payload[2]
    output.burnt, output.frozen = payload[3], payload[4]
    output.freezingTime = payload[5]
    output.hungChange, output.thirstChange = payload[6], payload[7]
    for i = 1, #FOOD_OPTIONAL_ORDER do
        key = FOOD_OPTIONAL_ORDER[i]
        if Util.hasFlag(optionalFlags, FOOD_OPTIONAL[key]) then
            output[key] = payload[cursor]
            cursor = cursor + 1
        end
    end
    return output
end

Registry.register({
    id = C.CODEC_FLUID, name = "fluid", priority = 105,
    matches = function(item)
        return Util.call(item, "getFluidContainer") ~= nil
            or type(item.fluidState) == "table"
    end,
    encode = function(item)
        local fluid = type(item.fluidState) == "table"
            and Portable.CopyFluidState(item.fluidState)
            or Portable.CaptureFluid(item)
        local delta
        if not fluid then return nil end
        local result = Support.commonResult(item)
        delta = Defaults.Diff(Support.fullType(item), fluid)
        if delta then
            result.flags = Support.append(result.flags, result.state,
                C.FLAG_FLUID, delta)
        end
        result.batchable = false
        return result
    end,
    decode = function(item, flags, state)
        local cursor = Support.decodeCommon(item, flags, state)
        local fluid
        local ok
        local reason
        if not Util.hasFlag(flags, C.FLAG_FLUID) then return true end
        fluid = state[cursor] or {}
        ok, reason = Portable.ApplyFluid(item, fluid)
        if not ok then return false, reason end
        return true
    end,
})

Registry.register({
    id = C.CODEC_FOOD, name = "food", priority = 100,
    matches = function(item)
        return Support.isKind(item, "Food") or item.isFood == true
    end,
    encode = function(item)
        local foodState = Portable.CaptureFood(item) or {}
        local result = Support.commonResult(item)
        local delta = Defaults.Diff(Support.fullType(item), foodState)
        if delta then
            result.flags = Support.append(result.flags, result.state,
                C.FLAG_FOOD, encodeFoodState(delta))
        end
        return result
    end,
    decode = function(item, flags, state)
        local cursor = Support.decodeCommon(item, flags, state)
        local food
        if not Util.hasFlag(flags, C.FLAG_FOOD) then return true end
        food = decodeFoodState(state[cursor] or {})
        Portable.ApplyFood(item, food)
        return true
    end,
})

Registry.register({
    id = C.CODEC_WEAPON, name = "weapon", priority = 90,
    matches = function(item)
        return Support.isKind(item, "HandWeapon") or item.isWeapon == true
    end,
    encode = function(item)
        local result = Support.commonResult(item)
        local parts = Util.javaList(Util.call(item, "getAllWeaponParts"))
        local attachments = {}
        local weaponState = {}
        local delta
        local payload
        local ammoCount = Util.number(
            Util.call(item, "getCurrentAmmoCount") or item.ammoCount)
        local roundChambered = Util.call(item, "isRoundChambered")
        local jammed = Util.call(item, "isJammed")
        for i = 1, #parts do
            local partType = Util.call(parts[i], "getFullType")
            if partType then attachments[#attachments + 1] = Types.getId(tostring(partType)) end
        end
        if ammoCount ~= nil then weaponState.ammoCount = ammoCount end
        if roundChambered ~= nil then
            weaponState.roundChambered = roundChambered == true
        elseif item.roundChambered ~= nil then
            weaponState.roundChambered = item.roundChambered == true
        end
        if jammed ~= nil then
            weaponState.jammed = jammed == true
        elseif item.jammed ~= nil then
            weaponState.jammed = item.jammed == true
        end
        delta = Defaults.Diff(Support.fullType(item), weaponState)
        if #attachments > 0 then result.batchable = false end
        if delta or #attachments > 0 then
            payload = {
                delta and delta.ammoCount or nil,
                delta and delta.roundChambered or nil,
                delta and delta.jammed or nil,
                attachments,
            }
            result.flags = Support.append(result.flags, result.state,
                C.FLAG_AMMO, payload)
        end
        return result
    end,
    decode = function(item, flags, state, context)
        local cursor = Support.decodeCommon(item, flags, state)
        local ammo
        if not Util.hasFlag(flags, C.FLAG_AMMO) then return true end
        ammo = state[cursor] or {}
        if ammo[1] ~= nil then Util.call(item, "setCurrentAmmoCount", ammo[1]) end
        if ammo[2] ~= nil then Util.call(item, "setRoundChambered", ammo[2]) end
        if ammo[3] ~= nil then Util.call(item, "setJammed", ammo[3]) end
        for i = 1, #(ammo[4] or {}) do
            local partType = Types.getFullType(ammo[4][i])
            local part = partType and context and context.createItem
                and context.createItem(partType) or nil
            if not part or not item.attachWeaponPart then
                return false, "weapon_attachment_restore_failed"
            end
            item:attachWeaponPart(part)
        end
        return true
    end,
})

Registry.register({
    id = C.CODEC_CLOTHING, name = "clothing", priority = 70,
    matches = function(item)
        return Support.isKind(item, "Clothing") or item.isClothing == true
    end,
    encode = function(item)
        local result = Support.commonResult(item)
        local clothingState = {
            wetness = Util.number(Util.call(item, "getWetness") or item.wetness),
            bloodLevel = Util.number(Util.call(item, "getBloodlevel")
                or Util.call(item, "getBloodLevel") or item.bloodLevel),
            dirtyness = Util.number(Util.call(item, "getDirtiness") or item.dirtyness),
        }
        local delta = Defaults.Diff(Support.fullType(item), clothingState)
        if delta then
            result.flags = Support.append(result.flags, result.state,
                C.FLAG_CLOTHING, {
                    delta.wetness, delta.bloodLevel, delta.dirtyness,
                })
        end
        return result
    end,
    decode = function(item, flags, state)
        local cursor = Support.decodeCommon(item, flags, state)
        local clothing
        if not Util.hasFlag(flags, C.FLAG_CLOTHING) then return true end
        clothing = state[cursor] or {}
        if clothing[1] ~= nil then Util.call(item, "setWetness", clothing[1]) end
        if clothing[2] ~= nil then Util.call(item, "setBloodLevel", clothing[2]) end
        if clothing[3] ~= nil then Util.call(item, "setDirtiness", clothing[3]) end
        return true
    end,
})

Registry.register({
    id = C.CODEC_CONTAINER, name = "container", priority = 110,
    matches = function(item) return Util.call(item, "getInventory") ~= nil end,
    encode = function(item, context)
        local result = Support.commonResult(item, false)
        local nested = {}
        local container = Util.call(item, "getInventory")
        local items = container and Util.javaList(Util.call(container, "getItems")) or {}
        for i = 1, #items do
            local record = context and context.encodeItem and context.encodeItem(items[i])
            if record then nested[#nested + 1] = record end
        end
        result.flags = Support.append(result.flags, result.state, C.FLAG_CONTAINER, nested)
        return result
    end,
    decode = function(item, flags, state, context)
        local cursor = Support.decodeCommon(item, flags, state)
        local nested = state[cursor] or {}
        local container = Util.call(item, "getInventory")
        if #nested > 0 and not container then return false, "container_unavailable" end
        for i = 1, #nested do
            local child, reason = context.decodeItem(nested[i])
            if not child then return false, reason end
            if container.AddItem then container:AddItem(child)
            else return false, "container_add_unavailable" end
        end
        return true
    end,
})

return Registry
