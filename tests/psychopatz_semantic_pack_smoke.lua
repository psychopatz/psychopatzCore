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

local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local PackRegistry = Semantics.PackRegistry
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local ConversationService = require "PsychopatzCore/Conversation/PsychopatzActorConversationService"

PackRegistry.Reset()
equal(PackRegistry.GetRevision(), 1, "reset bumped revision")

-- 1. Register a synthetic DynamicTrading pack
local dtPack, dtReason = Semantics.RegisterPack({
    id = "pack.dynamictrading.trader",
    ownerModID = "DynamicTrading",
    version = 1,
    capabilitiesRequired = { "dynamictrading.trade" },
    concepts = {
        {
            id = "concept.trade.open",
            aliases = { "trade", "barter", "open shop", "buy and sell" },
            kind = "intent",
        },
    },
    speechActs = {
        {
            definition = { id = "act.trade.request", intent = "trade" },
            metadata = { priority = 80 },
        },
    },
    actionProviders = {
        {
            id = "dynamictrading.trade_action",
            capabilityRequired = "dynamictrading.trade",
            sourceKind = "dynamic_trading",
            order = 20,
            collect = function(ctx)
                return {
                    {
                        id = "dt_choice_trade",
                        topic = "trade",
                        capabilityRequired = "dynamictrading.trade",
                        textKey = "UI_DT_Trade",
                    },
                }
            end,
        },
        {
            id = "dynamictrading.rumor_action",
            capabilityRequired = "dynamictrading.commercial_info",
            sourceKind = "dynamic_trading",
            order = 40,
            collect = function(ctx)
                return {
                    {
                        id = "dt_choice_rumor",
                        topic = "rumor",
                        capabilityRequired = "dynamictrading.commercial_info",
                        textKey = "UI_DT_Rumor",
                    },
                }
            end,
        },
    },
})
truthy(dtPack, dtReason)

-- 2. Register a synthetic ProjectHoomans pack
local hoomansPack, hReason = Semantics.RegisterPack({
    id = "pack.projecthoomans.companion",
    ownerModID = "ProjectHoomans",
    version = 1,
    capabilitiesRequired = { "projecthoomans.companion" },
    actionProviders = {
        {
            id = "projecthoomans.follow_action",
            capabilityRequired = "projecthoomans.follow",
            sourceKind = "project_hoomans",
            order = 10,
            collect = function(ctx)
                return {
                    {
                        id = "ph_choice_follow",
                        topic = "companion_follow",
                        capabilityRequired = "projecthoomans.follow",
                        textKey = "UI_PH_Follow",
                    },
                }
            end,
        },
    },
})
truthy(hoomansPack, hReason)

-- 3. Diagnostics
local diag = PackRegistry.GetDiagnostics()
equal(diag.packCount, 2, "2 packs registered")
equal(diag.actionProviderCount, 3, "3 action providers registered")

-- 4. Test capability-gating on CollectActions
-- Scenario A: DT standalone session (only DT trade capability, NO Hoomans capabilities)
local dtOnlyActions = Semantics.CollectActions({
    capabilities = {
        ["dynamictrading.trade"] = true,
    },
})
equal(#dtOnlyActions, 1, "only 1 action in DT-only session")
equal(dtOnlyActions[1].id, "dt_choice_trade", "DT trade action present")
-- Verify Hoomans action is completely absent, not merely disabled!
for _, choice in ipairs(dtOnlyActions) do
    if choice.id == "ph_choice_follow" then
        error("Hoomans action leaked into DT-only session!")
    end
end

-- Scenario B: Hoomans-only session (companion capabilities, no DT trade)
local hoomansOnlyActions = Semantics.CollectActions({
    capabilities = {
        ["projecthoomans.follow"] = true,
        ["projecthoomans.companion"] = true,
    },
})
equal(#hoomansOnlyActions, 1, "only 1 action in Hoomans-only session")
equal(hoomansOnlyActions[1].id, "ph_choice_follow", "Hoomans follow action present")

-- Scenario C: Combined session with both DT trade and Hoomans follow
local combinedActions = Semantics.CollectActions({
    capabilities = {
        ["dynamictrading.trade"] = true,
        ["dynamictrading.commercial_info"] = true,
        ["projecthoomans.follow"] = true,
    },
})
equal(#combinedActions, 3, "all 3 actions present in combined session")
-- Order check: ph_choice_follow (order 10) -> dt_choice_trade (order 20) -> dt_choice_rumor (order 40)
equal(combinedActions[1].id, "ph_choice_follow", "first choice by order")
equal(combinedActions[2].id, "dt_choice_trade", "second choice by order")
equal(combinedActions[3].id, "dt_choice_rumor", "third choice by order")

-- 5. Test Relationship-Aware Conversation Service integration
local registry = Actors.NewRegistry()
local testActor, createErr = registry:Create({
    actorId = "actor:dt:standalone",
    identitySeed = "seed-dt-pack-test",
    archetypeID = "trader.general",
    providerLease = { leaseID = "lease-dt-1", provider = "DTAbstract", owner = "DynamicTrading" },
})
truthy(testActor, createErr)

-- Set up actor with relationship to player:test:bob
local committed, commitErr = registry:Commit(testActor.actorId, {
    social = {
        relationships = {
            ["player:test:bob"] = {
                approval = 45,
                respect = 20,
                familiarity = 30,
                extensions = {
                    ["DynamicTrading"] = { commercialTrust = "high" },
                },
            },
        },
    },
})
truthy(committed, commitErr)

local freshActor = registry:Get(testActor.actorId)
local service, servErr = ConversationService.New({
    actor = freshActor,
    decide = function(ir, state, context, options)
        -- Verify that relationship was projected into context!
        truthy(context, "context present")
        truthy(context.actor, "context.actor present")
        truthy(context.actor.relationship, "context.actor.relationship projected")
        equal(context.actor.relationship.approval, 45, "relationship approval projected")
        equal(context.actor.relationship.extensions.DynamicTrading.commercialTrust,
            "high", "relationship DT extension projected")
        return {
            accepted = true,
            response = { text = "Welcome back, Bob!" },
        }
    end,
})
truthy(service, servErr)

-- Submit utterance with playerKey and DT capability
local result = service:Submit("Hello there", {
    playerKey = "player:test:bob",
    capabilities = { ["dynamictrading.trade"] = true },
}, {
    collectActions = true,
})
truthy(result, "submit result truthy")
equal(#result.responses, 1, "one response")
equal(result.responses[1].text, "Welcome back, Bob!", "response text")
truthy(result.actions, "actions collected in result")
equal(#result.actions, 1, "exactly 1 action collected")
equal(result.actions[1].id, "dt_choice_trade", "DT action in conversation result")

-- 6. UnregisterPack cleanup
local unreg, unregReason = Semantics.UnregisterPack("pack.dynamictrading.trader")
truthy(unreg, unregReason)
local afterUnreg = Semantics.CollectActions({
    capabilities = { ["dynamictrading.trade"] = true },
})
equal(#afterUnreg, 0, "actions removed when pack unregistered")

print("psychopatz_semantic_pack_smoke: PASS")
