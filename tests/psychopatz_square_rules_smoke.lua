local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    package.path,
}, ";")

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function object(sprite, properties, data, grid)
    local propertySet = properties or {}
    local propertyContainer = {
        Is = function(_, key) return propertySet[key] ~= nil end,
        Val = function(_, key) return propertySet[key] end,
    }
    local spriteValue = {
        getName = function() return sprite end,
        getProperties = function() return propertyContainer end,
        getSpriteGrid = function() return grid end,
    }
    return {
        getSprite = function() return spriteValue end,
        getProperties = function() return propertyContainer end,
        getModData = function() return data or {} end,
    }
end

local squares = {}
local function square(x, y, objects, data)
    local value = {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        getObjects = function() return javaList(objects or {}) end,
        getModData = function() return data or {} end,
    }
    squares[x .. ":" .. y .. ":0"] = value
    return value
end

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[x .. ":" .. y .. ":" .. z]
        end,
    }
end

local bedSquare = square(1, 1, {
    object("furniture_bedding_01_0", {
        BedType = "GoodBed", CustomName = "Bed", Facing = "E",
    }, nil, {
        getSpriteGridPosX = function() return 0 end,
        getSpriteGridPosY = function() return 0 end,
        getWidth = function() return 2 end,
        getHeight = function() return 1 end,
    }),
})
square(2, 1, { object("vegetation_farming_01_4") })
square(3, 1, {}, { farming = true })
square(4, 1, {})

local Rules = require "PsychopatzCore/World/PsychopatzSquareRules"
equal(Rules.MatchSquare(bedSquare, "bed"), true, "bed property rule")
local bed = Rules.DescribeBed(bedSquare)
equal(bed.x, 2, "multi-tile bed center x")
equal(bed.y, 1.5, "multi-tile bed center y")
equal(bed.axis, "x", "multi-tile bed axis")
equal(bed.facing, "E", "bed facing")
equal(Rules.MatchAt(2, 1, 0, "farmland"), true, "farmland sprite rule")
equal(Rules.MatchAt(3, 1, 0, "farmland"), true, "farmland mod-data rule")
equal(Rules.MatchAt(4, 1, 0, "farmland"), false, "ordinary ground rejected")

local valid, reason = Rules.ValidateRegion({
    levels = { [0] = { rows = { [1] = { 2, 3 } } } },
}, "farmland")
equal(valid, true, "all-farmland region accepted")

valid, reason = Rules.ValidateRegion({
    levels = { [0] = { rows = { [1] = { 2, 4 } } } },
}, "farmland")
equal(valid, false, "mixed ground region rejected")
equal(reason, "FARMLAND_REQUIRED", "region rejection reason")

print("psychopatz_square_rules_smoke: ok")
