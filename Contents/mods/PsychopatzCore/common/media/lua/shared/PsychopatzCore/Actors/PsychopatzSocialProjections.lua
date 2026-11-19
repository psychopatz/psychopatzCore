local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Retention = require "PsychopatzCore/Actors/PsychopatzSocialRetention"

local Projections = {}

local function clamp(value, low, high)
    value = tonumber(value) or low
    if value ~= value or value == math.huge or value == -math.huge then
        return low
    end
    return math.max(low, math.min(high, value))
end

function Projections.ResolveState(relationship)
    if type(relationship) ~= "table" then return "unknown" end
    local app = tonumber(relationship.approval) or 0
    local resp = tonumber(relationship.respect) or 0
    local fam = tonumber(relationship.familiarity) or 0
    local current = tostring(relationship.state or "unknown")
    if fam <= 0 and app == 0 and resp == 0 and current == "unknown" then
        return "unknown"
    end
    if app <= -50 or (app <= -35 and resp <= -20) or (current == "enemy" and app < -25) then
        return "enemy"
    end
    if (app <= -15 and resp >= -10) or (current == "rival" and app < -5) then
        return "rival"
    end
    if (app >= 45 and fam >= 20) or (current == "friend" and app >= 25 and fam >= 15) then
        return "friend"
    end
    return "neutral"
end

function Projections.ResolveAttitude(approval, respect)
    local app = tonumber(approval) or 0
    local resp = tonumber(respect) or 0
    if app >= 25 and resp >= 25 then return "alliance" end
    if app >= 10 and resp >= 10 then return "fondness" end
    if resp >= 20 and app <= -10 then return "fear" end
    if app <= -25 and resp <= -20 then return "hostility" end
    if resp <= -20 then return "contempt" end
    if app <= -15 then return "disliked" end
    if resp >= 15 then return "respect" end
    return "neutral"
end

local function compactMemoryView(memory, effStrength)
    return {
        id = memory.id,
        lastEventID = memory.lastEventID,
        type = memory.type or "event",
        retentionClass = Retention.EffectiveClass(memory),
        refStrength = memory.refStrength,
        aboutKey = memory.aboutKey,
        subjectKey = memory.subjectKey,
        degradedLabel = memory.degradedLabel,
        salience = Retention.MemorySalience(memory),
        effectiveStrength = effStrength,
        confidence = tonumber(memory.confidence)
            or Retention.DefaultConfidence(memory.sourceMode, memory.knowledgeSource),
        sourceMode = Retention.NormalizeSourceMode(memory.sourceMode, memory.knowledgeSource),
        sourceKey = memory.sourceKey,
        count = tonumber(memory.count) or 1,
        createdAt = memory.createdAt,
        firstCreatedAt = memory.firstCreatedAt,
        approvalEffect = tonumber(memory.approvalEffect) or 0,
        respectEffect = tonumber(memory.respectEffect) or 0,
        familiarityEffect = tonumber(memory.familiarityEffect) or 0,
        consolidationKey = memory.consolidationKey,
        shareable = memory.shareable == true,
    }
end

local function round3(value)
    value = tonumber(value) or 0
    return math.floor(value * 1000 + 0.5) / 1000
end

local PERSONALITY_DIMENSIONS = {
    "caution",
    "aggression",
    "forgiveness",
    "sociability",
    "greed",
}

local function normalizePersonality(state)
    local pers = type(state and state.personality) == "table" and state.personality or {}
    local overrides = type(state and state.personalityOverrides) == "table"
        and state.personalityOverrides or {}
    local out = {}
    for _, dim in ipairs(PERSONALITY_DIMENSIONS) do
        local raw = overrides[dim] ~= nil and overrides[dim] or pers[dim]
        if raw == nil then raw = 0.5 end
        out[dim] = round3(clamp(raw, 0, 1))
    end
    for k, v in pairs(pers) do
        if out[k] == nil and type(k) == "string" and type(v) == "number" then
            out[k] = round3(clamp(v, 0, 1))
        end
    end
    for k, v in pairs(overrides) do
        if type(k) == "string" and type(v) == "number" then
            out[k] = round3(clamp(v, 0, 1))
        end
    end
    return out
end

