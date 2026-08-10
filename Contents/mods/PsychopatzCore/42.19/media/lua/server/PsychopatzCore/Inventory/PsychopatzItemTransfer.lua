require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore.ItemTransfer = PsychopatzCore.ItemTransfer or {}

local Transfer = PsychopatzCore.ItemTransfer

local ITEM_VISUAL_STATE_FIELDS = {
    baseTexture = "visualBaseTexture",
    textureChoice = "visualTextureChoice",
    tintR = "visualTintR",
    tintG = "visualTintG",
    tintB = "visualTintB",
}

local function isMultiplayerServer()
    return isServer and isServer() == true
end

local function normalizeCount(count)
    local value = math.floor(tonumber(count) or 1)
    if value < 1 then
        return nil
    end
    return value
end

local function normalizeFluidType(fluidType)
    if fluidType == nil then
        return nil
    end
    local value = tostring(fluidType)
    local colonPos = string.find(value, ":", 1, true)
    if colonPos then
        value = string.sub(value, 1, colonPos - 1)
    end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or string.lower(value) == "true" then
        return nil
    end
    return value
end

local function resolveScriptFluid(fluidType)
    local normalized = normalizeFluidType(fluidType)
    if not normalized or not getScriptManager then
        return nil, normalized
    end

    local manager = getScriptManager()
    if not manager or not manager.getFluid then
        return nil, normalized
    end

    local fluid = manager:getFluid(normalized)
    if not fluid and string.sub(normalized, 1, 5) == "Base." then
        fluid = manager:getFluid(string.sub(normalized, 6))
    elseif not fluid then
        fluid = manager:getFluid("Base." .. normalized)
    end
    return fluid, normalized
end

local function applyFluidState(item, state)
    if not item or not state or not item.getFluidContainer then
        return
    end
    local container = item:getFluidContainer()
    if not container then
        return
    end

    local scriptFluid, fluidType = resolveScriptFluid(state.fluidType)
    local amount = tonumber(state.fluidAmount)
    local applied = false
    local attempts = {
        function()
            if scriptFluid and container.clear then container:clear() end
        end,
        function()
            if scriptFluid and container.setPrimaryFluid then
                container:setPrimaryFluid(scriptFluid)
                applied = true
            end
        end,
        function()
            if scriptFluid and amount ~= nil and container.setPrimaryFluid then
                container:setPrimaryFluid(scriptFluid, amount)
                applied = true
            end
        end,
        function()
            if scriptFluid and container.setFluid then
                container:setFluid(scriptFluid)
                applied = true
            end
        end,
        function()
            if scriptFluid and amount ~= nil and container.addFluid then
                container:addFluid(scriptFluid, amount)
                applied = true
            end
        end,
        function()
            if fluidType and container.setFluidType then
                container:setFluidType(fluidType)
                applied = true
            end
        end,
        function()
            if fluidType and amount ~= nil and container.addFluid then
                container:addFluid(fluidType, amount)
                applied = true
            end
        end,
        function()
            if fluidType and amount ~= nil and container.insertFluid then
                container:insertFluid(fluidType, amount)
                applied = true
            end
        end,
    }

    if fluidType then
        for _, attempt in ipairs(attempts) do
            pcall(attempt)
            if applied then break end
        end
    end
    if amount ~= nil and container.setAmount then
        pcall(container.setAmount, container, math.max(0, amount))
    end
end

local function readVisualValue(visual, methodName, ...)
    local method = visual and visual[methodName] or nil
    local ok
    local value
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, visual, ...)
    return ok and value or nil
end

local function applyItemVisualState(item, state)
    local visual
    local tintR
    local tintG
    local tintB
    if not item or type(state) ~= "table" then return end
    if state.visualFullType ~= nil
        and item.getFullType
        and tostring(state.visualFullType)
            ~= tostring(item:getFullType() or "")
    then
        return
    end
    visual = item.getVisual and item:getVisual() or nil
    if not visual then return end
    if state[ITEM_VISUAL_STATE_FIELDS.baseTexture] ~= nil
        and visual.setBaseTexture
    then
        visual:setBaseTexture(tonumber(
            state[ITEM_VISUAL_STATE_FIELDS.baseTexture]
        ) or -1)
    end
    if state[ITEM_VISUAL_STATE_FIELDS.textureChoice] ~= nil
        and visual.setTextureChoice
    then
        visual:setTextureChoice(tonumber(
            state[ITEM_VISUAL_STATE_FIELDS.textureChoice]
        ) or -1)
    end
    if state.visualDecal ~= nil and visual.setDecal then
        visual:setDecal(tostring(state.visualDecal))
    end
    tintR = tonumber(state[ITEM_VISUAL_STATE_FIELDS.tintR])
    tintG = tonumber(state[ITEM_VISUAL_STATE_FIELDS.tintG])
    tintB = tonumber(state[ITEM_VISUAL_STATE_FIELDS.tintB])
    if tintR and tintG and tintB and ImmutableColor and visual.setTint then
        visual:setTint(ImmutableColor.new(tintR, tintG, tintB, 1))
    end
