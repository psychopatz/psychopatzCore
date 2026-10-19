local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Notifications = {}
Notifications.SCHEMA_VERSION = 1
Notifications.MAX_ITEMS = 128

local Queue = {}
Queue.__index = Queue

function Notifications.NewQueue()
    return setmetatable({ items = {}, seen = {}, revision = 0 }, Queue)
end

function Queue:Publish(spec)
    spec = type(spec) == "table" and spec or {}
    local notificationID = Util.text(spec.notificationID
        or spec.notificationId, nil)
    local kind = Util.text(spec.kind, nil)
    if not notificationID then return nil, "notification_id_required" end
    if not kind then return nil, "notification_kind_required" end
    if self.seen[notificationID] then return nil, "duplicate_notification" end
    local payload = Util.clone(spec.payload or {})
    if not Util.isSerializable(payload) then return nil, "payload_invalid" end
    if #self.items >= Notifications.MAX_ITEMS then
        table.remove(self.items, 1)
    end
    local item = {
        schemaVersion = Notifications.SCHEMA_VERSION,
        notificationID = notificationID,
        kind = kind,
        actorID = Util.text(spec.actorID or spec.actorId, nil),
        createdAt = tonumber(spec.createdAt) or 0,
        payload = payload,
        acknowledged = false,
    }
    self.items[#self.items + 1] = item
    self.seen[notificationID] = true
    self.revision = self.revision + 1
    return Util.clone(item)
end

function Queue:List(includeAcknowledged)
    local output = {}
    for index = 1, #self.items do
        local item = self.items[index]
        if includeAcknowledged == true or not item.acknowledged then
            output[#output + 1] = Util.clone(item)
        end
    end
    return output
end

function Queue:Acknowledge(notificationID)
    for _, item in ipairs(self.items) do
        if item.notificationID == notificationID then
            item.acknowledged = true
            self.revision = self.revision + 1
            return true
        end
    end
    return false, "notification_not_found"
end

function Queue:Drain(limit)
    local output = {}
    local remaining = math.max(1, math.floor(tonumber(limit) or 16))
    for _, item in ipairs(self.items) do
        if not item.acknowledged and #output < remaining then
            item.acknowledged = true
            output[#output + 1] = Util.clone(item)
        end
    end
    if #output > 0 then self.revision = self.revision + 1 end
    return output
end

return Notifications
