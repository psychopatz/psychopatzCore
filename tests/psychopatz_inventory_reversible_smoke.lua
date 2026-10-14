local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local item = {
    fullType = "Base.Katana",
    condition = 7,
    conditionMax = 10,
    weight = 2,
}
function item:getFullType() return self.fullType end
function item:getCondition() return self.condition end
function item:getConditionMax() return self.conditionMax end
function item:getActualWeight() return self.weight end
function item:getWeight() return self.weight end
function item:isFavorite() return false end
function item:isCustomName() return false end
function item:getModData() return {} end

local source = Inventory.createVirtualInventory({ maxWeight = 100 })
local destination = Inventory.createVirtualInventory({ maxWeight = 100 })
truthy(source:add(item), "source item")

local moved, handle = Inventory.transfer(
    source,
    destination,
    "Base.Katana",
    1,
    { skipAuthorityCheck = true, reversible = true }
)
truthy(moved, "reversible transfer")
truthy(handle and type(handle.rollback) == "function", "undo handle")
equal(source:count("Base.Katana"), 0, "source after transfer")
equal(destination:count("Base.Katana"), 1, "destination after transfer")
truthy(handle:rollback(), "reversible transfer rollback")
equal(source:count("Base.Katana"), 1, "source after rollback")
equal(destination:count("Base.Katana"), 0, "destination after rollback")
truthy(handle:rollback(), "rollback is idempotent")

-- A physical destination returns native objects, not item-record tables.  The
-- reversible path must remove that exact object even when another matching
-- full type is added afterward.
local physicalSource = Inventory.createVirtualInventory({ maxWeight = 100 })
local nativeDestination = { items = {} }
function nativeDestination:add(record)
    local native = { fullType = record.fullType, marker = #self.items + 1 }
    self.items[#self.items + 1] = native
    return true, native
end
function nativeDestination:_nativeRemove(native)
    for index = #self.items, 1, -1 do
        if self.items[index] == native then
            table.remove(self.items, index)
            return true
        end
    end
    return false
end
truthy(physicalSource:add(item), "physical source item")
local physicalMoved, physicalHandle = Inventory.transfer(
    physicalSource,
    nativeDestination,
    "Base.Katana",
    1,
    { skipAuthorityCheck = true, reversible = true }
)
truthy(physicalMoved, "physical reversible transfer")
local movedNative = nativeDestination.items[1]
nativeDestination.items[#nativeDestination.items + 1] = {
    fullType = "Base.Katana", marker = "decoy"
}
truthy(physicalHandle:rollback(), "physical rollback")
equal(#nativeDestination.items, 1, "physical rollback preserves decoy")
equal(nativeDestination.items[1].marker, "decoy",
    "physical rollback removes exact native object")
equal(physicalSource:count("Base.Katana"), 1,
    "physical rollback restores source record")
equal(movedNative.marker, 1, "native object was the moved object")

print("psychopatz inventory reversible smoke: ok")
