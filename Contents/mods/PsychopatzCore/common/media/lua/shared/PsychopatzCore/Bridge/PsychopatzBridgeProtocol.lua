local Protocol = {}
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"

Protocol.VERSION = 1
Protocol.MAX_REQUEST_BYTES = 32768
Protocol.MAX_RESPONSE_BYTES = 65536
Protocol.MAX_STRING = 4096
-- A bridge response wraps conversation_context -> available_tools -> each
-- function declaration -> parameters -> properties -> property metadata.
-- Eight levels truncated the innermost `type` values into `[depth-limit]`,
-- which made Gemini report an unsupported tool schema. Keep this bounded but
-- deep enough for the published conversation tool contract.
Protocol.MAX_DEPTH = 12
Protocol.MAX_COLLECTION = 128
Protocol.ERRORS = {
    INVALID_REQUEST = true, UNSUPPORTED_PROTOCOL = true,
    UNKNOWN_NAMESPACE = true, UNKNOWN_COMMAND = true,
    INVALID_ARGUMENTS = true, NOT_AVAILABLE = true,
    NOT_AUTHORIZED = true, BUSY = true, TIMEOUT = true,
    INTERNAL_ERROR = true, STALE_RUNTIME = true,
}

local function limits()
    return { maxString = Protocol.MAX_STRING, maxDepth = Protocol.MAX_DEPTH,
        maxCollection = Protocol.MAX_COLLECTION }
end

function Protocol.Encode(value)
    local encoded = Json.Encode(value, limits())
    if #encoded > Protocol.MAX_RESPONSE_BYTES then return nil, "response size limit" end
    return encoded
end

function Protocol.Decode(text)
    if type(text) ~= "string" or #text > Protocol.MAX_REQUEST_BYTES then
        return nil, "request size limit"
    end
    local value, reason = Json.Decode(text, limits())
    if type(value) ~= "table" then return nil, reason or "malformed JSON" end
    return value
end

local function identifier(value, dotted)
    if type(value) ~= "string" or #value == 0 or #value > 96 then return false end
    if not dotted then return string.match(value, "^[%w_%-]+$") ~= nil end
    if string.sub(value, 1, 1) == "." or string.sub(value, -1) == "."
        or string.find(value, "..", 1, true) then return false end
    for part in string.gmatch(value, "[^.]+") do
        if not string.match(part, "^[%w_%-]+$") then return false end
    end
    return true
end

function Protocol.ValidateRequest(request)
    if type(request) ~= "table" then return nil, "INVALID_REQUEST", "Request must be an object." end
    if request.protocol_version ~= Protocol.VERSION then
        return nil, "UNSUPPORTED_PROTOCOL", "Protocol version is not supported."
    end
    if request.message_type ~= nil and request.message_type ~= "request" then
        return nil, "INVALID_REQUEST", "Message type must be request."
    end
    if not identifier(request.request_id, false) or #request.request_id < 8 or #request.request_id > 64 then
        return nil, "INVALID_REQUEST", "Request ID is invalid."
    end
    if not identifier(request.namespace, true) then return nil, "INVALID_REQUEST", "Namespace is invalid." end
    if not identifier(request.command, false) then return nil, "INVALID_REQUEST", "Command is invalid." end
    if type(request.arguments) ~= "table" then return nil, "INVALID_ARGUMENTS", "Arguments must be an object." end
    for key, _ in pairs(request.arguments) do
        if type(key) ~= "string" then return nil, "INVALID_ARGUMENTS", "Arguments must be an object." end
    end
    if request.created_at ~= nil and (type(request.created_at) ~= "number" or request.created_at < 0) then
        return nil, "INVALID_REQUEST", "Creation timestamp is invalid."
    end
    if request.target_runtime_id ~= nil and (type(request.target_runtime_id) ~= "string"
        or #request.target_runtime_id == 0 or #request.target_runtime_id > 128)
    then return nil, "INVALID_REQUEST", "Target runtime ID is invalid." end
    return true
end

function Protocol.Response(requestID, runtimeID, result)
    return { message_type = "response", protocol_version = Protocol.VERSION,
        request_id = requestID, runtime_id = runtimeID, status = "ok", request_state = "COMPLETE",
        result = result or {}, error = nil }
end

function Protocol.Error(requestID, runtimeID, code, message)
    if not Protocol.ERRORS[code] then code = "INTERNAL_ERROR" end
    return { message_type = "response", protocol_version = Protocol.VERSION,
        request_id = requestID or "invalid00", runtime_id = runtimeID,
        status = "error", request_state = "ERROR", result = nil,
        error = { code = code, message = tostring(message or "Request failed.") } }
end

return Protocol