end

local function captureItemVisualState(item, state)
    local visual = item and item.getVisual and item:getVisual() or nil
    local clothingItem = item and item.getClothingItem
        and item:getClothingItem() or nil
    local tint
    if not visual then return end
    state.visualFullType = item.getFullType
        and tostring(item:getFullType() or "") or nil
    state[ITEM_VISUAL_STATE_FIELDS.baseTexture] = tonumber(
        readVisualValue(visual, "getBaseTexture")
    )
    state[ITEM_VISUAL_STATE_FIELDS.textureChoice] = tonumber(
        readVisualValue(visual, "getTextureChoice")
    )
    state.visualDecal = readVisualValue(
        visual,
        "getDecal",
        clothingItem
    )
    tint = readVisualValue(visual, "getTint", clothingItem)
    if tint then
        state[ITEM_VISUAL_STATE_FIELDS.tintR] = tonumber(tint:getRedFloat())
        state[ITEM_VISUAL_STATE_FIELDS.tintG] = tonumber(tint:getGreenFloat())
        state[ITEM_VISUAL_STATE_FIELDS.tintB] = tonumber(tint:getBlueFloat())
    end
end

local function applyItemState(item, state)
    if not item or type(state) ~= "table" then
        return
    end

    if state.usedDelta ~= nil and item.IsDrainable and item:IsDrainable() and item.setUsedDelta then
        item:setUsedDelta(math.max(0, math.min(1, tonumber(state.usedDelta) or 0)))
    end
    if state.condition ~= nil and item.setCondition then
        local condition = math.max(0, math.floor(tonumber(state.condition) or 0))
        if item.getConditionMax then
            condition = math.min(item:getConditionMax(), condition)
        end
        item:setCondition(condition)
    end
    if state.headCondition ~= nil and item.setHeadCondition then
        local condition = math.max(0, math.floor(tonumber(state.headCondition) or 0))
        if item.getHeadConditionMax then
            condition = math.min(item:getHeadConditionMax(), condition)
        end
        item:setHeadCondition(condition)
    elseif state.condition ~= nil and item.setHeadConditionFromCondition then
        pcall(item.setHeadConditionFromCondition, item, item)
    end
    if state.quality ~= nil and item.setQuality then
        item:setQuality(math.max(0, math.floor(tonumber(state.quality) or 0)))
    end
    if state.haveBeenRepaired ~= nil and item.setHaveBeenRepaired then
        item:setHaveBeenRepaired(math.max(0, math.floor(tonumber(state.haveBeenRepaired) or 0)))
    end
    if state.favorite ~= nil and item.setFavorite then
        item:setFavorite(state.favorite == true)
    end
    if state.customName ~= nil and tostring(state.customName) ~= "" and item.setName then
        item:setName(tostring(state.customName))
    end
    if state.ammoCount ~= nil and item.setCurrentAmmoCount then
        item:setCurrentAmmoCount(math.max(0, math.floor(tonumber(state.ammoCount) or 0)))
    end
    if type(state.modData) == "table" and item.getModData then
        local modData = item:getModData()
        if modData then
            for key, value in pairs(state.modData) do
                if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
                    modData[tostring(key)] = value
                end
            end
        end
    end

    applyItemVisualState(item, state)

    applyFluidState(item, state)
end

local function eachJavaList(list, callback)
    if not list or not list.size or not list.get then
        return
    end
    for index = 0, list:size() - 1 do
        callback(list:get(index), index + 1)
    end
end

--- Adds fully configured items, then sends the native MP container packets.
function Transfer.AddToContainer(container, fullType, count, state)
    local quantity = normalizeCount(count)
    if not container or not fullType or tostring(fullType) == "" or not quantity then
        return nil, "invalid_add_request"
    end

    local items = container:AddItems(tostring(fullType), quantity)
    if not items then
        return nil, "add_failed"
    end

    eachJavaList(items, function(item)
        applyItemState(item, state)
    end)

    -- sendAddItemToContainer serializes the already-configured item. Sending
    -- SyncItemFields before this packet races the client's item creation and
    -- can make SyncItemFieldsPacket parse a null InventoryItem.
    if isMultiplayerServer() and sendAddItemToContainer then
        eachJavaList(items, function(item)
            sendAddItemToContainer(container, item)
        end)
    end
    return items
end

function Transfer.ApplyState(item, state)
    applyItemState(item, state)
    return item
end

