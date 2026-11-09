-- Provider-neutral travel contract for canonical actor and group journeys.
--
-- Core owns journey state, projection, and semantic lifecycle events. A
-- representation provider (abstract or physical) may consume this contract
-- without importing the other provider or Project Hoomans policy.

PsychopatzCore = PsychopatzCore or {}

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Traversal = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTraversal"
local GroupJourney = Traversal.GroupJourney
local Events = require "PsychopatzCore/Events/PC_EventBus"

local Travel = PsychopatzCore.Travel or {}
local EventTypes = Travel.EventTypes or {
    GROUP_STARTED = "PsychopatzCore.Travel.GroupJourneyStarted",
    GROUP_STATE_CHANGED = "PsychopatzCore.Travel.GroupJourneyStateChanged",
    GROUP_ARRIVED = "PsychopatzCore.Travel.GroupJourneyArrived",
    GROUP_REBASED = "PsychopatzCore.Travel.GroupJourneyRebased",
    GROUP_CANCELLED = "PsychopatzCore.Travel.GroupJourneyCancelled",
}

local function journeyOf(group)
    return type(group) == "table"
        and type(group.journey) == "table"
        and group.journey or nil
end

local function stateOf(group)
    local journey = journeyOf(group)
    return journey and journey.state or nil
end

local function eventPayload(eventType, operation, group, previous, reason)
    local journey = journeyOf(group)
    return {
        contractVersion = Travel.API_VERSION,
        type = eventType,
        operation = operation,
        groupID = group and group.id or nil,
        journeyID = journey and journey.journeyID or nil,
        ownerMod = journey and journey.ownerMod or nil,
        ownerRef = journey and journey.ownerRef or nil,
        mode = journey and journey.mode or nil,
        state = stateOf(group),
        previousState = stateOf(previous),
        reason = reason,
        group = Util.clone(group),
        previousGroup = Util.clone(previous),
    }
end

local function emit(eventType, operation, group, previous, reason)
    Events.emit(
        eventType,
        eventPayload(eventType, operation, group, previous, reason)
    )
end

local function requireRegistry(registry)
    if type(registry) ~= "table" then
        return nil, "survivor_world_registry_required"
    end
    if type(registry.GetGroup) ~= "function" then
        return nil, "survivor_world_registry_invalid"
    end
    return registry
end

-- Pure group operations. These do not persist anything and return a new
-- canonical group snapshot, matching SurvivorWorld traversal semantics.
local Group = Travel.Group or {}

function Group.Start(group, spec, now)
    local updated, reason = Traversal.Start(group, spec, now)
    if updated then
        emit(EventTypes.GROUP_STARTED, "start", updated, group)
    end
    return updated, reason
end

function Group.Advance(group, now)
    local previousState = stateOf(group)
    local updated, reason = Traversal.Advance(group, now)
    if not updated then return nil, reason end

    local nextState = stateOf(updated)
    if nextState ~= previousState then
        emit(
            nextState == "arrived"
                and EventTypes.GROUP_ARRIVED
                or EventTypes.GROUP_STATE_CHANGED,
            "advance",
            updated,
            group
        )
    end
    return updated
end

function Group.Rebase(group, origin, now)
    local updated, reason = Traversal.Rebase(group, origin, now)
    if updated then
        emit(EventTypes.GROUP_REBASED, "rebase", updated, group)
    end
    return updated, reason
end

function Group.Cancel(group, reason)
    local updated, failure = Traversal.Cancel(group, reason)
    if updated then
        emit(
            EventTypes.GROUP_CANCELLED,
            "cancel",
            updated,
            group,
            reason
        )
    end
    return updated, failure
end

function Group.ProjectPosition(group, now)
    return Traversal.ProjectGroupPosition(group, now)
end

function Group.ProjectMemberPosition(group, actorID, actorWorld, now)
    return Traversal.ProjectMemberPosition(
        group,
        actorID,
        actorWorld,
        now
    )
end

