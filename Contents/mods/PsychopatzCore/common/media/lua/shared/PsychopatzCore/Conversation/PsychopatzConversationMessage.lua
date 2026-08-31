PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Message = Conversation.Message or {}
Conversation.Message = Message

Message.VERSION = 1
Message.SAVE_ID_STORAGE_KEY = "PsychopatzCore_SaveIdentity"
Message.EVENT_TYPE = "PsychopatzCore.Conversation.Message"
Message.memoryRoot = Message.memoryRoot or {}

local serial = 0

local function clockValue()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function randomValue()
    if ZombRand then return tonumber(ZombRand(0, 1000000)) or 0 end
    return 0
end

local function newID(prefix)
    serial = serial + 1
    return tostring(prefix or "message") .. ":" .. tostring(clockValue())
        .. ":" .. tostring(serial) .. ":" .. tostring(randomValue())
end

local function copyTable(values)
    local output = {}
    if type(values) ~= "table" then return output end
    local key
    local value
    for key, value in pairs(values) do output[key] = value end
    return output
end

local function copyPayload(value)
    if type(value) ~= "table" then
        return { text = tostring(value or "") }
    end
    return {
        key = value.key,
        domain = value.domain,
        args = copyTable(value.args),
        text = value.text,
        fallback = value.fallback,
        delayMs = value.delayMs,
        style = value.style,
    }
end

local function saveIdentity()
    if ModData and ModData.getOrCreate then
        return ModData.getOrCreate(Message.SAVE_ID_STORAGE_KEY)
    end
    Message.memoryRoot.identity = Message.memoryRoot.identity or {}
    return Message.memoryRoot.identity
end

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return 0
end

function Message.NewID(prefix)
    return newID(prefix)
end

function Message.GetSaveID()
    local identity = saveIdentity()
    if type(identity.saveUUID) ~= "string" or identity.saveUUID == "" then
        identity.version = Message.VERSION
        local saveName = getCurrentSaveName and getCurrentSaveName() or nil
        if saveName ~= nil and tostring(saveName) ~= "" then
            identity.saveUUID = "pz-save:" .. tostring(saveName)
        else
            identity.saveUUID = newID("save")
        end
    end
    return identity.saveUUID
end

function Message.GetWorldAgeHours()
    return worldAgeHours()
end

function Message.GetGameDay(hours)
    return math.floor((tonumber(hours) or worldAgeHours()) / 24)
end

function Message.Publish(message)
    if type(message) ~= "table" then return false end
    local events = PsychopatzCore and PsychopatzCore.Events
    if events and type(events.emit) == "function" then
        events.emit(Message.EVENT_TYPE, message)
    end
    return true
end

local function isFalseFlag(value)
    return value == false
        or string.lower(tostring(value or "")) == "false"
        or tostring(value or "") == "0"
end

local function isTrueFlag(value)
    return value == true
        or string.lower(tostring(value or "")) == "true"
        or tostring(value or "") == "1"
end

local LLM_FAILURE_MARKERS = {
    "i cannot answer right now",
    "provider request failed",
    "provider returned an empty response",
    "openai-compatible provider",
    "llm completion failed",
    "i am an ai assistant",
    "as an ai",
    "language model",
    "large language model",
    "i don't have a personal identity",
    "i do not have a personal identity",
    "i don't have a name in the traditional sense",
    "i do not have a name in the traditional sense",
}

function Message.IsLLMContextEligible(message, content)
    if type(message) ~= "table" then return true end
    for _, source in ipairs({ message.source, message.provenance }) do
        if type(source) == "table"
            and (isFalseFlag(source.contextEligible)
                or isTrueFlag(source.providerFailure)
                or isTrueFlag(source.excludeFromLLM))
        then
            return false
        end
    end

    local speaker = string.lower(tostring(message.speakerKind or message.speaker or ""))
    if speaker == "player" then return true end
    local lowered = string.lower(tostring(content or message.text or ""))
    for _, marker in ipairs(LLM_FAILURE_MARKERS) do
        if string.find(lowered, marker, 1, true) then return false end
    end
    return true
end

function Message.New(spec)
    spec = spec or {}
    local hours = tonumber(spec.worldAgeHours)
    if hours == nil then hours = worldAgeHours() end

    local conversationID = tostring(spec.conversationID or "")
    if conversationID == "" then conversationID = newID("conversation") end

    local sequence = tonumber(spec.sequence) or 1
    local messageID = tostring(spec.messageID or "")
    if messageID == "" then
        messageID = conversationID .. ":" .. tostring(sequence)
    end

    local payload = copyPayload(spec.payload)
    local resolvedText = spec.text
    if resolvedText == nil then
        resolvedText = payload.text or payload.fallback or payload.key or ""
    end

    return {
        version = Message.VERSION,
        saveUUID = spec.saveUUID,
        messageID = messageID,
        conversationID = conversationID,
        sequence = sequence,

        -- Keep the legacy field for existing conversation parts.
        speaker = spec.speaker or "npc",
        speakerID = tostring(spec.speakerID or "unknown-speaker"),
        speakerName = spec.speakerName,
        speakerKind = spec.speakerKind or spec.speaker or "npc",
        playerUUID = spec.playerUUID,
        npcUUID = spec.npcUUID,
        namespace = spec.namespace,

        payload = payload,
        text = tostring(resolvedText or ""),
        gameDay = Message.GetGameDay(hours),
        worldAgeHours = hours,
        participants = copyTable(spec.participants),
        visibility = spec.visibility or "PUBLIC",
        provenance = copyTable(spec.provenance),

        source = copyTable(spec.source),
        deliveryState = spec.deliveryState or "delivered",
        presentationState = copyTable(spec.presentationState),
    }
end

return Message
