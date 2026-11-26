local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.layerRoot("common_shared")
local CLIENT = T.layerRoot("common_client")
package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then
        error((label or "truthy") .. ": expected truthy", 2)
    end
end

local function falsy(value, label)
    if value then
        error((label or "falsy") .. ": expected falsy, got=" .. tostring(value), 2)
    end
end

local now = 10000
local tickHandlers = {}
getTimeInMillis = function() return now end
getTimestampMs = function() return now end
getCurrentSaveName = function() return "social-flavor-lanes-test" end
getText = function(key) return key end
Events = {
    OnTick = {
        Add = function(callback)
            tickHandlers[#tickHandlers + 1] = callback
        end,
    },
}

local bridgeReady = false
PsychopatzCore = {
    Conversation = {},
    VoiceGateway = {
        LIFECYCLE_EVENT_TYPE = "PsychopatzCore.Voice.Lifecycle",
        IsBridgeReady = function() return bridgeReady end,
    },
}

local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local Client = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"

local published = {}
EventBus.subscribe(Message.EVENT_TYPE, function(message)
    published[#published + 1] = message
end, "social-flavor-lanes-smoke")

-- 1. SceneID and ThreadID do not collide (same string ID, speaker, and family).
Client.Reset()
local okBeat, reasonBeat = Client.Enqueue({
    eventID = "beat:collision:1",
    lane = "beat",
    threadID = "shared-id-1",
    speakerID = "npc-alpha",
    family = "shared_fam",
    priority = 62,
    text = "Looks like trouble over there.",
    memoryEligible = true,
    presentationState = { conversationUI = true },
    cooldowns = { familyMs = 8000, speakerMs = 8000, ambientMs = 8000, mergeWindowMs = 0 },
})
truthy(okBeat, "beat enqueued: " .. tostring(reasonBeat))
local pumpedBeat = Client.Pump(now)
truthy(pumpedBeat, "beat pumped")
equal(#published, 1, "beat published")
equal(published[1].source.lane, "beat", "beat source lane")
equal(published[1].source.threadID, "shared-id-1", "beat source threadID")
equal(published[1].source.sceneID, nil, "beat source has no sceneID")
equal(published[1].presentationState.conversationUI, false,
    "transient beat never enters conversation UI history")
equal(published[1].source.contextEligible, false,
    "transient beat never marks contextEligible")
equal(published[1].source.excludeFromLLM, true,
    "transient beat excludes from LLM memory")

now = now + 2600
local okScene, reasonScene = Client.Enqueue({
    eventID = "scene:collision:1",
    threadID = "shared-id-1",
    context = { sceneID = "shared-id-1" },
    speakerID = "npc-alpha",
    family = "shared_fam",
    priority = 55,
    text = "We need to talk about supplies.",
    presentationState = { conversationUI = true },
    cooldowns = { familyMs = 2000, speakerMs = 1500, ambientMs = 800, mergeWindowMs = 0 },
})
truthy(okScene, "scene with matching string ID is not blocked by beat cooldowns: " .. tostring(reasonScene))
local pumpedScene = Client.Pump(now)
truthy(pumpedScene, "scene pumped cleanly")
equal(#published, 2, "scene published")
equal(published[2].source.lane, "scene", "context.sceneID routes to scene lane")
equal(published[2].source.sceneID, "shared-id-1", "scene source sceneID preserved")
equal(published[2].source.threadID, nil, "scene source has no threadID")
equal(published[2].presentationState.conversationUI, true,
    "scene preserves conversationUI presentation")

local lanesAfterCollision = Client.GetLaneSnapshot(now)
truthy(lanesAfterCollision.activeScenes["shared-id-1"] ~= nil,
    "activeScenes tracks shared-id-1 independently")
truthy(lanesAfterCollision.activeThreads["shared-id-1"] ~= nil,
    "activeThreads retains shared-id-1 without overwriting or colliding with scene")

-- 2. Priority floor protects active interactive Scene turn from transient barks,
--    while urgent alerts can still preempt.
Client.Reset()
published = {}
now = 50000
truthy(Client.Enqueue({
    eventID = "scene:floor:1",
    sceneID = "scene-floor",
    speakerID = "npc-1",
    family = "semantic_scene",
    priority = 55,
    holdMs = 2400,
    text = "Listen closely, here is the plan.",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue scene turn 1")
truthy(Client.Pump(now), "deliver scene turn 1")
equal(#published, 1, "scene turn 1 published")

now = now + 400
truthy(Client.Enqueue({
    eventID = "beat:preempt:attempt",
    threadID = "beat-99",
    speakerID = "npc-2",
    family = "combat_ally_warn",
    priority = 68,
    interrupt = true,
    text = "Movement by the fence!",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue transient beat bark")
truthy(Client.Enqueue({
    eventID = "farewell:preempt:attempt",
    speakerID = "npc-3",
    family = "conversation_farewell",
    priority = 72,
    interrupt = true,
    text = "Catch you later.",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue farewell bark")
truthy(Client.Enqueue({
    eventID = "ambient:llm:attempt",
    speakerID = "npc-4",
    family = "ambient_chatter",
    llmEligible = true,
    text = "Quiet night.",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue low-authority llmEligible ambient chatter")
falsy(Client.Pump(now), "lower-authority barks cannot preempt active scene turn")
equal(#published, 1, "active scene turn remains uninterrupted")

-- Enqueue second scene turn (priority 55) while priority-68 beat is waiting;
-- once floor expires, scene turn must outrank the beat bark via SCENE_PRIORITY_FLOOR.
truthy(Client.Enqueue({
    eventID = "scene:floor:2",
    sceneID = "scene-floor",
    speakerID = "npc-1",
    family = "semantic_scene",
    priority = 55,
    holdMs = 2400,
    text = "First we check the perimeter.",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue scene turn 2")
now = now + 2600
truthy(Client.Pump(now), "pump after scene turn 1 floor expires")
equal(#published, 2, "second publication occurs")
equal(published[2].source.eventID, "scene:floor:2",
    "queued scene turn outranks queued priority-68 beat and priority-72 farewell")

-- Urgent alert (urgent=true or priority >= sceneFloor with interrupt) preempts active scene.
now = now + 200
truthy(Client.Enqueue({
    eventID = "urgent:medical:1",
    threadID = "urgent-med",
    speakerID = "npc-2",
    family = "medical_emergency",
    priority = 85,
    urgent = true,
    interrupt = true,
    text = "I am bleeding out, need a bandage now!",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue urgent medical alert")
truthy(Client.Pump(now), "urgent alert preempts active scene turn")
equal(#published, 3, "urgent alert published immediately")
equal(published[3].source.eventID, "urgent:medical:1", "urgent alert took floor")

-- 3. Bounded expiry and cleanup of transient threadID state.
Client.Reset()
published = {}
now = 100000
local totalThreads = Client.MAX_ACTIVE_THREADS + 8
for idx = 1, totalThreads do
    now = now + 3000
    local tid = "transient-thread-" .. tostring(idx)
    truthy(Client.Enqueue({
        eventID = "ev:" .. tid,
        lane = "beat",
        threadID = tid,
        speakerID = "npc-" .. tostring(idx),
        family = "world_beat",
        priority = 40,
        ttlMs = 3000,
        threadTTLMs = 5000,
        text = "Thread line " .. tostring(idx),
        cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
    }), "enqueue transient thread " .. tostring(idx))
    truthy(Client.Pump(now), "pump transient thread " .. tostring(idx))
end
local boundedSnapshot = Client.GetLaneSnapshot(now)
truthy(boundedSnapshot.activeThreadCount <= Client.MAX_ACTIVE_THREADS,
    "transient thread map stays bounded at MAX_ACTIVE_THREADS")
now = now + 6000
local expiredSnapshot = Client.GetLaneSnapshot(now)
equal(expiredSnapshot.activeThreadCount, 0,
    "all transient threadID entries expire cleanly after TTL")
equal(expiredSnapshot.activeThreadID, nil,
    "activeThreadID clears on expiry")

-- 4. Single queue + TTS lifecycle continuity preserved.
Client.Reset()
published = {}
bridgeReady = true
now = 200000
equal(#tickHandlers, 1, "single client OnTick handler registered")
truthy(Client.Enqueue({
    eventID = "tts:scene:1",
    sceneID = "tts-scene",
    conversationID = "scene:tts-scene",
    speakerID = "npc-tts",
    family = "semantic_scene",
    priority = 55,
    text = "Stay close while we sweep the hallway.",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue TTS scene turn")
truthy(Client.Enqueue({
    eventID = "tts:scene:2",
    sceneID = "tts-scene",
    conversationID = "scene:tts-scene",
    speakerID = "npc-tts-2",
    family = "semantic_scene",
    priority = 55,
    text = "Right behind you.",
    cooldowns = { familyMs = 0, speakerMs = 0, ambientMs = 0, mergeWindowMs = 0 },
}), "enqueue second TTS scene turn into same single queue")
equal(#Client.GetQueueSnapshot(), 2, "single queue holds both scene turns")
truthy(Client.Pump(now), "publish first TTS scene turn")
equal(#published, 1, "first TTS scene turn published")
equal(published[1].conversationID, "scene:tts-scene",
    "custom scene conversationID preserved for TTS")

now = now + 2600
falsy(Client.Pump(now), "TTS floor extends beyond readable hold until speechFinished")
EventBus.emit("PsychopatzCore.Voice.Lifecycle", {
    event = "speechFinished",
    utterance_id = published[1].messageID,
    conversation_id = "scene:tts-scene",
    speaker_id = "npc-tts",
})
falsy(Client.Pump(now), "TTS_FINISH_GAP_MS gap respected right after speechFinished")
now = now + Client.TTS_FINISH_GAP_MS
truthy(Client.Pump(now), "second scene turn publishes once TTS finish gap elapses")
equal(#published, 2, "second TTS turn delivered sequentially via single queue")

print("psychopatz_social_flavor_lanes_smoke: ok")
