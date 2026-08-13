local Protocol = require "PsychopatzCore/Bridge/PsychopatzBridgeProtocol"
local Transport = {}

Transport.SLOT_COUNT = 16
Transport.REQUEST_ROOT = "PsychopatzBridge/requests/"
Transport.RESPONSE_ROOT = "PsychopatzBridge/responses/"
Transport.STATE_ROOT = "PsychopatzBridge/state/"

local function readFile(path, maximum)
    if not getFileReader then return nil end
    local reader = getFileReader(path, false)
    if not reader then return nil end
    local parts, size = {}, 0
    local line = reader:readLine()
    while line do
        size = size + #line + 1
        if size > maximum then reader:close(); return nil, "size_limit" end
        parts[#parts + 1] = line
        line = reader:readLine()
    end
    reader:close()
    return table.concat(parts, "\n")
end

local function writeFile(path, value)
    if not getFileWriter then return false end
    local writer = getFileWriter(path, true, false)
    if not writer then return false end
    writer:write(tostring(value or ""))
    writer:close()
    return true
end

local function slotName(slot)
    return string.format("slot-%02d", slot)
end

function Transport.ReadRequest(slot)
    local name = slotName(slot)
    if readFile(Transport.RESPONSE_ROOT .. name .. ".ready.txt", 32) then return nil end
    local text, reason = readFile(Transport.REQUEST_ROOT .. name .. ".json", Protocol.MAX_REQUEST_BYTES)
    if not text then return nil, reason end
    local request, parseReason = Protocol.Decode(text)
    if not request then return { request_id = "invalid" .. tostring(slot) }, parseReason end
    return request
end

function Transport.WriteResponse(slot, response)
    local encoded, reason = Protocol.Encode(response)
    if not encoded then return false, reason end
    local name = slotName(slot)
    if not writeFile(Transport.RESPONSE_ROOT .. name .. ".json", encoded) then return false, "write_failed" end
    if not writeFile(Transport.RESPONSE_ROOT .. name .. ".ready.txt", response.request_id) then
        return false, "marker_failed"
    end
    return true
end

function Transport.WriteRuntime(runtime)
    local encoded, reason = Protocol.Encode(runtime)
    if not encoded then return false, reason end
    if not writeFile(Transport.STATE_ROOT .. "runtime.json", encoded) then return false, "write_failed" end
    return writeFile(Transport.STATE_ROOT .. "runtime.ready.txt", runtime.runtime_id)
end

return Transport
