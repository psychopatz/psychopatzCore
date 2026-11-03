local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Location = require "PsychopatzCore/Actors/PsychopatzActorLocation"
local Route = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupRoute"

local Journey = {}

Journey.SCHEMA_VERSION = 1
Journey.ACTIVE_STATES = {
    planned = true,
    en_route = true,
    waiting = true,
    paused = true,
}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function point(value, fallback)
    return Location.NormalizePoint(
        type(value) == "table" and value or fallback
    )
end

local function projectedFields(journey)
    local projected = Route.ProjectDistance(
        journey.route,
        journey.distanceTravelled
    )
    journey.segmentIndex = projected.segmentIndex
    journey.segmentProgress = projected.segmentProgress
    journey.progress = journey.distanceTotal <= 0 and 1
        or math.max(
            0,
            math.min(
                1,
                journey.distanceTravelled / journey.distanceTotal
            )
        )
    journey.x = projected.x
    journey.y = projected.y
    journey.z = projected.z
end

local function remainingWait(journey)
    local total = math.max(
        0,
        tonumber(journey.waitRemainingHours) or 0
    )
    for index = math.max(
        1,
        math.floor(tonumber(journey.segmentIndex) or 1)
    ), #journey.route.points - 1 do
        if index ~= journey.segmentIndex
            or journey.state ~= "waiting"
        then
            total = total + math.max(
                0,
                tonumber(journey.route.points[index + 1].waitHours)
                    or 0
            )
        end
    end
    return total
end

local function updateETA(journey, now)
    now = finite(now, journey.lastAdvancedAt)
    if journey.state == "arrived" then
        journey.eta = finite(journey.arrivedAt, now)
        return
    end
    if journey.state == "cancelled"
        or journey.state == "blocked"
    then
        journey.eta = nil
        return
    end
    local remainingDistance = math.max(
        0,
        journey.distanceTotal - journey.distanceTravelled
    )
    journey.eta = now
        + remainingDistance / math.max(0.001, journey.speed)
        + remainingWait(journey)
end

function Journey.New(groupID, spec, now)
    spec = type(spec) == "table" and spec or {}
    groupID = Util.text(groupID, nil)
    if not groupID then return nil, "group_id_required" end
    now = finite(now, spec.startAt or spec.departedWorldHour)
    local origin = point(spec.origin or spec.from or spec.location)
    local destination = point(
        spec.destination or spec.to or spec.targetLocation,
        origin
    )
    local route = Route.Normalize(
        spec.route,
        origin,
        destination
    )
    local speed = math.max(
        0.001,
        finite(spec.speed or spec.speedTilesPerWorldHour, 10)
    )
    local startAt = finite(
        spec.startAt or spec.departedWorldHour,
        now
    )
    local arrivalRadius = math.max(
        0.01,
        finite(spec.arrivalRadius, 0.5)
    )
    local state = startAt > now and "planned" or "en_route"
    if route.totalDistance <= arrivalRadius then
        state = "arrived"
    end
    local journeyID = Util.text(
        spec.journeyID or spec.journeyId,
        nil
    ) or "group_journey:" .. tostring(Util.hash(
        groupID .. ":" .. tostring(startAt)
            .. ":" .. tostring(destination.x)
            .. ":" .. tostring(destination.y)
    ))
    local journey = {
        schemaVersion = Journey.SCHEMA_VERSION,
        journeyID = journeyID,
        groupID = groupID,
        ownerMod = Util.text(spec.ownerMod, nil),
        ownerRef = Util.text(spec.ownerRef, nil),
        state = state,
        mode = Util.text(spec.mode, "abstract"),
        origin = origin,
        destination = destination,
        originAnchorID = Util.text(
            spec.originAnchorID or spec.originLocationID,
            nil
        ),
        destinationAnchorID = Util.text(
            spec.destinationAnchorID or spec.destinationLocationID,
            nil
        ),
        route = route,
        speed = speed,
        distanceTotal = route.totalDistance,
        distanceTravelled =
            state == "arrived" and route.totalDistance or 0,
        segmentIndex = 1,
        segmentProgress = 0,
        waitRemainingHours = 0,
        progress = state == "arrived" and 1 or 0,
        startAt = startAt,
        lastAdvancedAt = now,
        eta = startAt + route.totalDistance / speed
            + route.totalWaitHours,
        arrivalRadius = arrivalRadius,
        arrivedAt = state == "arrived" and now or nil,
        arrivalHandled = false,
        arrivalHandledBy = nil,
        failureReason = nil,
        revision = 1,
    }
    projectedFields(journey)
    updateETA(journey, now)
    return journey
