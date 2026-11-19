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

function Projections.QueryCandidateProjection(state, target, options, lookupRelFn)
    options = type(options) == "table" and options or {}
    local worldAgeHours = tonumber(options.worldAgeHours)
    local maxMemories = math.floor(clamp(options.maxMemories or 8, 0, 16))
    local rel, normalizedTarget = lookupRelFn(state, target)
    local socialRevision = tonumber(state and state.revision) or 0
    if not normalizedTarget then
        return nil, "target_key_invalid"
    end
    if not rel then
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
            socialRevision = socialRevision,
            lastEventAt = nil,
            grievanceScore = 0,
            assistanceScore = 0,
            directEvidenceCount = 0,
            witnessedEvidenceCount = 0,
            hearsayEvidenceCount = 0,
            anchorCount = 0,
            activeMemoryCount = 0,
            consolidatedEpisodeCount = 0,
            memories = {},
            extension = nil,
        }
    end

    local grievance, assistance = 0, 0
    local directCount, witnessedCount, hearsayCount = 0, 0, 0
    local anchorCount, activeCount, episodeCount = 0, 0, 0
    local ranked = {}

    for _, mem in ipairs(rel.memories or {}) do
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

    local resolvedState = (rel.state and rel.state ~= "") and rel.state or Projections.ResolveState(rel)
    return {
        schemaVersion = 1,
        exists = true,
        targetKey = normalizedTarget,
        approval = tonumber(rel.approval) or 0,
        respect = tonumber(rel.respect) or 0,
        familiarity = tonumber(rel.familiarity) or 0,
        state = resolvedState,
        previousState = rel.previousState or "unknown",
        attitude = Projections.ResolveAttitude(rel.approval, rel.respect),
        revision = tonumber(rel.revision) or 0,
        socialRevision = socialRevision,
        lastEventAt = rel.lastEventAt,
        grievanceScore = grievance,
        assistanceScore = assistance,
        directEvidenceCount = directCount,
        witnessedEvidenceCount = witnessedCount,
        hearsayEvidenceCount = hearsayCount,
        anchorCount = anchorCount,
        activeMemoryCount = activeCount,
        consolidatedEpisodeCount = episodeCount,
        memories = memoriesOut,
        extension = ext,
    }
end

function Projections.EvaluateAutonomyCandidates(state, target, candidates, options, lookupRelFn)
    if type(candidates) ~= "table" then return nil, "candidates_required" end
    local proj, reason = Projections.QueryCandidateProjection(state, target, options, lookupRelFn)
    if not proj then return nil, reason end

    local pers = type(state and state.personality) == "table" and state.personality or {}
    local aggression = clamp(pers.aggression ~= nil and pers.aggression or 0.3, 0, 1)
    local forgiveness = clamp(pers.forgiveness ~= nil and pers.forgiveness or 0.5, 0, 1)
    local caution = clamp(pers.caution ~= nil and pers.caution or 0.5, 0, 1)
    local sociability = clamp(pers.sociability ~= nil and pers.sociability or 0.5, 0, 1)
    local greed = clamp(pers.greed ~= nil and pers.greed or 0.5, 0, 1)

    local trustSignal = clamp((proj.approval * 0.65 + proj.respect * 0.35) / 100, -1, 1)
    local grievanceNorm = clamp(proj.grievanceScore / 50, 0, 1)
    local assistanceNorm = clamp(proj.assistanceScore / 50, 0, 1)
    local famNorm = clamp(proj.familiarity / 100, 0, 1)
    local provConf = 1.0
    if proj.activeMemoryCount > 0 then
        provConf = clamp((proj.directEvidenceCount + proj.witnessedEvidenceCount * 0.85
            + proj.hearsayEvidenceCount * 0.55) / proj.activeMemoryCount, 0.25, 1)
    end

    local results = {}
    for _, rawCandidate in ipairs(candidates) do
        local cand = string.upper(tostring(rawCandidate or ""))
        if cand ~= "" then
            local bias = 0
            local reasons = {}
            if cand == "TALK" then
                bias = clamp((trustSignal * 0.45) + (sociability * 0.3) + (famNorm * 0.2)
                    - (grievanceNorm * (0.6 - 0.3 * forgiveness)), -1, 1)
                if sociability >= 0.6 then reasons[#reasons + 1] = "personality_sociable" end
            elseif cand == "TRADE" then
                bias = clamp((trustSignal * 0.4) + (famNorm * 0.25) + ((1 - greed) * 0.1)
                    + (assistanceNorm * 0.2) - (grievanceNorm * 0.55), -1, 1)
                if famNorm >= 0.25 then reasons[#reasons + 1] = "familiar_partner" end
            elseif cand == "HELP" then
                bias = clamp((trustSignal * 0.5) + (assistanceNorm * 0.35) + (forgiveness * 0.15)
                    - (grievanceNorm * 0.7), -1, 1)
                if proj.assistanceScore > 0 then reasons[#reasons + 1] = "prior_assistance" end
            elseif cand == "AVOID" then
                bias = clamp((grievanceNorm * (0.45 + 0.4 * caution))
                    - (trustSignal * 0.4) - (aggression * 0.25), -1, 1)
                if caution >= 0.6 and proj.grievanceScore > 0 then reasons[#reasons + 1] = "cautious_grievance" end
            elseif cand == "CONFRONT" or cand == "RETALIATE" then
                bias = clamp((grievanceNorm * (0.4 + 0.5 * aggression) * (1.2 - 0.5 * forgiveness))
                    - (trustSignal * 0.35) - (caution * 0.2), -1, 1)
                if aggression >= 0.6 and proj.grievanceScore > 0 then reasons[#reasons + 1] = "aggressive_grievance" end
            elseif cand == "REPORT" then
                bias = clamp((grievanceNorm * 0.55 * provConf) + (caution * 0.25) - (trustSignal * 0.25), -1, 1)
                if proj.hearsayEvidenceCount > 0 then reasons[#reasons + 1] = "hearsay_corroboration_needed" end
            else
                bias = clamp(trustSignal * 0.35 - grievanceNorm * 0.35, -1, 1)
            end
            if proj.grievanceScore > 0 then reasons[#reasons + 1] = "grievance_present" end
            if proj.anchorCount > 0 then reasons[#reasons + 1] = "anchor_memory_present" end

            results[cand] = {
                candidate = cand,
                viabilityBias = bias,
                trustSignal = trustSignal,
                grievancePressure = grievanceNorm,
                assistanceDebt = assistanceNorm,
                familiarityBonus = famNorm,
                cautionSignal = clamp(grievanceNorm * caution, 0, 1),
                provenanceConfidence = provConf,
                directWitness = (proj.directEvidenceCount + proj.witnessedEvidenceCount) > 0,
                reasons = reasons,
            }
        end
    end

    return {
        schemaVersion = 1,
        targetKey = proj.targetKey,
        exists = proj.exists,
        socialRevision = proj.socialRevision,
        relationshipRevision = proj.revision,
        relationship = {
            approval = proj.approval,
            respect = proj.respect,
            familiarity = proj.familiarity,
            state = proj.state,
            attitude = proj.attitude,
            grievanceScore = proj.grievanceScore,
            assistanceScore = proj.assistanceScore,
            anchorCount = proj.anchorCount,
            activeMemoryCount = proj.activeMemoryCount,
            provenance = {
                direct = proj.directEvidenceCount,
                witnessed = proj.witnessedEvidenceCount,
                hearsay = proj.hearsayEvidenceCount,
            },
        },
        personality = Util.clone(pers),
        candidates = results,
        selectedAction = nil,
        mutated = false,
    }
end

return Projections
