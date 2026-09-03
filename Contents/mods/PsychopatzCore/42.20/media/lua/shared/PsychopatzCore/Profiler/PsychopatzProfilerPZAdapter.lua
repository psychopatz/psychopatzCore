local Adapter = {}

Adapter.SNAPSHOT_FILE = "PsychopatzCore_Profiler_latest.json"
Adapter._callbacks = Adapter._callbacks or {}
Adapter._engineProfiler = nil
Adapter._lastNowMs = nil

function Adapter.nowMs()
    local now = 0
    local gameTimeReader = rawget(_G, "getGameTime")
    if type(gameTimeReader) == "function" then
        local ok, gameTime = pcall(gameTimeReader)
        if ok and gameTime ~= nil then
            local methodOk, method = pcall(function()
                return gameTime["getServerTimeMills"]
            end)
            if methodOk and type(method) == "function" then
                local valueOk, value = pcall(method, gameTime)
                if valueOk and type(value) == "number" and value > 0 then
                    now = value
                end
            end
        end
    end
    if now == 0 then now = getTimeInMillis and getTimeInMillis() or 0 end
    if Adapter._lastNowMs and now < Adapter._lastNowMs then
        now = Adapter._lastNowMs
    end
    Adapter._lastNowMs = now
    return now
end

function Adapter.sourceType()
    if isServer and isServer() then return "server" end
    if isClient and isClient() then return "client" end
    return "singleplayer"
end

function Adapter.addSampleCallback(callback, intervalMs)
    if Adapter._callbacks[callback] then return false end
    local useTickEvent = tonumber(intervalMs) and tonumber(intervalMs) < 1000
    local event = Events and (
        useTickEvent and (Events.OnTick or Events.EveryOneSecond)
        or (Events.EveryOneSecond or Events.OnTick)
    ) or nil
    if not event or not event.Add then return false end
    event.Add(callback)
    Adapter._callbacks[callback] = event
    return true
end

local FRAME_METRICS = {
    { name = "ProjectZomboid.Frame.AverageFPS", reader = "getAverageFPS" },
    { name = "ProjectZomboid.Frame.CPUTimeMs", reader = "getCPUTime" },
    { name = "ProjectZomboid.Frame.GPUTimeMs", reader = "getGPUTime" },
    { name = "ProjectZomboid.Frame.CPUWaitMs", reader = "getCPUWait" },
    { name = "ProjectZomboid.Frame.GPUWaitMs", reader = "getGPUWait" },
}

local PERFORMANCE_KEYS = {
    "memory-free", "memory-used", "memory-total", "memory-max",
    "min-update-period", "max-update-period", "avg-update-period", "fps",
    "pool-objs-total", "pool-objs-used", "pool-objs-free",
}

local NETWORK_KEYS = {
    "received-packets", "sent-packets", "received-bytes", "sent-bytes",
    "last-actual-bytes-received", "last-actual-bytes-sent",
    "last-user-message-bytes-resent", "packet-loss-last-second",
    "voip-received", "voip-sent",
}

local GAME_KEYS = {
    "players", "animals-objects", "animals-instances", "zombies-total",
    "zombies-loaded", "zombies-simulated", "zombies-culled",
}

local function readGlobal(name)
    local reader = rawget(_G, name)
    if type(reader) ~= "function" then return nil end
    local ok, value = pcall(reader)
    return ok and type(value) == "number" and value or nil
end

local function readObject(name)
    local reader = rawget(_G, name)
    if type(reader) ~= "function" then return nil end
    local ok, value = pcall(reader)
    return ok and value or nil
end

local function readMethod(object, name)
    if object == nil then return nil end
    local ok, method = pcall(function() return object[name] end)
    if not ok or type(method) ~= "function" then return nil end
    ok, value = pcall(method, object)
    return ok and type(value) == "number" and value or nil
end

local function setGauge(api, name, value)
    if value ~= nil then api.SetGauge(name, value) end
end

local function readStatisticTable(api, getterName, prefix, keys)
    local tableReader = rawget(_G, getterName)
    if type(tableReader) ~= "function" then return end
    local ok, values = pcall(tableReader)
    if not ok or values == nil then return end
    for index = 1, #keys do
        local key = keys[index]
        local valueOk, value = pcall(function() return values[key] end)
        if valueOk and type(value) == "number" then
            setGauge(api, prefix .. key, value)
        end
    end
end

function Adapter.installEngineMetrics(profiler)
    if Adapter._engineProfiler == profiler then return true end
    if not profiler or not profiler.IsSectionEnabled
        or not profiler.IsSectionEnabled("performance")
    then return false end
    profiler.RegisterNamespace("ProjectZomboid", {
        displayName = "Project Zomboid",
    })
    local registered = profiler.RegisterSampler("PsychopatzCore.baseGame", function(api)
        for index = 1, #FRAME_METRICS do
            local entry = FRAME_METRICS[index]
            setGauge(api, entry.name, readGlobal(entry.reader))
        end
        local settings = readObject("getPerformance")
        setGauge(api, "ProjectZomboid.Frame.TargetFPS",
            readMethod(settings, "getLockFPS"))
        setGauge(api, "ProjectZomboid.Frame.LightingFPS",
            readMethod(settings, "getLightingFPS"))
        setGauge(api, "ProjectZomboid.Frame.UIRenderFPS",
            readMethod(settings, "getUIRenderFPS"))
        readStatisticTable(api, "getPerformanceLocal",
            "ProjectZomboid.Statistics.Performance.", PERFORMANCE_KEYS)
        readStatisticTable(api, "getNetworkLocal",
            "ProjectZomboid.Statistics.Network.", NETWORK_KEYS)
        readStatisticTable(api, "getGameLocal",
            "ProjectZomboid.Statistics.Game.", GAME_KEYS)
    end, { section = "performance" })
    if registered then Adapter._engineProfiler = profiler end
    return registered
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
    Adapter._engineProfiler = nil
    Adapter._lastNowMs = nil
end

return Adapter
