local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.layerRoot("common_shared")
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function containsReason(reasons, expectedReason)
    for _, r in ipairs(reasons or {}) do
        if r == expectedReason then return true end
    end
    return false
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social
local Authority = Actors.SocialAuthority

local reg = Actors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors
PsychopatzCore.Actors.DefaultRegistry = reg

local targetKey = "player:sp_slot_1:char_p8"
local function seedHistory(actorId, personality, sourceMode)
    local actor = assert(reg:Create({
        actorId = actorId,
        identitySeed = actorId,
        social = Social.NewState({ personality = personality }),
    }))
    actor = assert(Authority.RecordAuthorizedEvent(actorId, {
        targetKey = targetKey,
        eventID = "ev:p8:trade:" .. actorId,
        type = "commercial_trade",
        retentionClass = Social.RETENTION_LONG,
        salience = 105,
        approvalDelta = 2,
        respectDelta = 1,
        familiarityDelta = 4,
        createdAt = 150,
        worldAgeHours = 150,
        sourceMode = "direct",
        authority = "server",
        authorized = true,
    }, PsychopatzCore, actor.revision))
    actor = assert(Authority.RecordAuthorizedEvent(actorId, {
        targetKey = targetKey,
        eventID = "ev:p8:betrayal:" .. actorId,
        type = "betrayal",
        retentionClass = Social.RETENTION_ANCHOR,
        salience = 250,
        approvalDelta = -35,
        respectDelta = -20,
        familiarityDelta = 2,
        createdAt = 180,
        worldAgeHours = 180,
        sourceMode = sourceMode or "direct",
        confidence = sourceMode == "hearsay" and 0.55 or 1.0,
        authority = "server",
        authorized = true,
    }, PsychopatzCore, actor.revision))
    return assert(reg:Get(actorId))
end

local cautiousBefore = seedHistory("actor:p8:cautious", {
    caution = 0.9,
    forgiveness = 0.8,
    aggression = 0.1,
    sociability = 0.6,
    greed = 0.3,
}, "direct")

local aggressiveBefore = seedHistory("actor:p8:aggressive", {
    caution = 0.1,
    forgiveness = 0.1,
    aggression = 0.95,
    sociability = 0.3,
    greed = 0.7,
}, "direct")

local hearsayBefore = seedHistory("actor:p8:hearsay", {
    caution = 0.7,
    forgiveness = 0.5,
    aggression = 0.2,
    sociability = 0.5,
}, "hearsay")

