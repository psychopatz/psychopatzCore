local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Retention = require "PsychopatzCore/Actors/PsychopatzSocialRetention"
local Projections = require "PsychopatzCore/Actors/PsychopatzSocialProjections"

local Social = {}

Social.SCHEMA_VERSION = 3
Social.LEGACY_SCHEMA_VERSION_1 = 1
Social.LEGACY_SCHEMA_VERSION_2 = 2
Social.MAX_ACTOR_MEMORIES = Retention.MAX_ACTOR_MEMORIES
Social.MAX_MEMORIES = Retention.MAX_ACTOR_MEMORIES
Social.MAX_SHORT_MEMORIES = Retention.MAX_SHORT_MEMORIES
Social.MAX_LONG_MEMORIES = Retention.MAX_LONG_MEMORIES
Social.MAX_ANCHOR_MEMORIES = Retention.MAX_ANCHOR_MEMORIES
Social.MAX_RECENT_EVENTS = 128
Social.MAX_COOLDOWNS = 32
Social.MAX_SATURATION = 32
Social.MAX_EXTENSIONS_PER_SCOPE = 16
Social.MAX_MEMORY_INDEX_CACHE = 32
Social.MAX_ROLE_REFS = 4
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

Social.REF_STRONG = Retention.REF_STRONG
Social.REF_WEAK = Retention.REF_WEAK
Social.REF_LABEL_ONLY = Retention.REF_LABEL_ONLY

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

