require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore.ItemTransfer = PsychopatzCore.ItemTransfer or {}

local Transfer = PsychopatzCore.ItemTransfer

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
        if type(state) == "table" and isMultiplayerServer() and item.syncItemFields then
            item:syncItemFields()
        end
    end)

    if isMultiplayerServer() and sendAddItemToContainer then
        eachJavaList(items, function(item)
            sendAddItemToContainer(container, item)
        end)
    end
    return items
end

function Transfer.GiveToPlayer(player, fullType, count, state)
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then
        return nil, "inventory_unavailable"
    end
    return Transfer.AddToContainer(inventory, fullType, count, state)
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
Transfer.Remove = Transfer.RemoveItem
Transfer.Resolve = Transfer.ResolvePlayerItems
Transfer.Take = Transfer.TakeFromPlayer

return Transfer
