local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"

local Registry = { data = nil, reverse = {}, available = {} }

local function cleanData(raw)
    local data = {
        schemaVersion = C.REGISTRY_SCHEMA,
        revision = 0,
        nextId = 1,
        types = {},
    }
    local highest = 0
    if type(raw) == "table" and tonumber(raw.schemaVersion) == C.REGISTRY_SCHEMA then
        data.revision = math.max(0, math.floor(tonumber(raw.revision) or 0))
        for id, fullType in pairs(raw.types or {}) do
            id = math.floor(tonumber(id) or 0)
            if id > 0 and type(fullType) == "string" and fullType ~= "" then
                data.types[id] = fullType
                if id > highest then highest = id end
            end
        end
        data.nextId = math.max(highest + 1, math.floor(tonumber(raw.nextId) or 1))
        -- One revision is issued per append, so a revision is also a safe
        -- incremental-sync cursor without persisting a second index.
        data.revision = math.max(data.revision, highest)
    end
    return data
end

local function rebuild()
    Registry.reverse = {}
    for id, fullType in pairs(Registry.data.types) do
        if not Registry.reverse[fullType] then Registry.reverse[fullType] = id end
    end
    Metrics.gauge("registeredItemTypes", Registry.data.nextId - 1)
end

function Registry.load(raw)
    Registry.data = cleanData(raw)
    rebuild()
    return Registry.data
end

function Registry.getData()
    if not Registry.data then Registry.load(nil) end
    return Registry.data
end

function Registry.getId(fullType, create)
    local data = Registry.getData()
    fullType = type(fullType) == "string" and fullType or nil
    if not fullType or fullType == "" then return nil end
    if Registry.reverse[fullType] then return Registry.reverse[fullType] end
    if create == false then return nil end
    local id = data.nextId
    data.nextId = id + 1
    data.revision = data.revision + 1
    data.types[id] = fullType
    Registry.reverse[fullType] = id
    Metrics.gauge("registeredItemTypes", data.nextId - 1)
    return id
end

function Registry.getFullType(id)
    return Registry.getData().types[math.floor(tonumber(id) or 0)]
end

function Registry.scan(fullTypes)
    local values = {}
    local seen = {}
    local added = 0
    for i = 1, #(fullTypes or {}) do
        local value = tostring(fullTypes[i] or "")
        if value ~= "" and not seen[value] then
            seen[value] = true
            values[#values + 1] = value
        end
    end
    table.sort(values)
    Registry.available = seen
    for i = 1, #values do
        if not Registry.reverse[values[i]] then
            Registry.getId(values[i], true)
            added = added + 1
        end
    end
    local missing = 0
    for _, fullType in pairs(Registry.getData().types) do
        if not seen[fullType] then missing = missing + 1 end
    end
    Metrics.gauge("missingItemTypes", missing)
    return added
end

function Registry.scanScripts(manager)
    local items
    local values = {}
    manager = manager or (getScriptManager and getScriptManager())
    if not manager or not manager.getAllItems then return 0 end
    items = Util.javaList(manager:getAllItems())
    for i = 1, #items do
        local fullType = Util.call(items[i], "getFullName")
            or Util.call(items[i], "getFullType")
        if fullType then values[#values + 1] = tostring(fullType) end
    end
    return Registry.scan(values)
end

function Registry.isAvailable(id)
    local fullType = Registry.getFullType(id)
    return fullType ~= nil and Registry.available[fullType] == true
end

function Registry.getDelta(sinceRevision)
    local data = Registry.getData()
    local start = math.max(0, math.floor(tonumber(sinceRevision) or 0)) + 1
    local entries = {}
    for id = start, data.nextId - 1 do
        if data.types[id] then entries[#entries + 1] = { id, data.types[id] } end
    end
    return { schemaVersion = C.REGISTRY_SCHEMA, revision = data.revision, entries = entries }
end

function Registry.applyDelta(delta)
    local data = Registry.getData()
    if type(delta) ~= "table" or tonumber(delta.schemaVersion) ~= C.REGISTRY_SCHEMA then
        return false, "registry_schema_mismatch"
    end
    for i = 1, #(delta.entries or {}) do
        local entry = delta.entries[i]
        local id = math.floor(tonumber(entry and entry[1]) or 0)
        local fullType = entry and entry[2]
        if id <= 0 or type(fullType) ~= "string" then return false, "invalid_registry_entry" end
        if data.types[id] and data.types[id] ~= fullType then return false, "registry_id_conflict" end
        if Registry.reverse[fullType] and Registry.reverse[fullType] ~= id then
            return false, "registry_type_conflict"
        end
        data.types[id] = fullType
        Registry.reverse[fullType] = id
        if id >= data.nextId then data.nextId = id + 1 end
    end
    data.revision = math.max(data.revision, math.floor(tonumber(delta.revision) or 0))
    return true
end

function Registry.initializeWorld()
    local root
    if ModData and ModData.getOrCreate then
        root = ModData.getOrCreate("PsychopatzCore.Inventory")
        Registry.load(root.itemTypeRegistry)
        Registry.scanScripts()
        root.itemTypeRegistry = Registry.getData()
    else
        Registry.load(nil)
        Registry.scanScripts()
    end
    return Registry.getData()
end

Registry.load(nil)
PsychopatzCore.Inventory.ItemTypeRegistry = Registry
return Registry
