PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Extractor = Core.WorldMetadataExtractor
local Internal = Extractor.Internal
local Session = Internal.Session

local addUnique = Internal.addUnique
local compareID = Internal.compareID
local overlaps = Internal.overlaps
local publicBuilding = Internal.publicBuilding
local safeFileName = Internal.safeFileName

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



return Session