local function buildDecisionFeatures(params)
    local exists = params.exists == true
    local approval = tonumber(params.approval) or 0
    local respect = tonumber(params.respect) or 0
    local familiarity = tonumber(params.familiarity) or 0
    local grievance = tonumber(params.grievance) or 0
    local assistance = tonumber(params.assistance) or 0
    local directCount = tonumber(params.directCount) or 0
    local witnessedCount = tonumber(params.witnessedCount) or 0
    local hearsayCount = tonumber(params.hearsayCount) or 0
    local anchorCount = tonumber(params.anchorCount) or 0
    local activeCount = tonumber(params.activeCount) or 0
    local episodeCount = tonumber(params.episodeCount) or 0
    local relRev = tonumber(params.relationshipRevision) or 0
    local socialRev = tonumber(params.socialRevision) or 0
    local totalEvidenceCount = directCount + witnessedCount + hearsayCount

    local trustSignal = 0
    local grievancePressure = 0
    local assistanceHistory = 0
    local familiaritySignal = 0
    local cautionSignal = 0
    local provenanceConfidence = 0
    local directWitness = false
    local hearsayOnly = false

    if exists then
        trustSignal = round3(clamp(
            (approval * 0.45) + (respect * 0.35) + (familiarity * 0.20)
            + (assistance * 0.18) - (grievance * 0.65),
            -100,
            100
        ))
        grievancePressure = round3(clamp(grievance, 0, 100))
        assistanceHistory = round3(clamp(assistance, 0, 100))
        familiaritySignal = round3(clamp(familiarity, 0, 100))
        local evidenceCaution = directCount > 0 and 15 or (hearsayCount > 0 and 6 or 0)
        cautionSignal = round3(clamp(
            (grievance * 0.8) + evidenceCaution - (math.max(0, approval) * 0.15),
            0,
            100
        ))
        if totalEvidenceCount > 0 then
            provenanceConfidence = round3(clamp(
                ((directCount * 1.0) + (witnessedCount * 0.85) + (hearsayCount * 0.55))
                / totalEvidenceCount,
                0,
                1
            ))
        end
        directWitness = (directCount > 0 or witnessedCount > 0)
        hearsayOnly = (hearsayCount > 0 and directCount == 0 and witnessedCount == 0)
    end

    local personality = normalizePersonality(params.state)
    local features = {
        trustSignal = trustSignal,
        grievancePressure = grievancePressure,
        assistanceHistory = assistanceHistory,
        familiaritySignal = familiaritySignal,
        cautionSignal = cautionSignal,
        provenanceConfidence = provenanceConfidence,
        directWitness = directWitness,
        hearsayOnly = hearsayOnly,
        directEvidenceCount = directCount,
        witnessedEvidenceCount = witnessedCount,
        hearsayEvidenceCount = hearsayCount,
        anchorCount = anchorCount,
        activeMemoryCount = activeCount,
        consolidatedEpisodeCount = episodeCount,
        relationshipRevision = relRev,
        socialRevision = socialRev,
        personality = Util.clone(personality),
    }
    return {
        trustSignal = trustSignal,
        grievancePressure = grievancePressure,
        assistanceHistory = assistanceHistory,
        familiaritySignal = familiaritySignal,
        cautionSignal = cautionSignal,
        provenanceConfidence = provenanceConfidence,
        directWitness = directWitness,
        hearsayOnly = hearsayOnly,
        personality = personality,
        features = features,
    }
end

local function resolveTargetIdentity(options, rel, normalizedTarget)
    local reg = type(options) == "table" and options.registry or nil
    local proj = (type(reg) == "table" and type(reg.ProjectIdentity) == "function")
        and reg:ProjectIdentity(normalizedTarget) or nil
    local status = (proj and proj.status)
        or (type(rel) == "table" and rel.targetLifecycleStatus)
        or nil
    local rev = (proj and proj.lifecycleRevision)
        or (type(rel) == "table" and rel.targetLifecycleRevision)
        or nil
    local label = type(rel) == "table"
        and (rel.degradedLabel or rel.historicalLabel)
        or nil
    if not status then return nil end

    local referenceMode = nil
    if status == "LIVE" then
        referenceMode = "LIVE_ENTITY"
    elseif status == "RETIRED" then
        referenceMode = "HISTORICAL_NAMED"
    elseif status == "FORGOTTEN" then
        referenceMode = (type(label) == "string" and label ~= "")
            and "LABEL_ONLY" or "ANONYMOUS"
    end

    return {
        ref = (proj and proj.ref) or normalizedTarget,
        status = status,
        referenceMode = referenceMode,
        lifecycleRevision = tonumber(rev) or 0,
        displayName = status ~= "FORGOTTEN" and (proj and proj.displayName or label) or nil,
        role = proj and proj.role or (status == "FORGOTTEN" and label or nil),
        degradedLabel = status == "FORGOTTEN" and (label or "someone") or nil,
        retiredAt = status == "RETIRED" and proj and proj.retiredAt or nil,
        reason = status == "RETIRED" and proj and proj.reason or nil,
    }
