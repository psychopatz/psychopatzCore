PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Extractor = Core.WorldMetadataExtractor
local Internal = Extractor.Internal
local Session = Internal.Session

local call = Internal.call
local callGlobal = Internal.callGlobal
local number = Internal.number
local nonEmptyString = Internal.nonEmptyString
local normalizedName = Internal.normalizedName
local safeFileName = Internal.safeFileName
local increment = Internal.increment
local addUnique = Internal.addUnique
local listSize = Internal.listSize
local listItem = Internal.listItem
local boundsFor = Internal.boundsFor
local sizeFor = Internal.sizeFor
local overlaps = Internal.overlaps
local engineID = Internal.engineID
local compareID = Internal.compareID
local zoneIsTechnical = Internal.zoneIsTechnical
local zoneDetails = Internal.zoneDetails
local publicZone = Internal.publicZone
local publicRoom = Internal.publicRoom
local publicBuilding = Internal.publicBuilding

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


return Session

