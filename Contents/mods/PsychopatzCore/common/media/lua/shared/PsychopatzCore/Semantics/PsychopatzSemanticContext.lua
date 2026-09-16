PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local Context = Semantics.Context or {}
Semantics.Context = Context

Context.Resolvers = Context.Resolvers or {}

function Context.RegisterResolver(id, resolver, priority)
    if type(id) ~= "string" or id == "" or type(resolver) ~= "function" then
        return false, "invalid_context_resolver"
    end
    Context.Resolvers[id] = {
        id = id,
        resolve = resolver,
        priority = tonumber(priority) or 0,
    }
    return true, Context.Resolvers[id]
end

local function orderedResolvers()
    local output = {}
    local id
    local resolver
    for id, resolver in pairs(Context.Resolvers) do
        output[#output + 1] = resolver
    end
    table.sort(output, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function Context.Resolve(ir, context, options)
    local valid, validationReason = IR.Validate(ir)
    if valid ~= true then
        return nil, validationReason or "invalid_ir"
    end
    options = type(options) == "table" and options or {}
    local output = IR.Clone(ir)
    local failures = {}

    local resolvers = orderedResolvers()
    for _, resolver in ipairs(resolvers) do
        local ok
        local resolved
        ok, resolved = pcall(resolver.resolve, output, context, options)
        local resolvedValid
        if ok and type(resolved) == "table" then
            resolvedValid = IR.Validate(resolved)
        end
        if ok and type(resolved) == "table" and resolvedValid == true then
            output = resolved
        elseif not ok then
            failures[#failures + 1] = resolver.id
        end
    end

    local diagnostics = output.diagnostics or {}
    diagnostics.contextResolvers = #resolvers
    diagnostics.contextResolverFailures = failures
    output.diagnostics = diagnostics
    return output
end

function Context.ClearResolvers()
    Context.Resolvers = {}
end

return Context
