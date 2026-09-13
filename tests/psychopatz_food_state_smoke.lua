local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Portable = Inventory.PortableItemState
local Types = Inventory.ItemTypeRegistry
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function makeFood(fullType)
    local item = {
        fullType = fullType, age = 1.25, cooked = true, burnt = false,
        frozen = false, freezingTime = 12, hungChange = -0.2,
        thirstChange = -0.1, dangerousUncooked = true, poison = true,
        poisonDetectionLevel = 3, poisonLevelForRecipe = 2,
        poisonPower = 5, rottenTime = 0.25, cookedInMicrowave = true,
        tainted = true, fertilized = true, fertilizedTime = 4,
        heat = 2, lastCookMinute = 12, cookingTime = 9,
        foodLastAgedHours = 42, foodCreatedAtHours = 41,
        weight = 0.5,
    }
    function item:getFullType() return self.fullType end
    function item:getActualWeight() return self.weight end
    function item:getWeight() return self.weight end
    function item:getModData() return {} end
    function item:getAge() return self.age end
    function item:setAge(value) self.age = value end
    function item:isCooked() return self.cooked end
    function item:setCooked(value) self.cooked = value end
    function item:isBurnt() return self.burnt end
    function item:setBurnt(value) self.burnt = value end
    function item:isFrozen() return self.frozen end
    function item:setFrozen(value) self.frozen = value end
    function item:getFreezingTime() return self.freezingTime end
    function item:setFreezingTime(value) self.freezingTime = value end
    function item:getHungChange() return self.hungChange end
    function item:setHungChange(value) self.hungChange = value end
    function item:getThirstChange() return self.thirstChange end
    function item:setThirstChange(value) self.thirstChange = value end
    function item:isbDangerousUncooked() return self.dangerousUncooked end
    function item:setbDangerousUncooked(value) self.dangerousUncooked = value end
    function item:isPoison() return self.poison end
    function item:getPoisonDetectionLevel() return self.poisonDetectionLevel end
    function item:setPoisonDetectionLevel(value) self.poisonDetectionLevel = value end
    function item:getPoisonLevelForRecipe() return self.poisonLevelForRecipe end
    function item:setPoisonLevelForRecipe(value) self.poisonLevelForRecipe = value end
    function item:getPoisonPower() return self.poisonPower end
    function item:setPoisonPower(value) self.poisonPower = value end
    function item:getRottenTime() return self.rottenTime end
    function item:setRottenTime(value) self.rottenTime = value end
    function item:isCookedInMicrowave() return self.cookedInMicrowave end
    function item:setCookedInMicrowave(value) self.cookedInMicrowave = value end
    function item:isTainted() return self.tainted end
    function item:setTainted(value) self.tainted = value end
    function item:isFertilized() return self.fertilized end
    function item:setFertilized(value) self.fertilized = value end
    function item:getFertilizedTime() return self.fertilizedTime end
    function item:setFertilizedTime(value) self.fertilizedTime = value end
    function item:getHeat() return self.heat end
    function item:setHeat(value) self.heat = value end
    function item:getLastCookMinute() return self.lastCookMinute end
    function item:setLastCookMinute(value) self.lastCookMinute = value end
    function item:getCookingTime() return self.cookingTime end
    function item:setCookingTime(value) self.cookingTime = value end
    item.isFood = true
    return item
end

Types.load(nil)
Types.scan({ "Base.Apple" })
local source = makeFood("Base.Apple")
local encoded = Inventory.encodeItem(source, 1)
truthy(encoded, "food record encodes")
truthy(Util.hasFlag(encoded[C.FLAGS], C.FLAG_FOOD),
    "food codec selected")
    truthy(encoded[C.STATE][1][8],
    "optional food fields use a compact presence mask")
truthy(Util.hasFlag(encoded[C.STATE][1][8], 8192),
    "food lifecycle checkpoint is persisted in the food codec")
truthy(Util.hasFlag(encoded[C.STATE][1][8], 16384),
    "food creation anchor is persisted in the food codec")

local decoded = Inventory.decodeItem(encoded, function()
    return makeFood("Base.Apple")
end)
truthy(decoded, "food record decodes")
equal(decoded:getAge(), 1.25, "age restored")
equal(decoded.poisonPower, 5, "poison power restored")
equal(decoded.tainted, true, "taint restored")
equal(decoded.fertilizedTime, 4, "fertilized time restored")
equal(decoded:getCookingTime(), 9, "cooking time restored")
equal(decoded.foodLastAgedHours, 42, "lifecycle checkpoint restored")
equal(decoded.foodCreatedAtHours, 41, "food creation anchor restored")

local state = { age = 0, frozen = false }
local profile = { food = true, offAge = 1, offAgeMax = 2 }
local changed, status = Portable.AdvanceFoodState(
    state, profile, 0, { foodRotSpeed = 1 }
)
truthy(changed, "lifecycle initializes checkpoint")
changed, status = Portable.AdvanceFoodState(
    state, profile, 24, { foodRotSpeed = 1 }
)
truthy(changed, "lifecycle advances age")
equal(state.age, 1, "lifecycle age uses days")
equal(status.stale, true, "lifecycle status derives stale state")

local frozenState = { age = 0.25, frozen = true, freezingTime = 100 }
changed = Portable.AdvanceFoodState(
    frozenState, profile, 0, { foodRotSpeed = 1, keepFrozen = true }
)
truthy(changed, "freezer policy initializes checkpoint")
Portable.AdvanceFoodState(
    frozenState, profile, 240, { foodRotSpeed = 1, keepFrozen = true }
)
equal(frozenState.age, 0.25, "freezer policy stops food aging")
equal(frozenState.frozen, true, "freezer policy preserves frozen state")

local thawingState = { age = 0.25, frozen = true, freezingTime = 100 }
Portable.AdvanceFoodState(
    thawingState, profile, 0, { foodRotSpeed = 1 }
)
Portable.AdvanceFoodState(
    thawingState, profile, 2, { foodRotSpeed = 1 }
)
equal(thawingState.frozen, false, "ambient policy thaws food")

print("psychopatz_food_state_smoke: PASS")
