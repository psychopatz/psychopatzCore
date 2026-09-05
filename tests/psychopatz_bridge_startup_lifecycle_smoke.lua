local function equal(actual, expected, message)
    if actual ~= expected then error((message or "mismatch") .. ": expected="
        .. tostring(expected) .. " actual=" .. tostring(actual)) end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua", package.path,
}, ";")

local tickCallback
local gameStartCallback
Events = {
    OnTick = { Add = function(callback) tickCallback = callback end,
        Remove = function(callback)
            if tickCallback == callback then tickCallback = nil end
        end },
    OnGameStart = { Add = function(callback) gameStartCallback = callback end,
        Remove = function(callback)
            if gameStartCallback == callback then gameStartCallback = nil end
        end },
    OnGameExit = { Add = function() end, Remove = function() end },
}
getTimeInMillis = function() return 1000 end
PsychopatzCore = {}

local transport = {
    SLOT_COUNT = 16,
    runtime = nil,
    requests = {},
    responses = {},
}
transport.ReadRequest = function(slot)
        local request = transport.requests[slot]
        transport.requests[slot] = nil
        return request
    end
transport.WriteResponse = function(slot, response)
        transport.responses[slot] = response
        return true
    end
transport.WriteRuntime = function(runtime)
        transport.runtime = runtime
        return true
    end

local Bridge = require "PsychopatzCore/Bridge/PsychopatzBridge"
equal(Bridge.Initialize({
    runtimeID = "startup-runtime", configFingerprint = "test",
    pollIntervalMs = 250, transport = transport, authority = "multiplayer_client",
}), true, "bridge init")
equal(Bridge.lifecycle, "STARTING", "bridge did not gate startup")
equal(transport.runtime.lifecycle, "STARTING", "startup runtime was advertised ready")
equal(type(gameStartCallback), "function", "game-start readiness hook missing")

transport.requests[0] = {
    message_type = "request", protocol_version = 1, request_id = "before-start",
    namespace = "psychopatzcore.bridge", command = "ping", arguments = {},
}
equal(Bridge.ProcessPendingRequests(), 0, "startup processed an external request")
equal(transport.responses[0], nil, "startup wrote an external response")

gameStartCallback()
equal(Bridge.lifecycle, "READY", "game start did not ready the bridge")
equal(transport.runtime.lifecycle, "READY", "ready runtime was not published")

transport.requests[0] = {
    message_type = "request", protocol_version = 1, request_id = "after-start",
    namespace = "psychopatzcore.bridge", command = "ping", arguments = {},
}
equal(Bridge.ProcessPendingRequests(), 1, "ready bridge did not process a request")
equal(transport.responses[0].status, "ok", "ready bridge ping failed")

Bridge.Shutdown()
equal(gameStartCallback, nil, "game-start readiness hook was not removed")
equal(tickCallback, nil, "tick hook was not removed")
print("psychopatz bridge startup lifecycle: ok")
