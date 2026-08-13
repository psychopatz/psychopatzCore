require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore.CorpseItems = PsychopatzCore.CorpseItems or {}

local CorpseItems = PsychopatzCore.CorpseItems
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

CorpseItems.INJECTION_KEY_FIELD =
    CorpseItems.INJECTION_KEY_FIELD or "PsychopatzCore_CorpseItemKey"

local function isAuthority()
    return RuntimeRole.AllowsServerCode()
end

local function itemFullType(item)
    return item and item.getFullType and tostring(item:getFullType() or "") or ""
end

local function eachItem(container, callback)
    local items = container and container.getItems and container:getItems() or nil
    local index
    if not items or not items.size or not items.get then
        return
    end
    for index = 0, items:size() - 1 do
        callback(items:get(index), index + 1)
    end
end

local function injectionKey(item)
    local modData = item and item.getModData and item:getModData() or nil
    local value = modData and modData[CorpseItems.INJECTION_KEY_FIELD] or nil
    return value ~= nil and tostring(value) or nil
end

function CorpseItems.IsAuthority()
    return isAuthority()
end

function CorpseItems.Find(container, spec)
    local wantedKey = spec and spec.key ~= nil and tostring(spec.key) or nil
    local wantedType = spec and spec.fullType ~= nil and tostring(spec.fullType) or nil
    local matcher = spec and spec.match
    local found
    eachItem(container, function(item)
        local matches = false
        if found then
            return
        end
        if wantedKey and injectionKey(item) == wantedKey then
            matches = true
        elseif type(matcher) == "function" then
            local ok
            ok, matches = pcall(matcher, item, spec)
            matches = ok and matches == true
        elseif not wantedKey and wantedType and itemFullType(item) == wantedType then
            matches = true
        end
        if matches then
            found = item
        end
    end)
    return found
end

function CorpseItems.AddExisting(container, item)
    local added
    local ok
    if not isAuthority() then
        return false, "not_authority"
    end
    if not container or not item then
        return false, "invalid_item"
    end
    if item.getContainer and item:getContainer() == container then
        return true
    end
    eachItem(container, function(candidate)
        if candidate == item then
            added = true
        end
    end)
    if added then
        return true
    end
    if not container.AddItem then
        return false, "container_add_unavailable"
    end
    ok, added = pcall(container.AddItem, container, item)
    if not ok or not added then
        return false, "container_add_failed"
    end
    return true
end

function CorpseItems.Create(fullType)
    local ok
    local item
    local manager
    local script
    fullType = tostring(fullType or "")
    if fullType == "" then
        return nil
    end
    manager = getScriptManager and getScriptManager() or nil
    if manager and manager.FindItem then
        ok, script = pcall(manager.FindItem, manager, fullType)
        if not ok or not script then
            return nil
        end
    elseif manager and manager.getItem then
        ok, script = pcall(manager.getItem, manager, fullType)
        if not ok or not script then
            return nil
        end
    end
    if instanceItem then
        ok, item = pcall(instanceItem, fullType)
        if ok and item then
            return item
        end
    end
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
        if ok then
            return item
        end
    end
    return nil
end

function CorpseItems.ApplyState(item, spec)
    local modData
    local key
    local ok
    if not item or type(spec) ~= "table" then
        return false, "invalid_item_state"
    end
    if spec.customName ~= nil and item.setName then
        pcall(item.setName, item, tostring(spec.customName))
    end
    if spec.condition ~= nil and item.setCondition then
        pcall(
            item.setCondition,
            item,
            math.max(0, math.floor(tonumber(spec.condition) or 0))
        )
    end
    if spec.uses ~= nil and item.setUses then
        pcall(item.setUses, item, math.max(0, math.floor(tonumber(spec.uses) or 0)))
    end
    modData = item.getModData and item:getModData() or nil
    key = spec.key ~= nil and tostring(spec.key) or nil
    if modData and key then
        modData[CorpseItems.INJECTION_KEY_FIELD] = key
    end
    if modData and type(spec.modData) == "table" then
        for field, value in pairs(spec.modData) do
            if type(value) == "boolean" or type(value) == "number"
                or type(value) == "string"
            then
                modData[tostring(field)] = value
            end
        end
    end
    if type(spec.configure) == "function" then
        ok = pcall(spec.configure, item, spec)
        if not ok then
            return false, "configure_failed"
        end
    end
    return true
