-- Generic atomic material transactions across multiple inventory stores.
-- Consumers provide recipe rows and prioritized source adapters; this module
-- has no settlement, crafting, or Project Hoomans knowledge.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Inventory = PsychopatzCore.Inventory or {}

local MaterialTransaction = {}

local function normalizeRecipe(recipe)
    local rows = recipe
    if type(recipe) == "table" and recipe.costs then rows = recipe.costs end
    if type(rows) == "table" and rows.fullType then rows = { rows } end
    rows = type(rows) == "table" and rows or {}
    local grouped, order = {}, {}
    for _, row in ipairs(rows) do
        local fullType = type(row) == "table"
            and tostring(row.fullType or "") or ""
        local amount = type(row) == "table"
            and math.max(0, math.floor(tonumber(row.amount or row.quantity) or 0))
            or 0
        if fullType ~= "" and amount > 0 then
            if grouped[fullType] == nil then
                grouped[fullType] = 0
                order[#order + 1] = fullType
            end
            grouped[fullType] = grouped[fullType] + amount
        end
    end
    local normalized = {}
    for _, fullType in ipairs(order) do
        normalized[#normalized + 1] = {
            fullType = fullType, amount = grouped[fullType],
        }
    end
    return normalized
end

local function orderedSources(sources)
    local output = {}
    for index, source in ipairs(type(sources) == "table" and sources or {}) do
        if type(source) == "table" and type(source.store) == "table"
            and type(source.store.count) == "function"
            and type(source.store.remove) == "function"
        then
            output[#output + 1] = {
                id = tostring(source.id or ("source_" .. tostring(index))),
                label = tostring(source.label or source.id or index),
                priority = tonumber(source.priority) or index,
                source = source,
                originalIndex = index,
            }
        end
    end
    table.sort(output, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        return left.originalIndex < right.originalIndex
    end)
    return output
end

function MaterialTransaction.NormalizeRecipe(recipe)
    return normalizeRecipe(recipe)
end

function MaterialTransaction.Quote(recipe, sources)
    local normalized = normalizeRecipe(recipe)
    local ordered = orderedSources(sources)
    local quote = { affordable = true, costs = {}, sources = {}, totalMissing = 0 }
    for _, entry in ipairs(ordered) do
        quote.sources[#quote.sources + 1] = {
            id = entry.id, label = entry.label,
        }
    end
    for _, cost in ipairs(normalized) do
        local line = { fullType = cost.fullType, required = cost.amount,
            available = 0, missing = 0, allocations = {} }
        local remaining = cost.amount
        for _, entry in ipairs(ordered) do
            local available = math.max(0, math.floor(tonumber(
                entry.source.store:count({ fullType = cost.fullType })
            ) or 0))
            line.available = line.available + available
            local take = math.min(remaining, available)
            line.allocations[#line.allocations + 1] = {
                sourceId = entry.id, sourceLabel = entry.label,
                available = available, quantity = take,
            }
            remaining = remaining - take
        end
        line.missing = math.max(0, remaining)
        if line.missing > 0 then quote.affordable = false end
        quote.totalMissing = quote.totalMissing + line.missing
        quote.costs[#quote.costs + 1] = line
    end
    return quote
end

local function rollback(receipts)
    local ok = true
    local index
    for index = #receipts, 1, -1 do
        local receipt = receipts[index]
        local store = receipt.source.store
        local restored = store.restoreRemoved
            and store:restoreRemoved(receipt.removed) or false
        if restored ~= true then ok = false end
    end
    return ok
end

function MaterialTransaction.Consume(recipe, sources, options)
    local ordered = orderedSources(sources)
    local byId = {}
    for _, entry in ipairs(ordered) do byId[entry.id] = entry.source end
    local quote = MaterialTransaction.Quote(recipe, sources)
    if not quote.affordable then return false, "insufficient_materials", quote end
    local receipts = {}
    for _, cost in ipairs(quote.costs) do
        for _, allocation in ipairs(cost.allocations) do
            if allocation.quantity > 0 then
                local source = byId[allocation.sourceId]
                local ok, removed = source.store:remove(
                    { fullType = cost.fullType }, allocation.quantity,
                    options and options.removeOptions)
                if not ok then
                    local rollbackOK = rollback(receipts)
                    quote.rollbackOK = rollbackOK
                    return false, removed or "material_remove_failed", quote
                end
                receipts[#receipts + 1] = {
                    source = source, sourceId = allocation.sourceId,
                    fullType = cost.fullType, quantity = allocation.quantity,
                    removed = removed,
                }
            end
        end
    end
    local committed = {}
    for _, receipt in ipairs(receipts) do
        local source = receipt.source
        if not committed[source] then
            committed[source] = true
            if type(source.onCommitted) == "function" then
                source:onCommitted(receipts, quote)
            end
        end
    end
    quote.receipts = receipts
    return true, "consumed", quote
end

PsychopatzCore.Inventory.MaterialTransaction = MaterialTransaction
return MaterialTransaction
