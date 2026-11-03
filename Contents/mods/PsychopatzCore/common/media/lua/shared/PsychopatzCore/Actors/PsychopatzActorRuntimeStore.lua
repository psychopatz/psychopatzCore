-- Production persistence hook for the canonical Core actor registry.
-- The registry codec remains generic; this module connects it to PZ GlobalModData
-- on server/SP authority only.

local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

local Store = {}

Store.STORAGE_KEY = "PsychopatzCore.ActorRegistry"
Store.SCHEMA_VERSION = 1
Store.Registry = nil
Store.Loaded = false
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

function Store.Load(create)
    if not authority() then return false, "server_authority_required" end
    if not Store.Registry then return false, "actor_registry_unattached" end

    local data = root(create == true)
    if type(data) ~= "table" then
        return false, "global_moddata_unavailable"
    end
    if data.registry == nil or data.registry == "" then
        Store.LastResult = { action = "load", accepted = true, reason = "empty" }
        return true, "empty"
    end

    local ok, reason = Store.Registry:Load(data.registry)
    Store.LastResult = {
        action = "load", accepted = ok == true, reason = reason,
    }
    if ok then Store.Loaded = true end
    return ok, reason
end

function Store.Save()
    if not authority() then return false, "server_authority_required" end
    if not Store.Registry then return false, "actor_registry_unattached" end

    local data = root(true)
    if type(data) ~= "table" then
        return false, "global_moddata_unavailable"
    end

    local serialized, reason = Store.Registry:Save()
    if not serialized then
        Store.LastResult = {
            action = "save", accepted = false, reason = reason,
        }
        return false, reason
    end

    data.schemaVersion = Store.SCHEMA_VERSION
    data.registry = serialized
    data.registryRevision = tonumber(Store.Registry.revision) or 0
    Store.LastResult = { action = "save", accepted = true }
    return true
end

local function installHooks()
    if Store.HooksInstalled or not authority() then return end
    Store.HooksInstalled = true

    if Events and Events.OnInitGlobalModData
        and type(Events.OnInitGlobalModData.Add) == "function"
    then
        Events.OnInitGlobalModData.Add(function()
            Store.Load(true)
        end)
    end

    if Events and Events.OnSave
        and type(Events.OnSave.Add) == "function"
    then
        Events.OnSave.Add(function()
            Store.Save()
        end)
    end
end

function Store.Attach(registry)
    if type(registry) ~= "table"
        or type(registry.Save) ~= "function"
        or type(registry.Load) ~= "function"
    then
        return false, "actor_registry_required"
    end
    Store.Registry = registry
    installHooks()

    -- If the GlobalModData root already exists (late capability activation),
    -- load it now. Do not create an empty root merely by attaching.
    local existing = root(false)
    if type(existing) == "table" and existing.registry then
        return Store.Load(false)
    end
    return true
end

return Store