local function normalizeRoleRefs(roleRefs)
    if type(roleRefs) ~= "table" then return nil end
    local out = {}
    local count = 0
    local keys = {}
    for role in pairs(roleRefs) do
        if type(role) == "string" and role ~= "" then
            keys[#keys + 1] = role
        end
    end
    table.sort(keys)
    for index = 1, #keys do
        if count >= Social.MAX_ROLE_REFS then break end
        local role = keys[index]
        local ref = roleRefs[role]
        if type(ref) == "table" then
            local entry = {}
            local rk = ref.ref ~= nil and targetKey(ref.ref) or (ref.targetKey ~= nil and targetKey(ref.targetKey) or nil)
            if rk then entry.ref = rk end
            if ref.refStrength ~= nil then
                entry.refStrength = Retention.NormalizeRefStrength(ref.refStrength)
            end
            if type(ref.label) == "string" and ref.label ~= "" then
                entry.label = string.sub(ref.label, 1, 64)
            end
            if entry.ref ~= nil or entry.label ~= nil then
                count = count + 1
                out[role] = entry
            end
        elseif type(ref) == "string" and ref ~= "" then
            local rk = targetKey(ref)
            if rk then
                count = count + 1
                out[role] = { ref = rk }
            end
        end
    end
    if count == 0 then return nil end
    return out
end

local function copyMemory(memory, target)
    if type(memory) ~= "table" then return nil, "memory_invalid" end
    local id = memory.id or memory.eventID
    if type(id) ~= "string" or id == "" then return nil, "memory_id_required" end
    local output = Util.clone(memory)
    output.id = id
    output.type = output.type or output.eventType
    local resolvedAbout = target or targetKey(output.aboutKey)
    if resolvedAbout ~= nil then
        output.aboutKey = resolvedAbout
    elseif output.aboutKey ~= nil then
        return nil, "memory_about_key_invalid"
    end
    if output.subjectKey ~= nil then
        output.subjectKey = targetKey(output.subjectKey)
    end
    if output.retentionClass ~= nil then
        local cls = Retention.NormalizeClass(output.retentionClass, output.permanent)
        if not cls then return nil, "memory_retention_invalid" end
        output.retentionClass = cls
        if cls == Retention.ANCHOR then output.permanent = true end
    end
    local effectiveCls = Retention.EffectiveClass(output)
    if output.refStrength ~= nil then
        local upper = type(output.refStrength) == "string" and string.upper(output.refStrength) or ""
        if not Retention.VALID_REF_STRENGTHS[upper] then
            return nil, "memory_ref_strength_invalid"
        end
        output.refStrength = upper
    else
        output.refStrength = (effectiveCls == Retention.ANCHOR or output.permanent == true)
            and Retention.REF_STRONG or Retention.REF_WEAK
    end
    if output.sourceRefStrength ~= nil then
        local upper = type(output.sourceRefStrength) == "string" and string.upper(output.sourceRefStrength) or ""
        if not Retention.VALID_REF_STRENGTHS[upper] then
            return nil, "memory_ref_strength_invalid"
        end
        output.sourceRefStrength = upper
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
    if output.roleRefs ~= nil then
        output.roleRefs = normalizeRoleRefs(output.roleRefs)
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
    if value.historical == true then
        output.historical = true
    end
    if value.historicalPin == true then
        output.historicalPin = true
    end
    if type(value.targetLifecycleStatus) == "string" and value.targetLifecycleStatus ~= "" then
        output.targetLifecycleStatus = value.targetLifecycleStatus
    end
    if tonumber(value.targetLifecycleRevision) ~= nil then
        output.targetLifecycleRevision = math.max(0, math.floor(tonumber(value.targetLifecycleRevision)))
    end
    if type(value.historicalLabel) == "string" and value.historicalLabel ~= "" then
        output.historicalLabel = string.sub(value.historicalLabel, 1, 64)
    end
    if type(value.degradedLabel) == "string" and value.degradedLabel ~= "" then
        output.degradedLabel = string.sub(value.degradedLabel, 1, 64)
    end
    if type(value.historicalRole) == "string" and value.historicalRole ~= "" then
        output.historicalRole = string.sub(value.historicalRole, 1, 32)
    end
    if type(value.historicalReason) == "string" and value.historicalReason ~= "" then
        output.historicalReason = string.sub(value.historicalReason, 1, 48)
    end
    if tonumber(value.retiredAt) ~= nil then
        output.retiredAt = tonumber(value.retiredAt)
    end
    return output
end

function Social.NormalizeTargetKey(value)
    return targetKey(value)
end

local memoryIndexCache = {}

function Social.InvalidateMemoryIndex(state)
    if type(state) ~= "table" then return end
    for idx = #memoryIndexCache, 1, -1 do
        if memoryIndexCache[idx].stateRef == state then
            table.remove(memoryIndexCache, idx)
        end
    end
end

function Social.GetMemoryIndexStats()
    return {
        cachedStates = #memoryIndexCache,
        maxCachedStates = Social.MAX_MEMORY_INDEX_CACHE,
        persistedKeysAdded = false,
    }
end

local function buildMemoryIndex(state)
    local byTarget = {}
    local byClass = {
        ANCHOR = {},
        LONG = {},
        SHORT = {},
    }
    local byEvent = {}
    local bank = type(state) == "table" and state.memoryBank or nil
    if type(bank) == "table" then
        for index = 1, #bank do
            local mem = bank[index]
            if type(mem) == "table" then
                if type(mem.aboutKey) == "string" and mem.aboutKey ~= "" then
                    byTarget[mem.aboutKey] = byTarget[mem.aboutKey] or {}
                    byTarget[mem.aboutKey][#byTarget[mem.aboutKey] + 1] = mem
                end
                local cls = Retention.EffectiveClass(mem)
                byClass[cls] = byClass[cls] or {}
                byClass[cls][#byClass[cls] + 1] = mem
                if type(mem.type) == "string" and mem.type ~= "" then
                    byEvent[mem.type] = byEvent[mem.type] or {}
                    byEvent[mem.type][#byEvent[mem.type] + 1] = mem
                end
            end
        end
    end
    return {
        byTarget = byTarget,
        byClass = byClass,
        byEvent = byEvent,
    }
end

local function getMemoryIndex(state)
    if type(state) ~= "table" then return buildMemoryIndex(nil) end
    local rev = tonumber(state.revision) or 0
    local count = #(state.memoryBank or {})
    local firstID = state.memoryBank and state.memoryBank[1] and state.memoryBank[1].id or nil
    local lastID = state.memoryBank and count > 0 and state.memoryBank[count] and state.memoryBank[count].id or nil
    for idx = #memoryIndexCache, 1, -1 do
        local entry = memoryIndexCache[idx]
        if entry.stateRef == state
            and entry.revision == rev
            and entry.count == count
            and entry.firstID == firstID
            and entry.lastID == lastID
        then
            return entry.index
        end
    end
    Social.InvalidateMemoryIndex(state)
    local built = buildMemoryIndex(state)
    memoryIndexCache[#memoryIndexCache + 1] = {
        stateRef = state,
        revision = rev,
        count = count,
        firstID = firstID,
        lastID = lastID,
        index = built,
    }
    while #memoryIndexCache > Social.MAX_MEMORY_INDEX_CACHE do
        table.remove(memoryIndexCache, 1)
    end
    return built
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
        memoryBank = {},
        aliases = Util.clone(input.aliases or {}),
        extensions = normalizeExtensions(input.extensions),
    }
    for index = 1, math.min(#(input.recentEventIDs or {}), Social.MAX_RECENT_EVENTS) do
        output.recentEventIDs[index] = input.recentEventIDs[index]
    end

    local relKeys = {}
    for key in pairs(relationships) do
        relKeys[#relKeys + 1] = key
    end
    table.sort(relKeys, function(a, b) return tostring(a) < tostring(b) end)

    local seenMemoryIDs = {}
    local seqCounter = 0
    local function appendMigratedMemory(rawMem, fallbackTarget)
        if type(rawMem) ~= "table" then return nil, "memory_invalid" end
        local copied, reason = copyMemory(rawMem, fallbackTarget)
        if not copied then return nil, reason end
        if Retention.EffectiveClass(copied) == Retention.SCENE then
            return true
        end
        if seenMemoryIDs[copied.id] then
            return true
        end
        seenMemoryIDs[copied.id] = true
        seqCounter = seqCounter + 1
        copied.eventSequence = copied.eventSequence or seqCounter
        output.memoryBank[#output.memoryBank + 1] = copied
        return true
    end

    if type(input.memoryBank) == "table" then
        for index = 1, #input.memoryBank do
            local ok, reason = appendMigratedMemory(input.memoryBank[index], nil)
            if not ok then return nil, reason end
        end
    end

    for _, key in ipairs(relKeys) do
        local value = relationships[key]
        local normalizedKey = targetKey(key)
        if not normalizedKey then return nil, "relationship_target_invalid" end
        local relationship, reason = normalizeRelationship(normalizedKey, value)
        if not relationship then return nil, reason end
        output.relationships[normalizedKey] = relationship
        if type(value) == "table" and type(value.memories) == "table" then
            for index = 1, #value.memories do
                local ok, memReason = appendMigratedMemory(value.memories[index], normalizedKey)
                if not ok then return nil, memReason end
            end
        end
    end

    if #output.memoryBank > 0 then
        Retention.PruneMemories(output, nil, {
            promoteEvictedToBaseline = true,
            demoteOverflowAnchors = true,
        })
    end
    return output
end

function Social.Validate(state)
    if type(state) ~= "table"
        or tonumber(state.schemaVersion) ~= Social.SCHEMA_VERSION
        or type(state.relationships) ~= "table"
        or type(state.memoryBank) ~= "table"
    then return false, "social_schema_mismatch" end
    if type(state.personality) ~= "table"
        or type(state.personalityOverrides) ~= "table"
        or type(state.recentEventIDs) ~= "table"
    then return false, "social_shape_invalid" end
    if state.extensions ~= nil and type(state.extensions) ~= "table" then
        return false, "social_extensions_invalid"
    end
    if #state.memoryBank > Social.MAX_ACTOR_MEMORIES then
        return false, "memory_bank_limit_exceeded"
    end
    local memoryIDs = {}
    local anchorCount, shortCount, longCount = 0, 0, 0
    for index = 1, #state.memoryBank do
        local memory = state.memoryBank[index]
        if type(memory) ~= "table" or type(memory.id) ~= "string" or memory.id == "" then
            return false, "memory_bank_entry_invalid"
        end
        if memoryIDs[memory.id] then
            return false, "memory_bank_duplicate_id"
        end
        if memory.retentionClass ~= nil and not Retention.VALID_CLASSES[memory.retentionClass] then
            return false, "memory_bank_retention_invalid"
        end
        local cls = Retention.EffectiveClass(memory)
        if cls == Retention.SCENE then
            return false, "memory_bank_scene_forbidden"
        elseif cls == Retention.ANCHOR then
            anchorCount = anchorCount + 1
        elseif cls == Retention.SHORT then
            shortCount = shortCount + 1
        else
            longCount = longCount + 1
        end
        if memory.refStrength ~= nil and not Retention.VALID_REF_STRENGTHS[memory.refStrength] then
            return false, "memory_bank_ref_strength_invalid"
        end
        if memory.aboutKey ~= nil and targetKey(memory.aboutKey) ~= memory.aboutKey then
            return false, "memory_bank_about_key_invalid"
        end
        memoryIDs[memory.id] = true
    end
    if anchorCount > Social.MAX_ANCHOR_MEMORIES
        or shortCount > Social.MAX_SHORT_MEMORIES
        or longCount > Social.MAX_LONG_MEMORIES
    then
        return false, "memory_bank_bucket_limit_exceeded"
    end
    for key, relationship in pairs(state.relationships) do
        if targetKey(key) ~= key or type(relationship) ~= "table" then
            return false, "relationship_target_invalid"
        end
        if relationship.memories ~= nil then
            return false, "relationship_memories_forbidden"
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

local function memoryMatchesTarget(mem, normalized, includeSubject, includeSource, includeRoles)
    if type(mem) ~= "table" then return false end
    if mem.aboutKey == normalized then return true end
    if includeSubject and mem.subjectKey == normalized then return true end
    if includeSource and mem.sourceKey == normalized then return true end
    if includeRoles and type(mem.roleRefs) == "table" then
        for _, roleEntry in pairs(mem.roleRefs) do
            if type(roleEntry) == "table" and roleEntry.ref == normalized then
                return true
            end
        end
    end
    return false
end

function Social.GetMemoriesForTarget(state, target, options)
    if type(state) ~= "table" then return {} end
    local _, normalized = lookupRelationshipRef(state, target)
    if not normalized then return {} end
    options = type(options) == "table" and options or {}
    local includeSubject = options.includeSubject == true or options.includeAllRoles == true
    local includeSource = options.includeSource == true or options.includeAllRoles == true
    local includeRoles = options.includeRoleRefs == true or options.includeAllRoles == true
    local out = {}
    if not includeSubject and not includeSource and not includeRoles then
        local index = getMemoryIndex(state)
        local list = index.byTarget[normalized] or {}
        for i = 1, #list do
            out[i] = Util.clone(list[i])
        end
        return out
    end
    for i = 1, #(state.memoryBank or {}) do
        local mem = state.memoryBank[i]
        if memoryMatchesTarget(mem, normalized, includeSubject, includeSource, includeRoles) then
            out[#out + 1] = Util.clone(mem)
        end
    end
    return out
end

function Social.GetMemoriesByClass(state, retentionClass)
    if type(state) ~= "table" then return {} end
    local cls = Retention.NormalizeClass(retentionClass, false)
    if not cls or cls == Retention.SCENE then return {} end
    local index = getMemoryIndex(state)
    local list = index.byClass[cls] or {}
    local out = {}
    for i = 1, #list do
        out[i] = Util.clone(list[i])
    end
    return out
end

function Social.GetMemoriesByEvent(state, eventType)
    if type(state) ~= "table" or type(eventType) ~= "string" or eventType == "" then
        return {}
    end
    local index = getMemoryIndex(state)
    local list = index.byEvent[eventType] or {}
    local out = {}
    for i = 1, #list do
        out[i] = Util.clone(list[i])
    end
    return out
end

function Social.GetActorMemoryStats(state)
    if type(state) ~= "table" then return nil, "state_required" end
    local bank = state.memoryBank or {}
    local byClass = { ANCHOR = 0, LONG = 0, SHORT = 0 }
    local byRefStrength = { STRONG = 0, WEAK = 0, LABEL_ONLY = 0 }
    for i = 1, #bank do
        local mem = bank[i]
        if type(mem) == "table" then
            local cls = Retention.EffectiveClass(mem)
            if byClass[cls] ~= nil then
                byClass[cls] = byClass[cls] + 1
            end
            local rs = Retention.NormalizeRefStrength(mem.refStrength,
                cls == Retention.ANCHOR and Retention.REF_STRONG or Retention.REF_WEAK)
            byRefStrength[rs] = (byRefStrength[rs] or 0) + 1
        end
    end
    local relCount = 0
    for _ in pairs(state.relationships or {}) do
        relCount = relCount + 1
    end
    return {
        total = #bank,
        maxTotal = Social.MAX_ACTOR_MEMORIES,
        byClass = byClass,
        byRefStrength = byRefStrength,
        relationshipCount = relCount,
    }
end

local function hasSignificantExtension(extensions)
    if type(extensions) ~= "table" then return false end
    local hoomans = extensions.ProjectHoomans
    if type(hoomans) == "table" and type(hoomans.bond) == "table" then
        local cls = hoomans.bond.class
        if type(cls) == "string" and cls ~= "" and cls ~= "none" then
            return true
        end
    end
    for extID, extVal in pairs(extensions) do
        if type(extVal) == "table" then
            if extID ~= "ProjectHoomans" then
                for _ in pairs(extVal) do
                    return true
                end
            else
                if hoomans.bond ~= nil and hoomans.bond.class ~= nil and hoomans.bond.class ~= "none" then
                    return true
                end
                if type(hoomans.interactionJournal) == "table" and #hoomans.interactionJournal > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function Social.IsSignificantEdge(state, target, rel, options)
    if type(rel) ~= "table" then return false end
    options = type(options) == "table" and options or {}
    if rel.historicalPin == true then return true, "historical_pin" end
    if math.abs(tonumber(rel.approval) or 0) > 0
        or math.abs(tonumber(rel.respect) or 0) > 0
        or (tonumber(rel.baselineApproval) or 0) ~= 0
        or (tonumber(rel.baselineRespect) or 0) ~= 0
    then
        return true, "score_delta"
    end
    local minFam = tonumber(options.minSignificantFamiliarity) or 10
    if (tonumber(rel.familiarity) or 0) >= minFam then
        return true, "familiarity"
    end
    if hasSignificantExtension(rel.extensions) then
        return true, "extension"
    end
    local normalized = targetKey(target) or rel.targetKey
    if type(state) == "table" and normalized then
        for i = 1, #(state.memoryBank or {}) do
            local mem = state.memoryBank[i]
            if memoryMatchesTarget(mem, normalized, true, true, true) then
                return true, "memory_bank_ref"
            end
        end
    end
    return false
end

function Social.CompactHistoricalEdge(state, target, tombstoneOrInfo)
    if type(state) ~= "table" then return nil, "state_required" end
    local rel, normalized = lookupRelationshipRef(state, target)
    if not normalized then return nil, "target_key_invalid" end
    if not rel then return nil, "relationship_not_found" end
    local info = type(tombstoneOrInfo) == "table" and tombstoneOrInfo or {}
    rel.historical = true
    rel.targetLifecycleStatus = info.lifecycleStatus or info.status or rel.targetLifecycleStatus or "TOMBSTONE"
    if tonumber(info.lifecycleRevision) ~= nil then
        rel.targetLifecycleRevision = math.max(0, math.floor(tonumber(info.lifecycleRevision)))
    end
    local label = info.displayLabel or info.historicalLabel
    if type(label) == "string" and label ~= "" then
        rel.historicalLabel = string.sub(label, 1, 64)
    end
    local role = info.kind or info.historicalRole
    if type(role) == "string" and role ~= "" then
        rel.historicalRole = string.sub(role, 1, 32)
    end
    local reason = info.reasonClass or info.historicalReason
    if type(reason) == "string" and reason ~= "" then
        rel.historicalReason = string.sub(reason, 1, 48)
    end
    if tonumber(info.retiredAt) ~= nil then
        rel.retiredAt = tonumber(info.retiredAt)
    end
    -- Strip runtime throttling chatter on dead targets; durable consequences survive.
    rel.cooldowns = nil
    rel.saturation = nil
    rel.memories = nil
    rel.revision = (tonumber(rel.revision) or 0) + 1
    state.revision = (tonumber(state.revision) or 0) + 1
    Social.InvalidateMemoryIndex(state)
    return Util.clone(rel)
end

function Social.PruneDefaultEdges(state, options)
    if type(state) ~= "table" or type(state.relationships) ~= "table" then
        return 0
    end
    options = type(options) == "table" and options or {}
    local targetSet = nil
    if type(options.targets) == "table" then
        targetSet = {}
        for _, t in ipairs(options.targets) do
            targetSet[t] = true
        end
    end
    local keys = {}
    for k in pairs(state.relationships) do
        if not targetSet or targetSet[k] then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys)
    local removed = 0
    for i = 1, #keys do
        local k = keys[i]
        local rel = state.relationships[k]
        if not Social.IsSignificantEdge(state, k, rel, options) then
            state.relationships[k] = nil
            removed = removed + 1
        end
    end
    if removed > 0 then
        state.revision = (tonumber(state.revision) or 0) + 1
        Social.InvalidateMemoryIndex(state)
    end
    return removed
end

function Social.RemoveMemory(state, memoryID, authority)
    if authority ~= "server" then return nil, "server_authority_required" end
    if type(state) ~= "table" or type(memoryID) ~= "string" or memoryID == "" then
        return nil, "memory_id_required"
    end
    local bank = state.memoryBank or {}
    local removed = false
    for idx = #bank, 1, -1 do
        if bank[idx].id == memoryID then
            table.remove(bank, idx)
            removed = true
        end
    end
    if not removed then
        return nil, "memory_not_found"
    end
    state.revision = (tonumber(state.revision) or 0) + 1
    Social.InvalidateMemoryIndex(state)
    return true
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
    if sourceRel.historical == true then targetRel.historical = true end
    if sourceRel.historicalPin == true then targetRel.historicalPin = true end

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
    targetRel.memories = nil
    return targetRel
end

local function cloneRelationshipWithMemories(state, relationship, normalized, options)
    local out = Util.clone(relationship)
    out.memories = nil
    if not (options and options.includeMemories == false) then
        out.memories = Social.GetMemoriesForTarget(state, normalized)
    end
    return out
end

function Social.GetRelationshipSummary(state, target)
    return Social.Get(state, target, { includeMemories = false })
end

function Social.Get(state, target, options)
    local relationship, normalized = lookupRelationshipRef(state, target)
    if not normalized then return nil, "target_key_invalid" end
    if not relationship then return nil, "relationship_not_found" end
    return cloneRelationshipWithMemories(state, relationship, normalized, options)
end

function Social.GetHotRelationshipSnapshot(state, target, options)
    if type(state) ~= "table" then return nil, "state_required" end
    local relationship, normalized = lookupRelationshipRef(state, target)
    if not normalized then return nil, "target_key_invalid" end
    options = type(options) == "table" and options or {}
    local maxMems = math.max(0, math.min(16, math.floor(tonumber(options.maxMemories) or 4)))
    local socialRev = tonumber(state.revision) or 0
    local identityProj = (type(options.registry) == "table"
        and type(options.registry.ProjectIdentity) == "function")
        and options.registry:ProjectIdentity(normalized) or nil
    if not relationship then
        return {
            exists = false,
            targetKey = normalized,
            approval = 0,
            respect = 0,
            familiarity = 0,
            state = "unknown",
            attitude = "neutral",
            revision = 0,
            relationshipRevision = 0,
            socialRevision = socialRev,
            historical = false,
            historicalPin = false,
            targetLifecycleStatus = identityProj and identityProj.status or nil,
            targetLifecycleRevision = identityProj and identityProj.lifecycleRevision or nil,
            targetDisplayName = (identityProj and identityProj.status ~= "FORGOTTEN")
                and identityProj.displayName or nil,
            memoryCount = 0,
            strongMemoryCount = 0,
            recentMemories = {},
        }
    end
    local memories = Social.GetMemoriesForTarget(state, normalized)
    local strongCount = 0
    for i = 1, #memories do
        if memories[i].refStrength == Retention.REF_STRONG then
            strongCount = strongCount + 1
        end
    end
    local recent = {}
    local startIdx = math.max(1, #memories - maxMems + 1)
    for i = #memories, startIdx, -1 do
        local m = memories[i]
        recent[#recent + 1] = {
            id = m.id,
            type = m.type,
            retentionClass = Retention.EffectiveClass(m),
            refStrength = m.refStrength,
            aboutKey = m.aboutKey,
            subjectKey = m.subjectKey,
            degradedLabel = m.degradedLabel,
            salience = Retention.MemorySalience(m),
            createdAt = m.createdAt,
            count = m.count or 1,
        }
    end
    local approvalVal = tonumber(relationship.approval) or 0
    local respectVal = tonumber(relationship.respect) or 0
    local relRev = tonumber(relationship.revision) or 0
    local resolvedStatus = (identityProj and identityProj.status)
        or relationship.targetLifecycleStatus
    local resolvedLabel = relationship.degradedLabel or relationship.historicalLabel
    return {
        exists = true,
        targetKey = normalized,
        approval = approvalVal,
        respect = respectVal,
        familiarity = tonumber(relationship.familiarity) or 0,
        state = relationship.state or Projections.ResolveState(relationship),
        attitude = Projections.ResolveAttitude(approvalVal, respectVal),
        revision = relRev,
        relationshipRevision = relRev,
        socialRevision = socialRev,
        historical = relationship.historical == true,
        historicalPin = relationship.historicalPin == true,
        targetLifecycleStatus = resolvedStatus,
        targetLifecycleRevision = (identityProj and identityProj.lifecycleRevision)
            or relationship.targetLifecycleRevision,
        targetDisplayName = (identityProj and identityProj.status ~= "FORGOTTEN"
            and identityProj.displayName) or relationship.historicalLabel,
        degradedLabel = resolvedStatus == "FORGOTTEN"
            and (resolvedLabel or "someone") or nil,
        historicalLabel = relationship.historicalLabel,
        memoryCount = #memories,
        strongMemoryCount = strongCount,
        recentMemories = recent,
    }
end

function Social.GetOrCreate(state, target)
    local normalized = resolveTargetKey(target)
    if not normalized then return nil, "target_key_invalid" end
    if state and state.aliases and state.aliases[normalized] then
        normalized = state.aliases[normalized]
    end
    state.relationships = state.relationships or {}
    state.memoryBank = state.memoryBank or {}
    if not state.relationships[normalized] then
        state.relationships[normalized] = {
            targetKey = normalized,
            approval = 0,
            respect = 0,
            familiarity = 0,
            revision = 0,
            extensions = {},
        }
    else
        state.relationships[normalized].extensions =
            state.relationships[normalized].extensions or {}
        state.relationships[normalized].memories = nil
    end
    return state.relationships[normalized]
end

local function rewriteMemoryTargetAlias(mem, normalizedAlias, normalizedCanonical)
    local changed = false
    if mem.aboutKey == normalizedAlias then
        mem.aboutKey = normalizedCanonical
        changed = true
    end
    if mem.subjectKey == normalizedAlias then
        mem.subjectKey = normalizedCanonical
        changed = true
    end
    if mem.sourceKey == normalizedAlias then
        mem.sourceKey = normalizedCanonical
        changed = true
    end
    if type(mem.roleRefs) == "table" then
        for _, entry in pairs(mem.roleRefs) do
            if type(entry) == "table" and entry.ref == normalizedAlias then
                entry.ref = normalizedCanonical
                changed = true
            end
        end
    end
    return changed
end

function Social.MigrateAliases(state, canonicalKey, aliasKeys)
    if type(state) ~= "table" then return nil, "state_required" end
    local normalizedCanonical = resolveTargetKey(canonicalKey)
    if not normalizedCanonical then return nil, "canonical_key_invalid" end
    if type(aliasKeys) ~= "table" then return true end

    state.aliases = state.aliases or {}
    state.relationships = state.relationships or {}
    state.memoryBank = state.memoryBank or {}

    local mergedAny = false
    for _, alias in ipairs(aliasKeys) do
        local normalizedAlias = resolveTargetKey(alias)
        if normalizedAlias and normalizedAlias ~= normalizedCanonical then
            state.aliases[normalizedAlias] = normalizedCanonical
            for _, mem in ipairs(state.memoryBank) do
                if rewriteMemoryTargetAlias(mem, normalizedAlias, normalizedCanonical) then
                    mergedAny = true
                end
            end
            local legacyRel = state.relationships[normalizedAlias]
            if legacyRel then
                local canonicalRel = Social.GetOrCreate(state, normalizedCanonical)
                mergeRelationshipData(canonicalRel, legacyRel)
                if type(legacyRel.memories) == "table" then
                    local existingIDs = {}
                    for _, em in ipairs(state.memoryBank) do
                        if em.id then existingIDs[em.id] = true end
                    end
                    for _, lm in ipairs(legacyRel.memories) do
                        local copied = copyMemory(lm, normalizedCanonical)
                        if copied and not existingIDs[copied.id] then
                            existingIDs[copied.id] = true
                            Retention.ConsolidateOrInsertMemory(state, copied, { consolidate = true })
                        end
                    end
                end
                state.relationships[normalizedAlias] = nil
                mergedAny = true
            end
        end
    end
    if mergedAny then
        state.revision = (tonumber(state.revision) or 0) + 1
        Social.InvalidateMemoryIndex(state)
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
    cloneRel.memories = Social.GetMemoriesForTarget(state, normalized)
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
    if mutated.historical ~= nil then
        rel.historical = mutated.historical == true and true or nil
    end
    if mutated.historicalPin ~= nil then
        rel.historicalPin = mutated.historicalPin == true and true or nil
    end
    if type(mutated.targetLifecycleStatus) == "string" and mutated.targetLifecycleStatus ~= "" then
        rel.targetLifecycleStatus = mutated.targetLifecycleStatus
    end
    if tonumber(mutated.targetLifecycleRevision) ~= nil then
        rel.targetLifecycleRevision = math.max(0, math.floor(tonumber(mutated.targetLifecycleRevision)))
    end

    local existingMemories = {}
    for _, m in ipairs(state.memoryBank or {}) do
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
                Retention.ConsolidateOrInsertMemory(state, normalizedMem, { consolidate = false })
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

    rel.memories = nil
    rel.revision = (tonumber(rel.revision) or 0) + 1
    state.revision = (tonumber(state.revision) or 0) + 1
    Social.InvalidateMemoryIndex(state)
    return cloneRelationshipWithMemories(state, rel, normalized)
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
    Retention.PruneMemories(state, worldAgeHours, options)
    Social.InvalidateMemoryIndex(state)

    local usesBaselines = rel.baselineApproval ~= nil or rel.baselineRespect ~= nil
        or options.recalculateFromBaselines == true
    if usesBaselines then
        local app = tonumber(rel.baselineApproval) or 0
        local resp = tonumber(rel.baselineRespect) or 0
        for _, mem in ipairs(state.memoryBank or {}) do
            if mem.aboutKey == normalized then
                local str = Retention.CalculateMemoryStrength(mem, worldAgeHours)
                app = app + ((tonumber(mem.approvalEffect) or 0) * str)
                resp = resp + ((tonumber(mem.respectEffect) or 0) * str)
            end
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
    return cloneRelationshipWithMemories(state, rel, normalized, options)
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

    local rawRefStrength = event.refStrength
    if rawRefStrength == nil and policy and policy.refStrength ~= nil then
        rawRefStrength = policy.refStrength
    end
    local resolvedRefStrength
    if rawRefStrength ~= nil then
        local upper = type(rawRefStrength) == "string" and string.upper(rawRefStrength) or ""
        if not Retention.VALID_REF_STRENGTHS[upper] then
            return nil, "ref_strength_invalid"
        end
        resolvedRefStrength = upper
    else
        resolvedRefStrength = (retentionClass == Retention.ANCHOR or isPermanent)
            and Retention.REF_STRONG or Retention.REF_WEAK
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
        refStrength = resolvedRefStrength,
        createdAt = eventTime,
        approvalEffect = appDelta,
        respectEffect = respDelta,
        familiarityEffect = famDelta,
        tags = Util.clone(event.tags or {}),
    }
    if event.subjectKey ~= nil then
        memorySpec.subjectKey = resolveTargetKey(event.subjectKey)
    end
    if event.roleRefs ~= nil then
        memorySpec.roleRefs = normalizeRoleRefs(event.roleRefs)
    end
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
    local rawSrcRefStrength = event.sourceRefStrength or (policy and policy.sourceRefStrength)
    if rawSrcRefStrength ~= nil then
        memorySpec.sourceRefStrength = Retention.NormalizeRefStrength(rawSrcRefStrength)
    end
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

    local memResult = Retention.ConsolidateOrInsertMemory(state, memorySpec, insertOpts)
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
    Social.InvalidateMemoryIndex(state)
    return Util.clone(state)
end

Social.CalculateMemoryStrength = Retention.CalculateMemoryStrength
Social.PruneMemories = Retention.PruneMemories
Social.ConsolidateOrInsertMemory = Retention.ConsolidateOrInsertMemory
Social.ApplyPersonalityModulation = Retention.ApplyPersonalityModulation
Social.NextMemorySequence = Retention.NextMemorySequence
Social.NormalizeRefStrength = Retention.NormalizeRefStrength
Social.ResolveState = Projections.ResolveState
Social.ResolveAttitude = Projections.ResolveAttitude

function Social.QueryCandidateProjection(state, target, options)
    return Projections.QueryCandidateProjection(
        state,
        target,
        options,
        lookupRelationshipRef,
        Social.GetMemoriesForTarget
    )
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
