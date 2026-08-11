local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"

local Support = {}

function Support.fullType(item)
    return tostring(Util.call(item, "getFullType") or item.fullType or item.type or "")
end

function Support.isKind(item, className)
    local ok
    local value
    if instanceof then
        ok, value = pcall(instanceof, item, className)
        if ok and value then return true end
    end
    return false
end

local function getModData(item)
    local data = Util.call(item, "getModData")
    if type(data) ~= "table" then data = item and item.modData or nil end
    if type(data) ~= "table" or not Util.hasEntries(data) then return nil end
    return Util.copy(data)
end

function Support.encodeCommon(item)
    local flags = 0
    local state = {}
    local condition = Util.number(Util.call(item, "getCondition") or item.condition)
    local conditionMax = Util.number(Util.call(item, "getConditionMax") or item.conditionMax)
    local usedDelta = Util.number(Util.call(item, "getUsedDelta") or item.usedDelta)
    local favorite = Util.call(item, "isFavorite")
    local custom = Util.call(item, "isCustomName")
    local name = custom and Util.call(item, "getName") or item.customName
    local modData = getModData(item)
    local actualWeight = Util.number(Util.call(item, "getActualWeight") or item.actualWeight)
    local baseWeight = Util.number(Util.call(item, "getWeight") or item.weight)
    if condition and (not conditionMax or condition ~= conditionMax) then
        flags = flags + C.FLAG_CONDITION
        state[#state + 1] = condition
    end
    if usedDelta ~= nil then
        flags = flags + C.FLAG_USED_DELTA
        state[#state + 1] = usedDelta
    end
    if favorite == true or item.favorite == true then flags = flags + C.FLAG_FAVORITE end
    if name and name ~= "" then
        flags = flags + C.FLAG_CUSTOM_NAME
        state[#state + 1] = tostring(name)
    end
    if modData then
        flags = flags + C.FLAG_MOD_DATA
        state[#state + 1] = modData
    end
    if actualWeight and baseWeight and actualWeight ~= baseWeight then
        flags = flags + C.FLAG_CUSTOM_WEIGHT
        state[#state + 1] = actualWeight
    end
    return flags, state, actualWeight or baseWeight or 0
end

function Support.append(flags, state, flag, value)
    state[#state + 1] = value
    return flags + flag
end

function Support.decodeCommon(item, flags, state)
    local cursor = 1
    local value
    if Util.hasFlag(flags, C.FLAG_CONDITION) then
        value, cursor = state[cursor], cursor + 1
        Util.call(item, "setCondition", value)
        if type(item) == "table" and item.condition ~= nil then
            item.condition = value
        end
    end
    if Util.hasFlag(flags, C.FLAG_USED_DELTA) then
        value, cursor = state[cursor], cursor + 1
        Util.call(item, "setUsedDelta", value)
        if type(item) == "table" and item.usedDelta ~= nil then
            item.usedDelta = value
        end
    end
    if Util.hasFlag(flags, C.FLAG_FAVORITE) then Util.call(item, "setFavorite", true) end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_NAME) then
        value, cursor = state[cursor], cursor + 1
        Util.call(item, "setName", value)
    end
    if Util.hasFlag(flags, C.FLAG_MOD_DATA) then
        value, cursor = state[cursor], cursor + 1
        local target = Util.call(item, "getModData")
        if type(target) == "table" then
            for key, entry in pairs(value or {}) do target[key] = Util.copy(entry) end
        elseif type(item) == "table" then
            item.modData = Util.copy(value)
        end
    end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_WEIGHT) then
        value, cursor = state[cursor], cursor + 1
        Util.call(item, "setActualWeight", value)
    end
    return cursor
end

function Support.commonResult(item, batchable)
    local flags, state, weight = Support.encodeCommon(item)
    return { flags = flags, state = state, unitWeight = weight,
        batchable = batchable ~= false and not Util.hasFlag(flags, C.FLAG_MOD_DATA)
            and not Util.hasFlag(flags, C.FLAG_CUSTOM_NAME) }
end

return Support
