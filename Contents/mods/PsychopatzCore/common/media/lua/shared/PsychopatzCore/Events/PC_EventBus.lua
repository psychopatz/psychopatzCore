PsychopatzCore = PsychopatzCore or {}

local Events = PsychopatzCore.Events or {}
local listeners = Events._listeners or {}
Events._listeners = listeners

function Events.subscribe(eventType, listener, ownerToken)
    if type(eventType) ~= "string" or eventType == ""
        or type(listener) ~= "function"
    then return false end
    local list = listeners[eventType]
    if not list then
        list = {}
        listeners[eventType] = list
    end
    -- Registration is idempotent for a listener/owner pair. This prevents a
    -- reload or repeated composition pass from multiplying every delivery.
    for index = 1, #list do
        if list[index][1] == listener and list[index][2] == ownerToken then
            return true
        end
    end
    list[#list + 1] = { listener, ownerToken }
    return true
end

function Events.unsubscribe(eventType, listener)
    local list = listeners[eventType]
    if not list then return false end
    for index = #list, 1, -1 do
        if list[index][1] == listener then
            table.remove(list, index)
            if #list == 0 then listeners[eventType] = nil end
            return true
        end
    end
    return false
end

function Events.emit(eventType, ...)
    local list = listeners[eventType]
    if not list then return 0 end
    -- Deliver against a stable snapshot. A listener may subscribe or
    -- unsubscribe while handling an event without changing this delivery.
    local snapshot = {}
    for index = 1, #list do snapshot[index] = list[index] end
    local delivered = 0
    for index = 1, #snapshot do
        local ok, errorValue = pcall(snapshot[index][1], ...)
        if ok then
            delivered = delivered + 1
        elseif Events.onListenerError then
            pcall(Events.onListenerError, eventType, errorValue)
        end
    end
    return delivered
end

function Events.hasSubscribers(eventType)
    local list = listeners[eventType]
    return list ~= nil and #list > 0
end

function Events.getListenerCount(eventType)
    local list = listeners[eventType]
    return list and #list or 0
end

function Events.clearOwner(ownerToken)
    local removed = 0
    for eventType, list in pairs(listeners) do
        for index = #list, 1, -1 do
            if list[index][2] == ownerToken then
                table.remove(list, index)
                removed = removed + 1
            end
        end
        if #list == 0 then listeners[eventType] = nil end
    end
    return removed
end

PsychopatzCore.Events = Events
PC_Events = Events

return Events
