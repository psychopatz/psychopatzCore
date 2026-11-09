local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local Evidence = require "worker/TransportEvidence"

assert(Evidence.configure({ factCommand = "CoreFact" }),
    "fact command configuration failed")
local dispatches, facts = Evidence.partition({
    { command = "CoreFact", id = 1 },
    { command = "UnknownCommand", id = 2 },
})
assert(#facts == 1 and facts[1].id == 1,
    "configured fact command was not partitioned")
assert(#dispatches == 1 and dispatches[1].id == 2,
    "unknown command was not retained as dispatch evidence")

assert(Evidence.configure({
    isFactCommand = function(command, event)
        return command == "CallbackFact" and event.kind == "fact"
    end,
}), "fact classifier configuration failed")
dispatches, facts = Evidence.partition({
    { command = "CallbackFact", kind = "fact" },
    { command = "CallbackFact", kind = "dispatch" },
})
assert(#facts == 1 and #dispatches == 1,
    "provider fact classifier was not applied")

print("psychopatz semantic harness transport: ok")
