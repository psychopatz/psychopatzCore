local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Knowledge = {}

Knowledge.SCHEMA_VERSION = 1
Knowledge.MAX_PLAYERS = 32
Knowledge.MAX_FACTS_PER_PLAYER = 128
Knowledge.MAX_EVIDENCE_PER_PLAYER = 64
Knowledge.MAX_EVIDENCE_PER_FACT = 16
Knowledge.MAX_ID_LENGTH = 128
Knowledge.MAX_TEXT_LENGTH = 256
Knowledge.MAX_PAYLOAD_KEYS = 8

local STATUS_RANK = { suspected = 1, known = 2, confirmed = 3 }
local SOURCE_PATTERN = "^[%w_%.:%-]+$"

local function text(value, limit)
    value = Util.text(value, nil)
    if not value or #value > (limit or Knowledge.MAX_TEXT_LENGTH)
        or string.match(value, "[%c]")
    then return nil end
    return value
end

local function identifier(value)
    value = text(value, Knowledge.MAX_ID_LENGTH)
    if not value or not string.match(value, SOURCE_PATTERN) then return nil end
    return value
end

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return value
end

local function bounded(value, low, high, fallback)
    value = number(value, fallback)
    return math.max(low, math.min(high, value))
end

local function normalizePlayerKey(value)
    value = text(value, Knowledge.MAX_ID_LENGTH)
    if not value then return nil end
    if string.match(value, "^player:") then
        if not string.match(value, "^player:[%w_%.:%-]+$") then return nil end
        return value
    end
    if string.match(value, "^character:") then
        value = string.sub(value, 11)
    end
    if not string.match(value, "^[%w_%.:%-]+$") then return nil end
    return "player:" .. value
end

local function sanitizeValue(value, depth)
    depth = depth or 0
    if type(value) == "string" then
        local normalized = text(value, Knowledge.MAX_TEXT_LENGTH)
        if not normalized then return nil, "fact_value_invalid" end
        return normalized
    end
    if type(value) == "boolean" then return value end
    if type(value) == "number" then
        value = number(value, nil)
        if value == nil then return nil, "fact_value_invalid" end
        return value
    end
    if type(value) ~= "table" or depth >= 1 then
        return nil, "fact_value_invalid"
    end
    local output = {}
    local count = 0
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            return nil, "fact_value_invalid"
        end
        count = count + 1
        if count > Knowledge.MAX_PAYLOAD_KEYS then
            return nil, "fact_value_limit"
        end
        local normalized, reason = sanitizeValue(child, depth + 1)
        if normalized == nil and child ~= nil then return nil, reason end
        output[key] = normalized
    end
    return output
end

local function normalizeEvidence(value)
    if type(value) ~= "table" then return nil, "evidence_required" end
    local id = identifier(value.id or value.evidenceID)
    local sourceType = identifier(value.sourceType or value.source or "conversation")
    if not id then return nil, "evidence_id_required" end
    if not sourceType then return nil, "evidence_source_invalid" end
    local payload = value.payload
    if payload ~= nil then
        local normalized, reason = sanitizeValue(payload)
        if normalized == nil then return nil, reason end
        payload = normalized
    end
    local sourceEventID = value.sourceEventID
    if sourceEventID ~= nil then
        sourceEventID = identifier(sourceEventID)
        if not sourceEventID then return nil, "evidence_event_invalid" end
    end
    local sourceEntityKey = value.sourceEntityKey
    if sourceEntityKey ~= nil then
        sourceEntityKey = identifier(sourceEntityKey)
        if not sourceEntityKey then return nil, "evidence_entity_invalid" end
    end
    local direction = value.direction
    if direction ~= nil then
        if type(direction) == "number" then
            direction = math.max(-1, math.min(1, math.floor(direction)))
        else
            direction = identifier(direction)
            if not direction then return nil, "evidence_direction_invalid" end
        end
    end
    local tags = value.tags
    if tags ~= nil then
        local normalizedTags, tagsReason = sanitizeValue(tags)
        if normalizedTags == nil then return nil, tagsReason end
        tags = normalizedTags
    end
    return {
        id = id,
        sourceType = sourceType,
        direction = direction,
        strength = bounded(value.strength, 0, 1, 1),
        reliability = bounded(value.reliability, 0, 1, 1),
        createdAt = value.createdAt,
        sourceEventID = sourceEventID,
        sourceEntityKey = sourceEntityKey,
        payload = payload,
        tags = tags,
    }
