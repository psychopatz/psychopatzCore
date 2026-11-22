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
Client.AMBIENT_TTS_CONVERSATION_ID = "social-flavor:ambient_floor"
Client.VOICE_LIFECYCLE_EVENT = "PsychopatzCore.Voice.Lifecycle"
Client.MAX_QUEUE = 12
Client.MAX_QUEUE_PER_SPEAKER = 2
Client.MAX_TEXT_LENGTH = 420
Client.DEFAULT_TTL_MS = 20000
Client.DEFAULT_MERGE_WINDOW_MS = 10000
Client.DEFAULT_FAMILY_COOLDOWN_MS = 30000
Client.DEFAULT_SPEAKER_COOLDOWN_MS = 20000
Client.DEFAULT_AMBIENT_CADENCE_MS = 4500
Client.DEFAULT_LLM_GRACE_MS = 2500
Client.DEFAULT_HOLD_MS = 2400
Client.MIN_READABLE_HOLD_MS = 1800
Client.MAX_READABLE_HOLD_MS = 3800
Client.TTS_MIN_TIMEOUT_MS = 4500
Client.TTS_MAX_TIMEOUT_MS = 9000
Client.TTS_FINISH_GAP_MS = 350
Client.MAX_DELIVERED = 256
Client.CRITICAL_PRIORITY = 100
Client.LLM_PRIORITY = 90
Client.SCENE_PRIORITY_FLOOR = 80
Client.LANE_SCENE = "scene"
Client.LANE_BEAT = "beat"
Client.LANE_AMBIENT = "ambient"
Client.MAX_ACTIVE_SCENES = 16
Client.MAX_ACTIVE_THREADS = 24
Client.MAX_COOLDOWNS = 128

local queue = {}
local byEventID = {}
local delivered = {}
local deliveredOrder = {}
local recentFamily = {}
local recentSpeaker = {}
local recentSceneFamily = {}
local recentSceneSpeaker = {}
local activeScenes = {}
local activeThreads = {}
local sequence = 0
local laneSequence = 0
local activeUntil = 0
local activePriority = 0
local activeFloorPriority = 0
local activeLane = nil
local activeSceneID = nil
local activeEventID = nil
local activeMessageID = nil
local activeSpeakerID = nil
local activeConversationID = nil
local lastAmbientAt = 0
local lastAmbientPriority = 0
local activeThreadID = nil
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

local function basePriorityFor(spec)
    local priority = numeric(spec.priority, nil)
    if priority == nil then priority = 35 end
    return math.max(0, math.min(Client.CRITICAL_PRIORITY, priority))
end

local function priorityFor(spec, basePriority)
    local priority = basePriority
    if spec.llmEligible then
        priority = math.max(priority or 0,
            numeric(spec.llmPriority, Client.LLM_PRIORITY))
    end
    return math.max(0, math.min(Client.CRITICAL_PRIORITY, priority))
end

local function effectiveScorePriority(item)
    if item.lane == Client.LANE_SCENE then
        return math.max(item.priority, item.sceneFloor or Client.SCENE_PRIORITY_FLOOR)
    end
    if item.urgent then
        return math.max(item.priority, Client.SCENE_PRIORITY_FLOOR + 1)
    end
    if item.basePriority < Client.SCENE_PRIORITY_FLOOR
        and item.priority >= Client.SCENE_PRIORITY_FLOOR
    then
        return Client.SCENE_PRIORITY_FLOOR - 1
    end
    return item.priority
end

local function score(item)
    -- Priority is the hard ordering class. Weight only breaks ties, so a
    -- burst of low-value chatter can never starve a warning.
    return effectiveScorePriority(item) * 1000000 + item.weight * 1000 - item.sequence
end

local function cancelLLM(item)
    if item and item.llmRequested and type(llmCanceler) == "function" then
        llmCanceler(item.eventID)
    end
end

