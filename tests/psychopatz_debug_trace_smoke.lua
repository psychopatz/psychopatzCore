local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local timestamp = 100
getTimeInMillis = function() return timestamp end

local Trace = require "PsychopatzCore/Debug/PsychopatzDebugTrace"
assert(Trace.IsEnabled() == false, "trace capture was enabled by default")
assert(Trace.Record({
    source = "test", event = "disabled", data = { secret = "not copied" },
}) == false, "disabled trace did work")
assert(#Trace.GetEntries() == 0, "disabled trace retained an entry")

Trace.SetEnabled(true)
assert(Trace.Record({
    source = "test", event = "enabled", requestID = "request-1",
    data = { nested = { value = "visible" } },
}) == true, "enabled trace was rejected")
assert(#Trace.GetEntries() == 1, "enabled trace was not retained")
assert(Trace.GetEntries()[1].data.nested.value == "visible",
    "trace payload was not copied")

Trace.SetMaxEntries(2)
Trace.Record({ source = "test", event = "second", data = {} })
Trace.Record({ source = "test", event = "third", data = {} })
assert(#Trace.GetEntries() == 2, "trace ring buffer exceeded its limit")
assert(Trace.GetEntries()[1].event == "second", "oldest trace was not evicted")

Trace.SetEnabled(false)
assert(#Trace.GetEntries() == 0, "disabling trace did not clear retained payloads")
print("psychopatz_debug_trace_smoke: ok")
