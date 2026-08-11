PsychopatzCore = PsychopatzCore or {}

local RingBuffer = require "PsychopatzCore/Collections/PC_RingBuffer"
local Journals = PsychopatzCore.Journals or {}
local types = Journals._types or {}
local subjects = Journals._subjects or {}
Journals._types = types
Journals._subjects = subjects
Journals.VERSION = 1

local function subjectKey(value)
    if value == nil then return nil end
    local key = tostring(value)
    return key ~= "" and key or nil
end

local function normalizePolicy(value)
    value = tostring(value or "boundedRing")
    if value == "ring" then value = "boundedRing" end
    if value == "uniqueSet" then value = "uniqueArchive" end
    return value
end

local function newContainer(config)
    if config.storage == "boundedRing" then
        return { policy = config.storage, data = RingBuffer.new(config.capacity) }
    end
    return { policy = config.storage, entries = {}, keys = {} }
end

local function uniqueKey(config, entry)
    if config.uniqueKey then return config.uniqueKey(entry) end
    return tostring(entry[1]) .. "\31" .. tostring(entry[2])
end

local function appendEntry(config, container, entry)
    if container.policy == "boundedRing" then
        container.data:append(entry)
        return true
    end
    local key = uniqueKey(config, entry)
    if key == nil or container.keys[key] then return false end
    container.keys[key] = true
    container.entries[#container.entries + 1] = entry
    return true
end

function Journals.registerType(typeId, config)
    if type(typeId) ~= "string" or typeId == "" or type(config) ~= "table" then
        return false, "invalid_journal_type"
    end
    local storage = normalizePolicy(config.storage)
    if storage ~= "boundedRing" and storage ~= "uniqueArchive" then
        return false, "unknown_storage_policy"
    end
    local normalized = {
        storage = storage,
        capacity = math.max(1, math.floor(tonumber(config.capacity) or 32)),
        persistent = config.persistent == true,
        accept = config.accept,
        uniqueKey = config.uniqueKey,
    }
    types[typeId] = normalized
    subjects[typeId] = subjects[typeId] or {}
    return true, normalized
end

function Journals.getType(typeId)
    return types[typeId]
end

function Journals.append(typeId, subjectId, eventType, ...)
    local config = types[typeId]
    local key = subjectKey(subjectId)
    if not config or not key or type(eventType) ~= "string" or eventType == "" then
        return false, "invalid_append"
    end
    if config.accept and config.accept(subjectId, eventType, ...) ~= true then
        return false, "rejected"
    end
    local bucket = subjects[typeId]
    local container = bucket[key]
    if not container then
        container = newContainer(config)
        bucket[key] = container
    end
    local entry = { eventType, ... }
    if not appendEntry(config, container, entry) then
        return false, "duplicate"
    end
    return true, entry
end

function Journals.get(typeId, subjectId)
    local bucket = subjects[typeId]
    return bucket and bucket[subjectKey(subjectId)] or nil
end

function Journals.hasJournal(typeId, subjectId)
    return Journals.get(typeId, subjectId) ~= nil
end

function Journals.getRecent(typeId, subjectId, limit, newestFirst)
    local container = Journals.get(typeId, subjectId)
    if not container then return {} end
    if container.policy == "boundedRing" then
        return container.data:snapshot(newestFirst == true, limit)
    end
    local output = {}
    local count = math.min(#container.entries, math.max(0,
        math.floor(tonumber(limit) or #container.entries)))
    for index = 1, count do
        local source = newestFirst == true
            and (#container.entries - index + 1) or index
        output[index] = container.entries[source]
    end
    return output
end

function Journals.clear(typeId, subjectId)
    local container = Journals.get(typeId, subjectId)
    if not container then return false end
    if container.policy == "boundedRing" then
        container.data:clear()
    else
        container.entries = {}
        container.keys = {}
    end
    return true
end

function Journals.remove(typeId, subjectId)
    local bucket = subjects[typeId]
    local key = subjectKey(subjectId)
    if not bucket or not key or not bucket[key] then return false end
    bucket[key] = nil
    return true
end

function Journals.export(typeId, subjectId)
    local config = types[typeId]
    local container = Journals.get(typeId, subjectId)
    if not config or not container then return nil end
    return {
        version = Journals.VERSION,
        storage = config.storage,
        entries = Journals.getRecent(typeId, subjectId),
    }
end

function Journals.import(typeId, subjectId, payload)
    local config = types[typeId]
    local key = subjectKey(subjectId)
    if not config or not key or type(payload) ~= "table" then
        return false, "invalid_import"
    end
    local entries = type(payload.entries) == "table" and payload.entries or payload
    local replacement = newContainer(config)
    local accepted = 0
    local start = config.storage == "boundedRing"
        and math.max(1, #entries - config.capacity + 1) or 1
    for index = start, #entries do
        local entry = entries[index]
        if type(entry) == "table" and type(entry[1]) == "string"
            and entry[1] ~= ""
        then
            if appendEntry(config, replacement, entry) then
                accepted = accepted + 1
            end
        end
    end
    if accepted > 0 then
        subjects[typeId][key] = replacement
    else
        subjects[typeId][key] = nil
    end
    return true, accepted
end

PsychopatzCore.Journals = Journals
PC_Journals = Journals

return Journals
