local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"
local Registry = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRegistry"
local Import = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldImport"

local Store = {}

Store.STORAGE_KEY = "PsychopatzCore.SurvivorWorld"
Store.SCHEMA_VERSION = 1
Store.Registry = nil
Store.Active = false
Store.Loaded = false
Store.Dirty = false
Store.HooksInstalled = false
Store.LastResult = nil

local function authority()
    return RuntimeRole.AllowsServerCode()
end

local function root(create)
    if type(ModData) ~= "table" then return nil end
    if create and type(ModData.getOrCreate) == "function" then
        return ModData.getOrCreate(Store.STORAGE_KEY)
    end
    if type(ModData.get) == "function" then
        return ModData.get(Store.STORAGE_KEY)
    end
    return nil
end

local function ensureRegistry(spec)
    if Store.Registry then return Store.Registry end
    local registry, reason = Registry.new(spec or {})
    if not registry then return nil, reason end
    Store.Registry = registry
    return registry
end

function Store.GetRegistry()
    return Store.Registry
end

function Store.Snapshot()
    return Store.Registry and Store.Registry:Snapshot() or nil
end

function Store.MarkDirty(reason)
    if not Store.Registry then
        return false, "survivor_world_registry_unattached"
    end
    Store.Dirty = true
    Store.LastMutationReason = tostring(reason or "unspecified")
    return true
end

function Store.Load(create)
    if not authority() then
        return false, "server_authority_required"
    end
    if not Store.Active then
        return false, "survivor_world_not_active"
    end
    local registry, reason = ensureRegistry()
    if not registry then return false, reason end

    local data = root(create == true)
    if type(data) ~= "table" then
        return false, "global_moddata_unavailable"
    end
    if data.registry == nil or data.registry == "" then
        Store.Loaded = true
        -- Activation may happen before OnInitGlobalModData. Preserve any
        -- canonical mutations already made in that window so the first
        -- OnSave writes them instead of treating the empty root as clean.
        if registry:Revision() <= 0 then
            Store.Dirty = false
        end
        Store.LastResult = {
            action = "load",
            accepted = true,
            reason = "empty",
        }
        return true, "empty"
    end

    local ok
    ok, reason = registry:Load(data.registry)
    Store.LastResult = {
        action = "load",
        accepted = ok == true,
        reason = reason,
    }
    if ok then
        Store.Loaded = true
        Store.Dirty = false
    end
    return ok, reason
end

function Store.Save()
    if not authority() then
        return false, "server_authority_required"
    end
    if not Store.Active then
        return false, "survivor_world_not_active"
    end
    local registry, reason = ensureRegistry()
    if not registry then return false, reason end
    if not Store.Dirty and Store.Loaded then
        return false, "not_dirty"
    end

    local data = root(true)
    if type(data) ~= "table" then
        return false, "global_moddata_unavailable"
    end

    local serialized
    serialized, reason = registry:Save()
    if not serialized then
        Store.LastResult = {
            action = "save",
            accepted = false,
            reason = reason,
        }
        return false, reason
    end

    data.schemaVersion = Store.SCHEMA_VERSION
    data.registry = serialized
    data.registryRevision = registry:Revision()
    Store.Dirty = false
    Store.Loaded = true
    Store.LastResult = {
        action = "save",
        accepted = true,
    }
    return true, "saved"
end

local function installHooks()
    if Store.HooksInstalled or not authority() then return end
    Store.HooksInstalled = true

    if Events and Events.OnInitGlobalModData
        and type(Events.OnInitGlobalModData.Add) == "function"
    then
        Events.OnInitGlobalModData.Add(function()
            if Store.Active then Store.Load(true) end
        end)
    end

    if Events and Events.OnSave
        and type(Events.OnSave.Add) == "function"
    then
        Events.OnSave.Add(function()
            if Store.Active then Store.Save() end
        end)
    end
end

function Store.Activate(spec)
    if not authority() then
        return nil, "server_authority_required"
    end
    local registry, reason = ensureRegistry(spec)
    if not registry then return nil, reason end
    Store.Active = true
    installHooks()

    local existing = root(false)
    if type(existing) == "table" and existing.registry then
        local ok
        ok, reason = Store.Load(false)
        if not ok then return nil, reason end
    end
    return registry
end

function Store.Replace(snapshot, reason)
    if not authority() then
        return nil, "server_authority_required"
    end
    local registry, failure = Registry.new({ snapshot = snapshot })
    if not registry then return nil, failure end
    Store.Registry = registry
    Store.Active = true
    Store.Loaded = true
    Store.Dirty = true
    Store.LastMutationReason = tostring(reason or "replaced")
    installHooks()
    return registry
end

function Store.ImportPNC(source, options)
    if not authority() then
        return nil, "server_authority_required"
    end
    local snapshot, reason = Import.FromPNC(source, options)
    if not snapshot then return nil, reason end
    return Store.Replace(snapshot, "pnc_import")
end

function Store.ResetForTests()
    Store.Registry = nil
    Store.Active = false
    Store.Loaded = false
    Store.Dirty = false
    Store.LastResult = nil
    Store.LastMutationReason = nil
end

return Store