--- Captures the portable portion of an InventoryItem's state.
-- The result is intentionally packet-safe and can be used by other mods when
-- moving an item between an abstract inventory and a native ItemContainer.
function Transfer.CaptureState(item)
    if not item then
        return {}
    end
    local state = {}
    if item.getCondition then state.condition = tonumber(item:getCondition()) end
    if item.getHeadCondition then state.headCondition = tonumber(item:getHeadCondition()) end
    if item.getQuality then state.quality = tonumber(item:getQuality()) end
    if item.getHaveBeenRepaired then
        state.haveBeenRepaired = tonumber(item:getHaveBeenRepaired())
    end
    if item.getUsedDelta then state.usedDelta = tonumber(item:getUsedDelta()) end
    if item.isFavorite then state.favorite = item:isFavorite() == true end
    if item.isCustomName and item:isCustomName() and item.getName then
        state.customName = tostring(item:getName())
    end
    if item.getCurrentAmmoCount then
        state.ammoCount = tonumber(item:getCurrentAmmoCount())
    end
    captureItemVisualState(item, state)
    if item.getModData then
        local raw = item:getModData()
        local copied = {}
        local hasCopiedValue = false
        if raw then
            for key, value in pairs(raw) do
                if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
                    copied[tostring(key)] = value
                    hasCopiedValue = true
                end
            end
        end
        if hasCopiedValue then state.modData = copied end
    end
    if item.getFluidContainer then
        local ok, fluidContainer = pcall(item.getFluidContainer, item)
        if ok and fluidContainer then
            if fluidContainer.getAmount then
                ok, state.fluidAmount = pcall(fluidContainer.getAmount, fluidContainer)
                if not ok then state.fluidAmount = nil end
            end
            local fluid
            if fluidContainer.getPrimaryFluid then
                ok, fluid = pcall(fluidContainer.getPrimaryFluid, fluidContainer)
            elseif fluidContainer.getFluidType then
                ok, fluid = pcall(fluidContainer.getFluidType, fluidContainer)
            end
            if ok and fluid then
                if type(fluid) ~= "string" then
                    local value
                    if fluid.getFullName then
                        local fluidOK
                        fluidOK, value = pcall(fluid.getFullName, fluid)
                        if fluidOK then fluid = value end
                    elseif fluid.getName then
                        local fluidOK
                        fluidOK, value = pcall(fluid.getName, fluid)
                        if fluidOK then fluid = value end
                    end
                end
                state.fluidType = normalizeFluidType(fluid)
            end
        end
    end
    return state
end

function Transfer.DescribeItem(item)
    local fullType = item and item.getFullType and item:getFullType() or nil
    if not fullType or tostring(fullType) == "" then
        return nil, "item_type_missing"
    end
    return {
        fullType = tostring(fullType),
        state = Transfer.CaptureState(item),
    }
end

function Transfer.GiveToPlayer(player, fullType, count, state)
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then
        return nil, "inventory_unavailable"
    end
    return Transfer.AddToContainer(inventory, fullType, count, state)
end

--- Resolves a destination owned by the authoritative player inventory.
-- nil/"root" addresses the main inventory. Any other value is treated as the
-- ID of a carried container item and is resolved recursively.
function Transfer.ResolvePlayerContainer(player, containerItemID)
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then
        return nil, "inventory_unavailable"
    end
    if containerItemID == nil or tostring(containerItemID) == ""
        or tostring(containerItemID) == "root"
    then
        return inventory
    end

    local item = Transfer.FindByIDRecursive(inventory, containerItemID)
    if not item then
        return nil, "container_item_missing"
    end
    local nested = item.getItemContainer and item:getItemContainer()
        or item.getInventory and item:getInventory()
        or nil
    if not nested then
        return nil, "destination_not_container"
    end
    return nested
end

function Transfer.GiveToPlayerContainer(player, containerItemID, fullType, count, state)
    local container, reason = Transfer.ResolvePlayerContainer(player, containerItemID)
    if not container then
        return nil, reason
    end
    return Transfer.AddToContainer(container, fullType, count, state)
end

local function createItem(fullType)
    local ok
    local item
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        ok, item = pcall(InventoryItemFactory.CreateItem, tostring(fullType))
        if ok and item then return item end
    end
    if instanceItem then
        ok, item = pcall(instanceItem, tostring(fullType))
        if ok and item then return item end
    end
    return nil
end

