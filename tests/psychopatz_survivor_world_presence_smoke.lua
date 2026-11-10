local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Settings = require "PsychopatzCore/Debug/PsychopatzDebugSettings"
local Presence = World.Presence

PsychopatzCore.Debug = {
    CanUse = function() return true end,
}

local registry = Actors.NewRegistry()
Actors.DefaultRegistry = registry
local actor = assert(registry:Create({
    actorId = "npc:presence:smoke",
    identitySeed = "presence-smoke",
    world = { position = { x = 10, y = 20, z = 0 } },
}))

local adoptionActor = assert(registry:Create({
    actorId = "npc:presence:adoption-smoke",
    identitySeed = "presence-adoption-smoke",
    world = { position = { x = 11, y = 21, z = 0 } },
}))
local adopted = assert(Presence.EnsureAbstract(adoptionActor.actorId, {
    provider = "ProjectHoomans",
    owner = "ProjectHoomans:abstract",
    now = 1,
}))
assert(adopted.providerLease.provider == "ProjectHoomans")
assert(adopted.providerLease.state == "abstract")
local switched = assert(Presence.EnsureAbstract(adoptionActor.actorId, {
    provider = "DTAbstract",
    owner = "dtcommon:trader_world",
    now = 2,
}))
assert(switched.providerLease.provider == "DTAbstract")
assert(switched.providerLease.state == "abstract")

local providerID = "ProjectHoomans"
assert(Presence.RegisterProvider(providerID, {
    priority = 1000,
    canForceLive = function() return true end,
    forceLive = function(current, core, spec)
        local acquired, acquireReason = registry:AcquireProvider(current.actorId, {
            provider = providerID,
            owner = spec.owner,
            authority = "server",
            now = spec.now,
        })
        assert(acquired, acquireReason)
        local live = assert(registry:MaterializeProvider(
            acquired.actorId,
            {
                provider = providerID,
                owner = spec.owner,
                bodyID = "body:presence:smoke",
                authority = "server",
                now = spec.now,
            }
        ))
        return { actor = live, bodyID = "body:presence:smoke" }
    end,
    release = function(current, core, spec)
        local released = assert(registry:DematerializeProvider(
            current.actorId,
            {
                provider = providerID,
                owner = spec.owner,
                bodyID = current.providerLease.bodyID,
                authority = "server",
                now = spec.now,
            }
        ))
        return { actor = released }
    end,
}))

local id = Presence.SETTING_ID
assert(Settings.Set(id, true, false))
assert(Settings.ApplyConfigured())
local live = assert(Presence.DebugForceLive({}, actor.actorId))
assert(live.providerLease.provider == providerID)
assert(live.providerLease.state == "materialized")
assert(Presence.Session[actor.actorId])

local bodyBlocked, bodyBlockedReason = Presence.EnsureAbstract(
    actor.actorId,
    {
        provider = "ProjectHoomans",
        owner = "ProjectHoomans:abstract",
        now = 3,
    }
)
assert(bodyBlocked == nil and bodyBlockedReason == "body_lease_active")

local abstract = assert(Presence.DebugRelease({}, actor.actorId))
assert(abstract.providerLease.provider == "PsychopatzCore")
assert(abstract.providerLease.state == "released")
assert(Presence.Session[actor.actorId] == nil)

assert(Settings.Set(id, false, false))
assert(Settings.ApplyConfigured())
local blocked, reason = Presence.DebugForceLive({}, actor.actorId)
assert(blocked == nil and reason == "debug_not_authorized")

print("psychopatz_survivor_world_presence_smoke: PASS")
