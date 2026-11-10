-- Boundary and Capability Isolation Smoke Test (P5)
-- Verifies:
-- 1. PsychopatzCore does not depend on or require Project Hoomans or Dynamic Trading.
-- 2. Semantic Pack Action Provider capability gating strictly isolates DT-only vs Hoomans-only actions.
-- 3. Unknown capabilities or malicious calls fail closed.

local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function falsy(value, label)
    if value then error(label or "expected falsy") end
end

local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local PackRegistry = Semantics.PackRegistry
PackRegistry.Reset()

-- Register dummy DT provider
PackRegistry.RegisterActionProvider({
    id = "DT.trade",
    capabilityRequired = "DT.trade",
    order = 10,
    collect = function(ctx)
        return {
            { id = "dt_action_trade", label = "Trade" },
            { id = "dt_action_rumor", label = "Rumor" },
        }
    end,
})

-- Register dummy Hoomans companion provider
PackRegistry.RegisterActionProvider({
    id = "hoomans.companion",
    capabilityRequired = "hoomans.companion",
    order = 20,
    collect = function(ctx)
        return {
            { id = "hoomans_action_follow", label = "Follow Me" },
            { id = "hoomans_action_camp", label = "Make Camp" },
        }
    end,
})

-- Register dummy Hoomans command provider with choice-level gating
PackRegistry.RegisterActionProvider({
    id = "hoomans.command",
    order = 30,
    collect = function(ctx)
        return {
            { id = "hoomans_action_attack", label = "Attack", capabilityRequired = "hoomans.command" },
        }
    end,
})

-- Case 1: Pure DT Trader (capabilities: only DT.trade)
local dtContext = {
    actorID = "pure_dt_trader",
    capabilities = {
        ["DT.trade"] = true,
    },
}
local dtActions = PackRegistry.CollectActions(dtContext)
equal(#dtActions, 2, "DT actor gets exactly 2 DT actions")
for _, act in ipairs(dtActions) do
    truthy(string.sub(act.id, 1, 3) == "dt_", "Only DT actions returned for DT trader: " .. act.id)
    falsy(string.find(act.id, "hoomans", 1, true), "No hoomans actions on DT trader")
end

-- Case 2: Pure Hoomans Companion (capabilities: hoomans.companion)
local hoomansContext = {
    actorID = "pure_hoomans_npc",
    capabilities = {
        ["hoomans.companion"] = true,
    },
}
local hoomansActions = PackRegistry.CollectActions(hoomansContext)
equal(#hoomansActions, 2, "Hoomans companion gets exactly 2 companion actions")
for _, act in ipairs(hoomansActions) do
    truthy(string.sub(act.id, 1, 8) == "hoomans_", "Only Hoomans actions returned: " .. act.id)
    falsy(string.find(act.id, "dt_", 1, true), "No DT actions on Hoomans NPC")
end

-- Case 3: Empty capabilities (no actions allowed under strict gating)
local emptyContext = {
    actorID = "blank_actor",
    capabilities = {},
}
local emptyActions = PackRegistry.CollectActions(emptyContext)
equal(#emptyActions, 0, "No actions collected when actor has no matching capabilities")

-- Case 4: Nil capabilities with strictCapabilities = true
local strictActions = PackRegistry.CollectActions({ actorID = "unprivileged" }, { strictCapabilities = true })
equal(#strictActions, 0, "Strict capabilities mode blocks ungated capability providers")

-- Case 5: Hybrid actor (both capabilities present)
local hybridContext = {
    actorID = "hybrid_trader_companion",
    capabilities = {
        ["DT.trade"] = true,
        ["hoomans.companion"] = true,
        ["hoomans.command"] = true,
    },
}
local hybridActions = PackRegistry.CollectActions(hybridContext)
equal(#hybridActions, 5, "Hybrid actor receives all 5 actions from both providers")

-- Case 6: Faulty provider fails gracefully without crashing CollectActions
PackRegistry.RegisterActionProvider({
    id = "faulty.provider",
    capabilityRequired = "faulty.cap",
    collect = function()
        error("Simulated provider crash")
    end,
})
local faultyContext = {
    actorID = "faulty_test",
    capabilities = {
        ["DT.trade"] = true,
        ["faulty.cap"] = true,
    },
}
local resilientActions = PackRegistry.CollectActions(faultyContext)
equal(#resilientActions, 2, "CollectActions handles throwing provider gracefully")

print("psychopatz_boundary_isolation_smoke: PASS")
