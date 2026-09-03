-- Client-only flavor arbitration and presentation publisher.
--
-- This service is intentionally UI agnostic.  It publishes the same Core
-- conversation message consumed by nameplates and any future conversation,
-- diary, radio, or accessibility presentation adapters.

require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
require "PsychopatzCore/Events/PC_EventBus"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SocialFlavorClient = PsychopatzCore.SocialFlavorClient or {}

local Client = PsychopatzCore.SocialFlavorClient
local Flavor = PsychopatzCore.SocialFlavor
local Message = PsychopatzCore.Conversation.Message
local EventBus = PsychopatzCore.Events
local OWNER_TOKEN = Client

Client.EVENT_DELIVERED = "PsychopatzCore.SocialFlavor.Delivered"
Client.MAX_QUEUE = 24
Client.MAX_TEXT_LENGTH = 420
Client.DEFAULT_TTL_MS = 20000
Client.DEFAULT_MERGE_WINDOW_MS = 10000
Client.DEFAULT_FAMILY_COOLDOWN_MS = 30000
Client.DEFAULT_SPEAKER_COOLDOWN_MS = 20000
Client.DEFAULT_AMBIENT_CADENCE_MS = 4500
Client.DEFAULT_LLM_GRACE_MS = 2500
Client.DEFAULT_HOLD_MS = 4500
Client.MAX_DELIVERED = 256
Client.CRITICAL_PRIORITY = 100
Client.LLM_PRIORITY = 90

local queue = {}
local byEventID = {}
local delivered = {}
local deliveredOrder = {}
local recentFamily = {}
local recentSpeaker = {}
local sequence = 0
local activeUntil = 0
local lastAmbientAt = 0
local llmProvider = nil
local llmCanceler = nil
local debugEnabled = false

local function now()
    return getTimeInMillis and tonumber(getTimeInMillis())
        or getTimestampMs and tonumber(getTimestampMs()) or 0
end

local function clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function log(event, details)
    if debugEnabled and print then
        print("[PsychopatzCore][SocialFlavor] " .. tostring(event) .. " "
            .. tostring(details or ""))
    end
end

local function boundedText(value)
    value = clean(value, "")
    if #value <= Client.MAX_TEXT_LENGTH then return value end
    return string.sub(value, 1, Client.MAX_TEXT_LENGTH - 1) .. "…"
end

local function numeric(value, fallback)
    value = tonumber(value)
    return value == nil and fallback or value
end

local function copyMap(source)
    local output = {}
    if type(source) ~= "table" then return output end
    for key, value in pairs(source) do
        if type(value) ~= "table" and type(value) ~= "function"
            and type(value) ~= "userdata"
        then
            output[key] = value
        end
    end
    return output
end

local function priorityFor(spec)
    local priority = numeric(spec.priority, nil)
    if spec.llmEligible then
        priority = math.max(priority or 0,
            numeric(spec.llmPriority, Client.LLM_PRIORITY))
    end
    if priority == nil then priority = 35 end
    return math.max(0, math.min(Client.CRITICAL_PRIORITY, priority))
end

local function score(item)
    -- Priority is the hard ordering class. Weight only breaks ties, so a
    -- burst of low-value chatter can never starve a warning.
    return item.priority * 1000000 + item.weight * 1000 - item.sequence
end

local function removeAt(index)
    local item = table.remove(queue, index)
    if item and item.eventID and byEventID[item.eventID] == item then
        byEventID[item.eventID] = nil
    end
    return item
end

local function purge(current)
    local index = 1
    while index <= #queue do
        local item = queue[index]
        if item.expiresAt > 0 and current >= item.expiresAt then
            if item.llmRequested and type(llmCanceler) == "function" then
                pcall(llmCanceler, item.eventID)
            end
            removeAt(index)
            log("expired", "event=" .. tostring(item.eventID))
        else
            index = index + 1
        end
    end
end

local function lowestIndex()
    local index
    local lowest
    for position, item in ipairs(queue) do
        if not lowest or score(item) < score(lowest) then
            lowest = item
            index = position
        end
    end
    return index, lowest
end

