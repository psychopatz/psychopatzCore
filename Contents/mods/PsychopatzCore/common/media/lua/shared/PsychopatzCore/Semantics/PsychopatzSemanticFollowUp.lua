-- Lightweight multi-turn elliptical follow-up resolver.
-- Resolves short context-dependent utterances ("where?", "why?", "who?",
-- "tell me more", "yeah", "never mind") against bounded conversation context.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local FollowUp = Semantics.FollowUp or {}
Semantics.FollowUp = FollowUp

FollowUp.VERSION = 1

local ACT_TO_INTENT = {
    ASK_WHERE = { intent = "QUESTION", speechAct = "QUESTION", action = "LOCATE" },
    ASK_WHY = { intent = "QUESTION", speechAct = "QUESTION", action = "EXPLAIN" },
    ASK_WHO = { intent = "QUESTION", speechAct = "QUESTION", action = "IDENTIFY" },
    ASK_ELABORATE = { intent = "QUESTION", speechAct = "QUESTION", action = "ELABORATE" },
    CONFIRM = { intent = "AGREE", speechAct = "CONFIRM", action = "CONFIRM" },
    DENY = { intent = "REFUSE", speechAct = "DENY", action = "CANCEL" },
    THANK = { intent = "THANK", speechAct = "THANK", action = "THANK" },
    APOLOGIZE = { intent = "APOLOGIZE", speechAct = "APOLOGIZE", action = "APOLOGIZE" },
    CHALLENGE = { intent = "DISAGREE", speechAct = "CHALLENGE", action = "CHALLENGE" },
}

local function lastMentionOfRole(contextState, wantedRole)
    local mentions = type(contextState) == "table" and contextState.mentions or nil
    if type(mentions) ~= "table" then return nil end
    for i = #mentions, 1, -1 do
        local m = mentions[i]
        if type(m) == "table" and (wantedRole == nil or m.role == wantedRole or m.kind == wantedRole) then
            return m
        end
    end
    return nil
end

function FollowUp.Resolve(normalized, contextState)
    if type(normalized) ~= "table" or not normalized.dialogueAct then return nil end
    local mapping = ACT_TO_INTENT[normalized.dialogueAct]
    if not mapping then return nil end

    contextState = type(contextState) == "table" and contextState or {}
    local topic = contextState.currentTopic or contextState.previousTopic
    local target = {}
    local subject = topic and string.upper(tostring(topic)) or "CONVERSATION_TOPIC"

    if normalized.dialogueAct == "ASK_WHERE" then
        local loc = lastMentionOfRole(contextState, "location") or lastMentionOfRole(contextState, "item")
        if loc then
            target = { key = loc.key, id = loc.entityID, name = loc.label or loc.key, kind = loc.kind }
        elseif not topic then
            return nil
        end
        subject = "LOCATION"
    elseif normalized.dialogueAct == "ASK_WHO" then
        local person = lastMentionOfRole(contextState, "person") or lastMentionOfRole(contextState, "npc")
        if person then
            target = { key = person.key, id = person.entityID, name = person.label or person.key, kind = "person" }
            subject = "IDENTITY"
        elseif topic then
            subject = "IDENTITY"
        else
            return nil
        end
    elseif normalized.dialogueAct == "ASK_WHY" or normalized.dialogueAct == "ASK_ELABORATE" then
        if not topic and not contextState.lastAction then return nil end
    end

    return {
        schemaVersion = 1,
        kind = "utterance",
        intent = mapping.intent,
        speechAct = mapping.speechAct,
        action = mapping.action,
        subject = subject,
        target = target,
        slots = {
            dialogueAct = normalized.dialogueAct,
            followUpTopic = topic,
        },
        socialContext = {
            playerTone = normalized.playerTone or "neutral",
            playerRude = normalized.playerRude == true,
            playerShouting = normalized.playerShouting == true,
            playerPolite = normalized.playerPolite == true,
        },
        confidence = 0.82,
        diagnostics = {
            ellipticalFollowUp = true,
            dialogueAct = normalized.dialogueAct,
            resolvedTopic = topic,
        },
        rawText = normalized.rawText,
        normalizedText = normalized.normalizedText,
    }
end

return FollowUp
