-- Smoke test for PsychopatzCore Minimal Kernel (P1 acceptance)

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

local Kernel = require "PsychopatzCore/Kernel/PC_Kernel"
local Registry = Kernel.Registry
local Resolver = Kernel.Resolver
local Lifecycle = Kernel.Lifecycle
local STATES = Kernel.STATES

local function assertEqual(actual, expected, msg)
    if actual ~= expected then
        error((msg or "mismatch") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

-- 1. Kernel Boot Isolation
-- Before InitCatalog, registry is empty
assertEqual(Kernel.catalogInitialized, false, "catalog should not be initialized yet")
Kernel.InitCatalog()
assertEqual(Kernel.catalogInitialized, true, "catalog should now be initialized")

local allStates = Kernel.GetAllStatus()
local registeredCount = 0
for id, state in pairs(allStates) do
    registeredCount = registeredCount + 1
    assertEqual(state.state, STATES.REGISTERED, "capability " .. id .. " should be REGISTERED, not loaded")
    assertEqual(state.totalConsumers, 0, "capability " .. id .. " should have 0 consumers")
end
assert(registeredCount >= 25, "expected at least 25 registered capabilities")

-- 2. Mock Capabilities for strict contract & lifecycle testing
local activated = {}
local deactivated = {}
local loaded = {}

Registry.Register({
    id = "test.base",
    domain = "Test",
    roles = { shared = true },
    load = function()
        table.insert(loaded, "test.base")
        return { name = "BaseModule" }
    end,
    activate = function()
        table.insert(activated, "test.base")
    end,
    deactivate = function()
        table.insert(deactivated, "test.base")
    end,
})

Registry.Register({
    id = "test.dependent",
    domain = "Test",
    roles = { shared = true },
    depends = { "test.base" },
    load = function()
        table.insert(loaded, "test.dependent")
        return { name = "DependentModule" }
    end,
    activate = function()
        table.insert(activated, "test.dependent")
    end,
    deactivate = function()
        table.insert(deactivated, "test.dependent")
    end,
})

-- Before activation, nothing was loaded or activated
assertEqual(#loaded, 0, "no module should be loaded before require")
assertEqual(#activated, 0, "no callback should be activated before require")

-- 3. Demand-driven activation & dependency closure
local ok, facade = Kernel.Require("test.dependent", "ConsumerA")
assertEqual(ok, true, "Require test.dependent failed")

-- Verify topological ordering: test.base loaded and activated BEFORE test.dependent
assertEqual(#loaded, 2, "both base and dependent should be loaded")
assertEqual(loaded[1], "test.base", "base must load before dependent")
assertEqual(loaded[2], "test.dependent", "dependent loads second")

assertEqual(#activated, 2, "both base and dependent should be activated")
assertEqual(activated[1], "test.base", "base must activate before dependent")
assertEqual(activated[2], "test.dependent", "dependent activates second")

local stateDep = Kernel.GetStatus("test.dependent")
assertEqual(stateDep.state, STATES.ACTIVE, "dependent state should be ACTIVE")
assertEqual(stateDep.totalConsumers, 1, "dependent totalConsumers should be 1")

local stateBase = Kernel.GetStatus("test.base")
assertEqual(stateBase.state, STATES.ACTIVE, "base state should be ACTIVE")
assertEqual(stateBase.totalConsumers, 1, "base totalConsumers should be 1")

-- 4. Multi-consumer reference counting
local ok2 = Kernel.Require("test.dependent", "ConsumerB")
assertEqual(ok2, true, "second require should succeed")
assertEqual(Kernel.GetStatus("test.dependent").totalConsumers, 2, "totalConsumers should be 2")

-- Release ConsumerA: should remain ACTIVE because ConsumerB still holds it
Kernel.Release("test.dependent", "ConsumerA")
assertEqual(Kernel.GetStatus("test.dependent").state, STATES.ACTIVE, "should remain ACTIVE with 1 consumer")
assertEqual(Kernel.GetStatus("test.dependent").totalConsumers, 1, "totalConsumers should now be 1")
assertEqual(#deactivated, 0, "deactivate should not run while consumers remain")

-- Release ConsumerB: now reaches 0 consumers -> becomes DORMANT
Kernel.Release("test.dependent", "ConsumerB")
assertEqual(Kernel.GetStatus("test.dependent").state, STATES.DORMANT, "should transition to DORMANT")
assertEqual(Kernel.GetStatus("test.dependent").totalConsumers, 0, "totalConsumers should be 0")
assertEqual(#deactivated, 1, "deactivate should run once on last release")
assertEqual(deactivated[1], "test.dependent", "dependent was deactivated")

-- 5. Cycle Detection
Registry.Register({
    id = "cycle.a",
    roles = { shared = true },
    depends = { "cycle.b" },
})
Registry.Register({
    id = "cycle.b",
    roles = { shared = true },
    depends = { "cycle.c" },
})
Registry.Register({
    id = "cycle.c",
    roles = { shared = true },
    depends = { "cycle.a" },
})

local cycleOk, cycleErr = Resolver.ResolveClosure(Registry, "cycle.a")
assertEqual(cycleOk, nil, "cycle should fail resolution")
assert(string.find(cycleErr, "cycle detected", 1, true) ~= nil, "error should report cycle detected: " .. tostring(cycleErr))

-- 6. Role Eligibility Enforcement
Registry.Register({
    id = "role.server_only",
    roles = { server = true },
    load = function() return true end,
})

local clientOnlyRoles = { shared = true, client = true }
local roleOk, roleErr = Resolver.ResolveClosure(Registry, "role.server_only", clientOnlyRoles)
assertEqual(roleOk, nil, "server_only capability should fail on client role")
assert(string.find(roleErr, "not eligible", 1, true) ~= nil, "error should report role ineligibility: " .. tostring(roleErr))

local serverRoles = { shared = true, server = true }
local srvClosure, srvErr = Resolver.ResolveClosure(Registry, "role.server_only", serverRoles)
assert(srvClosure ~= nil, "server_only capability should succeed on server role: " .. tostring(srvErr))
assertEqual(srvClosure[1], "role.server_only", "closure contains server_only")

print("psychopatz kernel smoke: ok")
