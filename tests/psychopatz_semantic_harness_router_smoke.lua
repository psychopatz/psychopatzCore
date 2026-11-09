local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local Router = require "worker/Router"

local annotated = 0
local handlers = {
    {
        handle = function(_, command)
            if command ~= "FIRST" then return false end
            return false
        end,
    },
    {
        handle = function(_, command, payload)
            if command ~= "SECOND" then return false end
            return {
                ok = true,
                payload = payload,
                transport = { { command = "Fact" } },
            }, nil, true
        end,
    },
}

local evidence = {
    annotate = function(response)
        annotated = annotated + 1
        response.transport[1].annotated = true
    end,
}

local result, failure, shouldQuit = Router.dispatch(
    handlers,
    {},
    { command = "SECOND", payload = { value = 7 } },
    evidence
)
assert(result.ok == true and result.payload.value == 7,
    "router did not return the matching handler result")
assert(shouldQuit == true and failure == nil,
    "router did not preserve handler control results")
assert(annotated == 1 and result.transport[1].annotated == true,
    "router did not annotate transport through the supplied seam")

local unknown, reason = Router.dispatch(handlers, {}, {
    command = "MISSING",
}, evidence)
assert(unknown == nil and reason == "unknown_command:MISSING",
    "router unknown-command failure is not canonical")

print("psychopatz semantic harness router: ok")