local function findMerge(item)
    local key = item.mergeKey
    if not key then return nil end
    for _, queued in ipairs(queue) do
        if queued.mergeKey == key
            and queued.createdAt + item.mergeWindowMs >= item.createdAt
        then
            return queued
        end
    end
    return nil
end

local function cooldownActive(map, key, current)
    return key and tonumber(map[key]) and current < tonumber(map[key])
end

local function normalize(spec)
    if type(spec) ~= "table" then return nil, "invalid_spec" end
    local eventID = clean(spec.eventID or spec.id, nil)
    local speakerID = clean(spec.speakerID or spec.npcID, nil)
    if not eventID or not speakerID then return nil, "identity_required" end
    local current = now()
    sequence = sequence + 1
    local priority = priorityFor(spec)
    local cooldowns = type(spec.cooldowns) == "table" and spec.cooldowns or {}
    local context = copyMap(spec.context)
    context.npcType = context.npcType or spec.npcType
    context.socialRole = context.socialRole or spec.socialRole
    context.relationshipState = context.relationshipState
        or spec.relationshipState
    context.relationshipTier = context.relationshipTier
        or spec.relationshipTier
    local item = {
        eventID = eventID,
        flavorID = clean(spec.flavorID, nil),
        family = clean(spec.family, "ambient"),
        speakerID = speakerID,
        speakerName = clean(spec.speakerName, speakerID),
        speakerKind = clean(spec.speakerKind, "npc"),
        playerUUID = clean(spec.playerUUID, nil),
        context = context,
        text = boundedText(spec.text),
        seed = spec.seed or eventID,
        priority = priority,
        weight = numeric(spec.weight, 0),
        mergeKey = clean(spec.mergeKey, nil),
        mergeWindowMs = numeric(cooldowns.mergeWindowMs
            or spec.mergeWindowMs, Client.DEFAULT_MERGE_WINDOW_MS),
        familyCooldownMs = numeric(cooldowns.familyMs
            or spec.familyCooldownMs, Client.DEFAULT_FAMILY_COOLDOWN_MS),
        speakerCooldownMs = numeric(cooldowns.speakerMs
            or spec.speakerCooldownMs, Client.DEFAULT_SPEAKER_COOLDOWN_MS),
        ambientCadenceMs = numeric(cooldowns.ambientMs
            or spec.ambientCadenceMs, Client.DEFAULT_AMBIENT_CADENCE_MS),
        holdMs = numeric(spec.holdMs, Client.DEFAULT_HOLD_MS),
        ttlMs = numeric(spec.ttlMs, Client.DEFAULT_TTL_MS),
        llmEligible = spec.llmEligible == true,
        memoryEligible = spec.memoryEligible == true,
        llmGraceMs = numeric(spec.llmGraceMs, Client.DEFAULT_LLM_GRACE_MS),
        presentationState = copyMap(spec.presentationState),
        source = copyMap(spec.source),
        createdAt = current,
        expiresAt = current + numeric(spec.ttlMs, Client.DEFAULT_TTL_MS),
        sequence = sequence,
        mergedCount = 1,
    }
    if item.text == "" and not item.flavorID then return nil, "content_required" end
    return item
end

local function shouldAdmit(item, current)
    if delivered[item.eventID] then return false, "duplicate_delivered" end
    if byEventID[item.eventID] then return false, "duplicate_queued" end
    local merged = findMerge(item)
    if merged then return true, "merge", merged end
    if item.priority < Client.CRITICAL_PRIORITY
        and cooldownActive(recentFamily, item.family, current)
    then
        return false, "family_cooldown"
    end
    if item.priority < Client.CRITICAL_PRIORITY
        and cooldownActive(recentSpeaker, item.speakerID, current)
    then
        return false, "speaker_cooldown"
    end
    if item.priority < Client.CRITICAL_PRIORITY
        and lastAmbientAt > 0
        and current < lastAmbientAt + item.ambientCadenceMs
    then
        return false, "ambient_cadence"
    end
    return true, "accepted"
end

