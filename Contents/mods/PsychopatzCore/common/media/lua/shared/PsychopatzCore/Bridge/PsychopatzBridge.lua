PsychopatzCore = PsychopatzCore or {}
local Bridge = PsychopatzCore.Bridge or {}
PsychopatzCore.Bridge = Bridge

local Protocol = require "PsychopatzCore/Bridge/PsychopatzBridgeProtocol"
local Registry = require "PsychopatzCore/Bridge/PsychopatzBridgeRegistry"

Bridge.PROTOCOL_VERSION = Protocol.VERSION
Bridge.lifecycle = Bridge.lifecycle or "UNLOADED"
local MAX_RESPONSE_CACHE = 64

local function nowMs()
    return getTimeInMillis and getTimeInMillis() or 0
end

function Bridge.GetRuntimeInfo()
    local state = Bridge.state
    if not state then return { lifecycle = Bridge.lifecycle, enabled = false } end
    return {
        message_type = "runtime", protocol_version = Protocol.VERSION,
        runtime_id = state.runtimeID, startup_timestamp = state.startedAt,
        lifecycle = Bridge.lifecycle, enabled = Bridge.lifecycle == "READY",
        transport = "file", config_fingerprint = state.configFingerprint,
        authority = state.authority, namespaces = Registry.Capabilities(),
    }
end

function Bridge.GetCapabilities()
    return Registry.Capabilities()
end

function Bridge.RegisterCommand(namespace, command, options)
    if Bridge.lifecycle == "UNLOADED" then return false, "bridge_disabled" end
    return Registry.Register(namespace, command, options)
end

function Bridge.UnregisterNamespace(namespace)
    return Registry.UnregisterNamespace(namespace)
end

function Bridge.RefreshRuntimeState()
    if Bridge.state and Bridge.state.transport then
        return Bridge.state.transport.WriteRuntime(Bridge.GetRuntimeInfo())
    end
    return false
end

local function dispatch(request)
    local state = Bridge.state
    local valid, code, message = Protocol.ValidateRequest(request)
    if not valid then return Protocol.Error(request and request.request_id, state.runtimeID, code, message) end
    if request.target_runtime_id ~= nil and request.target_runtime_id ~= state.runtimeID then
        return Protocol.Error(request.request_id, state.runtimeID, "STALE_RUNTIME",
            "Request targets a different Project Zomboid runtime.")
    end
    local infrastructure = request.namespace == "psychopatzcore.bridge"
    if not infrastructure and request.target_runtime_id == nil then
        return Protocol.Error(request.request_id, state.runtimeID, "NOT_AUTHORIZED",
            "A current target runtime ID is required.")
    end
    local command, resolveError = Registry.Resolve(request.namespace, request.command)
    if not command then
        return Protocol.Error(request.request_id, state.runtimeID, resolveError,
            resolveError == "UNKNOWN_NAMESPACE" and "Namespace is not registered."
                or "Command is not registered.")
    end
    local context = { runtimeID = state.runtimeID, authority = state.authority,
        readOnly = command.readOnly, category = command.category }
    local ok, result, handlerCode, handlerMessage = pcall(command.handler, context, request.arguments)
    if not ok then
        return Protocol.Error(request.request_id, state.runtimeID, "INTERNAL_ERROR",
            "Registered command failed safely.")
    end
    if result == nil then
        return Protocol.Error(request.request_id, state.runtimeID,
            Protocol.ERRORS[handlerCode] and handlerCode or "INTERNAL_ERROR",
            handlerMessage or "Command could not be completed.")
    end
    return Protocol.Response(request.request_id, state.runtimeID, result)
end

