local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

local Travel = require "PsychopatzCore/Travel/PsychopatzTravel"
local Traversal = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTraversal"

local group = {
    id = "group:travel:contract",
    memberActorIDs = { "actor:travel:contract" },
    location = { id = "origin", x = 0, y = 0, z = 0 },
    state = "IDLE",
}

local registry = {
    groups = { [group.id] = group },
}

function registry:GetGroup(groupID)
    return self.groups[groupID]
end

function registry:StartGroupJourney(groupID, spec, now)
    local updated, reason = Traversal.Start(
        self.groups[groupID],
        spec,
        now
    )
    if not updated then return nil, reason end
    self.groups[groupID] = updated
    return updated
end

function registry:AdvanceGroupJourney(groupID, now)
    local updated, reason = Traversal.Advance(
        self.groups[groupID],
        now
    )
    if not updated then return nil, reason end
    self.groups[groupID] = updated
    return updated
end

function registry:RebaseGroupJourney(groupID, origin, now)
    local updated, reason = Traversal.Rebase(
        self.groups[groupID],
        origin,
        now
    )
    if not updated then return nil, reason end
    self.groups[groupID] = updated
    return updated
end

function registry:CancelGroupJourney(groupID, reason)
    local updated, failure = Traversal.Cancel(
        self.groups[groupID],
        reason
    )
    if not updated then return nil, failure end
    self.groups[groupID] = updated
    return updated
end

function registry:ProjectGroupPosition(groupID, now)
    return Traversal.ProjectGroupPosition(self.groups[groupID], now)
end

function registry:ProjectGroupMemberPosition(
    groupID,
    actorID,
    actorWorld,
    now
)
    return Traversal.ProjectMemberPosition(
        self.groups[groupID],
        actorID,
        actorWorld,
        now
    )
end

local received = {}
local owner = "travel-contract-smoke"
local function onEvent(event)
    received[#received + 1] = event
end
for _, eventType in pairs(Travel.EventTypes) do
    Travel.Subscribe(eventType, onEvent, owner)
end

local started = assert(Travel.Registry.Start(registry, group.id, {
    ownerMod = "TestProvider",
    ownerRef = "contract",
    mode = "abstract",
    origin = { x = 0, y = 0, z = 0 },
    destination = { id = "destination", x = 100, y = 0, z = 0 },
    speed = 10,
    startAt = 1,
}, 0))
assert(started.journey.ownerMod == "TestProvider",
    "Core travel lost journey ownership metadata")
assert(received[1].type == Travel.EventTypes.GROUP_STARTED,
    "Core travel did not emit group started")
assert(received[1].contractVersion == 1,
    "Core travel event contract version missing")

local advanced = assert(Travel.Registry.Advance(registry, group.id, 5))
assert(advanced.journey.state == "en_route",
    "Core travel did not advance group journey")
assert(received[2].type == Travel.EventTypes.GROUP_STATE_CHANGED,
    "Core travel did not emit state transition")

local projected = assert(Travel.Registry.ProjectPosition(
    registry,
    group.id,
    5
))
assert(math.abs(projected.x - 40) < 0.001,
    "Core travel projection changed")

local rebased = assert(Travel.Registry.Rebase(
    registry,
    group.id,
    { x = 50, y = 10, z = 0 },
    5
))
assert(rebased.journey.origin.y == 10,
    "Core travel rebase did not update origin")

local cancelled = assert(Travel.Registry.Cancel(
    registry,
    group.id,
    "contract_test"
))
assert(cancelled.journey.state == "cancelled",
    "Core travel cancel did not update state")
assert(received[#received].type == Travel.EventTypes.GROUP_CANCELLED,
    "Core travel did not emit cancellation")

for _, eventType in pairs(Travel.EventTypes) do
    Travel.Unsubscribe(eventType, onEvent)
end
print("psychopatz_travel_contract_smoke: PASS")
