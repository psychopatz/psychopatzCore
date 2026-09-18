local SHARED = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;" .. package.path

PsychopatzCore = {}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end

local function javaList(entries)
    return {
        size = function() return #entries end,
        get = function(_, index) return entries[index + 1] end,
    }
end

local function room(id, name, x, y, z, width, height, flags)
    flags = flags or {}
    return {
        getIDString = function() return id end,
        getName = function() return name end,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        getW = function() return width end,
        getH = function() return height end,
        getX2 = function() return x + width - 1 end,
        getY2 = function() return y + height - 1 end,
        getRects = function() return javaList({ {} }) end,
        isShop = function() return flags.shop == true end,
        isKidsRoom = function() return flags.kids == true end,
        isUserDefined = function() return flags.user == true end,
        isEmptyOutside = function() return flags.outside == true end,
    }
end

local kitchen = room("room-kitchen", "Kitchen", 101, 202, 0, 5, 4)
local bathroom = room("room-bathroom", "Bathroom", 106, 202, 0, 3, 3,
    { user = true })
local rooms = javaList({ kitchen, bathroom })

local building = {
    getIDString = function() return "building-rosewood-1" end,
    getX = function() return 100 end,
    getY = function() return 200 end,
    getW = function() return 12 end,
    getH = function() return 10 end,
    getX2 = function() return 111 end,
    getY2 = function() return 209 end,
    getRooms = function() return rooms end,
    isResidential = function() return true end,
    isShop = function() return false end,
}

local town = {
    getIDString = function() return "zone-town" end,
    getName = function() return "Rosewood" end,
    getOriginalName = function() return "Rosewood" end,
    getType = function() return "TownZone" end,
    getX = function() return 90 end,
    getY = function() return 190 end,
    getWidth = function() return 40 end,
    getHeight = function() return 40 end,
}
local forest = {
    getIDString = function() return "zone-forest" end,
    getName = function() return "Rosewood Forest" end,
    getOriginalName = function() return "Rosewood Forest" end,
    getType = function() return "Forest" end,
    getX = function() return 300 end,
    getY = function() return 300 end,
    getWidth = function() return 20 end,
    getHeight = function() return 20 end,
}
local zombiesType = {
    getIDString = function() return "zone-zombies-type" end,
    getName = function() return "Rosewood Restaurant" end,
    getOriginalName = function() return "Rosewood Restaurant" end,
    getType = function() return "ZombiesType" end,
    getX = function() return 95 end,
    getY = function() return 195 end,
    getWidth = function() return 30 end,
    getHeight = function() return 30 end,
}
local nav = {
    getIDString = function() return "zone-nav" end,
    getName = function() return "Rosewood Nav" end,
    getOriginalName = function() return "Rosewood Nav" end,
    getType = function() return "Nav" end,
    getX = function() return 95 end,
    getY = function() return 195 end,
    getWidth = function() return 30 end,
    getHeight = function() return 30 end,
}

local metaGrid = {
    getMinX = function() return 0 end,
    getMaxX = function() return 999 end,
    getMinY = function() return 0 end,
    getMaxY = function() return 999 end,
    getZones = function()
        return javaList({ town, town, forest, zombiesType, nav })
    end,
    getZonesAt = function()
        return javaList({ town, zombiesType, nav })
    end,
    getBuildings = function()
        return javaList({ building, building })
    end,
}
local world = {
    getMetaGrid = function() return metaGrid end,
}