end

function Journey.Normalize(raw, groupID, now)
    if type(raw) ~= "table" then
        return nil, "group_journey_required"
    end
    local journey, reason = Journey.New(
        groupID or raw.groupID,
        raw,
        finite(
            raw.startAt or raw.departedWorldHour,
            now
        )
    )
    if not journey then return nil, reason end
    journey.journeyID = Util.text(
        raw.journeyID or raw.journeyId,
        journey.journeyID
    )
    journey.state = tostring(raw.state or journey.state)
    if not Journey.ACTIVE_STATES[journey.state]
        and journey.state ~= "arrived"
        and journey.state ~= "cancelled"
        and journey.state ~= "blocked"
    then
        return nil, "group_journey_state_invalid"
    end
    journey.distanceTravelled = math.max(
        0,
        math.min(
            journey.distanceTotal,
            finite(raw.distanceTravelled, 0)
        )
    )
    journey.waitRemainingHours = math.max(
        0,
        finite(
            raw.waitRemainingHours or raw.waitRemainingWorldHours,
            0
        )
    )
    journey.lastAdvancedAt = finite(
        raw.lastAdvancedAt or raw.lastAdvancedWorldHour,
        journey.startAt
    )
    journey.arrivedAt = tonumber(
        raw.arrivedAt or raw.arrivedWorldHour
    )
    journey.arrivalHandled = raw.arrivalHandled == true
    journey.arrivalHandledBy = Util.text(
        raw.arrivalHandledBy,
        nil
    )
    journey.failureReason = Util.text(raw.failureReason, nil)
    journey.revision = math.max(
        1,
        math.floor(finite(raw.revision, 1))
    )
    projectedFields(journey)
    updateETA(journey, journey.lastAdvancedAt)
    return journey
end

function Journey.Validate(journey)
    if type(journey) ~= "table"
        or tonumber(journey.schemaVersion) ~= Journey.SCHEMA_VERSION
        or not Util.text(journey.journeyID, nil)
        or not Util.text(journey.groupID, nil)
        or type(journey.origin) ~= "table"
        or type(journey.destination) ~= "table"
        or tonumber(journey.speed) == nil
        or tonumber(journey.distanceTotal) == nil
        or tonumber(journey.distanceTravelled) == nil
        or tonumber(journey.progress) == nil
        or journey.progress < 0
        or journey.progress > 1
        or not Journey.ACTIVE_STATES[journey.state]
            and journey.state ~= "arrived"
            and journey.state ~= "cancelled"
            and journey.state ~= "blocked"
        or not Util.isSerializable(journey)
    then
        return false, "group_journey_invalid"
    end
    local valid, reason = Route.Validate(journey.route)
    if not valid then return false, reason end
    if journey.arrivalHandled and journey.state ~= "arrived" then
        return false, "group_journey_arrival_state_invalid"
    end
    return true
end

