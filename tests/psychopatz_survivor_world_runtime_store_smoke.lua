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

local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
local Store = assert(World.RuntimeStore)

assert(next(roots) == nil,
    "loading SurvivorWorld must not allocate GlobalModData")
assert(#initCallbacks == 0 and #saveCallbacks == 0,
    "runtime hooks must be lazy until activation")

local registry, reason = World.ActivateRuntime({ worldSeed = 4242 })
assert(registry, reason)
assert(next(roots) == nil,
    "activation before GlobalModData init must remain allocation-free")
assert(#initCallbacks == 1 and #saveCallbacks == 1,
    "activation must install one persistence hook pair")

assert(registry:AddFaction({
    factionID = "faction_runtime",
    name = "Runtime Faction",
    archetypeID = "survivor",
}))
assert(registry:AddCommunity({
    communityID = "community_runtime",
    factionID = "faction_runtime",
    name = "Runtime Camp",
    home = { x = 100, y = 200, z = 0 },
}))
assert(registry:AddGroup({
    groupID = "agroup_runtime",
    factionID = "faction_runtime",
    homeCommunityID = "community_runtime",
    memberActorIDs = { "actor_runtime" },
    location = {
        id = "aloc_runtime",
        kind = "SETTLEMENT",
        x = 100, y = 200, z = 0,
    },
}))
assert(Store.MarkDirty("runtime_fixture"))

for _, callback in ipairs(initCallbacks) do callback() end
local root = assert(roots[Store.STORAGE_KEY])
assert(root.registry == nil,
    "initialization must not write before save")

for _, callback in ipairs(saveCallbacks) do callback() end
assert(type(root.registry) == "string" and root.registry ~= "",
    "OnSave must persist the Core SurvivorWorld")
assert(root.registryRevision == registry:Revision(),
    "persisted revision must match registry")

Store.ResetForTests()
local fresh, freshReason = World.ActivateRuntime({ worldSeed = 1 })
assert(fresh, freshReason)
assert(fresh:WorldSeed() == 4242,
    "existing persisted world must win over activation seed")
assert(fresh:GetFaction("faction_runtime"),
    "faction must restore from Core ModData")
assert(fresh:GetCommunity("community_runtime"),
    "community must restore from Core ModData")
assert(fresh:GetGroup("agroup_runtime"),
    "group must restore from Core ModData")

local before = root.registry
local unchanged, unchangedReason = Store.Save()
assert(unchanged == false and unchangedReason == "not_dirty",
    "clean runtime world must not rewrite ModData")
assert(root.registry == before,
    "clean save must leave payload unchanged")

print("psychopatz_survivor_world_runtime_store_smoke: PASS")
