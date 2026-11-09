-- Provider-neutral command-handler dispatch for semantic worker adapters.

local Router = {}

function Router.dispatch(handlers, context, request, transportEvidence)
    local command = request and request.command
    local payload = request and request.payload
    for index = 1, #(handlers or {}) do
        local handler = handlers[index]
        local result, failure, shouldQuit = handler.handle(
            context,
            command,
            payload
        )
        if result ~= false then
            if transportEvidence
                and type(transportEvidence.annotate) == "function"
                and type(result) == "table"
                and type(result.transport) == "table"
            then
                transportEvidence.annotate(result)
            end
            return result, failure, shouldQuit
        end
    end
    return nil, "unknown_command:" .. tostring(command)
end

return Router
