package.path = "./Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;" .. package.path

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = {
    AllowsServerCode = function() return true end,
}

local nowMs = 1000
getTimeInMillis = function()
    nowMs = nowMs + 1
    return nowMs
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social
local SocialQuery = Actors.SocialQuery
local Interaction = Actors.Interaction
local GC = Actors.GC

assert(SocialQuery ~= nil, "Actors.SocialQuery must be exported")
SocialQuery.ResetDiagnostics()

local registry = Actors.NewRegistry()
Actors.DefaultRegistry = registry

local worldHours = 250

-- Speaking NPC Alice + 4 target lifecycle classes:
--   1. liveTarget (LIVE)
--   2. recentDeadTarget (RETIRED within 72h -> recentlyDead = true)
--   3. historicalNamedTarget (RETIRED > 72h -> HISTORICAL_NAMED)
--   4. purgedLabeledTarget (FORGOTTEN after GC -> LABEL_ONLY)
--   5. purgedAnonTarget (FORGOTTEN after GC with no label -> ANONYMOUS)
assert(registry:Create({
    actorId = "npc:live_target",
    identitySeed = "live-target",
    identity = { displayName = "Marcus Vale", role = "scout" },
}))
assert(registry:Create({
    actorId = "npc:recent_dead",
    identitySeed = "recent-dead",
    identity = { displayName = "Clara Reed", role = "medic" },
}))
assert(registry:Create({
    actorId = "npc:historical_named",
    identitySeed = "historical-named",
    identity = { displayName = "Victor Shaw", role = "trader" },
}))
assert(registry:Create({
    actorId = "npc:purged_labeled",
    identitySeed = "purged-labeled",
    identity = { displayName = "Helena Cross", role = "companion" },
}))
assert(registry:Create({
    actorId = "npc:purged_anon",
    identitySeed = "purged-anon",
    identity = { displayName = "Anonymous Drifter", role = "stranger" },
}))

local mems = {
    {
        id = "mem:live:1",
        aboutKey = "npc:live_target",
        eventType = "helped_in_combat",
        retentionClass = "LONG",
        refStrength = "WEAK",
        salience = 55,
        confidence = 0.9,
        sourceMode = "direct",
        createdAt = worldHours - 2,
    },
    {
        id = "mem:recent:1",
        aboutKey = "npc:recent_dead",
        eventType = "saved_from_incapacitation",
        retentionClass = "ANCHOR",
        refStrength = "STRONG",
        salience = 95,
        confidence = 1.0,
        sourceMode = "direct",
        createdAt = worldHours - 5,
    },
    {
        id = "mem:hist:1",
        aboutKey = "npc:historical_named",
        eventType = "betrayed_player",
        retentionClass = "ANCHOR",
        refStrength = "STRONG",
        salience = 90,
        confidence = 0.95,
        sourceMode = "witnessed",
        createdAt = worldHours - 140,
    },
    {
        id = "mem:label:1",
        aboutKey = "npc:purged_labeled",
        eventType = "shared_ration",
        retentionClass = "LONG",
        refStrength = "LABEL_ONLY",
        salience = 60,
        confidence = 0.85,
        sourceMode = "direct",
        degradedLabel = "former_companion",
        createdAt = worldHours - 200,
    },
    {
        id = "mem:anon:1",
        aboutKey = "npc:purged_anon",
        eventType = "saw_passing",
        retentionClass = "LONG",
        refStrength = "WEAK",
        salience = 30,
        confidence = 0.7,
        sourceMode = "hearsay",
        createdAt = worldHours - 200,
    },
}
for idx = 1, 10 do
    mems[#mems + 1] = {
        id = "mem:extra:" .. tostring(idx),
        aboutKey = "npc:live_target",
        eventType = "casual_chat",
        retentionClass = "SHORT",
        refStrength = "WEAK",
        salience = 20 + idx,
        confidence = 0.8,
        sourceMode = "direct",
        createdAt = worldHours - 1,
    }
end

local speaker = assert(registry:Create({
    actorId = "npc:speaker_alice",
    identitySeed = "speaker-alice",
    identity = { displayName = "Alice Vance", role = "guard" },
    social = Social.NewState({
        relationships = {
            ["npc:live_target"] = {
                target = "npc:live_target",
                approval = 35,
                respect = 20,
                familiarity = 40,
                revision = 3,
            },
            ["npc:recent_dead"] = {
                target = "npc:recent_dead",
                approval = 60,
                respect = 50,
                familiarity = 70,
                revision = 2,
            },
            ["npc:historical_named"] = {
                target = "npc:historical_named",
                approval = -75,
                respect = -40,
                familiarity = 50,
                revision = 4,
            },
            ["npc:purged_labeled"] = {
                target = "npc:purged_labeled",
                approval = 25,
                respect = 15,
                familiarity = 30,
                historicalLabel = "former_companion",
                revision = 1,
            },
            ["npc:purged_anon"] = {
                target = "npc:purged_anon",
                approval = 0,
                respect = 0,
                familiarity = 5,
                revision = 1,
            },
        },
        memoryBank = mems,
    }),
}))

