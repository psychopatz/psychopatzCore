local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Social = {}

Social.SCHEMA_VERSION = 1
Social.MAX_MEMORIES = 64
Social.MAX_RECENT_EVENTS = 128
Social.MIN_APPROVAL = -100
Social.MAX_APPROVAL = 100
Social.MIN_RESPECT = -100
Social.MAX_RESPECT = 100
Social.MIN_FAMILIARITY = 0
Social.MAX_FAMILIARITY = 100

local function bounded(value, low, high)
    value = tonumber(value) or 0
    return math.max(low, math.min(high, value))
end

local function targetKey(value)
    value = type(value) == "string" and value or ""
    if value == "" or string.match(value, "^%s+$") then return nil end
    local prefix = string.match(value, "^([%w_]+):")
    if prefix ~= "npc" and prefix ~= "actor" and prefix ~= "player"
        and prefix ~= "steam"
    then return nil end
    return value
end

local function hasRecentEvent(state, eventID)
    for index = 1, #(state.recentEventIDs or {}) do
        if state.recentEventIDs[index] == eventID then return true end
    end
    return false
end

local function copyMemory(memory, target)
    if type(memory) ~= "table" then return nil, "memory_invalid" end
    local id = memory.id or memory.eventID
    if type(id) ~= "string" or id == "" then return nil, "memory_id_required" end
    local output = Util.clone(memory)
    output.id = id
    output.aboutKey = target
    return output
end

