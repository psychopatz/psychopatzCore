local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Landing = require
    "PsychopatzCore/Conversation/PsychopatzActorConversationLanding"

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

Semantics.PackRegistry.Reset()
local registered, reason = Semantics.RegisterPack({
    id = "pack.core.landing.smoke",
    ownerModID = "Smoke",
    version = 1,
    actionProviders = {
        {
            id = "smoke.trade_action",
            sourceKind = "smoke",
            capabilityRequired = "smoke.trade",
            order = 20,
            collect = function()
                return {
                    {
                        id = "smoke.trade",
                        sourceKind = "smoke",
                        fallbackText = "Trade",
                        order = 20,
                    },
                }
            end,
        },
    },
    dialogueBlocks = {
        {
            id = "smoke.greeting",
            category = "greeting",
            priority = 100,
            gates = {},
            entryNode = "opening",
            nodes = {
                opening = {
                    textKey = "UI_Smoke_Greeting",
                    fallback = "Welcome, traveler.",
                },
            },
        },
    },
})
truthy(registered, reason)

local built = Landing.Build({
    context = {
        actorID = "actor:smoke",
        capabilities = { ["smoke.trade"] = true },
        strictCapabilities = true,
    },
    greetingFallback = "Fallback greeting",
    actionFilter = function(action)
        return action.sourceKind == "smoke"
    end,
    actionChoice = function(action)
        return { id = action.id, text = action.fallbackText .. " now" }
    end,
    choices = {
        { id = "goodbye", text = "Goodbye.", close = true },
    },
})

equal(built.start, "landing", "Core landing uses one stable entry node")
equal(built.nodes.landing.npc.text,
    "Welcome, traveler.",
    "Core landing uses the selected semantic greeting fallback")
equal(#built.actions, 1,
    "Core landing collects capability-authorized actions")
equal(built.nodes.landing.choices[1].id, "smoke.trade",
    "Core landing places provider actions in the native choice list")
equal(built.nodes.landing.choices[1].next, "landing",
    "Core landing returns actions to the shared landing")
equal(built.nodes.landing.choices[2].id, "goodbye",
    "Core landing preserves adopter-authored static choices")

local noCapability = Landing.Build({
    context = { capabilities = {}, strictCapabilities = true },
    actionFilter = function() return true end,
})
equal(#noCapability.actions, 0,
    "Core landing does not expose unauthorized provider actions")
truthy(noCapability.nodes.landing,
    "Core landing remains usable when optional actions are unavailable")

print("psychopatz_actor_conversation_landing_smoke: PASS")
