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

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Authority = Actors.SocialAuthority

truthy(Authority, "social authority exported")
local registry = Actors.NewRegistry()
local core = { Actors = { DefaultRegistry = registry } }
local actor, actorReason = registry:Create({
    actorId = "npc:authority:one",
    identitySeed = "authority-seed",
})
truthy(actor, actorReason)

local initial, initialReason = Authority.GetSocial(actor.actorId, core)
truthy(initial, initialReason)
local committed, commitReason = Authority.MutateRelationship(
    actor.actorId,
    "player:char:one",
    function(relationship)
        relationship.approval = 24
        relationship.respect = 9
        relationship.familiarity = 3
        return relationship
    end,
    core,
    actor.revision,
    0
)
truthy(committed, commitReason)
local relationship = Authority.GetSocial(actor.actorId, core)
relationship = relationship and relationship.relationships["player:char:one"]
truthy(relationship, "relationship committed through authority")
equal(relationship.approval, 24, "authority approval")
equal(relationship.respect, 9, "authority respect")
equal(relationship.familiarity, 3, "authority familiarity")

local stale, staleReason = Authority.MutateRelationship(
    actor.actorId,
    "player:char:one",
    function(value)
        value.approval = 90
        return value
    end,
    core,
    actor.revision,
    relationship.revision
)
equal(stale, nil, "stale actor revision rejected")
equal(staleReason, "revision_conflict", "stale actor revision reason")

local current = registry:Get(actor.actorId)
local eventActor, eventReason = Authority.RecordAuthorizedEvent(
    actor.actorId,
    {
        targetKey = "player:char:one",
        eventID = "event:authority-trade",
        type = "trade_completed",
        approvalDelta = 5,
        authority = "server",
        authorized = true,
    },
    core,
    current.revision
)
truthy(eventActor, eventReason)
local afterEvent = Authority.GetSocial(actor.actorId, core)
equal(afterEvent.relationships["player:char:one"].approval, 29,
    "authorized event approval")

print("psychopatz_actor_social_authority_smoke: PASS")
