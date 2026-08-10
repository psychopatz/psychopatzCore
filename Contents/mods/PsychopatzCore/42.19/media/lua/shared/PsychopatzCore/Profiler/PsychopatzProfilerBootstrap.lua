-- This is the only profiler module loaded in a normal OFF session. Keep it tiny.
PsychopatzCore = PsychopatzCore or {}

local Bootstrap = PsychopatzCore.ProfilerBootstrap or {}
PsychopatzCore.ProfilerBootstrap = Bootstrap

Bootstrap.MODE_OFF = "OFF"
Bootstrap.MODE_BASIC = "BASIC"
Bootstrap.MODE_DETAILED = "DETAILED"
Bootstrap.CONFIG_FILE = "PsychopatzCore_Profiler.txt"
Bootstrap.mode = Bootstrap.mode or Bootstrap.MODE_OFF

local function normalizeMode(value)
    value = string.upper(string.match(tostring(value or "OFF"), "^%s*(.-)%s*$") or "OFF")
    if value == Bootstrap.MODE_BASIC or value == Bootstrap.MODE_DETAILED then
        return value
    end
    return Bootstrap.MODE_OFF
end

local function readConfiguredMode()
    local explicit = rawget(_G, "PSYCHOPATZ_PROFILER_MODE")
    if explicit ~= nil then return normalizeMode(explicit) end
    if not getFileReader then return Bootstrap.MODE_OFF end

    local reader = getFileReader(Bootstrap.CONFIG_FILE, false)
    if not reader then return Bootstrap.MODE_OFF end
    local mode = Bootstrap.MODE_OFF
    local line = reader:readLine()
    while line do
        local key, value = string.match(line, "^%s*([%w_]+)%s*=%s*([^#;]+)")
        if key and string.lower(key) == "mode" then
            mode = normalizeMode(value)
            break
        end
        line = reader:readLine()
    end
    reader:close()
    return mode
end

local function startRoleModules()
    local server = isServer and isServer() or false
    local client = isClient and isClient() or false
    if server then
        local bridge = require "PsychopatzCore/Profiler/PsychopatzProfilerServer"
        if bridge and bridge.Start then bridge.Start() end
    end
    if client or not server then
        local bridge = require "PsychopatzCore/Profiler/PsychopatzProfilerClient"
        if bridge and bridge.Start then bridge.Start() end
    end
end

function Bootstrap.IsEnabled()
    return Bootstrap.mode ~= Bootstrap.MODE_OFF
end

function Bootstrap.GetMode()
    return Bootstrap.mode
end

function Bootstrap.Enable(mode)
    mode = normalizeMode(mode)
    if mode == Bootstrap.MODE_OFF then return Bootstrap.Disable() end

    Bootstrap.mode = mode
    local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
    if type(Profiler) ~= "table" or type(Profiler.Start) ~= "function" then
        Bootstrap.mode = Bootstrap.MODE_OFF
        return nil, "restart_required"
    end
    local Adapter = require "PsychopatzCore/Profiler/PsychopatzProfilerPZAdapter"
    if Profiler.IsRunning and Profiler.IsRunning() then Profiler.Stop() end
    Profiler.Start(mode, Adapter)
    startRoleModules()
    return Profiler
end

function Bootstrap.Disable()
    local profiler = rawget(PsychopatzCore, "Profiler")
    if profiler and profiler.Stop then profiler.Stop() end
    local client = rawget(PsychopatzCore, "ProfilerClient")
    if client and client.Stop then client.Stop() end
    local server = rawget(PsychopatzCore, "ProfilerServer")
    if server and server.Stop then server.Stop() end
    Bootstrap.mode = Bootstrap.MODE_OFF
    return true
end

function Bootstrap.Initialize()
    if Bootstrap.initialized then return Bootstrap.IsEnabled() end
    Bootstrap.initialized = true
    local mode = readConfiguredMode()
    Bootstrap.mode = mode
    if mode ~= Bootstrap.MODE_OFF then Bootstrap.Enable(mode) end
    return Bootstrap.IsEnabled()
end

Bootstrap.NormalizeMode = normalizeMode
Bootstrap.ReadConfiguredMode = readConfiguredMode

return Bootstrap
