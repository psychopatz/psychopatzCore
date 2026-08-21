local SHARED_ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/shared/"
local COMMON_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. COMMON_ROOT .. "?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

PsychopatzCore = {}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end
isClient = function() return false end
isServer = function() return true end
instanceof = function(object, className)
    return className == "IsoDeadBody" and object.isDeadBody == true
end

local nextItemId = 10
local function newItem(fullType, name)
    nextItemId = nextItemId + 1
    local item = {
        id = nextItemId, fullType = fullType, name = name or fullType,
        weight = 1, modData = {},
    }
    function item:getID() return self.id end
    function item:getFullType() return self.fullType end
    function item:getDisplayName() return self.name end
    function item:getName() return self.name end
    function item:getCategory() return "Item" end
    function item:getContainer() return self.container end
    function item:getActualWeight() return self.weight end
    function item:getWeight() return self.weight end
    function item:setActualWeight(value) self.weight = value end
    function item:getModData() return self.modData end
    function item:isFavorite() return false end
    function item:isCustomName() return false end
    function item:IsDrainable() return false end
    return item
end

InventoryItemFactory = {
    CreateItem = function(fullType) return newItem(fullType) end,
}
instanceItem = function(fullType) return newItem(fullType) end

local addPackets = 0
local removePackets = 0
sendAddItemToContainer = function() addPackets = addPackets + 1 end
sendRemoveItemFromContainer = function() removePackets = removePackets + 1 end