function Journey.Advance(journey, now)
    local valid, reason = Journey.Validate(journey)
    if not valid then return nil, reason end

    local nextJourney = Util.clone(journey)
    now = finite(now, nextJourney.lastAdvancedAt)
    local previousAdvancedAt = finite(
        nextJourney.lastAdvancedAt,
        nextJourney.startAt
    )
    if nextJourney.state == "planned"
        and now < nextJourney.startAt
    then
        nextJourney.lastAdvancedAt = now
        updateETA(nextJourney, now)
        return nextJourney
    elseif nextJourney.state == "planned" then
        nextJourney.state = "en_route"
        previousAdvancedAt = math.max(
            previousAdvancedAt,
            nextJourney.startAt
        )
    end

    if nextJourney.state == "paused"
        or nextJourney.state == "cancelled"
        or nextJourney.state == "blocked"
        or nextJourney.state == "arrived"
    then
        nextJourney.lastAdvancedAt = now
        projectedFields(nextJourney)
        updateETA(nextJourney, now)
        return nextJourney
    end

    local elapsed = math.max(
        0,
        now - previousAdvancedAt
    )
    nextJourney.lastAdvancedAt = now

    while elapsed > 0
        and nextJourney.state ~= "arrived"
        and nextJourney.state ~= "paused"
    do
        if nextJourney.state == "waiting" then
            local wait = math.max(
                0,
                tonumber(nextJourney.waitRemainingHours) or 0
            )
            if elapsed < wait then
                nextJourney.waitRemainingHours = wait - elapsed
                elapsed = 0
            else
                elapsed = elapsed - wait
                nextJourney.waitRemainingHours = 0
                nextJourney.state = "en_route"
            end
        else
            local segment = Route.Segment(
                nextJourney.route,
                nextJourney.segmentIndex
            )
            local remaining = math.max(
                0,
                segment.distanceEnd
                    - nextJourney.distanceTravelled
            )
            local travelHours =
                remaining / math.max(0.001, nextJourney.speed)
            if elapsed + 0.0000001 < travelHours then
                nextJourney.distanceTravelled =
                    nextJourney.distanceTravelled
                        + nextJourney.speed * elapsed
                elapsed = 0
            else
                nextJourney.distanceTravelled =
                    segment.distanceEnd
                elapsed = math.max(0, elapsed - travelHours)
                if nextJourney.distanceTravelled
                    + nextJourney.arrivalRadius
                    >= nextJourney.distanceTotal
                then
                    nextJourney.distanceTravelled =
                        nextJourney.distanceTotal
                    nextJourney.state = "arrived"
                    nextJourney.arrivedAt = now - elapsed
                else
                    nextJourney.segmentIndex = math.min(
                        #nextJourney.route.points - 1,
                        nextJourney.segmentIndex + 1
                    )
                    if segment.waitHours > 0 then
                        nextJourney.state = "waiting"
                        nextJourney.waitRemainingHours =
                            segment.waitHours
                    end
                end
            end
        end
    end

    projectedFields(nextJourney)
    updateETA(nextJourney, now)
    nextJourney.revision =
        (tonumber(journey.revision) or 1) + 1
    return nextJourney
end

function Journey.ProjectPosition(journey, now)
    local projected, reason = Journey.Advance(journey, now)
    if not projected then return nil, reason end
    return {
        x = projected.x,
        y = projected.y,
        z = projected.z,
    }, projected
end

function Journey.Rebase(journey, origin, now)
    local current, reason = Journey.Advance(journey, now)
    if not current then return nil, reason end
    if current.state == "arrived" then
        return Util.clone(current)
    end

    local projected = Route.ProjectDistance(
        current.route,
        current.distanceTravelled
    )
    local nextOrigin = point(origin, projected)
    local remainingRoute
    remainingRoute, reason = Route.Remaining(
        current.route,
        current.distanceTravelled,
        nextOrigin
    )
    if not remainingRoute then return nil, reason end

    local rebased
    rebased, reason = Journey.New(
        current.groupID,
        {
            journeyID = current.journeyID,
            ownerMod = current.ownerMod,
            ownerRef = current.ownerRef,
            mode = current.mode,
            origin = nextOrigin,
            destination = current.destination,
            originAnchorID = current.originAnchorID,
            destinationAnchorID = current.destinationAnchorID,
            route = remainingRoute.points,
            speed = current.speed,
            arrivalRadius = current.arrivalRadius,
            startAt = finite(now, current.lastAdvancedAt),
        },
        finite(now, current.lastAdvancedAt)
    )
    if not rebased then return nil, reason end
    if current.state == "paused" then
        rebased.state = "paused"
    end
    rebased.revision = (tonumber(current.revision) or 1) + 1
    updateETA(rebased, rebased.lastAdvancedAt)
    return rebased
end

function Journey.MarkArrivalHandled(journey, handlerID)
    if type(journey) ~= "table"
        or journey.state ~= "arrived"
    then
        return nil, "group_journey_not_arrived"
    end
    if journey.arrivalHandled then
        return nil, "group_journey_arrival_already_handled"
    end
    local copy = Util.clone(journey)
    copy.arrivalHandled = true
    copy.arrivalHandledBy = Util.text(handlerID, "core")
    copy.revision = (tonumber(journey.revision) or 1) + 1
    return copy
end

function Journey.Cancel(journey, reason)
    if type(journey) ~= "table" then
        return nil, "group_journey_required"
    end
    if journey.state == "arrived" then
        return nil, "group_journey_already_arrived"
    end
    local copy = Util.clone(journey)
    copy.state = "cancelled"
    copy.failureReason = Util.text(reason, "cancelled")
    copy.eta = nil
    copy.revision = (tonumber(journey.revision) or 1) + 1
    return copy
end

return Journey
