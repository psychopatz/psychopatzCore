-- This is the only profiler module loaded in a normal OFF session. Keep it tiny.
PsychopatzCore = PsychopatzCore or {}

local Bootstrap = PsychopatzCore.ProfilerBootstrap or {}
PsychopatzCore.ProfilerBootstrap = Bootstrap

Bootstrap.MODE_OFF = "OFF"
Bootstrap.MODE_BASIC = "BASIC"
Bootstrap.MODE_DETAILED = "DETAILED"
Bootstrap.CONFIG_FILE = "PsychopatzCore_Profiler.txt"
Bootstrap.mode = Bootstrap.mode or Bootstrap.MODE_OFF
Bootstrap.captureConfig = Bootstrap.captureConfig or nil
Bootstrap.captureControllers = Bootstrap.captureControllers or {}
Bootstrap.roleStarters = Bootstrap.roleStarters or {}
Bootstrap.activeRoles = Bootstrap.activeRoles or {}

local ROLE_ORDER = { "server", "client" }

local function normalizeMode(value)
    value = string.upper(string.match(tostring(value or "OFF"), "^%s*(.-)%s*$") or "OFF")
    if value == Bootstrap.MODE_BASIC or value == Bootstrap.MODE_DETAILED then
        return value
    end
    return Bootstrap.MODE_OFF
end

local function boundedInteger(value, default, minimum, maximum)
    value = math.floor(tonumber(value) or default)
    return math.max(minimum, math.min(maximum, value))
end

