-- Sampled Radio OS performance evidence. Gesture tracing does not enable this
-- module's timing or Lua-memory work.

PsychopatzCore = PsychopatzCore or {}
local Core = PsychopatzCore
local OS = Core.RadioOS
local Diagnostics = OS.Diagnostics
local DebugSettings = Core.DebugSettings

local SAMPLE_EVERY = 10
local SUMMARY_INTERVAL_MS = 2000
local RESOURCE_INTERVAL_MS = 1000
local SETTING_ID = Diagnostics.PERFORMANCE_SETTING

local function resetPhase()
    return { calls = 0, samples = 0, totalMs = 0, maxMs = 0, lastMs = 0 }
end

function Diagnostics.ResetPerformance()
    Diagnostics._performance = {
        prerender = resetPhase(),
        render = resetPhase(),
        lastSummaryAt = nil,
        lastResourceAt = nil,
        luaMemoryKB = nil,
        windowCount = 0,
        textureCount = 0,
        lastSampleAt = nil,
    }
end

Diagnostics.ResetPerformance()

local function nowMs()
    if type(getTimeInMillis) == "function" then
        return tonumber(getTimeInMillis())
    end
    return nil
end

local function tableCount(values)
    local count = 0
    for key, value in pairs(values or {}) do
        if key ~= nil and value ~= nil then count = count + 1 end
    end
    return count
end

local function activeWindowCount()
    local registry = OS._registry
    if not registry then return 0 end
    local count = 0
    for _, window in pairs(registry.windows or {}) do
        if window and window._closed ~= true then count = count + 1 end
    end
    return count
end

local function resourceSample(window, current)
    local performance = Diagnostics._performance
    if performance.lastResourceAt and current
        and current - performance.lastResourceAt < RESOURCE_INTERVAL_MS
    then
        return
    end
    performance.lastResourceAt = current
    performance.lastSampleAt = current
    performance.windowCount = activeWindowCount()
    performance.textureCount = tableCount(window and window._textures)
    if type(collectgarbage) == "function" then
        local ok, value = pcall(collectgarbage, "count")
        if ok then performance.luaMemoryKB = tonumber(value) end
    end
end

function Diagnostics.GetPerformanceSnapshot(window)
    if not Diagnostics.IsPerformanceEnabled() then return nil end
    local performance = Diagnostics._performance
    local current = nowMs()
    resourceSample(window, current)
    local output = {
        windowCount = performance.windowCount,
        textureCount = performance.textureCount,
        luaMemoryKB = performance.luaMemoryKB,
        sampleEvery = SAMPLE_EVERY,
        lastSampleAt = performance.lastSampleAt,
    }
    for _, phase in ipairs({ "prerender", "render" }) do
        local stats = performance[phase]
        local prefix = phase .. "_"
        output[prefix .. "calls"] = stats.calls
        output[prefix .. "samples"] = stats.samples
        output[prefix .. "lastMs"] = stats.lastMs
        output[prefix .. "maxMs"] = stats.maxMs
        output[prefix .. "avgMs"] = stats.samples > 0
            and stats.totalMs / stats.samples or 0
    end
    return output
end

function Diagnostics.BeginFrame(window, phase)
    if not Diagnostics.IsPerformanceEnabled() then return nil end
    phase = phase == "render" and "render" or "prerender"
    local stats = Diagnostics._performance[phase]
    stats.calls = stats.calls + 1
    if stats.calls % SAMPLE_EVERY ~= 0 then return nil end
    local started = nowMs()
    if not started then return nil end
    return { phase = phase, started = started }
end

function Diagnostics.EndFrame(window, token)
    if not token or not Diagnostics.IsPerformanceEnabled() then return end
    local finished = nowMs()
    if not finished then return end
    local elapsed = math.max(0, finished - token.started)
    local stats = Diagnostics._performance[token.phase]
    stats.samples = stats.samples + 1
    stats.totalMs = stats.totalMs + elapsed
    stats.lastMs = elapsed
    stats.maxMs = math.max(stats.maxMs, elapsed)

    if token.phase ~= "prerender" then return end
    resourceSample(window, finished)
    local performance = Diagnostics._performance
    if performance.lastSummaryAt and finished - performance.lastSummaryAt
        < SUMMARY_INTERVAL_MS
    then
        return
    end
    performance.lastSummaryAt = finished
    Diagnostics.RecordPerformance("performance.summary",
        Diagnostics.GetPerformanceSnapshot(window))
end

if not DebugSettings and type(require) == "function" then
    pcall(require, "PsychopatzCore/Debug/PsychopatzDebugSettings")
    DebugSettings = Core.DebugSettings
end

if DebugSettings and type(DebugSettings.Register) == "function" then
    DebugSettings.Register({
        id = SETTING_ID,
        source = "PsychopatzCore.RadioOS",
        order = 220,
        title = "Radio OS performance diagnostics",
        description = "Samples Radio OS UI cost, resource counts, and Lua memory; disabled by default.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SetPerformanceEnabled(enabled)
        end,
    })
end

return Diagnostics
