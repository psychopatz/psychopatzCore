require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Extractor = Core.WorldMetadataExtractor or {}
Core.WorldMetadataExtractor = Extractor

-- Coordinates and bounds are used internally to associate records, but never
-- leave this module. They are runtime facts, not stable NLP features.
Extractor.OUTPUT_ROOT = Extractor.OUTPUT_ROOT
    or "Debugs/WorldPlaceMetadata"
Extractor.INDEX_FILE = Extractor.INDEX_FILE
    or (Extractor.OUTPUT_ROOT .. "/Index.json")
Extractor.SCHEMA_VERSION = Extractor.SCHEMA_VERSION or 2
Extractor.STEP_BUDGET_MS = Extractor.STEP_BUDGET_MS or 3
Extractor.STEP_ITEM_LIMIT = Extractor.STEP_ITEM_LIMIT or 64
Extractor.MAX_LOG_LINES = 5
Extractor.DEFAULT_ZONE_SELECTIONS = {
    Places = true,
    ZombiesType = true,
    Nav = false,
    ForagingNav = false,
    SpawnPoint = false,
    Other = true,
}

local Json
local function jsonCodec()
    if not Json then
        Json = require "PsychopatzCore/Serialization/PsychopatzJson"
    end
    return Json
end

local JSON_LIMITS = {
    maxDepth = 16,
    maxCollection = 10000,
    maxString = 1048576,
}

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function callGlobal(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    return ok and value or nil
end

local function number(value)
    if value == nil then return nil end
    return tonumber(value)
end

local function nonEmptyString(value)
    if value == nil then return nil end
    local text = tostring(value)
    return text ~= "" and text or nil
end

local function normalizedName(value)
    local text = nonEmptyString(value)
    if not text then return nil end
    text = string.lower(text)
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text ~= "" and text or nil
end

local function safeFileName(value)
    local text = nonEmptyString(value) or "Unassigned"
    text = string.gsub(text, "[^%w%-%_ ]", "_")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text ~= "" and text or "Unassigned"
end

local function increment(bucket, key)
    bucket[key] = (bucket[key] or 0) + 1
end

local function addUnique(list, seen, value)
    if not value or seen[value] then return false end
    seen[value] = true
    list[#list + 1] = value
    return true
end

local function listSize(list)
    local size = number(call(list, "size"))
    if not size or size < 0 then return nil end
    return math.floor(size)
end

local function listItem(list, index)
    return call(list, "get", index)
end

local function boundsFor(object, widthMethod, heightMethod, x2Method, y2Method)
    local x = number(call(object, "getX"))
    local y = number(call(object, "getY"))
    local width = number(call(object, widthMethod))
    local height = number(call(object, heightMethod))
    local x2 = number(call(object, x2Method))
    local y2 = number(call(object, y2Method))
    if width == nil and x ~= nil and x2 ~= nil then width = x2 - x + 1 end
    if height == nil and y ~= nil and y2 ~= nil then height = y2 - y + 1 end
    if x == nil or y == nil or width == nil or height == nil then
        return nil
    end
    return { x = x, y = y, width = width, height = height }
end

local function sizeFor(bounds, extras)
    local result = {
        width = bounds and bounds.width or 0,
        height = bounds and bounds.height or 0,
    }
    result.area = result.width * result.height
    if type(extras) == "table" then
        for key, value in pairs(extras) do result[key] = value end
    end
    return result
end

local function overlaps(left, right)
    if not left or not right then return false end
    return left.x < right.x + right.width
        and right.x < left.x + left.width
        and left.y < right.y + right.height
        and right.y < left.y + left.height
end

local function engineID(object)
    local id = nonEmptyString(call(object, "getIDString"))
    if id then return id end
    return nonEmptyString(call(object, "getID"))
end

local function compareID(left, right)
    return tostring(left.id or "") < tostring(right.id or "")
end

local function zoneIsTechnical(zoneType)
    local value = string.lower(tostring(zoneType or ""))
    return value == "nav" or value == "foragingnav"
        or value == "spawnpoint"
end

local function zoneDetails(zone)
    local bounds = boundsFor(zone, "getWidth", "getHeight", nil, nil)
    local rawName = nonEmptyString(call(zone, "getName"))
    local originalName = nonEmptyString(call(zone, "getOriginalName"))
    local zoneType = nonEmptyString(call(zone, "getType"))
    local normalizedType = normalizedName(zoneType) or "unknown"
    local normalizedZoneName = normalizedName(originalName or rawName)
    local key = normalizedType .. "|" .. (normalizedZoneName or "")
    local placeName
    if zoneType == "Region" or (zoneType == "TownZone" and rawName) then
        placeName = rawName or originalName
    end
    return {
        id = "zone:" .. key,
        type = "zone",
        rawName = rawName,
        originalName = originalName,
        zoneType = zoneType,
        normalizedName = normalizedZoneName,
        bounds = bounds,
        placeName = placeName,
        isPlaceZone = zoneType == "Region"
            or (zoneType == "TownZone"
                and (rawName ~= nil or originalName ~= nil)),
    }
end

local function publicZone(zone)
    return {
        id = zone.id,
        type = zone.type,
        rawName = zone.rawName,
        originalName = zone.originalName,
        zoneType = zone.zoneType,
        normalizedName = zone.normalizedName,
        size = zone.size,
        features = zone.features,
    }
end

local function publicRoom(room)
    return {
        id = room.id,
        type = room.type,
        rawName = room.rawName,
        normalizedName = room.normalizedName,
        level = room.level,
        size = room.size,
        features = room.features,
    }
end

local function publicBuilding(building)
    return {
        id = building.id,
        type = building.type,
        size = building.size,
        zoneIDs = building.zoneIDs,
        features = building.features,
        rooms = building.rooms,
    }
end

local Session = {}
Session.__index = Session

local function nowMillis()
    return number(callGlobal(getTimeInMillis))
end

function Session:log(message)
    local lines = self.logs
    if #lines >= Extractor.MAX_LOG_LINES then
        for index = 1, #lines - 1 do lines[index] = lines[index + 1] end
        lines[#lines] = tostring(message)
    else
        lines[#lines + 1] = tostring(message)
    end
end

function Session:fail(reason)
    self.state = "failed"
    self.error = tostring(reason or "unknown_error")
    self:log("Failed: " .. self.error)
end

function Session:resetData()
    self.state = "idle"
    self.phase = "idle"
    self.error = nil
    self.logs = {}
    self.zoneList = nil
    self.buildingList = nil
    self.zoneCursor = 0
    self.buildingCursor = 0
    self.currentBuilding = nil
    self.roomCursor = 0
    self.zoneByID = {}
    self.buildingsSeen = {}
    self.placeAreas = {}
    self.places = {}
    self.placeKeys = {}
    self.placeCursor = 0
    self.outputUnits = {}
    self.outputUnitCursor = 0
    self.writeUnit = nil
    self.writer = nil
    self.writerStage = nil
    self.writerZoneCursor = 0
    self.writerBuildingCursor = 0
    self.indexDocument = nil
    self.rawCounts = { zones = 0, buildings = 0, rooms = 0 }
    self.uniqueCounts = { zones = 0, buildings = 0, rooms = 0 }
    self.duplicateCounts = { zones = 0, buildings = 0, rooms = 0 }
    self.excludedZoneTypes = {}
    self.fileNames = {}
end

function Session.new(options)
    local session = setmetatable({}, Session)
    session.options = type(options) == "table" and options or {}
    session.timeBudgetMs = tonumber(session.options.timeBudgetMs)
        or Extractor.STEP_BUDGET_MS
    session.itemLimit = tonumber(session.options.itemLimit)
        or Extractor.STEP_ITEM_LIMIT
    session.writeOutput = session.options.writeOutput ~= false
    session.zoneSelections = {}
    for key, value in pairs(Extractor.DEFAULT_ZONE_SELECTIONS) do
        session.zoneSelections[key] = value
    end
    if type(session.options.zoneSelections) == "table" then
        for key, value in pairs(session.options.zoneSelections) do
            session.zoneSelections[key] = value == true
        end
    end
    session.includePlaceMetadata = session.zoneSelections.Places == true
    session:resetData()
    return session
end

function Session:ensurePlace(placeName)
    local normalized = normalizedName(placeName) or "unassigned"
    local display = nonEmptyString(placeName) or "Unassigned"
    local place = self.places[normalized]
    if place then return place end

    local fileName = safeFileName(display)
    if self.fileNames[fileName]
        and self.fileNames[fileName] ~= normalized
    then
        fileName = fileName .. "_" .. normalized
    end
    self.fileNames[fileName] = normalized
    place = {
        key = normalized,
        name = display,
        normalizedName = normalized,
        fileName = fileName .. ".json",
        baseZones = {},
        baseZoneSeen = {},
        zonesByType = {},
        buildings = {},
        buildingSeen = {},
        roomCount = 0,
        duplicateCounts = { zones = 0, buildings = 0, rooms = 0 },
    }
    self.places[normalized] = place
    return place
end

function Session:prepare()
    local world = self.options.world or callGlobal(getWorld)
    if not world then return false, "world_unavailable" end
    local metaGrid = self.options.metaGrid or call(world, "getMetaGrid")
    if not metaGrid then return false, "meta_grid_unavailable" end

    self.world = world
    self.metaGrid = metaGrid
    self.zoneList = call(metaGrid, "getZones")
    self.buildingList = call(metaGrid, "getBuildings")
    self.zoneTotal = listSize(self.zoneList)
    self.buildingTotal = listSize(self.buildingList)
    if self.zoneTotal == nil then return false, "zones_unavailable" end
    if self.buildingTotal == nil and self.includePlaceMetadata then
        return false, "buildings_unavailable"
    end
    self.zoneTotal = math.max(0, self.zoneTotal)
    self.buildingTotal = math.max(0, self.buildingTotal or 0)
    self.phase = "zones"
    self:log("Started world metadata extraction")
    return true
end

function Session:isZoneSelected(data)
    if data.isPlaceZone then
        return self.zoneSelections.Places == true
    end
    local zoneType = data.zoneType
    if zoneType and self.zoneSelections[zoneType] ~= nil then
        return self.zoneSelections[zoneType] == true
    end
    return self.zoneSelections.Other ~= false
end

function Session:Start()
    if self.state == "running" then return false, "already_running" end
    self:resetData()
    local ok, reason = self:prepare()
    if not ok then
        self:fail(reason)
        return false, reason
    end
    self.state = "running"
    return true
end

function Session:Cancel()
    if self.state ~= "running" then return false end
    self.state = "cancelled"
    self.phase = "cancelled"
    self:log("Cancelled")
    if self.writer then pcall(self.writer.close, self.writer) end
    self.writer = nil
    return true
end

function Session:processZone()
    local index = self.zoneCursor
    self.zoneCursor = index + 1
    local zone = listItem(self.zoneList, index)
    self.rawCounts.zones = self.rawCounts.zones + 1
    if not zone then return end

    local data = zoneDetails(zone)
    if data.placeName then
        local place = self:ensurePlace(data.placeName)
        self.placeAreas[#self.placeAreas + 1] = {
            placeKey = place.key,
            bounds = data.bounds,
        }
    end
    if not self:isZoneSelected(data) then
        increment(self.excludedZoneTypes, data.zoneType or "unknown")
        return
    end

    data.output = true

    local existing = self.zoneByID[data.id]
    if existing then
        self.duplicateCounts.zones = self.duplicateCounts.zones + 1
        existing.size.segmentCount = (existing.size.segmentCount or 1) + 1
        existing.size.totalArea = (existing.size.totalArea or existing.size.area)
            + (data.bounds and data.bounds.width * data.bounds.height or 0)
        return
    end

    local area = data.bounds and data.bounds.width * data.bounds.height or 0
    data.size = sizeFor(data.bounds, { segmentCount = 1, totalArea = area })
    data.features = {
        hasName = data.rawName ~= nil,
        hasOriginalName = data.originalName ~= nil,
        isPlaceRegion = data.placeName ~= nil,
    }
    data._placeKey = data.placeName
        and (normalizedName(data.placeName) or "unassigned") or nil
    data.public = publicZone(data)
    self.zoneByID[data.id] = data
    self.uniqueCounts.zones = self.uniqueCounts.zones + 1
end

function Session:resolveBuildingZones(building)
    local candidates = {}
    local candidateSeen = {}
    local placeCandidates = {}
    local placeSeen = {}
    local center = building._bounds and {
        x = building._bounds.x + building._bounds.width / 2,
        y = building._bounds.y + building._bounds.height / 2,
    }
    local nearby
    if center and type(self.metaGrid.getZonesAt) == "function" then
        nearby = call(self.metaGrid, "getZonesAt", math.floor(center.x),
            math.floor(center.y), 0)
    end
    local nearbySize = listSize(nearby)
    if nearbySize ~= nil then
        for index = 0, nearbySize - 1 do
            local zone = listItem(nearby, index)
            if zone then
                local data = zoneDetails(zone)
                local known = self.zoneByID[data.id]
                if known then
                    if known.output then
                        addUnique(candidates, candidateSeen, data.id)
                    end
                    if not zoneIsTechnical(known.zoneType) then
                        addUnique(building.features.zoneTypes,
                            building.zoneTypeSeen, known.zoneType)
                        if known.normalizedName then
                            building.features.zoneNameCounts[
                                known.normalizedName] =
                                (building.features.zoneNameCounts[
                                    known.normalizedName] or 0) + 1
                            addUnique(building.features.zoneNames,
                                building.zoneNameSeen, known.normalizedName)
                        end
                    end
                    if known._placeKey then
                        addUnique(placeCandidates, placeSeen, known._placeKey)
                    end
                end
            end
        end
    end

    -- Region metadata is the reliable source for names such as Muldraugh and
    -- Rosewood. It is cheap to check because there are few region rectangles.
    for _, area in ipairs(self.placeAreas) do
        if overlaps(building._bounds, area.bounds) then
            addUnique(placeCandidates, placeSeen, area.placeKey)
        end
    end

    table.sort(placeCandidates)
    building.zoneIDs = candidates
    table.sort(building.zoneIDs)
    table.sort(building.features.zoneTypes)
    table.sort(building.features.zoneNames)
    building._placeKey = placeCandidates[1] or "unassigned"
end

function Session:processRoom()
    local building = self.currentBuilding
    local index = self.roomCursor
    if index >= building.roomTotal then
        self:resolveBuildingZones(building)
        if self.includePlaceMetadata then
            local place = self:ensurePlace(building._placeKey)
            if not place.buildingSeen[building.id] then
                place.buildingSeen[building.id] = true
                place.buildings[#place.buildings + 1] = publicBuilding(building)
                place.roomCount = place.roomCount + #building.rooms
                self.uniqueCounts.buildings = self.uniqueCounts.buildings + 1
                self.uniqueCounts.rooms = self.uniqueCounts.rooms + #building.rooms
            end
        end
        self.currentBuilding = nil
        self.phase = "buildings"
        return
    end

    self.roomCursor = index + 1
    self.rawCounts.rooms = self.rawCounts.rooms + 1
    local room = listItem(building.roomList, index)
    if not room then return end

    local bounds = boundsFor(room, "getW", "getH", "getX2", "getY2")
    local rawName = nonEmptyString(call(room, "getName"))
    local normalized = normalizedName(rawName)
    local sourceID = engineID(room)
    local roomID = sourceID
        and ("room:" .. building.id .. ":" .. sourceID)
        or ("room:" .. building.id .. ":" .. (normalized or "unnamed")
            .. ":" .. tostring(index + 1))
    if building.roomSeen[roomID] then
        self.duplicateCounts.rooms = self.duplicateCounts.rooms + 1
        return
    end
    building.roomSeen[roomID] = true

    local z = number(call(room, "getZ"))
    local rectCount = listSize(call(room, "getRects")) or 0
    local roomData = {
        id = roomID,
        type = "room",
        rawName = rawName,
        normalizedName = normalized,
        level = z,
        size = sizeFor(bounds, { rectangleCount = rectCount }),
        features = {
            isShop = call(room, "isShop") == true,
            isKidsRoom = call(room, "isKidsRoom") == true,
            isUserDefined = call(room, "isUserDefined") == true,
            isEmptyOutside = call(room, "isEmptyOutside") == true,
            rectangleCount = rectCount,
        },
    }
    building.rooms[#building.rooms + 1] = publicRoom(roomData)
    if normalized then
        building.features.roomNameCounts[normalized] =
            (building.features.roomNameCounts[normalized] or 0) + 1
        addUnique(building.features.roomNames,
            building.roomNameSeen, normalized)
    end
    if z ~= nil and addUnique(building.features.levels,
        building.levelSeen, z)
    then
        table.sort(building.features.levels)
    end
    building.size.roomCount = #building.rooms
    building.size.floorCount = #building.features.levels
    building.features.hasRooms = #building.rooms > 0
    building.features.multiLevel = building.size.floorCount > 1
end

function Session:processBuilding()
    local index = self.buildingCursor
    self.buildingCursor = index + 1
    local building = listItem(self.buildingList, index)
    self.rawCounts.buildings = self.rawCounts.buildings + 1
    if not building then return end

    local bounds = boundsFor(building, "getW", "getH", "getX2", "getY2")
    local sourceID = engineID(building)
    local buildingID = sourceID
        and ("building:" .. sourceID)
        or ("building:unnamed:" .. tostring(index + 1))
    if self.buildingsSeen[buildingID] then
        self.duplicateCounts.buildings = self.duplicateCounts.buildings + 1
        return
    end
    self.buildingsSeen[buildingID] = true

    local roomList = call(building, "getRooms")
    local roomTotal = listSize(roomList) or 0
    local record = {
        id = buildingID,
        type = "building",
        size = sizeFor(bounds, { roomCount = 0, floorCount = 0 }),
        zoneIDs = {},
        features = {
            isResidential = call(building, "isResidential") == true,
            isShop = call(building, "isShop") == true,
            hasRooms = false,
            multiLevel = false,
            roomNames = {},
            roomNameCounts = {},
            levels = {},
            zoneTypes = {},
            zoneNames = {},
            zoneNameCounts = {},
        },
        rooms = {},
        _bounds = bounds,
        roomList = roomList,
        roomTotal = roomTotal,
        roomSeen = {},
        roomNameSeen = {},
        levelSeen = {},
        zoneTypeSeen = {},
        zoneNameSeen = {},
    }
    self.currentBuilding = record
    self.roomCursor = 0
    self.phase = "rooms"
end

function Session:assignZonesToPlaces()
    for _, zone in pairs(self.zoneByID) do
        local placeKey = zone._placeKey
        if not placeKey and zone.bounds then
            local candidates = {}
            local seen = {}
            for _, area in ipairs(self.placeAreas) do
                if overlaps(zone.bounds, area.bounds) then
                    addUnique(candidates, seen, area.placeKey)
                end
            end
            table.sort(candidates)
            placeKey = candidates[1]
        end
        if zone.output then
            local place = self:ensurePlace(placeKey or "Unassigned")
            if zone.isPlaceZone then
                if not place.baseZoneSeen[zone.id] then
                    place.baseZoneSeen[zone.id] = true
                    place.baseZones[#place.baseZones + 1] = zone.public
                end
            else
                local category = zone.zoneType or "Unknown"
                local bucket = place.zonesByType[category]
                if not bucket then
                    bucket = { records = {}, seen = {} }
                    place.zonesByType[category] = bucket
                end
                if not bucket.seen[zone.id] then
                    bucket.seen[zone.id] = true
                    bucket.records[#bucket.records + 1] = zone.public
                end
            end
        end
    end
end

function Session:buildOutputUnits()
    self.outputUnits = {}
    for _, key in ipairs(self.placeKeys) do
        local place = self.places[key]
        place.outputFiles = {}
        if self.includePlaceMetadata then
            local unit = {
                place = place,
                name = place.name,
                category = nil,
                file = place.fileName,
                path = Extractor.OUTPUT_ROOT .. "/" .. place.fileName,
                zones = place.baseZones,
                buildings = place.buildings,
                roomCount = place.roomCount,
                kind = "psychopatz.world_place_metadata",
            }
            self.outputUnits[#self.outputUnits + 1] = unit
            place.outputFiles[#place.outputFiles + 1] = unit
        end

        local categories = {}
        for category, bucket in pairs(place.zonesByType) do
            if #bucket.records > 0 then categories[#categories + 1] = category end
        end
        table.sort(categories)
        for _, category in ipairs(categories) do
            local bucket = place.zonesByType[category]
            local relative = "Zones/" .. safeFileName(category) .. "/"
                .. place.fileName
            local unit = {
                place = place,
                name = place.name,
                category = category,
                file = relative,
                path = Extractor.OUTPUT_ROOT .. "/" .. relative,
                zones = bucket.records,
                buildings = {},
                roomCount = 0,
                kind = "psychopatz.world_place_zone_metadata",
            }
            self.outputUnits[#self.outputUnits + 1] = unit
            place.outputFiles[#place.outputFiles + 1] = unit
        end
    end
end

function Session:prepareOutput()
    self:assignZonesToPlaces()
    self.placeKeys = {}
    for key, _ in pairs(self.places) do self.placeKeys[#self.placeKeys + 1] = key end
    table.sort(self.placeKeys)
    self.placeCursor = 0
    self:log("Preparing per-place output")
    self.phase = "sort"
end

function Session:sortOnePlace()
    self.placeCursor = self.placeCursor + 1
    local key = self.placeKeys[self.placeCursor]
    if not key then
        self.placeCursor = 0
        self:buildOutputUnits()
        if self.writeOutput then
            self.phase = "write"
        else
            self:buildIndexDocument()
            self.state = "complete"
            self.phase = "complete"
            self:log("Completed in-memory extraction")
        end
        return
    end
    local place = self.places[key]
    table.sort(place.baseZones, compareID)
    table.sort(place.buildings, compareID)
    for _, bucket in pairs(place.zonesByType) do
        table.sort(bucket.records, compareID)
    end
end

local function encode(value)
    return jsonCodec().Encode(value, JSON_LIMITS)
end

function Session:writeUnitHeader(unit)
    local stats = {
        zoneCount = #unit.zones,
        buildingCount = #unit.buildings,
        roomCount = unit.roomCount,
        duplicateZones = unit.place.duplicateCounts.zones,
        duplicateBuildings = unit.place.duplicateCounts.buildings,
        duplicateRooms = unit.place.duplicateCounts.rooms,
    }
    self.writer:write("{\"schemaVersion\":" .. tostring(Extractor.SCHEMA_VERSION)
        .. ",\"kind\":" .. encode(unit.kind)
        .. ",\"place\":" .. encode({
            name = unit.name,
            normalizedName = unit.place.normalizedName,
        })
        .. (unit.category and ",\"zoneCategory\":" .. encode(unit.category)
            or "")
        .. ",\"source\":{\"provider\":\"IsoMetaGrid\",\"scope\":\"static_map_metadata\"}"
        .. ",\"tagging\":{\"status\":\"raw\",\"semanticTags\":\"deferred\",\"consumer\":\"downstream semantic tagging agent\"}"
        .. ",\"stats\":" .. encode(stats)
        .. ",\"zones\":[")
    self.writerStage = "zones"
    self.writerZoneCursor = 0
    self.writerBuildingCursor = 0
end

function Session:writeUnitStep()
    local unit = self.writeUnit
    if self.writerStage == "open" then
        local writer = getFileWriter and getFileWriter(unit.path, true, true) or nil
        if not writer then return false, "file_writer_unavailable" end
        self.writer = writer
        self:writeUnitHeader(unit)
        return true
    end

    if self.writerStage == "zones" then
        self.writerZoneCursor = self.writerZoneCursor + 1
        local zone = unit.zones[self.writerZoneCursor]
        if zone then
            if self.writerZoneCursor > 1 then self.writer:write(",\n")
            else self.writer:write("\n") end
            self.writer:write(encode(zone))
            return true
        end
        self.writer:write("\n],\"buildings\":[")
        self.writerStage = "buildings"
        self.writerBuildingCursor = 0
        return true
    end

    if self.writerStage == "buildings" then
        self.writerBuildingCursor = self.writerBuildingCursor + 1
        local building = unit.buildings[self.writerBuildingCursor]
        if building then
            if self.writerBuildingCursor > 1 then self.writer:write(",\n")
            else self.writer:write("\n") end
            self.writer:write(encode(building))
            return true
        end
        self.writer:write("\n],\"diagnostics\":"
            .. encode({ excludedZoneTypes = self.excludedZoneTypes }) .. "}\n")
        local ok, reason = pcall(self.writer.close, self.writer)
        self.writer = nil
        if not ok then return false, tostring(reason) end
        self.writerStage = "closed"
        return true
    end
    return true
end

function Session:writeNextUnit()
    if self.writerStage == "closed" or self.writeUnit == nil then
        self.outputUnitCursor = self.outputUnitCursor + 1
        local unit = self.outputUnits[self.outputUnitCursor]
        if not unit then
            self.phase = "index"
            return true
        end
        self.writeUnit = unit
        self.writerStage = "open"
    end

    local ok, reason = self:writeUnitStep()
    if not ok then return false, reason end
    if self.writerStage == "closed" then self.writeUnit = nil end
    return true
end

function Session:buildIndexDocument()
    local places = {}
    local total = { zones = 0, buildings = 0, rooms = 0 }
    for _, key in ipairs(self.placeKeys) do
        local place = self.places[key]
        local files = {}
        for _, unit in ipairs(place.outputFiles or {}) do
            local stats = {
                zoneCount = #unit.zones,
                buildingCount = #unit.buildings,
                roomCount = unit.roomCount,
            }
            files[#files + 1] = {
                file = unit.file,
                category = unit.category,
                kind = unit.kind,
                stats = stats,
            }
            total.zones = total.zones + stats.zoneCount
            total.buildings = total.buildings + stats.buildingCount
            total.rooms = total.rooms + stats.roomCount
        end
        if #files > 0 then
            places[#places + 1] = {
                name = place.name,
                normalizedName = place.normalizedName,
                file = self.includePlaceMetadata and place.fileName or nil,
                files = files,
            }
        end
    end
    self.indexDocument = {
        schemaVersion = Extractor.SCHEMA_VERSION,
        kind = "psychopatz.world_place_metadata_index",
        outputRoot = Extractor.OUTPUT_ROOT,
        tagging = { status = "raw", semanticTags = "deferred" },
        selections = self.zoneSelections,
        places = places,
        stats = {
            rawZones = self.rawCounts.zones,
            rawBuildings = self.rawCounts.buildings,
            rawRooms = self.rawCounts.rooms,
            zoneCount = total.zones,
            buildingCount = total.buildings,
            roomCount = total.rooms,
            duplicateZones = self.duplicateCounts.zones,
            duplicateBuildings = self.duplicateCounts.buildings,
            duplicateRooms = self.duplicateCounts.rooms,
            excludedZoneTypes = self.excludedZoneTypes,
        },
    }
end

function Session:writeIndex()
    self:buildIndexDocument()
    local writer = getFileWriter and getFileWriter(Extractor.INDEX_FILE,
        true, true) or nil
    if not writer then return false, "file_writer_unavailable" end
    local ok, reason = pcall(function()
        writer:write(encode(self.indexDocument))
        writer:close()
    end)
    if not ok then return false, tostring(reason) end
    self.state = "complete"
    self.phase = "complete"
    self:log("Completed: " .. tostring(#self.outputUnits) .. " output files")
    return true
end

function Session:stepItem()
    if self.phase == "zones" then
        if self.zoneCursor < self.zoneTotal then
            self:processZone()
        else
            self:log("Zones scanned")
            self.phase = "buildings"
        end
        return
    end
    if self.phase == "buildings" then
        if not self.includePlaceMetadata then
            self:log("Building and room extraction skipped")
            self.phase = "assign"
        elseif self.buildingCursor < self.buildingTotal then
            self:processBuilding()
        else
            self:log("Buildings and rooms scanned")
            self.phase = "assign"
        end
        return
    end
    if self.phase == "rooms" then
        self:processRoom()
        return
    end
    if self.phase == "assign" then
        self:prepareOutput()
        return
    end
    if self.phase == "sort" then
        self:sortOnePlace()
        return
    end
    if self.phase == "write" then
        local ok, reason = self:writeNextUnit()
        if not ok then self:fail(reason) end
        return
    end
    if self.phase == "index" then
        local ok, reason = self:writeIndex()
        if not ok then self:fail(reason) end
    end
end

function Session:Step()
    if self.state ~= "running" then return self:Snapshot() end
    local start = nowMillis()
    local processed = 0
    while self.state == "running" do
        self:stepItem()
        processed = processed + 1
        if processed >= self.itemLimit then break end
        if self.timeBudgetMs > 0 and start then
            local current = nowMillis()
            if current and current - start >= self.timeBudgetMs then break end
        end
    end
    return self:Snapshot()
end

function Session:RunToCompletion()
    while self.state == "running" do self:Step() end
    return self.state == "complete", self.error, self.indexDocument
end

function Session:Snapshot()
    local current = self.phase
    local completed = 0
    local total = 0
    if current == "zones" then
        completed, total = self.zoneCursor, self.zoneTotal or 0
    elseif current == "buildings" or current == "rooms" then
        completed, total = self.buildingCursor, self.buildingTotal or 0
    elseif current == "sort" then
        completed, total = self.placeCursor, #self.placeKeys
    elseif current == "write" then
        completed, total = self.outputUnitCursor, #self.outputUnits
    elseif current == "complete" then
        completed, total = #self.outputUnits, #self.outputUnits
    end
    return {
        state = self.state,
        phase = current,
        completed = completed,
        total = total,
        currentPlace = self.writeUnit and self.writeUnit.name or nil,
        counts = {
            rawZones = self.rawCounts.zones,
            rawBuildings = self.rawCounts.buildings,
            rawRooms = self.rawCounts.rooms,
            zones = self.uniqueCounts.zones,
            buildings = self.uniqueCounts.buildings,
            rooms = self.uniqueCounts.rooms,
        },
        duplicates = self.duplicateCounts,
        logs = self.logs,
        outputRoot = Extractor.OUTPUT_ROOT,
        error = self.error,
    }
end

function Extractor.CreateSession(options)
    return Session.new(options)
end

-- Useful for focused tests and small integrations. The Debug Hub uses
-- CreateSession and Step instead, so a real map never enters this synchronous
-- path from the UI.
function Extractor.Extract(options)
    options = type(options) == "table" and options or {}
    local sessionOptions = {}
    for key, value in pairs(options) do sessionOptions[key] = value end
    sessionOptions.writeOutput = false
    sessionOptions.itemLimit = 1000000
    sessionOptions.timeBudgetMs = 0
    local session = Session.new(sessionOptions)
    local started, reason = session:Start()
    if not started then return nil, reason end
    local ok, runReason, document = session:RunToCompletion()
    if not ok then return nil, runReason end
    return document
end

function Extractor.Export(options)
    options = type(options) == "table" and options or {}
    local sessionOptions = {}
    for key, value in pairs(options) do sessionOptions[key] = value end
    sessionOptions.writeOutput = true
    local session = Session.new(sessionOptions)
    local started, reason = session:Start()
    if not started then return nil, reason end
    local ok, runReason, document = session:RunToCompletion()
    if not ok then return nil, runReason, document end
    return document
end

return Extractor
