-- The only bridge module loaded while bridge_enabled=false. Keep startup gating here.
PsychopatzCore = PsychopatzCore or {}
local Bootstrap = PsychopatzCore.BridgeBootstrap or {}
PsychopatzCore.BridgeBootstrap = Bootstrap

Bootstrap.CONFIG_FILE = "PsychopatzCore_Bridge.txt"
Bootstrap.enabled = false

local function truthy(value)
    value = string.lower(tostring(value or "false"))
    return value == "true" or value == "1" or value == "yes" or value == "on"
end

local function readConfig()
    if not getFileReader then return { enabled = false, transport = "file", pollIntervalMs = 250 } end
    local reader = getFileReader(Bootstrap.CONFIG_FILE, false)
    if not reader then return { enabled = false, transport = "file", pollIntervalMs = 250 } end
    local values, line = {}, reader:readLine()
    while line do
        local key, value = string.match(line, "^%s*([%w_]+)%s*=%s*([^#;]+)")
        if key then values[string.lower(key)] = string.match(value, "^%s*(.-)%s*$") end
        line = reader:readLine()
    end
    reader:close()
    local interval = math.max(100, math.min(5000,
        math.floor(tonumber(values.bridge_poll_interval_ms) or 250)))
    local enabled = truthy(values.bridge_enabled)
    return { version = 1, enabled = enabled, transport = "file", pollIntervalMs = interval,
        fingerprint = table.concat({ "v1", tostring(enabled), "file", tostring(interval) }, "|") }
end

local function authoritative()
    local server = isServer and isServer() or false
    local client = isClient and isClient() or false
    if client and not server then return false, "multiplayer_client" end
    return true, server and "server" or "singleplayer"
end

function Bootstrap.IsEnabled() return Bootstrap.enabled == true end
function Bootstrap.GetConfig() return Bootstrap.config or readConfig() end

function Bootstrap.Initialize()
    if Bootstrap.initialized then return Bootstrap.IsEnabled() end
    Bootstrap.initialized = true
    Bootstrap.config = readConfig()
    if not Bootstrap.config.enabled then return false end
    local allowed, authority = authoritative()
    if not allowed then return false end
    local Runtime = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
    local runtime = Runtime.GetRuntimeMetadata()
    local Transport = require "PsychopatzCore/Bridge/PsychopatzBridgeFileTransport"
    local Bridge = require "PsychopatzCore/Bridge/PsychopatzBridge"
    Bootstrap.enabled = Bridge.Initialize({ runtimeID = runtime.id,
        startedAt = getTimeInMillis and getTimeInMillis() or 0,
        configFingerprint = Bootstrap.config.fingerprint,
        pollIntervalMs = Bootstrap.config.pollIntervalMs,
        transport = Transport, authority = authority }) == true
    if Bootstrap.enabled then
        print("[PsychopatzBridge] runtime=" .. runtime.id
            .. " config=" .. Bootstrap.config.fingerprint .. " authority=" .. authority)
    end
    return Bootstrap.enabled
end

Bootstrap.ReadConfig = readConfig
return Bootstrap