-- Retire historicalNamed (120h ago -> not recentlyDead), recentDead (4h ago -> recentlyDead),
-- purgedLabeled & purgedAnon (200h ago -> will be purged by GC)
assert(registry:Retire("npc:historical_named", {
    authority = "server",
    reason = "death",
    retiredAt = worldHours - 120,
    graceHours = 12,
    label = "Victor Shaw",
    role = "trader",
}))
assert(registry:Retire("npc:recent_dead", {
    authority = "server",
    reason = "death",
    retiredAt = worldHours - 4,
    graceHours = 48,
    label = "Clara Reed",
    role = "medic",
}))
assert(registry:Retire("npc:purged_labeled", {
    authority = "server",
    reason = "death",
    retiredAt = worldHours - 200,
    graceHours = 12,
    label = "Helena Cross",
    role = "companion",
}))
assert(registry:Retire("npc:purged_anon", {
    authority = "server",
    reason = "death",
    retiredAt = worldHours - 200,
    graceHours = 12,
    label = "Anonymous Drifter",
    role = "stranger",
}))

-- Sweep GC: unpinned weak tombstones purge to FORGOTTEN, STRONG tombstones stay RETIRED
local sweepResult = assert(GC.RunFull(registry, {
    authority = "server",
    now = worldHours,
}))
assert(sweepResult.completed == true)
assert(registry:GetLifecycleState("npc:purged_labeled") == "FORGOTTEN")
assert(registry:GetLifecycleState("npc:purged_anon") == "FORGOTTEN")
assert(registry:GetLifecycleState("npc:recent_dead") == "RETIRED")
assert(registry:GetLifecycleState("npc:historical_named") == "RETIRED")

-- Verify ResolveAttitude bug fix on GetHotRelationshipSnapshot + zero GC during clicks
local genBeforeClick = (registry.gcMeta and registry.gcMeta.generation) or 0

local hotLive = assert(SocialQuery.OpenInteractionHotContext(
    registry, "npc:speaker_alice", "npc:live_target", { now = worldHours }
))
assert(hotLive.targetIdentity.referenceMode == "LIVE_ENTITY")
assert(hotLive.targetIdentity.displayName == "Marcus Vale")
assert(hotLive.hotSnapshot.attitude == "fondness",
    "ResolveAttitude must read relationship.approval/respect rather than table")
assert(hotLive.hotSnapshot.relationshipRevision == 3)
assert(hotLive.hotSnapshot.socialRevision >= 0)
assert(hotLive.revisions.lifecycleRevision == 1)

local hotRecent = assert(SocialQuery.OpenInteractionHotContext(
    registry, "npc:speaker_alice", "npc:recent_dead", { now = worldHours }
))
assert(hotRecent.targetIdentity.status == "RETIRED")
assert(hotRecent.targetIdentity.referenceMode == "HISTORICAL_NAMED")
assert(hotRecent.targetIdentity.recentlyDead == true)
assert(hotRecent.targetIdentity.displayName == "Clara Reed")
-- Zero internal tombstone leakage
assert(hotRecent.targetIdentity.graceHours == nil)
assert(hotRecent.targetIdentity.purgeEligibleAt == nil)
assert(hotRecent.targetIdentity.aliases == nil)

local hotHistorical = assert(SocialQuery.OpenInteractionHotContext(
    registry, "npc:speaker_alice", "npc:historical_named", { now = worldHours }
))
assert(hotHistorical.targetIdentity.status == "RETIRED")
assert(hotHistorical.targetIdentity.referenceMode == "HISTORICAL_NAMED")
assert(hotHistorical.targetIdentity.recentlyDead == false)
assert(hotHistorical.targetIdentity.displayName == "Victor Shaw")

local hotLabeled = assert(SocialQuery.OpenInteractionHotContext(
    registry, "npc:speaker_alice", "npc:purged_labeled", {
        now = worldHours,
        degradedLabel = "former_companion",
    }
))
assert(hotLabeled.targetIdentity.status == "FORGOTTEN")
assert(hotLabeled.targetIdentity.referenceMode == "LABEL_ONLY")
assert(hotLabeled.targetIdentity.displayName == nil)
assert(hotLabeled.targetIdentity.degradedLabel == "former_companion")

