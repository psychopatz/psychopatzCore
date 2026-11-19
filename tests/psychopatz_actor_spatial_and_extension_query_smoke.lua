local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local SHARED = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
package.path = table.concat({
    COMMON .. "?.lua",
    SHARED .. "?.lua",
    package.path,
}, ";")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Identity = require "PsychopatzCore/Actors/PsychopatzActorIdentity"

local registry = Actors.NewRegistry()

for i = 1, 200 do
    local x, y
    if i <= 3 then
        x = 1000 + (i - 1) * 4
        y = 2000
    elseif i == 4 then
        x = 1004
        y = 2000
    else
        x = 20000 + i * 25
        y = 20000
    end
    local ext = nil
    if i == 2 or i == 50 then
        ext = {
            ["ProjectHoomans.ActorExtension"] = { schemaVersion = 1, recruited = i == 2 },
        }
    end
    local lease = nil
    if i == 3 then
        lease = {
            provider = "ProjectHoomans",
            owner = "ProjectHoomans:test",
            state = "materialized",
            bodyID = "body:3",
        }
    end
    assert(registry:Create({
        actorId = string.format("actor:%03d", i),
        identitySeed = "seed:" .. tostring(i),
        extensions = ext,
        providerLease = lease,
        world = { location = { position = { x = x, y = y, z = 0 } } },
    }))
end

assert(registry:HasActiveActor("actor:001") == true)
assert(registry:HasActiveActor("actor:missing") == false)

local near = registry:QueryNearPosition(1000, 2000, 12)
assert(#near == 4, "expected 4 nearby actors, got " .. tostring(#near))
assert(near[1].actorId == "actor:001" and near[1].distSq == 0)
assert(near[2].actorId == "actor:002" and near[2].distSq == 16)
assert(near[3].actorId == "actor:004" and near[3].distSq == 16)
assert(near[4].actorId == "actor:003" and near[4].distSq == 64)

local limited = registry:QueryNearPosition(1000, 2000, 12, { limit = 2 })
assert(#limited == 2)
assert(limited[1].actorId == "actor:001")
assert(limited[2].actorId == "actor:002")

local filtered = registry:QueryNearPosition(1000, 2000, 12, {
    filter = function(actor)
        return type(actor.extensions) == "table"
            and actor.extensions["ProjectHoomans.ActorExtension"] ~= nil
    end,
})
assert(#filtered == 1 and filtered[1].actorId == "actor:002")

-- Incremental Commit position update (out of range & back in range) + O(1) non-identity commit
local a2 = assert(registry:Get("actor:002"))
local moved = assert(registry:Commit("actor:002", {
    world = { location = { position = { x = 5000, y = 5000, z = 0 } } },
}, a2.revision))
near = registry:QueryNearPosition(1000, 2000, 12)
assert(#near == 3, "moved actor must leave nearby cell query")
assert(registry:QueryNearPosition(5000, 5000, 2)[1].actorId == "actor:002")

-- O(1) non-identity Commit still preserves identity resolution & AttachIdentity updates alias
local okExt = assert(registry:AttachExtension("actor:002", "ProjectHoomans.ActorExtension", {
    schemaVersion = 1,
    recruited = true,
}))
local ext = registry:GetExtension("actor:002", "ProjectHoomans.ActorExtension")
assert(ext and ext.recruited == true)
assert(registry:AttachIdentity("actor:002", { aliases = { "legacy_alias_2" } }))
local resolvedByAlias = assert(registry:Resolve("legacy_alias_2"))
assert(resolvedByAlias.actorId == "actor:002")

-- ListWithExtension & ListMaterialized avoid returning all 200 actors
local withExt = registry:ListWithExtension("ProjectHoomans.ActorExtension")
assert(#withExt == 2)
assert(withExt[1].actorId == "actor:002" and withExt[2].actorId == "actor:050")
local materialized = registry:ListMaterialized()
assert(#materialized == 1 and materialized[1].actorId == "actor:003")

-- Remove, HardDelete, and Retire update spatial index immediately
assert(registry:Remove("actor:004"))
assert(#registry:QueryNearPosition(1000, 2000, 12) == 2)
assert(registry:HardDelete("actor:003", { authority = "server", reason = "test_cleanup" }))
assert(#registry:QueryNearPosition(1000, 2000, 12) == 1)
assert(registry:Retire("actor:001", { authority = "server", reason = "departed", now = 1 }))
assert(#registry:QueryNearPosition(1000, 2000, 12) == 0)

-- Save & Load rebuilds spatial index cleanly
local serialized = assert(registry:Save())
local reloaded = Actors.NewRegistry()
assert(reloaded:Load(serialized))
local reloadedNear = reloaded:QueryNearPosition(5000, 5000, 5)
assert(#reloadedNear == 1 and reloadedNear[1].actorId == "actor:002")
assert(reloaded:HasActiveActor("actor:001") == false)
assert(reloaded:HasActiveActor("actor:050") == true)

print("PASS: psychopatz_actor_spatial_and_extension_query_smoke")
