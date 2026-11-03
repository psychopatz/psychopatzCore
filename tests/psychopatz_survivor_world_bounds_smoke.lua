local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal")
            .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
local Registry = World.Registry
local Types = World.Types
local Persistence = World.Persistence

equal(Registry.MAX_FACTIONS, 256, "faction bound")
equal(Registry.MAX_COMMUNITIES, 512, "community bound")
equal(Registry.MAX_LOCATIONS, 4096, "location bound")
equal(Registry.MAX_GROUPS, 1024, "group bound")
equal(Registry.MAX_SECTORS, 4096, "sector bound")
equal(Registry.MAX_DISCOVERY_PLAYERS, 256,
    "discovery-player bound")
equal(Types.MAX_GROUP_MEMBERS, 128, "group-member bound")
equal(Types.MAX_DISCOVERY_ENTRIES, 4096,
    "discovery-entry bound")
equal(Persistence.MAX_BYTES, 32 * 1024 * 1024,
    "world persistence byte bound")

local registry = assert(World.NewRegistry({ worldSeed = 99117 }))
for index = 1, Registry.MAX_FACTIONS do
    local faction, reason = registry:AddFaction({
        factionID = "faction_bound_" .. tostring(index),
        name = "Bound Faction " .. tostring(index),
        archetypeID = "survivor",
    })
    truthy(faction, reason)
end

local overflow, overflowReason = registry:AddFaction({
    factionID = "faction_bound_overflow",
    name = "Overflow",
    archetypeID = "survivor",
})
equal(overflow, nil, "faction capacity rejects overflow")
equal(overflowReason, "survivor_world_capacity_exceeded",
    "faction overflow reason")

local members = {}
for index = Types.MAX_GROUP_MEMBERS + 20, 1, -1 do
    members[#members + 1] =
        "npc_member_" .. string.format("%03d", index)
end
local group = assert(Types.NormalizeGroup({
    groupID = "agroup_bound",
    factionID = "faction_bound_1",
    memberActorIDs = members,
    groupType = "TRADER",
    state = "IDLE",
    mission = "IDLE",
    location = {
        locationID = "aloc_bound",
        kind = "TEMPORARY",
        x = 1, y = 2, z = 0,
    },
}, 99117, "agroup_bound"))
equal(#group.memberActorIDs, Types.MAX_GROUP_MEMBERS,
    "direct normalized member list is bounded")
equal(group.memberActorIDs[1], "npc_member_001",
    "bounded member list deterministic/sorted")

local tooMany = {}
for index = 1, Types.MAX_GROUP_MEMBERS + 1 do
    tooMany[index] = "npc_overflow_" .. tostring(index)
end
local rejected, rejectedReason = registry:AddGroup({
    groupID = "agroup_overflow",
    factionID = "faction_bound_1",
    memberActorIDs = tooMany,
    location = { x = 1, y = 2, z = 0 },
})
equal(rejected, nil, "registry rejects oversized member input")
equal(rejectedReason, "survivor_world_group_member_capacity",
    "oversized member reason")

local first = Types.DeterministicID(
    "group", 99117, "psector_1", 42)
local second = Types.DeterministicID(
    "group", 99117, "psector_1", 42)
equal(first, second, "deterministic group ID")
truthy(#first <= Types.ID_MAX_LENGTH,
    "deterministic ID bounded")

print("psychopatz_survivor_world_bounds_smoke: PASS")
