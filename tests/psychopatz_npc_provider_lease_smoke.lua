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
local Provider = Actors.Provider
local registry = Actors.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:p8:provider",
    identitySeed = "p8-provider-seed",
    social = {
        relationships = {
            ["player:user:alice"] = {
                target = "player:user:alice",
                approval = 24,
                respect = 11,
                familiarity = 8,
            },
        },
    },
    world = { position = { x = 5, y = 6, z = 0 } },
})
truthy(actor, actorReason)
equal(actor.providerLease.state, "released", "new actor lease state")

local clientAttempt, clientReason = Provider.Acquire(actor, {
    provider = "DTAbstract",
    owner = "client:spoof",
    authority = "client",
})
equal(clientAttempt, nil, "client cannot mutate provider lease")
equal(clientReason, "server_authority_required", "provider authority boundary")

local abstract, abstractReason = registry:AcquireProvider(actor.actorId, {
    provider = "DTAbstract",
    owner = "dtabstract:radio",
    authority = "server",
    now = 1,
})
truthy(abstract, abstractReason)
equal(abstract.providerLease.provider, "DTAbstract", "abstract provider")
equal(abstract.providerLease.state, "abstract", "abstract lease")

local competing, competingReason = registry:AcquireProvider(actor.actorId, {
    provider = "DTHoomans",
    owner = "dthoomans:body",
    now = 2,
})
equal(competing, nil, "second provider cannot claim lease")
equal(competingReason, "provider_lease_owned", "provider ownership boundary")

local materialized, materializeReason = registry:MaterializeProvider(
    actor.actorId,
    {
        provider = "DTAbstract",
        owner = "dtabstract:radio",
        bodyID = "body:p8:one",
        now = 3,
    }
)
truthy(materialized, materializeReason)
equal(materialized.providerLease.state, "materialized", "body materialized")
equal(materialized.providerLease.bodyID, "body:p8:one", "body lease id")

local secondBody, secondBodyReason = registry:MaterializeProvider(
    actor.actorId,
    {
        provider = "DTAbstract",
        owner = "dtabstract:radio",
        bodyID = "body:p8:two",
        now = 4,
    }
)
equal(secondBody, nil, "second body cannot attach")
equal(secondBodyReason, "body_lease_active", "single body ownership")

local otherActor = registry:Create({
    actorId = "npc:p8:other-body",
    identitySeed = "p8-other-body-seed",
})
truthy(otherActor, "second actor for body ownership")
truthy(registry:AcquireProvider(otherActor.actorId, {
    provider = "DTHoomans", owner = "dthoomans:other", now = 4,
}))
local claimed, claimedReason = registry:MaterializeProvider(
    otherActor.actorId,
    {
        provider = "DTHoomans", owner = "dthoomans:other",
        bodyID = "body:p8:one", now = 4,
    }
)
equal(claimed, nil, "body cannot be claimed by another actor")
equal(claimedReason, "body_lease_claimed", "global body ownership")

local before = registry:Get(actor.actorId)
local projection, projectionReason = Provider.Project(before, "DTAbstract")
truthy(projection, projectionReason)
equal(projection.identity.identitySeed, before.identity.identitySeed,
    "projection identity")
equal(projection.appearance.contract.policyHash,
    before.appearance.contract.policyHash, "projection appearance")
equal(projection.personalInventory.items[1].itemId,
    before.personalInventory.items[1].itemId, "projection inventory")
equal(projection.social.relationships["player:user:alice"].approval,
    before.social.relationships["player:user:alice"].approval,
    "projection social")
equal(projection.world.location.position.x,
    before.world.location.position.x, "projection world")

local abstractAgain, dematerializeReason = registry:DematerializeProvider(
    actor.actorId,
    {
        provider = "DTAbstract",
        owner = "dtabstract:radio",
        bodyID = "body:p8:one",
        now = 6,
    }
)
truthy(abstractAgain, dematerializeReason)
equal(abstractAgain.providerLease.state, "abstract", "body dematerialized")
equal(abstractAgain.providerLease.bodyID, nil, "body handle released")

local released, releaseReason = registry:ReleaseProvider(actor.actorId, {
    provider = "DTAbstract",
    owner = "dtabstract:radio",
    now = 7,
})
truthy(released, releaseReason)
equal(released.providerLease.state, "released", "provider released")

local hoomans, hoomansReason = registry:AcquireProvider(actor.actorId, {
    provider = "DTHoomans",
    owner = "dthoomans:body",
    now = 8,
})
truthy(hoomans, hoomansReason)
local body, bodyReason = registry:MaterializeProvider(actor.actorId, {
    provider = "DTHoomans",
    owner = "dthoomans:body",
    bodyID = "body:p8:two",
    now = 9,
})
truthy(body, bodyReason)

local payload, saveReason = registry:Save()
truthy(payload, saveReason)
local fresh = Actors.NewRegistry()
truthy(fresh:Load(payload), "provider lease reload")
local restored = fresh:Get(actor.actorId)
equal(restored.providerLease.provider, "DTHoomans", "provider survives reload")
equal(restored.providerLease.bodyID, "body:p8:two", "body survives reload")
local restoredProjection = Provider.Project(restored, "DTHoomans")
equal(restoredProjection.personalInventory.items[1].itemId,
    before.personalInventory.items[1].itemId, "inventory survives provider switch")
equal(restoredProjection.social.relationships["player:user:alice"].respect,
    before.social.relationships["player:user:alice"].respect,
    "social survives provider switch")

print("psychopatz_npc_provider_lease_smoke: PASS")
