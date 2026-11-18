-- ConvoEngine: hand-written
-- S11A5: Core-owned portable domain adapter registry and dispatcher.
-- Connects portable S11 effects, modifiers, queries, memory residue, and actions
-- directly to existing authoritative systems without compatibility shims or shadow state.
-- Kahlua2-safe (Lua 5.1 compatible).

local ActionContract = require "PsychopatzCore/ConvoEngine/ActionContract"

local S11DomainAdapters = {}

S11DomainAdapters._domainAdapters = S11DomainAdapters._domainAdapters or {}
S11DomainAdapters._effectHandlers = S11DomainAdapters._effectHandlers or {}
S11DomainAdapters._queryHandlers = S11DomainAdapters._queryHandlers or {}
S11DomainAdapters._memoryAdapter = S11DomainAdapters._memoryAdapter or nil

function S11DomainAdapters.Reset()
    S11DomainAdapters._domainAdapters = {}
    S11DomainAdapters._effectHandlers = {}
    S11DomainAdapters._queryHandlers = {}
    S11DomainAdapters._memoryAdapter = nil
end

function S11DomainAdapters.RegisterDomainAdapter(domain, adapter)
    if type(domain) ~= "string" or domain == "" or type(adapter) ~= "table" then
        return false, "invalid_domain_adapter"
    end
    S11DomainAdapters._domainAdapters[domain] = adapter
    return true
end

function S11DomainAdapters.RegisterEffectHandler(effectType, handler)
    if type(effectType) ~= "string" or effectType == "" or type(handler) ~= "function" then
        return false, "invalid_effect_handler"
    end
    S11DomainAdapters._effectHandlers[effectType] = handler
    return true
end

function S11DomainAdapters.RegisterQueryHandler(root, handler)
    if type(root) ~= "string" or root == "" or type(handler) ~= "function" then
        return false, "invalid_query_handler"
    end
    S11DomainAdapters._queryHandlers[root] = handler
    return true
end

function S11DomainAdapters.RegisterMemoryAdapter(adapter)
    if type(adapter) ~= "table" then
        return false, "invalid_memory_adapter"
    end
    S11DomainAdapters._memoryAdapter = adapter
    return true
end

function S11DomainAdapters.DispatchEffect(effectSpec, roleBindings, context)
    if type(effectSpec) ~= "table" or type(effectSpec.type) ~= "string" then
        return { ok = false, reason = "invalid_effect_spec" }
    end
    local handler = S11DomainAdapters._effectHandlers[effectSpec.type]
    if type(handler) ~= "function" then
        return { ok = false, reason = "unregistered_effect_handler:" .. effectSpec.type }
    end
    return handler(effectSpec, roleBindings or {}, context or {})
end

function S11DomainAdapters.ApplyModifier(modifierSpec, roleBindings, context)
    if type(modifierSpec) ~= "table" or type(modifierSpec.domain) ~= "string" then
        return { ok = false, reason = "invalid_modifier_spec" }
    end
    local adapter = S11DomainAdapters._domainAdapters[modifierSpec.domain]
    if type(adapter) ~= "table" or type(adapter.applyModifier) ~= "function" then
        return { ok = false, reason = "unregistered_domain_adapter:" .. modifierSpec.domain }
    end
    return adapter.applyModifier(modifierSpec, roleBindings or {}, context or {})
end

function S11DomainAdapters.RecordMemoryResidue(closureSpec, roleBindings, context)
    if type(closureSpec) ~= "table" then
        return { ok = true, skipped = true, reason = "no_closure" }
    end
    local cclass = tostring(closureSpec.closureClass or "none")
    if cclass == "none" or cclass == "state_transition" then
        return { ok = true, skipped = true, reason = "non_memory_closure" }
    end
    local adapter = S11DomainAdapters._memoryAdapter
    if type(adapter) ~= "table" or type(adapter.recordResidue) ~= "function" then
        return { ok = false, reason = "unregistered_memory_adapter" }
    end
    return adapter.recordResidue(closureSpec, roleBindings or {}, context or {})
end

function S11DomainAdapters.ResolveQuery(querySpec, context)
    if type(querySpec) ~= "table" or type(querySpec.path) ~= "string" then
        return { ok = false, reason = "invalid_query_spec" }
    end
    local root = string.match(querySpec.path, "^([^%.]+)")
    local handler = root and S11DomainAdapters._queryHandlers[root] or nil
    if type(handler) == "function" then
        return handler(querySpec, context or {})
    end
    return { ok = false, reason = "unregistered_query_handler:" .. tostring(root or "") }
end

function S11DomainAdapters.ExecuteAction(contractOrId, input, context, callback)
    return ActionContract.Execute(contractOrId, input, context, callback)
end

return S11DomainAdapters
