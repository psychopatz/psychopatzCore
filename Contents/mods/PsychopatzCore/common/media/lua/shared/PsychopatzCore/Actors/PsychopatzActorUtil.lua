local Util = {}

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    if depth > 32 then return nil end

    local result = {}
    for key, child in pairs(value) do
        local copied = copyValue(child, depth + 1)
        if copied ~= nil or child == nil then
            result[key] = copied
        end
    end
    return result
end

function Util.clone(value)
    return copyValue(value, 0)
end

function Util.text(value, fallback)
    if type(value) ~= "string" then return fallback end
    local normalized = string.match(value, "^%s*(.-)%s*$")
    if not normalized or normalized == "" then return fallback end
    return normalized
end

function Util.number(value, fallback)
    local normalized = tonumber(value)
    if normalized == nil then return fallback end
    return normalized
end

function Util.integer(value, fallback)
    local normalized = tonumber(value)
    if normalized == nil then return fallback end
    return math.floor(normalized)
end

function Util.hash(value)
    local text = tostring(value or "")
    local hash = 5381
    for index = 1, #text do
        hash = (hash * 33 + string.byte(text, index)) % 2147483647
    end
    return hash
end

function Util.pick(values, seed, offset)
    local count = #values
    if count == 0 then return nil end
    local index = (Util.hash(seed) + (offset or 0)) % count + 1
    return values[index]
end

function Util.isNamespacedKey(value)
    return type(value) == "string"
        and string.match(value, "^[%w_%-]+[:%.].+$") ~= nil
end

local function validateSerializable(value, seen, depth)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "string" then
        return true
    end
    if kind == "number" then
        return value == value and value ~= math.huge and value ~= -math.huge
    end
    if kind ~= "table" then return false end
    if depth > 32 or seen[value] then return false end

    seen[value] = true
    for key, child in pairs(value) do
        local keyKind = type(key)
        if keyKind ~= "string" and keyKind ~= "number" then
            seen[value] = nil
            return false
        end
        if not validateSerializable(child, seen, depth + 1) then
            seen[value] = nil
            return false
        end
    end
    seen[value] = nil
    return true
end

function Util.isSerializable(value)
    return validateSerializable(value, {}, 0)
end

return Util
