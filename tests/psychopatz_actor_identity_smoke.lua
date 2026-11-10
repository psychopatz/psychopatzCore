local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = table.concat({
    COMMON .. "?.lua",
    CLIENT .. "?.lua",
    package.path,
}, ";")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Identity = require "PsychopatzCore/Actors/PsychopatzActorIdentity"
local Projection = require "PsychopatzCore/Actors/PsychopatzActorProjection"
local Presentation = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresentation"

local registry = Actors.NewRegistry()
local actor = assert(registry:Create({
    actorId = "dt:caravan:member:1",
    identitySeed = "identity-smoke",
    source = { traderID = "trader:identity:1" },
    extensions = {
        [Identity.EXTENSION] = {
            canonicalActorID = "actor:identity:1",
            aliases = { "npcLegacyIdentity", "dtMemberIdentity" },
            providerID = "DTAbstract",
            presenceState = "abstract",
            capabilities = {
                ["conversation"] = true,
                ["DT.trade"] = true,
            },
        },
    },
    providerLease = {
        provider = "DTHoomans",
        owner = "DynamicTrading",
        state = "abstract",
    },
    world = { position = { x = 100, y = 200, z = 0 } },
}))

local resolved, resolution = assert(registry:Resolve("npcLegacyIdentity"))
assert(resolved.actorId == actor.actorId, "alias resolved wrong actor")
assert(resolution.canonicalActorID == "actor:identity:1",
    "resolver lost canonical actor ID")
assert(resolution.aliasKind == "alias", "resolver did not report alias")
assert(registry:HasReference("trader:identity:1"),
    "source trader reference was not indexed")

local projected = assert(Projection.ProjectActor(actor, 0, {
    sourceID = "fixture",
    portrait = assert(Actors.Presentation.BuildPortrait(actor)),
    capabilities = {
        conversation = true,
        ["DT.trade"] = true,
    },
}))
assert(projected.actorID == "actor:identity:1",
    "projection did not expose canonical actor ID")
assert(projected.providerState == "abstract"
    and projected.presenceState == "abstract",
    "projection lost abstract presence")
assert(projected.provider == "DTAbstract",
    "projection lost provider identity while actor was unreleased")
assert(projected.bodyID == nil, "abstract actor received a body ID")
assert(projected.aliases and #projected.aliases >= 3,
    "projection aliases were not preserved")

local store = Projection.NewStore()
assert(store:ApplySnapshot({
    schema = Projection.SCHEMA,
    schemaVersion = Projection.SCHEMA_VERSION,
    sourceID = "fixture",
    snapshotRevision = 1,
    entries = { projected },
}))
local byAlias, aliasInfo = assert(store:Resolve("dtMemberIdentity"))
assert(byAlias.actorID == "actor:identity:1",
    "client store did not resolve DT member alias")
assert(aliasInfo.aliasKind == "alias",
    "client store did not report alias resolution")
assert(store:Get("trader:identity:1").actorID == "actor:identity:1",
    "client store did not resolve trader reference")

local serialized = assert(registry:Save())
local restored = Actors.NewRegistry()
assert(restored:Load(serialized))
local restoredActor, restoredResolution = assert(
    restored:Resolve("npcLegacyIdentity")
)
assert(restoredActor.actorId == actor.actorId
    and restoredResolution.canonicalActorID == "actor:identity:1",
    "save/reload lost actor identity aliases")

local attached = assert(registry:AttachIdentity(actor.actorId, {
    aliases = { "attached:legacy" },
    providerID = "DTHoomans",
    project = true,
    capabilities = { ["DT.trade"] = true },
}))
assert(attached.extensions[Identity.EXTENSION].project == true,
    "identity attachment did not persist projection hint")
local attachedActor, attachedResolution = assert(
    registry:Resolve("attached:legacy")
)
assert(attachedActor.actorId == actor.actorId
    and attachedResolution.canonicalActorID == "actor:identity:1",
    "identity attachment did not update the live resolver")
local extended = assert(registry:AttachExtension(
    actor.actorId,
    "PsychopatzCore.SurvivorWorld",
    { factionID = "faction:identity" }
))
assert(extended.extensions["PsychopatzCore.SurvivorWorld"].factionID
    == "faction:identity",
    "generic extension attachment did not persist")

local world = { ListGroups = function() return {} end }
local entries = Presentation.BuildActorEntries(world, registry, 0, {
    sourceID = "fixture",
})
assert(#entries == 1 and entries[1].actorID == "actor:identity:1",
    "ungrouped active actor was not projected")
assert(entries[1].capabilities
    and entries[1].capabilities["DT.trade"] == true,
    "projection dropped actor trading capability")

print("psychopatz_actor_identity_smoke: PASS")
