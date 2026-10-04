local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local SERVER_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
package.path = SHARED_ROOT .. "?.lua;" .. SERVER_ROOT .. "?.lua;"
    .. package.path

local function assertEqual(actual, expected, message)
    assert(actual == expected, message .. " (expected " .. tostring(expected)
        .. ", got " .. tostring(actual) .. ")")
end

local function javaList(values)
    local list = { values = values }
    function list:size()
        return #self.values
    end
    function list:get(index)
        return self.values[index + 1]
    end
    return list
end

local function makeContainer()
    local container = { items = {} }
    function container:getItems()
        return javaList(self.items)
    end
    function container:AddItem(fullType)
        if type(fullType) == "table" then
            fullType.container = self
            self.items[#self.items + 1] = fullType
            return fullType
        end
        local item = {
            fullType = fullType,
            count = 1,
            container = self,
        }
        function item:getFullType() return self.fullType end
        function item:getCount() return self.count end
    function item:setCount(value) self.count = value end
    function item:getContainer() return self.container end
    function item:syncItemFields() end
    self.items[#self.items + 1] = item
    return item
end
function container:AddItems(fullType, quantity)
    local result = {}
    for _ = 1, quantity do
        result[#result + 1] = self:AddItem(fullType)
    end
    return javaList(result)
end
    function container:DoRemoveItem(item)
        for index = #self.items, 1, -1 do
            if self.items[index] == item then
                table.remove(self.items, index)
                item.container = nil
                return
            end
        end
    end
    return container
end

PsychopatzCore = {}
local Currency = require "PsychopatzCore/Economy/PsychopatzCurrency"
assertEqual(PsychopatzCore.CurrencyDiagnostics.SETTING_ID,
    "PsychopatzCore.CurrencyAudit", "currency audit setting registration")
assertEqual(PsychopatzCore.CurrencyDiagnostics.IsEnabled(), false,
    "currency audit is disabled by default")
local addPackets = 0
local batchPackets = 0
local removePackets = 0
local statPackets = 0
isServer = function() return true end
sendAddItemToContainer = function() addPackets = addPackets + 1 end
sendAddItemsToContainer = function() batchPackets = batchPackets + 1 end
sendRemoveItemFromContainer = function() removePackets = removePackets + 1 end
sendItemStats = function() statPackets = statPackets + 1 end
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end
package.preload["PsychopatzCore/Economy/PsychopatzCurrency"] = function()
    return Currency
end

local ServerCurrency = require
    "PsychopatzCore/Economy/PsychopatzCurrencyServer"
assertEqual(ServerCurrency, Currency, "server currency service binding")

local container = makeContainer()
container:AddItems(Currency.MONEY_TYPE, 250)
local bundled, bundleReason = Currency.BundleLoose(container)
assertEqual(bundled, true, "bundle operation")
assertEqual(bundleReason, "bundled", "bundle operation reason")
local bundledSnapshot = Currency.Snapshot(container, { recursive = true })
assertEqual(bundledSnapshot.units, 250, "bundling preserves value")
assertEqual(bundledSnapshot.loose, 50, "bundling keeps remainder")
assertEqual(bundledSnapshot.bundles, 2, "bundling creates counted bundles")
assertEqual(bundledSnapshot.itemCount, 52, "bundling keeps physical records")

local unbundled, unbundleReason = Currency.Unbundle(container)
assertEqual(unbundled, true, "unbundle operation")
assertEqual(unbundleReason, "unbundled", "unbundle operation reason")
local unbundledSnapshot = Currency.Snapshot(container, { recursive = true })
assertEqual(unbundledSnapshot.units, 250, "unbundling preserves value")
assertEqual(unbundledSnapshot.loose, 250, "unbundling creates counted money")
assertEqual(unbundledSnapshot.bundles, 0, "unbundling removes bundles")
assertEqual(unbundledSnapshot.itemCount, 250, "unbundling keeps physical records")

local remainderContainer = makeContainer()
remainderContainer:AddItems(Currency.BUNDLE_TYPE, 2)
local removed, removeReason = Currency.RemoveUnits(
    remainderContainer, 50, { recursive = false })
assertEqual(removed, true, "partial bundle removal")
assertEqual(removeReason, "removed", "partial bundle removal reason")
local remainderSnapshot = Currency.Snapshot(
    remainderContainer, { recursive = false })
assertEqual(remainderSnapshot.units, 150, "partial bundle preserves value")
assertEqual(remainderSnapshot.loose, 50, "partial bundle creates change")
assertEqual(remainderSnapshot.bundles, 1, "partial bundle keeps remainder")
assertEqual(addPackets + batchPackets > 0, true,
    "multiplayer add synchronization")
assertEqual(removePackets > 0, true, "multiplayer remove synchronization")

-- A replacement-add failure must not destroy the source currency. This is
-- the failure mode that matters most for live MP inventories: remove first
-- is acceptable only when the original counted item can be restored.
local sourceContainer = makeContainer()
sourceContainer:AddItems(Currency.MONEY_TYPE, 100)
local failedDestination = { items = {} }
function failedDestination:getItems()
    return javaList(self.items)
end
function failedDestination:AddItem(value)
    if type(value) == "string" then return nil end
    value.container = self
    self.items[#self.items + 1] = value
    return value
end
local failedBundle, failedReason = Currency.BundleLoose(
    sourceContainer, failedDestination)
assertEqual(failedBundle, false, "failed bundle operation")
assertEqual(failedReason, "physical_add_failed",
    "failed bundle operation reason")
local restoredSnapshot = Currency.Snapshot(sourceContainer, {
    recursive = false,
})
assertEqual(restoredSnapshot.units, 100,
    "failed bundling restores the original value")
assertEqual(restoredSnapshot.loose, 100,
    "failed bundling restores loose money")
assertEqual(restoredSnapshot.bundles, 0,
    "failed bundling creates no replacement bundle")

print("psychopatz currency server smoke: ok")
