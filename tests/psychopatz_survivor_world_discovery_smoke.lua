local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"

local plan = assert(World.Bootstrap.BuildPlan({
    seedString = "discovery-fixture",
    anchor = { x = 5000, y = 6000, z = 0 },
    communityCount = 3,
    groupCount = 3,
}))
local registry = assert(World.NewRegistry({
    worldSeed = plan.worldSeed,
}))
local actors = Actors.NewRegistry()
assert(World.Bootstrap.Commit(registry, plan, actors))

local Discovery = World.Discovery
local key = "player:discovery-fixture"
local communityID = plan.communities[1].communityID
local groupID = plan.groups[1].groupID

assert(Discovery.RegisterEntityProvider("fixture_signals", {
    list = function()
        return {
            {
                entityID = "signal:fixture",
                kind = "signal",
                name = "Fixture signal",
                x = 5100,
                y = 6100,
                z = 0,
            },
        }
    end,
}))

local entities = Discovery.ListWorldEntities(registry, 10)
local kinds = { community = 0, group = 0, signal = 0 }
for _, entity in ipairs(entities) do
    kinds[entity.kind] = (kinds[entity.kind] or 0) + 1
end
assert(kinds.community == 3, "community entities")
assert(kinds.group == 3, "group entities")
assert(kinds.signal == 1, "signal provider entity")

local rumored, reason, changed = Discovery.SetPhase(
    registry,
    key,
    "settlement",
    communityID,
    Discovery.PHASE_RUMORED,
    "radio",
    10
)
assert(rumored and reason == "advanced" and changed == true,
    "settlement alias rumor")
local repeated, repeatedReason, repeatedChanged =
    Discovery.SetPhase(
        registry,
        key,
        "community",
        communityID,
        Discovery.PHASE_RUMORED,
        "radio",
        11
    )
assert(repeated and repeatedReason == "unchanged"
    and repeatedChanged ~= true,
    "discovery phases must be monotonic")

local rumorSnapshot =
    Discovery.BuildSnapshot(registry, key, 11)
local rumorEntity
for _, entry in ipairs(rumorSnapshot.entities) do
    if entry.entityID == communityID then
        rumorEntity = entry
        break
    end
end
assert(rumorEntity, "rumored community snapshot")
assert(rumorEntity.phaseName == "RUMORED", "rumor phase name")
assert(rumorEntity.approximate == true, "rumor must be approximate")
local liveCommunity = registry:GetCommunity(communityID)
assert(
    rumorEntity.x ~= liveCommunity.home.x
        or rumorEntity.y ~= liveCommunity.home.y,
    "rumored coordinate should be deterministically offset"
)

local knownFaction, factionReason =
    Discovery.MarkFactionKnown(
        registry,
        key,
        "community",
        communityID,
        "conversation",
        12
    )
assert(knownFaction and factionReason == "advanced",
    "faction reveal")
assert(knownFaction.factionKnown == true,
    "faction knowledge")

local arrived, arrivalReason = Discovery.MarkArrived(
    registry,
    key,
    "mobile_group",
    groupID,
    Discovery.PRESENCE_ABSENT,
    "traversal",
    13
)
assert(arrived and arrivalReason == "advanced",
    "group arrival")
assert(arrived.phase == Discovery.PHASE_LOCATED,
    "arrival locates entity")
assert(arrived.arrivalState == Discovery.ARRIVAL_SEARCHED,
    "arrival search state")
assert(arrived.searchedAt == 13, "searched timestamp retained")

local contacted, contactReason = Discovery.MarkContacted(
    registry,
    key,
    "group",
    groupID,
    "conversation",
    14
)
assert(contacted and contactReason == "advanced",
    "group contact")
assert(contacted.phase == Discovery.PHASE_CONTACTED,
    "contacted phase")
assert(contacted.arrivalState == Discovery.ARRIVAL_CONTACTED,
    "contacted arrival state")
assert(contacted.presenceStatus == Discovery.PRESENCE_PRESENT,
    "contact confirms presence")
assert(contacted.contactedAt == 14,
    "contacted timestamp retained")

local signalCount = assert(Discovery.DiscoverAll(
    registry,
    key,
    "signals",
    Discovery.PHASE_LOCATED,
    "debug",
    15
))
assert(signalCount == 1, "signal debug scope")

local nearbyGroup = registry:GetGroup(groupID)
local nearbyPos = registry:ProjectGroupPosition(groupID, 15)
local nearCount = assert(Discovery.DiscoverNearby(
    registry,
    key,
    nearbyPos,
    {
        group = 1,
        community = 1,
        default = 0,
    },
    "proximity",
    15
))
assert(nearCount >= 0, "nearby scan")

local persisted = registry:GetDiscovery()
local player = assert(persisted.players[key],
    "discovery must persist in SurvivorWorld snapshot")
assert(player.entities.community[communityID],
    "community discovery persisted")
assert(player.entities.group[groupID].contactedAt == 14,
    "contact timestamp persisted through normalization")
assert(player.entities.signal["signal:fixture"],
    "signal discovery persisted")

local resetSignal, resetSignalReason, resetSignalChanged =
    Discovery.ResetEntity(
        registry,
        key,
        "signal",
        "signal:fixture"
    )
assert(resetSignal
    and resetSignalReason == "reset"
    and resetSignalChanged == true,
    "single-entity discovery reset")
local afterSignalReset =
    registry:GetDiscovery().players[key]
assert(afterSignalReset.entities.signal["signal:fixture"] == nil,
    "single-entity reset left signal discovery")
assert(afterSignalReset.entities.group[groupID] ~= nil,
    "single-entity reset erased unrelated group discovery")

local reset, resetReason, resetChanged =
    Discovery.ResetPlayer(registry, key)
assert(reset and resetReason == "reset"
    and resetChanged == true, "discovery reset")
local afterReset = registry:GetDiscovery().players[key]
assert(afterReset, "reset keeps player discovery record")
assert(next(afterReset.entities.community) == nil,
    "community discoveries reset")
assert(next(afterReset.entities.group) == nil,
    "group discoveries reset")
assert(next(afterReset.entities.signal) == nil,
    "signal discoveries reset")

Discovery.UnregisterEntityProvider("fixture_signals")
print("psychopatz_survivor_world_discovery_smoke: PASS")
