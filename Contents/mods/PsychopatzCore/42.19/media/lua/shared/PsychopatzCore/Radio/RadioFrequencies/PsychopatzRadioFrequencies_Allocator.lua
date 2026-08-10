-- Stable allocation helpers. Existing assignments win, allowing consumers to
-- persist frequencies while safely adding more channels later.

local Frequencies = PsychopatzCore.RadioFrequencies

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return nil end
    return value
end

function Frequencies.NormalizeMHz(value, step)
    value = finite(value)
    step = math.max(0.001, finite(step) or 0.1)
    if not value then return nil end
    return math.floor(value / step + 0.5) * step
end

function Frequencies.FormatMHz(value)
    value = finite(value)
    if not value then return "--.- MHz" end
    return string.format("%.1f MHz", value)
end

local function hash(value)
    local output = 5381
    value = tostring(value or "")
    for index = 1, #value do
        output = (output * 33 + string.byte(value, index)) % 2147483647
    end
    return output
end

local function normalizedKeys(keys)
    local output = {}
    local seen = {}
    for _, key in ipairs(type(keys) == "table" and keys or {}) do
        key = tostring(key or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            output[#output + 1] = key
        end
    end
    table.sort(output)
    return output
end

function Frequencies.AllocateUnique(keys, options)
    options = type(options) == "table" and options or {}
    local minimum = finite(options.minimum) or 88
    local maximum = finite(options.maximum) or 108
    local step = math.max(0.001, finite(options.step) or 0.1)
    local slots = math.max(1,
        math.floor((maximum - minimum) / step + 0.5) + 1)
    local namespace = tostring(options.namespace or "radio")
    local existing = type(options.existing) == "table"
        and options.existing or {}
    local allocation = {}
    local used = {}
    local ordered = normalizedKeys(keys)

    for _, key in ipairs(ordered) do
        local frequency = Frequencies.NormalizeMHz(existing[key], step)
        local slot = frequency
            and math.floor((frequency - minimum) / step + 0.5) or nil
        if slot and slot >= 0 and slot < slots and not used[slot] then
            allocation[key] = minimum + slot * step
            used[slot] = true
        end
    end

    for _, key in ipairs(ordered) do
        if allocation[key] == nil then
            local first = hash(namespace .. ":" .. key) % slots
            local assigned
            for offset = 0, slots - 1 do
                local slot = (first + offset) % slots
                if not used[slot] then
                    used[slot] = true
                    assigned = minimum + slot * step
                    break
                end
            end
            allocation[key] = assigned
        end
    end
    return allocation
end

return Frequencies