-- Verify initial equality of objective relationship history between direct actors
local cRelBefore = assert(Social.Get(cautiousBefore.social, targetKey))
local aRelBefore = assert(Social.Get(aggressiveBefore.social, targetKey))
equal(cRelBefore.approval, aRelBefore.approval, "identical approval history across personalities")
equal(#cRelBefore.memories, 2, "2 active memories before evaluation")

-- 0. Verify Core Social exposes only action-neutral decision features (no action-scoring policy)
equal(Social.EvaluateAutonomyCandidates, nil, "Social.EvaluateAutonomyCandidates removed")
equal(Authority.EvaluateAutonomyCandidates, nil, "Authority.EvaluateAutonomyCandidates removed")

local forbiddenActions = { "TALK", "TRADE", "HELP", "AVOID", "CONFRONT", "REPORT", "RETALIATE" }
for _, relPath in ipairs({
    ROOT .. "PsychopatzCore/Actors/PsychopatzSocialProjections.lua",
    ROOT .. "PsychopatzCore/Actors/PsychopatzSocial.lua",
    ROOT .. "PsychopatzCore/Actors/PsychopatzActorSocialAuthority.lua",
    ROOT .. "PsychopatzCore/Actors/PsychopatzSocialRetention.lua",
}) do
    local fh = assert(io.open(relPath, "r"))
    local src = fh:read("*a")
    fh:close()
    for _, actionName in ipairs(forbiddenActions) do
        equal(string.find(src, '"' .. actionName .. '"', 1, true), nil,
            relPath .. " must not contain action literal " .. actionName)
    end
end

-- Synthetic EXTERNAL consumer weights candidate actions solely from action-neutral Core features
local function clamp01(v)
    return math.max(-1, math.min(1, tonumber(v) or 0))
end

local function externalEvaluateCandidates(proj, candidates)
    local pers = proj.personality or {}
    local aggression = tonumber(pers.aggression) or 0.3
    local forgiveness = tonumber(pers.forgiveness) or 0.5
    local caution = tonumber(pers.caution) or 0.5
    local sociability = tonumber(pers.sociability) or 0.5
    local greed = tonumber(pers.greed) or 0.5

    local trustNorm = clamp01((tonumber(proj.trustSignal) or 0) / 100)
    local grievanceNorm = math.max(0, math.min(1, (tonumber(proj.grievancePressure) or 0) / 50))
    local assistanceNorm = math.max(0, math.min(1, (tonumber(proj.assistanceHistory) or 0) / 50))
    local famNorm = math.max(0, math.min(1, (tonumber(proj.familiaritySignal) or 0) / 100))
    local provConf = math.max(0, math.min(1, tonumber(proj.provenanceConfidence) or 0))

    local results = {}
    for _, cand in ipairs(candidates) do
        local bias = 0
        local reasons = {}
        if cand == "TALK" then
            bias = clamp01((trustNorm * 0.45) + (sociability * 0.3) + (famNorm * 0.2)
                - (grievanceNorm * (0.6 - 0.3 * forgiveness)))
        elseif cand == "TRADE" then
            bias = clamp01((trustNorm * 0.4) + (famNorm * 0.25) + ((1 - greed) * 0.1)
                + (assistanceNorm * 0.2) - (grievanceNorm * 0.55))
        elseif cand == "HELP" then
            bias = clamp01((trustNorm * 0.5) + (assistanceNorm * 0.35) + (forgiveness * 0.15)
                - (grievanceNorm * 0.7))
        elseif cand == "AVOID" then
            bias = clamp01((grievanceNorm * (0.45 + 0.4 * caution))
                - (trustNorm * 0.4) - (aggression * 0.25))
            if caution >= 0.6 and proj.grievancePressure > 0 then
                reasons[#reasons + 1] = "cautious_grievance"
            end
        elseif cand == "CONFRONT" or cand == "RETALIATE" then
            bias = clamp01((grievanceNorm * (0.4 + 0.5 * aggression) * (1.2 - 0.5 * forgiveness))
                - (trustNorm * 0.35) - (caution * 0.2))
            if aggression >= 0.6 and proj.grievancePressure > 0 then
                reasons[#reasons + 1] = "aggressive_grievance"
            end
        elseif cand == "REPORT" then
            bias = clamp01((grievanceNorm * 0.55 * provConf) + (caution * 0.25) - (trustNorm * 0.25))
            if proj.hearsayOnly or proj.hearsayEvidenceCount > 0 then
                reasons[#reasons + 1] = "hearsay_corroboration_needed"
            end
        end
        if proj.anchorCount > 0 then reasons[#reasons + 1] = "anchor_memory_present" end
        results[cand] = {
            candidate = cand,
            viabilityBias = bias,
            reasons = reasons,
        }
    end
    return results
end

local unknownProj = assert(Authority.QueryCandidateProjection(
    cautiousBefore.actorId, "player:sp_slot_1:unknown", { worldAgeHours = 200 }, PsychopatzCore
))
equal(unknownProj.exists, false, "unknown target projection returns exists=false")
equal(unknownProj.trustSignal, 0, "unknown target trustSignal is 0")
equal(unknownProj.directWitness, false, "unknown target directWitness is false")

local cautiousProj = assert(Authority.QueryCandidateProjection(
    cautiousBefore.actorId, targetKey, { worldAgeHours = 200 }, PsychopatzCore
))
local aggressiveProj = assert(Authority.QueryCandidateProjection(
    aggressiveBefore.actorId, targetKey, { worldAgeHours = 200 }, PsychopatzCore
))
local hearsayProj = assert(Authority.QueryCandidateProjection(
    hearsayBefore.actorId, targetKey, { worldAgeHours = 200 }, PsychopatzCore
))

-- Determinism check across repeated calls with identical state and worldAgeHours
local cautiousProjRepeat = assert(Authority.QueryCandidateProjection(
    cautiousBefore.actorId, targetKey, { worldAgeHours = 200 }, PsychopatzCore
))
equal(cautiousProjRepeat.trustSignal, cautiousProj.trustSignal, "deterministic trustSignal")
equal(cautiousProjRepeat.cautionSignal, cautiousProj.cautionSignal, "deterministic cautionSignal")
equal(cautiousProjRepeat.relationshipRevision, cautiousProj.revision, "relationshipRevision matches revision")
equal(cautiousProj.features.grievancePressure, cautiousProj.grievancePressure, "nested features match top-level")

-- 1. Non-mutating, non-commanding contract
equal(cautiousProj.schemaVersion, 1, "projection schemaVersion == 1")
equal(cautiousProj.exists, true, "projection reports existing relationship")

local cautiousAfter = assert(reg:Get(cautiousBefore.actorId))
local aggressiveAfter = assert(reg:Get(aggressiveBefore.actorId))
equal(cautiousAfter.revision, cautiousBefore.revision, "actor revision unchanged after projection query")
equal(cautiousAfter.social.revision, cautiousBefore.social.revision, "social revision unchanged after query")
equal(aggressiveAfter.revision, aggressiveBefore.revision, "aggressive actor revision unchanged")
equal(aggressiveAfter.social.revision, aggressiveBefore.social.revision, "aggressive social revision unchanged")

local candidates = { "TALK", "TRADE", "HELP", "AVOID", "CONFRONT", "REPORT", "RETALIATE" }
local cautiousEval = externalEvaluateCandidates(cautiousProj, candidates)
local aggressiveEval = externalEvaluateCandidates(aggressiveProj, candidates)
local hearsayEval = externalEvaluateCandidates(hearsayProj, candidates)

-- 2. Provenance and grievance signals surfaced cleanly without raw ModData
truthy(cautiousProj.grievancePressure > 0, "grievancePressure surfaced")
equal(cautiousProj.directWitness, true, "direct betrayal flagged as directWitness")
equal(cautiousProj.hearsayOnly, false, "direct betrayal is not hearsayOnly")
equal(cautiousProj.provenanceConfidence, 1.0, "direct history keeps full provenanceConfidence")
truthy(containsReason(cautiousEval.AVOID.reasons, "cautious_grievance"), "cautious consumer derives avoid reason")
truthy(containsReason(cautiousEval.AVOID.reasons, "anchor_memory_present"), "anchor evidence surfaced")
truthy(containsReason(aggressiveEval.RETALIATE.reasons, "aggressive_grievance"),
    "aggressive consumer derives retaliate reason")

-- 3. External consumer + Core personality inputs shift candidate rankings for identical history
truthy(cautiousEval.AVOID.viabilityBias > cautiousEval.RETALIATE.viabilityBias,
    "cautious actor favors AVOID over RETALIATE given identical betrayal")
truthy(aggressiveEval.RETALIATE.viabilityBias > cautiousEval.RETALIATE.viabilityBias,
    "aggressive actor weights RETALIATE higher than cautious actor")
truthy(aggressiveEval.CONFRONT.viabilityBias > cautiousEval.CONFRONT.viabilityBias,
    "aggressive actor weights CONFRONT higher than cautious actor")

-- 4. Mixed hearsay weakens provenanceConfidence, and pure-hearsay flags hearsayOnly
equal(hearsayProj.directWitness, true, "hearsay actor also has direct trade witness")
equal(hearsayProj.hearsayOnly, false, "mixed direct+hearsay is not hearsayOnly")
truthy(hearsayProj.hearsayEvidenceCount == 1, "hearsay betrayal counted")
truthy(hearsayProj.provenanceConfidence < 1.0, "hearsay weakens provenanceConfidence")
truthy(containsReason(hearsayEval.REPORT.reasons, "hearsay_corroboration_needed"),
    "hearsay betrayal requests corroboration for REPORT")

local pureHearsayActor = assert(reg:Create({
    actorId = "actor:p8:pure_hearsay",
    identitySeed = "actor:p8:pure_hearsay",
    social = Social.NewState({ personality = { caution = 0.7 } }),
}))
pureHearsayActor = assert(Authority.RecordAuthorizedEvent(pureHearsayActor.actorId, {
    targetKey = targetKey,
    eventID = "ev:p8:rumor:only",
    type = "betrayal",
    retentionClass = Social.RETENTION_ANCHOR,
    salience = 250,
    approvalDelta = -35,
    respectDelta = -20,
    familiarityDelta = 2,
    createdAt = 180,
    worldAgeHours = 180,
    sourceMode = "hearsay",
    confidence = 0.55,
    authority = "server",
    authorized = true,
}, PsychopatzCore, pureHearsayActor.revision))
local pureHearsayProj = assert(Authority.QueryCandidateProjection(
    pureHearsayActor.actorId, targetKey, { worldAgeHours = 200 }, PsychopatzCore
))
equal(pureHearsayProj.directWitness, false, "pure hearsay actor is not directWitness")
equal(pureHearsayProj.hearsayOnly, true, "pure hearsay actor flagged hearsayOnly")
equal(pureHearsayProj.provenanceConfidence, 0.55, "pure hearsay provenanceConfidence == 0.55")

print("PASS psychopatz_social_autonomy_seam_smoke")
