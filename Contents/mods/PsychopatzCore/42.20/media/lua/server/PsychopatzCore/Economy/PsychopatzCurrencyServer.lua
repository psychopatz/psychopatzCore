require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/Economy/PsychopatzCurrency"

PsychopatzCore = PsychopatzCore or {}
local Core = PsychopatzCore
local Currency = Core.Currency
local Audit = Core.CurrencyDiagnostics
if not Currency then return nil end

local function isMultiplayerServer()
    return type(isServer) == "function" and isServer() == true
end

local function call(object, methodName, fallback, ...)
    local method = object and object[methodName]
    if type(method) ~= "function" then return fallback end
    local ok, value = pcall(method, object, ...)
    if not ok or value == nil then return fallback end
    return value
end

local function syncItemStats(item)
    if item and type(item.syncItemFields) == "function" then
        pcall(item.syncItemFields, item)
    end
    if type(sendItemStats) == "function" and item then
        pcall(sendItemStats, item)
    end
end

local function setNativeQuantity(item, quantity, deferSync)
    local setter = item and item.setCount
    if type(setter) ~= "function" then return false end
    local ok = pcall(setter, item, math.max(1, math.floor(quantity)))
    if not ok then return false end
    local actual = tonumber(call(item, "getCount", nil))
    if actual and actual ~= math.floor(quantity) then return false end
    if not deferSync then syncItemStats(item) end
    return true
end

local function removeNativeItem(item)
    local container = call(item, "getContainer", nil)
    if not container then return false, "item_not_contained" end
    local removed = false
    if type(container.DoRemoveItem) == "function" then
        local ok, result = pcall(container.DoRemoveItem, container, item)
        removed = ok and result ~= false
    elseif type(container.Remove) == "function" then
        local ok, result = pcall(container.Remove, container, item)
        removed = ok and result ~= false
    end
    if not removed then return false, "physical_remove_failed" end
    if isMultiplayerServer() and type(sendRemoveItemFromContainer) == "function" then
        pcall(sendRemoveItemFromContainer, container, item)
    end
    return true, container
end

local function itemInContainer(container, wanted)
    local items = call(container, "getItems", nil)
    local size = tonumber(call(items, "size", 0)) or 0
    for index = 0, size - 1 do
        if call(items, "get", nil, index) == wanted then return true end
    end
    return false
end

local function restoreNativeItem(container, item)
    if not container or not item or type(container.AddItem) ~= "function" then
        return false
    end
    local ok, added = pcall(container.AddItem, container, item)
    if not ok then return false end
    -- Build 42 returns the item here, but a compatibility bridge may return
    -- void. Verify the authoritative container instead of treating a void
    -- return as a failed rollback after the item was actually restored.
    local restored = added == item
        or itemInContainer(container, item)
    if not restored then return false end
    local restoredItem = added or item
    if isMultiplayerServer() and type(sendAddItemToContainer) == "function" then
        pcall(sendAddItemToContainer, container, restoredItem)
    end
    syncItemStats(restoredItem)
    return true
end

local function removeAddedEntries(entries)
    local ok = true
    for index = #(entries or {}), 1, -1 do
        local removed = removeNativeItem(entries[index].item)
        if not removed then ok = false end
    end
    return ok
end

