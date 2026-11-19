local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Retention = {}

Retention.SCENE = "SCENE"
Retention.SHORT = "SHORT"
Retention.LONG = "LONG"
Retention.ANCHOR = "ANCHOR"

Retention.MAX_MEMORIES = 64
Retention.MAX_SHORT_MEMORIES = 16
Retention.MAX_LONG_MEMORIES = 42
Retention.MAX_ANCHOR_MEMORIES = 6
Retention.ANCHOR_MIN_SALIENCE = 180
Retention.DEFAULT_SALIENCE = 100

Retention.VALID_CLASSES = {
    SCENE = true,
    SHORT = true,
    LONG = true,
    ANCHOR = true,
}

Retention.DEFAULT_DECAY = {
    SCENE = 0,
    SHORT = 1.0,
    LONG = 0.05,
    ANCHOR = 0,
}

local function clamp(value, low, high)
    value = tonumber(value) or low
    if value ~= value or value == math.huge or value == -math.huge then
        return low
    end
    return math.max(low, math.min(high, value))
end

function Retention.NormalizeClass(value, permanent)
    if type(value) == "string" then
        local upper = string.upper(value)
        if Retention.VALID_CLASSES[upper] then
            return upper
        end
    end
    if permanent == true then
        return Retention.ANCHOR
    end
    return nil
end

function Retention.EffectiveClass(memory)
    if type(memory) ~= "table" then return Retention.LONG end
    local explicit = Retention.NormalizeClass(memory.retentionClass, memory.permanent)
    if explicit then return explicit end
    local decay = tonumber(memory.decayPerDay) or 0
    if decay >= 0.5 then return Retention.SHORT end
    return Retention.LONG
end

function Retention.NormalizeSourceMode(sourceMode, knowledgeSource)
    local raw = type(sourceMode) == "string" and string.lower(sourceMode) or nil
    if raw == "direct" or raw == "experienced" then return "direct" end
    if raw == "witnessed" or raw == "witness" then return "witnessed" end
    if raw == "hearsay" or raw == "gossip" then return "hearsay" end
    if raw == "system" or raw == "inferred" then return "system" end
    local ks = type(knowledgeSource) == "string" and string.lower(knowledgeSource) or nil
    if ks == "experienced" or ks == "direct" then return "direct" end
    if ks == "witnessed" then return "witnessed" end
    if ks == "told_by_trusted_person" or ks == "told_by_stranger"
        or ks == "community_rumor" or ks == "hearsay"
    then
        return "hearsay"
    end
    if ks == "inferred" or ks == "system" then return "system" end
    return "direct"
end

function Retention.DefaultConfidence(sourceMode, knowledgeSource)
    local ks = type(knowledgeSource) == "string" and string.lower(knowledgeSource) or ""
    if ks == "told_by_trusted_person" then return 0.75 end
    if ks == "community_rumor" then return 0.45 end
    if ks == "told_by_stranger" then return 0.55 end
    local mode = Retention.NormalizeSourceMode(sourceMode, knowledgeSource)
    if mode == "hearsay" then return 0.6 end
    return 1.0
end

function Retention.MemorySalience(memory)
    if type(memory) ~= "table" then return Retention.DEFAULT_SALIENCE end
    local s = tonumber(memory.salience)
    if s ~= nil then
        return math.floor(clamp(s, 0, 255))
    end
    if memory.permanent == true or memory.retentionClass == Retention.ANCHOR then
        return 200
    end
    return Retention.DEFAULT_SALIENCE
end

function Retention.CalculateMemoryStrength(memory, worldAgeHours)
    if type(memory) ~= "table" then return 0 end
    local cls = Retention.EffectiveClass(memory)
    local strength = clamp(memory.strength ~= nil and memory.strength or 1, 0, 1)
    local createdAt = tonumber(memory.createdAt) or 0
    if cls == Retention.SCENE then
        if worldAgeHours == nil or tonumber(worldAgeHours) <= createdAt then
            return strength
        end
        return 0
    end
    if cls == Retention.ANCHOR or memory.permanent == true then
        return strength
    end
    if worldAgeHours == nil then
        return strength
    end
    local decay = tonumber(memory.decayPerDay)
    if decay == nil then
        decay = Retention.DEFAULT_DECAY[cls] or 0.05
    end
    if decay <= 0 then return strength end
    local elapsedDays = math.max(0, (tonumber(worldAgeHours) - createdAt) / 24)
    return math.max(0, strength - (decay * elapsedDays))
end

