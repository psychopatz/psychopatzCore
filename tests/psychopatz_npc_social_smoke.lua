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

local function nilReason(value, expected, label)
    equal(value, nil, label)
    equal(select(2, value), expected, label .. " reason")
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social

equal(Social.NormalizeTargetKey("npc:merchant:one"), "npc:merchant:one",
    "NPC target key")
equal(Social.NormalizeTargetKey("Alice"), nil, "username-only target rejected")

local state, stateReason = Social.NewState({
    personality = { patience = 0.7, greed = 0.2 },
    relationships = {
        ["npc:merchant:one"] = {
            approval = 12,
            respect = 4,
            familiarity = 8,
            revision = 3,
            memories = {
                { id = "memory:prior", type = "trade", createdAt = 11 },
            },
        },
        ["player:char:one"] = { approval = -5, respect = 2 },
    },
    recentEventIDs = { "event:prior" },
})
truthy(state, stateReason)
local relationship = Social.Get(state, "npc:merchant:one")
equal(relationship.approval, 12, "approval restored")
equal(relationship.memories[1].aboutKey, "npc:merchant:one",
    "memory target restored")

local unauthorized, unauthorizedReason = Social.RecordAuthorizedEvent(state, {
    targetKey = "npc:merchant:one",
    eventID = "event:client-forged",
    approvalDelta = 100,
    authority = "client",
    authorized = false,
})
equal(unauthorized, nil, "unauthorized event rejected")
equal(unauthorizedReason, "server_authority_required",
    "unauthorized reason")

local applied, appliedReason = Social.RecordAuthorizedEvent(state, {
    targetKey = "npc:merchant:one",
    eventID = "event:server-trade",
    type = "trade_completed",
    approvalDelta = 7,
    respectDelta = 3,
    familiarityDelta = 9,
    createdAt = 42,
    authority = "server",
    authorized = true,
    tags = { merchant = true },
})
truthy(applied, appliedReason)
local afterEvent = Social.Get(applied, "npc:merchant:one")
equal(afterEvent.approval, 19, "authorized approval delta")
equal(afterEvent.respect, 7, "authorized respect delta")
equal(afterEvent.familiarity, 17, "authorized familiarity delta")
equal(afterEvent.memories[#afterEvent.memories].id, "event:server-trade",
    "event memory recorded")

local duplicate, duplicateReason = Social.RecordAuthorizedEvent(applied, {
    targetKey = "npc:merchant:one",
    eventID = "event:server-trade",
    approvalDelta = 100,
    authority = "server",
    authorized = true,
})
equal(duplicate, nil, "duplicate event rejected")
equal(duplicateReason, "duplicate_event", "duplicate event reason")
equal(Social.Get(applied, "npc:merchant:one").approval, 19,
    "duplicate event did not mutate score")

local personality, personalityReason = Social.SetPersonality(applied,
    { patience = 0.9 }, "client")
equal(personality, nil, "client personality mutation rejected")
equal(personalityReason, "server_authority_required", "personality authority")
local revised, revisedReason = Social.SetPersonality(applied,
    { patience = 0.9 }, "server", applied.revision)
truthy(revised, revisedReason)
equal(revised.personality.patience, 0.9, "server personality mutation")

local actorRegistry = Actors.NewRegistry()
local actor, actorReason = actorRegistry:Create({
    actorId = "npc:social:actor",
    identitySeed = "social-seed",
    social = revised,
})
truthy(actor, actorReason)
local saved, saveReason = actorRegistry:Save()
truthy(saved, saveReason)
local fresh = Actors.NewRegistry()
truthy(fresh:Load(saved), "social registry reload")
local restored = fresh:Get("npc:social:actor")
truthy(restored, "social actor reload")
local restoredRelationship = Social.Get(restored.social, "npc:merchant:one")
equal(restoredRelationship.approval, 19, "social approval survives reload")
equal(restoredRelationship.memories[#restoredRelationship.memories].id,
    "event:server-trade", "social memory survives reload")
equal(restored.social.personality.patience, 0.9,
    "social personality survives reload")

local invalid, invalidReason = Social.NewState({
    relationships = { Alice = { approval = 1 } },
})
equal(invalid, nil, "invalid relationship target rejected")
equal(invalidReason, "relationship_target_invalid",
    "invalid relationship reason")

print("psychopatz_npc_social_smoke: PASS")
