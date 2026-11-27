local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"
local Registry = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRegistry"

local Store = {}

Store.STORAGE_KEY = "PsychopatzCore.SurvivorWorld"
Store.SCHEMA_VERSION = 1
-- Project Zomboid's GlobalModData binary string reader uses a signed 16-bit
-- short length (max 32,767 bytes). Chunk larger SurvivorWorld snapshots into
-- UTF-8-safe 30,000-byte strings, matching PsychopatzActorRuntimeStore.
Store.MAX_STRING_BYTES = 30000
Store.Registry = nil
Store.Active = false
Store.Loaded = false
Store.Dirty = false
Store.HooksInstalled = false
Store.LastResult = nil

local function isContinuationByte(value)
    return value ~= nil and value >= 128 and value <= 191
end

local function utf8Width(value)
    if value == nil or value < 128 then return 1 end
    if value <= 223 then return 2 end
    if value <= 239 then return 3 end
    if value <= 247 then return 4 end
    return 1
end

local function safeChunkEnd(value, startIndex, proposedEnd)
    local byte = string.byte(value, proposedEnd)
    if isContinuationByte(byte) then
        while proposedEnd > startIndex
            and isContinuationByte(string.byte(value, proposedEnd))
        do
            proposedEnd = proposedEnd - 1
        end
        proposedEnd = proposedEnd - 1
    elseif utf8Width(byte) > 1 then
        proposedEnd = proposedEnd - 1
    end
    if proposedEnd < startIndex then
        return startIndex
    end
    return proposedEnd
end

local function splitRegistry(serialized)
    local chunks = {}
    local startIndex = 1
    local length = #serialized
    while startIndex <= length do
        local proposedEnd = math.min(
            length,
            startIndex + Store.MAX_STRING_BYTES - 1
        )
        local finish = proposedEnd
        if proposedEnd < length then
            finish = safeChunkEnd(serialized, startIndex, proposedEnd)
        end
        chunks[#chunks + 1] = string.sub(serialized, startIndex, finish)
        startIndex = finish + 1
    end
    return chunks
end

local function serializedFromRoot(data)
    if type(data.registry) == "string" and data.registry ~= "" then
        return data.registry
    end
    local chunks = data.registryChunks
    if type(chunks) ~= "table" then return nil, "empty" end
    local count = #chunks
    if count < 1 then return nil, "empty" end
    local parts = {}
    for index = 1, count do
        local chunk = chunks[index]
        if type(chunk) ~= "string"
            or #chunk > Store.MAX_STRING_BYTES
        then
            return nil, "registry_chunk_invalid"
        end
        parts[index] = chunk
    end
    return table.concat(parts)
end

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

local function isFiniteNumber(v)
    v = tonumber(v)
    return v ~= nil and v == v and v ~= math.huge and v ~= -math.huge
end

-- Boot sanitizer: repairs corrupted NaN/inf journey or coordinate fields so a
-- server crash or mid-save mod update can never leave a save stuck.
function Store.SanitizeLoadedRegistry(registry)
    if type(registry) ~= "table" or type(registry.snapshot) ~= "table" then
        return 0
    end
    local repaired = 0
    local groups = type(registry.snapshot.groups) == "table" and registry.snapshot.groups or {}
    for _, group in pairs(groups) do
        if type(group) == "table" then
            if type(group.journey) == "table" then
                local j = group.journey
                local bad = not isFiniteNumber(j.startAt)
                    or not isFiniteNumber(j.eta)
                    or not isFiniteNumber(j.speed) or tonumber(j.speed) <= 0
                    or not isFiniteNumber(j.x)
                    or not isFiniteNumber(j.y)
                if bad then
                    group.journey = nil
                    if group.state == "TRAVELING" then
                        group.state = "IDLE"
                    end
                    repaired = repaired + 1
                end
            end
            if type(group.location) == "table" then
                if not isFiniteNumber(group.location.x) then
                    group.location.x = 0
                    repaired = repaired + 1
                end
                if not isFiniteNumber(group.location.y) then
                    group.location.y = 0
                    repaired = repaired + 1
                end
            end
        end
    end
    return repaired
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
    local serialized, readReason = serializedFromRoot(data)
    if not serialized then
        if readReason ~= "empty" then
            Store.LastResult = {
                action = "load",
                accepted = false,
                reason = readReason,
            }
            return false, readReason
        end
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
    ok, reason = registry:Load(serialized)
    Store.LastResult = {
        action = "load",
        accepted = ok == true,
        reason = reason,
    }
    if ok then
        local repaired = Store.SanitizeLoadedRegistry(registry)
        Store.Loaded = true
        Store.Dirty = repaired > 0
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
    if #serialized > Store.MAX_STRING_BYTES then
        data.registry = nil
        data.registryChunks = splitRegistry(serialized)
        data.registryChunkCount = #data.registryChunks
    else
        data.registry = serialized
        data.registryChunks = nil
        data.registryChunkCount = nil
    end
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
            -- Do not clobber an already-loaded or dirty live registry if
            -- OnCreatePlayer / pre-cutover startup already populated and
            -- mutated SurvivorWorld before OnInitGlobalModData fires.
            if Store.Active and not Store.Loaded then
                Store.Load(true)
            end
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
    -- Once loaded, the live registry owns unsaved mutations. Ordinary
    -- callers activate repeatedly to resolve that registry.
    if not Store.Loaded
        and type(existing) == "table"
        and (existing.registry or existing.registryChunks)
    then
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

function Store.ResetForTests()
    Store.Registry = nil
    Store.Active = false
    Store.Loaded = false
    Store.Dirty = false
    Store.LastResult = nil
    Store.LastMutationReason = nil
end

return Store
