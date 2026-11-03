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
local Persistence =
    require "PsychopatzCore/Actors/PsychopatzActorPersistence"

local registry = Actors.NewRegistry()
local COUNT = 900

for index = 1, COUNT do
    local actor, reason = registry:Create({
        actorId = string.format("large:actor:%04d", index),
        identitySeed = "large-registry-seed:" .. tostring(index),
        world = {
            location = {
                kind = "world",
                x = 1000 + index,
                y = 2000 + index,
                z = 0,
            },
        },
    })
    truthy(actor, reason)
end

equal(registry:Count(), COUNT, "source actor count")
local serialized, reason = registry:Save()
truthy(serialized, reason)
truthy(#serialized > 1024 * 1024,
    "fixture must exceed generic one-megabyte JSON decode limit")
truthy(#serialized < Persistence.MAX_REGISTRY_BYTES,
    "fixture remains inside actor-registry bound")

local fresh = Actors.NewRegistry()
truthy(fresh:Load(serialized), "large compact registry reload")
equal(fresh:Count(), COUNT, "reloaded actor count")

local first = fresh:Get("large:actor:0001")
local last = fresh:Get("large:actor:0900")
truthy(first and last, "boundary actors restored")
equal(first.personalInventory.mode, "SEED_ONLY",
    "first actor remains compact")
equal(last.personalInventory.mode, "SEED_ONLY",
    "last actor remains compact")
equal(last.world.location.position.x, 1900,
    "last actor world state restored")

print("psychopatz_actor_large_registry_smoke: PASS bytes=" .. #serialized)