--- Materializes items on a loaded square using the same state contract as
-- AddToContainer. World creation is authority-only at call sites.
function Transfer.DropToSquare(square, fullType, count, state, offsets)
    local quantity = normalizeCount(count)
    if not square or not fullType or tostring(fullType) == "" or not quantity then
        return nil, "invalid_drop_request"
    end
    local created = {}
    for index = 1, quantity do
        local item = createItem(fullType)
        if not item then
            return nil, "item_create_failed"
        end
        applyItemState(item, state)
        local offsetX = offsets and tonumber(offsets.x)
            or (ZombRand and (ZombRand(41) - 20) / 100)
            or 0
        local offsetY = offsets and tonumber(offsets.y)
            or (ZombRand and (ZombRand(41) - 20) / 100)
            or 0
        local worldItem = square:AddWorldInventoryItem(
            item,
            0.5 + offsetX,
            0.5 + offsetY,
            offsets and tonumber(offsets.z) or 0
        )
        if not worldItem then
            return nil, "world_add_failed"
        end
        -- AddWorldInventoryItem performs the native square replication when
        -- invoked by the server; do not send a second complete-item packet.
        created[#created + 1] = worldItem
    end
    return created
end

function Transfer.RemoveItem(item)
    local container = item and item.getContainer and item:getContainer() or nil
    if not container then
        return false, "item_not_contained"
    end

    container:DoRemoveItem(item)
    if isMultiplayerServer() and sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end
    return true
end

function Transfer.FindByIDRecursive(container, itemID)
    if not container or itemID == nil or not container.getItems then
        return nil
    end

    local wantedID = tostring(itemID)
    local items = container:getItems()
    if not items or not items.size or not items.get then
        return nil
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and item.getID and tostring(item:getID()) == wantedID then
            return item
        end
        local nested = item and item.getItemContainer and item:getItemContainer() or nil
        if nested then
            local found = Transfer.FindByIDRecursive(nested, itemID)
            if found then return found end
        end
    end
    return nil
end

local function resolveFromInventory(inventory, itemID)
    local item = nil
    if inventory and inventory.getItemById then
        local numericID = tonumber(itemID)
        if numericID then
            local ok, result = pcall(inventory.getItemById, inventory, numericID)
            if ok then item = result end
        end
    end
    return item or Transfer.FindByIDRecursive(inventory, itemID)
end

--- Resolves untrusted client item IDs against the authoritative player inventory.
-- Every item is validated before the caller mutates inventory state.
function Transfer.ResolvePlayerItems(player, itemIDs, options)
    options = options or {}
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then
        return nil, "inventory_unavailable"
    end

    local ids = type(itemIDs) == "table" and itemIDs or { itemIDs }
    if #ids < 1 then
        return nil, "items_missing"
    end

    local resolved = {}
    local seen = {}
    for index = 1, #ids do
        local itemID = ids[index]
        local key = itemID ~= nil and tostring(itemID) or ""
        if key == "" or seen[key] then
            return nil, "invalid_item_selection"
        end

        local item = resolveFromInventory(inventory, itemID)
        if not item then
            return nil, "item_missing"
        end
        if options.expectedFullType and item.getFullType
            and item:getFullType() ~= options.expectedFullType then
            return nil, "item_type_mismatch"
        end
        if options.validate then
            local ok, accepted = pcall(options.validate, item, index)
            if not ok or accepted == false then
                return nil, "item_rejected"
            end
        end

        seen[key] = true
        resolved[#resolved + 1] = item
    end
    return resolved
end

local function clearPlayerReferences(player, item)
    if not player then return end
    if player.getPrimaryHandItem and player:getPrimaryHandItem() == item and player.setPrimaryHandItem then
        player:setPrimaryHandItem(nil)
    end
    if player.getSecondaryHandItem and player:getSecondaryHandItem() == item and player.setSecondaryHandItem then
        player:setSecondaryHandItem(nil)
    end
    if player.removeWornItem then
        pcall(player.removeWornItem, player, item)
    end
    if player.removeAttachedItem then
        pcall(player.removeAttachedItem, player, item)
    end
end

--- Takes items identified by client-safe IDs from the authoritative inventory.
-- Resolution and validation complete before any item is removed.
function Transfer.TakeFromPlayer(player, itemIDs, options)
    local items, reason = Transfer.ResolvePlayerItems(player, itemIDs, options)
    if not items then
        return nil, reason
    end

    for _, item in ipairs(items) do
        clearPlayerReferences(player, item)
    end
    for _, item in ipairs(items) do
        local removed, removeReason = Transfer.RemoveItem(item)
        if not removed then
            return nil, removeReason
        end
    end
    return items
end

-- Short aliases for call sites that prefer verb-style names.
Transfer.Add = Transfer.AddToContainer
Transfer.Give = Transfer.GiveToPlayer
Transfer.GiveToContainer = Transfer.GiveToPlayerContainer
Transfer.Remove = Transfer.RemoveItem
Transfer.Resolve = Transfer.ResolvePlayerItems
Transfer.Take = Transfer.TakeFromPlayer
Transfer.Drop = Transfer.DropToSquare

return Transfer