end

local function normalizeFact(factID, source)
    if type(source) ~= "table" then return nil, "fact_invalid" end
    local id = identifier(factID or source.id or source.factID)
    if not id then return nil, "fact_id_required" end
    local status = source.status or "suspected"
    if not STATUS_RANK[status] then return nil, "fact_status_invalid" end
    if source.value == nil then return nil, "fact_value_required" end
    local value, reason = sanitizeValue(source.value)
    if value == nil then return nil, reason end
    local evidence = {}
    for index = 1, math.min(#(source.evidence or {}), Knowledge.MAX_EVIDENCE_PER_FACT) do
        local item
        item, reason = normalizeEvidence(source.evidence[index])
        if not item then return nil, reason end
        evidence[#evidence + 1] = item
    end
    local output = {
        id = id,
        status = status,
        value = value,
        confidence = bounded(source.confidence, 0, 1, 0),
        firstDiscoveredAt = source.firstDiscoveredAt or source.discoveredAt,
        lastUpdatedAt = source.lastUpdatedAt or source.discoveredAt,
        primarySource = identifier(source.primarySource or source.sourceType),
        evidence = evidence,
        revision = math.max(0, math.floor(number(source.revision, 0))),
    }
    if source.primarySource ~= nil and not output.primarySource then
        return nil, "fact_source_invalid"
    end
    return output
end

local function normalizePlayer(source, playerKey)
    local input = type(source) == "table" and source or {}
    local output = {
        playerKey = playerKey,
        revision = math.max(0, math.floor(number(input.revision, 0))),
        facts = {},
    }
    local facts = input.facts or input.byFact or {}
    if type(facts) ~= "table" then return nil, "facts_required" end
    local count = 0
    for factID, value in pairs(facts) do
        count = count + 1
        if count > Knowledge.MAX_FACTS_PER_PLAYER then
            return nil, "fact_limit"
        end
        local fact, reason = normalizeFact(factID, value)
        if not fact then return nil, reason end
        output.facts[fact.id] = fact
    end
    return output
end

local function totalEvidence(player)
    local count = 0
    for _, fact in pairs(player.facts or {}) do count = count + #(fact.evidence or {}) end
    return count
end

local function trimEvidence(player)
    while totalEvidence(player) > Knowledge.MAX_EVIDENCE_PER_PLAYER do
        local removed = false
        for _, fact in pairs(player.facts or {}) do
            if #(fact.evidence or {}) > 0 then
                table.remove(fact.evidence, 1)
                removed = true
                break
            end
        end
        if not removed then break end
    end
end

local function hasEvidence(fact, evidenceID)
    for index = 1, #(fact.evidence or {}) do
        if fact.evidence[index].id == evidenceID then return true end
    end
    return false
end

function Knowledge.NormalizePlayerKey(value)
    return normalizePlayerKey(value)
end

function Knowledge.NewState(source)
    local input = type(source) == "table" and source or {}
    local output = {
        schemaVersion = Knowledge.SCHEMA_VERSION,
        revision = math.max(0, math.floor(number(input.revision, 0))),
        byPlayer = {},
    }
    local players = input.byPlayer or input.players or {}
    if type(players) ~= "table" then return nil, "players_required" end
    local count = 0
    for playerKey, value in pairs(players) do
        count = count + 1
        if count > Knowledge.MAX_PLAYERS then return nil, "player_limit" end
        local normalizedKey = normalizePlayerKey(playerKey)
        if not normalizedKey then return nil, "player_key_invalid" end
        local player, reason = normalizePlayer(value, normalizedKey)
        if not player then return nil, reason end
        output.byPlayer[normalizedKey] = player
    end
    return output
end

function Knowledge.Validate(state)
    if type(state) ~= "table"
        or tonumber(state.schemaVersion) ~= Knowledge.SCHEMA_VERSION
        or type(state.byPlayer) ~= "table"
    then return false, "knowledge_schema_mismatch" end
    local normalized, reason = Knowledge.NewState(state)
    if not normalized then return false, reason end
    if normalized.revision ~= state.revision then return false, "knowledge_revision_invalid" end
    for playerKey, player in pairs(state.byPlayer) do
        if normalizePlayerKey(playerKey) ~= playerKey
            or type(player) ~= "table"
            or player.playerKey ~= playerKey
        then return false, "player_key_invalid" end
        if not normalized.byPlayer[playerKey] then return false, "player_invalid" end
        for factID, fact in pairs(player.facts or {}) do
            if factID ~= fact.id or not STATUS_RANK[fact.status]
                or fact.value == nil
            then return false, "fact_invalid" end
        end
    end
    if not Util.isSerializable(state) then return false, "knowledge_not_serializable" end
    return true
end

function Knowledge.GetPlayer(state, playerKey)
    playerKey = normalizePlayerKey(playerKey)
    if not playerKey then return nil, "player_key_invalid" end
    local player = state and state.byPlayer and state.byPlayer[playerKey]
    if not player then return nil, "player_knowledge_not_found" end
    return Util.clone(player)
end

function Knowledge.Get(state, playerKey, factID)
    local player, reason = Knowledge.GetPlayer(state, playerKey)
    if not player then return nil, reason end
    factID = identifier(factID)
    if not factID then return nil, "fact_id_required" end
    local fact = player.facts[factID]
    if not fact then return nil, "fact_not_found" end
    return Util.clone(fact)
end

function Knowledge.Record(state, specification, authority, expectedRevision)
    if authority ~= "server" then return nil, "server_authority_required" end
    if type(state) ~= "table" or type(specification) ~= "table" then
        return nil, "knowledge_input_required"
    end
    if expectedRevision ~= nil
        and tonumber(expectedRevision) ~= tonumber(state.revision)
    then return nil, "revision_conflict" end
    local playerKey = normalizePlayerKey(
        specification.playerKey or specification.characterKey)
    local factID = identifier(specification.factID or specification.id)
    if not playerKey then return nil, "player_key_invalid" end
    if not factID then return nil, "fact_id_required" end
    if specification.value == nil then return nil, "fact_value_required" end
    local value, reason = sanitizeValue(specification.value)
    if value == nil then return nil, reason end
    local evidence, evidenceReason = normalizeEvidence(specification.evidence)
    if not evidence then return nil, evidenceReason end
    local status = specification.status or "suspected"
    if not STATUS_RANK[status] then return nil, "fact_status_invalid" end
    local player = state.byPlayer[playerKey]
    if not player then
        local playerCount = 0
        for _ in pairs(state.byPlayer) do playerCount = playerCount + 1 end
        if playerCount >= Knowledge.MAX_PLAYERS then return nil, "player_limit" end
        player = { playerKey = playerKey, revision = 0, facts = {} }
        state.byPlayer[playerKey] = player
    end
    local fact = player.facts[factID]
    if not fact then
        local factCount = 0
        for _ in pairs(player.facts) do factCount = factCount + 1 end
        if factCount >= Knowledge.MAX_FACTS_PER_PLAYER then
            return nil, "fact_limit"
        end
        fact = {
            id = factID,
            status = status,
            value = value,
            confidence = bounded(specification.confidence, 0, 1, 0),
            firstDiscoveredAt = specification.discoveredAt,
            lastUpdatedAt = specification.discoveredAt,
            primarySource = evidence.sourceType,
            evidence = {},
            revision = 0,
        }
        player.facts[factID] = fact
    else
        if STATUS_RANK[status] >= STATUS_RANK[fact.status] then
            fact.status = status
            fact.value = value
            fact.confidence = bounded(specification.confidence, 0, 1,
                fact.confidence)
        end
        fact.lastUpdatedAt = specification.discoveredAt or fact.lastUpdatedAt
        if not fact.primarySource then fact.primarySource = evidence.sourceType end
    end
    if not hasEvidence(fact, evidence.id) then
        fact.evidence[#fact.evidence + 1] = evidence
    end
    fact.revision = fact.revision + 1
    player.revision = player.revision + 1
    state.revision = (tonumber(state.revision) or 0) + 1
    trimEvidence(player)
    return Util.clone(state)
end

function Knowledge.ToPayload(state)
    local normalized, reason = Knowledge.NewState(state)
    if not normalized then return nil, reason end
    local valid
    valid, reason = Knowledge.Validate(normalized)
    if not valid then return nil, reason end
    return normalized
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ActorKnowledge = Knowledge
return Knowledge
