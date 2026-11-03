local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local ActorWorld = require "PsychopatzCore/Actors/PsychopatzActorWorld"
local GroupJourney = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"

local Traversal = {}

local function hasMember(group, actorID)
    actorID = tostring(actorID or "")
    for _, memberID in ipairs(
        type(group) == "table"
            and group.memberActorIDs or {}
    ) do
        if tostring(memberID) == actorID then return true end
    end
    return false
end

local function locationAt(group, position, arrived)
    local location = Util.clone(
        type(group.location) == "table"
            and group.location or {}
    )
    location.x = position.x
    location.y = position.y
    location.z = position.z
    if arrived then
        local target = type(group.targetLocation) == "table"
            and group.targetLocation or {}
        location.id = group.journey
            and group.journey.destinationAnchorID
            or target.id
            or location.id
        location.kind = target.kind or location.kind or "world"
    end
    return location
end

function Traversal.Start(group, spec, now)
    if type(group) ~= "table" or not group.id then
        return nil, "group_required"
    end
    spec = type(spec) == "table" and Util.clone(spec) or {}
    spec.origin = spec.origin or group.location
    spec.destination = spec.destination
        or spec.targetLocation
        or group.targetLocation
    if not spec.destination then
        return nil, "group_journey_destination_required"
    end
    spec.originAnchorID = spec.originAnchorID
        or (type(group.location) == "table"
            and group.location.id)
    spec.destinationAnchorID = spec.destinationAnchorID
        or (type(spec.destination) == "table"
            and (spec.destination.id
                or spec.destination.locationID))
    local journey, reason =
        GroupJourney.New(group.id, spec, now)
    if not journey then return nil, reason end

    local copy = Util.clone(group)
    copy.journey = journey
    copy.state = journey.state == "arrived"
        and "ARRIVED" or "TRAVELING"
    copy.targetLocation = Util.clone(
        spec.targetLocation or spec.destination
    )
    copy.stateStartedAt = tonumber(now)
        or tonumber(journey.startAt) or 0
    copy.stateEndsAt = tonumber(journey.eta) or 0
    copy.revision = (tonumber(group.revision) or 0) + 1
    return copy
end

function Traversal.Advance(group, now)
    if type(group) ~= "table" then
        return nil, "group_required"
    end
    if type(group.journey) ~= "table" then
        return Util.clone(group)
    end
    local journey, reason =
        GroupJourney.Advance(group.journey, now)
    if not journey then return nil, reason end

    local position = {
        x = journey.x,
        y = journey.y,
        z = journey.z,
    }
    local copy = Util.clone(group)
    copy.journey = journey
    copy.location = locationAt(
        copy,
        position,
        journey.state == "arrived"
    )
    copy.stateEndsAt = tonumber(journey.eta) or 0
    if journey.state == "arrived" then
        copy.state = "ARRIVED"
        copy.targetLocation = nil
    elseif journey.state == "cancelled"
        or journey.state == "blocked"
    then
        copy.state = "IDLE"
        copy.targetLocation = nil
    else
        copy.state = "TRAVELING"
    end
    copy.revision = (tonumber(group.revision) or 0) + 1
    return copy
end

function Traversal.Rebase(group, origin, now)
    if type(group) ~= "table"
        or type(group.journey) ~= "table"
    then
        return nil, "group_journey_required"
    end
    local journey, reason =
        GroupJourney.Rebase(group.journey, origin, now)
    if not journey then return nil, reason end
    local copy = Util.clone(group)
    copy.journey = journey
    copy.location = locationAt(copy, {
        x = journey.x,
        y = journey.y,
        z = journey.z,
    }, false)
    copy.stateEndsAt = tonumber(journey.eta) or 0
    copy.revision = (tonumber(group.revision) or 0) + 1
    return copy
end

function Traversal.Cancel(group, reason)
    if type(group) ~= "table"
        or type(group.journey) ~= "table"
    then
        return nil, "group_journey_required"
    end
    local journey, failure =
        GroupJourney.Cancel(group.journey, reason)
    if not journey then return nil, failure end
    local copy = Util.clone(group)
    copy.journey = journey
    copy.state = "IDLE"
    copy.targetLocation = nil
    copy.stateEndsAt = 0
    copy.revision = (tonumber(group.revision) or 0) + 1
    return copy
end

function Traversal.ProjectGroupPosition(group, now)
    if type(group) ~= "table" then
        return nil, "group_required"
    end
    if type(group.journey) == "table" then
        return GroupJourney.ProjectPosition(group.journey, now)
    end
    local location = type(group.location) == "table"
        and group.location or {}
    return {
        x = tonumber(location.x) or 0,
        y = tonumber(location.y) or 0,
        z = tonumber(location.z) or 0,
    }
end

function Traversal.ProjectMemberPosition(
    group,
    actorID,
    actorWorld,
    now
)
    if type(group) ~= "table" then
        return nil, "group_required"
    end
    if not hasMember(group, actorID) then
        return nil, "group_member_not_found"
    end
    if type(actorWorld) == "table"
        and type(actorWorld.journey) == "table"
    then
        local position, reason =
            ActorWorld.ProjectPosition(actorWorld, now)
        if not position then return nil, reason end
        return position, "actor_override"
    end
    local position, reason =
        Traversal.ProjectGroupPosition(group, now)
    if not position then return nil, reason end
    return position, "group"
end

Traversal.GroupJourney = GroupJourney

return Traversal
