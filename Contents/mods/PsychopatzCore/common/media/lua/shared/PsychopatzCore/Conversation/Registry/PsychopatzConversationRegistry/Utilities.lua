-- Build 42.20 conversation category/block registry.
-- Conversation content is data-only so the same definitions can be loaded by
-- clients, dedicated servers, and other mods without trusting client state.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Registry = PsychopatzCore.Conversation.Registry or {}
PsychopatzCore.Conversation.Registry = Registry
local Internal = Registry.Internal

Registry.API_VERSION = 1
Registry.SCHEMA_VERSION = 1
Registry.categories = Registry.categories or {}
Registry.blocks = Registry.blocks or {}
Registry.invalidCategories = Registry.invalidCategories or {}
Registry.invalidBlocks = Registry.invalidBlocks or {}
Registry.conditionHandlers = Registry.conditionHandlers or {}
Registry.categoryEligibilityProviders =
    Registry.categoryEligibilityProviders or {}
Registry.effectHandlers = Registry.effectHandlers or {}
Registry.revision = tonumber(Registry.revision) or 0

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[copy(key, seen)] = copy(child, seen)
    end
    return output
end

local function validID(value)
    return type(value) == "string"
        and #value >= 3
        and #value <= 128
        and string.match(value, "^[%w_.-]+:[%w_.-]+$") ~= nil
end

local VALID_AUDIENCES = {
    hostile = true,
    neutral = true,
    member = true,
    special = true,
    shared = true,
}

local function serializable(value, seen, path)
    local kind = type(value)
    if kind == "nil" or kind == "string" or kind == "boolean" then
        return true
    end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return false, tostring(path) .. " contains a non-finite number"
        end
        return true
    end
    if kind ~= "table" then
        return false, tostring(path) .. " contains " .. kind
    end
    seen = seen or {}
    if seen[value] then return false, tostring(path) .. " contains a cycle" end
    seen[value] = true
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType ~= "string" and keyType ~= "number" then
            seen[value] = nil
            return false, tostring(path) .. " contains an unsafe key"
        end
        local ok, reason = serializable(
            child,
            seen,
            tostring(path) .. "." .. tostring(key)
        )
        if not ok then
            seen[value] = nil
            return false, reason
        end
    end
    seen[value] = nil
    return true
end

local function addError(errors, message)
    errors[#errors + 1] = tostring(message)
end

local function validateTextSource(source, errors, path)
    path = path or "textSource"
    if type(source) ~= "table" then
        addError(errors, path .. " is required")
        return
    end
    if type(source.modID) ~= "string" or source.modID == "" then
        addError(errors, path .. ".modID is required")
    end
    if type(source.pathPattern) ~= "string"
        or not string.find(source.pathPattern, "{language}", 1, true)
        or string.find(source.pathPattern, "..", 1, true)
        or string.sub(source.pathPattern or "", 1, 1) == "/"
        or string.find(source.pathPattern or "", "\\", 1, true)
    then
        addError(errors, path .. ".pathPattern must be relative and contain {language}")
    end
    if type(source.domain) ~= "string" or source.domain == "" then
        addError(errors, path .. ".domain is required")
    end
end

local function validateRepeat(policy, errors, path)
    if policy == nil then return end
    if type(policy) ~= "table" then
        addError(errors, path .. " must be a table")
        return
    end
    local scope = policy.scope or "pair"
    if scope ~= "pair" and scope ~= "character"
        and scope ~= "npc" and scope ~= "world"
    then addError(errors, path .. ".scope is invalid") end
    if policy.cooldownHours ~= nil
        and (tonumber(policy.cooldownHours) or -1) < 0
    then addError(errors, path .. ".cooldownHours must be non-negative") end
    if policy.maxUses ~= nil
        and (tonumber(policy.maxUses) or 0) < 1
    then addError(errors, path .. ".maxUses must be positive") end
    if policy.oncePerDay ~= nil and type(policy.oncePerDay) ~= "boolean" then
        addError(errors, path .. ".oncePerDay must be boolean")
    end
end

local function validateGates(gates, errors, path)
    if gates == nil then return end
    if type(gates) ~= "table" then
        addError(errors, path .. " must be a table")
        return
    end
    for index, gate in ipairs(gates) do
        local gatePath = path .. "[" .. tostring(index) .. "]"
        if type(gate) ~= "table" or type(gate.type) ~= "string" then
            addError(errors, gatePath .. " requires a type")
        elseif gate.type == "all" or gate.type == "any" then
            if type(gate.gates) ~= "table" or #gate.gates == 0 then
                addError(errors, gatePath .. ".gates must contain conditions")
            else
                validateGates(gate.gates, errors, gatePath .. ".gates")
            end
        elseif gate.type == "not" then
            if type(gate.gate) ~= "table" then
                addError(errors, gatePath .. ".gate is required")
            else
                validateGates({ gate.gate }, errors, gatePath .. ".gate")
            end
        elseif not Registry.conditionHandlers[gate.type] then
            addError(errors, gatePath .. " uses unknown condition " .. gate.type)
        end
    end
end

local function validateEffects(effects, errors, path)
    if effects == nil then return end
    if type(effects) ~= "table" then
        addError(errors, path .. " must be a table")
        return
    end
    for index, effect in ipairs(effects) do
        local effectPath = path .. "[" .. tostring(index) .. "]"
        if type(effect) ~= "table" or type(effect.type) ~= "string" then
            addError(errors, effectPath .. " requires a type")
        elseif not Registry.effectHandlers[effect.type] then
            addError(errors, effectPath .. " uses unknown effect " .. effect.type)
        end
    end
end

Internal.Copy = copy
Internal.ValidID = validID
Internal.ValidAudiences = VALID_AUDIENCES
Internal.Serializable = serializable
Internal.AddError = addError
Internal.ValidateTextSource = validateTextSource
Internal.ValidateRepeat = validateRepeat
Internal.ValidateGates = validateGates
Internal.ValidateEffects = validateEffects

Registry.Copy = copy
Registry.IsSerializable = serializable
