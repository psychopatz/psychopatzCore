-- Core-owned bounded semantic predicate contract and evaluator.
--
-- The evaluator reads projected public tables only.  Domain adapters may
-- provide context projections, but they do not provide another predicate
-- language or evaluator.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Predicate = Semantics.Predicate or {}
Semantics.Predicate = Predicate

Predicate.VERSION = 1
Predicate.MAX_DEPTH = 6
Predicate.MAX_GROUP = 16
Predicate.MAX_TRACE = 24

local OPS = {
    exists = true,
    eq = true,
    equals = true,
    neq = true,
    not_equals = true,
    ["in"] = true,
    not_in = true,
    gt = true,
    gte = true,
    lt = true,
    lte = true,
    truthy = true,
    falsy = true,
    contains = true,
    not_contains = true,
    contains_any = true,
    contains_all = true,
}

local function normalized(value)
    return string.lower(tostring(value or ""))
end

local function privateKey(key)
    key = normalized(key)
    return key == "private"
        or key == "secret"
        or key == "undiscovered"
        or string.find(key, "private", 1, true) ~= nil
        or string.find(key, "secret", 1, true) ~= nil
end

local function primitive(value)
    if type(value) == "table" then return "<table>" end
    if type(value) == "string" and #value > 96 then
        return string.sub(value, 1, 96)
    end
    return value
end

local function appendTrace(trace, row)
    if #trace < Predicate.MAX_TRACE then trace[#trace + 1] = row end
end

local function unknown(reason, trace)
    return {
        status = "unknown",
        allowed = false,
        reason = reason or "predicate_unknown",
        trace = trace or {},
    }
end

local function validateNode(value, depth)
    depth = tonumber(depth) or 0
    if type(value) ~= "table" then return false, "predicate_invalid" end
    if depth > Predicate.MAX_DEPTH then return false, "predicate_depth_limit" end

    local structural = 0
    if value.all ~= nil then structural = structural + 1 end
    if value.any ~= nil then structural = structural + 1 end
    if value["not"] ~= nil then structural = structural + 1 end
    if structural > 0 then
        if structural ~= 1 then return false, "predicate_structure_invalid" end
        if value.all ~= nil or value.any ~= nil then
            local items = value.all or value.any
            if type(items) ~= "table" or #items < 1
                or #items > Predicate.MAX_GROUP
            then
                return false, "predicate_group_invalid"
            end
            for index = 1, #items do
                local valid, reason = validateNode(items[index], depth + 1)
                if not valid then return false, reason end
            end
            return true
        end
        return validateNode(value["not"], depth + 1)
    end

    local path = value.path or value.field
    if type(path) ~= "string" or path == "" or #path > 128 then
        return false, "predicate_path_invalid"
    end
    local op = normalized(value.op or "eq")
    if OPS[op] ~= true then return false, "predicate_operator_invalid" end
    if op == "exists" or op == "truthy" or op == "falsy" then
        return true
    end
    if op == "in" or op == "not_in"
        or op == "contains_any" or op == "contains_all"
    then
        local values = value.values or value.value
        if type(values) ~= "table" or #values < 1
            or #values > Predicate.MAX_GROUP
        then
            return false, "predicate_values_invalid"
        end
        return true
    end
    if value.value == nil then return false, "predicate_value_missing" end
    return true
end

function Predicate.Validate(value)
    return validateNode(value, 0)
end

local function typedEqual(left, right)
    return type(left) == type(right) and left == right
end