local function normalizeRelationship(target, value)
    value = type(value) == "table" and value or {}
    local output = {
        targetKey = target,
        approval = bounded(value.approval, Social.MIN_APPROVAL, Social.MAX_APPROVAL),
        respect = bounded(value.respect, Social.MIN_RESPECT, Social.MAX_RESPECT),
        familiarity = bounded(value.familiarity, Social.MIN_FAMILIARITY,
            Social.MAX_FAMILIARITY),
        revision = math.max(0, math.floor(tonumber(value.revision) or 0)),
        lastEventAt = value.lastEventAt,
        memories = {},
    }
    for index = 1, math.min(#(value.memories or {}), Social.MAX_MEMORIES) do
        local memory, reason = copyMemory(value.memories[index], target)
        if not memory then return nil, reason end
        output.memories[#output.memories + 1] = memory
    end
    return output
end

function Social.NormalizeTargetKey(value)
    return targetKey(value)
end

function Social.NewState(source)
    local input = type(source) == "table" and source or {}
    local relationships = input.relationships or input.entries or {}
    local output = {
        schemaVersion = Social.SCHEMA_VERSION,
        revision = math.max(0, math.floor(tonumber(input.revision) or 0)),
        personality = Util.clone(input.personality or {}),
        personalityOverrides = Util.clone(input.personalityOverrides or {}),
        recentEventIDs = {},
        relationships = {},
    }
    for index = 1, math.min(#(input.recentEventIDs or {}), Social.MAX_RECENT_EVENTS) do
        output.recentEventIDs[index] = input.recentEventIDs[index]
    end
    for key, value in pairs(relationships) do
        local normalizedKey = targetKey(key)
        if not normalizedKey then return nil, "relationship_target_invalid" end
        local relationship, reason = normalizeRelationship(normalizedKey, value)
        if not relationship then return nil, reason end
        output.relationships[normalizedKey] = relationship
    end
    return output
end

function Social.Validate(state)
    if type(state) ~= "table"
        or tonumber(state.schemaVersion) ~= Social.SCHEMA_VERSION
        or type(state.relationships) ~= "table"
    then return false, "social_schema_mismatch" end
    if type(state.personality) ~= "table"
        or type(state.personalityOverrides) ~= "table"
        or type(state.recentEventIDs) ~= "table"
    then return false, "social_shape_invalid" end
    for key, relationship in pairs(state.relationships) do
        if targetKey(key) ~= key or type(relationship) ~= "table" then
            return false, "relationship_target_invalid"
        end
        if bounded(relationship.approval, Social.MIN_APPROVAL,
            Social.MAX_APPROVAL) ~= relationship.approval
            or bounded(relationship.respect, Social.MIN_RESPECT,
                Social.MAX_RESPECT) ~= relationship.respect
            or bounded(relationship.familiarity, Social.MIN_FAMILIARITY,
                Social.MAX_FAMILIARITY) ~= relationship.familiarity
        then return false, "relationship_score_invalid" end
        local memoryIDs = {}
        for index = 1, #(relationship.memories or {}) do
            local memory = relationship.memories[index]
            if type(memory) ~= "table" or type(memory.id) ~= "string"
                or memory.id == "" or memoryIDs[memory.id]
            then return false, "relationship_memory_invalid" end
            memoryIDs[memory.id] = true
        end
    end
    return true
end

function Social.Get(state, target)
    local normalized = targetKey(target)
    if not normalized then return nil, "target_key_invalid" end
    local relationship = state and state.relationships
        and state.relationships[normalized]
    if not relationship then return nil, "relationship_not_found" end
    return Util.clone(relationship)
end

function Social.GetOrCreate(state, target)
    local normalized = targetKey(target)
    if not normalized then return nil, "target_key_invalid" end
    state.relationships = state.relationships or {}
    if not state.relationships[normalized] then
        state.relationships[normalized] = {
            targetKey = normalized, approval = 0, respect = 0,
            familiarity = 0, revision = 0, memories = {},
        }
    end
    return state.relationships[normalized]
end

function Social.SetPersonality(state, personality, authority, expectedRevision)
    if authority ~= "server" then return nil, "server_authority_required" end
    if type(personality) ~= "table" then return nil, "personality_required" end
    if expectedRevision ~= nil
        and tonumber(expectedRevision) ~= tonumber(state.revision)
    then return nil, "revision_conflict" end
    state.personality = Util.clone(personality)
    state.revision = (tonumber(state.revision) or 0) + 1
    return Util.clone(state)
end

function Social.RecordAuthorizedEvent(state, event)
    if type(state) ~= "table" or type(event) ~= "table" then
        return nil, "event_required"
    end
    if event.authorized ~= true or event.authority ~= "server" then
        return nil, "server_authority_required"
    end
    local normalized = targetKey(event.targetKey)
    local eventID = event.eventID
    if not normalized then return nil, "target_key_invalid" end
    if type(eventID) ~= "string" or eventID == "" then
        return nil, "event_id_required"
    end
    if hasRecentEvent(state, eventID) then return nil, "duplicate_event" end
    local relationship, reason = Social.GetOrCreate(state, normalized)
    if not relationship then return nil, reason end
    relationship.approval = bounded(relationship.approval
        + (tonumber(event.approvalDelta) or 0), Social.MIN_APPROVAL,
        Social.MAX_APPROVAL)
    relationship.respect = bounded(relationship.respect
        + (tonumber(event.respectDelta) or 0), Social.MIN_RESPECT,
        Social.MAX_RESPECT)
    relationship.familiarity = bounded(relationship.familiarity
        + (tonumber(event.familiarityDelta) or 0), Social.MIN_FAMILIARITY,
        Social.MAX_FAMILIARITY)
    relationship.revision = relationship.revision + 1
    relationship.lastEventAt = event.createdAt or event.eventTime
    local memory = {
        id = eventID,
        type = event.type or "event",
        aboutKey = normalized,
        createdAt = event.createdAt or event.eventTime,
        approvalEffect = tonumber(event.approvalDelta) or 0,
        respectEffect = tonumber(event.respectDelta) or 0,
        familiarityEffect = tonumber(event.familiarityDelta) or 0,
        tags = Util.clone(event.tags or {}),
    }
    relationship.memories[#relationship.memories + 1] = memory
    while #relationship.memories > Social.MAX_MEMORIES do
        table.remove(relationship.memories, 1)
    end
    state.recentEventIDs[#state.recentEventIDs + 1] = eventID
    while #state.recentEventIDs > Social.MAX_RECENT_EVENTS do
        table.remove(state.recentEventIDs, 1)
    end
    state.revision = (tonumber(state.revision) or 0) + 1
    return Util.clone(state)
end

function Social.ToPayload(state)
    local normalized, reason = Social.NewState(state)
    if not normalized then return nil, reason end
    local valid
    valid, reason = Social.Validate(normalized)
    if not valid then return nil, reason end
    return normalized
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Social = Social
return Social
