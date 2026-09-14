local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Defaults = require
    "PsychopatzCore/Inventory/PsychopatzItemStateDefaults"

local Portable = {}
local EPSILON = 0.000001
local MAX_FLUIDS = 8
local NETWORK_MAX_STRING_LENGTH = 128
local NETWORK_MAX_FLUID_STRING_LENGTH = 64
local NETWORK_MAX_MODDATA_KEYS = 8
local FOOD_EPSILON = 0.000001
local FOOD_NO_EXPIRY = 1000000000
local fluidCatalog

local function finiteNumber(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function methodValue(object, methodName, fallback)
    local value = Util.call(object, methodName)
    if value == nil then return fallback end
    return value
end

local function fluidName(fluid)
    local name = Util.call(fluid, "getFluidTypeString")
        or Util.call(fluid, "getFluidType")
    if name == nil then return nil end
    name = tostring(name)
    return name ~= "" and name or nil
end

local function allFluids()
    local fluidClass = rawget(_G, "Fluid")
    if fluidCatalog then return fluidCatalog end
    if not fluidClass or type(fluidClass.getAllFluids) ~= "function" then
        return {}
    end
    local ok, values = pcall(fluidClass.getAllFluids)
    if not ok then return {} end
    values = Util.javaList(values)
    if #values > 0 then fluidCatalog = values end
    return values
end

local function sortFluids(entries, primaryType)
    table.sort(entries, function(left, right)
        if left.type == primaryType then return right.type ~= primaryType end
        if right.type == primaryType then return false end
        return left.type < right.type
    end)
end

local function boundedString(value, limit)
    value = tostring(value or "")
    if value == "" then return nil end
    limit = math.max(1, math.floor(tonumber(limit) or NETWORK_MAX_STRING_LENGTH))
    if #value > limit then value = string.sub(value, 1, limit) end
    return value
end

local function copyFluidEntries(entries, typeLimit)
    local output = {}
    if type(entries) ~= "table" then return output end
    for i = 1, math.min(#(entries or {}), MAX_FLUIDS) do
        local entry = entries[i]
        local fluidType = type(entry) == "table"
            and boundedString(entry.type, typeLimit)
            or nil
        local amount = type(entry) == "table" and finiteNumber(entry.amount)
            or nil
        if fluidType and amount and amount >= 0 then
            output[#output + 1] = { type = fluidType, amount = amount }
        end
    end
    return output
end

function Portable.CaptureFluid(item)
    local container = Util.call(item, "getFluidContainer")
    local primary
    local primaryType
    local state
    local entries
    local fluids
    if not container then return nil end

    state = {
        fluidAmount = finiteNumber(methodValue(container, "getAmount", 0)) or 0,
        fluidCapacity = finiteNumber(methodValue(container, "getCapacity")),
        fluidInputLocked = methodValue(container, "isInputLocked") == true,
        fluidCanPlayerEmpty = methodValue(container, "canPlayerEmpty"),
        fluidRainCatcher = finiteNumber(
            methodValue(container, "getRainCatcher")
        ),
        fluids = {},
    }
    primary = methodValue(container, "getPrimaryFluid")
    primaryType = fluidName(primary)
    state.fluidPrimaryType = primaryType

    fluids = allFluids()
    for i = 1, #fluids do
        local fluid = fluids[i]
        local name = fluidName(fluid)
        local amount = finiteNumber(
            Util.call(container, "getSpecificFluidAmount", fluid)
        )
        if name and amount and amount > EPSILON then
            entries = entries or {}
            if #entries < MAX_FLUIDS then
                entries[#entries + 1] = { type = name, amount = amount }
            end
        end
    end
    entries = entries or {}
    sortFluids(entries, primaryType)

    -- Older servers or test doubles may expose only the primary-fluid API.
    -- Keep a single-fluid fallback so those states remain portable.
    if #entries == 0 and primaryType and state.fluidAmount > EPSILON then
        entries[1] = { type = primaryType, amount = state.fluidAmount }
    end
    state.fluids = entries
    return state
end

function Portable.RefreshFluidCatalog()
    fluidCatalog = nil
    return allFluids()
end

local function resolveFluid(name)
    local fluidClass = rawget(_G, "Fluid")
    local fluidTypeClass = rawget(_G, "FluidType")
    local normalized = tostring(name or "")
    local ok
    local fluid
    if normalized == "" then return nil end
    if fluidClass and type(fluidClass.Get) == "function" then
        ok, fluid = pcall(fluidClass.Get, normalized)
        if ok and fluid then return fluid end
    end
    if fluidTypeClass and type(fluidTypeClass.FromNameLower) == "function" then
        ok, fluid = pcall(fluidTypeClass.FromNameLower,
            string.lower(normalized))
        if ok and fluid and fluidClass
            and type(fluidClass.Get) == "function"
        then
            ok, fluid = pcall(fluidClass.Get, fluid)
            if ok and fluid then return fluid end
        end
    end
    return nil
end

local function clearContainer(container)
    local _, ok = Util.call(container, "Empty", false)
    if ok then return true end
    local amount = finiteNumber(Util.call(container, "getAmount")) or 0
    if amount <= EPSILON then return true end
    _, ok = Util.call(container, "removeFluid", amount)
    return ok
end

local function restoreFlag(container, methodName, value)
    if value == nil then return true end
    local _, ok = Util.call(container, methodName, value == true)
    return ok
end

local function chooseValue(preferred, fallback)
    return preferred == nil and fallback or preferred
end

local function isFood(item)
    local ok
    local value
    if item and item.isFood == true then return true end
    value = Util.call(item, "isFood")
    if value == true then return true end
    value = Util.call(item, "IsFood")
    if value == true then return true end
    if instanceof then
        ok, value = pcall(instanceof, item, "Food")
        return ok and value == true
    end
    return false
end

local function readFoodValue(item, methodName, fieldName)
    local value = Util.call(item, methodName)
    if value ~= nil then return value end
    return item and item[fieldName] or nil
end

local function worldAgeHours()
    local getGameTime = rawget(_G, "getGameTime")
    local gameTimeClass = rawget(_G, "GameTime")
    local gameTime
    local ok
    local value
    if type(getGameTime) == "function" then
        ok, gameTime = pcall(getGameTime)
        if ok and gameTime then
            value = Util.call(gameTime, "getWorldAgeHours")
            value = finiteNumber(value)
            if value ~= nil then return value end
        end
    end
    if gameTimeClass and type(gameTimeClass.getInstance) == "function" then
        ok, gameTime = pcall(gameTimeClass.getInstance)
        if ok and gameTime then
            value = Util.call(gameTime, "getWorldAgeHours")
            value = finiteNumber(value)
            if value ~= nil then return value end
        end
    end
    return nil
end

Portable.GetWorldAgeHours = worldAgeHours

function Portable.CaptureFood(item)
    local state = {}
    local fields = {
        { "age", "getAge" },
        { "cooked", "isCooked" },
        { "burnt", "isBurnt" },
        { "frozen", "isFrozen" },
        { "freezingTime", "getFreezingTime" },
        { "hungChange", "getHungChange" },
        { "thirstChange", "getThirstChange" },
        { "calories", "getCalories" },
        { "carbohydrates", "getCarbohydrates" },
        { "proteins", "getProteins" },
        { "lipids", "getLipids" },
    }
    local optional = {
        { "dangerousUncooked", "isbDangerousUncooked", nil, true },
        { "poison", "isPoison", "poison", true },
        { "poisonDetectionLevel", "getPoisonDetectionLevel", nil, -1 },
        { "poisonLevelForRecipe", "getPoisonLevelForRecipe", nil, 0 },
        { "poisonPower", "getPoisonPower", nil, 0 },
        { "rottenTime", "getRottenTime", nil, 0 },
        { "cookedInMicrowave", "isCookedInMicrowave", nil, true },
        { "tainted", "isTainted", "isTainted", true },
        { "fertilized", "isFertilized", "fertilized", true },
        { "fertilizedTime", "getFertilizedTime", nil, 0 },
        { "heat", "getHeat", nil, 1 },
        { "lastCookMinute", "getLastCookMinute", nil, 0 },
        { "cookingTime", "getCookingTime", nil, 0 },
        { "foodLastAgedHours", "getFoodLastAgedHours",
            "foodLastAgedHours", nil },
        { "foodCreatedAtHours", "getFoodCreatedAtHours",
            "foodCreatedAtHours", nil },
    }
    local captured = false
    local value
    local now
    if not isFood(item) then return nil end

    -- A native item may have been sitting in a container since the last
    -- engine update. Bring it current before crossing the portable boundary,
    -- then use the capture time as the ledger's next aging checkpoint.
    now = worldAgeHours()
    if now ~= nil and type(item.updateAge) == "function" then
        pcall(item.updateAge, item, false)
    end
    for i = 1, #fields do
        local field, method = fields[i][1], fields[i][2]
        local value = Util.call(item, method)
        if value ~= nil then
            state[field] = value
            captured = true
        end
    end
    for i = 1, #optional do
        local entry = optional[i]
        value = readFoodValue(item, entry[2], entry[3])
        if value ~= nil
            and ((entry[4] == true and value == true)
                or (entry[4] ~= true and value ~= entry[4]))
        then
            state[entry[1]] = value
            captured = true
        end
    end
    if now ~= nil then
        state.foodLastAgedHours = now
        captured = true
    end
    return captured and state or nil
end

function Portable.ApplyFood(item, state)
    local methods = {
        age = "setAge", cooked = "setCooked", burnt = "setBurnt",
        frozen = "setFrozen", freezingTime = "setFreezingTime",
        hungChange = "setHungChange", thirstChange = "setThirstChange",
        calories = "setCalories", carbohydrates = "setCarbohydrates",
        proteins = "setProteins", lipids = "setLipids",
        dangerousUncooked = "setbDangerousUncooked",
        poisonDetectionLevel = "setPoisonDetectionLevel",
        poisonLevelForRecipe = "setPoisonLevelForRecipe",
        poisonPower = "setPoisonPower", rottenTime = "setRottenTime",
        cookedInMicrowave = "setCookedInMicrowave",
        tainted = "setTainted", fertilized = "setFertilized",
        fertilizedTime = "setFertilizedTime", heat = "setHeat",
        lastCookMinute = "setLastCookMinute", cookingTime = "setCookingTime",
    }
    local value
    if not isFood(item) or type(state) ~= "table" then return true end
    for field, method in pairs(methods) do
        value = state[field]
        if value ~= nil then Util.call(item, method, value) end
    end
    if state.poison ~= nil and item then
        pcall(function() item.poison = state.poison == true end)
    end
    if type(item) == "table" and state.foodLastAgedHours ~= nil then
        item.foodLastAgedHours = state.foodLastAgedHours
    end
    if type(item) == "table" and state.foodCreatedAtHours ~= nil then
        item.foodCreatedAtHours = state.foodCreatedAtHours
    end
    return true
end

function Portable.GetFoodStatus(state, profile)
    local age
    local offAge
    local offAgeMax
    local fertilized
    if type(state) ~= "table" then state = {} end
    profile = type(profile) == "table" and profile or {}
    age = math.max(0, finiteNumber(state.age) or 0)
    offAge = finiteNumber(profile.offAge)
    offAgeMax = finiteNumber(profile.offAgeMax)
    -- Build 42 uses 1e9 as the script-side "never" expiry sentinel.
    if offAge and offAge >= FOOD_NO_EXPIRY then offAge = nil end
    if offAgeMax and offAgeMax >= FOOD_NO_EXPIRY then offAgeMax = nil end
    fertilized = state.fertilized == true
    return {
        age = age,
        fresh = fertilized or offAge == nil or age < offAge,
        stale = not fertilized and offAge ~= nil and age >= offAge
            and (offAgeMax == nil or age < offAgeMax),
        rotten = not fertilized and offAgeMax ~= nil and age >= offAgeMax,
        fertilized = fertilized,
        burnt = state.burnt == true,
    }
end

-- Advances only the portable food state. Storage temperature, sandbox speed,
-- and other policy decisions stay outside this function so the shared core can
-- be reused by NPC ledgers, containers, and other mods without engine objects.
function Portable.AdvanceFoodState(state, profile, nowHours, policy)
    local now = finiteNumber(nowHours)
    local last
    local created
    local elapsed
    local multiplier
    local speed
    local age
    local nextAge
    local freezingTime
    local nextFreezingTime
    local changed = false
    if type(state) ~= "table" or type(profile) ~= "table"
        or profile.food ~= true or now == nil
    then
        return false, "not_advanceable"
    end
    policy = type(policy) == "table" and policy or {}
    age = math.max(0, finiteNumber(state.age) or 0)
    if state.age ~= age then
        state.age = age
        changed = true
    end

    last = finiteNumber(state.foodLastAgedHours)
    if last == nil then
        created = finiteNumber(state.foodCreatedAtHours)
        if created ~= nil then
            -- A generated item can remain abstract for a long time. Use its
            -- creation anchor for the first lazy update, then switch to the
            -- normal checkpoint representation.
            state.foodLastAgedHours = created
            state.foodCreatedAtHours = nil
            last = created
            changed = true
        else
            state.foodLastAgedHours = now
            return true, Portable.GetFoodStatus(state, profile)
        end
    end
    if now < last then
        -- World time should be monotonic, but a load or test clock can move
        -- backwards. Never make food younger; reset only the checkpoint.
        state.foodLastAgedHours = now
        return true, Portable.GetFoodStatus(state, profile)
    end
    elapsed = now - last
    if elapsed <= FOOD_EPSILON then
        return changed, Portable.GetFoodStatus(state, profile)
    end

    if state.frozen == true and policy.keepFrozen ~= true then
        freezingTime = finiteNumber(state.freezingTime)
        if freezingTime and freezingTime > FOOD_EPSILON then
            nextFreezingTime = math.max(0,
                freezingTime - elapsed
                    / math.max(FOOD_EPSILON,
                        finiteNumber(policy.thawHours) or 1.5)
                    * 100)
            if math.abs(nextFreezingTime - freezingTime) > FOOD_EPSILON then
                state.freezingTime = nextFreezingTime
                changed = true
            end
            if nextFreezingTime <= FOOD_EPSILON then
                state.frozen = false
                changed = true
            end
        end
    end

    multiplier = finiteNumber(policy.rotMultiplier)
        or finiteNumber(profile.rotMultiplier) or 1
    speed = finiteNumber(policy.foodRotSpeed)
        or finiteNumber(profile.foodRotSpeed) or 1
    multiplier = math.max(0, multiplier)
    speed = math.max(0, speed)
    if state.frozen == true then multiplier = 0 end
    nextAge = age + (elapsed * multiplier * speed / 24)
    if math.abs(nextAge - age) > FOOD_EPSILON then
        state.age = nextAge
        changed = true
    end
    if state.foodLastAgedHours ~= now then
        state.foodLastAgedHours = now
        changed = true
    end
    return changed, Portable.GetFoodStatus(state, profile)
end

function Portable.ApplyFluid(item, state)
    local container = Util.call(item, "getFluidContainer")
    local fullType = Util.call(item, "getFullType")
        or item and (item.fullType or item.type)
    local nativeDefault = Portable.CaptureFluid(item)
    local resolved
    local effectiveState
    local entries
    local expectedAmount
    local capacity
    local inputLocked
    local canPlayerEmpty
    local oldInputLocked
    local oldCanPlayerEmpty
    local fluid
    local resolvedFluids = {}
    local actualAmount
    local componentAmount
    local _, ok
    if not container then return false, "fluid_container_unavailable" end

    _, resolved = Defaults.Resolve(fullType)
    if resolved then
        effectiveState = Defaults.Apply(fullType, state)
    elseif nativeDefault then
        effectiveState = Defaults.Apply(fullType, state, {
            defaults = nativeDefault,
        })
    else
        effectiveState = type(state) == "table" and state or {}
    end
    entries = copyFluidEntries(effectiveState.fluids)
    expectedAmount = finiteNumber(effectiveState.fluidAmount) or 0
    capacity = finiteNumber(effectiveState.fluidCapacity)
    inputLocked = effectiveState.fluidInputLocked
    canPlayerEmpty = effectiveState.fluidCanPlayerEmpty

    if #entries == 0 and effectiveState
        and (effectiveState.fluidPrimaryType or effectiveState.fluidType)
        and expectedAmount > EPSILON
    then
        entries[1] = {
            type = tostring(effectiveState.fluidPrimaryType
                or effectiveState.fluidType),
            amount = expectedAmount,
        }
    end
    if capacity and capacity > 0 then
        _, ok = Util.call(container, "setCapacity", capacity)
        if not ok then return false, "fluid_capacity_restore_failed" end
    end

    oldInputLocked = methodValue(container, "isInputLocked")
    oldCanPlayerEmpty = methodValue(container, "canPlayerEmpty")
    local function fail(reason)
        restoreFlag(container, "setCanPlayerEmpty",
            chooseValue(canPlayerEmpty, oldCanPlayerEmpty))
        restoreFlag(container, "setInputLocked",
            chooseValue(inputLocked, oldInputLocked))
        return false, reason
    end
    _, ok = Util.call(container, "setInputLocked", false)
    if not ok and oldInputLocked ~= nil then
        return fail("fluid_unlock_failed")
    end
    _, ok = Util.call(container, "setCanPlayerEmpty", true)
    if not ok and oldCanPlayerEmpty ~= nil then
        return fail("fluid_open_failed")
    end
    if not clearContainer(container) then
        return fail("fluid_clear_failed")
    end

    for i = 1, #entries do
        local entry = entries[i]
        fluid = resolveFluid(entry.type)
        if not fluid then return fail("fluid_type_unavailable") end
        resolvedFluids[i] = fluid
        _, ok = Util.call(container, "addFluid", fluid, entry.amount)
        if not ok then return fail("fluid_add_failed") end
    end

    if expectedAmount > EPSILON then
        _, ok = Util.call(container, "adjustAmount", expectedAmount)
        if not ok then return fail("fluid_amount_restore_failed") end
    end
    actualAmount = finiteNumber(Util.call(container, "getAmount")) or 0
    if math.abs(actualAmount - expectedAmount) > 0.0001 then
        return fail("fluid_amount_mismatch")
    end
    for i = 1, #entries do
        componentAmount = finiteNumber(Util.call(container,
            "getSpecificFluidAmount", resolvedFluids[i]))
        if componentAmount
            and math.abs(componentAmount - entries[i].amount) > 0.0001
        then
            return fail("fluid_component_mismatch")
        end
    end

    if effectiveState and effectiveState.fluidRainCatcher ~= nil then
        _, ok = Util.call(container, "setRainCatcher",
            finiteNumber(effectiveState.fluidRainCatcher) or 0)
        if not ok then return fail("fluid_rain_catcher_restore_failed") end
    end
    if not restoreFlag(container, "setCanPlayerEmpty",
        chooseValue(canPlayerEmpty, oldCanPlayerEmpty)
    )
    then
        return false, "fluid_open_state_restore_failed"
    end
    if not restoreFlag(container, "setInputLocked",
        chooseValue(inputLocked, oldInputLocked)
    )
    then
        return false, "fluid_lock_state_restore_failed"
    end
    return true
end

function Portable.CopyFluidState(state)
    if type(state) ~= "table" then return nil end
    local output = {}
    local primaryType = state.fluidPrimaryType or state.fluidType
    local entries = copyFluidEntries(state.fluids)
    local fields = {
        "fluidAmount", "fluidCapacity",
        "fluidInputLocked", "fluidCanPlayerEmpty", "fluidRainCatcher",
    }
    for i = 1, #fields do
        local key = fields[i]
        if state[key] ~= nil then output[key] = state[key] end
    end
    if primaryType then output.fluidPrimaryType = tostring(primaryType) end
    -- Keep the explicit list until Defaults.Diff can compare it with the
    -- definition.  A one-entry list is redundant for a single-fluid default,
    -- but it is meaningful when replacing a mixed default.
    if #entries > 0 then
        output.fluids = entries
    end
    return output
end

-- Returns the bounded, network-safe view of an item state. Persistence keeps
-- the broader compatibility state; network payloads should not carry arbitrary
-- modData or duplicate fields already present beside itemState.
function Portable.ProjectNetworkState(state, options)
    local output = {}
    options = type(options) == "table" and options or {}
    local exclude = type(options.exclude) == "table" and options.exclude or {}
    local maxString = options.maxStringLength
        or NETWORK_MAX_STRING_LENGTH
    local key
    local value
    local kind
    local primaryType
    local entries
    local amount
    local definition
    local definitionResolved
    local keepSingleFluid
    local maxModDataKeys
    local copied
    local modKey
    local modValue
    if type(state) ~= "table" then return output end

    if options.fullType then
        definition, definitionResolved = Defaults.Resolve(options.fullType)
        if definitionResolved then
            definition = Defaults.Compact(definition)
            keepSingleFluid = type(definition.fluids) == "table"
                and #definition.fluids > 1
        end
    end

    for key, value in pairs(state) do
        if key ~= "modData" and key ~= "fluids"
            and key ~= "foodLastAgedHours"
            and not exclude[key]
        then
            kind = type(value)
            if kind == "string" then
                value = boundedString(value, maxString)
                if value then output[key] = value end
            elseif kind == "number" then
                value = finiteNumber(value)
                if value ~= nil then output[key] = value end
            elseif kind == "boolean" then
                output[key] = value
            end
        end
    end

    primaryType = output.fluidPrimaryType or output.fluidType
    if primaryType then
        output.fluidPrimaryType = boundedString(primaryType,
            NETWORK_MAX_FLUID_STRING_LENGTH)
        output.fluidType = nil
    end
    entries = copyFluidEntries(state.fluids, NETWORK_MAX_FLUID_STRING_LENGTH)
    amount = finiteNumber(output.fluidAmount)
    if #entries > 0
        and not (keepSingleFluid ~= true and #entries == 1
            and entries[1].type == tostring(primaryType or "")
            and amount ~= nil
            and math.abs(entries[1].amount - amount) <= EPSILON)
    then
        output.fluids = entries
    else
        output.fluids = nil
    end

    if options.includeModData == true
        and type(state.modData) == "table"
    then
        maxModDataKeys = math.max(0, math.floor(tonumber(
            options.maxModDataKeys or NETWORK_MAX_MODDATA_KEYS
        ) or NETWORK_MAX_MODDATA_KEYS))
        copied = 0
        for modKey, modValue in pairs(state.modData) do
            if copied >= maxModDataKeys then break end
            kind = type(modValue)
            if kind == "string" then
                modValue = boundedString(modValue, maxString)
            elseif kind == "number" then
                modValue = finiteNumber(modValue)
            elseif kind ~= "boolean" then
                modValue = nil
            end
            modKey = boundedString(modKey, maxString)
            if modKey and modValue ~= nil then
                output.modData = output.modData or {}
                output.modData[modKey] = modValue
                copied = copied + 1
            end
        end
    end
    return output
end

Portable.NetworkState = Portable.ProjectNetworkState

return Portable
