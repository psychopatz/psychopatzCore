local Adapter = {}

Adapter.SNAPSHOT_FILE = "PsychopatzCore_Profiler_latest.json"
Adapter._callbacks = Adapter._callbacks or {}

function Adapter.nowMs()
    return getTimeInMillis and getTimeInMillis() or 0
end

function Adapter.sourceType()
    if isServer and isServer() then return "server" end
    if isClient and isClient() then return "client" end
    return "singleplayer"
end

function Adapter.addSampleCallback(callback)
    if Adapter._callbacks[callback] then return false end
    local event = Events and (Events.EveryOneSecond or Events.OnTick) or nil
    if not event or not event.Add then return false end
    event.Add(callback)
    Adapter._callbacks[callback] = event
    return true
end

function Adapter.removeSampleCallback(callback)
    local event = Adapter._callbacks[callback]
    if not event then return false end
    if event.Remove then event.Remove(callback) end
    Adapter._callbacks[callback] = nil
    return true
end

function Adapter.writeSnapshot(json)
    if not getFileWriter then return false end
    local writer = getFileWriter(Adapter.SNAPSHOT_FILE, true, false)
    if not writer then return false end
    writer:write(tostring(json or ""))
    writer:close()
    return true
end

function Adapter.onStop()
    for callback, event in pairs(Adapter._callbacks) do
        if event.Remove then event.Remove(callback) end
        Adapter._callbacks[callback] = nil
    end
end

return Adapter
