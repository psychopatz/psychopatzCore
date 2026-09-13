local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Codecs = require "PsychopatzCore/Inventory/PsychopatzItemCodecRegistry"
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Defaults = require
    "PsychopatzCore/Inventory/PsychopatzItemStateDefaults"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

local Display = {}
local MAX_FLUIDS = 8

-- This is intentionally a display contract rather than a persistence contract.
-- Keep it small enough for UI/network projections and do not add arbitrary
-- modData here. Codec-specific fields remain owned by their codec payload.
local FIELDS = {
    "condition", "conditionMax", "usedDelta", "favorite", "customName",
    "ammoCount", "roundChambered", "jammed", "age", "cooked", "burnt",
    "frozen", "freezingTime", "hungChange", "thirstChange",
    "dangerousUncooked", "poison", "poisonDetectionLevel",
    "poisonLevelForRecipe", "poisonPower", "rottenTime",
    "cookedInMicrowave", "tainted", "fertilized", "fertilizedTime",
    "heat", "lastCookMinute", "cookingTime", "wetness", "bloodLevel",
    "dirtyness", "fluidAmount", "fluidType", "fluidPrimaryType",
    "fluidCapacity", "fluidInputLocked", "fluidCanPlayerEmpty",
    "fluidRainCatcher", "fluidMixture", "foodCreatedAtHours",
}

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
}

local FOOD_OPTIONAL_ORDER = {
    "dangerousUncooked", "poison", "poisonDetectionLevel",
    "poisonLevelForRecipe", "poisonPower", "rottenTime",
    "cookedInMicrowave", "tainted", "fertilized", "fertilizedTime",
    "heat", "lastCookMinute", "cookingTime", "foodLastAgedHours",
    "foodCreatedAtHours",
}

local FOOD_FIELDS = {
    { "age", "getAge" }, { "cooked", "isCooked" },
    { "burnt", "isBurnt" }, { "frozen", "isFrozen" },
    { "freezingTime", "getFreezingTime" },
    { "hungChange", "getHungChange" },
    { "thirstChange", "getThirstChange" },
    { "dangerousUncooked", "isbDangerousUncooked" },
    { "poison", "isPoison" },
    { "poisonDetectionLevel", "getPoisonDetectionLevel" },
    { "poisonLevelForRecipe", "getPoisonLevelForRecipe" },
    { "poisonPower", "getPoisonPower" },
    { "rottenTime", "getRottenTime" },
    { "cookedInMicrowave", "isCookedInMicrowave" },
    { "tainted", "isTainted" }, { "fertilized", "isFertilized" },
    { "fertilizedTime", "getFertilizedTime" },
    { "heat", "getHeat" }, { "lastCookMinute", "getLastCookMinute" },
    { "cookingTime", "getCookingTime" },
}

local CLOTHING_FIELDS = {
    { "wetness", "getWetness" }, { "bloodLevel", "getBloodlevel" },
    { "dirtyness", "getDirtiness" },
}

