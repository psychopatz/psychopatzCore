-- Dependency-safe point-to-point spatial relations.
--
-- Project Zomboid's world axes are used deliberately here: +X is east and
-- +Y is south.  This matches zombie.iso.IsoDirections (N = 0,-1,
-- E = 1,0, S = 0,1, W = -1,0).  Consumers must use these results rather than
-- repeating the axis convention in their own sign checks.

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Relation = Core.SpatialRelation or {}
Core.SpatialRelation = Relation

Relation.DEFAULT_SAME_AREA_THRESHOLD = 1.0
Relation.DEFAULT_MAX_DISTANCE_BANDS = 16

Relation.Directions = Relation.Directions or {
    "SAME_AREA",
    "NORTH",
    "NORTHEAST",
    "EAST",
    "SOUTHEAST",
    "SOUTH",
    "SOUTHWEST",
    "WEST",
    "NORTHWEST",
}

Relation.Opposites = Relation.Opposites or {
    NORTH = "SOUTH",
    NORTHEAST = "SOUTHWEST",
    EAST = "WEST",
    SOUTHEAST = "NORTHWEST",
    SOUTH = "NORTH",
    SOUTHWEST = "NORTHEAST",
    WEST = "EAST",
    NORTHWEST = "SOUTHEAST",
    SAME_AREA = "SAME_AREA",
}

Relation.DirectionLabelKeys = Relation.DirectionLabelKeys or {
    SAME_AREA = "UI_PsychopatzCore_Spatial_Direction_SameArea",
    NORTH = "UI_PsychopatzCore_Spatial_Direction_North",
    NORTHEAST = "UI_PsychopatzCore_Spatial_Direction_Northeast",
    EAST = "UI_PsychopatzCore_Spatial_Direction_East",
    SOUTHEAST = "UI_PsychopatzCore_Spatial_Direction_Southeast",
    SOUTH = "UI_PsychopatzCore_Spatial_Direction_South",
    SOUTHWEST = "UI_PsychopatzCore_Spatial_Direction_Southwest",
    WEST = "UI_PsychopatzCore_Spatial_Direction_West",
    NORTHWEST = "UI_PsychopatzCore_Spatial_Direction_Northwest",
}

Relation.ClockLabelKeys = Relation.ClockLabelKeys or {
    CLOCK_01 = "UI_PsychopatzCore_Spatial_Clock_01",
    CLOCK_02 = "UI_PsychopatzCore_Spatial_Clock_02",
    CLOCK_03 = "UI_PsychopatzCore_Spatial_Clock_03",
    CLOCK_04 = "UI_PsychopatzCore_Spatial_Clock_04",
    CLOCK_05 = "UI_PsychopatzCore_Spatial_Clock_05",
    CLOCK_06 = "UI_PsychopatzCore_Spatial_Clock_06",
    CLOCK_07 = "UI_PsychopatzCore_Spatial_Clock_07",
    CLOCK_08 = "UI_PsychopatzCore_Spatial_Clock_08",
    CLOCK_09 = "UI_PsychopatzCore_Spatial_Clock_09",
    CLOCK_10 = "UI_PsychopatzCore_Spatial_Clock_10",
    CLOCK_11 = "UI_PsychopatzCore_Spatial_Clock_11",
    CLOCK_12 = "UI_PsychopatzCore_Spatial_Clock_12",
}

Relation.ClockFallbackLabels = Relation.ClockFallbackLabels or {
    CLOCK_01 = "1 o'clock",
    CLOCK_02 = "2 o'clock",
    CLOCK_03 = "3 o'clock",
    CLOCK_04 = "4 o'clock",
    CLOCK_05 = "5 o'clock",
    CLOCK_06 = "6 o'clock",
    CLOCK_07 = "7 o'clock",
    CLOCK_08 = "8 o'clock",
    CLOCK_09 = "9 o'clock",
    CLOCK_10 = "10 o'clock",
    CLOCK_11 = "11 o'clock",
    CLOCK_12 = "12 o'clock",
}

