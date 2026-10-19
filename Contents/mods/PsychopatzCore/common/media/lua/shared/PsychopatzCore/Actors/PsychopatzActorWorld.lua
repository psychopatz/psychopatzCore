local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Location = require "PsychopatzCore/Actors/PsychopatzActorLocation"
local Journey = require "PsychopatzCore/Actors/PsychopatzActorJourney"
local Task = require "PsychopatzCore/Actors/PsychopatzActorTask"
local Scheduler = require "PsychopatzCore/Actors/PsychopatzActorScheduler"

local World = {}
World.SCHEMA_VERSION = 1

function World.NewState(source, actorID, now)
    source = type(source) == "table" and source or {}
    local location, reason = Location.NewState(source.location or source)
    if not location then return nil, reason end
    local tasks
    tasks, reason = Task.NewQueue(source.tasks)
    if not tasks then return nil, reason end
    local scheduler
    scheduler, reason = Scheduler.NewState(source.scheduler)
    if not scheduler then return nil, reason end
    local journey
    local rawJourney = source.journey or source.travel
    if type(rawJourney) == "table" then
        journey, reason = Journey.Normalize(rawJourney, actorID, now)
        if not journey then return nil, reason end
    end
    local state = {
        schemaVersion = World.SCHEMA_VERSION,
        location = location,
        journey = journey,
        tasks = tasks,
        scheduler = scheduler,
        revision = math.max(0, math.floor(tonumber(source.revision) or 0)),
    }
    local valid
    valid, reason = World.Validate(state)
    if not valid then return nil, reason end
    return state
end

function World.Validate(state)
    if type(state) ~= "table"
        or Util.integer(state.schemaVersion, 0) ~= World.SCHEMA_VERSION
    then return false, "world_schema_mismatch" end
    local valid, reason = Location.Validate(state.location)
    if not valid then return false, reason end
    valid, reason = Task.ValidateQueue(state.tasks)
    if not valid then return false, reason end
    valid, reason = Scheduler.Validate(state.scheduler)
    if not valid then return false, reason end
    if state.journey then
        valid, reason = Journey.Validate(state.journey)
        if not valid then return false, reason end
    end
    return true
end

function World.StartJourney(state, actorID, spec, now)
    if type(state) ~= "table" then return nil, "world_required" end
    local journey, reason = Journey.New(actorID, spec, now)
    if not journey then return nil, reason end
    local nextState = Util.clone(state)
    nextState.journey = journey
    nextState.revision = (tonumber(state.revision) or 0) + 1
    return nextState
end

function World.AdvanceJourney(state, now)
    if type(state) ~= "table" then return nil, "world_required" end
    if not state.journey then return Util.clone(state) end
    local nextState = Util.clone(state)
    nextState.journey = Journey.Advance(state.journey, now)
    if nextState.journey.state == "arrived" then
        nextState.location.position = Location.NormalizePoint(
            nextState.journey.destination)
        nextState.location.activeAnchorID =
            nextState.journey.destinationAnchorID
    end
    nextState.revision = (tonumber(state.revision) or 0) + 1
    return nextState
end

function World.MarkArrivalHandled(state, handlerID)
    if type(state) ~= "table" or not state.journey then
        return nil, "journey_not_found"
    end
    local journey, reason = Journey.MarkArrivalHandled(state.journey, handlerID)
    if not journey then return nil, reason end
    local nextState = Util.clone(state)
    nextState.journey = journey
    nextState.revision = (tonumber(state.revision) or 0) + 1
    return nextState
end

return World
