local SHARED = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;" .. package.path

local authorized = true
local chunkLoaded = false
local printed = {}
local oldPrint = print

PsychopatzCore = {
    Debug = {
        CanUse = function() return authorized end,
    },
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end

print = function(message)
    printed[#printed + 1] = tostring(message)
end

local metaChunk = {
    getUnadjustedZombieIntensity = function() return 128 end,
    getZombieIntensity = function(_, deterministic)
        assert(deterministic == false,
            "population debug must request deterministic intensity")
        return 6.5
    end,
}

local zombieType = {
    getName = function() return "Office" end,
    getType = function() return "ZombiesType" end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getWidth = function() return 8 end,
    getHeight = function() return 8 end,
}

local metaGrid = {
    getChunkDataFromTile = function(_, x, y)
        assert(x == -1 and y == 80, "map coordinates were not normalized")
        return metaChunk
    end,
    isChunkLoaded = function(_, physicalX, physicalY)
        assert(physicalX == -1 and physicalY == 8,
            "loaded check did not use physical chunk coordinates")
        return chunkLoaded
    end,
    getZonesAt = function()
        return {
            size = function() return 1 end,
            get = function() return zombieType end,
        }
    end,
}

getWorld = function()
    return {
        getMetaGrid = function() return metaGrid end,
        getCell = function()
            if not chunkLoaded then
                error("unloaded population inspection must not access the cell")
            end
            return {
                getZombieList = function()
                    local zombies = {
                        { getX = function() return -5 end, getY = function() return 85 end },
                        { getX = function() return -1 end, getY = function() return 89 end },
                        { getX = function() return 5 end, getY = function() return 85 end },
                    }
                    return {
                        size = function() return #zombies end,
                        get = function(_, index) return zombies[index + 1] end,
                    }
                end,
            }
        end,
    }
end

local Context = require
    "PsychopatzCore/Debug/PsychopatzZombiePopulationDebugContext"
assert(Context.InspectCoordinates({}, -0.25, 80.75, 0, "map"),
    "population inspection did not complete")
assert(#printed == 1, "population inspection did not print one record")
assert(string.find(printed[1], "metaChunk=-1,10", 1, true),
    "meta chunk coordinates were incorrect")
assert(string.find(printed[1], "physicalChunk=-1,8", 1, true),
    "physical chunk coordinates were incorrect")
assert(string.find(printed[1], "loaded=false", 1, true),
    "unloaded state was missing")
assert(string.find(printed[1], "exactCount=<nil>", 1, true),
    "unloaded inspection reported an exact count")
assert(string.find(printed[1], "estimatedCount=7", 1, true),
    "deterministic estimate was missing")
assert(string.find(printed[1], "rawIntensity=128", 1, true),
    "raw intensity was missing")
assert(string.find(printed[1], "zombiesType=Office", 1, true),
    "zombie type was missing")

chunkLoaded = true
assert(Context.InspectCoordinates({}, -0.25, 80.75, 0, "map"),
    "loaded population inspection did not complete")
assert(string.find(printed[2], "loaded=true", 1, true),
    "loaded state was missing")
assert(string.find(printed[2], "exactCount=2", 1, true),
    "loaded exact count was incorrect")
assert(string.find(printed[2], "confidence=exact-loaded-chunk", 1, true),
    "loaded confidence was incorrect")

authorized = false
assert(not Context.InspectCoordinates({}, 1, 1, 0, "map"),
    "population inspection bypassed debug access")
assert(#printed == 2, "unauthorized population inspection printed output")

print = oldPrint
print("psychopatz_zombie_population_debug_context_smoke: ok")