local function addNativeItems(container, fullType, quantity)
    quantity = math.max(0, math.floor(tonumber(quantity) or 0))
    if quantity < 1 or not container then return nil, "quantity_invalid" end

    -- InventoryItem:setCount() changes an item's script count; it does not
    -- create the physical currency units counted by the native inventory,
    -- save format, and MP container packets. Use AddItems so every dollar or
    -- bundle is a real Base.Money/Base.MoneyBundle record. Build 42's network
    -- layer compresses identical records while they are in transit.
    local items
    if type(container.AddItems) == "function" then
        local ok
        ok, items = pcall(container.AddItems, container, fullType, quantity)
        if not ok or not items then return nil, "physical_add_failed" end
    elseif type(container.AddItem) == "function" then
        -- Compatibility fallback for older/modded container bridges without
        -- AddItems. Keep the same physical-record contract.
        items = {}
        for _ = 1, quantity do
            local ok, item = pcall(container.AddItem, container, fullType)
            if not ok or not item then
                for index = #items, 1, -1 do
                    removeNativeItem(items[index])
                end
                return nil, "physical_add_failed"
            end
            items[#items + 1] = item
        end
    else
        return nil, "physical_add_failed"
    end

    local result = {}
    local isLuaArray = type(items) == "table"
        and type(items.size) ~= "function"
    local itemCount = isLuaArray
        and #items
        or (tonumber(call(items, "size", 0)) or 0)
    for index = 0, itemCount - 1 do
        local item = isLuaArray
            and items[index + 1]
            or call(items, "get", nil, index)
        if item and tostring(call(item, "getFullType", ""))
            == tostring(fullType)
        then
            result[#result + 1] = {
                item = item,
                container = container,
                quantity = Currency.ItemQuantity(item),
            }
        end
    end
    local addedQuantity = 0
    for index = 1, #result do
        addedQuantity = addedQuantity + Currency.ItemQuantity(result[index].item)
    end
    if addedQuantity ~= quantity then
        removeAddedEntries(result)
        return nil, "physical_add_incomplete"
    end
    if isMultiplayerServer()
        and type(sendAddItemsToContainer) == "function"
        and not isLuaArray
    then
        pcall(sendAddItemsToContainer, container, items)
    elseif isMultiplayerServer() and type(sendAddItemToContainer) == "function" then
        for index = 1, #result do
            pcall(sendAddItemToContainer, container, result[index].item)
        end
    end
    return result
end

local function removeQuantity(entry, quantity)
    local item = entry and entry.item
    local available = math.max(1, math.floor(tonumber(entry and entry.quantity)
        or Currency.ItemQuantity(item)))
    quantity = math.max(1, math.floor(tonumber(quantity) or 0))
    if quantity > available then return nil, "insufficient_quantity" end

    if quantity < available then
        if not setNativeQuantity(item, available - quantity) then
            return nil, "partial_stack_unsupported"
        end
        return function()
            return setNativeQuantity(item, available)
        end
    end

    local ok, containerOrReason = removeNativeItem(item)
    if not ok then return nil, containerOrReason end
    local container = containerOrReason
    return function() return restoreNativeItem(container, item) end
end

local function undoAll(undo)
    local ok = true
    for index = #undo, 1, -1 do
        if type(undo[index]) == "function" then
            local callOK, result = pcall(undo[index])
            if not callOK or result == false then ok = false end
        end
    end
    return ok
end

local function makeRestore(undo)
    return function()
        local ok = true
        for index = #undo, 1, -1 do
            if type(undo[index]) == "function" then
                local callOK, result = pcall(undo[index])
                if not callOK or result == false then ok = false end
            end
        end
        return ok
    end
end

local function restoreDetails(details)
    if details and type(details.restore) == "function" then
        local ok, result = pcall(details.restore)
        return ok and result ~= false
    end
    return undoAll(details and details.undo or {})
end

local function removalFailure(undo, reason, rollbackComplete)
    return false, rollbackComplete and reason or "rollback_failed", {
        undo = undo,
        restore = makeRestore(undo),
        rollbackComplete = rollbackComplete == true,
    }
end

local function auditRecord(operationID, phase, data)
    if operationID and Audit and type(Audit.Record) == "function" then
        Audit.Record(operationID, phase, data)
    end
end

local function auditSnapshot(operationID, phase, snapshot)
    if operationID and Audit and type(Audit.Snapshot) == "function" then
        Audit.Snapshot(operationID, phase, snapshot)
    end
end

local function entriesOf(snapshot, fullType)
    local output = {}
    for index = 1, #(snapshot.items or {}) do
        local entry = snapshot.items[index]
        if entry.fullType == fullType then output[#output + 1] = entry end
    end
    return output
end

local function consumeEntries(snapshot, fullType, quantity, undo)
    local remaining = math.max(0, math.floor(tonumber(quantity) or 0))
    local entries = entriesOf(snapshot, fullType)
    for index = #entries, 1, -1 do
        if remaining < 1 then break end
        local entry = entries[index]
        local take = math.min(remaining, entry.quantity)
        local restore, reason = removeQuantity(entry, take)
        if not restore then return false, reason, remaining end
        undo[#undo + 1] = restore
        remaining = remaining - take
    end
    return remaining < 1, nil, remaining
end

function Currency.AddUnits(container, units)
    units = math.max(0, math.floor(tonumber(units) or 0))
    if units < 1 then return true, "nothing_to_add", {} end
    local _, bundles, loose = Currency.CanonicalSpecs(units)
    local added = {}
    local ok, reason
    if bundles > 0 then
        local entries
        entries, reason = addNativeItems(
            container, Currency.BUNDLE_TYPE, bundles)
        if entries then
            for index = 1, #entries do added[#added + 1] = entries[index] end
        else
            ok = false
        end
    else
        ok = true
    end
    if ok ~= false and loose > 0 then
        local entries
        entries, reason = addNativeItems(
            container, Currency.MONEY_TYPE, loose)
        if entries then
            for index = 1, #entries do added[#added + 1] = entries[index] end
        else
            ok = false
        end
    end
    if ok == nil then ok = true end
    if not ok then
        local removed = removeAddedEntries(added)
        return false, removed and (reason or "physical_add_failed")
            or "rollback_failed", {}
    end
    return true, "added", added
end

function Currency.RemoveUnits(inventory, units, options)
    options = type(options) == "table" and options or {}
    units = math.max(0, math.floor(tonumber(units) or 0))
    if units < 1 then return false, "quantity_invalid" end
    local auditID = options.auditID
    auditRecord(auditID, "remove.request", {
        units = units,
        fullType = options.fullType,
    })
    local snapshot = Currency.Snapshot(inventory, {
        recursive = options.recursive ~= false,
        includeItems = true,
        maxDepth = options.maxDepth,
    })
    auditSnapshot(auditID, "remove.before", snapshot)
    if snapshot.units < units then return false, "insufficient_currency" end

    local undo = {}
    local remaining = units
    local ok, reason
    local exactType = options.fullType
    if exactType == Currency.MONEY_TYPE
        or exactType == Currency.BUNDLE_TYPE
    then
        local unitValue = Currency.UnitValue(exactType)
        if units % unitValue ~= 0 then return false, "quantity_invalid" end
        local requested = math.floor(units / unitValue)
        local exactOK
        local exactRemaining
        exactOK, reason, exactRemaining = consumeEntries(
            snapshot, exactType, requested, undo)
        if not exactOK or exactRemaining > 0 then
            local restored = undoAll(undo)
            return removalFailure(
                undo, reason or "insufficient_currency", restored)
        end
        auditRecord(auditID, "remove.complete", { units = units })
        return true, "removed", {
            undo = undo,
            restore = makeRestore(undo),
            units = units,
        }
    end
    -- Spend loose units first. This avoids needlessly converting bundles for
    -- common small payments and preserves the canonical bundle representation.
    local looseTake = math.min(remaining, snapshot.loose)
    if looseTake > 0 then
        local looseOK
        local looseRemaining
        looseOK, reason, looseRemaining = consumeEntries(
            snapshot, Currency.MONEY_TYPE, looseTake, undo)
        if not looseOK or looseRemaining > 0 then
            local restored = undoAll(undo)
            return removalFailure(
                undo, reason or "insufficient_currency", restored)
        end
        remaining = remaining - looseTake
    end

    local wholeBundles = math.floor(remaining / Currency.BUNDLE_VALUE)
    if wholeBundles > 0 then
        local bundleOK
        local bundleRemaining
        bundleOK, reason, bundleRemaining = consumeEntries(
            snapshot, Currency.BUNDLE_TYPE,
            wholeBundles, undo)
        if not bundleOK or bundleRemaining > 0 then
            local restored = undoAll(undo)
            return removalFailure(
                undo, reason or "insufficient_currency", restored)
        end
        remaining = remaining - wholeBundles * Currency.BUNDLE_VALUE
    end

    if remaining > 0 then
        -- A remainder from a bundle is converted in-place: remove one bundle,
        -- return its unspent loose value, then consume the requested amount.
        local remainderSnapshot = Currency.Snapshot(inventory, {
            recursive = options.recursive ~= false,
            includeItems = true,
            maxDepth = options.maxDepth,
        })
        local bundleEntries = entriesOf(
            remainderSnapshot, Currency.BUNDLE_TYPE)
        local entry = bundleEntries[#bundleEntries]
        if not entry then
            local restored = undoAll(undo)
            return removalFailure(undo, "insufficient_currency", restored)
        end
        local restore, removeReason = removeQuantity(entry, 1)
        if not restore then
            local restored = undoAll(undo)
            return removalFailure(undo, removeReason, restored)
        end
        undo[#undo + 1] = restore
        local change, addReason = addNativeItems(
            entry.container, Currency.MONEY_TYPE,
            Currency.BUNDLE_VALUE - remaining)
        if not change then
            local restored = undoAll(undo)
            return removalFailure(undo, addReason, restored)
        end
        for index = 1, #change do
            local changeEntry = change[index]
            undo[#undo + 1] = function()
                return removeNativeItem(changeEntry.item)
            end
        end
    end
    auditRecord(auditID, "remove.complete", { units = units })
    return true, "removed", {
        undo = undo,
        restore = makeRestore(undo),
        units = units,
    }
end

function Currency.AddType(container, fullType, quantity, auditID)
    if not Currency.IsType(fullType) then return false, "type_invalid" end
    auditRecord(auditID, "add.request", {
        fullType = fullType,
        quantity = quantity,
    })
    local entries, reason = addNativeItems(
        container, fullType, math.floor(tonumber(quantity) or 0))
    if not entries then
        auditRecord(auditID, "add.failed", { reason = reason })
        return false, reason
    end
    local addedQuantity = 0
    local firstType
    local firstCount
    for index = 1, #entries do
        local item = entries[index].item
        addedQuantity = addedQuantity + Currency.ItemQuantity(item)
        if not firstType then
            firstType = call(item, "getFullType", nil)
            firstCount = call(item, "getCount", nil)
        end
    end
    auditRecord(auditID, "add.complete", {
        fullType = fullType,
        quantity = quantity,
        entries = #entries,
        addedQuantity = addedQuantity,
        firstType = firstType,
        firstCount = firstCount,
    })
    return true, "added", entries
end

local function conversionMatches(before, after, operation, quantity, sameContainer)
    local value = quantity * Currency.BUNDLE_VALUE
    if not sameContainer then
        if after.units ~= before.units - value then return false end
        if operation == "bundle" then
            return after.loose == before.loose - value
                and after.bundles == before.bundles
        end
        return after.loose == before.loose
            and after.bundles == before.bundles - quantity
    end
    if after.units ~= before.units then return false end
    if operation == "bundle" then
        return after.loose == before.loose - value
            and after.bundles == before.bundles + quantity
    end
    return after.loose == before.loose + value
        and after.bundles == before.bundles - quantity
end

local function rollbackConversion(entries, details)
    local removed = removeAddedEntries(entries)
    local restored = true
    if details and details.rollbackComplete ~= true then
        restored = restoreDetails(details)
    end
    return removed and restored
end

local function replacementMatches(before, after, fullType, quantity)
    local value = Currency.ValueFor(fullType, quantity)
    if after.units - before.units ~= value then return false end
    if fullType == Currency.MONEY_TYPE then
        return after.loose - before.loose == quantity
            and after.bundles == before.bundles
    end
    if fullType == Currency.BUNDLE_TYPE then
        return after.loose == before.loose
            and after.bundles - before.bundles == quantity
    end
    return false
end

local function verifyReplacement(target, before, fullType, quantity)
    local after = Currency.Snapshot(target, {
        recursive = true,
        includeItems = true,
    })
    return replacementMatches(before, after, fullType, quantity), after
end

function Currency.BundleLoose(inventory, destination)
    local auditID = Audit and Audit.Begin and Audit.Begin("bundle") or nil
    local snapshot = Currency.Snapshot(inventory, {
        recursive = true,
        includeItems = true,
    })
    auditSnapshot(auditID, "bundle.before", snapshot)
    local bundleCount = math.floor(snapshot.loose / Currency.BUNDLE_VALUE)
    if bundleCount < 1 then return false, "insufficient_loose_currency" end

    -- Add and verify the replacement before touching the source money.
    local target = destination or inventory
    local targetBefore = target == inventory and snapshot
        or Currency.Snapshot(target, { recursive = true, includeItems = true })
    local added, addReason, entries = Currency.AddType(
        target, Currency.BUNDLE_TYPE, bundleCount, auditID)
    if not added then
        auditRecord(auditID, "bundle.failed", { reason = addReason })
        return false, addReason or "physical_add_failed"
    end
    local replacementOK = verifyReplacement(
        target, targetBefore, Currency.BUNDLE_TYPE, bundleCount)
    if not replacementOK then
        local safe = rollbackConversion(entries, nil)
        auditRecord(auditID, "bundle.add_verify_failed", { safe = safe })
        return false, safe and "physical_add_unverified" or "rollback_failed"
    end
    local removed, reason, details = Currency.RemoveUnits(
        inventory, bundleCount * Currency.BUNDLE_VALUE, {
            fullType = Currency.MONEY_TYPE,
            auditID = auditID,
        })
    if not removed then
        local safe = rollbackConversion(entries, details)
        auditRecord(auditID, "bundle.rollback", {
            reason = reason,
            safe = safe,
        })
        return false, safe and reason or "rollback_failed"
    end
    local after = Currency.Snapshot(inventory, {
        recursive = true,
        includeItems = true,
    })
    auditSnapshot(auditID, "bundle.after", after)
    if not conversionMatches(
        snapshot, after, "bundle", bundleCount, target == inventory)
    then
        local safe = rollbackConversion(entries, details)
        auditRecord(auditID, "bundle.verify_failed", { safe = safe })
        return false, safe and "verification_failed" or "rollback_failed"
    end
    auditRecord(auditID, "bundle.complete", { bundles = bundleCount })
    return true, "bundled", {
        bundles = bundleCount,
        loose = bundleCount * Currency.BUNDLE_VALUE,
        added = entries,
    }
end

function Currency.Unbundle(inventory, destination)
    local auditID = Audit and Audit.Begin and Audit.Begin("unbundle") or nil
    local snapshot = Currency.Snapshot(inventory, {
        recursive = true,
        includeItems = true,
    })
    auditSnapshot(auditID, "unbundle.before", snapshot)
    if snapshot.bundles < 1 then return false, "no_bundles" end
    local bundleCount = snapshot.bundles
    local target = destination or inventory

    -- Add and verify the replacement before touching the source bundles.
    local targetBefore = target == inventory and snapshot
        or Currency.Snapshot(target, { recursive = true, includeItems = true })
    local added, addReason, entries = Currency.AddType(
        target, Currency.MONEY_TYPE, bundleCount * Currency.BUNDLE_VALUE,
        auditID)
    if not added then
        auditRecord(auditID, "unbundle.failed", { reason = addReason })
        return false, addReason or "physical_add_failed"
    end
    local replacementOK = verifyReplacement(
        target, targetBefore, Currency.MONEY_TYPE,
        bundleCount * Currency.BUNDLE_VALUE)
    if not replacementOK then
        local safe = rollbackConversion(entries, nil)
        auditRecord(auditID, "unbundle.add_verify_failed", { safe = safe })
        return false, safe and "physical_add_unverified" or "rollback_failed"
    end
    local removed, reason, details = Currency.RemoveUnits(
        inventory, bundleCount * Currency.BUNDLE_VALUE, {
            fullType = Currency.BUNDLE_TYPE,
            auditID = auditID,
        })
    if not removed then
        local safe = rollbackConversion(entries, details)
        auditRecord(auditID, "unbundle.rollback", {
            reason = reason,
            safe = safe,
        })
        return false, safe and reason or "rollback_failed"
    end
    local after = Currency.Snapshot(inventory, {
        recursive = true,
        includeItems = true,
    })
    auditSnapshot(auditID, "unbundle.after", after)
    if not conversionMatches(
        snapshot, after, "unbundle", bundleCount, target == inventory)
    then
        local safe = rollbackConversion(entries, details)
        auditRecord(auditID, "unbundle.verify_failed", { safe = safe })
        return false, safe and "verification_failed" or "rollback_failed"
    end
    auditRecord(auditID, "unbundle.complete", { bundles = bundleCount })
    return true, "unbundled", {
        bundles = bundleCount,
        loose = bundleCount * Currency.BUNDLE_VALUE,
        added = entries,
    }
end

function Currency.TransferUnits(sourceInventory, destinationContainer, units,
    options)
    local removed, reason, details = Currency.RemoveUnits(
        sourceInventory, units, options)
    if not removed then return false, reason end
    local added, addReason, addedItems = Currency.AddUnits(
        destinationContainer, units)
    if not added then
        local restored = restoreDetails(details)
        return false, restored and (addReason or "physical_add_failed")
            or "rollback_failed"
    end
    return true, "transferred", {
        units = units,
        added = addedItems,
    }
end

return Currency