function Bridge.ProcessPendingRequests()
    local state = Bridge.state
    if Bridge.lifecycle ~= "READY" or not state then return 0 end
    local processed = 0
    for offset = 0, state.slotCount - 1 do
        if processed >= state.maxPerCycle then break end
        local slot = (state.nextSlot + offset) % state.slotCount
        local request, readError = state.transport.ReadRequest(slot)
        if request then
            local requestID = tostring(request.request_id or "")
            local response = state.responseByRequestID[requestID]
            if not response then
                if readError then
                    response = Protocol.Error(request.request_id, state.runtimeID,
                        "INVALID_REQUEST", "Request JSON is malformed or exceeds limits.")
                else
                    response = dispatch(request)
                end
                state.responseByRequestID[requestID] = response
                state.responseOrder[#state.responseOrder + 1] = requestID
                if #state.responseOrder > MAX_RESPONSE_CACHE then
                    local expired = table.remove(state.responseOrder, 1)
                    state.responseByRequestID[expired] = nil
                end
            end
            state.transport.WriteResponse(slot, response)
            processed = processed + 1
            state.nextSlot = (slot + 1) % state.slotCount
        end
    end
    return processed
end

local function onTick()
    local state = Bridge.state
    if not state then return end
    local now = nowMs()
    if now - state.lastPollAt < state.pollIntervalMs then return end
    state.lastPollAt = now
    Bridge.ProcessPendingRequests()
end

local function registerBuiltins()
    Registry.Register("psychopatzcore.bridge", "ping", { readOnly = true, handler = function(_, arguments)
        local marker = tostring(arguments and arguments.console_marker or "desktop")
        marker = string.gsub(marker, "[^%w_%-%.:]", "_")
        if #marker > 96 then marker = string.sub(marker, 1, 96) end
        print("[PsychopatzBridge] external_ping marker=" .. marker
            .. " runtime=" .. tostring(Bridge.state.runtimeID))
        return { alive = true, runtime_id = Bridge.state.runtimeID,
            protocol_version = Protocol.VERSION, lifecycle = Bridge.lifecycle,
            console_marker = marker, console_logged = true }
    end })
    Registry.Register("psychopatzcore.bridge", "capabilities", { readOnly = true, handler = function()
        return { runtime_id = Bridge.state.runtimeID, protocol_version = Protocol.VERSION,
            namespaces = Registry.Capabilities() }
    end })
    Registry.Register("psychopatzcore.bridge", "runtimeInfo", { readOnly = true, handler = function()
        return Bridge.GetRuntimeInfo()
    end })
end

function Bridge.Initialize(options)
    if Bridge.lifecycle ~= "UNLOADED" then return false end
    Bridge.lifecycle = "INITIALIZING"
    Bridge.state = {
        runtimeID = assert(options.runtimeID), startedAt = options.startedAt or nowMs(),
        configFingerprint = options.configFingerprint, pollIntervalMs = options.pollIntervalMs or 250,
        transport = assert(options.transport), authority = options.authority or "server",
        slotCount = math.min(options.slotCount or 16, 16), maxPerCycle = math.min(options.maxPerCycle or 4, 4),
        nextSlot = 0, lastPollAt = 0, responseByRequestID = {}, responseOrder = {},
    }
    Registry.namespaces = {}
    Registry.onChanged = Bridge.RefreshRuntimeState
    registerBuiltins()
    Bridge.lifecycle = "READY"
    Bridge.RefreshRuntimeState()
    if Events and Events.OnTick and Events.OnTick.Add then Events.OnTick.Add(onTick) end
    if Events and Events.OnGameExit and Events.OnGameExit.Add then Events.OnGameExit.Add(Bridge.Shutdown) end
    return true
end

function Bridge.Shutdown()
    if Bridge.lifecycle == "UNLOADED" then return false end
    Bridge.lifecycle = "SHUTTING_DOWN"
    if Events and Events.OnTick and Events.OnTick.Remove then Events.OnTick.Remove(onTick) end
    if Events and Events.OnGameExit and Events.OnGameExit.Remove then Events.OnGameExit.Remove(Bridge.Shutdown) end
    Registry.onChanged = nil
    Bridge.state = nil
    Bridge.lifecycle = "UNLOADED"
    return true
end

return Bridge
