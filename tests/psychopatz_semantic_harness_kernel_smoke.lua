local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local RuntimeState = require "worker/RuntimeState"
local Values = require "worker/Values"

local runtime = RuntimeState.new()
assert(type(runtime.extensions) == "table", "runtime extension bucket missing")
runtime.extensions.provider = { mode = "abstract" }
assert(runtime.extensions.provider.mode == "abstract",
    "provider extension state was not preserved")

runtime.transcript = { 1, 2, 3 }
runtime.queued = { 1, 2 }
runtime.trace = { 1, 2 }
runtime.transport = { 1, 2 }
runtime.translationLookups = { 1, 2 }
runtime.now = 9000
runtime.turn = 9
RuntimeState.resetContainers(runtime)
assert(#runtime.transcript == 0, "runtime transcript was not reset")
assert(runtime.now == 1000 and runtime.turn == 0,
    "runtime clock was not reset")

local source = { nested = { value = 3 } }
local bounded = Values.copy(source)
bounded.nested.value = 4
assert(source.nested.value == 3, "bounded copy aliased source state")
assert(Values.number("4", 0) == 4, "number normalization failed")
assert(Values.safeString(nil, "fallback") == "fallback",
    "safe string fallback failed")

print("psychopatz semantic harness kernel: ok")