local function newContainer(containerType, items)
    local container = { values = items or {}, containerType = containerType }
    for index = 1, #container.values do
        container.values[index].container = container
    end
    function container:getType() return self.containerType end
    function container:getItems() return list(self.values) end
    function container:AddItem(item)
        self.values[#self.values + 1] = item
        item.container = self
        return item
    end
    function container:DoRemoveItem(item)
        for index = 1, #self.values do
            if self.values[index] == item then
                table.remove(self.values, index)
                item.container = nil
                return
            end
        end
    end
    return container
end

local function newSquare(x, y, z)
    local square = {
        x = x, y = y, z = z, objects = {}, static = {}, world = {},
    }
    function square:getX() return self.x end
    function square:getY() return self.y end
    function square:getZ() return self.z end
    function square:getObjects() return list(self.objects) end
    function square:getStaticMovingObjects() return list(self.static) end
    function square:getWorldObjects() return list(self.world) end
    function square:transmitRemoveItemFromSquare(worldObject)
        for index = 1, #self.world do
            if self.world[index] == worldObject then
                table.remove(self.world, index)
                return
            end
        end
    end
    function square:AddWorldInventoryItem(item)
        local worldObject = { item = item }
        function worldObject:getItem() return self.item end
        self.world[#self.world + 1] = worldObject
        return worldObject
    end
    return square
end

local fridgeItem = newItem("Base.CannedBeans", "Canned Beans")
local moddedItem = newItem("SomeMod.SpecialFood", "Special Food")
local corpseItem = newItem("Base.Bandage", "Bandage")
local floorItem = newItem("Base.Hammer", "Hammer")
local fridge = newContainer("fridge", { fridgeItem, moddedItem })
local corpseInventory = newContainer("inventorymale", { corpseItem })
local destination = newContainer("npc", {})

local origin = newSquare(100, 100, 0)
origin.objects[1] = {
    getContainer = function() return fridge end,
    getObjectName = function() return "Fridge" end,
}
local corpseSquare = newSquare(101, 100, 0)
corpseSquare.static[1] = {
    isDeadBody = true,
    getContainer = function() return corpseInventory end,
    getObjectName = function() return "Corpse" end,
}
local floorSquare = newSquare(100, 101, 0)
floorSquare:AddWorldInventoryItem(floorItem)

local squares = {
    ["100:100:0"] = origin,
    ["101:100:0"] = corpseSquare,
    ["100:101:0"] = floorSquare,
}
local cell = {
    getGridSquare = function(_, x, y, z)
        return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
    end,
}

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"

local containerOnly = WorldLoot.FindSources({
    x = 100, y = 100, z = 0, radius = 2, cell = cell,
    sourceTypes = { containers = true },
})
equal(#containerOnly.sources, 1, "container-only source count")
equal(containerOnly.sources[1].sourceType, "container", "container source type")
equal(containerOnly.sources[1].container, nil, "descriptor has no raw container")
equal(containerOnly.sources[1].object, nil, "descriptor has no raw object")

local mixed = WorldLoot.FindSources({
    x = 100, y = 100, z = 0, radius = 2, cell = cell,
    sourceTypes = { containers = true, floorItems = true, corpses = true },
})
equal(#mixed.sources, 3, "mixed source count")
equal(mixed.counts.container, 1, "container count")
equal(mixed.counts.floor, 1, "floor count")
equal(mixed.counts.corpse, 1, "corpse count")

local byType = {}
for index = 1, #mixed.sources do
    byType[mixed.sources[index].sourceType] = mixed.sources[index]
end
local containerItems = WorldLoot.ListItems(byType.container.sourceToken)
equal(#containerItems, 2, "container item enumeration")
equal(containerItems[2].fullType, "SomeMod.SpecialFood", "modded FullType")
equal(containerItems[1].item, nil, "item descriptor has no raw item")
local corpseItems = WorldLoot.ListItems(byType.corpse.sourceToken)
equal(corpseItems[1].fullType, "Base.Bandage", "corpse enumeration")
local floorItems = WorldLoot.ListItems(byType.floor.sourceToken)
equal(floorItems[1].fullType, "Base.Hammer", "floor enumeration")

local wrongQuantity, wrongQuantityReason = WorldLoot.Transfer({
    sourceToken = byType.container.sourceToken,
    itemToken = containerItems[1].itemToken,
    quantity = 2,
    destination = destination,
})
equal(wrongQuantity, false, "multi-unit exact item transfer rejected")
equal(wrongQuantityReason, "item_quantity_invalid", "quantity rejection reason")
equal(#fridge.values, 2, "quantity rejection preserves source")

local moved = WorldLoot.Transfer({
    sourceToken = byType.container.sourceToken,
    itemToken = containerItems[1].itemToken,
    destination = destination,
})
equal(moved, true, "container transfer")
equal(#fridge.values, 1, "container source decremented")
equal(#destination.values, 1, "destination incremented")
truthy(addPackets > 0, "destination add replicated")
truthy(removePackets > 0, "source remove replicated")

local reservedItems = WorldLoot.ListItems(byType.container.sourceToken)
local reservation = WorldLoot.ReserveItem(byType.container.sourceToken,
    reservedItems[1].itemToken, "npc:1")
truthy(reservation and reservation.reservationToken,
    "exact item reservation created")
local blocked, blockedReason = WorldLoot.Transfer({
    sourceToken = byType.container.sourceToken,
    itemToken = reservedItems[1].itemToken,
    destination = destination,
})
equal(blocked, false, "reserved item rejects unrelated transfer")
equal(blockedReason, "item_reserved", "reservation rejection reason")
truthy(WorldLoot.ReleaseReservation(reservation.reservationToken, "test"),
    "reservation released")

local corpseMoved = WorldLoot.Transfer({
    sourceToken = byType.corpse.sourceToken,
    itemToken = corpseItems[1].itemToken,
    destination = destination,
})
equal(corpseMoved, true, "corpse transfer")
equal(#corpseInventory.values, 0, "corpse source decremented")

local staleCorpseItem = newItem("Base.AlcoholWipes", "Alcohol Wipes")
corpseInventory:AddItem(staleCorpseItem)
local staleSearch = WorldLoot.FindSources({
    x = 100, y = 100, z = 0, radius = 2, cell = cell,
    sourceTypes = { corpses = true },
})
local staleItems = WorldLoot.ListItems(staleSearch.sources[1].sourceToken)
corpseInventory:DoRemoveItem(staleCorpseItem)
local stale, staleReason = WorldLoot.Transfer({
    sourceToken = staleSearch.sources[1].sourceToken,
    itemToken = staleItems[1].itemToken,
    destination = destination,
})
equal(stale, false, "stale transfer rejected")
equal(staleReason, "item_unavailable", "stale transfer reason")

local floorMoved = WorldLoot.Transfer({
    sourceToken = byType.floor.sourceToken,
    itemToken = floorItems[1].itemToken,
    destination = destination,
})
equal(floorMoved, true, "floor transfer")
equal(#floorSquare.world, 0, "floor object removed")

local rollbackItem = newItem("Base.Nails", "Nails")
fridge:AddItem(rollbackItem)
local rollbackSearch = WorldLoot.FindSources({
    x = 100, y = 100, z = 0, radius = 0, cell = cell,
    sourceTypes = { containers = true },
})
local rollbackItems = WorldLoot.ListItems(rollbackSearch.sources[1].sourceToken)
local rejectingDestination = {
    add = function() return false, "capacity" end,
}
local failed, failedReason = WorldLoot.Transfer({
    sourceToken = rollbackSearch.sources[1].sourceToken,
    itemToken = rollbackItems[#rollbackItems].itemToken,
    destination = rejectingDestination,
})
equal(failed, false, "destination failure reported")
equal(failedReason, "capacity", "destination failure reason")
equal(fridge.values[#fridge.values], rollbackItem, "failed transfer restored source")

local removeContainerItem = newItem("Base.Saw", "Saw")
local removeCorpseItem = newItem("Base.RippedSheets", "Ripped Sheets")
local removeFloorItem = newItem("Base.Axe", "Axe")
fridge:AddItem(removeContainerItem)
corpseInventory:AddItem(removeCorpseItem)
floorSquare:AddWorldInventoryItem(removeFloorItem)
local removalSearch = WorldLoot.FindSources({
    x = 100, y = 100, z = 0, radius = 2, cell = cell,
    sourceTypes = { containers = true, floorItems = true, corpses = true },
})
local removalByType = {}
for index = 1, #removalSearch.sources do
    removalByType[removalSearch.sources[index].sourceType] =
        removalSearch.sources[index]
end
local function tokenFor(source, fullType)
    local values = WorldLoot.ListItems(source.sourceToken)
    for index = 1, #values do
        if values[index].fullType == fullType then return values[index].itemToken end
    end
end
local beforeContainer = #fridge.values
local removedContainer = WorldLoot.RemoveItem(
    removalByType.container.sourceToken,
    tokenFor(removalByType.container, "Base.Saw"), 1)
equal(removedContainer, true, "direct container removal")
equal(#fridge.values, beforeContainer - 1, "container removal mutates source")
local removedCorpse = WorldLoot.RemoveItem(removalByType.corpse.sourceToken,
    tokenFor(removalByType.corpse, "Base.RippedSheets"), 1)
equal(removedCorpse, true, "direct corpse removal")
equal(#corpseInventory.values, 0, "corpse removal mutates source")
local beforeFloor = #floorSquare.world
local removedFloor = WorldLoot.RemoveItem(removalByType.floor.sourceToken,
    tokenFor(removalByType.floor, "Base.Axe"), 1)
equal(removedFloor, true, "direct floor removal")
equal(#floorSquare.world, beforeFloor - 1, "floor removal mutates world square")

local capped = WorldLoot.FindSources({
    x = 100, y = 100, z = 0, radius = 2, cell = cell,
    sourceTypes = { containers = true, floorItems = true, corpses = true },
    maxCandidates = 1,
})
equal(#capped.sources, 1, "candidate cap")
equal(capped.truncated, true, "candidate truncation flag")

truthy(WorldLoot.ReleaseSession(mixed.sessionId), "session released")
print("psychopatz_world_loot_smoke: ok")
