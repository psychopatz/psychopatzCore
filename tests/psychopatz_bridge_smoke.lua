local function equal(actual, expected, message)
    if actual ~= expected then error((message or "mismatch") .. ": expected="
        .. tostring(expected) .. " actual=" .. tostring(actual)) end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua", package.path,
}, ";")

local tickCallback
Events = {
    OnTick = { Add = function(callback) tickCallback = callback end,
        Remove = function(callback) if tickCallback == callback then tickCallback = nil end end },
    OnGameExit = { Add = function() end, Remove = function() end },
}
local now = 1000
getTimeInMillis = function() return now end
PsychopatzCore = {}
local printed = {}
local originalPrint = print
print = function(message) printed[#printed + 1] = tostring(message) end

local Protocol = require "PsychopatzCore/Bridge/PsychopatzBridgeProtocol"
local valid = Protocol.Decode('{"protocol_version":1,"request_id":"request01","namespace":"psychopatzcore.bridge","command":"ping","arguments":{}}')
equal(valid.command, "ping", "valid JSON request")
equal(Protocol.Decode("{"), nil, "malformed JSON accepted")
local ok, code = Protocol.ValidateRequest({ protocol_version = 2, request_id = "request02",
    namespace = "psychopatzcore.bridge", command = "ping", arguments = {} })
equal(ok, nil, "unsupported protocol accepted")
equal(code, "UNSUPPORTED_PROTOCOL", "unsupported protocol code")

local requests, responses = {}, {}
local transport
transport = {
    SLOT_COUNT = 16,
    ReadRequest = function(slot) local request = requests[slot]; requests[slot] = nil; return request end,
    WriteResponse = function(slot, response) responses[slot] = response; return true end,
    WriteRuntime = function(runtime) transport.runtime = runtime; return true end,
}
local Bridge = require "PsychopatzCore/Bridge/PsychopatzBridge"
equal(Bridge.Initialize({ runtimeID = "runtime-new", configFingerprint = "v1|true|file|250",
    pollIntervalMs = 250, transport = transport, authority = "server" }), true, "bridge init")
equal(type(tickCallback), "function", "enabled bridge did not register tick")
equal(transport.runtime.lifecycle, "READY", "runtime state")

requests[0] = { message_type = "request", protocol_version = 1, request_id = "request03",
    namespace = "psychopatzcore.bridge", command = "ping",
    arguments = { console_marker = "desktop-test-42" } }
Bridge.ProcessPendingRequests()
equal(responses[0].status, "ok", "ping failed")
equal(responses[0].result.runtime_id, "runtime-new", "ping runtime")
equal(responses[0].result.console_marker, "desktop-test-42", "ping marker response")
equal(string.find(printed[#printed], "external_ping marker=desktop%-test%-42") ~= nil,
    true, "ping did not write console confirmation")
local printCount = #printed
requests[0] = { message_type = "request", protocol_version = 1, request_id = "request03",
    namespace = "psychopatzcore.bridge", command = "ping",
    arguments = { console_marker = "desktop-test-42" } }
Bridge.ProcessPendingRequests()
equal(#printed, printCount, "duplicate request executed ping twice")
equal(responses[0].result.console_marker, "desktop-test-42", "cached response missing")

requests[1] = { message_type = "request", protocol_version = 1, request_id = "request04",
    target_runtime_id = "runtime-old", namespace = "psychopatzcore.bridge",
    command = "ping", arguments = {} }
Bridge.ProcessPendingRequests()
equal(responses[1].error.code, "STALE_RUNTIME", "stale runtime executed")

requests[2] = { message_type = "request", protocol_version = 1, request_id = "request05",
    target_runtime_id = "runtime-new", namespace = "future.mod",
    command = "missing", arguments = {} }
Bridge.ProcessPendingRequests()
equal(responses[2].error.code, "UNKNOWN_NAMESPACE", "unknown namespace response")

local registered = Bridge.RegisterCommand("example.debug", "inspect", {
    readOnly = true, handler = function(_, arguments) return { value = arguments.value } end,
})
equal(registered, true, "command registration")
equal(Bridge.RegisterCommand("example.debug", "inspect", { handler = function() end }), false,
    "duplicate command replaced")
requests[3] = { message_type = "request", protocol_version = 1, request_id = "request06",
    target_runtime_id = "runtime-new", namespace = "example.debug",
    command = "inspect", arguments = { value = 42 } }
Bridge.ProcessPendingRequests()
equal(responses[3].result.value, 42, "registered handler")
equal(Bridge.GetCapabilities()["example.debug"].commands[1].name, "inspect", "capability discovery")

local toolRegistered = Bridge.RegisterTool("example.debug", "inspect_tool", {
    type = "function", ["function"] = {
        name = "inspect_tool", description = "Inspect a debug value.",
        parameters = { type = "object", properties = {}, additionalProperties = false },
    },
})
equal(toolRegistered, true, "tool registration")
local catalog = Bridge.GetToolCatalog()
equal(catalog.catalog_version, 1, "tool catalog revision")
equal(catalog.tools[1].id, "example.debug:inspect_tool", "tool catalog entry")
equal(transport.runtime.tool_catalog_id, catalog.catalog_id, "runtime catalog fingerprint")

requests[4] = { message_type = "request", protocol_version = 1, request_id = "request07",
    target_runtime_id = "runtime-new", namespace = "psychopatzcore.bridge",
    command = "toolCatalog", arguments = {} }
Bridge.ProcessPendingRequests()
equal(responses[4].result.catalog_id, catalog.catalog_id, "tool catalog command")

equal(Bridge.RegisterPacketChannel("example.debug", "events", { maxEvents = 2 }), true,
    "packet channel registration")
local snapshotOK, snapshotRevision = Bridge.SetPacketSnapshot(
    "example.debug", "events", { active = true }, 7
)
equal(snapshotOK, true, "packet snapshot")
equal(snapshotRevision, 7, "packet snapshot revision")
Bridge.PublishPacket("example.debug", "events", { packet_type = "first" })
Bridge.PublishPacket("example.debug", "events", { packet_type = "second" })
Bridge.PublishPacket("example.debug", "events", { packet_type = "third" })
requests[5] = { message_type = "request", protocol_version = 1, request_id = "request08",
    target_runtime_id = "runtime-new", namespace = "psychopatzcore.bridge",
    command = "pollPackets", arguments = {
        subscriptions = { {
            namespace = "example.debug", channel = "events", after = 0,
            include_snapshot = true,
        } },
    } }
Bridge.ProcessPendingRequests()
local stream = responses[5].result.streams[1]
equal(stream.gap, true, "packet stream gap detection")
equal(#stream.events, 2, "packet stream bounded retention")
equal(stream.snapshot.active, true, "packet stream snapshot")
Bridge.Shutdown()
equal(tickCallback, nil, "shutdown callback retained")

print = originalPrint
print("psychopatz bridge smoke: ok")
