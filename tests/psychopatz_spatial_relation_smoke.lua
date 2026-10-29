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

print("psychopatz spatial relation: ok")