local function pruneCooldownMap(map, current)
    local expired = {}
    local count = 0
    local oldestKey = nil
    local oldestExpiry = nil
    for key, expiry in pairs(map) do
        local exp = tonumber(expiry) or 0
        if current >= exp then
            expired[#expired + 1] = key
        else
            count = count + 1
            if not oldestExpiry or exp < oldestExpiry then
                oldestExpiry = exp
                oldestKey = key
            end
        end
    end
    for i = 1, #expired do
        map[expired[i]] = nil
    end
    if count > Client.MAX_COOLDOWNS and oldestKey ~= nil then
        map[oldestKey] = nil
    end
end

local function pruneLaneMap(map, current, maxEntries)
    local expired = {}
    local count = 0
    for key, entry in pairs(map) do
        if type(entry) ~= "table" or current >= (tonumber(entry.untilMs) or 0) then
            expired[#expired + 1] = key
        else
            count = count + 1
        end
    end
    for i = 1, #expired do
        map[expired[i]] = nil
    end
    while count > maxEntries do
        local oldestKey = nil
        local oldestSeq = nil
        for key, entry in pairs(map) do
            local seq = tonumber(entry.seq) or 0
            if not oldestSeq or seq < oldestSeq then
                oldestSeq = seq
                oldestKey = key
            end
        end
        if oldestKey == nil then break end
        map[oldestKey] = nil
        count = count - 1
    end
end

local function pruneRuntimeState(current)
    pruneLaneMap(activeScenes, current, Client.MAX_ACTIVE_SCENES)
    pruneLaneMap(activeThreads, current, Client.MAX_ACTIVE_THREADS)
    if activeSceneID and not activeScenes[activeSceneID] and current >= activeUntil then
        activeSceneID = nil
    end
    if activeThreadID and not activeThreads[activeThreadID] then
        activeThreadID = nil
    end
    if activeLane ~= nil and current >= activeUntil then
        activeLane = nil
        activeFloorPriority = 0
    end
    pruneCooldownMap(recentFamily, current)
    pruneCooldownMap(recentSpeaker, current)
    pruneCooldownMap(recentSceneFamily, current)
    pruneCooldownMap(recentSceneSpeaker, current)
end

local function removeAt(index)
    local item = table.remove(queue, index)
    if item and item.eventID and byEventID[item.eventID] == item then
        byEventID[item.eventID] = nil
    end
    return item
end

local function purge(current)
    pruneRuntimeState(current)
    local index = 1
    while index <= #queue do
        local item = queue[index]
        if item.expiresAt > 0 and current >= item.expiresAt then
            cancelLLM(item)
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
            and queued.lane == item.lane
            and queued.sceneID == item.sceneID
            and queued.threadID == item.threadID
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

local function sameActiveScene(item, current)
    if item.lane ~= Client.LANE_SCENE or item.sceneID == nil then return false end
    local entry = activeScenes[item.sceneID]
    return type(entry) == "table" and current < (tonumber(entry.untilMs) or 0)
end

local function sameActiveThread(item, current)
    if item.lane ~= Client.LANE_BEAT or item.threadID == nil then return false end
    local entry = activeThreads[item.threadID]
    return type(entry) == "table" and current < (tonumber(entry.untilMs) or 0)
end

local function ambientCadenceBlocks(item, current)
    return item.priority <= lastAmbientPriority
        and lastAmbientAt > 0
        and current < lastAmbientAt + item.ambientCadenceMs
end

local function resolveLaneAndIDs(spec, context)
    local rawLane = clean(spec.lane, nil)
    if rawLane then rawLane = string.lower(rawLane) end
    local ctx = type(spec.context) == "table" and spec.context or context
    local rawSceneID = clean(spec.sceneID or (ctx and ctx.sceneID) or nil, nil)
    local rawThreadID = clean(spec.threadID or (ctx and ctx.threadID) or nil, nil)
    if rawLane == Client.LANE_SCENE
        or (rawLane ~= Client.LANE_BEAT and rawSceneID ~= nil)
    then
        return Client.LANE_SCENE, rawSceneID or rawThreadID, nil
    end
    if rawLane == Client.LANE_BEAT or rawThreadID ~= nil then
        return Client.LANE_BEAT, nil, rawThreadID
    end
    return rawLane or Client.LANE_AMBIENT, nil, nil
end

local function normalize(spec)
    if type(spec) ~= "table" then return nil, "invalid_spec" end
    local eventID = clean(spec.eventID or spec.id, nil)
    local speakerID = clean(spec.speakerID or spec.npcID, nil)
    if not eventID or not speakerID then return nil, "identity_required" end
    local current = now()
    sequence = sequence + 1
    local basePriority = basePriorityFor(spec)
    local priority = priorityFor(spec, basePriority)
    local cooldowns = type(spec.cooldowns) == "table" and spec.cooldowns or {}
    local context = copyMap(spec.context)
    local voiceBinding = spec.voiceBinding or spec.voice_binding
    if type(voiceBinding) == "table" then
        context.voiceBinding = copyMap(voiceBinding)
    end
    context.npcType = context.npcType or spec.npcType
    context.socialRole = context.socialRole or spec.socialRole
    context.relationshipState = context.relationshipState
        or spec.relationshipState
    context.relationshipTier = context.relationshipTier
        or spec.relationshipTier
    local lane, sceneID, threadID = resolveLaneAndIDs(spec, context)
    local presentationState = copyMap(spec.presentationState)
    local source = copyMap(spec.source)
    local urgent = spec.urgent == true
        or (type(spec.context) == "table" and spec.context.urgent == true)
        or source.urgent == true
        or presentationState.urgent == true
    local explicitFloor = numeric(spec.sceneFloor
        or (type(spec.context) == "table" and spec.context.sceneFloor), nil)
    local sceneFloor = lane == Client.LANE_SCENE
        and math.max(priority, math.min(Client.CRITICAL_PRIORITY,
            explicitFloor or Client.SCENE_PRIORITY_FLOOR))
        or nil
    local item = {
        eventID = eventID,
        flavorID = clean(spec.flavorID, nil),
        family = clean(spec.family, "ambient"),
        lane = lane,
        sceneID = sceneID,
        threadID = threadID,
        speakerID = speakerID,
        speakerName = clean(spec.speakerName, speakerID),
        speakerKind = clean(spec.speakerKind, "npc"),
        playerUUID = clean(spec.playerUUID, nil),
        context = context,
        text = boundedText(spec.text),
        seed = spec.seed or eventID,
        basePriority = basePriority,
        priority = priority,
        urgent = urgent,
        sceneFloor = sceneFloor,
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
        holdMs = spec.holdMs ~= nil and numeric(spec.holdMs, nil) or nil,
        respectShortHold = spec.respectShortHold == true,
        interrupt = spec.interrupt == true
            or presentationState.interrupt == true,
        conversationID = clean(spec.conversationID, nil),
        ttlMs = numeric(spec.ttlMs, Client.DEFAULT_TTL_MS),
        threadTTLMs = spec.threadTTLMs ~= nil and numeric(spec.threadTTLMs, nil)
            or (spec.threadTtlMs ~= nil and numeric(spec.threadTtlMs, nil) or nil),
        sceneTTLMs = spec.sceneTTLMs ~= nil and numeric(spec.sceneTTLMs, nil)
            or (spec.sceneTtlMs ~= nil and numeric(spec.sceneTtlMs, nil) or nil),
        llmEligible = spec.llmEligible == true,
        memoryEligible = spec.memoryEligible == true,
        llmGraceMs = numeric(spec.llmGraceMs, Client.DEFAULT_LLM_GRACE_MS),
        presentationState = presentationState,
        source = source,
        createdAt = current,
        expiresAt = current + numeric(spec.ttlMs, Client.DEFAULT_TTL_MS),
        sequence = sequence,
        mergedCount = 1,
    }
    if item.text == "" and not item.flavorID then return nil, "content_required" end
    return item
end

local function suppressionReason(item, current)
    if item.priority >= Client.CRITICAL_PRIORITY or item.urgent == true then
        return nil
    end
    if item.lane == Client.LANE_SCENE then
        local inScene = sameActiveScene(item, current)
        if not inScene
            and cooldownActive(recentSceneFamily, item.family, current)
        then
            return "family_cooldown"
        end
        if cooldownActive(recentSceneSpeaker, item.speakerID, current) then
            return "speaker_cooldown"
        end
        return nil
    end
    local inThread = sameActiveThread(item, current)
    if not inThread
        and cooldownActive(recentFamily, item.family, current)
    then
        return "family_cooldown"
    end
    if cooldownActive(recentSpeaker, item.speakerID, current) then
        return "speaker_cooldown"
    end
    if not inThread and ambientCadenceBlocks(item, current) then
        return "ambient_cadence"
    end
    return nil
end

local function shouldAdmit(item, current)
    if delivered[item.eventID] then return false, "duplicate_delivered" end
    if byEventID[item.eventID] then return false, "duplicate_queued" end
    local merged = findMerge(item)
    if merged then return true, "merge", merged end
    local suppressed = suppressionReason(item, current)
    if suppressed then return false, suppressed end
    return true, "accepted"
end

local function discardSuppressed(current)
    local index = 1
    while index <= #queue do
        local item = queue[index]
        if suppressionReason(item, current) ~= nil then
            cancelLLM(item)
            removeAt(index)
            log("discarded", "event=" .. tostring(item.eventID)
                .. " reason=delivery_cooldown")
        else
            index = index + 1
        end
    end
end

local function isBridgeReady()
    local gw = PsychopatzCore and PsychopatzCore.VoiceGateway or nil
    if not gw or type(gw.IsBridgeReady) ~= "function" then return false end
    return gw.IsBridgeReady() == true
end

local function computeFloorHold(item, text, presentation)
    local textLen = #(tostring(text or ""))
    local estMs = math.min(
        Client.MAX_READABLE_HOLD_MS,
        math.max(Client.MIN_READABLE_HOLD_MS, 1600 + textLen * 26)
    )
    if item.respectShortHold and type(item.holdMs) == "number" then
        estMs = math.max(0, item.holdMs)
    elseif type(item.holdMs) == "number" and item.holdMs >= Client.MIN_READABLE_HOLD_MS then
        estMs = math.min(Client.TTS_MAX_TIMEOUT_MS, item.holdMs)
    end
    local usingTTS = presentation.tts ~= false and isBridgeReady()
    if usingTTS then
        return math.min(
            Client.TTS_MAX_TIMEOUT_MS,
            math.max(Client.TTS_MIN_TIMEOUT_MS, estMs + 2500)
        ), true
    end
    return estMs, false
end

local function onVoiceLifecycle(event)
    if type(event) ~= "table" or not activeEventID then return end
    local kind = tostring(event.event or "")
    local msgID = tostring(event.utterance_id or event.utteranceID or event.message_id or event.messageID or "")
    local convID = tostring(event.conversation_id or event.conversationID or "")
    local expectedConvID = tostring(activeConversationID or Client.AMBIENT_TTS_CONVERSATION_ID)
    local sameUtterance = (msgID ~= "" and msgID == activeMessageID)
        or (convID ~= "" and convID == expectedConvID
            and tostring(event.speaker_id or "") == tostring(activeSpeakerID or ""))
    if not sameUtterance then return end
    if kind == "speechFinished" or kind == "speechFailed" then
        local current = now()
        activeUntil = math.min(activeUntil, current + Client.TTS_FINISH_GAP_MS)
        activeEventID = nil
        activeMessageID = nil
        activeSpeakerID = nil
        activeConversationID = nil
    end
end

local function enforceSpeakerQueueCap(item)
    if item.interrupt then return end
    local count = 0
    local lowestSpeakerIdx = nil
    local lowestSpeakerItem = nil
    for i = 1, #queue do
        local q = queue[i]
        if q.speakerID == item.speakerID and not q.interrupt then
            count = count + 1
            if q.lane == item.lane and q.family == item.family
                and score(q) <= score(item)
            then
                removeAt(i)
                return
            end
            if not (q.lane == Client.LANE_SCENE
                and item.lane ~= Client.LANE_SCENE
                and not item.urgent)
                and (not lowestSpeakerItem or score(q) < score(lowestSpeakerItem))
            then
                lowestSpeakerItem = q
                lowestSpeakerIdx = i
            end
        end
    end
    if count >= Client.MAX_QUEUE_PER_SPEAKER and lowestSpeakerIdx then
        removeAt(lowestSpeakerIdx)
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
    enforceSpeakerQueueCap(item)
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
    local speaker = item.speakerKind or item.speaker or "npc"
    local result = Flavor.ResolveDetailed(
        item.flavorID, speaker, item.seed, item.context
    )
    return result and boundedText(result.text) or nil, false
end

local function publish(item, text, isLLM, current)
    text = boundedText(text)
    if text == "" then return false, "empty_text" end
    local presentation = copyMap(item.presentationState)
    if item.ttsManaged then
        -- The local provider may already be speaking streamed chunks. The
        -- final canonical message remains visible everywhere, but Core's
        -- generic voice gateway must not replay the complete response.
        presentation.tts = false
    end
    if presentation.nameplate == nil then presentation.nameplate = true end
    if item.lane == Client.LANE_BEAT then
        -- Transient beat threads must never persist into conversation history.
        presentation.conversationUI = false
    elseif presentation.conversationUI == nil then
        presentation.conversationUI = false
    end
    if presentation.interrupt == nil then
        presentation.interrupt = item.interrupt == true
            or item.urgent == true
            or item.priority >= Client.CRITICAL_PRIORITY
    end
    local source = copyMap(item.source)
    source.kind = source.kind or "social_flavor"
    source.family = item.family
    source.lane = item.lane
    source.eventID = item.eventID
    source.priority = item.priority
    source.weight = item.weight
    source.llm = isLLM == true
    if item.lane == Client.LANE_SCENE and item.sceneID ~= nil then
        source.sceneID = item.sceneID
        source.threadID = nil
    elseif item.lane == Client.LANE_BEAT and item.threadID ~= nil then
        source.threadID = item.threadID
        source.sceneID = nil
    end
    if item.urgent == true then source.urgent = true end
    -- Ambient chatter and transient beat threads are not durable LLM memory
    -- unless explicitly opted in on non-beat items.
    local memoryEligible = item.memoryEligible == true
        and item.lane ~= Client.LANE_BEAT
    source.contextEligible = memoryEligible
    source.excludeFromLLM = not memoryEligible
    local msgID = "social-flavor:" .. item.eventID
    local convID = item.conversationID or Client.AMBIENT_TTS_CONVERSATION_ID
    local message = Message.New({
        messageID = msgID,
        conversationID = convID,
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
    if item.lane == Client.LANE_SCENE then
        recentSceneFamily[item.family] = current + item.familyCooldownMs
        recentSceneSpeaker[item.speakerID] = current + item.speakerCooldownMs
    else
        recentFamily[item.family] = current + item.familyCooldownMs
        recentSpeaker[item.speakerID] = current + item.speakerCooldownMs
        lastAmbientAt = current
        lastAmbientPriority = item.priority
    end
    local holdDuration = computeFloorHold(item, text, presentation)
    activeUntil = current + holdDuration
    activePriority = item.priority
    activeLane = item.lane
    activeFloorPriority = effectiveScorePriority(item)
    activeEventID = item.eventID
    activeMessageID = msgID
    activeSpeakerID = item.speakerID
    activeConversationID = convID
    if item.lane == Client.LANE_SCENE and item.sceneID ~= nil then
        laneSequence = laneSequence + 1
        local sceneTTL = item.sceneTTLMs or math.max(item.ttlMs or 9000, 12000)
        activeSceneID = item.sceneID
        activeScenes[item.sceneID] = {
            untilMs = current + math.max(0, sceneTTL),
            floor = item.sceneFloor or Client.SCENE_PRIORITY_FLOOR,
            lastAt = current,
            seq = laneSequence,
        }
        pruneLaneMap(activeScenes, current, Client.MAX_ACTIVE_SCENES)
    else
        activeSceneID = nil
    end
    if item.lane == Client.LANE_BEAT and item.threadID ~= nil then
        laneSequence = laneSequence + 1
        local threadTTL = item.threadTTLMs or math.max(item.ttlMs or 9000, 12000)
        activeThreadID = item.threadID
        activeThreads[item.threadID] = {
            untilMs = current + math.max(0, threadTTL),
            lastAt = current,
            seq = laneSequence,
        }
        pruneLaneMap(activeThreads, current, Client.MAX_ACTIVE_THREADS)
    else
        activeThreadID = nil
    end
    EventBus.emit(Client.EVENT_DELIVERED, {
        item = item,
        message = message,
        text = text,
        llm = isLLM == true,
    })
    log("delivered", "event=" .. item.eventID .. " priority="
        .. tostring(item.priority) .. " lane=" .. tostring(item.lane)
        .. " llm=" .. tostring(isLLM == true) .. " text=" .. text)
    return true, "delivered"
end

local function isUrgentOverScene(item, floor)
    local highAuthority = item.urgent == true
        or item.basePriority >= floor
        or item.priority >= Client.CRITICAL_PRIORITY
    local wantsPreempt = item.interrupt == true
        or item.urgent == true
        or item.priority >= Client.CRITICAL_PRIORITY
    return highAuthority and wantsPreempt
end

local function canPreemptActiveFloor(item, current)
    if current >= activeUntil then return true end
    if activeLane == Client.LANE_SCENE then
        if item.lane == Client.LANE_SCENE then
            return item.interrupt == true and (
                item.sceneID == activeSceneID
                or item.basePriority >= activeFloorPriority
                or item.priority >= Client.CRITICAL_PRIORITY
            )
        end
        return isUrgentOverScene(item, activeFloorPriority)
    end
    return item.interrupt == true
        or item.urgent == true
        or item.priority >= Client.CRITICAL_PRIORITY
        or (type(item.presentationState) == "table"
            and item.presentationState.interrupt == true)
end

local function choose(current)
    local selected
    local selectedIndex
    for index, item in ipairs(queue) do
        if canPreemptActiveFloor(item, current) then
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
    local function complete(text, options)
        Client.ReceiveLLMResult(item.eventID, text, options)
    end
    local accepted = llmProvider(item, complete)
    if accepted ~= true then
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

function Client.ReceiveLLMResult(eventID, text, options)
    eventID = clean(eventID, "")
    local item = byEventID[eventID]
    if not item or delivered[eventID] then
        log("llm_late_result", "event=" .. eventID)
        return false, "event_unavailable"
    end
    text = boundedText(text)
    if text == "" then return false, "empty_text" end
    item.llmText = text
    item.ttsManaged = type(options) == "table"
        and options.ttsManaged == true
        or false
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
        if item.llmRequested and not item.llmReady then
            cancelLLM(item)
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
            lane = item.lane,
            sceneID = item.sceneID,
            threadID = item.threadID,
            speakerID = item.speakerID,
            priority = item.priority,
            urgent = item.urgent == true,
            weight = item.weight,
            mergedCount = item.mergedCount,
            llmRequested = item.llmRequested == true,
            llmReady = item.llmReady == true,
            ttsManaged = item.ttsManaged == true,
        }
    end
    return output
end

function Client.GetLaneSnapshot(current)
    current = tonumber(current) or now()
    pruneRuntimeState(current)
    local scenes = {}
    local sceneCount = 0
    for id, entry in pairs(activeScenes) do
        sceneCount = sceneCount + 1
        scenes[id] = {
            untilMs = entry.untilMs,
            floor = entry.floor,
        }
    end
    local threads = {}
    local threadCount = 0
    for id, entry in pairs(activeThreads) do
        threadCount = threadCount + 1
        threads[id] = {
            untilMs = entry.untilMs,
        }
    end
    return {
        activeLane = activeLane,
        activeSceneID = activeSceneID,
        activeThreadID = activeThreadID,
        activeUntil = activeUntil,
        activeFloorPriority = activeFloorPriority,
        activeSceneCount = sceneCount,
        activeThreadCount = threadCount,
        activeScenes = scenes,
        activeThreads = threads,
    }
end

function Client.SetDebug(enabled)
    debugEnabled = enabled == true
    return debugEnabled
end

function Client.Reset()
    for _, item in ipairs(queue) do
        cancelLLM(item)
    end
    queue = {}
    byEventID = {}
    delivered = {}
    deliveredOrder = {}
    recentFamily = {}
    recentSpeaker = {}
    recentSceneFamily = {}
    recentSceneSpeaker = {}
    activeScenes = {}
    activeThreads = {}
    sequence = 0
    laneSequence = 0
    activeUntil = 0
    activePriority = 0
    activeFloorPriority = 0
    activeLane = nil
    activeSceneID = nil
    activeEventID = nil
    activeMessageID = nil
    activeSpeakerID = nil
    activeConversationID = nil
    lastAmbientAt = 0
    lastAmbientPriority = 0
    activeThreadID = nil
    return true
end

EventBus.clearOwner(OWNER_TOKEN)
local gw = PsychopatzCore and PsychopatzCore.VoiceGateway or nil
local lifecycleEvent = (gw and gw.LIFECYCLE_EVENT_TYPE) or Client.VOICE_LIFECYCLE_EVENT
EventBus.subscribe(lifecycleEvent, onVoiceLifecycle, OWNER_TOKEN)
if Events and Events.OnTick and not Client.TickRegistered then
    Events.OnTick.Add(function() Client.Pump() end)
    Client.TickRegistered = true
end

return Client