Relation.RelativeSectorLabelKeys = Relation.RelativeSectorLabelKeys or {
    AHEAD = "UI_PsychopatzCore_Spatial_Relative_Ahead",
    FRONT_RIGHT = "UI_PsychopatzCore_Spatial_Relative_FrontRight",
    RIGHT = "UI_PsychopatzCore_Spatial_Relative_Right",
    REAR_RIGHT = "UI_PsychopatzCore_Spatial_Relative_RearRight",
    BEHIND = "UI_PsychopatzCore_Spatial_Relative_Behind",
    REAR_LEFT = "UI_PsychopatzCore_Spatial_Relative_RearLeft",
    LEFT = "UI_PsychopatzCore_Spatial_Relative_Left",
    FRONT_LEFT = "UI_PsychopatzCore_Spatial_Relative_FrontLeft",
}

Relation.RelativeSectorFallbackLabels = Relation.RelativeSectorFallbackLabels or {
    AHEAD = "ahead",
    FRONT_RIGHT = "ahead, right side",
    RIGHT = "to the right",
    REAR_RIGHT = "behind us, right side",
    BEHIND = "behind us",
    REAR_LEFT = "behind us, left side",
    LEFT = "to the left",
    FRONT_LEFT = "ahead, left side",
}

local function finiteNumber(value)
    local number = tonumber(value)
    if not number or number ~= number
        or number == math.huge or number == -math.huge
    then
        return nil
    end
    return number
end

local function normalizePoint(point)
    if type(point) ~= "table" then return nil, "POINT_REQUIRED" end
    local x = finiteNumber(point.x)
    local y = finiteNumber(point.y)
    if x == nil or y == nil then return nil, "XY_REQUIRED" end

    local z = point.z
    if z == nil then
        z = 0
    else
        z = finiteNumber(z)
        if z == nil then return nil, "Z_INVALID" end
    end
    return { x = x, y = y, z = z }
end

local function normalizeHeading(heading)
    if type(heading) ~= "table" then
        return nil, "HEADING_REQUIRED"
    end

    local x = finiteNumber(heading.x)
    local y = finiteNumber(heading.y)
    if x == nil or y == nil then
        return nil, "HEADING_XY_REQUIRED"
    end

    local length = math.sqrt(x * x + y * y)
    if length <= 0.000001 then
        return nil, "HEADING_ZERO"
    end

    return {
        x = x / length,
        y = y / length,
        sourceLength = length,
    }
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    return math.atan(y, x)
end

local function normalizedDegrees(value)
    local degrees = math.deg(value)
    while degrees < 0 do degrees = degrees + 360 end
    while degrees >= 360 do degrees = degrees - 360 end
    return degrees
end

local function directionForAngle(angleRadians)
    -- The compass bearing is clockwise from north.  In PZ coordinates that
    -- means north is -Y, east is +X, south is +Y, and west is -X.
    local bearing = normalizedDegrees(atan2(math.cos(angleRadians),
        -math.sin(angleRadians)))
    local index = math.floor((bearing + 22.5) / 45) % 8
    local directions = {
        "NORTH", "NORTHEAST", "EAST", "SOUTHEAST",
        "SOUTH", "SOUTHWEST", "WEST", "NORTHWEST",
    }
    return directions[index + 1]
end

local function clockForRelativeDegrees(relativeDegrees)
    local sector = math.floor((relativeDegrees + 15) / 30) % 12
    local hour = sector == 0 and 12 or sector
    return hour, string.format("CLOCK_%02d", hour)
end

local function relativeSectorForDegrees(relativeDegrees)
    local index = math.floor((relativeDegrees + 22.5) / 45) % 8
    local sectors = {
        "AHEAD",
        "FRONT_RIGHT",
        "RIGHT",
        "REAR_RIGHT",
        "BEHIND",
        "REAR_LEFT",
        "LEFT",
        "FRONT_LEFT",
    }
    return sectors[index + 1]
end

local function normalizeThreshold(value)
    value = finiteNumber(value)
    if value == nil or value < 0 then
        return Relation.DEFAULT_SAME_AREA_THRESHOLD
    end
    return value
end

local function distanceBand(distance, bands)
    if type(bands) ~= "table" then return nil end
    local bestToken
    local bestMaximum
    local limit = math.min(#bands, Relation.DEFAULT_MAX_DISTANCE_BANDS)
    local index
    for index = 1, limit do
        local band = bands[index]
        local maximum = type(band) == "table" and finiteNumber(band.max)
        local token = type(band) == "table" and band.token or nil
        if maximum ~= nil and maximum >= 0 and type(token) == "string"
            and token ~= ""
            and maximum >= distance
            and (bestMaximum == nil or maximum < bestMaximum)
        then
            bestMaximum = maximum
            bestToken = token
        end
    end
    return bestToken
end

function Relation.GetDirectionLabelKey(direction)
    return Relation.DirectionLabelKeys[tostring(direction or "")]
end

function Relation.GetDirectionLabel(direction, fallback)
    direction = tostring(direction or "")
    local key = Relation.GetDirectionLabelKey(direction)
    if not key then return fallback or direction end

    local translation = Core.Translation
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, fallback or string.lower(direction))
    end
    return fallback or string.lower(direction)
