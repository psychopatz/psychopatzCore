local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Retention = require "PsychopatzCore/Actors/PsychopatzSocialRetention"
local Projections = require "PsychopatzCore/Actors/PsychopatzSocialProjections"

local Social = {}

Social.SCHEMA_VERSION = 1
Social.MAX_MEMORIES = Retention.MAX_MEMORIES
Social.MAX_SHORT_MEMORIES = Retention.MAX_SHORT_MEMORIES
Social.MAX_LONG_MEMORIES = Retention.MAX_LONG_MEMORIES
Social.MAX_ANCHOR_MEMORIES = Retention.MAX_ANCHOR_MEMORIES
Social.MAX_RECENT_EVENTS = 128
Social.MAX_COOLDOWNS = 32
Social.MAX_SATURATION = 32
Social.MAX_EXTENSIONS_PER_SCOPE = 16
Social.MIN_APPROVAL = -100
Social.MAX_APPROVAL = 100
Social.MIN_RESPECT = -100
Social.MAX_RESPECT = 100
Social.MIN_FAMILIARITY = 0
Social.MAX_FAMILIARITY = 100

Social.RETENTION_SCENE = Retention.SCENE
Social.RETENTION_SHORT = Retention.SHORT
Social.RETENTION_LONG = Retention.LONG
Social.RETENTION_ANCHOR = Retention.ANCHOR

local VALID_STATES = {
    unknown = true,
    neutral = true,
    friend = true,
    rival = true,
    enemy = true,
}

local function bounded(value, low, high)
    value = tonumber(value) or 0
    if value ~= value or value == math.huge or value == -math.huge then
        value = 0
    end
    return math.max(low, math.min(high, value))
end

local function targetKey(value)
    value = type(value) == "string" and value or ""
    if value == "" or string.match(value, "^%s+$") or string.find(value, "%c") then
        return nil
    end
    local prefix, rest = string.match(value, "^([%w_]+):(.+)$")
    if not rest or rest == "" then return nil end
    if prefix ~= "npc" and prefix ~= "actor" and prefix ~= "player"
        and prefix ~= "steam"
    then return nil end
    return value
end

function Social.ParseTargetKey(value)
    local normalized = targetKey(value)
    if not normalized then return nil end
    local prefix, rest = string.match(normalized, "^([%w_]+):(.+)$")
    if prefix == "player" then
        local account, charUUID = string.match(rest, "^([^:]+):([^:]+)$")
        if account and charUUID then
            return {
                key = normalized,
                kind = "player",
                id = rest,
                accountIdentity = account,
                characterUUID = charUUID,
            }
        end
    end
    return {
        key = normalized,
        kind = prefix,
        id = rest,
    }
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
    if output.retentionClass ~= nil then
        local cls = Retention.NormalizeClass(output.retentionClass, output.permanent)
        if not cls then return nil, "memory_retention_invalid" end
        output.retentionClass = cls
        if cls == Retention.ANCHOR then output.permanent = true end
    end
    if output.salience ~= nil then
        output.salience = math.floor(bounded(output.salience, 0, 255))
    end
    if output.confidence ~= nil then
        output.confidence = bounded(output.confidence, 0, 1)
    end
    if output.sourceMode ~= nil then
        output.sourceMode = Retention.NormalizeSourceMode(output.sourceMode, output.knowledgeSource)
    end
    if output.sourceKey ~= nil then
        output.sourceKey = targetKey(output.sourceKey)
    end
    return output
end

local function normalizeExtensions(value)
    if type(value) ~= "table" then return {} end
    local output = {}
    local count = 0
    for extKey, extVal in pairs(value) do
        if type(extVal) == "table" then
            count = count + 1
            if count <= Social.MAX_EXTENSIONS_PER_SCOPE then
                output[tostring(extKey)] = Util.clone(extVal)
            end
        end
    end
    return output
end

