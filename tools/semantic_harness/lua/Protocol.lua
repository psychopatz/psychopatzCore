-- Bounded JSON-lines protocol for the Core semantic harness worker.
--
-- The JSON codec is Core-owned. This worker protocol only adds the request
-- envelope, response correlation, and message-size boundary.

local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local Protocol = {
    VERSION = 1,
    MAX_MESSAGE_BYTES = 1024 * 1024,
}
-- Keep the explicit null marker available to provider harness adapters. The
-- Core JSON codec recognizes it both at the root and inside nested records.
Protocol.NULL = Json.NULL

local JSON_LIMITS = {
    maxString = Protocol.MAX_MESSAGE_BYTES,
    maxDepth = 32,
    maxCollection = 4096,
}

local function encoded(value)
    return Json.Encode(value, JSON_LIMITS)
end

function Protocol.encode(value)
    return encoded(value)
end

function Protocol.decode(source)
    return Json.Decode(source, JSON_LIMITS)
end

function Protocol.emit(value, requestID)
    if type(value) ~= "table" then value = { value = value } end
    value.protocolVersion = Protocol.VERSION
    if requestID then value.id = requestID end
    io.write(encoded(value) .. "\n")
    io.flush()
end

function Protocol.fail(requestID, reason)
    Protocol.emit({
        ok = false,
        error = tostring(reason or "worker_error"),
    }, requestID)
end

function Protocol.readRequest(source)
    if type(source) ~= "string" then
        return nil, "request_text_required"
    end
    if #source > Protocol.MAX_MESSAGE_BYTES then
        return nil, "request_too_large"
    end
    local request, reason = Json.Decode(source, JSON_LIMITS)
    if type(request) ~= "table" then
        return nil, reason or "invalid_request"
    end
    if request.protocolVersion ~= Protocol.VERSION then
        return nil, "unsupported_protocol_version"
    end
    if type(request.id) ~= "string" or request.id == "" then
        return nil, "request_id_required"
    end
    if type(request.command) ~= "string" or request.command == "" then
        return nil, "request_command_required"
    end
    return request
end

return Protocol