local function readPath(context, path)
    local current = context
    local parts = {}
    for segment in string.gmatch(tostring(path or ""), "[^%.]+") do
        parts[#parts + 1] = segment
    end
    if #parts == 0 then return nil, "predicate_path_missing", false end
    for index = 1, #parts do
        local segment = parts[index]
        if privateKey(segment) then return nil, "private_field", true end
        if type(current) ~= "table" or current[segment] == nil then
            return nil, "predicate_field_unknown", false
        end
        current = current[segment]
        if type(current) == "table"
            and (current.private == true
                or current.secret == true
                or current.undiscovered == true)
        then
            return nil, "private_field", true
        end
    end
    return current, nil, false
end

local function collectionContains(collection, expected)
    if type(collection) ~= "table" then return nil end
    if collection[expected] == true then return true end
    for index = 1, #collection do
        if typedEqual(collection[index], expected) then return true end
    end
    return false
end

local function compare(value, predicate)
    local op = normalized(predicate.op or "eq")
    local expected = predicate.value
    if op == "exists" then return value ~= nil end
    if value == nil then return nil end
    if op == "eq" or op == "equals" then return typedEqual(value, expected) end
    if op == "neq" or op == "not_equals" then
        return type(value) == type(expected) and value ~= expected
    end
    if op == "in" or op == "not_in" then
        local values = predicate.values or expected
        if type(values) ~= "table" then return nil end
        local found = false
        for index = 1, #values do
            if type(values[index]) ~= type(value) then return nil end
            if typedEqual(value, values[index]) then found = true break end
        end
        if op == "in" then return found end
        return not found
    end
    if op == "contains" or op == "not_contains" then
        local found = collectionContains(value, expected)
        if found == nil then return nil end
        if op == "contains" then return found end
        return not found
    end
    if op == "contains_any" or op == "contains_all" then
        if type(value) ~= "table" or type(predicate.values) ~= "table" then
            return nil
        end
        local matched = 0
        for index = 1, #predicate.values do
            local found = collectionContains(value, predicate.values[index])
            if found == nil then return nil end
            if found then matched = matched + 1 end
        end
        if op == "contains_any" then return matched > 0 end
        return matched == #predicate.values
    end
    if op == "gt" or op == "gte" or op == "lt" or op == "lte" then
        if type(value) ~= "number" or type(expected) ~= "number" then return nil end
        if op == "gt" then return value > expected end
        if op == "gte" then return value >= expected end
        if op == "lt" then return value < expected end
        return value <= expected
    end
    if op == "truthy" then return type(value) == "boolean" and value end
    if op == "falsy" then return type(value) == "boolean" and not value end
    return nil
end

local evaluateNode

local function combineAll(results)
    local hasUnknown = false
    local trace = {}
    for index = 1, #results do
        local result = results[index]
        for _, row in ipairs(result.trace or {}) do appendTrace(trace, row) end
        if result.status == "rejected" then
            return {
                status = "rejected", allowed = false,
                reason = result.reason or "predicate_rejected", trace = trace,
            }
        end
        if result.status == "unknown" or result.status == "private" then
            hasUnknown = true
        end
    end
    if hasUnknown then return unknown("predicate_unknown", trace) end
    return {status = "allowed", allowed = true, reason = "all_allowed", trace = trace}
end

local function combineAny(results)
    local hasUnknown = false
    local hasPrivate = false
    local trace = {}
    for index = 1, #results do
        local result = results[index]
        for _, row in ipairs(result.trace or {}) do appendTrace(trace, row) end
        if result.allowed == true then
            return {status = "allowed", allowed = true, reason = "any_allowed", trace = trace}
        end
        if result.status == "private" then hasPrivate = true end
        if result.status == "unknown" then hasUnknown = true end
    end
    if hasPrivate then
        return {status = "private", allowed = false, reason = "private_field", trace = trace}
    end
    if hasUnknown then return unknown("predicate_unknown", trace) end
    return {status = "rejected", allowed = false, reason = "none_allowed", trace = trace}
end

evaluateNode = function(predicate, context, depth)
    depth = tonumber(depth) or 0
    if depth > Predicate.MAX_DEPTH then return unknown("predicate_depth_limit") end
    if type(predicate) ~= "table" then return unknown("predicate_invalid") end
    if predicate.all ~= nil then
        if type(predicate.all) ~= "table" then return unknown("all_invalid") end
        local results = {}
        for index = 1, #predicate.all do
            results[#results + 1] = evaluateNode(predicate.all[index], context, depth + 1)
        end
        return combineAll(results)
    end
    if predicate.any ~= nil then
        if type(predicate.any) ~= "table" then return unknown("any_invalid") end
        local results = {}
        for index = 1, #predicate.any do
            results[#results + 1] = evaluateNode(predicate.any[index], context, depth + 1)
        end
        return combineAny(results)
    end
    if predicate["not"] ~= nil then
        local result = evaluateNode(predicate["not"], context, depth + 1)
        if result.status == "unknown" or result.status == "private" then return result end
        return {
            status = result.allowed and "rejected" or "allowed",
            allowed = result.allowed ~= true,
            reason = result.allowed and "not_failed" or "not_allowed",
            trace = result.trace,
        }
    end

    local path = predicate.path or predicate.field
    local value, readReason, isPrivate = readPath(context, path)
    local safePath = isPrivate and "<private>" or path
    if isPrivate then
        return {
            status = "private", allowed = false, reason = "private_field",
            trace = {{path = safePath, op = normalized(predicate.op or "eq"), status = "private", passed = false}},
        }
    end
    if readReason and value == nil then
        return {
            status = "unknown", allowed = false, reason = readReason,
            trace = {{path = safePath, op = normalized(predicate.op or "eq"), actual = nil, status = "unknown", passed = false}},
        }
    end
    local matched = compare(value, predicate)
    if matched == nil then
        return {
            status = "unknown", allowed = false, reason = "predicate_type_mismatch",
            trace = {{path = safePath, op = normalized(predicate.op or "eq"), expected = primitive(predicate.values or predicate.value), actual = primitive(value), status = "unknown", passed = false}},
        }
    end
    return {
        status = matched and "allowed" or "rejected", allowed = matched,
        reason = "typed_compare",
        trace = {{path = safePath, op = normalized(predicate.op or "eq"), expected = primitive(predicate.values or predicate.value), actual = primitive(value), status = matched and "allowed" or "rejected", passed = matched}},
    }
end

function Predicate.Evaluate(predicate, context)
    local valid, reason = Predicate.Validate(predicate)
    if not valid then
        local result = unknown(reason)
        result.schemaVersion = Predicate.VERSION
        return result
    end
    local result = evaluateNode(predicate, type(context) == "table" and context or {}, 0)
    result.schemaVersion = Predicate.VERSION
    result.trace = result.trace or {}
    result.truncated = #result.trace >= Predicate.MAX_TRACE
    return result
end

return Predicate
