local SHARED = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;" .. package.path

local authorized = false
local printed = {}
local oldPrint = print

PsychopatzCore = {
    Debug = {
        CanUse = function() return authorized end,
    },
}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end

print = function(message)
    printed[#printed + 1] = tostring(message)
end

local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = { name = name, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    return menu
end

local function javaList(entries)
    return {
        size = function() return #entries end,
        get = function(_, index) return entries[index + 1] end,
    }
end

local townZone = {
    getName = function() return "Rosewood" end,
    getOriginalName = function() return "Rosewood" end,
    getType = function() return "TownZone" end,
    getZ = function() return 0 end,
    getWidth = function() return 40 end,
    getHeight = function() return 40 end,
    getTotalArea = function() return 1600 end,
}
local forestZone = {
    getName = function() return "Rosewood Forest" end,
    getOriginalName = function() return "Rosewood Forest" end,
    getType = function() return "Forest" end,
    getZ = function() return 0 end,
    getWidth = function() return 20 end,
    getHeight = function() return 20 end,
}
local zombiesZone = {
    getName = function() return "Restaurant" end,
    getOriginalName = function() return "Restaurant" end,
    getType = function() return "ZombiesType" end,
    getZ = function() return 0 end,
    getWidth = function() return 10 end,
    getHeight = function() return 8 end,
    zombiesTypeToSpawn = "Restaurant",
}
local foragingZone = {
    getName = function() return "Rosewood Forage" end,
    getOriginalName = function() return "Rosewood Forage" end,
    getType = function() return "ForagingNav" end,
    getZ = function() return 0 end,
    getWidth = function() return 30 end,
    getHeight = function() return 30 end,
}
local roomDef = {
    getName = function() return "kitchen" end,
}
local square = {
    getX = function() return 101 end,
    getY = function() return 202 end,
    getZ = function() return 0 end,
    getZoneType = function() return "TownZone" end,
    getSquareZombiesType = function() return "Restaurant" end,
    getLootZone = function() return "RestaurantLoot" end,
    getRoomDef = function() return roomDef end,
}
local player = {
    getCurrentSquare = function() return square end,
}
local metaGrid = {
    getZonesAt = function()
        return javaList({ townZone, forestZone, zombiesZone, foragingZone })
    end,
}
local world = {
    getMetaGrid = function() return metaGrid end,
}
getWorld = function() return world end
getZone = function() return forestZone end

local Context = require "PsychopatzCore/Debug/PsychopatzPlaceDebugContext"
local menu = newMenu()

assert(Context.Add(menu, player) == nil,
    "place option was visible without debug access")
assert(#menu.options == 0, "unauthorized place menu was not empty")

authorized = true
local option = Context.Add(menu, player)
assert(option and option.name == "[Debug] Inspect Current Place",
    "place option label was incorrect")
option.callback()
assert(#printed == 1, "place option did not print a record")
assert(string.find(printed[1], "coords=101,202,0", 1, true),
    "coordinates were missing")
assert(string.find(printed[1], "town=Rosewood", 1, true),
    "TownZone name was missing")
assert(string.find(printed[1], "preferredZone=Rosewood Forest:Forest", 1, true),
    "preferred zone was missing")
assert(string.find(printed[1], "zones=Rosewood:TownZone,Rosewood Forest:Forest,Restaurant:ZombiesType,Rosewood Forage:ForagingNav",
    1, true), "overlapping zones were missing")
assert(string.find(printed[1], "zoneMetadata=", 1, true),
    "zone metadata section was missing")
assert(string.find(printed[1], "type=ZombiesType", 1, true),
    "ZombiesType metadata was missing")
assert(string.find(printed[1], "zombiesTypeToSpawn=Restaurant", 1, true),
    "ZombiesType spawn metadata was missing")
assert(string.find(printed[1], "type=ForagingNav", 1, true),
    "ForagingNav metadata was missing")
assert(string.find(printed[1], "size=10x8", 1, true),
    "zone dimensions were missing")
assert(string.find(printed[1], "squareZoneType=TownZone", 1, true),
    "loaded square zone type was missing")
assert(string.find(printed[1], "squareZombiesType=Restaurant", 1, true),
    "loaded square ZombiesType was missing")
assert(string.find(printed[1], "squareLootZone=RestaurantLoot", 1, true),
    "loaded square loot zone was missing")
assert(string.find(printed[1], "room=kitchen", 1, true),
    "room name was missing")

authorized = false
option.callback()
assert(#printed == 1, "stale place option bypassed debug access")

print = oldPrint
print("psychopatz_place_debug_context_smoke: ok")