local function finite(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function call(object, method, ...)
    local value
    local ok
    if not object or type(object[method]) ~= "function" then return nil end
    ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function copyFluids(source, target)
    local entries
    if type(source) ~= "table" then return end
    entries = {}
    for index = 1, math.min(MAX_FLUIDS, #source) do
        local entry = source[index]
        local amount = type(entry) == "table" and finite(entry.amount) or nil
        local fluidType = type(entry) == "table" and entry.type or nil
        if fluidType ~= nil and amount ~= nil and amount >= 0 then
            entries[#entries + 1] = {
                type = tostring(fluidType), amount = amount,
            }
        end
    end
    if #entries > 0 then target.fluids = entries end
end

function Display.Copy(state, options)
    local output = {}
    local field
    local value
    options = type(options) == "table" and options or {}
    if type(state) ~= "table" then return output end
    for index = 1, #FIELDS do
        field = FIELDS[index]
        value = state[field]
        if value ~= nil then output[field] = value end
    end
    copyFluids(state.fluids, output)
    if options.includeModData == true and type(state.modData) == "table" then
        output.modData = Portable.ProjectNetworkState({
            modData = state.modData,
        }, { includeModData = true }).modData
    end
    return output
end

local function copyStateFields(source, target)
    local value
    if type(source) ~= "table" then return end
    for index = 1, #FIELDS do
        local field = FIELDS[index]
        value = source[field]
        if value ~= nil then target[field] = value end
    end
    copyFluids(source.fluids, target)
end

local function hasValues(state)
    local value
    if type(state) ~= "table" then return false end
    for index = 1, #FIELDS do
        value = state[FIELDS[index]]
        if value ~= nil then return true end
    end
    return type(state.fluids) == "table" and #state.fluids > 0
end

local function finishProjection(state, options)
    local known
    state = Display.Copy(state, options)
    known = hasValues(state)
    if options.network == true then
        state = Portable.ProjectNetworkState(state, options)
    end
    return state, known
end

local function readNative(item, fullFluid)
    local state = {}
    local profile = Profiles.ClassifyNative(item)
    local capabilities = profile.capabilities or {}
    local value
    local container
    local primary
    local primaryType

    value = call(item, "getCondition")
    if value ~= nil then state.condition = value end
    value = call(item, "getConditionMax")
    if value ~= nil then state.conditionMax = value end
    value = call(item, "getUsedDelta")
    if value ~= nil then state.usedDelta = value end
    if capabilities.ammo then
        value = call(item, "getCurrentAmmoCount")
        if value ~= nil then state.ammoCount = value end
        value = call(item, "isRoundChambered")
        if value ~= nil then state.roundChambered = value == true end
        value = call(item, "isJammed")
        if value ~= nil then state.jammed = value == true end
    end
    value = call(item, "isFavorite")
    if value ~= nil then state.favorite = value == true end
    value = call(item, "isCustomName")
    if value == true then
        state.customName = call(item, "getName")
    end

    if capabilities.food then
        for index = 1, #FOOD_FIELDS do
            local field = FOOD_FIELDS[index][1]
            value = call(item, FOOD_FIELDS[index][2])
            if value ~= nil then state[field] = value end
        end
    end
    if capabilities.clothing then
        for index = 1, #CLOTHING_FIELDS do
            local field = CLOTHING_FIELDS[index][1]
            value = call(item, CLOTHING_FIELDS[index][2])
            if value == nil and field == "bloodLevel" then
                value = call(item, "getBloodLevel")
            end
            if value ~= nil then state[field] = value end
        end
    end

    if capabilities.fluid then container = call(item, "getFluidContainer") end
    if container then
        if fullFluid == true then
            copyStateFields(Portable.CaptureFluid(item), state)
        else
            value = call(container, "getAmount")
            if value ~= nil then state.fluidAmount = value end
            value = call(container, "getCapacity")
            if value ~= nil then state.fluidCapacity = value end
            value = call(container, "isMixture")
            if value ~= nil then state.fluidMixture = value == true end
            primary = call(container, "getPrimaryFluid")
            primaryType = call(primary, "getFluidTypeString")
            if primaryType ~= nil then
                state.fluidPrimaryType = tostring(primaryType)
            end
        end
    end
    return state
end

local function readCompact(item)
    local state = {}
    local effective
    local fullType
    if type(item) ~= "table" then return state end
    copyStateFields(item.itemState, state)
    copyStateFields(item.fluidState, state)
    copyStateFields(item, state)
    if item.cond ~= nil then state.condition = item.cond end
    if item.uses ~= nil then state.usedDelta = item.uses end
    if item.fav ~= nil then state.favorite = item.fav == true end
    fullType = item.type or item.fullType
    if fullType then
        effective = Defaults.Effective({
            type = fullType, itemState = state,
        })
        for key, value in pairs(effective) do state[key] = value end
    end
    return state
end

local function decodeFood(payload, state)
    local optionalFlags = tonumber(payload[8]) or 0
    local cursor = 9
    state.age, state.cooked = payload[1], payload[2]
    state.burnt, state.frozen = payload[3], payload[4]
    state.freezingTime = payload[5]
    state.hungChange, state.thirstChange = payload[6], payload[7]
    for index = 1, #FOOD_OPTIONAL_ORDER do
        local field = FOOD_OPTIONAL_ORDER[index]
        if Util.hasFlag(optionalFlags, FOOD_OPTIONAL[field]) then
            if field ~= "foodLastAgedHours" then
                state[field] = payload[cursor]
            end
            cursor = cursor + 1
        end
    end
end

local function decodeRecord(record)
    local flags = math.max(0, math.floor(tonumber(record[C.FLAGS]) or 0))
    local data = type(record[C.STATE]) == "table" and record[C.STATE] or {}
    local state = {}
    local cursor = 1
    local value
    local fullType = Types.getFullType(record[C.TYPE_ID])
    if Util.hasFlag(flags, C.FLAG_CONDITION) then
        state.condition, cursor = data[cursor], cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_USED_DELTA) then
        state.usedDelta, cursor = data[cursor], cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_FAVORITE) then state.favorite = true end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_NAME) then
        state.customName, cursor = data[cursor], cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_MOD_DATA) then cursor = cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_WEIGHT) then cursor = cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_FLUID) then
        value = data[cursor] or {}
        copyStateFields(value, state)
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_FOOD) then
        decodeFood(data[cursor] or {}, state)
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_AMMO) then
        value = data[cursor] or {}
        state.ammoCount = value[1]
        state.roundChambered = value[2]
        state.jammed = value[3]
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_CLOTHING) then
        value = data[cursor] or {}
        state.wetness, state.bloodLevel, state.dirtyness = value[1], value[2], value[3]
        cursor = cursor + 1
    end
    if fullType then
        local effective = Defaults.Effective({
            type = fullType, itemState = state,
        })
        for key, entry in pairs(effective) do state[key] = entry end
    end
    return state
