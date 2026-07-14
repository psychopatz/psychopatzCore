local SHARED_ROOT = "Contents/mods/PsychopatzCore/42.16/media/lua/shared/"
local SERVER_ROOT = "Contents/mods/PsychopatzCore/42.16/media/lua/server/"
package.path = SHARED_ROOT .. "?.lua;" .. SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local serverCommandHandler
Events = {
    OnServerCommand = {
        Add = function(callback) serverCommandHandler = callback end,
    },
}

local multiplayerServer = false
local multiplayerClient = false
local sentApproval
local nativeCommand
local localTeleport
local player = {
    teleportTo = function(_, x, y, z) localTeleport = { x = x, y = y, z = z } end,
}

isServer = function() return multiplayerServer end
isClient = function() return multiplayerClient end
getSpecificPlayer = function() return player end
sendServerCommand = function(target, module, command, args)
    sentApproval = { target = target, module = module, command = command, args = args }
end
SendCommandToServer = function(command) nativeCommand = command end

local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"
assertEqual(Teleport.ToCoordinates(player, 12000.5, 13000.25, 1.9), true, "single-player teleport")
assertEqual(localTeleport.x, 12000.5, "single-player x")
assertEqual(localTeleport.z, 1, "single-player z normalized")

multiplayerServer = true
assertEqual(Teleport.ToCoordinates(player, 25000.5, 26000.5, 2), true, "server approval")
assertEqual(sentApproval.target, player, "approval target")
assertEqual(sentApproval.module, "PsychopatzCore", "approval module")
assertEqual(sentApproval.command, "TeleportApproved", "approval command")

multiplayerServer = false
multiplayerClient = true
serverCommandHandler(sentApproval.module, sentApproval.command, sentApproval.args)
assertEqual(nativeCommand, "/teleportto 25000.5,26000.5,2", "base-game teleport handoff")
assertEqual(Teleport.ToCoordinates(player, 0 / 0, 1, 0), false, "invalid coordinate rejected")

local addedPackets = {}
local removedPackets = {}
sendAddItemToContainer = function(container, item)
    addedPackets[#addedPackets + 1] = { container = container, item = item }
end
sendRemoveItemFromContainer = function(container, item)
    removedPackets[#removedPackets + 1] = { container = container, item = item }
end

local nextID = 100
local function newItem(fullType, container)
    nextID = nextID + 1
    local item = {
        id = nextID,
        fullType = fullType,
        container = container,
        condition = 10,
        syncCount = 0,
    }
    function item:getID() return self.id end
    function item:getFullType() return self.fullType end
    function item:getContainer() return self.container end
    function item:IsDrainable() return false end
    function item:setCondition(value) self.condition = value end
    function item:getConditionMax() return 10 end
    function item:syncItemFields() self.syncCount = self.syncCount + 1 end
    return item
end

local function newContainer()
    local values = {}
    local container = { values = values }
    function container:getItems() return javaList(values) end
    function container:getItemById(id)
        for _, item in ipairs(values) do
            if item:getID() == id then return item end
        end
        return nil
    end
    function container:AddItems(fullType, count)
        local created = {}
        for _ = 1, count do
            local item = newItem(fullType, self)
            values[#values + 1] = item
            created[#created + 1] = item
        end
        return javaList(created)
    end
    function container:DoRemoveItem(target)
        for index, item in ipairs(values) do
            if item == target then
                table.remove(values, index)
                return
            end
        end
    end
    return container
end

multiplayerClient = false
multiplayerServer = true
local ItemTransfer = require "PsychopatzCore/Inventory/PsychopatzItemTransfer"
local inventory = newContainer()
function player:getInventory() return inventory end
function player:getPrimaryHandItem() return self.primary end
function player:getSecondaryHandItem() return self.secondary end
function player:setPrimaryHandItem(item) self.primary = item end
function player:setSecondaryHandItem(item) self.secondary = item end

local created = ItemTransfer.GiveToPlayer(player, "Base.Axe", 2, { condition = 7 })
assertEqual(created:size(), 2, "give count")
assertEqual(created:get(0).condition, 7, "state applied before sync")
assertEqual(created:get(0).syncCount, 1, "item fields synced")
assertEqual(#addedPackets, 2, "native add packets")

local first = created:get(0)
local second = created:get(1)
player.primary = first
local beforeDuplicate = #inventory.values
local duplicate, duplicateReason = ItemTransfer.TakeFromPlayer(player, { first:getID(), first:getID() })
assertEqual(duplicate, nil, "duplicates rejected")
assertEqual(duplicateReason, "invalid_item_selection", "duplicate reason")
assertEqual(#inventory.values, beforeDuplicate, "validation completed before mutation")

local taken = ItemTransfer.TakeFromPlayer(player, { first:getID(), second:getID() }, {
    expectedFullType = "Base.Axe",
})
assertEqual(#taken, 2, "take count")
assertEqual(player.primary, nil, "held reference cleared")
assertEqual(#inventory.values, 0, "items removed")
assertEqual(#removedPackets, 2, "native remove packets")

local bag = newItem("Base.Bag_DuffelBag", inventory)
local bagInventory = newContainer()
function bag:getItemContainer() return bagInventory end
inventory.values[#inventory.values + 1] = bag
local nested = bagInventory:AddItems("Base.Money", 1):get(0)
local nestedTaken = ItemTransfer.TakeFromPlayer(player, nested:getID())
assertEqual(nestedTaken[1], nested, "nested item resolved")
assertEqual(#bagInventory.values, 0, "nested item removed")
assertEqual(#inventory.values, 1, "containing bag preserved")

print("psychopatz_world_inventory_smoke: ok")