function Retention.NextMemorySequence(relationship)
    local memories = relationship and relationship.memories or {}
    local seq = math.max(tonumber(relationship and relationship.revision) or 0, #memories)
    for index = 1, #memories do
        seq = math.max(seq, tonumber(memories[index].eventSequence) or 0)
    end
    return math.min(2147483646, seq + 1)
end

function Retention.ApplyPersonalityModulation(personality, event, policy)
    local app = tonumber(event and event.approvalDelta) or 0
    local resp = tonumber(event and event.respectDelta) or 0
    local fam = tonumber(event and event.familiarityDelta) or 0
    local decay = event and event.decayPerDay or (policy and policy.decayPerDay)
    local salience = event and event.salience or (policy and policy.salience)
    local enabled = (event and event.applyPersonality == true)
        or (policy and policy.personalityModulation == true)
    if not enabled or type(personality) ~= "table" then
        return {
            approvalDelta = app,
            respectDelta = resp,
            familiarityDelta = fam,
            decayPerDay = decay,
            salience = salience,
        }
    end
    local forgiveness = clamp(personality.forgiveness ~= nil and personality.forgiveness or 0.5, 0, 1)
    local sociability = clamp(personality.sociability ~= nil and personality.sociability or 0.5, 0, 1)
    local greed = clamp(personality.greed ~= nil and personality.greed or 0.5, 0, 1)
    if app < 0 then
        app = app * (1.3 - (0.6 * forgiveness))
        if decay ~= nil and tonumber(decay) > 0 then
            decay = tonumber(decay) * (0.6 + (0.8 * forgiveness))
        end
    elseif app > 0 then
        local mult = 0.8 + (0.4 * sociability)
        if type(event and event.tags) == "table" and event.tags.trade then
            mult = mult * (0.85 + (0.3 * (1 - greed)))
        end
        app = app * mult
    end
    if fam > 0 then
        fam = fam * (0.8 + (0.4 * sociability))
    end
    return {
        approvalDelta = app,
        respectDelta = resp,
        familiarityDelta = fam,
        decayPerDay = decay,
        salience = salience,
    }
end

local function memoryRankLess(left, right, worldAgeHours)
    local lStr = Retention.CalculateMemoryStrength(left, worldAgeHours)
    local rStr = Retention.CalculateMemoryStrength(right, worldAgeHours)
    local lSal = Retention.MemorySalience(left)
    local rSal = Retention.MemorySalience(right)
    local lScore = lStr * (lSal / 100)
    local rScore = rStr * (rSal / 100)
    if lScore ~= rScore then return lScore < rScore end
    local lMag = math.abs(tonumber(left.approvalEffect) or 0) + math.abs(tonumber(left.respectEffect) or 0)
    local rMag = math.abs(tonumber(right.approvalEffect) or 0) + math.abs(tonumber(right.respectEffect) or 0)
    if lMag ~= rMag then return lMag < rMag end
    local lCreated = tonumber(left.createdAt) or 0
    local rCreated = tonumber(right.createdAt) or 0
    if lCreated ~= rCreated then return lCreated < rCreated end
    local lSeq = tonumber(left.eventSequence) or 0
    local rSeq = tonumber(right.eventSequence) or 0
    if lSeq ~= rSeq then return lSeq < rSeq end
    return tostring(left.id or "") < tostring(right.id or "")
end

local function promoteToBaseline(relationship, memory, worldAgeHours)
    local str = Retention.CalculateMemoryStrength(memory, worldAgeHours)
    if str <= 0 then return end
    local appEff = (tonumber(memory.approvalEffect) or 0) * str
    local respEff = (tonumber(memory.respectEffect) or 0) * str
    if appEff ~= 0 or relationship.baselineApproval ~= nil then
        relationship.baselineApproval = clamp((tonumber(relationship.baselineApproval) or 0) + appEff, -100, 100)
    end
    if respEff ~= 0 or relationship.baselineRespect ~= nil then
        relationship.baselineRespect = clamp((tonumber(relationship.baselineRespect) or 0) + respEff, -100, 100)
    end
end

function Retention.PruneMemories(relationship, worldAgeHours, options)
    if type(relationship) ~= "table" then return 0, 0 end
    options = type(options) == "table" and options or {}
    local maxTotal = math.floor(clamp(options.maxMemories or Retention.MAX_MEMORIES, 1, Retention.MAX_MEMORIES))
    local maxAnchors = math.floor(clamp(options.maxAnchors or Retention.MAX_ANCHOR_MEMORIES, 1, Retention.MAX_ANCHOR_MEMORIES))
    local maxShort = math.floor(clamp(options.maxShort or Retention.MAX_SHORT_MEMORIES, 1, Retention.MAX_SHORT_MEMORIES))
    local maxLong = math.floor(clamp(options.maxLong or Retention.MAX_LONG_MEMORIES, 1, Retention.MAX_LONG_MEMORIES))
    local promote = options.promoteEvictedToBaseline ~= false
    local demoteAnchors = options.demoteOverflowAnchors ~= false

    local expiredCount, evictedCount = 0, 0
    local anchors, shorts, longs = {}, {}, {}
    for _, mem in ipairs(relationship.memories or {}) do
        local cls = Retention.EffectiveClass(mem)
        local str = Retention.CalculateMemoryStrength(mem, worldAgeHours)
        if cls == Retention.SCENE or (worldAgeHours ~= nil and cls ~= Retention.ANCHOR and str <= 0) then
            expiredCount = expiredCount + 1
        elseif cls == Retention.ANCHOR then
            anchors[#anchors + 1] = mem
        elseif cls == Retention.SHORT then
            shorts[#shorts + 1] = mem
        else
            longs[#longs + 1] = mem
        end
    end

    if #anchors > maxAnchors then
        table.sort(anchors, function(a, b) return memoryRankLess(a, b, worldAgeHours) end)
        local overflow = #anchors - maxAnchors
        local keptAnchors = {}
        for idx = 1, #anchors do
            if idx <= overflow then
                local demoted = anchors[idx]
                if demoteAnchors then
                    demoted.retentionClass = Retention.LONG
                    demoted.permanent = false
                    demoted.decayPerDay = Retention.DEFAULT_DECAY.LONG
                    longs[#longs + 1] = demoted
                else
                    evictedCount = evictedCount + 1
                    if promote then promoteToBaseline(relationship, demoted, worldAgeHours) end
                end
            else
                keptAnchors[#keptAnchors + 1] = anchors[idx]
            end
        end
        anchors = keptAnchors
    end

    local function trimBucket(bucket, cap)
        if #bucket <= cap then return bucket end
        table.sort(bucket, function(a, b) return memoryRankLess(a, b, worldAgeHours) end)
        local drop = #bucket - cap
        local kept = {}
        for idx = 1, #bucket do
            if idx <= drop then
                evictedCount = evictedCount + 1
                if promote then promoteToBaseline(relationship, bucket[idx], worldAgeHours) end
            else
                kept[#kept + 1] = bucket[idx]
            end
        end
        return kept
    end

    shorts = trimBucket(shorts, maxShort)
    longs = trimBucket(longs, maxLong)

    local combined = {}
    for _, m in ipairs(anchors) do combined[#combined + 1] = m end
    for _, m in ipairs(shorts) do combined[#combined + 1] = m end
    for _, m in ipairs(longs) do combined[#combined + 1] = m end

    if #combined > maxTotal then
        local nonAnchors = {}
        for _, m in ipairs(shorts) do nonAnchors[#nonAnchors + 1] = m end
        for _, m in ipairs(longs) do nonAnchors[#nonAnchors + 1] = m end
        table.sort(nonAnchors, function(a, b) return memoryRankLess(a, b, worldAgeHours) end)
        local needDrop = #combined - maxTotal
        local dropSet = {}
        for idx = 1, math.min(needDrop, #nonAnchors) do
            dropSet[nonAnchors[idx]] = true
            evictedCount = evictedCount + 1
            if promote then promoteToBaseline(relationship, nonAnchors[idx], worldAgeHours) end
        end
        local nextCombined = {}
        for _, m in ipairs(anchors) do nextCombined[#nextCombined + 1] = m end
        for _, m in ipairs(nonAnchors) do
            if not dropSet[m] then nextCombined[#nextCombined + 1] = m end
        end
        if #nextCombined > maxTotal then
            nextCombined = trimBucket(nextCombined, maxTotal)
        end
        combined = nextCombined
    end

    table.sort(combined, function(a, b)
        local aTime = tonumber(a.createdAt) or 0
        local bTime = tonumber(b.createdAt) or 0
        if aTime ~= bTime then return aTime < bTime end
        local aSeq = tonumber(a.eventSequence) or 0
        local bSeq = tonumber(b.eventSequence) or 0
        if aSeq ~= bSeq then return aSeq < bSeq end
        return tostring(a.id or "") < tostring(b.id or "")
    end)
    relationship.memories = combined
    return expiredCount, evictedCount
end

local function clampDeltaForCap(currentEffect, delta, maxCap)
    if maxCap == nil then return delta end
    local cap = math.abs(tonumber(maxCap) or 0)
    if cap <= 0 then return 0 end
    local nextTotal = clamp((tonumber(currentEffect) or 0) + delta, -cap, cap)
    return nextTotal - (tonumber(currentEffect) or 0), nextTotal
end

function Retention.ConsolidateOrInsertMemory(relationship, memory, options)
    if type(relationship) ~= "table" or type(memory) ~= "table" then
        return { status = "invalid" }
    end
    options = type(options) == "table" and options or {}
    local cls = Retention.EffectiveClass(memory)
    if cls == Retention.SCENE then
        return { status = "scene_ephemeral", memory = memory }
    end

    relationship.memories = relationship.memories or {}
    local consolKey = memory.consolidationKey
    if (type(consolKey) ~= "string" or consolKey == "")
        and type(memory.consolidationFamily) == "string" and memory.consolidationFamily ~= ""
    then
        consolKey = memory.consolidationFamily .. ":" .. tostring(memory.aboutKey or "")
            .. ":" .. tostring(Retention.NormalizeSourceMode(memory.sourceMode, memory.knowledgeSource))
    end

    if type(consolKey) == "string" and consolKey ~= "" and options.consolidate ~= false then
        for idx = #relationship.memories, 1, -1 do
            local existing = relationship.memories[idx]
            if existing.consolidationKey == consolKey and Retention.EffectiveClass(existing) == cls then
                if options.worldAgeHours ~= nil and cls ~= Retention.ANCHOR
                    and Retention.CalculateMemoryStrength(existing, options.worldAgeHours) <= 0
                then
                    table.remove(relationship.memories, idx)
                    break
                end
                local appDelta = tonumber(memory.approvalEffect) or 0
                local respDelta = tonumber(memory.respectEffect) or 0
                local famDelta = tonumber(memory.familiarityEffect) or 0
                local nextApp, nextResp, nextFam
                appDelta, nextApp = clampDeltaForCap(existing.approvalEffect, appDelta, options.maxConsolidatedApproval)
                respDelta, nextResp = clampDeltaForCap(existing.respectEffect, respDelta, options.maxConsolidatedRespect)
                famDelta, nextFam = clampDeltaForCap(existing.familiarityEffect, famDelta, options.maxConsolidatedFamiliarity)

                existing.count = (tonumber(existing.count) or 1) + (tonumber(memory.count) or 1)
                existing.firstCreatedAt = existing.firstCreatedAt or existing.createdAt or memory.createdAt
                local incomingAt = tonumber(memory.createdAt)
                if incomingAt ~= nil then
                    existing.createdAt = math.max(tonumber(existing.createdAt) or incomingAt, incomingAt)
                end
                existing.lastEventID = memory.id
                existing.eventSequence = Retention.NextMemorySequence(relationship)
                existing.approvalEffect = nextApp ~= nil and nextApp or ((tonumber(existing.approvalEffect) or 0) + appDelta)
                existing.respectEffect = nextResp ~= nil and nextResp or ((tonumber(existing.respectEffect) or 0) + respDelta)
                existing.familiarityEffect = nextFam ~= nil and nextFam or ((tonumber(existing.familiarityEffect) or 0) + famDelta)
                existing.strength = math.max(tonumber(existing.strength) or 1, tonumber(memory.strength) or 1)
                existing.salience = math.max(Retention.MemorySalience(existing), Retention.MemorySalience(memory))
                if type(memory.tags) == "table" then
                    existing.tags = existing.tags or {}
                    for tk, tv in pairs(memory.tags) do
                        existing.tags[tk] = Util.clone(tv)
                    end
                end
                return {
                    status = "consolidated",
                    memory = existing,
                    count = existing.count,
                    appliedApprovalDelta = appDelta,
                    appliedRespectDelta = respDelta,
                    appliedFamiliarityDelta = famDelta,
                }
            end
        end
    end

    local inserted = Util.clone(memory)
    if type(consolKey) == "string" and consolKey ~= "" then
        inserted.consolidationKey = consolKey
        inserted.count = tonumber(inserted.count) or 1
        inserted.firstCreatedAt = inserted.firstCreatedAt or inserted.createdAt
    end
    inserted.eventSequence = inserted.eventSequence or Retention.NextMemorySequence(relationship)
    relationship.memories[#relationship.memories + 1] = inserted
    Retention.PruneMemories(relationship, options.worldAgeHours, options)
    return {
        status = "inserted",
        memory = inserted,
        appliedApprovalDelta = tonumber(inserted.approvalEffect) or 0,
        appliedRespectDelta = tonumber(inserted.respectEffect) or 0,
        appliedFamiliarityDelta = tonumber(inserted.familiarityEffect) or 0,
    }
end

return Retention
