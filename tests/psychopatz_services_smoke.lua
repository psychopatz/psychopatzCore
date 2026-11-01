-- Smoke test for P6 Domain Capsule Refinement and Services Lookup Facade

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

-- PZ mock globals
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

assert(Core.Services ~= nil, "Services facade missing on Core")
assert(Core.Features ~= nil, "Features facade missing on Core")

-- 1. Check initial state
assert(Core.Services.Has("inventory") == false, "inventory should not be active initially")
assert(Core.Services.Has("currency") == false, "currency should not be active initially")

-- 2. Retrieve Inventory service
local inv, err = Core.Services.Get("inventory", "ServicesSmokeTest")
assert(inv ~= nil, "Failed to get inventory service: " .. tostring(err))
assert(type(inv.encodeItem) == "function", "inv.encodeItem missing")
assert(inv.Constants ~= nil, "inv.Constants missing on facade")
assert(Core.Services.Has("inventory") == true, "inventory should now be active")

-- 3. Retrieve Currency service
local curr, currErr = Core.Services.Get("currency", "ServicesSmokeTest")
assert(curr ~= nil, "Failed to get currency service: " .. tostring(currErr))
assert(type(curr.IsType) == "function", "curr.IsType missing")
assert(Core.Services.Has("currency") == true, "currency should now be active")

-- 4. Check ListActive
local activeList = Core.Services.ListActive()
assert(#activeList >= 2, "expected at least 2 active services")

-- 5. Features alias check
assert(Core.Features.Require == Core.Capabilities.Require, "Features.Require must alias Capabilities.Require")

print("psychopatz services smoke: ok")
