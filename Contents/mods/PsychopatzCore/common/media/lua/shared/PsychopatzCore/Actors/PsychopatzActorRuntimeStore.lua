-- Production persistence hook for the canonical Core actor registry.
-- The registry codec remains generic; this module connects it to PZ GlobalModData
-- on server/SP authority only.

local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

local Store = {}

Store.STORAGE_KEY = "PsychopatzCore.ActorRegistry"
Store.SCHEMA_VERSION = 1
-- PZ's ByteBuffer StringUTF stores the encoded byte length in a signed
-- short. Keep a margin below 32767 and split larger JSON payloads into
-- ordinary nested ModData strings.
Store.MAX_STRING_BYTES = 30000
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
        -- The lead byte belongs with the continuation bytes in the next
        -- chunk. This preserves UTF-8 actor names across reassembly.
        proposedEnd = proposedEnd - 1
    elseif utf8Width(byte) > 1
    then
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
            finish = safeChunkEnd(
                serialized,
                startIndex,
                proposedEnd
            )
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

function Store.Load(create)
    if not authority() then return false, "server_authority_required" end
    if not Store.Registry then return false, "actor_registry_unattached" end

    local data = root(create == true)
    if type(data) ~= "table" then
        return false, "global_moddata_unavailable"
    end
    local serialized, serializedReason = serializedFromRoot(data)
    if not serialized then
        if serializedReason ~= "empty" then
            Store.LastResult = {
                action = "load",
                accepted = false,
                reason = serializedReason,
            }
            return false, serializedReason
        end
        Store.LastResult = { action = "load", accepted = true, reason = "empty" }
        return true, "empty"
    end

    local ok, reason = Store.Registry:Load(serialized)
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
    if #serialized > Store.MAX_STRING_BYTES then
        data.registry = nil
        data.registryChunks = splitRegistry(serialized)
        data.registryChunkCount = #data.registryChunks
    else
        data.registry = serialized
        data.registryChunks = nil
        data.registryChunkCount = nil
    end
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
    if type(existing) == "table"
        and (existing.registry or existing.registryChunks)
    then
        return Store.Load(false)
    end
    return true
end

return Store
