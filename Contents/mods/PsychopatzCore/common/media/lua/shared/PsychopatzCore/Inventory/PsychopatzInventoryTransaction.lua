local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"

local Transaction = {}

local function authorityAllowed(options)
    if options and options.skipAuthorityCheck then return true end
    return not (isClient and isClient() == true and (not isServer or isServer() ~= true))
end

local function rollbackSource(source, removed)
    if source.restoreRemoved then return source:restoreRemoved(removed) end
    for i = 1, #(removed or {}) do
        local ok = source:add(removed[i])
        if not ok then return false end
    end
    return true
end

local function rollbackDestination(destination, added)
    for i = #added, 1, -1 do
        local entry = added[i]
        if type(entry.result) == "table" and entry.result[1]
            and destination._nativeRemove
        then
            for j = #entry.result, 1, -1 do destination:_nativeRemove(entry.result[j]) end
        else
            local key = ItemRecord.stackKey(entry.record)
            local resultRecord = entry.result
            local query = { predicate = function(candidate)
                if key then return ItemRecord.stackKey(candidate) == key end
                return candidate == resultRecord
            end }
            destination:remove(query, entry.record[C.QUANTITY], { includeReserved = true })
        end
    end
end

function Transaction.transfer(source, destination, query, quantity, options)
    Metrics.increment("transactionCount")
    if not authorityAllowed(options) then
        Metrics.increment("transactionFailures")
        return false, "server_authority_required"
    end
    if not source or not destination or type(source.remove) ~= "function"
        or type(destination.add) ~= "function"
    then
        Metrics.increment("transactionFailures")
        return false, "invalid_store"
    end
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local removedOk, removed = source:remove(query, quantity)
    if not removedOk then
        Metrics.increment("transactionFailures")
        return false, removed
    end
    local added = {}
    for i = 1, #removed do
        local ok, result = destination:add(removed[i])
        if not ok then
            rollbackDestination(destination, added)
            rollbackSource(source, removed)
            Metrics.increment("transactionFailures")
            return false, result or "destination_add_failed"
        end
        added[#added + 1] = { result = result, record = removed[i] }
    end
    return true, removed
end

function Transaction.deposit(destination, value, quantity, options)
    if not authorityAllowed(options) then return false, "server_authority_required" end
    return destination:add(value, quantity)
end

function Transaction.withdraw(source, query, quantity, options)
    if not authorityAllowed(options) then return false, "server_authority_required" end
    return source:remove(query, quantity)
end

function Transaction.consume(source, query, quantity, options)
    return Transaction.withdraw(source, query, quantity, options)
end

return Transaction
