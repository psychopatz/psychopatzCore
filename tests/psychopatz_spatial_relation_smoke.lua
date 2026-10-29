local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local Relation = require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function assertNear(actual, expected, label)
    if math.abs(actual - expected) > 0.000001 then
        error((label or "assertNear") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local origin = { x = 100, y = 100, z = 0 }
local cases = {
    { name = "NORTH", point = { x = 100, y = 90, z = 0 } },
    { name = "NORTHEAST", point = { x = 110, y = 90, z = 0 } },
    { name = "EAST", point = { x = 110, y = 100, z = 0 } },
    { name = "SOUTHEAST", point = { x = 110, y = 110, z = 0 } },
    { name = "SOUTH", point = { x = 100, y = 110, z = 0 } },
    { name = "SOUTHWEST", point = { x = 90, y = 110, z = 0 } },
    { name = "WEST", point = { x = 90, y = 100, z = 0 } },
    { name = "NORTHWEST", point = { x = 90, y = 90, z = 0 } },
}

for _, case in ipairs(cases) do
    local relation, reason = Relation.Between(origin, case.point)
    assert(relation, case.name .. " relation failed: " .. tostring(reason))
    assertEqual(relation.direction8, case.name,
        "PZ axis direction for " .. case.name)
    assertEqual(Relation.Opposite(case.name),
        Relation.Between(case.point, origin).direction8,
        "opposite symmetry for " .. case.name)
end

local localRelation = Relation.Between(origin, { x = 100.5, y = 100.5, z = 0 },
    { sameAreaThreshold = 1.0 })
assert(localRelation.sameArea, "dead-zone relation should be same area")
assertEqual(localRelation.direction8, "SAME_AREA", "same-area token")

local measured = Relation.Between({ x = 0, y = 0, z = 0 },
    { x = 3, y = 4, z = 12 }, { distanceBands = {
        { max = 5, token = "NEAR" },
        { max = 20, token = "MEDIUM" },
    } })
assertNear(measured.distance, 13, "numeric Euclidean distance")
assertEqual(measured.dx, 3, "dx")
assertEqual(measured.dy, 4, "dy")
assertEqual(measured.dz, 12, "dz")
assertEqual(measured.distanceBand, "MEDIUM", "configured distance band")
assertNear(measured.bearingDegrees, 143.1301023542,
    "canonical compass bearing")

local nan = 0 / 0
local invalidCases = {
    { point = { x = nan, y = 0 }, reason = "XY_REQUIRED" },
    { point = { x = math.huge, y = 0 }, reason = "XY_REQUIRED" },
    { point = { x = 0, y = 0, z = -math.huge }, reason = "Z_INVALID" },
    { point = { y = 0 }, reason = "XY_REQUIRED" },
}
for _, case in ipairs(invalidCases) do
    local relation, reason = Relation.Between(origin, case.point)
    assertEqual(relation, nil, "invalid coordinate rejected")
    assertEqual(reason, case.reason, "invalid coordinate reason")
end

assertEqual(Relation.GetDirectionLabelKey("NORTHEAST"),
    "UI_PsychopatzCore_Spatial_Direction_Northeast", "direction label key")
assertEqual(Relation.GetDirectionLabel("NORTHEAST"), "northeast",
    "fallback direction label")

-- Observer-relative tactical bearing acceptance.
local function assertClock(target, heading, expectedHour, expectedToken, expectedSector, label)
    local relation, reason = Relation.RelativeToHeading(origin, target, heading,
        { sameAreaThreshold = 0.1 })
    assert(relation, (label or "clock") .. " relation failed: " .. tostring(reason))
    assertEqual(relation.clockHour, expectedHour, (label or "clock") .. " hour")
    assertEqual(relation.clockToken, expectedToken, (label or "clock") .. " token")
    assertEqual(relation.relativeSector8, expectedSector, (label or "clock") .. " sector")
    return relation
end

local northHeading = { x = 0, y = -1 }
assertClock({ x = 100, y = 90 }, northHeading, 12, "CLOCK_12", "AHEAD", "ahead")
assertClock({ x = 110, y = 100 }, northHeading, 3, "CLOCK_03", "RIGHT", "right")
assertClock({ x = 100, y = 110 }, northHeading, 6, "CLOCK_06", "BEHIND", "behind")
assertClock({ x = 90, y = 100 }, northHeading, 9, "CLOCK_09", "LEFT", "left")

local angle240 = math.rad(240)
local clockEightPoint = {
    x = origin.x + math.sin(angle240) * 10,
    y = origin.y - math.cos(angle240) * 10,
}
assertClock(clockEightPoint, northHeading, 8, "CLOCK_08", "REAR_LEFT",
    "rear-left eight o'clock")

for hour = 1, 12 do
    local degrees = (hour % 12) * 30
    local radians = math.rad(degrees)
    local point = {
        x = origin.x + math.sin(radians) * 10,
        y = origin.y - math.cos(radians) * 10,
    }
    local expected = string.format("CLOCK_%02d", hour)
    local relation = Relation.RelativeToHeading(origin, point, northHeading,
        { sameAreaThreshold = 0.1 })
    assert(relation, "clock sector " .. hour .. " should resolve")
    assertEqual(relation.clockHour, hour, "clock sector hour " .. hour)
    assertEqual(relation.clockToken, expected, "clock sector token " .. hour)
end

local diagonalHeading = { x = 3, y = -3 }
local diagonalScaled = { x = 30, y = -30 }
local diagTarget = { x = 110, y = 90 }
local diagA = Relation.RelativeToHeading(origin, diagTarget, diagonalHeading,
    { sameAreaThreshold = 0.1 })
local diagB = Relation.RelativeToHeading(origin, diagTarget, diagonalScaled,
    { sameAreaThreshold = 0.1 })
assertEqual(diagA.clockToken, "CLOCK_12", "non-cardinal heading forward")
assertEqual(diagB.clockToken, diagA.clockToken, "heading scale invariance")

local rotated = Relation.RelativeToHeading(origin, { x = 110, y = 100 },
    { x = 1, y = 0 }, { sameAreaThreshold = 0.1 })
assertEqual(rotated.clockToken, "CLOCK_12", "observer rotation updates clock relation")

local invalidHeading, invalidHeadingReason = Relation.RelativeToHeading(origin,
    { x = 110, y = 100 }, { x = 0, y = 0 })
assertEqual(invalidHeading, nil, "zero heading rejected")
assertEqual(invalidHeadingReason, "HEADING_ZERO", "zero heading reason")

local malformedHeading, malformedHeadingReason = Relation.RelativeToHeading(origin,
    { x = 110, y = 100 }, { x = 0 / 0, y = 1 })
assertEqual(malformedHeading, nil, "invalid heading rejected")
assertEqual(malformedHeadingReason, "HEADING_XY_REQUIRED", "invalid heading reason")

local sameAreaClock = Relation.RelativeToHeading(origin,
    { x = 100.05, y = 100.05 }, northHeading, { sameAreaThreshold = 1.0 })
assert(sameAreaClock and sameAreaClock.sameArea, "same-area clock relation exists")
assertEqual(sameAreaClock.clockHour, nil, "same-area suppresses clock hour")
assertEqual(sameAreaClock.clockToken, nil, "same-area suppresses clock token")
assertEqual(sameAreaClock.relativeSector8, nil, "same-area suppresses relative sector")

assertEqual(Relation.GetClockLabelKey("CLOCK_08"),
    "UI_PsychopatzCore_Spatial_Clock_08", "clock label key")
assertEqual(Relation.GetClockLabel("CLOCK_08"), "8 o'clock", "clock fallback label")
assertEqual(Relation.GetRelativeSectorLabelKey("REAR_LEFT"),
    "UI_PsychopatzCore_Spatial_Relative_RearLeft", "relative sector label key")
assertEqual(Relation.GetRelativeSectorLabel("REAR_LEFT"), "behind us, left side",
    "relative sector fallback label")

local function pointAtClockDegrees(degrees, radius)
    local radians = math.rad(degrees)
    return {
        x = origin.x + math.sin(radians) * (radius or 10),
        y = origin.y - math.cos(radians) * (radius or 10),
    }
end

local justBeforeBoundary = Relation.RelativeToHeading(origin,
    pointAtClockDegrees(14.999), northHeading, { sameAreaThreshold = 0.1 })
local exactBoundary = Relation.RelativeToHeading(origin,
    pointAtClockDegrees(15.0), northHeading, { sameAreaThreshold = 0.1 })
local justAfterBoundary = Relation.RelativeToHeading(origin,
    pointAtClockDegrees(15.001), northHeading, { sameAreaThreshold = 0.1 })
assertEqual(justBeforeBoundary.clockToken, "CLOCK_12",
    "clock boundary below 15 degrees")
assertEqual(exactBoundary.clockToken, "CLOCK_01",
    "clock boundary at 15 degrees is deterministic")
assertEqual(justAfterBoundary.clockToken, "CLOCK_01",
    "clock boundary above 15 degrees")

print("psychopatz spatial relation: ok")
