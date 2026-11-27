-- Lightweight multi-turn elliptical follow-up resolver.
-- Resolves short context-dependent utterances ("where?", "why?", "who?",
-- "tell me more", "yeah", "never mind") against bounded conversation context.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
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
    RECIPROCATE = { intent = "GREET", speechAct = "GREET", action = nil },
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

local BARE_IDENTITY_STOPWORDS = {
    what = true, who = true, where = true, why = true, when = true, how = true,
    which = true, yes = true, yeah = true, yep = true, no = true, nope = true,
    nah = true, okay = true, ok = true, maybe = true, never = true, nothing = true,
    nobody = true, none = true, whatever = true, wait = true, stop = true,
    help = true, hello = true, hi = true, hey = true, bye = true, thanks = true,
    sorry = true, please = true, ["not"] = true, dont = true, ["don't"] = true,
    cant = true, ["can't"] = true, idk = true, nvm = true,
}

local function pendingIdentityFor(contextState)
    if type(contextState) ~= "table" then return nil end
    local pending = contextState.pendingIdentityExchange
        or (type(contextState.semanticContextState) == "table"
            and contextState.semanticContextState.pendingIdentityExchange)
        or (type(contextState.semanticDialogueContext) == "table"
            and contextState.semanticDialogueContext.pendingIdentityExchange)
        or nil
    if type(pending) == "table" then return pending end
    local pq = contextState.pendingQuestion
    if type(pq) == "table" and tostring(pq.subject or "") == "IDENTITY" then
        return pq
    end
    return nil
end

local function resolveBareIdentityAnswer(normalized, contextState)
    if not pendingIdentityFor(contextState) then return nil end
    if normalized.isQuestion == true or normalized.playerRude == true then
        return nil
    end
    local tokens = type(normalized.tokens) == "table" and normalized.tokens or {}
    if #tokens < 1 or #tokens > 3 then return nil end
    for i = 1, #tokens do
        local tok = tostring(tokens[i] or "")
        if #tok < 2 or #tok > 20
            or not string.match(tok, "^[%a][%a'%-]*$")
            or BARE_IDENTITY_STOPWORDS[string.lower(tok)] == true
        then
            return nil
        end
    end
    local claimed = tostring(normalized.rawText or normalized.normalizedText or "")
    claimed = (claimed:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[!%.]+$", ""))
    if claimed == "" then return nil end
    return IR.New({
        intent = "INFORM",
        speechAct = "INFORM",
        subject = "IDENTITY",
        slots = {
            identityClaim = {
                name = claimed,
                mode = "spoken",
                bareAnswer = true,
            },
            dialogueAct = "IDENTITY_BARE_ANSWER",
            followUpTopic = "identity",
        },
        socialContext = {
            selfDirected = true,
            target = "SELF",
            identityClaim = true,
            playerTone = normalized.playerTone or "neutral",
            playerRude = normalized.playerRude == true,
            playerShouting = normalized.playerShouting == true,
            playerPolite = normalized.playerPolite == true,
        },
        confidence = 0.90,
        diagnostics = {
            ellipticalFollowUp = true,
            dialogueAct = "IDENTITY_BARE_ANSWER",
            resolvedTopic = "identity",
        },
        provenance = {
            provider = "lua",
            parser = "followup",
            pattern = "core.followup.identity_bare_answer",
        },
        rawText = normalized.rawText,
        normalizedText = normalized.normalizedText,
    })
end

function FollowUp.Resolve(normalized, contextState)
    if type(normalized) ~= "table" then return nil end
    contextState = type(contextState) == "table" and contextState or {}
    if not normalized.dialogueAct then
        return resolveBareIdentityAnswer(normalized, contextState)
    end
    local mapping = ACT_TO_INTENT[normalized.dialogueAct]
    if not mapping then
        return resolveBareIdentityAnswer(normalized, contextState)
    end
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
    elseif normalized.dialogueAct == "RECIPROCATE" then
        local lastBranch = tostring(contextState.lastBranch or "")
        local topicLower = string.lower(tostring(topic or ""))
        if lastBranch == "FAREWELL_ACKNOWLEDGED" or topicLower == "farewell" then
            mapping = { intent = "FAREWELL", speechAct = "FAREWELL", action = nil }
            subject = "FAREWELL"
        elseif lastBranch == "COMPLIMENT_RECEIVED" then
            mapping = { intent = "THANK", speechAct = "THANK", action = nil }
        else
            mapping = { intent = "GREET", speechAct = "GREET", action = nil }
        end
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
