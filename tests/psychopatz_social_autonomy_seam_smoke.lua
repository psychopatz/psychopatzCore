local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
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

-- Synthetic read-only future-autonomy consumer evaluates candidates without raw ModData access
local candidates = { "TALK", "TRADE", "HELP", "AVOID", "CONFRONT", "REPORT", "RETALIATE" }
local cautiousEval = assert(Authority.EvaluateAutonomyCandidates(
    cautiousBefore.actorId, targetKey, candidates, { worldAgeHours = 200 }, PsychopatzCore
))
local aggressiveEval = assert(Authority.EvaluateAutonomyCandidates(
    aggressiveBefore.actorId, targetKey, candidates, { worldAgeHours = 200 }, PsychopatzCore
))
local hearsayEval = assert(Authority.EvaluateAutonomyCandidates(
    hearsayBefore.actorId, targetKey, candidates, { worldAgeHours = 200 }, PsychopatzCore
))

-- 1. Non-mutating, non-commanding contract
equal(cautiousEval.schemaVersion, 1, "autonomy seam schemaVersion == 1")
equal(cautiousEval.exists, true, "autonomy seam reports existing relationship")
equal(cautiousEval.selectedAction, nil, "Portable Social State never selects final autonomy action")
equal(cautiousEval.mutated, false, "EvaluateAutonomyCandidates does not mutate state")
equal(aggressiveEval.selectedAction, nil, "aggressive evaluation never selects final action")
equal(aggressiveEval.mutated, false, "aggressive evaluation is read-only")

local cautiousAfter = assert(reg:Get(cautiousBefore.actorId))
local aggressiveAfter = assert(reg:Get(aggressiveBefore.actorId))
equal(cautiousAfter.revision, cautiousBefore.revision, "actor revision unchanged after evaluation")
equal(cautiousAfter.social.revision, cautiousBefore.social.revision, "social revision unchanged after evaluation")
equal(aggressiveAfter.revision, aggressiveBefore.revision, "aggressive actor revision unchanged")
equal(aggressiveAfter.social.revision, aggressiveBefore.social.revision, "aggressive social revision unchanged")

-- 2. Provenance and grievance reasons surfaced cleanly without raw ModData
truthy(cautiousEval.candidates.AVOID.grievancePressure > 0, "grievancePressure surfaced")
equal(cautiousEval.candidates.AVOID.directWitness, true, "direct betrayal flagged as directWitness")
equal(cautiousEval.candidates.AVOID.provenanceConfidence, 1.0, "direct history keeps full provenanceConfidence")
truthy(containsReason(cautiousEval.candidates.AVOID.reasons, "cautious_grievance"), "cautious reason attached")
truthy(containsReason(cautiousEval.candidates.AVOID.reasons, "anchor_memory_present"), "anchor reason attached")
truthy(containsReason(aggressiveEval.candidates.RETALIATE.reasons, "aggressive_grievance"), "aggressive reason attached")

-- 3. Personality shifts candidate viability weights deterministically for identical history
truthy(cautiousEval.candidates.AVOID.viabilityBias > cautiousEval.candidates.RETALIATE.viabilityBias,
    "cautious actor favors AVOID over RETALIATE given identical betrayal")
truthy(aggressiveEval.candidates.RETALIATE.viabilityBias > cautiousEval.candidates.RETALIATE.viabilityBias,
    "aggressive actor weights RETALIATE higher than cautious actor")
truthy(aggressiveEval.candidates.CONFRONT.viabilityBias > cautiousEval.candidates.CONFRONT.viabilityBias,
    "aggressive actor weights CONFRONT higher than cautious actor")

-- 4. Hearsay provenance lowers confidence and requests corroboration
truthy(hearsayEval.candidates.REPORT.provenanceConfidence < 1.0, "hearsay weakens provenanceConfidence")
truthy(containsReason(hearsayEval.candidates.REPORT.reasons, "hearsay_corroboration_needed"),
    "hearsay betrayal requests corroboration for REPORT")

print("PASS psychopatz_social_autonomy_seam_smoke")
