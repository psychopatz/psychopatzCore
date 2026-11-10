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
    return value
end

local World = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
local registry = World.NewRegistry({ worldSeed = 9117 })
local Service = World.FactionService

local created = truthy(Service.Upsert(registry, {
    id = "faction_service_fixture",
    name = "Service Fixture",
    archetypeID = "survivor.generic",
    memberActorIDs = { "actor_one" },
    leaderActorID = "actor_one",
}))
equal(created.leaderActorID, "actor_one", "initial leader committed")

local added, addReason = Service.AddMember(
    registry, "faction_service_fixture", "actor_two")
truthy(added, addReason)
equal(#added.memberActorIDs, 2, "member command updates Core")

local unchanged, unchangedReason = Service.AddMember(
    registry, "faction_service_fixture", "actor_two")
truthy(unchanged, "duplicate member query returns canonical state")
equal(unchangedReason, "unchanged", "duplicate member is idempotent")

local leader, leaderReason = Service.SetLeader(
    registry, "faction_service_fixture", "actor_two")
truthy(leader, leaderReason)
equal(leader.leaderActorID, "actor_two", "leader command updates Core")

local invalidLeader, invalidReason = Service.SetLeader(
    registry, "faction_service_fixture", "actor_missing")
equal(invalidLeader, nil, "non-member cannot become leader")
equal(invalidReason, "leader_not_member", "leader validation is explicit")

local removed, removeReason = Service.RemoveMember(
    registry, "faction_service_fixture", "actor_two")
truthy(removed, removeReason)
equal(removed.leaderActorID, nil, "removing leader clears Core leader")
equal(#removed.memberActorIDs, 1, "member removal updates Core")

local status, statusReason = Service.SetStatus(
    registry, "faction_service_fixture", "archived")
truthy(status, statusReason)
equal(status.status, "archived", "status command updates Core")
equal(Service.Get(registry, "faction_service_fixture").status,
    "archived", "query reads canonical registry")

print("psychopatz_survivor_world_faction_service_smoke: PASS")
