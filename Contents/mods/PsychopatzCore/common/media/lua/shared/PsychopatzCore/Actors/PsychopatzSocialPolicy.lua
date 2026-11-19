PsychopatzCore = PsychopatzCore or {}

local SocialPolicy = PsychopatzCore.SocialPolicy or {}
PsychopatzCore.SocialPolicy = SocialPolicy

SocialPolicy.SCHEMA_VERSION = 1
SocialPolicy.Registries = SocialPolicy.Registries or {}
SocialPolicy.Events = SocialPolicy.Events or {}
SocialPolicy.Aliases = SocialPolicy.Aliases or {}

function SocialPolicy.RegisterRegistry(registry)
    if type(registry) ~= "table" or type(registry.events) ~= "table" then
        return false, "social_policy_registry_invalid"
    end
    local owner = tostring(registry.owner or registry.package or "default")
    SocialPolicy.Registries[owner] = registry
    for eventID, spec in pairs(registry.events) do
        if type(eventID) == "string" and type(spec) == "table" then
            SocialPolicy.Events[eventID] = spec
        end
    end
    for alias, canonical in pairs(registry.aliases or {}) do
        if type(alias) == "string" and type(canonical) == "string" then
            SocialPolicy.Aliases[alias] = canonical
        end
    end
    return true
end

local function ensureBuiltinRegistries()
    if not SocialPolicy.Registries["PsychopatzCore"] then
        local ok, coreReg = pcall(require, "PsychopatzCore/SocialPolicy/Registry")
        if ok and type(coreReg) == "table" then
            SocialPolicy.RegisterRegistry(coreReg)
        end
    end
    if PNC and PNC.SocialPolicy and PNC.SocialPolicy.Registry
        and not SocialPolicy.Registries["ProjectHoomans"]
    then
        SocialPolicy.RegisterRegistry(PNC.SocialPolicy.Registry)
    end
    if DTCommon and DTCommon.SocialPolicy and DTCommon.SocialPolicy.Registry
        and not SocialPolicy.Registries["DTCommon"]
    then
        SocialPolicy.RegisterRegistry(DTCommon.SocialPolicy.Registry)
    end
end

function SocialPolicy.Resolve(eventType)
    if type(eventType) ~= "string" or eventType == "" then return nil end
    ensureBuiltinRegistries()
    local canonical = SocialPolicy.Aliases[eventType] or eventType
    return SocialPolicy.Events[canonical]
end

function SocialPolicy.ResolveForOwner(owner, eventType)
    if type(eventType) ~= "string" or eventType == "" then return nil end
    ensureBuiltinRegistries()
    local reg = SocialPolicy.Registries[tostring(owner or "")]
    if not reg or type(reg.Resolve) ~= "function" then
        return SocialPolicy.Resolve(eventType)
    end
    return reg.Resolve(eventType)
end

function SocialPolicy.ListRegistries()
    ensureBuiltinRegistries()
    local out = {}
    for owner, reg in pairs(SocialPolicy.Registries) do
        out[#out + 1] = {
            owner = owner,
            package = reg.package,
            fingerprint = reg.fingerprint,
        }
    end
    table.sort(out, function(a, b) return a.owner < b.owner end)
    return out
end

ensureBuiltinRegistries()

return SocialPolicy
