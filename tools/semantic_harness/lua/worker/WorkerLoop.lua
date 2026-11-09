-- Provider-neutral JSON-lines worker lifecycle.

local WorkerLoop = {}

function WorkerLoop.run(Protocol, dispatch, options)
    options = type(options) == "table" and options or {}
    local hello = options.hello
    if type(hello) ~= "function" then
        error("worker loop requires a hello callback")
    end
    if type(dispatch) ~= "function" then
        error("worker loop requires a dispatch callback")
    end
    local lineIterator = options.lineIterator or io.lines

    Protocol.emit(hello(), "__hello__")
    for line in lineIterator() do
        local request, reason = Protocol.readRequest(line)
        if not request then
            io.stderr:write("protocol error: " .. tostring(reason) .. "\n")
            break
        end
        local response, failure, shouldQuit = dispatch(request)
        if failure then
            Protocol.fail(request.id, failure)
        elseif response then
            Protocol.emit(response, request.id)
        end
        if shouldQuit then break end
    end
end

return WorkerLoop
