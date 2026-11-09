local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local Protocol = require "Protocol"

local function assertEqual(actual, expected, message)
    assert(actual == expected,
        message .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

assertEqual(Protocol.VERSION, 1, "protocol version")
assertEqual(Protocol.MAX_MESSAGE_BYTES, 1024 * 1024,
    "protocol message bound")

local encoded = Protocol.encode({
    greeting = "Mara",
    nested = { true, 4 },
    explicitNull = Protocol.NULL,
})
assert(string.find(encoded, '"explicitNull":null', 1, true),
    "protocol should encode explicit null")

local decoded = Protocol.decode(encoded)
assertEqual(decoded.greeting, "Mara", "protocol string round trip")
assertEqual(decoded.nested[1], true, "protocol boolean round trip")
assertEqual(decoded.nested[2], 4, "protocol number round trip")
assertEqual(decoded.explicitNull, nil,
    "protocol decode should retain legacy nil null behavior")

local request, reason = Protocol.readRequest(
    '{"protocolVersion":1,"id":"request-1","command":"PING"}'
)
assert(request and reason == nil, "valid protocol request should decode")
assertEqual(request.id, "request-1", "request id")

local invalid, invalidReason = Protocol.readRequest(
    '{"protocolVersion":2,"id":"request-1","command":"PING"}'
)
assertEqual(invalid, nil, "invalid protocol version should reject")
assertEqual(invalidReason, "unsupported_protocol_version",
    "invalid protocol version reason")

print("psychopatz semantic harness protocol: ok")
