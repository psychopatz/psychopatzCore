PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Extractor = Core.WorldMetadataExtractor
local Internal = Extractor.Internal

local call = Internal.call
local callGlobal = Internal.callGlobal
local number = Internal.number
local nonEmptyString = Internal.nonEmptyString
local normalizedName = Internal.normalizedName
local safeFileName = Internal.safeFileName
local listSize = Internal.listSize

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



Internal.Session = Session

return Session

