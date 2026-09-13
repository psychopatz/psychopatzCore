local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Defaults = Inventory.ItemStateDefaults
local Portable = Inventory.PortableItemState
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Types = Inventory.ItemTypeRegistry

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

Defaults.RegisterProvider(function(fullType)
    if fullType == "Base.MixedBottle" then
        return {
            fluidAmount = 1,
            fluidCapacity = 1,
            fluidPrimaryType = "Water",
            fluids = {
                { type = "Water", amount = 0.6 },
                { type = "Coffee", amount = 0.4 },
            },
        }
    end
    if fullType ~= "Base.TestBottle" then return nil end
    return {
        fluidAmount = 1,
        fluidCapacity = 1,
        fluidPrimaryType = "Water",
        fluids = { { type = "Water", amount = 1 } },
        condition = 10,
        usedDelta = 1,
    }
end, 7)

local defaultDelta = Defaults.Diff("Base.TestBottle", {
    fluidAmount = 1,
    fluidCapacity = 1,
    fluidPrimaryType = "Water",
    fluids = { { type = "Water", amount = 1 } },
    condition = 10,
    usedDelta = 1,
})
equal(defaultDelta, nil, "definition defaults are not serialized")
equal(Defaults.Diff("Base.TestBottle", {}), nil,
    "absent fluid state uses the definition default")

local partial = Defaults.Diff("Base.TestBottle", {
    fluidAmount = 0.5,
    fluidCapacity = 1,
    fluidPrimaryType = "Water",
    fluids = { { type = "Water", amount = 0.5 } },
})
truthy(partial, "partial fluid creates a delta")
equal(partial.fluidAmount, 0.5, "partial amount is retained")
equal(partial.fluids, nil, "single-fluid mixture is not duplicated")

local empty = Defaults.Diff("Base.TestBottle", { fluidAmount = 0 })
truthy(empty, "empty fluid creates an explicit delta")
equal(empty.fluidAmount, 0, "zero amount is not treated as missing")

local effective = Defaults.Apply("Base.TestBottle", empty)
equal(effective.fluidAmount, 0, "empty override applies")
equal(effective.fluidPrimaryType, nil, "empty clears inherited primary")
equal(effective.fluids, nil, "empty clears inherited mixture")

local itemState = Inventory.resolveItemState({
    type = "Base.TestBottle", itemState = partial,
})
equal(itemState.fluidAmount, 0.5, "effective item state resolves")
equal(itemState.fluidPrimaryType, "Water", "effective primary resolves")

local singleFromMixed = Defaults.Diff("Base.MixedBottle", {
    fluidAmount = 1,
    fluidPrimaryType = "Water",
    fluids = { { type = "Water", amount = 1 } },
})
truthy(singleFromMixed and singleFromMixed.fluids,
    "single-fluid override of mixed definition was lost")
equal(singleFromMixed.fluids[1].amount, 1,
    "single-fluid override amount changed")
local mixedEffective = Defaults.Apply("Base.MixedBottle", singleFromMixed)
equal(#mixedEffective.fluids, 1,
    "mixed definition did not apply single-fluid override")
equal(mixedEffective.fluids[1].type, "Water",
    "mixed definition applied the wrong single-fluid override")
local mixedNetwork = Portable.ProjectNetworkState({
    fluidAmount = 1, fluidPrimaryType = "Water",
    fluids = { { type = "Water", amount = 1 } },
}, { fullType = "Base.MixedBottle" })
equal(#mixedNetwork.fluids, 1,
    "network projection dropped a single-fluid mixed override")

Types.load(nil)
Types.scan({ "Base.TestBottle" })
local defaultItem = {
    fullType = "Base.TestBottle",
    fluidState = {
        fluidAmount = 1, fluidCapacity = 1,
        fluidPrimaryType = "Water",
        fluids = { { type = "Water", amount = 1 } },
    },
}
function defaultItem:getFullType() return self.fullType end
function defaultItem:getActualWeight() return 0.1 end
function defaultItem:getWeight() return 0.1 end
local defaultRecord = Inventory.encodeItem(defaultItem, 1)
truthy(defaultRecord, "default item encodes")
equal(defaultRecord[C.FLAGS] % (C.FLAG_FLUID * 2) >= C.FLAG_FLUID,
    false, "default fluid codec omits fluid payload")

local emptyItem = {
    fullType = "Base.TestBottle", fluidState = { fluidAmount = 0 },
}
function emptyItem:getFullType() return self.fullType end
function emptyItem:getActualWeight() return 0.1 end
function emptyItem:getWeight() return 0.1 end
local emptyRecord = Inventory.encodeItem(emptyItem, 1)
truthy(emptyRecord, "empty item encodes")
truthy(emptyRecord[C.FLAGS] % (C.FLAG_FLUID * 2) >= C.FLAG_FLUID,
    "empty fluid keeps an explicit payload")
equal(emptyRecord[C.STATE][1].fluidAmount, 0,
    "empty fluid amount is encoded as zero")

print("psychopatz_inventory_defaults_smoke: PASS")
