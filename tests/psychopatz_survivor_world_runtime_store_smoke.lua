local T = require "tests/support/test"
T.addPackagePaths()

local COMMON = T.layerRoot("common_shared")
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

local faction = assert(fresh:GetFaction("faction_runtime"))
faction.name = "Unsaved faction promotion"
assert(fresh:UpsertFaction(faction))
assert(Store.MarkDirty("unsaved_promotion"))
local activated = assert(World.ActivateRuntime())
assert(activated == fresh, "repeated activation reuses the live registry")
assert(activated:GetFaction(faction.id).name == faction.name,
    "activation must preserve unsaved canonical mutations")
assert(root.registry == before,
    "activation must not save synchronously")

-- Large SurvivorWorld payloads (>30,000 bytes) must split into UTF-8-safe
-- registryChunks so Project Zomboid's signed 16-bit GlobalModData string
-- reader never overflows on reload.
for i = 1, 250 do
    assert(fresh:UpsertFaction({
        id = "faction_chunk_" .. tostring(i),
        name = "Chunked Faction " .. tostring(i) .. " " .. string.rep("x", 120),
    }))
end
assert(Store.MarkDirty("large_chunk_test"))
local savedLarge, saveLargeReason = Store.Save()
assert(savedLarge, saveLargeReason)
assert(root.registry == nil,
    "large SurvivorWorld must clear unchunked registry string")
assert(type(root.registryChunks) == "table" and #root.registryChunks >= 2,
    "large SurvivorWorld must persist across >= 2 registryChunks")
for i = 1, #root.registryChunks do
    assert(#root.registryChunks[i] <= Store.MAX_STRING_BYTES,
        "every SurvivorWorld chunk must stay <= MAX_STRING_BYTES")
end
Store.ResetForTests()
local reloadedLarge, reloadLargeReason = World.ActivateRuntime({ worldSeed = 1 })
assert(reloadedLarge, reloadLargeReason)
assert(reloadedLarge:GetFaction("faction_chunk_250") ~= nil,
    "chunked SurvivorWorld must restore all persisted factions")
assert(reloadedLarge:Counts().factions == 251,
    "chunked SurvivorWorld must restore exact O(1) faction count")

-- Regression: OnInitGlobalModData must NOT overwrite an already-loaded/dirty
-- live registry with an earlier provisional snapshot saved during startup
-- (e.g. OnCreatePlayer provisional diplomacy faction -> Replace+Save ->
-- StartingCompanions promoteProvisionalFaction + MarkDirty -> OnInitGlobalModData).
local provisionalWorld = assert(World.NewRegistry({ worldSeed = 777 }))
assert(provisionalWorld:UpsertFaction({
    id = "faction_player_start",
    name = "Player Diplomacy",
    archetypeID = "settler",
    tags = {
        provisionalPlayerFaction = true,
        hiddenFromFactionLists = true,
    },
}))
local liveReplaced = assert(Store.Replace(provisionalWorld:Snapshot(), "startup_import"))
assert(Store.Save())
assert(liveReplaced:UpsertFaction({
    id = "faction_player_start",
    name = "patz Company",
    archetypeID = "settler",
    tags = {
        automaticallyCreated = true,
        factionNamePending = true,
        promotedFromProvisional = true,
    },
}))
assert(Store.MarkDirty("promoted_provisional"))
for _, handler in ipairs(initCallbacks) do
    handler()
end
local afterInit = assert(Store.GetRegistry():GetFaction("faction_player_start"))
assert(afterInit.name == "patz Company",
    "OnInitGlobalModData must preserve promoted player faction name")
assert(afterInit.tags.provisionalPlayerFaction == nil,
    "OnInitGlobalModData must not revert promoted faction back to provisional")
assert(afterInit.tags.promotedFromProvisional == true,
    "OnInitGlobalModData must preserve promotedFromProvisional tag")

print("psychopatz_survivor_world_runtime_store_smoke: PASS")
