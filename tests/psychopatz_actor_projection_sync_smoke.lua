local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local SERVER = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = table.concat({
    COMMON .. "?.lua",
    SERVER .. "?.lua",
    CLIENT .. "?.lua",
    package.path,
}, ";")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Projection = require "PsychopatzCore/Actors/PsychopatzActorProjection"

local authorityRegistry = Actors.NewRegistry()
local actor, reason = authorityRegistry:Create({
    actorId = "actor:projection:test",
    identitySeed = "projection-test",
    world = { position = { x = 100, y = 200, z = 0 } },
})
assert(actor, reason)

local world = Actors.World.StartJourney(actor.world, actor.actorId, {
    journeyID = "journey:projection:test",
    origin = { x = 100, y = 200, z = 0 },
    destination = { x = 300, y = 200, z = 0 },
    speed = 20,
    startAt = 0,
}, 0)
assert(world)
local committed = authorityRegistry:Commit(
    actor.actorId, { world = world }, actor.revision)
assert(committed)

-- Authority projection. This is the only object the client will receive.
local serverActor = authorityRegistry:Get(actor.actorId)
local Presentation =
    require "PsychopatzCore/Actors/PsychopatzActorPresentation"
local projected = assert(Projection.ProjectActor(serverActor, 5, {
    sourceID = "fixture",
    provider = "DTAbstract",
    providerState = "abstract",
    groupID = "agroup:projection",
    communityID = "community:projection",
    factionID = "faction:projection",
    role = "trader",
    markerID = "npc",
    label = "Projection Trader",
    portrait = Presentation.BuildPortrait(serverActor),
    capabilities = {
        select = true,
        track = true,
    },
}))
assert(projected.position.x == 200 and projected.position.y == 200,
    "authority projection did not use canonical journey position")

local snapshot = {
    schema = Projection.SCHEMA,
    schemaVersion = Projection.SCHEMA_VERSION,
    sourceID = "fixture",
    snapshotRevision = 1,
    entries = { projected },
}

-- Client store is intentionally distinct from the authority actor registry.
local clientStore = Projection.NewStore()
assert(clientStore ~= authorityRegistry, "client reused authority registry")
assert(clientStore:ApplySnapshot(snapshot))
local clientActor = assert(clientStore:Get(actor.actorId))
assert(clientActor.position.x == 200 and clientActor.position.y == 200,
    "client did not apply projected position")
assert(clientActor.journey.state == "en_route",
    "journey summary was not projected")
assert(clientActor.provider == "DTAbstract"
    and clientActor.providerState == "abstract",
    "provider presentation state was lost")
assert(clientActor.groupID == "agroup:projection"
    and clientActor.communityID == "community:projection"
    and clientActor.factionID == "faction:projection",
    "survivor-world context was lost in projection transport")
assert(clientActor.role == "trader"
    and clientActor.markerID == "npc",
    "role/marker metadata was lost")
assert(clientActor.portrait
    and clientActor.portrait.actorID == actor.actorId,
    "portrait metadata was lost")
assert(clientActor.capabilities
    and clientActor.capabilities.track == true,
    "capabilities were lost")

-- Advance only the authority. Client must remain unchanged until a new
-- projection revision is delivered.
local authorityActor = authorityRegistry:Get(actor.actorId)
local advanced = Actors.World.AdvanceJourney(authorityActor.world, 8)
assert(authorityRegistry:Commit(
    actor.actorId, { world = advanced }, authorityActor.revision))
assert(clientStore:Get(actor.actorId).position.x == 200,
    "client leaked authority registry mutation")

local nextProjection = assert(Projection.ProjectActor(
    authorityRegistry:Get(actor.actorId), 8, {
        sourceID = "fixture",
        provider = "DTAbstract",
        providerState = "abstract",
    }))
assert(nextProjection.position.x == 260,
    "authority second projection is wrong")
assert(clientStore:ApplySnapshot({
    schema = Projection.SCHEMA,
    schemaVersion = Projection.SCHEMA_VERSION,
    sourceID = "fixture",
    snapshotRevision = 2,
    entries = { nextProjection },
}))
assert(clientStore:Get(actor.actorId).position.x == 260,
    "client did not advance after new snapshot")

local stale, staleReason = clientStore:ApplySnapshot(snapshot)
assert(stale == false and staleReason == "stale_snapshot",
    "stale snapshot was not rejected")
assert(clientStore:Get(actor.actorId).position.x == 260,
    "stale snapshot rolled client state backward")

print("psychopatz_actor_projection_sync_smoke: PASS")