-- Journey primitives are exposed through the same Core seam so compatibility
-- bridges can normalize older records without importing implementation paths.
local Journey = Travel.GroupJourney or {}
Journey.New = GroupJourney.New
Journey.Normalize = GroupJourney.Normalize
Journey.Validate = GroupJourney.Validate
Journey.Advance = GroupJourney.Advance
Journey.ProjectPosition = GroupJourney.ProjectPosition
Journey.Rebase = GroupJourney.Rebase
Journey.MarkArrivalHandled = GroupJourney.MarkArrivalHandled
Journey.Cancel = GroupJourney.Cancel

-- Registry operations add persistence and lifecycle events around the
-- canonical SurvivorWorld registry. Providers never need to call the
-- registry's implementation methods directly.
local Registry = Travel.Registry or {}

function Registry.Start(registry, groupID, spec, now)
    local resolved, reason = requireRegistry(registry)
    if not resolved then return nil, reason end
    local previous = resolved:GetGroup(groupID)
    if not previous then return nil, "group_not_found" end
    local updated, failure = resolved:StartGroupJourney(groupID, spec, now)
    if updated then
        emit(EventTypes.GROUP_STARTED, "start", updated, previous)
    end
    return updated, failure
end

function Registry.Advance(registry, groupID, now)
    local resolved, reason = requireRegistry(registry)
    if not resolved then return nil, reason end
    local previous = resolved:GetGroup(groupID)
    if not previous then return nil, "group_not_found" end
    local previousState = stateOf(previous)
    local updated, failure = resolved:AdvanceGroupJourney(groupID, now)
    if not updated then return nil, failure end
    local nextState = stateOf(updated)
    if nextState ~= previousState then
        emit(
            nextState == "arrived"
                and EventTypes.GROUP_ARRIVED
                or EventTypes.GROUP_STATE_CHANGED,
            "advance",
            updated,
            previous
        )
    end
    return updated
end

function Registry.Rebase(registry, groupID, origin, now)
    local resolved, reason = requireRegistry(registry)
    if not resolved then return nil, reason end
    local previous = resolved:GetGroup(groupID)
    if not previous then return nil, "group_not_found" end
    local updated, failure = resolved:RebaseGroupJourney(
        groupID,
        origin,
        now
    )
    if updated then
        emit(EventTypes.GROUP_REBASED, "rebase", updated, previous)
    end
    return updated, failure
end

function Registry.Cancel(registry, groupID, reason)
    local resolved, failure = requireRegistry(registry)
    if not resolved then return nil, failure end
    local previous = resolved:GetGroup(groupID)
    if not previous then return nil, "group_not_found" end
    local updated
    updated, failure = resolved:CancelGroupJourney(groupID, reason)
    if updated then
        emit(
            EventTypes.GROUP_CANCELLED,
            "cancel",
            updated,
            previous,
            reason
        )
    end
    return updated, failure
end

function Registry.ProjectPosition(registry, groupID, now)
    local resolved, reason = requireRegistry(registry)
    if not resolved then return nil, reason end
    return resolved:ProjectGroupPosition(groupID, now)
end

function Registry.ProjectMemberPosition(
    registry,
    groupID,
    actorID,
    actorWorld,
    now
)
    local resolved, reason = requireRegistry(registry)
    if not resolved then return nil, reason end
    return resolved:ProjectGroupMemberPosition(
        groupID,
        actorID,
        actorWorld,
        now
    )
end

Travel.API_VERSION = 1
Travel.EventTypes = EventTypes
Travel.Group = Group
Travel.GroupJourney = Journey
Travel.Registry = Registry
Travel.Subscribe = Events.subscribe
Travel.Unsubscribe = Events.unsubscribe

Travel.Capabilities = {
    contractVersion = Travel.API_VERSION,
    representations = { abstract = true, physical = true },
    groupJourney = {
        commands = {
            "start",
            "advance",
            "rebase",
            "cancel",
        },
        queries = {
            "project",
            "project_member",
        },
        events = {
            EventTypes.GROUP_STARTED,
            EventTypes.GROUP_STATE_CHANGED,
            EventTypes.GROUP_ARRIVED,
            EventTypes.GROUP_REBASED,
            EventTypes.GROUP_CANCELLED,
        },
    },
}

function Travel.GetCapabilities()
    return Util.clone(Travel.Capabilities)
end

PsychopatzCore.Travel = Travel

return Travel
