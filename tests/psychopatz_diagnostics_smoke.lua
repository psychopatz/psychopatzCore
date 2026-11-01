-- Smoke test for P8 Diagnostics and Mechanical Assertions

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

-- Mock globals
Events = setmetatable({}, {
    __index = function(t, k)
        local h = { Add = function() end, Remove = function() end }
        rawset(t, k, h)
        return h
    end
})
isClient = function() return false end
isServer = function() return false end
getText = function(s) return s end

local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local Kernel = Core.Capabilities
local Diagnostics = Kernel.Diagnostics

assert(Diagnostics ~= nil, "Diagnostics module missing")

-- 1. Report before activation
local report = Kernel.Report()
assert(report["core.inventory"] ~= nil, "core.inventory missing in report")
assert(report["core.traits"] ~= nil, "core.traits missing in report")
assert(report["core.traits"].state == "REGISTERED", "core.traits should be REGISTERED initially")

-- 2. Explain on unrequested capability
local explanationUnrequested = Kernel.Explain("core.traits")
assert(string.find(explanationUnrequested, "REGISTERED", 1, true) ~= nil, "Explain should mention REGISTERED: " .. explanationUnrequested)
assert(string.find(explanationUnrequested, "0 consumers", 1, true) ~= nil, "Explain should mention 0 consumers: " .. explanationUnrequested)

-- 3. AssertRegistered helper
assert(Diagnostics.AssertRegistered("core.zombie_kill_detector") == true, "AssertRegistered should succeed for unrequested capability")

-- 4. Activate capability and inspect explanation & assertion
local ok, facade = Kernel.Require("core.inventory", "DT_SmokeConsumer")
assert(ok == true, "Require core.inventory failed")

local explanationActive = Kernel.Explain("core.inventory")
assert(string.find(explanationActive, "ACTIVE", 1, true) ~= nil, "Explain should report ACTIVE: " .. explanationActive)
assert(string.find(explanationActive, "DT_SmokeConsumer", 1, true) ~= nil, "Explain should mention requesting consumer: " .. explanationActive)

-- 5. AssertActive helper
assert(Diagnostics.AssertActive("core.inventory", "DT_SmokeConsumer") == true, "AssertActive should succeed for active consumer")

print("psychopatz diagnostics smoke: ok")
