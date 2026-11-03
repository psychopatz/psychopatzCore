local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

isClient = function() return false end
isServer = function() return false end

local roots = {}
ModData = {
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
    get = function(key)
        return roots[key]
    end,
}

local initCallbacks = {}
local saveCallbacks = {}
Events = {
    OnInitGlobalModData = {
        Add = function(callback)
            initCallbacks[#initCallbacks + 1] = callback
        end,
    },
    OnSave = {
        Add = function(callback)
            saveCallbacks[#saveCallbacks + 1] = callback
        end,
    },
}

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Store = Actors.RuntimeStore
assert(Store and Store.Registry == Actors.DefaultRegistry,
    "default actor registry was not attached to production store")
assert(#initCallbacks >= 1 and #saveCallbacks >= 1,
    "production persistence hooks were not installed")

-- Simulate GlobalModData initialization before actor creation. Other Core
-- capabilities may also register initialization callbacks.
for _, callback in ipairs(initCallbacks) do callback() end

local actor, reason = Actors.DefaultRegistry:Create({
    actorId = "actor:runtime-store:test",
    identitySeed = "runtime-store",
    world = { position = { x = 100, y = 200, z = 0 } },
})
assert(actor, reason)

local acquired = assert(Actors.Provider.Acquire(actor, {
    provider = "DTAbstract",
    owner = "abstract:lifecycle",
    authority = "server",
    now = 1,
}))
assert(Actors.DefaultRegistry:Commit(
    actor.actorId, { providerLease = acquired.providerLease }, actor.revision))

local current = Actors.DefaultRegistry:Get(actor.actorId)
local journey = assert(Actors.World.StartJourney(current.world, actor.actorId, {
    journeyID = "journey:runtime-store:test",
    origin = { x = 100, y = 200, z = 0 },
    destination = { x = 300, y = 200, z = 0 },
    speed = 20,
    startAt = 1,
}, 1))
assert(Actors.DefaultRegistry:Commit(
    actor.actorId, { world = journey }, current.revision))

-- Real production OnSave callback writes the canonical registry to GlobalModData.
for _, callback in ipairs(saveCallbacks) do callback() end
local root = assert(roots[Store.STORAGE_KEY])
assert(type(root.registry) == "string" and root.registry ~= "",
    "OnSave did not persist actor registry")

-- A fresh registry attaches through the production runtime store and loads the
-- existing GlobalModData payload automatically.
local fresh = Actors.NewRegistry()
Store.Registry = nil
Store.Loaded = false
local attached, attachReason = Store.Attach(fresh)
assert(attached, attachReason)

local restored = assert(fresh:Get("actor:runtime-store:test"),
    "fresh registry did not restore actor")
assert(restored.providerLease.provider == "DTAbstract"
    and restored.providerLease.state == "abstract",
    "provider lease did not survive production reload")
assert(restored.world.journey
    and restored.world.journey.journeyID == "journey:runtime-store:test",
    "journey did not survive production reload")
assert(Actors.World.ProjectPosition(restored.world, 6).x == 200,
    "restored journey projection is incorrect")

print("psychopatz_actor_runtime_store_smoke: PASS")
