require "PsychopatzCore/UI/Conversation/PsychopatzConversationText"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text
local Settings = Conversation.Settings
local History = Conversation.History or {}
Conversation.History = History

History.STORAGE_KEY = "PsychopatzCore_ConversationHistory"
History.VERSION = 4
History.memoryRoot = History.memoryRoot or {
    v = History.VERSION,
    d = -1,
    threads = {},
}

local function currentDay()
    local gameTime = getGameTime and getGameTime() or nil
    local hours = gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0
    return math.floor(hours / 24)
end

local function root()
    local value
    if ModData and ModData.getOrCreate then
        value = ModData.getOrCreate(History.STORAGE_KEY)
    else
        value = History.memoryRoot
    end
    if tonumber(value.v) ~= History.VERSION
        and tonumber(value.v) ~= 3
    then
        value.v = History.VERSION
        value.threads = {}
    end
    if tonumber(value.v) == 3 then
        value.v = History.VERSION
        value.migratedThreads = value.migratedThreads or {}
    end
    value.threads = type(value.threads) == "table" and value.threads or {}
    local day = currentDay()
    if tonumber(value.d) ~= day then
        value.d = day
        value.threads = {}
    end
    return value
end

local function legacyThreadID(namespace, npcID)
    return tostring(namespace or "default") .. ":" .. tostring(npcID or "unknown")
end

local function threadID(namespace, npcID, characterUUID)
    return tostring(characterUUID or "unbound") .. ":"
        .. legacyThreadID(namespace, npcID)
end

local function recordsFor(namespace, npcID, characterUUID, create)
    local data = root()
    local key = threadID(namespace, npcID, characterUUID)
    local legacyKey = legacyThreadID(namespace, npcID)
    data.migratedThreads = data.migratedThreads or {}
    if data.threads[key] == nil and data.threads[legacyKey] ~= nil
        and data.migratedThreads[legacyKey] == nil
        and characterUUID and characterUUID ~= "unbound"
    then
        data.threads[key] = data.threads[legacyKey]
        data.migratedThreads[legacyKey] = tostring(characterUUID)
    end
    if create and data.threads[key] == nil then data.threads[key] = {} end
    return data, key, data.threads[key] or {}
end

local function copyPrimitiveArgs(values)
    local output = {}
    local copied = 0
    local key
    local value
    for key, value in pairs(type(values) == "table" and values or {}) do
        if copied >= 8 then break end
        if type(key) == "number" or type(key) == "string" then
            if type(value) == "string"
                or type(value) == "number"
                or type(value) == "boolean"
            then
                output[key] = value
            else
                output[key] = tostring(value or "")
            end
            copied = copied + 1
        end
    end
    return output
end

function History.GetDay()
    return currentDay()
end

function History.Get(namespace, npcID, characterUUID)
    local _, _, records = recordsFor(namespace, npcID, characterUUID, false)
    local output = {}
    for index = 1, #records do
        local record = records[index]
        output[index] = {
            speaker = record.s == 1 and "player" or "npc",
            payload = Text.FromRecord(record),
            timestamp = record.t,
        }
    end
    return output
end

function History.Append(namespace, npcID, speaker, value, characterUUID)
    local data, key, records = recordsFor(
        namespace, npcID, characterUUID, true
    )
    data.threads[key] = records
    local textRecord = Text.ToRecord(value)
    records[#records + 1] = {
        s = speaker == "player" and 1 or 0,
        k = textRecord.k,
        d = textRecord.d,
        a = copyPrimitiveArgs(textRecord.a),
        x = textRecord.x,
        f = textRecord.f,
        t = getGameTime and getGameTime():getWorldAgeHours() or 0,
    }
    local limit = math.max(32, tonumber(Settings.Get("historySafetyLimit", 512)) or 512)
    while #records > limit do table.remove(records, 1) end
    return records[#records]
end

function History.Clear(namespace, npcID, characterUUID)
    root().threads[threadID(namespace, npcID, characterUUID)] = nil
end

function History.ClearAll()
    local data = root()
    data.threads = {}
end

function History.DebugSetDay(day)
    local data = root()
    data.d = tonumber(day) or data.d
end

return History
