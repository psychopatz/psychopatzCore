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

local function near(actual, expected, eps, label)
    if math.abs((tonumber(actual) or 0) - expected) > (eps or 0.001) then
        error((label or "near") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social
local Authority = Actors.SocialAuthority
local Persistence = Actors.Persistence
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

-- 1. ParseTargetKey across actor/npc/player/steam
local pActor = Social.ParseTargetKey("actor:dt:world:7")
truthy(pActor and pActor.kind == "actor" and pActor.id == "dt:world:7", "parse actor key")
local pPlayer3 = Social.ParseTargetKey("player:sp_slot_1:char_abc")
truthy(pPlayer3 and pPlayer3.kind == "player" and pPlayer3.accountIdentity == "sp_slot_1"
    and pPlayer3.characterUUID == "char_abc", "parse 3-segment player key")
local pPlayer2 = Social.ParseTargetKey("player:online:9")
truthy(pPlayer2 and pPlayer2.kind == "player", "parse legacy 2/3 segment player key")
equal(Social.ParseTargetKey("   "), nil, "whitespace target rejected")

-- 2. Default-omission invariant preserved
local reg = Actors.NewRegistry()
local emptyActor = assert(reg:Create({ actorId = "actor:p2:empty", identitySeed = "p2-empty" }))
local compactEmpty = assert(Persistence.EncodeActor(emptyActor))
equal(compactEmpty.social, nil, "default social still omitted in compact persistence")

-- 3. SCENE retention never persists
local s = Social.NewState({ personality = { forgiveness = 0.2, sociability = 0.8 } })
s = assert(Social.RecordAuthorizedEvent(s, {
    targetKey = "player:acc1:char1",
    eventID = "ev:scene:1",
    type = "ambient_greeting",
    retentionClass = Social.RETENTION_SCENE,
    approvalDelta = 2,
    familiarityDelta = 1,
    createdAt = 10,
    authority = "server",
    authorized = true,
}))
local rel1 = Social.Get(s, "player:acc1:char1")
equal(rel1.approval, 2, "SCENE delta applied to relationship score")
equal(#rel1.memories, 0, "SCENE memory never persisted in relationship.memories")

-- 4. Consolidation of repeated equivalent events within cap
for i = 1, 25 do
    s = assert(Social.RecordAuthorizedEvent(s, {
        targetKey = "player:acc1:char1",
        eventID = "ev:trade:" .. i,
        type = "commercial_trade",
        retentionClass = Social.RETENTION_LONG,
        consolidationFamily = "dt:trade:routine",
        maxConsolidatedApproval = 10,
        maxConsolidatedFamiliarity = 15,
        approvalDelta = 1,
        respectDelta = 0,
        familiarityDelta = 1,
        createdAt = 20 + i,
        salience = 110,
        authority = "server",
        authorized = true,
        tags = { trade = true },
    }))
end
local relConsol = Social.Get(s, "player:acc1:char1")
equal(#relConsol.memories, 1, "25 repeated trades consolidated into 1 memory slot")
equal(relConsol.memories[1].count, 25, "consolidated count tracked")
equal(relConsol.memories[1].firstCreatedAt, 21, "firstCreatedAt preserved")
equal(relConsol.memories[1].createdAt, 45, "latest createdAt updated")
equal(relConsol.approval, 12, "consolidated approval capped (+2 SCENE + 10 cap = 12)")
equal(relConsol.familiarity, 16, "consolidated familiarity capped (+1 SCENE + 15 cap = 16)")

-- 5. SHORT lazy decay with zero per-tick loop + RecalculateRelationship
s = assert(Social.RecordAuthorizedEvent(s, {
    targetKey = "player:acc2:char2",
    eventID = "ev:short:1",
    type = "minor_insult",
    retentionClass = Social.RETENTION_SHORT,
    approvalDelta = -10,
    respectDelta = -5,
    familiarityDelta = 2,
    createdAt = 100,
    decayPerDay = 1.0,
    salience = 90,
    authority = "server",
    authorized = true,
}))
local memShort = Social.Get(s, "player:acc2:char2").memories[1]
near(Social.CalculateMemoryStrength(memShort, 112), 0.5, 0.001, "12h decay = 0.5 strength")
near(Social.CalculateMemoryStrength(memShort, 124), 0.0, 0.001, "24h decay = 0.0 expired")
local projAt12 = Social.QueryCandidateProjection(s, "player:acc2:char2", { worldAgeHours = 112 })
equal(projAt12.activeMemoryCount, 1, "active at 12h")
local projAt24 = Social.QueryCandidateProjection(s, "player:acc2:char2", { worldAgeHours = 124 })
equal(projAt24.activeMemoryCount, 0, "lazily expired at 24h on query without mutating store")

-- 6. ANCHOR cap (MAX_ANCHOR_MEMORIES = 6) deterministic salience replacement/demotion
for i = 1, 8 do
    s = assert(Social.RecordAuthorizedEvent(s, {
        targetKey = "player:acc3:char3",
        eventID = "ev:anchor:" .. i,
        type = "major_event",
        retentionClass = Social.RETENTION_ANCHOR,
        salience = 180 + (i * 5),
        approvalDelta = 5,
        createdAt = 200 + i,
        authority = "server",
        authorized = true,
    }))
end
local relAnchor = Social.Get(s, "player:acc3:char3")
local anchorCount, longCount = 0, 0
for _, m in ipairs(relAnchor.memories) do
    if m.retentionClass == Social.RETENTION_ANCHOR then anchorCount = anchorCount + 1 end
    if m.retentionClass == Social.RETENTION_LONG then longCount = longCount + 1 end
end
equal(anchorCount, Social.MAX_ANCHOR_MEMORIES, "anchor hard cap enforced at 6")
equal(longCount, 2, "2 weakest anchors deterministically demoted to LONG")

-- 7. Provenance modes: direct vs witnessed vs hearsay
s = assert(Social.RecordAuthorizedEvent(s, {
    targetKey = "player:acc4:char4",
    eventID = "ev:hearsay:1",
    type = "betrayal_rumor",
    retentionClass = Social.RETENTION_LONG,
    sourceMode = "hearsay",
    knowledgeSource = "told_by_trusted_person",
    sourceKey = "npc:informant_1",
    approvalDelta = -10,
    createdAt = 300,
    authority = "server",
    authorized = true,
}))
local projHearsay = Social.QueryCandidateProjection(s, "player:acc4:char4", { worldAgeHours = 301 })
equal(projHearsay.hearsayEvidenceCount, 1, "hearsay provenance counted")
equal(projHearsay.memories[1].sourceMode, "hearsay", "sourceMode preserved")
equal(projHearsay.memories[1].sourceKey, "npc:informant_1", "sourceKey preserved")
near(projHearsay.memories[1].confidence, 0.75, 0.001, "hearsay confidence attenuated")

-- 8. Personality modulation when enabled
local unforgiving = Social.NewState({ personality = { forgiveness = 0.0, sociability = 0.5 } })
local forgiving = Social.NewState({ personality = { forgiveness = 1.0, sociability = 0.5 } })
local evBase = {
    targetKey = "player:acc5:char5",
    eventID = "ev:insult:mod",
    type = "insult",
    retentionClass = Social.RETENTION_SHORT,
    approvalDelta = -10,
    decayPerDay = 1.0,
    createdAt = 400,
    applyPersonality = true,
    authority = "server",
    authorized = true,
}
unforgiving = assert(Social.RecordAuthorizedEvent(unforgiving, evBase))
forgiving = assert(Social.RecordAuthorizedEvent(forgiving, evBase))
truthy(Social.Get(unforgiving, "player:acc5:char5").approval < Social.Get(forgiving, "player:acc5:char5").approval,
    "low forgiveness takes harsher approval hit than high forgiveness")

-- 9. Authority wrappers + roundtrip persistence
local authActor = assert(reg:Create({ actorId = "actor:p2:auth", identitySeed = "p2-auth" }))
local committed = assert(Authority.RecordAuthorizedEvent("actor:p2:auth", {
    targetKey = "player:acc1:char1",
    eventID = "ev:auth:1",
    type = "commercial_trade",
    retentionClass = Social.RETENTION_LONG,
    consolidationFamily = "dt:trade:routine",
    approvalDelta = 3,
    familiarityDelta = 2,
    createdAt = 500,
    authority = "server",
    authorized = true,
}, { Actors = { DefaultRegistry = reg } }, authActor.revision))
local projAuth = assert(Authority.QueryCandidateProjection("actor:p2:auth", "player:acc1:char1",
    { worldAgeHours = 500 }, { Actors = { DefaultRegistry = reg } }))
equal(projAuth.approval, 3, "Authority.QueryCandidateProjection returns committed score")
equal(Social.EvaluateAutonomyCandidates, nil, "Social.EvaluateAutonomyCandidates removed")
equal(Authority.EvaluateAutonomyCandidates, nil, "Authority.EvaluateAutonomyCandidates removed")
truthy(projAuth.trustSignal > 0, "action-neutral trustSignal positive for cooperative partner")
truthy(projAuth.familiaritySignal > 0, "action-neutral familiaritySignal positive")
equal(projAuth.directWitness, true, "direct witness provenance flagged")
equal(projAuth.features.trustSignal, projAuth.trustSignal, "nested features mirror trustSignal")

local savedJson = assert(reg:Save())
local reloaded = Actors.NewRegistry()
truthy(reloaded:Load(savedJson), "reload saved social state")
local reloadedActor = assert(reloaded:Get("actor:p2:auth"))
local reloadedRel = assert(Social.Get(reloadedActor.social, "player:acc1:char1"))
equal(reloadedRel.memories[1].consolidationKey, "dt:trade:routine:player:acc1:char1:direct",
    "consolidationKey survives compact save/reload")
equal(reloadedRel.memories[1].retentionClass, Social.RETENTION_LONG, "retentionClass survives save/reload")

print("psychopatz_social_retention_consolidation_smoke: PASS")