end

function Projections.QueryCandidateProjection(state, target, options, lookupRelFn, getMemoriesFn)
    options = type(options) == "table" and options or {}
    local worldAgeHours = tonumber(options.worldAgeHours)
    local maxMemories = math.floor(clamp(options.maxMemories or 8, 0, 16))
    local rel, normalizedTarget = lookupRelFn(state, target)
    local socialRevision = tonumber(state and state.revision) or 0
    if not normalizedTarget then
        return nil, "target_key_invalid"
    end
    local targetIdentity = resolveTargetIdentity(options, rel, normalizedTarget)
    if not rel then
        local emptyDecision = buildDecisionFeatures({
            exists = false,
            state = state,
            relationshipRevision = 0,
            socialRevision = socialRevision,
        })
        if targetIdentity then
            emptyDecision.features.targetLifecycleStatus = targetIdentity.status
            emptyDecision.features.targetLifecycleRevision = targetIdentity.lifecycleRevision
            emptyDecision.features.historical = false
        end
        return {
            schemaVersion = 1,
            exists = false,
            targetKey = normalizedTarget,
            approval = 0,
            respect = 0,
            familiarity = 0,
            state = "unknown",
            previousState = "unknown",
            attitude = "neutral",
            revision = 0,
            relationshipRevision = 0,
            socialRevision = socialRevision,
            historical = false,
            historicalPin = false,
            targetLifecycleStatus = targetIdentity and targetIdentity.status or nil,
            targetLifecycleRevision = targetIdentity and targetIdentity.lifecycleRevision or nil,
            targetIdentity = targetIdentity,
            referenceMode = targetIdentity and targetIdentity.referenceMode or nil,
            lastEventAt = nil,
            grievanceScore = 0,
            assistanceScore = 0,
            directEvidenceCount = 0,
            witnessedEvidenceCount = 0,
            hearsayEvidenceCount = 0,
            anchorCount = 0,
            activeMemoryCount = 0,
            consolidatedEpisodeCount = 0,
            trustSignal = emptyDecision.trustSignal,
            grievancePressure = emptyDecision.grievancePressure,
            assistanceHistory = emptyDecision.assistanceHistory,
            familiaritySignal = emptyDecision.familiaritySignal,
            cautionSignal = emptyDecision.cautionSignal,
            provenanceConfidence = emptyDecision.provenanceConfidence,
            directWitness = emptyDecision.directWitness,
            hearsayOnly = emptyDecision.hearsayOnly,
            personality = emptyDecision.personality,
            features = emptyDecision.features,
            memories = {},
            extension = nil,
        }
    end

    local grievance, assistance = 0, 0
    local directCount, witnessedCount, hearsayCount = 0, 0, 0
    local anchorCount, activeCount, episodeCount = 0, 0, 0
    local ranked = {}

    local memories
    if type(getMemoriesFn) == "function" then
        memories = getMemoriesFn(state, normalizedTarget)
    else
        memories = rel.memories or {}
    end
    for _, mem in ipairs(memories or {}) do
        local str = Retention.CalculateMemoryStrength(mem, worldAgeHours)
        if str > 0 then
            activeCount = activeCount + 1
            local cls = Retention.EffectiveClass(mem)
            if cls == Retention.ANCHOR then anchorCount = anchorCount + 1 end
            local cnt = tonumber(mem.count) or 1
            episodeCount = episodeCount + cnt
            local mode = Retention.NormalizeSourceMode(mem.sourceMode, mem.knowledgeSource)
            if mode == "direct" then
                directCount = directCount + 1
            elseif mode == "witnessed" then
                witnessedCount = witnessedCount + 1
            elseif mode == "hearsay" then
                hearsayCount = hearsayCount + 1
            end
            local conf = clamp(tonumber(mem.confidence)
                or Retention.DefaultConfidence(mem.sourceMode, mem.knowledgeSource), 0, 1)
            local appEff = tonumber(mem.approvalEffect) or 0
            local respEff = tonumber(mem.respectEffect) or 0
            local weighted = (appEff + (respEff * 0.5)) * str * conf
            if weighted < 0 then
                grievance = grievance + math.abs(weighted)
            elseif weighted > 0 then
                assistance = assistance + weighted
            end
            if maxMemories > 0 then
                local priority = str * (Retention.MemorySalience(mem) / 100) * conf
                ranked[#ranked + 1] = {
                    view = compactMemoryView(mem, str),
                    priority = priority,
                    createdAt = tonumber(mem.createdAt) or 0,
                    seq = tonumber(mem.eventSequence) or 0,
                }
            end
        end
    end

    table.sort(ranked, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        if a.createdAt ~= b.createdAt then return a.createdAt > b.createdAt end
        if a.seq ~= b.seq then return a.seq > b.seq end
        return tostring(a.view.id or "") < tostring(b.view.id or "")
    end)

    local memoriesOut = {}
    for index = 1, math.min(maxMemories, #ranked) do
        memoriesOut[index] = ranked[index].view
    end

    local ext = nil
    if type(options.extensionID) == "string" and options.extensionID ~= ""
        and type(rel.extensions) == "table" and rel.extensions[options.extensionID] ~= nil
    then
        ext = Util.clone(rel.extensions[options.extensionID])
    end

    local approvalVal = tonumber(rel.approval) or 0
    local respectVal = tonumber(rel.respect) or 0
    local familiarityVal = tonumber(rel.familiarity) or 0
    local relRev = tonumber(rel.revision) or 0
    local decision = buildDecisionFeatures({
        exists = true,
        state = state,
        approval = approvalVal,
        respect = respectVal,
        familiarity = familiarityVal,
        grievance = grievance,
        assistance = assistance,
        directCount = directCount,
        witnessedCount = witnessedCount,
        hearsayCount = hearsayCount,
        anchorCount = anchorCount,
        activeCount = activeCount,
        episodeCount = episodeCount,
        relationshipRevision = relRev,
        socialRevision = socialRevision,
    })

    local resolvedState = (rel.state and rel.state ~= "") and rel.state or Projections.ResolveState(rel)
    local resolvedTargetStatus = (targetIdentity and targetIdentity.status) or rel.targetLifecycleStatus
    local resolvedTargetRev = (targetIdentity and targetIdentity.lifecycleRevision) or rel.targetLifecycleRevision
    decision.features.historical = rel.historical == true
    decision.features.targetLifecycleStatus = resolvedTargetStatus
    decision.features.targetLifecycleRevision = resolvedTargetRev
    return {
        schemaVersion = 1,
        exists = true,
        targetKey = normalizedTarget,
        approval = approvalVal,
        respect = respectVal,
        familiarity = familiarityVal,
        state = resolvedState,
        previousState = rel.previousState or "unknown",
        attitude = Projections.ResolveAttitude(approvalVal, respectVal),
        revision = relRev,
        relationshipRevision = relRev,
        socialRevision = socialRevision,
        historical = rel.historical == true,
        historicalPin = rel.historicalPin == true,
        historicalLabel = rel.historicalLabel,
        degradedLabel = rel.degradedLabel or rel.historicalLabel,
        targetLifecycleStatus = resolvedTargetStatus,
        targetLifecycleRevision = resolvedTargetRev,
        targetIdentity = targetIdentity,
        referenceMode = targetIdentity and targetIdentity.referenceMode or nil,
        lastEventAt = rel.lastEventAt,
        grievanceScore = grievance,
        assistanceScore = assistance,
        directEvidenceCount = directCount,
        witnessedEvidenceCount = witnessedCount,
        hearsayEvidenceCount = hearsayCount,
        anchorCount = anchorCount,
        activeMemoryCount = activeCount,
        consolidatedEpisodeCount = episodeCount,
        trustSignal = decision.trustSignal,
        grievancePressure = decision.grievancePressure,
        assistanceHistory = decision.assistanceHistory,
        familiaritySignal = decision.familiaritySignal,
        cautionSignal = decision.cautionSignal,
        provenanceConfidence = decision.provenanceConfidence,
        directWitness = decision.directWitness,
        hearsayOnly = decision.hearsayOnly,
        personality = decision.personality,
        features = decision.features,
        memories = memoriesOut,
        extension = ext,
    }
end

return Projections