end

function CorpseItems.SyncAddedItem(container, item)
    if not isAuthority() then
        return false, "not_authority"
    end
    if isServer and isServer() == true then
        if item and item.syncItemFields then
            pcall(item.syncItemFields, item)
        end
        if item and item.transmitModData then
            pcall(item.transmitModData, item)
        end
        if sendAddItemToContainer then
            local ok = pcall(sendAddItemToContainer, container, item)
            return ok, ok and nil or "item_transmit_failed"
        end
    end
    return true
end

function CorpseItems.Insert(container, spec, options)
    local item
    local ok
    local reason
    options = options or {}
    if not isAuthority() then
        return nil, false, "not_authority"
    end
    if not container or type(spec) ~= "table" then
        return nil, false, "invalid_insertion"
    end
    if spec.item then
        item = spec.item
    elseif type(spec.create) == "function" then
        ok, item = pcall(spec.create, spec)
        if not ok then
            item = nil
        end
    else
        item = CorpseItems.Create(spec.fullType)
    end
    if not item then
        return nil, false, "item_create_failed"
    end
    ok, reason = CorpseItems.ApplyState(item, spec)
    if not ok then
        return nil, false, reason
    end
    ok, reason = CorpseItems.AddExisting(container, item)
    if not ok then
        return nil, false, reason
    end
    if options.syncItem == true then
        ok, reason = CorpseItems.SyncAddedItem(container, item)
        if not ok then
            -- The authoritative container already owns the item. Return it so
            -- callers do not retry and create a duplicate after a packet error.
            return item, true, reason
        end
    end
    return item, true
end

function CorpseItems.Inject(container, spec, options)
    local item
    local ok
    local reason
    options = options or {}
    if not isAuthority() then
        return nil, false, "not_authority"
    end
    if not container or type(spec) ~= "table" then
        return nil, false, "invalid_injection"
    end
    item = CorpseItems.Find(container, spec)
    if item then
        ok, reason = CorpseItems.ApplyState(item, spec)
        if not ok then
            return nil, false, reason
        end
        return item, false
    end
    return CorpseItems.Insert(container, spec, options)
end

function CorpseItems.InjectMany(container, specs, options)
    local results = {}
    local failures = {}
    local item
    local created
    local reason
    local index
    if type(specs) ~= "table" then
        return results, { { reason = "invalid_specs" } }
    end
    for index = 1, #specs do
        item, created, reason = CorpseItems.Inject(container, specs[index], options)
        if item then
            results[#results + 1] = {
                item = item,
                created = created == true,
                spec = specs[index],
            }
        else
            failures[#failures + 1] = {
                index = index,
                reason = reason,
                spec = specs[index],
            }
        end
    end
    return results, failures
end

function CorpseItems.InjectIntoCharacter(character, specs, options)
    local container = character and character.getInventory
        and character:getInventory() or nil
    return CorpseItems.InjectMany(container, specs, options)
end

function CorpseItems.InjectIntoCorpse(corpse, specs, options)
    local container = corpse and corpse.getContainer and corpse:getContainer() or nil
    return CorpseItems.InjectMany(container, specs, options)
end

function CorpseItems.Transmit(corpse)
    if not isAuthority() then
        return false, "not_authority"
    end
    if isServer and isServer() == true
        and corpse and corpse.transmitCompleteItemToClients
    then
        local ok = pcall(corpse.transmitCompleteItemToClients, corpse)
        return ok, ok and nil or "transmit_failed"
    end
    return true
end

return CorpseItems