local function parseList(value)
    local output, seen = {}, {}
    for item in string.gmatch(tostring(value or ""), "[^,%s]+") do
        if not seen[item] then output[#output + 1], seen[item] = item, true end
    end
    return output
end

local function buildConfig(values)
    local mode = normalizeMode(values.mode)
    local requested, sections = {}, {}
    for _, section in ipairs(parseList(values.capture or "performance")) do
        requested[string.lower(section)] = true
    end
    for _, section in ipairs({ "performance", "moddata", "npc" }) do
        if requested[section] then sections[#sections + 1] = section end
    end
    if mode ~= Bootstrap.MODE_OFF and #sections == 0 then sections[1] = "performance" end
    local enabled = {}
    for _, section in ipairs(sections) do enabled[section] = true end
    local scope = string.lower(tostring(values.npc_scope or "selected"))
    if scope ~= "selected" and scope ~= "all_bounded" then scope = "selected" end
    local config = {
        version = 2, mode = mode, sections = sections, enabled = enabled,
        performanceIntervalMs = boundedInteger(values.performance_interval_ms, 1000, 250, 60000),
        modDataIntervalMs = boundedInteger(values.moddata_interval_ms, 60000, 5000, 3600000),
        npcIntervalMs = boundedInteger(values.npc_interval_ms, 5000, 1000, 300000),
        npcScope = scope, npcIDs = parseList(values.npc_ids),
    }
    local orderedIDs = {}
    for index = 1, #config.npcIDs do orderedIDs[index] = config.npcIDs[index] end
    table.sort(orderedIDs)
    config.fingerprint = table.concat({
        "v2", config.mode, table.concat(sections, ","),
        tostring(config.performanceIntervalMs), tostring(config.modDataIntervalMs),
        tostring(config.npcIntervalMs), config.npcScope, table.concat(orderedIDs, ","),
    }, "|")
    return config
end

local function readConfiguredConfig()
    local explicit = rawget(_G, "PSYCHOPATZ_PROFILER_MODE")
    if explicit ~= nil then return buildConfig({ mode = explicit }) end
    if not getFileReader then return buildConfig({ mode = "OFF" }) end

    local reader = getFileReader(Bootstrap.CONFIG_FILE, false)
    if not reader then return buildConfig({ mode = "OFF" }) end
    local values = {}
    local line = reader:readLine()
    while line do
        local key, value = string.match(line, "^%s*([%w_]+)%s*=%s*([^#;]+)")
        if key then values[string.lower(key)] = string.match(value, "^%s*(.-)%s*$") end
        line = reader:readLine()
    end
    reader:close()
    return buildConfig(values)
end

local function serializeConfig(config)
    local sections = table.concat(config.sections or {}, ",")
    local npcIDs = table.concat(config.npcIDs or {}, ",")
    return table.concat({
        "config_version=2",
        "mode=" .. tostring(config.mode or Bootstrap.MODE_OFF),
        "capture=" .. sections,
        "performance_interval_ms=" .. tostring(config.performanceIntervalMs or 1000),
        "moddata_interval_ms=" .. tostring(config.modDataIntervalMs or 60000),
        "npc_interval_ms=" .. tostring(config.npcIntervalMs or 5000),
        "npc_scope=" .. tostring(config.npcScope or "selected"),
        "npc_ids=" .. npcIDs,
        "",
    }, "\n")
end

function Bootstrap.IsEnabled()
    return Bootstrap.mode ~= Bootstrap.MODE_OFF
end

function Bootstrap.GetMode()
    return Bootstrap.mode
end

function Bootstrap.GetCaptureConfig()
    return Bootstrap.captureConfig or buildConfig({ mode = Bootstrap.mode })
end

function Bootstrap.WriteConfiguredConfig(config)
    if not getFileWriter then return false, "file_writer_unavailable" end
    config = config or Bootstrap.GetCaptureConfig()
    local writer = getFileWriter(Bootstrap.CONFIG_FILE, true, false)
    if not writer or not writer.write then return false, "file_writer_unavailable" end
    local ok, reason = pcall(function()
        writer:write(serializeConfig(config))
        if writer.close then writer:close() end
    end)
    if not ok then
        if writer.close then pcall(function() writer:close() end) end
        return false, tostring(reason)
    end
    return true
end

function Bootstrap.IsSectionEnabled(section)
    local config = Bootstrap.GetCaptureConfig()
    return config.mode ~= Bootstrap.MODE_OFF and config.enabled[tostring(section or "")] == true
end

local function runtimeID()
    if Bootstrap.runtimeID then return Bootstrap.runtimeID end
    local now = getTimeInMillis and getTimeInMillis() or 0
    local random = ZombRand and ZombRand(1000000000) or math.floor(now % 1000000000)
    Bootstrap.runtimeID = tostring(now) .. "-" .. tostring(random)
    return Bootstrap.runtimeID
end

function Bootstrap.GetRuntimeMetadata()
    local config = Bootstrap.GetCaptureConfig()
    return {
        id = runtimeID(), configFingerprint = config.fingerprint,
        capture = { performance = config.enabled.performance == true,
            moddata = config.enabled.moddata == true, npc = config.enabled.npc == true },
    }
end

function Bootstrap.RegisterCaptureController(id, callback)
    if type(id) ~= "string" or id == "" or type(callback) ~= "function" then return false end
    if Bootstrap.captureControllers[id] then return false end
    Bootstrap.captureControllers[id] = callback
    if Bootstrap.initialized or Bootstrap.IsEnabled() then
        local ok, value = pcall(callback, Bootstrap.GetCaptureConfig())
        if not ok or value == false then
            Bootstrap.captureControllers[id] = nil
            return false
        end
    end
    return true
end

function Bootstrap.UnregisterCaptureController(id)
    id = tostring(id or "")
    if id == "" or not Bootstrap.captureControllers[id] then return false end
    Bootstrap.captureControllers[id] = nil
    return true
end

local function notifyCaptureControllers(config)
    local applied, failed = {}, {}
    for id, callback in pairs(Bootstrap.captureControllers) do
        local ok, value = pcall(callback, config)
        if ok and value ~= false then applied[#applied + 1] = id else failed[#failed + 1] = id end
    end
    table.sort(applied)
    table.sort(failed)
    Bootstrap.lastControllersApplied = applied
    Bootstrap.lastControllersFailed = failed
    return applied, failed
end

function Bootstrap.StartRole(role)
    role = tostring(role or "")
    if not Bootstrap.IsEnabled() then
        return false, "disabled"
    end
    if Bootstrap.activeRoles[role] then
        return true
    end
    local starter = Bootstrap.roleStarters[role]
    if type(starter) ~= "function" then
        return false, "not_registered"
    end
    local ok, started = pcall(starter)
    if not ok then
        print("[PsychopatzProfiler][WARN] role_start_failed role="
            .. role .. " error=" .. tostring(started))
        return false, tostring(started)
    end
    if started == false then
        return false, "starter_rejected"
    end
    Bootstrap.activeRoles[role] = true
    return true
end

function Bootstrap.RegisterRoleStarter(role, callback)
    role = tostring(role or "")
    if role == "" or type(callback) ~= "function" then
        return false, "invalid_starter"
    end
    if Bootstrap.roleStarters[role] then
        return false, "already_registered"
    end
    Bootstrap.roleStarters[role] = callback
    if Bootstrap.IsEnabled() then
        return Bootstrap.StartRole(role)
    end
    return true
end

local function startRegisteredRoles()
    local failed = {}
    local index
    local role
    local started
    local reason
    for index = 1, #ROLE_ORDER do
        role = ROLE_ORDER[index]
        if Bootstrap.roleStarters[role] then
            started, reason = Bootstrap.StartRole(role)
            if not started then
                failed[#failed + 1] = role .. ":" .. tostring(reason)
            end
        end
    end
    return #failed == 0, failed
end

function Bootstrap.Enable(mode)
    mode = normalizeMode(mode)
    if mode == Bootstrap.MODE_OFF then return Bootstrap.Disable() end

    Bootstrap.mode = mode
    if not Bootstrap.captureConfig or Bootstrap.captureConfig.mode ~= mode then
        Bootstrap.captureConfig = buildConfig({ mode = mode, capture = "performance" })
    end
    local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
    if type(Profiler) ~= "table" or type(Profiler.Start) ~= "function" then
        Bootstrap.mode = Bootstrap.MODE_OFF
        return nil, "restart_required"
    end
    local Adapter = require "PsychopatzCore/Profiler/PsychopatzProfilerPZAdapter"
    if Profiler.IsRunning and Profiler.IsRunning() then Profiler.Stop() end
    local config = Bootstrap.GetCaptureConfig()
    Profiler.Start(mode, Adapter, {
        sampleIntervalMs = config.performanceIntervalMs,
        capture = config.enabled,
        runtime = Bootstrap.GetRuntimeMetadata(),
    })
    startRegisteredRoles()
    local client = rawget(PsychopatzCore, "ProfilerClient")
    if client and client.SetCaptureActive then client.SetCaptureActive(true) end
    notifyCaptureControllers(config)
    print("[PsychopatzProfiler] runtime=" .. runtimeID()
        .. " config=" .. config.fingerprint)
    return Profiler
end

function Bootstrap.Disable()
    local profiler = rawget(PsychopatzCore, "Profiler")
    if profiler and profiler.Stop then profiler.Stop() end
    local client = rawget(PsychopatzCore, "ProfilerClient")
    if client and client.SetCaptureActive then client.SetCaptureActive(false) end
    if client and client.ClearServerSnapshot then client.ClearServerSnapshot() end
    local server = rawget(PsychopatzCore, "ProfilerServer")
    if server and server.Stop then server.Stop() end
    Bootstrap.activeRoles = {}
    Bootstrap.mode = Bootstrap.MODE_OFF
    return true
end

function Bootstrap.ApplyCaptureConfig(arguments)
    if type(arguments) ~= "table" then return nil, "configuration must be an object" end
    local mode = normalizeMode(arguments.mode)
    local capture = arguments.capture
    if type(capture) == "table" then capture = table.concat(capture, ",") end
    local values = {
        mode = mode, capture = capture or "performance",
        performance_interval_ms = arguments.performance_interval_ms,
        moddata_interval_ms = arguments.moddata_interval_ms,
        npc_interval_ms = arguments.npc_interval_ms,
        npc_scope = arguments.npc_scope, npc_ids = arguments.npc_ids,
    }
    if type(values.npc_ids) == "table" then values.npc_ids = table.concat(values.npc_ids, ",") end
    local config = buildConfig(values)
    Bootstrap.captureConfig, Bootstrap.mode = config, config.mode
    if config.mode == Bootstrap.MODE_OFF then
        Bootstrap.Disable()
        notifyCaptureControllers(config)
    else
        local profiler, reason = Bootstrap.Enable(config.mode)
        if not profiler then return nil, reason or "profiler could not start" end
    end
    local applied = Bootstrap.lastControllersApplied or {}
    local failed = Bootstrap.lastControllersFailed or {}
    return { applied = #failed == 0, restart_required = #failed > 0,
        runtime_id = runtimeID(), config_fingerprint = config.fingerprint,
        capture = { performance = config.enabled.performance == true,
            moddata = config.enabled.moddata == true, npc = config.enabled.npc == true },
        controllers_applied = applied, controllers_failed = failed }
end

function Bootstrap.Initialize()
    if Bootstrap.initialized then return Bootstrap.IsEnabled() end
    Bootstrap.initialized = true
    local config = readConfiguredConfig()
    Bootstrap.captureConfig = config
    Bootstrap.mode = config.mode
    if config.mode ~= Bootstrap.MODE_OFF then Bootstrap.Enable(config.mode) end
    return Bootstrap.IsEnabled()
end

Bootstrap.NormalizeMode = normalizeMode
Bootstrap.BuildConfig = buildConfig
Bootstrap.ReadConfiguredConfig = readConfiguredConfig
Bootstrap.ReadConfiguredMode = function() return readConfiguredConfig().mode end
Bootstrap.StartRegisteredRoles = startRegisteredRoles

return Bootstrap