local function normalizeCooldowns(value)
    if type(value) ~= "table" then return nil end
    local output = {}
    local count = 0
    for k, v in pairs(value) do
        if type(k) == "string" and k ~= "" and tonumber(v) ~= nil then
            count = count + 1
            if count <= Social.MAX_COOLDOWNS then
                output[k] = tonumber(v)
            end
        end
    end
    return output
end

local function normalizeSaturation(value)
    if type(value) ~= "table" then return nil end
    local output = {}
    local count = 0
    for k, v in pairs(value) do
        if type(k) == "string" and k ~= "" and type(v) == "table" then
            count = count + 1
            if count <= Social.MAX_SATURATION then
                output[k] = {
                    approval = tonumber(v.approval) or 0,
                    respect = tonumber(v.respect) or 0,
                }
            end
        end
    end
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
        extensions = normalizeExtensions(value.extensions),
    }
    if value.baselineApproval ~= nil then
        output.baselineApproval = bounded(value.baselineApproval, Social.MIN_APPROVAL, Social.MAX_APPROVAL)
    end
    if value.baselineRespect ~= nil then
        output.baselineRespect = bounded(value.baselineRespect, Social.MIN_RESPECT, Social.MAX_RESPECT)
    end
    if type(value.state) == "string" and VALID_STATES[value.state] then
        output.state = value.state
    end
    if type(value.previousState) == "string" and VALID_STATES[value.previousState] then
        output.previousState = value.previousState
    end
    if tonumber(value.lastEvaluatedAt) ~= nil then
        output.lastEvaluatedAt = tonumber(value.lastEvaluatedAt)
    end
    if value.cooldowns ~= nil then
        output.cooldowns = normalizeCooldowns(value.cooldowns)
    end
    if value.saturation ~= nil then
        output.saturation = normalizeSaturation(value.saturation)
    end

    local rawMemories = value.memories or {}
    local startIdx = 1
    if #rawMemories > Social.MAX_MEMORIES then
        startIdx = #rawMemories - Social.MAX_MEMORIES + 1
    end
    for index = startIdx, #rawMemories do
        local memory, reason = copyMemory(rawMemories[index], target)
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
    local schemaVersion = tonumber(input.schemaVersion)
    if schemaVersion ~= 1 and schemaVersion ~= 2 then
        schemaVersion = Social.SCHEMA_VERSION
    end
    local output = {
        schemaVersion = schemaVersion,
        revision = math.max(0, math.floor(tonumber(input.revision) or 0)),
        personality = Util.clone(input.personality or {}),
        personalityOverrides = Util.clone(input.personalityOverrides or {}),
        recentEventIDs = {},
        relationships = {},
        aliases = Util.clone(input.aliases or {}),
        extensions = normalizeExtensions(input.extensions),
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
        or (tonumber(state.schemaVersion) ~= Social.SCHEMA_VERSION
            and tonumber(state.schemaVersion) ~= 2)
        or type(state.relationships) ~= "table"
    then return false, "social_schema_mismatch" end
    if type(state.personality) ~= "table"
        or type(state.personalityOverrides) ~= "table"
        or type(state.recentEventIDs) ~= "table"
    then return false, "social_shape_invalid" end
    if state.extensions ~= nil and type(state.extensions) ~= "table" then
        return false, "social_extensions_invalid"
    end
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
        if relationship.extensions ~= nil
            and type(relationship.extensions) ~= "table"
        then
            return false, "relationship_extensions_invalid"
        end
        local memories = relationship.memories or {}
        if #memories > Social.MAX_MEMORIES then
            return false, "relationship_memory_limit_exceeded"
        end
        local memoryIDs = {}
        for index = 1, #memories do
            local memory = memories[index]
            if type(memory) ~= "table" or type(memory.id) ~= "string"
                or memory.id == "" or memoryIDs[memory.id]
            then return false, "relationship_memory_invalid" end
            if memory.retentionClass ~= nil
                and not Retention.VALID_CLASSES[memory.retentionClass]
            then return false, "relationship_memory_retention_invalid" end
            memoryIDs[memory.id] = true
        end
    end
    return true
end

local function resolveTargetKey(target)
    local normalized = targetKey(target)
    if not normalized and PsychopatzCore and PsychopatzCore.Actors
        and PsychopatzCore.Actors.PlayerIdentity
    then
        normalized = targetKey(PsychopatzCore.Actors.PlayerIdentity.GetTargetKey(target))
    end
    return normalized
end

local function lookupRelationshipRef(state, target)
    local normalized = resolveTargetKey(target)
    if not normalized then return nil, nil end
    if state and state.aliases and state.aliases[normalized] then
        normalized = state.aliases[normalized]
    end
    local rel = state and state.relationships and state.relationships[normalized]
    return rel, normalized
end

local function mergeRelationshipData(targetRel, sourceRel)
    if not sourceRel then return targetRel end
    if (sourceRel.familiarity or 0) > (targetRel.familiarity or 0)
        or (targetRel.familiarity == 0 and (sourceRel.approval ~= 0 or sourceRel.respect ~= 0))
    then
        targetRel.approval = sourceRel.approval
        targetRel.respect = sourceRel.respect
        targetRel.familiarity = sourceRel.familiarity
        if sourceRel.baselineApproval ~= nil then
            targetRel.baselineApproval = sourceRel.baselineApproval
        end
        if sourceRel.baselineRespect ~= nil then
            targetRel.baselineRespect = sourceRel.baselineRespect
        end
        if sourceRel.state ~= nil then targetRel.state = sourceRel.state end
        if sourceRel.previousState ~= nil then targetRel.previousState = sourceRel.previousState end
    end

    local existingMemoryIDs = {}
    for _, m in ipairs(targetRel.memories or {}) do
        local id = m.id or m.eventID
        if id then existingMemoryIDs[id] = true end
    end
    for _, m in ipairs(sourceRel.memories or {}) do
        local id = m.id or m.eventID
        if id and not existingMemoryIDs[id] then
            existingMemoryIDs[id] = true
            Retention.ConsolidateOrInsertMemory(targetRel, m, { consolidate = true })
        end
    end

    targetRel.extensions = targetRel.extensions or {}
    for extID, extVal in pairs(sourceRel.extensions or {}) do
        if targetRel.extensions[extID] == nil then
            targetRel.extensions[extID] = Util.clone(extVal)
        elseif type(extVal) == "table" and type(targetRel.extensions[extID]) == "table" then
            for k, v in pairs(extVal) do
                if targetRel.extensions[extID][k] == nil then
                    targetRel.extensions[extID][k] = Util.clone(v)
                end
            end
        end
    end
    targetRel.revision = math.max(targetRel.revision or 0, sourceRel.revision or 0) + 1
    return targetRel
end

function Social.Get(state, target)
    local relationship, normalized = lookupRelationshipRef(state, target)
    if not normalized then return nil, "target_key_invalid" end
    if not relationship then return nil, "relationship_not_found" end
    return Util.clone(relationship)
end

function Social.GetOrCreate(state, target)
    local normalized = resolveTargetKey(target)
    if not normalized then return nil, "target_key_invalid" end
    if state and state.aliases and state.aliases[normalized] then
        normalized = state.aliases[normalized]
    end
    state.relationships = state.relationships or {}
    if not state.relationships[normalized] then
        state.relationships[normalized] = {
            targetKey = normalized, approval = 0, respect = 0,
            familiarity = 0, revision = 0, memories = {},
            extensions = {},
        }
    else
        state.relationships[normalized].extensions =
            state.relationships[normalized].extensions or {}
    end
    return state.relationships[normalized]
end

function Social.MigrateAliases(state, canonicalKey, aliasKeys)
    if type(state) ~= "table" then return nil, "state_required" end
    local normalizedCanonical = resolveTargetKey(canonicalKey)
    if not normalizedCanonical then return nil, "canonical_key_invalid" end
    if type(aliasKeys) ~= "table" then return true end

    state.aliases = state.aliases or {}
    state.relationships = state.relationships or {}

    local mergedAny = false
    for _, alias in ipairs(aliasKeys) do
        local normalizedAlias = resolveTargetKey(alias)
        if normalizedAlias and normalizedAlias ~= normalizedCanonical then
            state.aliases[normalizedAlias] = normalizedCanonical
            local legacyRel = state.relationships[normalizedAlias]
            if legacyRel then
                local canonicalRel = Social.GetOrCreate(state, normalizedCanonical)
                mergeRelationshipData(canonicalRel, legacyRel)
                state.relationships[normalizedAlias] = nil
                mergedAny = true
            end
        end
    end
    if mergedAny then
        state.revision = (tonumber(state.revision) or 0) + 1
    end
    return true
end

function Social.MutateRelationship(state, target, mutatorFn, authority, expectedRevision)
    if authority ~= "server" then return nil, "server_authority_required" end
    if type(state) ~= "table" then return nil, "state_required" end
    if type(mutatorFn) ~= "function" then return nil, "mutator_fn_required" end

    local normalized = resolveTargetKey(target)
    if not normalized then return nil, "target_key_invalid" end
    if state and state.aliases and state.aliases[normalized] then
        normalized = state.aliases[normalized]
    end

    local rel = Social.GetOrCreate(state, normalized)
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= tonumber(rel.revision) then
        return nil, "relationship_revision_conflict"
    end

    local oldApp = tonumber(rel.approval) or 0
    local oldResp = tonumber(rel.respect) or 0
    local cloneRel = Util.clone(rel)
    local ok, mutated = pcall(mutatorFn, cloneRel)
    if not ok or type(mutated) ~= "table" then
        return nil, "mutation_failed"
    end

    if mutated.baselineApproval ~= nil then
        rel.baselineApproval = bounded(mutated.baselineApproval, Social.MIN_APPROVAL, Social.MAX_APPROVAL)
    end
    if mutated.baselineRespect ~= nil then
        rel.baselineRespect = bounded(mutated.baselineRespect, Social.MIN_RESPECT, Social.MAX_RESPECT)
    end
    if mutated.approval ~= nil then
        rel.approval = bounded(mutated.approval, Social.MIN_APPROVAL, Social.MAX_APPROVAL)
    end
    if mutated.respect ~= nil then
        rel.respect = bounded(mutated.respect, Social.MIN_RESPECT, Social.MAX_RESPECT)
    end
    if mutated.familiarity ~= nil then
        rel.familiarity = bounded(mutated.familiarity, Social.MIN_FAMILIARITY, Social.MAX_FAMILIARITY)
    end
    if type(mutated.state) == "string" and VALID_STATES[mutated.state] then
        rel.state = mutated.state
    end
    if type(mutated.previousState) == "string" and VALID_STATES[mutated.previousState] then
        rel.previousState = mutated.previousState
    end
    if tonumber(mutated.lastEvaluatedAt) ~= nil then
        rel.lastEvaluatedAt = tonumber(mutated.lastEvaluatedAt)
    end
    if mutated.cooldowns ~= nil then
        rel.cooldowns = normalizeCooldowns(mutated.cooldowns)
    end
    if mutated.saturation ~= nil then
        rel.saturation = normalizeSaturation(mutated.saturation)
    end

    local existingMemories = {}
    for _, m in ipairs(rel.memories or {}) do
        local id = m.id or m.eventID
        if id then existingMemories[id] = true end
    end
    local addedMemories = 0
    for _, m in ipairs(mutated.memories or {}) do
        local id = m.id or m.eventID
        if id and not existingMemories[id] then
            local normalizedMem = copyMemory(m, normalized)
            if normalizedMem then
                existingMemories[id] = true
                addedMemories = addedMemories + 1
                Retention.ConsolidateOrInsertMemory(rel, normalizedMem, { consolidate = false })
            end
        end
    end
    if addedMemories == 0 then
        local deltaApp = (tonumber(rel.approval) or 0) - oldApp
        local deltaResp = (tonumber(rel.respect) or 0) - oldResp
        if deltaApp ~= 0 and (rel.baselineApproval ~= nil or mutated.baselineApproval ~= nil) then
            rel.baselineApproval = bounded((tonumber(rel.baselineApproval) or 0) + deltaApp,
                Social.MIN_APPROVAL, Social.MAX_APPROVAL)
        end
        if deltaResp ~= 0 and (rel.baselineRespect ~= nil or mutated.baselineRespect ~= nil) then
            rel.baselineRespect = bounded((tonumber(rel.baselineRespect) or 0) + deltaResp,
                Social.MIN_RESPECT, Social.MAX_RESPECT)
        end
    end

    rel.extensions = rel.extensions or {}
    if type(mutated.extensions) == "table" then
        for extID, extVal in pairs(mutated.extensions) do
            if type(extVal) == "table" then
                rel.extensions[extID] = Util.clone(extVal)
            elseif extVal == nil then
                rel.extensions[extID] = nil
            end
        end
    end

    rel.revision = (tonumber(rel.revision) or 0) + 1
    state.revision = (tonumber(state.revision) or 0) + 1
    return Util.clone(rel)
end

function Social.GetExtension(state, target, extensionID)
    if type(state) ~= "table" then return nil, "state_required" end
    if type(extensionID) ~= "string" or extensionID == "" then
        return nil, "extension_id_required"
    end
    if target == nil or target == "" then
        local ext = state.extensions and state.extensions[extensionID]
        return ext and Util.clone(ext) or nil
    end
    local rel, normalized = lookupRelationshipRef(state, target)
    if not normalized then return nil, "target_key_invalid" end
    if not rel then return nil, "relationship_not_found" end
    local ext = rel.extensions and rel.extensions[extensionID]
    return ext and Util.clone(ext) or nil
end

function Social.SetExtension(state, target, extensionID, payload, authority, expectedRevision)
    if authority ~= "server" then return nil, "server_authority_required" end
    if type(state) ~= "table" then return nil, "state_required" end
    if type(extensionID) ~= "string" or extensionID == "" then
        return nil, "extension_id_required"
    end
    if expectedRevision ~= nil
        and tonumber(expectedRevision) ~= tonumber(state.revision)
    then
        return nil, "revision_conflict"
    end
    if target == nil or target == "" then
        state.extensions = state.extensions or {}
        if payload == nil then
            state.extensions[extensionID] = nil
        else
            if type(payload) ~= "table" then return nil, "payload_table_required" end
            state.extensions[extensionID] = Util.clone(payload)
        end
        state.revision = (tonumber(state.revision) or 0) + 1
        return Util.clone(state)
    end
    local normalized = resolveTargetKey(target)
    if not normalized then return nil, "target_key_invalid" end
    if state and state.aliases and state.aliases[normalized] then
        normalized = state.aliases[normalized]
    end
    local rel, reason = Social.GetOrCreate(state, normalized)
    if not rel then return nil, reason end
    rel.extensions = rel.extensions or {}
    if payload == nil then
        rel.extensions[extensionID] = nil
    else
        if type(payload) ~= "table" then return nil, "payload_table_required" end
        rel.extensions[extensionID] = Util.clone(payload)
    end
    rel.revision = (tonumber(rel.revision) or 0) + 1
    state.revision = (tonumber(state.revision) or 0) + 1
    return Util.clone(state)
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

function Social.RecalculateRelationship(state, target, worldAgeHours, options)
    if type(state) ~= "table" then return nil, "state_required" end
    local rel, normalized = lookupRelationshipRef(state, target)
    if not normalized then return nil, "target_key_invalid" end
    if not rel then return nil, "relationship_not_found" end

    options = type(options) == "table" and options or {}
    Retention.PruneMemories(rel, worldAgeHours, options)

    local usesBaselines = rel.baselineApproval ~= nil or rel.baselineRespect ~= nil
        or options.recalculateFromBaselines == true
    if usesBaselines then
        local app = tonumber(rel.baselineApproval) or 0
        local resp = tonumber(rel.baselineRespect) or 0
        for _, mem in ipairs(rel.memories or {}) do
            local str = Retention.CalculateMemoryStrength(mem, worldAgeHours)
            app = app + ((tonumber(mem.approvalEffect) or 0) * str)
            resp = resp + ((tonumber(mem.respectEffect) or 0) * str)
        end
        rel.approval = bounded(app, Social.MIN_APPROVAL, Social.MAX_APPROVAL)
        rel.respect = bounded(resp, Social.MIN_RESPECT, Social.MAX_RESPECT)
    end
    local nextState = Projections.ResolveState(rel)
    if rel.state ~= nil or options.updateState == true then
        if nextState ~= rel.state then
            rel.previousState = rel.state or "unknown"
            rel.state = nextState
        end
    end
    if worldAgeHours ~= nil then
        rel.lastEvaluatedAt = tonumber(worldAgeHours)
    end
    return Util.clone(rel)
end

local function resolvePolicyForEvent(event)
    if type(event.policy) == "table" then return event.policy end
    local policySvc = PsychopatzCore and PsychopatzCore.SocialPolicy
    if policySvc and type(policySvc.Resolve) == "function" then
        return policySvc.Resolve(event.type)
    end
    return nil
end

function Social.RecordAuthorizedEvent(state, event)
    if type(state) ~= "table" or type(event) ~= "table" then
        return nil, "event_required"
    end
    if event.authorized ~= true or event.authority ~= "server" then
        return nil, "server_authority_required"
    end
    local normalized = resolveTargetKey(event.targetKey)
    local eventID = event.eventID
    if not normalized then return nil, "target_key_invalid" end
    if state and state.aliases and state.aliases[normalized] then
        normalized = state.aliases[normalized]
    end
    if type(eventID) ~= "string" or eventID == "" then
        return nil, "event_id_required"
    end
    if hasRecentEvent(state, eventID) then return nil, "duplicate_event" end

    local policy = resolvePolicyForEvent(event)
    local rawRetention = event.retentionClass or (policy and policy.retentionClass)
    local isPermanent = event.permanent == true or (policy and policy.permanent == true)
    local retentionClass = Retention.NormalizeClass(rawRetention, isPermanent)
    if rawRetention ~= nil and not retentionClass then
        return nil, "retention_class_invalid"
    end

    local relationship, reason = Social.GetOrCreate(state, normalized)
    if not relationship then return nil, reason end

    local eventTime = event.createdAt or event.eventTime
    local worldAge = tonumber(event.worldAgeHours or eventTime)
    local cooldownHours = tonumber(event.cooldownHours or (policy and policy.cooldownHours))
    if cooldownHours and cooldownHours > 0 and worldAge ~= nil then
        local cdKey = tostring(event.cooldownKey or event.type or "event")
        local untilHours = relationship.cooldowns and tonumber(relationship.cooldowns[cdKey])
        if untilHours and worldAge < untilHours then
            return nil, "event_cooldown_active"
        end
        relationship.cooldowns = relationship.cooldowns or {}
        relationship.cooldowns[cdKey] = worldAge + cooldownHours
    end

    local baseEvent = Util.clone(event)
    if baseEvent.approvalDelta == nil and policy and policy.approvalDelta ~= nil then
        baseEvent.approvalDelta = policy.approvalDelta
    end
    if baseEvent.respectDelta == nil and policy and policy.respectDelta ~= nil then
        baseEvent.respectDelta = policy.respectDelta
    end
    if baseEvent.familiarityDelta == nil and policy and policy.familiarityDelta ~= nil then
        baseEvent.familiarityDelta = policy.familiarityDelta
    end
    local mod = Retention.ApplyPersonalityModulation(state.personality, baseEvent, policy)

    local appDelta = mod.approvalDelta
    local respDelta = mod.respectDelta
    local famDelta = mod.familiarityDelta

    local satCaps = event.saturationCaps or (policy and policy.saturationCaps)
    if type(satCaps) == "table" then
        local satKey = tostring(event.saturationKey or event.type or "event")
        relationship.saturation = relationship.saturation or {}
        local sat = relationship.saturation[satKey] or { approval = 0, respect = 0 }
        if satCaps.approval ~= nil then
            local cap = math.abs(tonumber(satCaps.approval) or 0)
            local nextSat = bounded(sat.approval + appDelta, -cap, cap)
            appDelta = nextSat - sat.approval
            sat.approval = nextSat
        end
        if satCaps.respect ~= nil then
            local cap = math.abs(tonumber(satCaps.respect) or 0)
            local nextSat = bounded(sat.respect + respDelta, -cap, cap)
            respDelta = nextSat - sat.respect
            sat.respect = nextSat
        end
        relationship.saturation[satKey] = sat
    end

    local memorySpec = {
        id = eventID,
        type = event.type or "event",
        aboutKey = normalized,
        createdAt = eventTime,
        approvalEffect = appDelta,
        respectEffect = respDelta,
        familiarityEffect = famDelta,
        tags = Util.clone(event.tags or {}),
    }
    if retentionClass then
        memorySpec.retentionClass = retentionClass
        if retentionClass == Retention.ANCHOR then memorySpec.permanent = true end
    end
    if mod.salience ~= nil then
        memorySpec.salience = math.floor(bounded(mod.salience, 0, 255))
    end
    if mod.decayPerDay ~= nil then
        memorySpec.decayPerDay = math.max(0, tonumber(mod.decayPerDay) or 0)
    elseif retentionClass == Retention.SHORT then
        memorySpec.decayPerDay = Retention.DEFAULT_DECAY.SHORT
    elseif retentionClass == Retention.LONG then
        memorySpec.decayPerDay = Retention.DEFAULT_DECAY.LONG
    end
    if event.strength ~= nil then
        memorySpec.strength = bounded(event.strength, 0, 1)
    end
    if event.permanent ~= nil then memorySpec.permanent = event.permanent == true end
    if event.shareable ~= nil or (policy and policy.shareable ~= nil) then
        memorySpec.shareable = (event.shareable ~= nil) and (event.shareable == true)
            or (policy and policy.shareable == true)
    end
    if event.knowledgeSource ~= nil then memorySpec.knowledgeSource = event.knowledgeSource end
    if event.sourceMode ~= nil or event.knowledgeSource ~= nil then
        memorySpec.sourceMode = Retention.NormalizeSourceMode(event.sourceMode, event.knowledgeSource)
    end
    if event.sourceKey ~= nil then memorySpec.sourceKey = targetKey(event.sourceKey) end
    if event.confidence ~= nil then
        memorySpec.confidence = bounded(event.confidence, 0, 1)
    elseif memorySpec.sourceMode == "hearsay" then
        memorySpec.confidence = Retention.DefaultConfidence(memorySpec.sourceMode, memorySpec.knowledgeSource)
    end
    local consolKey = event.consolidationKey or (policy and policy.consolidationKey)
    local consolFamily = event.consolidationFamily or (policy and policy.consolidationFamily)
    if type(consolKey) == "string" and consolKey ~= "" then
        memorySpec.consolidationKey = consolKey
    end
    if type(consolFamily) == "string" and consolFamily ~= "" then
        memorySpec.consolidationFamily = consolFamily
    end

    local insertOpts = {
        worldAgeHours = worldAge,
        maxMemories = event.maxMemories or (policy and policy.maxMemories),
        maxAnchors = event.maxAnchors or (policy and policy.maxAnchors),
        maxShort = event.maxShort or (policy and policy.maxShort),
        maxLong = event.maxLong or (policy and policy.maxLong),
        consolidate = event.consolidate,
        maxConsolidatedApproval = event.maxConsolidatedApproval
            or (policy and policy.maxConsolidatedApproval),
        maxConsolidatedRespect = event.maxConsolidatedRespect
            or (policy and policy.maxConsolidatedRespect),
        maxConsolidatedFamiliarity = event.maxConsolidatedFamiliarity
            or (policy and policy.maxConsolidatedFamiliarity),
    }

    local memResult = Retention.ConsolidateOrInsertMemory(relationship, memorySpec, insertOpts)
    local effAppDelta = memResult.appliedApprovalDelta ~= nil and memResult.appliedApprovalDelta or appDelta
    local effRespDelta = memResult.appliedRespectDelta ~= nil and memResult.appliedRespectDelta or respDelta
    local effFamDelta = memResult.appliedFamiliarityDelta ~= nil and memResult.appliedFamiliarityDelta or famDelta

    relationship.approval = bounded(relationship.approval + effAppDelta,
        Social.MIN_APPROVAL, Social.MAX_APPROVAL)
    relationship.respect = bounded(relationship.respect + effRespDelta,
        Social.MIN_RESPECT, Social.MAX_RESPECT)
    relationship.familiarity = bounded(relationship.familiarity + effFamDelta,
        Social.MIN_FAMILIARITY, Social.MAX_FAMILIARITY)

    if memResult.status == "scene_ephemeral"
        and (relationship.baselineApproval ~= nil or relationship.baselineRespect ~= nil)
    then
        if effAppDelta ~= 0 then
            relationship.baselineApproval = bounded(
                (tonumber(relationship.baselineApproval) or 0) + effAppDelta,
                Social.MIN_APPROVAL, Social.MAX_APPROVAL)
        end
        if effRespDelta ~= 0 then
            relationship.baselineRespect = bounded(
                (tonumber(relationship.baselineRespect) or 0) + effRespDelta,
                Social.MIN_RESPECT, Social.MAX_RESPECT)
        end
    end

    if relationship.state ~= nil or (policy and policy.updateState == true) then
        local resolvedState = Projections.ResolveState(relationship)
        if resolvedState ~= relationship.state then
            relationship.previousState = relationship.state or "unknown"
            relationship.state = resolvedState
        end
    end

    relationship.revision = relationship.revision + 1
    relationship.lastEventAt = eventTime
    state.recentEventIDs[#state.recentEventIDs + 1] = eventID
    while #state.recentEventIDs > Social.MAX_RECENT_EVENTS do
        table.remove(state.recentEventIDs, 1)
    end
    state.revision = (tonumber(state.revision) or 0) + 1
    return Util.clone(state)
end

Social.CalculateMemoryStrength = Retention.CalculateMemoryStrength
Social.PruneMemories = Retention.PruneMemories
Social.ConsolidateOrInsertMemory = Retention.ConsolidateOrInsertMemory
Social.ApplyPersonalityModulation = Retention.ApplyPersonalityModulation
Social.NextMemorySequence = Retention.NextMemorySequence
Social.ResolveState = Projections.ResolveState
Social.ResolveAttitude = Projections.ResolveAttitude

function Social.QueryCandidateProjection(state, target, options)
    return Projections.QueryCandidateProjection(state, target, options, lookupRelationshipRef)
end

function Social.ToPayload(state)
    local normalized, reason = Social.NewState(state)
    if not normalized then return nil, reason end
    local valid
    valid, reason = Social.Validate(normalized)
    if not valid then return nil, reason end
    return normalized
end

function Social.FromPayload(payload)
    return Social.NewState(payload)
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Social = Social
return Social