-- Also verify ExecutePlan surfaces GC-degraded LABEL_ONLY memory when aboutKey was stripped
local degradedPlanRes = assert(SocialQuery.ExecutePlan(registry, "npc:speaker_alice", {
    eventTypes = { "shared_ration" },
    maxMemories = 4,
}, { now = worldHours }))
assert(#degradedPlanRes.memories == 1, "degraded LABEL_ONLY memory survives purge cleanly")
assert(degradedPlanRes.memories[1].targetReference.status == "FORGOTTEN")
assert(degradedPlanRes.memories[1].targetReference.referenceMode == "LABEL_ONLY")
assert(degradedPlanRes.memories[1].targetReference.degradedLabel == "former_companion")
assert(degradedPlanRes.memories[1].targetReference.displayName == nil)

local hotAnon = assert(SocialQuery.OpenInteractionHotContext(
    registry, "npc:speaker_alice", "npc:purged_anon", { now = worldHours }
))
assert(hotAnon.targetIdentity.status == "FORGOTTEN")
assert(hotAnon.targetIdentity.referenceMode == "ANONYMOUS")
assert(hotAnon.targetIdentity.displayName == nil)
assert(hotAnon.targetIdentity.degradedLabel == "someone")

-- Confirm ZERO GC ran during hot opens
local genAfterClick = (registry.gcMeta and registry.gcMeta.generation) or 0
assert(genAfterClick == genBeforeClick, "hot click must not trigger GC")
assert(SocialQuery.GetDiagnostics().gcCallsDuringHotOpen == 0)

-- Bounded SocialQuery.ExecutePlan (clamped to <= 8 even if 999 requested)
local planRes = assert(SocialQuery.ExecutePlan(registry, "npc:speaker_alice", {
    targetRef = "npc:live_target",
    maxMemories = 999,
}, { now = worldHours }))
assert(#planRes.memories <= 8, "ExecutePlan must enforce maxMemories <= 8")
assert(planRes.totalCandidateCount == 11)
assert(planRes.memories[1].type == "helped_in_combat")
assert(planRes.memories[1].graceHours == nil)

-- Token validation: valid -> accept, mutated social/relationship -> reject, retired speaker -> reject
assert(SocialQuery.ValidateDecisionToken(registry, hotLive.decisionToken) == true)

local latestSpeaker = assert(registry:Get("npc:speaker_alice"))
local updatedSocialState = assert(Social.NewState(latestSpeaker.social))
assert(Social.MutateRelationship(
    updatedSocialState,
    "npc:live_target",
    function(rel) rel.approval = 45; return rel end,
    "server",
    nil
))
assert(registry:Commit("npc:speaker_alice", { social = updatedSocialState }, latestSpeaker.revision))

local staleOK, staleReason = SocialQuery.ValidateDecisionToken(registry, hotLive.decisionToken)
assert(staleOK == false and staleReason == "social_revision_conflict")

local skipSocialOK, relConflict = SocialQuery.ValidateDecisionToken(
    registry, hotLive.decisionToken, { allowSocialAdvance = true }
)
assert(skipSocialOK == false and relConflict == "relationship_revision_conflict")

-- Interaction.AuthorizeConversation revision & lifecycle checks
local entryLive = {
    actorID = "npc:live_target",
    revision = 1,
    lifecycleRevision = 1,
    capabilities = { talk = true },
}
local talkReq = assert(Interaction.BuildNearbyConversation(entryLive, "player:1", 2))
local talkOK = assert(Interaction.AuthorizeConversation(talkReq, entryLive, {
    authority = "server",
    registry = registry,
}))
assert(talkOK == true)

talkReq.lifecycleRevision = 99
local staleReqOK, staleReqReason = Interaction.AuthorizeConversation(talkReq, entryLive, {
    authority = "server",
    registry = registry,
})
assert(staleReqOK == false and staleReqReason == "lifecycle_revision_conflict")

-- Retire speaking actor -> hot open & token validation reject
assert(registry:Retire("npc:speaker_alice", {
    authority = "server",
    reason = "death",
    retiredAt = worldHours,
}))
local deadOpen, deadErr = SocialQuery.OpenInteractionHotContext(
    registry, "npc:speaker_alice", "npc:live_target"
)
assert(deadOpen == nil and deadErr == "actor_retired")
local retiredTokOK, retiredTokErr = SocialQuery.ValidateDecisionToken(registry, hotLive.decisionToken)
assert(retiredTokOK == false and retiredTokErr == "actor_retired")

-- Enriched GC.GetDiagnostics checks
local diag = assert(GC.GetDiagnostics(registry, { now = worldHours }))
assert(diag.memoryCountsByClass ~= nil and diag.memoryCountsByClass.total == 0)
assert(diag.edgeCounts ~= nil and diag.edgeCounts.total == 0)
assert(diag.interactionQuery ~= nil and diag.interactionQuery.hotOpenCount == 6)

print("PASS psychopatz_social_lifecycle_semantic_projection_smoke")
