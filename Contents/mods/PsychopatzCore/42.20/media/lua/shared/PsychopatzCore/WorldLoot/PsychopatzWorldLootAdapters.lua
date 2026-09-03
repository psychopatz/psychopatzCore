local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Registry = require "PsychopatzCore/WorldLoot/PsychopatzWorldLootSourceRegistry"

local Adapters = {}

local function call(object, methodName, ...)
    local method = object and object[methodName]
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, object, ...)
    return ok and value or nil
end

local function listValues(list)
    local output = {}
    if not list then return output end
    if type(list) == "table" and not list.size then
        for index = 1, #list do output[#output + 1] = list[index] end
        return output
    end
    if list.size and list.get then
        for index = 0, list:size() - 1 do
            output[#output + 1] = list:get(index)
        end
    end
    return output
end

local function objectName(object)
    return tostring(call(object, "getObjectName")
        or call(object, "getName") or "")
end

local function isCorpse(object)
    if not object then return false end
    if instanceof then
        local ok, result = pcall(instanceof, object, "IsoDeadBody")
        if ok and result == true then return true end
    end
    local name = string.lower(objectName(object))
    return object.isDeadBody == true or name == "corpse"
        or name == "isodeadbody"
end

local function location(source)
    return { x = source.x, y = source.y, z = source.z }
end

local function containerItems(source)
    return listValues(call(source.container, "getItems"))
end

local function containerLabel(container, object, fallback)
    return tostring(call(container, "getType")
        or call(object, "getName") or call(object, "getObjectName")
        or fallback)
end

local function emitContainer(emit, sourceType, square, object, container,
    containerIndex)
    if not container then return end
    local x = tonumber(call(square, "getX")) or 0
    local y = tonumber(call(square, "getY")) or 0
    local z = tonumber(call(square, "getZ")) or 0
    local label = containerLabel(container, object,
        sourceType == "corpse" and "Corpse" or "Container")
    emit({
        sourceType = sourceType,
        square = square,
        object = object,
        container = container,
        x = x, y = y, z = z,
    }, {
        sourceType = sourceType,
        x = x, y = y, z = z,
        label = label,
        containerIndex = containerIndex,
    }, sourceType .. ":" .. tostring(container))
end

local Container = { sourceType = "container", policyKey = "containers" }

function Container.Discover(square, _, emit)
    local objects = listValues(call(square, "getObjects"))
    for index = 1, #objects do
        local object = objects[index]
        if not isCorpse(object) then
            local count = tonumber(call(object, "getContainerCount")) or 0
            if count > 0 and object.getContainerByIndex then
                for containerIndex = 0, count - 1 do
                    emitContainer(emit, "container", square, object,
                        call(object, "getContainerByIndex", containerIndex),
                        containerIndex)
                end
            else
                emitContainer(emit, "container", square, object,
                    call(object, "getContainer"), 0)
            end
        end
    end
end

function Container.IsValid(source)
    return source and source.container ~= nil
        and call(source.container, "getItems") ~= nil
end

function Container.ListItems(source) return containerItems(source) end
function Container.GetLocation(source) return location(source) end
function Container.CreateStore(source)
    return Inventory.wrapPhysicalInventory(source.container, {
        recursive = false, syncOnMutation = true,
    })
end

local Corpse = { sourceType = "corpse", policyKey = "corpses" }

function Corpse.Discover(square, _, emit)
    local lists = {
        call(square, "getStaticMovingObjects"), call(square, "getObjects"),
    }
    local seen = {}
    for listIndex = 1, #lists do
        local objects = listValues(lists[listIndex])
        for index = 1, #objects do
            local object = objects[index]
            if not seen[object] and isCorpse(object) then
                seen[object] = true
                emitContainer(emit, "corpse", square, object,
                    call(object, "getContainer"), 0)
            end
        end
    end
end

function Corpse.IsValid(source) return Container.IsValid(source) end
function Corpse.ListItems(source) return containerItems(source) end
function Corpse.GetLocation(source) return location(source) end
function Corpse.CreateStore(source) return Container.CreateStore(source) end

local function floorObjects(source)
    local objects = listValues(call(source.square, "getWorldObjects"))
    local output = {}
    for index = 1, #objects do
        local item = call(objects[index], "getItem")
        if item then
            output[#output + 1] = { item = item, worldObject = objects[index] }
        end
    end
    return output
end

local function removeFloorObject(square, worldObject)
    if square and square.transmitRemoveItemFromSquare then
        local ok = pcall(square.transmitRemoveItemFromSquare, square, worldObject)
        if ok then return true end
    end
    if square and square.RemoveTileObject then
        local ok = pcall(square.RemoveTileObject, square, worldObject)
        if ok then return true end
    end
    if worldObject and worldObject.removeFromWorld then
        pcall(worldObject.removeFromWorld, worldObject)
        if worldObject.removeFromSquare then
            pcall(worldObject.removeFromSquare, worldObject)
        end
        return true
    end
    return false
end

local FloorStore = {}
FloorStore.__index = FloorStore

function FloorStore.new(source)
    return setmetatable({ source = source, revision = 0 }, FloorStore)
end

local function itemMatches(item, query)
    if type(query) == "function" then return query(item) == true end
    if type(query) == "table" and type(query.predicate) == "function" then
        return query.predicate(item) == true
    end
    if type(query) == "table" and query.fullType then
        return tostring(call(item, "getFullType") or "")
            == tostring(query.fullType)
    end
    if type(query) == "string" then
        return tostring(call(item, "getFullType") or "") == query
    end
    return query == nil
end

function FloorStore:remove(query, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local entries = floorObjects(self.source)
    local selected = {}
    for index = 1, #entries do
        if itemMatches(entries[index].item, query) then
            selected[#selected + 1] = entries[index]
            if #selected >= quantity then break end
        end
    end
    if #selected < quantity then return false, "insufficient_quantity" end
    local removed = { floorEntries = {} }
    for index = 1, #selected do
        local record, reason = ItemRecord.encode(selected[index].item, 1)
        if not record then return false, reason end
        removed[#removed + 1] = record
        removed.floorEntries[index] = selected[index]
    end
    for index = 1, #selected do
        if not removeFloorObject(self.source.square,
            selected[index].worldObject)
        then
            self:restoreRemoved(removed, index - 1)
            return false, "floor_remove_failed"
        end
    end
    self.revision = self.revision + 1
    return true, removed
end

function FloorStore:restoreRemoved(removed, maximum)
    maximum = math.min(tonumber(maximum) or #(removed.floorEntries or {}),
        #(removed.floorEntries or {}))
    for index = 1, maximum do
        local entry = removed.floorEntries[index]
        local square = self.source.square
        if not square or not square.AddWorldInventoryItem then return false end
        local restored = square:AddWorldInventoryItem(entry.item, 0.5, 0.5, 0)
        if not restored then return false end
        entry.worldObject = restored
    end
    return true
end

local Floor = { sourceType = "floor", policyKey = "floorItems" }

function Floor.Discover(square, _, emit)
    local objects = listValues(call(square, "getWorldObjects"))
    if #objects < 1 then return end
    local x = tonumber(call(square, "getX")) or 0
    local y = tonumber(call(square, "getY")) or 0
    local z = tonumber(call(square, "getZ")) or 0
    emit({ sourceType = "floor", square = square, x = x, y = y, z = z }, {
        sourceType = "floor", x = x, y = y, z = z,
        label = "floor",
    }, "floor:" .. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z))
end

function Floor.IsValid(source) return #floorObjects(source) > 0 end
function Floor.ListItems(source)
    local entries = floorObjects(source)
    local output = {}
    for index = 1, #entries do output[index] = entries[index].item end
    return output
end
function Floor.GetLocation(source) return location(source) end
function Floor.CreateStore(source) return FloorStore.new(source) end

Registry.Register(Container)
Registry.Register(Floor)
Registry.Register(Corpse)

Adapters.Container = Container
Adapters.Corpse = Corpse
Adapters.Floor = Floor
Adapters.FloorStore = FloorStore
Adapters.ListValues = listValues

return Adapters
