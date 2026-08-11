local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"
local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
local Virtual = PsychopatzCore.Inventory.VirtualInventoryClass

local function queryTypeId(query)
    if type(query) == "number" then return math.floor(query) end
    if type(query) == "string" then return Types.getId(query, false) end
    if type(query) == "table" then
        return tonumber(query.typeId) or (query.fullType and Types.getId(query.fullType, false))
    end
    return nil
end

function Virtual:reserve(query, quantity, owner)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local typeId = queryTypeId(query)
    if not typeId then return nil, "reservation_requires_item_type" end
    if self:count(query, false) < quantity then return nil, "insufficient_available_quantity" end
    local id = self.nextReservationId
    self.nextReservationId = id + 1
    local token = {
        id = id,
        typeId = typeId,
        quantity = quantity,
        owner = owner,
        query = query,
    }
    self.reservations[id] = token
    self.reservedByType[typeId] = (self.reservedByType[typeId] or 0) + quantity
    Metrics.increment("reservationCount")
    return token
end

function Virtual:releaseReservation(token)
    local id = type(token) == "table" and token.id or tonumber(token)
    local saved = id and self.reservations[id] or nil
    if not saved then return false, "reservation_not_found" end
    self.reservations[id] = nil
    self.reservedByType[saved.typeId] = math.max(0,
        (self.reservedByType[saved.typeId] or 0) - saved.quantity)
    return true
end

function Virtual:commitReservation(token)
    local id = type(token) == "table" and token.id or tonumber(token)
    local saved = id and self.reservations[id] or nil
    if not saved then return false, "reservation_not_found" end
    local ok, removed = self:remove(
        saved.query or saved.typeId,
        saved.quantity,
        { includeReserved = true }
    )
    if not ok then return false, removed end
    self:releaseReservation(saved)
    return true, removed
end

return Virtual