local function discardSuppressed(current)
    local index = 1
    while index <= #queue do
        local item = queue[index]
        local suppressed = item.priority < Client.CRITICAL_PRIORITY
            and (
                cooldownActive(recentFamily, item.family, current)
                or cooldownActive(recentSpeaker, item.speakerID, current)
                or (lastAmbientAt > 0
                    and current < lastAmbientAt + item.ambientCadenceMs)
            )
        if suppressed then
            if item.llmRequested and type(llmCanceler) == "function" then
                pcall(llmCanceler, item.eventID)
            end
            removeAt(index)
            log("discarded", "event=" .. tostring(item.eventID)
                .. " reason=delivery_cooldown")
        else
            index = index + 1
        end
    end
end

local function enqueueInternal(item)
    local current = now()
    purge(current)
    local admitted, reason, merged = shouldAdmit(item, current)
    if not admitted then
        log("discarded", "event=" .. item.eventID .. " reason=" .. reason)
        return false, reason
    end
    if reason == "merge" then
        merged.mergedCount = merged.mergedCount + 1
        merged.context = item.context
        merged.createdAt = item.createdAt
        merged.expiresAt = math.max(merged.expiresAt, item.expiresAt)
        merged.weight = math.max(merged.weight, item.weight)
        return true, "merged"
    end
    if #queue >= Client.MAX_QUEUE then
        local index, lowest = lowestIndex()
        if not lowest or score(lowest) >= score(item) then
            return false, "queue_full"
        end
        removeAt(index)
        log("evicted", "event=" .. tostring(lowest.eventID))
    end
    queue[#queue + 1] = item
    byEventID[item.eventID] = item
    log("queued", "event=" .. item.eventID .. " priority="
        .. tostring(item.priority) .. " family=" .. item.family)
    return true, "accepted"
end

local function fallbackText(item)
    if item.text ~= "" then return item.text, false end
    local result = Flavor.ResolveDetailed(
        item.flavorID, "npc", item.seed, item.context
    )
    return result and boundedText(result.text) or nil, false
end

local function publish(item, text, isLLM, current)
    text = boundedText(text)
    if text == "" then return false, "empty_text" end
    local presentation = copyMap(item.presentationState)
    if presentation.nameplate == nil then presentation.nameplate = true end
    if presentation.conversationUI == nil then presentation.conversationUI = false end
    if presentation.interrupt == nil then
        presentation.interrupt = item.priority >= Client.CRITICAL_PRIORITY
    end
    local source = copyMap(item.source)
    source.kind = source.kind or "social_flavor"
    source.family = item.family
    source.eventID = item.eventID
    source.priority = item.priority
    source.weight = item.weight
    source.llm = isLLM == true
    -- Ambient chatter is not durable LLM memory by default.  Future event
    -- families such as gossip may explicitly opt in; this keeps routine
    -- combat commentary from inflating the client-to-provider outbox.
    source.contextEligible = item.memoryEligible == true
    source.excludeFromLLM = item.memoryEligible ~= true
    local message = Message.New({
        messageID = "social-flavor:" .. item.eventID,
        conversationID = "social-flavor:" .. item.eventID,
        sequence = item.mergedCount,
        speaker = item.speakerKind,
        speakerID = item.speakerID,
        speakerName = item.speakerName,
        speakerKind = item.speakerKind,
        playerUUID = item.playerUUID,
        npcUUID = item.speakerID,
        namespace = "PsychopatzCore.SocialFlavor",
        text = text,
        payload = { text = text, style = "social_flavor" },
        source = source,
        presentationState = presentation,
    })
    Message.Publish(message)
    delivered[item.eventID] = true
    deliveredOrder[#deliveredOrder + 1] = item.eventID
    while #deliveredOrder > Client.MAX_DELIVERED do
        local oldest = table.remove(deliveredOrder, 1)
        delivered[oldest] = nil
    end
    byEventID[item.eventID] = nil
    recentFamily[item.family] = current + item.familyCooldownMs
    recentSpeaker[item.speakerID] = current + item.speakerCooldownMs
    lastAmbientAt = current
    activeUntil = current + item.holdMs
    EventBus.emit(Client.EVENT_DELIVERED, {
        item = item,
        message = message,
        text = text,
        llm = isLLM == true,
    })
    log("delivered", "event=" .. item.eventID .. " priority="
        .. tostring(item.priority) .. " llm=" .. tostring(isLLM == true)
        .. " text=" .. text)
    return true, "delivered"
end

local function choose(current)
    local selected
    local selectedIndex
    for index, item in ipairs(queue) do
        if current >= activeUntil
            or item.priority >= Client.CRITICAL_PRIORITY
        then
            if not selected or score(item) > score(selected) then
                selected = item
                selectedIndex = index
            end
        end
    end
    return selectedIndex, selected
end

local function requestLLM(item, current)
    if not item.llmEligible or type(llmProvider) ~= "function" then
        return false
    end
    if item.llmRequested then return true end
    item.llmRequested = true
    item.llmDeadline = current + item.llmGraceMs
    local function complete(text)
        Client.ReceiveLLMResult(item.eventID, text)
    end
    local ok, accepted = pcall(llmProvider, item, complete)
    if not ok or accepted ~= true then
        item.llmRequested = false
        item.llmDeadline = nil
        log("llm_unavailable", "event=" .. item.eventID)
        return false
    end
    log("llm_requested", "event=" .. item.eventID)
    return true
end

function Client.SetLLMProvider(provider, canceler)
    llmProvider = type(provider) == "function" and provider or nil
    llmCanceler = type(canceler) == "function" and canceler or nil
    return true
end

function Client.Enqueue(spec)
    local item, reason = normalize(spec)
    if not item then return false, reason end
    return enqueueInternal(item)
end

function Client.ReceiveLLMResult(eventID, text)
    eventID = clean(eventID, "")
    local item = byEventID[eventID]
    if not item or delivered[eventID] then
        log("llm_late_result", "event=" .. eventID)
        return false, "event_unavailable"
    end
    text = boundedText(text)
    if text == "" then return false, "empty_text" end
    item.llmText = text
    item.llmReady = true
    item.priority = math.max(item.priority, Client.LLM_PRIORITY)
    item.expiresAt = math.max(item.expiresAt, now() + 1000)
    log("llm_ready", "event=" .. eventID)
    return true, "ready"
end

function Client.Pump(current)
    current = tonumber(current) or now()
    purge(current)
    discardSuppressed(current)
    local index, item = choose(current)
    if not item then return false, "idle" end
    if item.llmEligible and not item.llmReady then
        requestLLM(item, current)
        if item.llmRequested and not item.llmReady
            and current < item.llmDeadline
        then
            return false, "llm_wait"
        end
        if item.llmRequested and not item.llmReady
            and type(llmCanceler) == "function"
        then
            pcall(llmCanceler, item.eventID)
        end
    end
    removeAt(index)
    local text = item.llmReady and item.llmText or fallbackText(item)
    local isLLM = item.llmReady and true or false
    if type(text) == "table" then text = text[1] end
    if not text or text == "" then
        log("discarded", "event=" .. item.eventID .. " reason=no_text")
        return false, "no_text"
    end
    return publish(item, text, isLLM, current)
end

function Client.GetQueueSnapshot()
    local output = {}
    for _, item in ipairs(queue) do
        output[#output + 1] = {
            eventID = item.eventID,
            family = item.family,
            speakerID = item.speakerID,
            priority = item.priority,
            weight = item.weight,
            mergedCount = item.mergedCount,
            llmRequested = item.llmRequested == true,
            llmReady = item.llmReady == true,
        }
    end
    return output
end

function Client.SetDebug(enabled)
    debugEnabled = enabled == true
    return debugEnabled
end

function Client.Reset()
    if type(llmCanceler) == "function" then
        for _, item in ipairs(queue) do
            if item.llmRequested then pcall(llmCanceler, item.eventID) end
        end
    end
    queue = {}
    byEventID = {}
    delivered = {}
    deliveredOrder = {}
    recentFamily = {}
    recentSpeaker = {}
    sequence = 0
    activeUntil = 0
    lastAmbientAt = 0
    return true
end

EventBus.clearOwner(OWNER_TOKEN)
if Events and Events.OnTick and not Client.TickRegistered then
    Events.OnTick.Add(function() Client.Pump() end)
    Client.TickRegistered = true
end

return Client
