local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Registry = require "PsychopatzCore/Inventory/PsychopatzItemCodecRegistry"
local Support = require "PsychopatzCore/Inventory/Codecs/PsychopatzItemCodecSupport"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"

Registry.register({
    id = C.CODEC_FOOD, name = "food", priority = 100,
    matches = function(item)
        return Support.isKind(item, "Food") or item.isFood == true
            or tonumber(Util.call(item, "getAge")) ~= nil
    end,
    encode = function(item)
        local result = Support.commonResult(item)
        result.flags = Support.append(result.flags, result.state, C.FLAG_FOOD, {
            tonumber(Util.call(item, "getAge") or item.age),
            Util.call(item, "isCooked") == true or item.cooked == true,
            Util.call(item, "isBurnt") == true or item.burnt == true,
            Util.call(item, "isFrozen") == true or item.frozen == true,
            tonumber(Util.call(item, "getFreezingTime") or item.freezingTime),
        })
        return result
    end,
    decode = function(item, flags, state)
        local cursor = Support.decodeCommon(item, flags, state)
        local food = state[cursor] or {}
        if food[1] ~= nil then Util.call(item, "setAge", food[1]) end
        Util.call(item, "setCooked", food[2] == true)
        Util.call(item, "setBurnt", food[3] == true)
        Util.call(item, "setFrozen", food[4] == true)
        if food[5] ~= nil then Util.call(item, "setFreezingTime", food[5]) end
        return true
    end,
})

Registry.register({
    id = C.CODEC_WEAPON, name = "weapon", priority = 90,
    matches = function(item)
        return Support.isKind(item, "HandWeapon") or item.isWeapon == true
            or tonumber(Util.call(item, "getCurrentAmmoCount")) ~= nil
    end,
    encode = function(item)
        local result = Support.commonResult(item)
        local parts = Util.javaList(Util.call(item, "getAllWeaponParts"))
        local attachments = {}
        for i = 1, #parts do
            local partType = Util.call(parts[i], "getFullType")
            if partType then attachments[#attachments + 1] = Types.getId(tostring(partType)) end
        end
        if #attachments > 0 then result.batchable = false end
        result.flags = Support.append(result.flags, result.state, C.FLAG_AMMO, {
            tonumber(Util.call(item, "getCurrentAmmoCount") or item.ammoCount),
            Util.call(item, "isRoundChambered") == true or item.roundChambered == true,
            Util.call(item, "isJammed") == true or item.jammed == true,
            attachments,
        })
        return result
    end,
    decode = function(item, flags, state, context)
        local cursor = Support.decodeCommon(item, flags, state)
        local ammo = state[cursor] or {}
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
            or tonumber(Util.call(item, "getWetness")) ~= nil
    end,
    encode = function(item)
        local result = Support.commonResult(item)
        result.flags = Support.append(result.flags, result.state, C.FLAG_CLOTHING, {
            tonumber(Util.call(item, "getWetness") or item.wetness),
            tonumber(Util.call(item, "getBloodlevel")
                or Util.call(item, "getBloodLevel") or item.bloodLevel),
            tonumber(Util.call(item, "getDirtyness") or item.dirtyness),
        })
        return result
    end,
    decode = function(item, flags, state)
        local cursor = Support.decodeCommon(item, flags, state)
        local clothing = state[cursor] or {}
        if clothing[1] ~= nil then Util.call(item, "setWetness", clothing[1]) end
        if clothing[2] ~= nil then Util.call(item, "setBloodLevel", clothing[2]) end
        if clothing[3] ~= nil then Util.call(item, "setDirtyness", clothing[3]) end
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
