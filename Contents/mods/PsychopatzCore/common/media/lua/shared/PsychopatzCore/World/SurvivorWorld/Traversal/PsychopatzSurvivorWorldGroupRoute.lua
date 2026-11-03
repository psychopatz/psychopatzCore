local Location = require "PsychopatzCore/Actors/PsychopatzActorLocation"
local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"

local Route = {}

Route.SCHEMA_VERSION = 1
Route.MAX_POINTS = Types.MAX_GROUP_ROUTE_POINTS

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

-- group route helpers
local function point(value, fallback)
    value = type(value) == "table" and value or {}
    fallback = type(fallback) == "table" and fallback or {}
    local normalized = Location.NormalizePoint({
        x = finite(value.x, fallback.x),
        y = finite(value.y, fallback.y),
        z = finite(value.z, fallback.z),
    })
    normalized.waitHours = math.max(
        0,
        finite(value.waitHours or value.waitWorldHours,
            fallback.waitHours)
    )
    if type(value.tag) == "string" and value.tag ~= "" then
        normalized.tag = string.sub(value.tag, 1, 64)
    end
    return normalized
end

local function samePoint(left, right)
    return math.abs(left.x - right.x) <= 0.001
        and math.abs(left.y - right.y) <= 0.001
        and math.abs(left.z - right.z) <= 0.001
end

local function distance(left, right)
    local dx = right.x - left.x
    local dy = right.y - left.y
    local dz = right.z - left.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Route.Normalize(raw, origin, destination)
    raw = type(raw) == "table" and raw or {}
    local sourcePoints = type(raw.points) == "table"
        and raw.points or raw
    local startPoint = point(origin)
    local endPoint = point(destination, startPoint)
    local points = { startPoint }

    for index = 1, math.min(#sourcePoints, Route.MAX_POINTS) do
        local candidate = point(sourcePoints[index], points[#points])
        if not samePoint(candidate, points[#points])
            and #points < Route.MAX_POINTS
        then
            points[#points + 1] = candidate
        elseif samePoint(candidate, points[#points])
            and candidate.waitHours > 0
        then
            points[#points].waitHours = math.max(
                points[#points].waitHours or 0,
                candidate.waitHours
            )
            points[#points].tag =
                candidate.tag or points[#points].tag
        end
    end

    if not samePoint(points[#points], endPoint) then
        if #points >= Route.MAX_POINTS then
            points[#points] = endPoint
        else
            points[#points + 1] = endPoint
        end
    end
    if #points < 2 then points[2] = endPoint end

    local totalDistance = 0
    local totalWaitHours = 0
    for index = 1, #points - 1 do
        totalDistance = totalDistance
            + distance(points[index], points[index + 1])
        totalWaitHours = totalWaitHours
            + math.max(
                0,
                tonumber(points[index + 1].waitHours) or 0
            )
    end

    return {
        schemaVersion = Route.SCHEMA_VERSION,
        points = points,
        totalDistance = totalDistance,
        totalWaitHours = totalWaitHours,
    }
end

function Route.Validate(route)
    if type(route) ~= "table"
        or tonumber(route.schemaVersion) ~= Route.SCHEMA_VERSION
        or type(route.points) ~= "table"
        or #route.points < 2
        or #route.points > Route.MAX_POINTS
        or tonumber(route.totalDistance) == nil
        or tonumber(route.totalWaitHours) == nil
    then
        return false, "group_route_invalid"
    end
    return true
end

local function segmentAtDistance(route, distanceTravelled)
    local clamped = math.max(
        0,
        math.min(
            tonumber(route.totalDistance) or 0,
            tonumber(distanceTravelled) or 0
        )
    )
    local traversed = 0
    for index = 1, #route.points - 1 do
        local left = route.points[index]
        local right = route.points[index + 1]
        local length = distance(left, right)
        if clamped <= traversed + length or index == #route.points - 1 then
            local within = clamped - traversed
            local progress = length <= 0 and 1
                or math.max(0, math.min(1, within / length))
            return index, progress, left, right
        end
        traversed = traversed + length
    end
    return #route.points - 1, 1,
        route.points[#route.points - 1],
        route.points[#route.points]
end

function Route.ProjectDistance(route, distanceTravelled)
    local valid, reason = Route.Validate(route)
    if not valid then return nil, reason end
    local index, progress, left, right =
        segmentAtDistance(route, distanceTravelled)
    return {
        x = left.x + (right.x - left.x) * progress,
        y = left.y + (right.y - left.y) * progress,
        z = left.z + (right.z - left.z) * progress,
        segmentIndex = index,
        segmentProgress = progress,
        distanceTravelled = math.max(
            0,
            math.min(
                route.totalDistance,
                tonumber(distanceTravelled) or 0
            )
        ),
    }
end

function Route.Segment(route, index)
    local valid, reason = Route.Validate(route)
    if not valid then return nil, reason end
    index = math.max(
        1,
        math.min(#route.points - 1,
            math.floor(tonumber(index) or 1))
    )
    local distanceStart = 0
    for cursor = 1, index - 1 do
        distanceStart = distanceStart
            + distance(route.points[cursor], route.points[cursor + 1])
    end
    local left = route.points[index]
    local right = route.points[index + 1]
    local length = distance(left, right)
    return {
        index = index,
        left = left,
        right = right,
        length = length,
        distanceStart = distanceStart,
        distanceEnd = distanceStart + length,
        waitHours = math.max(0, tonumber(right.waitHours) or 0),
    }
end

function Route.Remaining(route, distanceTravelled, origin)
    local projected, reason =
        Route.ProjectDistance(route, distanceTravelled)
    if not projected then return nil, reason end
    local points = { point(origin or projected) }
    for index = projected.segmentIndex + 1, #route.points do
        points[#points + 1] = point(route.points[index])
    end
    local destination = route.points[#route.points]
    return Route.Normalize(points, points[1], destination)
end

return Route