local files = {}
getFileWriter = function(name)
    local chunks = {}
    return {
        write = function(_, value) chunks[#chunks + 1] = value end,
        close = function() files[name] = table.concat(chunks) end,
    }
end

local Extractor = require
    "PsychopatzCore/World/PsychopatzWorldMetadataExtractor"
local session = Extractor.CreateSession({
    world = world,
    writeOutput = false,
    itemLimit = 2,
})
local started, startReason = session:Start()
assert(started, "metadata session failed to start: " .. tostring(startReason))
local ok, reason, document = session:RunToCompletion()
assert(ok and document and not reason,
    "metadata extraction failed: " .. tostring(reason))
assert(session.state == "complete", "metadata session did not complete")
assert(#session.logs <= 5, "metadata session log exceeded five lines")
assert(document.schemaVersion == 2, "schema version was missing")
assert(document.tagging.status == "raw", "semantic tagging was not deferred")
assert(document.stats.zoneCount == 3, "duplicate zones were not removed")
assert(document.stats.buildingCount == 1,
    "duplicate buildings were not removed")
assert(document.stats.roomCount == 2, "duplicate rooms were not removed")
assert(document.stats.duplicateZones == 1,
    "zone duplicate diagnostic was missing")
assert(document.stats.duplicateBuildings == 1,
    "building duplicate diagnostic was missing")
assert(document.stats.duplicateRooms == 0,
    "room duplicate diagnostic was missing")

local place = session.places.rosewood
assert(place and #place.buildings == 1, "place grouping was missing")
local buildingRecord = place.buildings[1]
assert(buildingRecord.position == nil and buildingRecord.bounds == nil,
    "runtime coordinates leaked into building output")
local building = buildingRecord
assert(building.id == "building:building-rosewood-1",
    "building ID was not stable")
assert(building.size.width == 12 and building.size.height == 10,
    "building size was not exported")
assert(building.size.roomCount == 2 and building.size.floorCount == 1,
    "building room/floor counts were not exported")
assert(building.features.isResidential == true,
    "building structural feature was not exported")
assert(#building.rooms == 2 and #building.zoneIDs == 2,
    "building relationships were not normalized")
assert(string.find(building.rooms[1].id,
    "room:building:building-rosewood-1:",
    1, true),
    "room IDs were not scoped to their building")
assert(building.features.roomNameCounts.bathroom == 1,
    "room name feature counts were not exported")
assert(building.rooms[1].size.area > 0,
    "room size feature was not exported")
assert(building.rooms[1].position == nil and building.rooms[1].bounds == nil,
    "runtime coordinates leaked into room output")

local exported, exportReason = Extractor.Export({ world = world })
assert(exported and not exportReason,
    "metadata export failed: " .. tostring(exportReason))
assert(files[Extractor.INDEX_FILE], "metadata index was not written")
assert(files[Extractor.OUTPUT_ROOT .. "/Rosewood.json"],
    "place metadata file was not written")
assert(files[Extractor.OUTPUT_ROOT .. "/Zones/ZombiesType/Rosewood.json"],
    "ZombiesType metadata file was not written")
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local decoded, decodeReason = Json.Decode(
    files[Extractor.OUTPUT_ROOT .. "/Rosewood.json"])
assert(decoded and not decodeReason, "metadata JSON was invalid")
assert(decoded.stats.roomCount == 2,
    "metadata JSON did not preserve normalized counts")
assert(decoded.place.name == "Rosewood", "place name was not exported")

files = {}
local navSession = Extractor.CreateSession({
    world = world,
    writeOutput = true,
    itemLimit = 2,
    zoneSelections = {
        Places = false,
        ZombiesType = false,
        Nav = true,
        ForagingNav = false,
        SpawnPoint = false,
        Other = false,
    },
})
local navStarted, navStartReason = navSession:Start()
assert(navStarted, "Nav-only session failed to start: " .. tostring(navStartReason))
local navOK, navReason = navSession:RunToCompletion()
assert(navOK and not navReason,
    "Nav-only extraction failed: " .. tostring(navReason))
assert(files[Extractor.OUTPUT_ROOT .. "/Zones/Nav/Rosewood.json"],
    "Nav-only output file was not written")
assert(not files[Extractor.OUTPUT_ROOT .. "/Rosewood.json"],
    "Nav-only extraction wrote place metadata")
assert(navSession.uniqueCounts.buildings == 0
    and navSession.uniqueCounts.rooms == 0,
    "Nav-only extraction scanned building or room metadata")

print("psychopatz_world_metadata_extractor_smoke: ok")
