PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Inventory = PsychopatzCore.Inventory or {}

local Util = {}

function Util.hasFlag(flags, flag)
    flags = math.max(0, math.floor(tonumber(flags) or 0))
    return flags % (flag * 2) >= flag
end

function Util.call(object, methodName, ...)
    local method = object and object[methodName]
    local ok
    local value
    if type(method) ~= "function" then return nil, false end
    ok, value = pcall(method, object, ...)
    return ok and value or nil, ok
end

function Util.copy(value, depth, seen)
    local output
    local key
    local copied
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth > 8 then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    output = {}
    for key, copied in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            copied = Util.copy(copied, depth + 1, seen)
            if copied ~= nil and (type(copied) == "string"
                or type(copied) == "number" or type(copied) == "boolean"
                or type(copied) == "table")
            then
                output[key] = copied
            end
        end
    end
    seen[value] = nil
    return output
end

function Util.hasEntries(value)
    if type(value) ~= "table" then return false end
    for _, _ in pairs(value) do return true end
    return false
end

local function canonical(value, output, seen, depth)
    local keys
    local key
    if depth > 8 then output[#output + 1] = "!depth" return end
    if type(value) == "nil" then output[#output + 1] = "n"
    elseif type(value) == "boolean" then output[#output + 1] = value and "t" or "f"
    elseif type(value) == "number" then output[#output + 1] = string.format("#%.17g", value)
    elseif type(value) == "string" then output[#output + 1] = "$" .. #value .. ":" .. value
    elseif type(value) == "table" then
        if seen[value] then output[#output + 1] = "!cycle" return end
        seen[value] = true
        keys = {}
        for key, _ in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta == tb then return tostring(a) < tostring(b) end
            return ta < tb
        end)
        output[#output + 1] = "{"
        for i = 1, #keys do
            key = keys[i]
            canonical(key, output, seen, depth + 1)
            canonical(value[key], output, seen, depth + 1)
        end
        output[#output + 1] = "}"
        seen[value] = nil
    else
        output[#output + 1] = "!" .. type(value)
    end
end

function Util.canonical(value)
    local output = {}
    canonical(value, output, {}, 0)
    return table.concat(output)
end

function Util.javaList(list)
    local output = {}
    local size
    if not list then return output end
    if type(list) == "table" and type(list.size) ~= "function" then
        for i = 1, #list do output[#output + 1] = list[i] end
        return output
    end
    size = list.size and list:size() or 0
    for i = 0, size - 1 do output[#output + 1] = list:get(i) end
    return output
end

function Util.log(level, message)
    local core = PsychopatzCore or {}
    local logger = core.Logger
    local method = logger and (logger[level] or logger[string.lower(level)])
    if type(method) == "function" then
        pcall(method, logger, "Inventory", message)
    elseif (level == "ERROR" or level == "WARN") and print then
        print("[PsychopatzCore][Inventory][" .. level .. "] " .. tostring(message))
    end
end

PsychopatzCore.Inventory.Util = Util
return Util
