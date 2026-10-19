local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

-- Core-only configuration: provider transitions must not import a trading or
-- Hoomans package merely because the actor registry is loaded.
DTCommon = nil
DTHoomans = nil
PNC = nil

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
    actorId = "npc:p9:matrix",
    identitySeed = "p9-matrix-seed",
    social = {
        relationships = {
            ["player:user:alice"] = {
                target = "player:user:alice",
                approval = 42,
                respect = 22,
                familiarity = 15,
            },
        },
    },
    world = { position = { x = 1, y = 2, z = 0 } },
})
truthy(actor, actorReason)
local duplicate, duplicateReason = registry:Create({
    actorId = actor.actorId,
    identitySeed = "p9-duplicate",
})
equal(duplicate, nil, "Core-only duplicate actor rejected")
equal(duplicateReason, "duplicate_actor_id", "duplicate actor reason")

local start = os.clock()
for index = 1, 32 do
    local created, reason = registry:Create({
        actorId = "npc:p9:bounded:" .. tostring(index),
        identitySeed = "p9-bounded:" .. tostring(index),
    })
    truthy(created, reason)
end
equal(registry:Count(), 33, "bounded actor registry population")
truthy(os.clock() - start < 5, "bounded actor creation remains finite")

local leased, leaseReason = registry:AcquireProvider(actor.actorId, {
    provider = "DTAbstract", owner = "p9:server", authority = "server",
    now = 10,
})
truthy(leased, leaseReason)
local materialized, materializeReason = registry:MaterializeProvider(
    actor.actorId,
    {
        provider = "DTAbstract", owner = "p9:server",
        bodyID = "body:p9:matrix", authority = "server", now = 11,
    }
)
truthy(materialized, materializeReason)
local dematerialized, dematerializeReason = registry:DematerializeProvider(
    actor.actorId,
    {
        provider = "DTAbstract", owner = "p9:server",
        bodyID = "body:p9:matrix", authority = "server", now = 12,
    }
)
truthy(dematerialized, dematerializeReason)
local released, releaseReason = registry:ReleaseProvider(actor.actorId, {
    provider = "DTAbstract", owner = "p9:server", authority = "server",
    now = 13,
})
truthy(released, releaseReason)

local saved, saveReason = registry:Save()
truthy(saved, saveReason)
local fresh = Actors.NewRegistry()
truthy(fresh:Load(saved), "Core-only matrix reload")
local restored = fresh:Get(actor.actorId)
equal(restored.identity.identitySeed, actor.identity.identitySeed,
    "identity continuity")
equal(restored.appearance.contract.policyHash,
    actor.appearance.contract.policyHash, "appearance continuity")
equal(restored.personalInventory.items[1].itemId,
    actor.personalInventory.items[1].itemId, "inventory continuity")
equal(restored.social.relationships["player:user:alice"].approval,
    actor.social.relationships["player:user:alice"].approval,
    "social continuity")
equal(restored.world.location.position.x, actor.world.location.position.x,
    "world continuity")
equal(restored.providerLease.state, "released", "lease continuity")
local projection, projectionReason = Provider.Project(restored, "DTAbstract")
truthy(projection, projectionReason)
equal(projection.personalInventory.items[1].itemId,
    actor.personalInventory.items[1].itemId, "projection parity after reload")

print("psychopatz_npc_acceptance_matrix_smoke: PASS")
