local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local WorkerLoop = require "worker/WorkerLoop"

local emitted = {}
local requests = { "PING", "QUIT" }
local index = 0
local Protocol = {
    emit = function(value, requestID)
        emitted[#emitted + 1] = { value = value, id = requestID }
    end,
    fail = function(requestID, reason)
        emitted[#emitted + 1] = {
            value = { ok = false, error = reason },
            id = requestID,
        }
    end,
    readRequest = function(line)
        if line == "PING" then
            return { id = "one", command = "PING" }
        end
        if line == "QUIT" then
            return { id = "two", command = "QUIT" }
        end
        return nil, "bad_request"
    end,
}

local function lineIterator()
    return function()
        index = index + 1
        return requests[index]
    end
end

WorkerLoop.run(
    Protocol,
    function(request)
        if request.command == "PING" then
            return { ok = true, type = "pong" }
        end
        return { ok = true, type = "closed" }, nil, true
    end,
    {
        hello = function()
            return { ok = true, type = "hello" }
        end,
        lineIterator = lineIterator,
    }
)

assert(#emitted == 3, "worker loop emitted the wrong response count")
assert(emitted[1].id == "__hello__"
    and emitted[2].id == "one"
    and emitted[3].id == "two",
    "worker loop did not preserve handshake/request correlation")
assert(emitted[2].value.type == "pong"
    and emitted[3].value.type == "closed",
    "worker loop did not preserve dispatch results")

print("psychopatz semantic harness worker loop: ok")
