-- Core-owned typed text binding and resolver contract.
--
-- This resolves already-authored semantic placeholders. It never parses
-- player/NPC text and never dispatches gameplay effects.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local ConvoEngine = PsychopatzCore.ConvoEngine
local Binding = ConvoEngine.TextBinding or {}
ConvoEngine.TextBinding = Binding

Binding.VERSION = 1
Binding.MAX_PLACEHOLDERS = 16
Binding.Resolvers = Binding.Resolvers or {}

local function parts(path)
    local output = {}
    for segment in string.gmatch(tostring(path or ""), "[^%.]+") do
        output[#output + 1] = segment
    end
    return output
end

local function scalarText(value)
    if type(value) ~= "table" then
        return value == nil and nil or tostring(value)
    end
    for _, key in ipairs({"name", "displayName", "text", "value", "id"}) do
        if value[key] ~= nil then return scalarText(value[key]) end
    end
    return nil
end

function Binding.RegisterResolver(id, resolver)
    if type(id) ~= "string" or id == "" or type(resolver) ~= "function" then
        return false, "invalid_text_binding_resolver"
    end
    Binding.Resolvers[id] = resolver
    return true, id
end

function Binding.ClearResolvers()
    Binding.Resolvers = {}
end

function Binding.ResolvePath(context, path)
    if not IR.IsPublicContextPath(path) then
        return nil, "binding_path_private_or_unknown"
    end
    local current = type(context) == "table" and context or {}
    for _, segment in ipairs(parts(path)) do
        if type(current) ~= "table" or current[segment] == nil then
            return nil, "binding_value_missing"
        end
        current = current[segment]
    end
    local value = scalarText(current)
    if value == nil or value == "" then
        return nil, "binding_value_not_presentable"
    end
    return value
end

function Binding.Resolve(name, context, definitions)
    definitions = type(definitions) == "table" and definitions or {}
    local definition = definitions[name]
    local path = name
    local resolverID
    if type(definition) == "table" then
        path = definition.from
        resolverID = definition.resolver
    end
    local value, reason = Binding.ResolvePath(context, path)
    if value == nil then return nil, reason end
    if resolverID ~= nil then
        local resolver = Binding.Resolvers[resolverID]
        if type(resolver) ~= "function" then
            return nil, "binding_resolver_unavailable"
        end
        value = resolver(value, context, definition)
        value = scalarText(value)
        if value == nil or value == "" then
            return nil, "binding_resolver_empty"
        end
    end
    return value
end

function Binding.Render(template, context, definitions)
    if type(template) ~= "string" then
        return nil, "binding_template_invalid"
    end
    local count = 0
    local missing
    for name in string.gmatch(template, "{([a-z][a-z0-9_.]*)}") do
        count = count + 1
        if count > Binding.MAX_PLACEHOLDERS then
            return nil, "binding_placeholder_limit"
        end
        local value, reason = Binding.Resolve(name, context, definitions)
        if value == nil then missing = reason or "binding_value_missing" end
    end
    if missing ~= nil then return nil, missing end
    return (string.gsub(template, "{([a-z][a-z0-9_.]*)}", function(name)
        return Binding.Resolve(name, context, definitions)
    end))
end

return Binding