end

function Relation.GetClockLabelKey(clockToken)
    return Relation.ClockLabelKeys[tostring(clockToken or "")]
end

function Relation.GetClockLabel(clockToken, fallback)
    clockToken = tostring(clockToken or "")
    local key = Relation.GetClockLabelKey(clockToken)
    local default = fallback or Relation.ClockFallbackLabels[clockToken]
        or string.lower(clockToken)
    if not key then return default end

    local translation = Core.Translation
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, default)
    end
    return default
end

function Relation.GetRelativeSectorLabelKey(sector)
    return Relation.RelativeSectorLabelKeys[tostring(sector or "")]
end

function Relation.GetRelativeSectorLabel(sector, fallback)
    sector = tostring(sector or "")
    local key = Relation.GetRelativeSectorLabelKey(sector)
    local default = fallback or Relation.RelativeSectorFallbackLabels[sector]
        or string.lower(sector)
    if not key then return default end

    local translation = Core.Translation
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, default)
    end
    return default
end

function Relation.Opposite(direction)
    return Relation.Opposites[tostring(direction or "")]
end

function Relation.Between(fromPoint, toPoint, options)
    local from, fromError = normalizePoint(fromPoint)
    if not from then return nil, fromError end
    local to, toError = normalizePoint(toPoint)
    if not to then return nil, toError end

    options = type(options) == "table" and options or {}
    local dx = to.x - from.x
    local dy = to.y - from.y
    local dz = to.z - from.z
    local horizontalDistance = math.sqrt(dx * dx + dy * dy)
    local distance = math.sqrt(horizontalDistance * horizontalDistance
        + dz * dz)
    local angleRadians = horizontalDistance == 0 and 0 or atan2(dy, dx)
    local bearingDegrees = horizontalDistance == 0 and 0
        or normalizedDegrees(atan2(dx, -dy))
    local threshold = normalizeThreshold(options.sameAreaThreshold)
    local sameArea = horizontalDistance <= threshold
    local direction = sameArea and "SAME_AREA"
        or directionForAngle(angleRadians)

    return {
        dx = dx,
        dy = dy,
        dz = dz,
        distance = distance,
        horizontalDistance = horizontalDistance,
        angleRadians = angleRadians,
        bearingDegrees = bearingDegrees,
        direction8 = direction,
        sameArea = sameArea,
        sameAreaThreshold = threshold,
        distanceBand = distanceBand(distance, options.distanceBands),
    }
end

function Relation.RelativeToHeading(fromPoint, toPoint, heading, options)
    local relation, relationError = Relation.Between(fromPoint, toPoint, options)
    if not relation then return nil, relationError end

    local normalizedHeading, headingError = normalizeHeading(heading)
    if not normalizedHeading then return nil, headingError end

    relation.headingX = normalizedHeading.x
    relation.headingY = normalizedHeading.y
    relation.headingSourceLength = normalizedHeading.sourceLength

    if relation.sameArea then
        return relation
    end

    -- PZ uses +Y south.  This determinant is positive when the target is
    -- clockwise/right of the observer's heading in that coordinate system.
    local cross = normalizedHeading.x * relation.dy
        - normalizedHeading.y * relation.dx
    local dot = normalizedHeading.x * relation.dx
        + normalizedHeading.y * relation.dy
    local signedRelativeRadians = atan2(cross, dot)
    local relativeDegrees = normalizedDegrees(signedRelativeRadians)
    local hour, clockToken = clockForRelativeDegrees(relativeDegrees)

    relation.relativeAngleRadians = math.rad(relativeDegrees)
    relation.relativeAngleDegrees = relativeDegrees
    relation.clockHour = hour
    relation.clockToken = clockToken
    relation.relativeSector8 = relativeSectorForDegrees(relativeDegrees)

    return relation
end

return Relation
