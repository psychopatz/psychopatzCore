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
History.VERSION = 3
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
    if tonumber(value.v) ~= History.VERSION then
        value.v = History.VERSION
        value.threads = {}
    end
    value.threads = type(value.threads) == "table" and value.threads or {}
    local day = currentDay()
    if tonumber(value.d) ~= day then
        value.d = day
        value.threads = {}
    end
    return value
end

local function threadID(namespace, npcID)
    return tostring(namespace or "default") .. ":" .. tostring(npcID or "unknown")
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

function History.Get(namespace, npcID)
    local records = root().threads[threadID(namespace, npcID)] or {}
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

function History.Append(namespace, npcID, speaker, value)
    local data = root()
    local key = threadID(namespace, npcID)
    local records = data.threads[key] or {}
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

function History.Clear(namespace, npcID)
    root().threads[threadID(namespace, npcID)] = nil
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
