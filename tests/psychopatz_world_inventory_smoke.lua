local SHARED_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
local SERVER_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
local COMMON_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;"
    .. SERVER_ROOT .. "?.lua;" .. package.path

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
ImmutableColor = {
    new = function(r, g, b)
        return {
            getRedFloat = function() return r end,
            getGreenFloat = function() return g end,
            getBlueFloat = function() return b end,
        }
    end,
}
local function newItem(fullType, container)
    nextID = nextID + 1
    local item = {
        id = nextID,
        fullType = fullType,
        container = container,
        condition = 10,
        modelIndex = 0,
        customColor = false,
        colorR = 1,
        colorG = 1,
        colorB = 1,
        syncCount = 0,
        visual = {
            baseTexture = -1,
            textureChoice = -1,
        },
    }
    function item:getID() return self.id end
    function item:getFullType() return self.fullType end
    function item:getContainer() return self.container end
    function item:getName() return self.customName or self.fullType end
    function item:isCustomName() return self.customName ~= nil end
    function item:setName(value) self.customName = value end
    function item:isFavorite() return self.favorite == true end
    function item:setFavorite(value) self.favorite = value end
    function item:getCondition() return self.condition end
    function item:IsDrainable() return false end
    function item:setCondition(value) self.condition = value end
    function item:getConditionMax() return 10 end
    function item:getModelIndex() return self.modelIndex end
    function item:setModelIndex(value) self.modelIndex = value end
    function item:isCustomColor() return self.customColor end
    function item:setCustomColor(value) self.customColor = value end
    function item:getColorRed() return self.colorR end
    function item:getColorGreen() return self.colorGreen or self.colorG end
    function item:getColorBlue() return self.colorBlue or self.colorB end
    function item:setColorRed(value) self.colorR = value end
    function item:setColorGreen(value) self.colorG = value end
    function item:setColorBlue(value) self.colorB = value end
    function item:syncItemFields() self.syncCount = self.syncCount + 1 end
    function item:getVisual() return self.visual end
    function item:getClothingItem() return {} end
    function item.visual:setBaseTexture(value) self.baseTexture = value end
    function item.visual:getBaseTexture() return self.baseTexture end
    function item.visual:setTextureChoice(value) self.textureChoice = value end
    function item.visual:getTextureChoice() return self.textureChoice end
    function item.visual:setDecal(value) self.decal = value end
    function item.visual:getDecal() return self.decal end
    function item.visual:setTint(value) self.tint = value end
    function item.visual:getTint() return self.tint end
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

local created = ItemTransfer.GiveToPlayer(player, "Base.Axe", 2, {
    condition = 7,
    visualFullType = "Base.Axe",
    visualBaseTexture = 3,
    visualTextureChoice = 6,
    visualDecal = "SpiffoLogo",
    visualTintR = 0.9,
    visualTintG = 0.8,
    visualTintB = 0.1,
    visualModelIndex = 1,
    visualCustomColor = true,
    visualColorR = 0.4,
    visualColorG = 0.5,
    visualColorB = 0.6,
})
assertEqual(created:size(), 2, "give count")
assertEqual(created:get(0).condition, 7, "state applied before sync")
assertEqual(created:get(0).syncCount, 0,
    "new item sent a premature SyncItemFields packet")
assertEqual(created:get(0).visual.baseTexture, 3,
    "visual base texture applied before sync")
assertEqual(created:get(0).visual.textureChoice, 6,
    "visual texture choice applied before sync")
assertEqual(created:get(0).visual.decal, "SpiffoLogo",
    "visual decal applied before sync")
assertEqual(created:get(0).visual.tint:getGreenFloat(), 0.8,
    "visual tint applied before sync")
assertEqual(created:get(0).modelIndex, 1,
    "item model index applied before sync")
assertEqual(created:get(0).colorG, 0.5,
    "item color applied before sync")
assertEqual(created:get(0).customColor, true,
    "item custom-color flag applied before sync")
assertEqual(#addedPackets, 2, "native add packets")

local first = created:get(0)
local second = created:get(1)
assertEqual(ItemTransfer.CaptureState(first).visualDecal,
    "SpiffoLogo", "visual decal captured for transfer")
assertEqual(ItemTransfer.CaptureState(first).visualModelIndex,
    1, "item model index captured for transfer")
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

local resolvedRoot = ItemTransfer.ResolvePlayerContainer(player, "root")
assertEqual(resolvedRoot, inventory, "root destination resolved")
local resolvedBag = ItemTransfer.ResolvePlayerContainer(player, bag:getID())
assertEqual(resolvedBag, bagInventory, "nested destination resolved")
local nestedCreated = ItemTransfer.GiveToPlayerContainer(
    player, bag:getID(), "Base.Bandage", 1, {
        condition = 6,
        favorite = true,
        customName = "Emergency Bandage",
    }
)
assertEqual(nestedCreated:size(), 1, "give to nested container")
assertEqual(nestedCreated:get(0).condition, 6, "nested state condition")
assertEqual(nestedCreated:get(0).favorite, true, "nested state favorite")
assertEqual(nestedCreated:get(0).customName, "Emergency Bandage", "nested custom name")

local captured = ItemTransfer.CaptureState(nestedCreated:get(0))
assertEqual(captured.condition, 6, "captured condition")
assertEqual(captured.favorite, true, "captured favorite")
assertEqual(captured.customName, "Emergency Bandage", "captured custom name")
assertEqual(captured.visualFullType, "Base.Bandage",
    "captured visual identity")

local capturedItem = nestedCreated:get(0)
function capturedItem:getModData()
    return {
        owner = "Forrest",
        nested = { ignored = true },
    }
end
local luaNext = next
next = nil
local kahluaCompatible, kahluaState = pcall(ItemTransfer.CaptureState, capturedItem)
next = luaNext
assertEqual(kahluaCompatible, true, "capture state avoids unavailable Kahlua next")
assertEqual(kahluaState.modData.owner, "Forrest", "scalar mod data captured")
assertEqual(kahluaState.modData.nested, nil, "nested mod data omitted")

print("psychopatz_world_inventory_smoke: ok")
