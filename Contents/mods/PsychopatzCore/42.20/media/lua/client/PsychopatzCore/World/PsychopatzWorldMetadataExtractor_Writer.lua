PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Extractor = Core.WorldMetadataExtractor
local Internal = Extractor.Internal
local Session = Internal.Session

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



return Session
