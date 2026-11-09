-- Bounded value handling shared by Core and provider worker adapters.

local Values = {}

-- Production response plans may contain bounded branch-offer predicates. Keep
-- the worker projection bounded without changing the durable Core record path.
Values.MAX_DEPTH = 12

function Values.copy(value, depth, seen)
    if type(value) ~= "table" then return value end
    depth = depth or 0
    if depth > Values.MAX_DEPTH then return "<depth_limit>" end
    seen = seen or {}
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        count = count + 1
        if count > 128 then break end
        if type(key) == "string" or type(key) == "number" then
            local itemType = type(item)
            if itemType == "table" then
                output[key] = Values.copy(item, depth + 1, seen)
            elseif itemType ~= "function"
                and itemType ~= "userdata"
                and itemType ~= "thread"
            then
                output[key] = item
            end
        end
    end
    seen[value] = nil
    return output
end

-- Provider production modules use Core.DeepCopy for durable records. Keep the
-- bounded copy above for worker responses, but do not let its diagnostic cap
-- alter the serialized data that the real Core path stores.
function Values.productionCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local output = {}
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            local itemType = type(item)
            if itemType == "table" then
                output[key] = Values.productionCopy(item, seen)
            elseif itemType ~= "function"
                and itemType ~= "userdata"
                and itemType ~= "thread"
            then
                output[key] = item
            end
        end
    end
    seen[value] = nil
    return output
end

function Values.clearTable(value)
    for key in pairs(value) do value[key] = nil end
    return value
end

function Values.safeString(value, fallback)
    value = tostring(value or fallback or "")
    return value
end

function Values.number(value, fallback)
    value = tonumber(value)
    return value ~= nil and value or fallback
end

return Values
