local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Display = require
    "PsychopatzCore/Inventory/PsychopatzInventoryDisplayState"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
    return value
end

local foodFlags = C.FLAG_CONDITION + C.FLAG_FOOD
local foodRecord = {
    1, 2, foodFlags, C.CODEC_FOOD,
    { 7, { 1.5, true, false, false, 0, -0.2, -0.1,
        32 + 16384 + 32768 + 65536 + 131072 + 262144,
        42, 99, 720, 72, 18, 36 } },
    0.5,
}
local foodState, foodKnown = Display.ProjectRecord(foodRecord)
truthy(foodKnown, "food state known")
equal(foodState.condition, 7, "food condition")
equal(foodState.age, 1.5, "food age")
equal(foodState.cooked, true, "food cooked")
equal(foodState.rottenTime, 42, "food optional field")
equal(foodState.foodLastAgedHours, nil, "aging checkpoint omitted")
equal(foodState.foodCreatedAtHours, 99, "food creation anchor")
equal(foodState.calories, 720, "food calories")
equal(foodState.carbohydrates, 72, "food carbohydrates")
equal(foodState.proteins, 18, "food proteins")
equal(foodState.lipids, 36, "food lipids")

local fluidFlags = C.FLAG_CONDITION + C.FLAG_FLUID
local fluidRecord = {
    2, 1, fluidFlags, C.CODEC_FLUID,
    { 4, {
        fluidAmount = 0.75, fluidCapacity = 1,
        fluidPrimaryType = "Water", fluids = {
            { type = "Water", amount = 0.5 },
            { type = "Bleach", amount = 0.25 },
        },
    } },
    0.4,
}
local fluidState, fluidKnown = Inventory.projectItemState(fluidRecord)
truthy(fluidKnown, "fluid state known")
equal(fluidState.fluidPrimaryType, "Water", "fluid primary")
equal(#fluidState.fluids, 2, "fluid mixture entries")
equal(fluidState.fluids[2].type, "Bleach", "fluid mixture type")

local compactState, compactKnown = Display.StateForRow({
    fullType = "Base.WaterBottle",
    compactItem = { cond = 3, uses = 0.5, fav = true,
        fluidState = { fluidAmount = 0.5, fluidPrimaryType = "Water" } },
})
truthy(compactKnown, "compact state known")
equal(compactState.condition, 3, "compact condition alias")
equal(compactState.usedDelta, 0.5, "compact uses alias")
equal(compactState.favorite, true, "compact favorite alias")

local projected = Display.ProjectNetworkState({
    condition = 4, foodLastAgedHours = 99,
    modData = { serial = "private" },
    fluidAmount = 1,
    fluidPrimaryType = "Water",
    fluids = { { type = "Water", amount = 1 } },
})
equal(projected.condition, 4, "network condition")
equal(projected.foodLastAgedHours, nil, "network checkpoint omitted")
equal(projected.modData, nil, "network modData omitted")
equal(projected.fluids, nil, "redundant single fluid omitted")

print("psychopatz_inventory_display_state_smoke: PASS")