end

function Display.ProjectRecord(record, options)
    local state
    local codec
    local projected
    local ok
    options = type(options) == "table" and options or {}
    if type(record) ~= "table" then return {}, false end
    codec = Codecs.get(record[C.CODEC_ID])
    if codec and type(codec.project) == "function" then
        ok, projected = pcall(codec.project, record, options)
        if ok and type(projected) == "table" then
            return finishProjection(projected, options)
        end
    end
    state = decodeRecord(record)
    return finishProjection(state, options)
end

function Display.ProjectNetworkState(state, options)
    return Portable.ProjectNetworkState(Display.Copy(state), options)
end

function Display.ProjectCompactState(item, options)
    local state
    options = type(options) == "table" and options or {}
    state = Display.Copy(readCompact(item), options)
    return state, hasValues(state)
end

function Display.ProjectNativeState(item, options)
    local state
    options = type(options) == "table" and options or {}
    state = Display.Copy(readNative(item, options.fullFluid == true), options)
    return state, true
end

function Display.StateForRow(row, player, options)
    local state = {}
    local known = false
    local compact
    local storage
    options = type(options) == "table" and options or {}
    if type(row) ~= "table" then return state, false end
    if row.nativeItem then
        state = readNative(row.nativeItem, options.fullFluid == true)
        known = true
    else
        compact = row.compactItem
        if type(compact) == "table" then
            state, known = Display.ProjectCompactState(compact, options)
        else
            storage = row.storageRecord
            if type(storage) == "table" and type(storage.tooltipState) == "table" then
                state = Display.Copy(storage.tooltipState, options)
                known = true
            elseif type(storage) == "table" and type(storage[C.STATE]) == "table" then
                state, known = Display.ProjectRecord(storage, options)
            end
        end
    end
    if type(row.tooltipState) == "table" then
        copyStateFields(row.tooltipState, state)
        known = true
    end
    return state, known
end

function Display.ProfileForRow(row)
    return Profiles.ForRow(row)
end

Display.Fields = FIELDS
Display.MaxFluids = MAX_FLUIDS

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Inventory = PsychopatzCore.Inventory or {}
PsychopatzCore.Inventory.DisplayState = Display

return Display
