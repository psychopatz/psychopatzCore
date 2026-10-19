local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Location = require "PsychopatzCore/Actors/PsychopatzActorLocation"

local Journey = {}

Journey.SCHEMA_VERSION = 1
Journey.MAX_METADATA_DEPTH = 6
Journey.ACTIVE_STATES = {
    planned = true,
    en_route = true,
    paused = true,
}

local function number(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then return fallback end
    return value
end

local function distance(left, right)
    local dx = left.x - right.x
    local dy = left.y - right.y
    local dz = left.z - right.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function metadata(value, depth)
    if value == nil or type(value) == "boolean"
        or type(value) == "string" or type(value) == "number"
    then return value end
    if type(value) ~= "table" or depth > Journey.MAX_METADATA_DEPTH then
        return nil
    end
    local output = {}
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            return nil
        end
        local copied = metadata(child, depth + 1)
        if copied == nil and child ~= nil then return nil end
        output[key] = copied
    end
    return output
end

function Journey.New(actorID, spec, now)
    spec = type(spec) == "table" and spec or {}
    actorID = Util.text(actorID, nil)
    if not actorID then return nil, "actor_id_required" end
    local origin = Location.NormalizePoint(spec.origin or spec.from)
    local destination = Location.NormalizePoint(
        spec.destination or spec.to, origin)
    local journeyID = Util.text(spec.journeyID or spec.journeyId, nil)
        or "journey:" .. tostring(Util.hash(actorID .. ":"
            .. tostring(spec.startAt or now or 0) .. ":"
            .. tostring(destination.x) .. ":" .. tostring(destination.y)))
    local speed = math.max(0.001, number(spec.speed, 10))
    local startAt = number(spec.startAt, number(now, 0))
    local total = distance(origin, destination)
    local arrivalRadius = math.max(0.01, number(spec.arrivalRadius, 0.5))
    local eta = startAt + (total / speed)
    local state = startAt > number(now, startAt) and "planned" or "en_route"
    if total <= arrivalRadius then state = "arrived" end
    return {
        schemaVersion = Journey.SCHEMA_VERSION,
        journeyID = journeyID,
        actorID = actorID,
        ownerMod = Util.text(spec.ownerMod, nil),
        ownerRef = Util.text(spec.ownerRef, nil),
        state = state,
        mode = Util.text(spec.mode, "abstract"),
        origin = origin,
        destination = destination,
        originAnchorID = Util.text(spec.originAnchorID, nil),
        destinationAnchorID = Util.text(spec.destinationAnchorID, nil),
        speed = speed,
        distanceTotal = total,
        distanceTravelled = state == "arrived" and total or 0,
        progress = state == "arrived" and 1 or 0,
        startAt = startAt,
        eta = eta,
        lastAdvancedAt = number(now, startAt),
        arrivalRadius = arrivalRadius,
        arrivalAction = Util.clone(spec.arrivalAction or { type = "none" }),
        metadata = metadata(spec.metadata or {}, 0) or {},
        arrivedAt = nil,
        arrivalHandled = false,
        arrivalHandledBy = nil,
        failureReason = nil,
        revision = 1,
    }
end

function Journey.Normalize(raw, actorID, now)
    if type(raw) ~= "table" then return nil, "journey_required" end
    local journey, reason = Journey.New(actorID or raw.actorID, raw, now)
    if not journey then return nil, reason end
    for key, value in pairs(raw) do
        if key ~= "schemaVersion" and journey[key] ~= nil then
            journey[key] = Util.clone(value)
        end
    end
    journey.schemaVersion = Journey.SCHEMA_VERSION
    journey.actorID = Util.text(raw.actorID or actorID, journey.actorID)
    journey.journeyID = Util.text(raw.journeyID or raw.journeyId,
        journey.journeyID)
    journey.state = tostring(raw.state or journey.state)
    if not Journey.ACTIVE_STATES[journey.state]
        and journey.state ~= "arrived"
        and journey.state ~= "cancelled"
        and journey.state ~= "blocked"
    then return nil, "journey_state_invalid" end
    journey.distanceTotal = math.max(0, number(raw.distanceTotal,
        journey.distanceTotal))
    journey.distanceTravelled = math.max(0, math.min(
        journey.distanceTotal, number(raw.distanceTravelled, 0)))
    journey.progress = journey.distanceTotal <= 0 and 1 or math.max(0,
        math.min(1, number(raw.progress,
            journey.distanceTravelled / journey.distanceTotal)))
    journey.revision = math.max(1, Util.integer(raw.revision, 1))
    journey.arrivalHandled = raw.arrivalHandled == true
    journey.arrivedAt = number(raw.arrivedAt, nil)
    journey.arrivalHandledBy = Util.text(raw.arrivalHandledBy, nil)
    journey.failureReason = Util.text(raw.failureReason, nil)
    journey.lastAdvancedAt = number(raw.lastAdvancedAt, journey.lastAdvancedAt)
    return journey
end

function Journey.Validate(journey)
    if type(journey) ~= "table"
        or Util.integer(journey.schemaVersion, 0) ~= Journey.SCHEMA_VERSION
        or not Util.text(journey.journeyID, nil)
        or not Util.text(journey.actorID, nil)
        or type(journey.origin) ~= "table"
        or type(journey.destination) ~= "table"
        or not Journey.ACTIVE_STATES[journey.state]
            and journey.state ~= "arrived"
            and journey.state ~= "cancelled"
            and journey.state ~= "blocked"
        or tonumber(journey.distanceTotal) == nil
        or tonumber(journey.distanceTravelled) == nil
        or tonumber(journey.progress) == nil
        or journey.progress < 0 or journey.progress > 1
        or type(journey.metadata) ~= "table"
        or not Util.isSerializable(journey)
    then return false, "journey_invalid" end
    if journey.arrivalHandled and journey.state ~= "arrived" then
        return false, "arrival_state_invalid"
    end
    return true
end

function Journey.Advance(journey, now)
    local nextJourney = Util.clone(journey)
    now = number(now, nextJourney.lastAdvancedAt)
    if not Journey.ACTIVE_STATES[nextJourney.state] then
        return nextJourney
    end
    if nextJourney.state == "planned" and now < nextJourney.startAt then
        nextJourney.lastAdvancedAt = now
        return nextJourney
    end
    local elapsed = math.max(0, now - nextJourney.startAt)
    local travelled = math.min(nextJourney.distanceTotal,
        elapsed * nextJourney.speed)
    nextJourney.distanceTravelled = travelled
    nextJourney.progress = nextJourney.distanceTotal <= 0 and 1
        or travelled / nextJourney.distanceTotal
    nextJourney.lastAdvancedAt = now
    if travelled + nextJourney.arrivalRadius >= nextJourney.distanceTotal then
        nextJourney.distanceTravelled = nextJourney.distanceTotal
        nextJourney.progress = 1
        nextJourney.state = "arrived"
        nextJourney.arrivedAt = now
    else
        nextJourney.state = "en_route"
    end
    nextJourney.revision = (tonumber(journey.revision) or 1) + 1
    return nextJourney
end

function Journey.MarkArrivalHandled(journey, handlerID)
    if type(journey) ~= "table" or journey.state ~= "arrived" then
        return nil, "journey_not_arrived"
    end
    if journey.arrivalHandled then return nil, "arrival_already_handled" end
    local nextJourney = Util.clone(journey)
    nextJourney.arrivalHandled = true
    nextJourney.arrivalHandledBy = Util.text(handlerID, "core")
    nextJourney.revision = (tonumber(journey.revision) or 1) + 1
    return nextJourney
end

function Journey.Cancel(journey, reason)
    if type(journey) ~= "table" then return nil, "journey_required" end
    if journey.state == "arrived" then return nil, "journey_already_arrived" end
    local nextJourney = Util.clone(journey)
    nextJourney.state = "cancelled"
    nextJourney.failureReason = Util.text(reason, "cancelled")
    nextJourney.revision = (tonumber(journey.revision) or 1) + 1
    return nextJourney
end

return Journey
