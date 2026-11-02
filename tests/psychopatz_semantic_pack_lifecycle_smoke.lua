local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error((label or "expected truthy") .. " got=" .. tostring(value)) end
end

local function falsy(value, label)
    if value then error((label or "expected falsy") .. " got=" .. tostring(value)) end
end

local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local PackRegistry = Semantics.PackRegistry
local Registry = Semantics.Registry
local Parser = Semantics.Parser

PackRegistry.Reset()
Registry.Reset()

-- 1. Define a modular semantic pack with capabilities required
local testPackSpec = {
    id = "pack_combat_tactics",
    ownerModID = "ProjectHoomans",
    version = 1,
    capabilitiesRequired = { "tactical_orders" },
    concepts = {
        {
            id = "concept.flank",
            aliases = { "flank", "flanking maneuver" },
            priority = 20,
        },
        {
            id = "concept.suppress",
            aliases = { "suppress", "covering fire" },
            priority = 20,
        },
    },
    speechActs = {
        {
            definition = { id = "act.tactical_order" },
            metadata = { intent = "order" },
        },
    },
    patterns = {
        {
            id = "pattern_order_flank",
            priority = 50,
            match = {
                { concept = "concept.flank" },
            },
            emit = {
                speechAct = "act.tactical_order",
                intent = "flank_target",
            },
        },
    },
    actionProviders = {
        {
            id = "provider_tactical_commands",
            capabilityRequired = "tactical_orders",
            collect = function(context)
                return {
                    { id = "action_flank", label = "Flank Left", order = 10 },
                }
            end,
        },
    },
    dialogueBlocks = {
        tactical_flank_response = {
            category = "combat_order",
            priority = 100,
            gates = {
                { field = "relationship.approval", op = ">=", value = 10 },
            },
            nodes = {
                opening = {
                    textKey = "IGUI_Flank_Ack",
                    choices = {},
                },
            },
        },
    },
}

-- 2. Register pack
local registeredPack, regErr = PackRegistry.RegisterPack(testPackSpec)
truthy(registeredPack, regErr)
equal(#registeredPack.registeredConcepts, 2, "Registered 2 concepts")
equal(#registeredPack.registeredSpeechActs, 1, "Registered 1 speech act")
equal(#registeredPack.registeredPatterns, 1, "Registered 1 pattern")
equal(#registeredPack.registeredActionProviders, 1, "Registered 1 provider")
equal(#registeredPack.registeredDialogueBlocks, 1, "Registered 1 dialogue block")

-- 3. Verify presence in semantic registry
truthy(Registry.GetConcept("concept.flank"), "Concept present")
truthy(Registry.GetSpeechAct("act.tactical_order"), "Speech act present")
truthy(Registry.Patterns["pattern_order_flank"], "Pattern present")

-- 4. Verify parsing with required capability
local parsedAllowed = Parser.Parse("flank", { capabilities = { tactical_orders = true } })
truthy(parsedAllowed, "Parses with capability")
equal(parsedAllowed.speechAct, "act.tactical_order", "Emits speech act")
equal(parsedAllowed.intent, "flank_target", "Emits intent")

-- 5. Verify capability gating: parser rejects if required capability is absent
local parsedDenied = Parser.Parse("flank", { capabilities = { tactical_orders = false } })
truthy(parsedDenied.confidence == 0, "Parser confidence is 0 without capability")
truthy(parsedDenied.diagnostics.noMatch, "noMatch is true without capability")
falsy(parsedDenied.speechAct, "Parser emits no speechAct without required capability")
falsy(parsedDenied.intent, "Parser emits no intent without required capability")

-- 6. Verify dialogue block capability gating
local blockAllowed = PackRegistry.SelectDialogueBlock("combat_order", {
    capabilities = { tactical_orders = true },
    relationship = { approval = 20 },
})
truthy(blockAllowed, "Dialogue block selected when capability met")
equal(blockAllowed.id, "tactical_flank_response")

local blockDenied = PackRegistry.SelectDialogueBlock("combat_order", {
    capabilities = { tactical_orders = false },
    relationship = { approval = 20 },
})
falsy(blockDenied, "Dialogue block excluded when capability missing")

-- 7. Verify action provider capability gating
local actionsAllowed = PackRegistry.CollectActions({ capabilities = { tactical_orders = true } })
equal(#actionsAllowed, 1, "Action collected when capability met")
equal(actionsAllowed[1].id, "action_flank")

local actionsDenied = PackRegistry.CollectActions({ capabilities = { tactical_orders = false } })
equal(#actionsDenied, 0, "Action excluded when capability missing")

-- 8. UNREGISTER PACK: complete residue-free lifecycle purge
local unregOk, unregErr = PackRegistry.UnregisterPack("pack_combat_tactics")
truthy(unregOk, unregErr)

-- Verify complete purge from Registry
falsy(Registry.GetConcept("concept.flank"), "Concept purged after unregister")
falsy(Registry.GetConcept("concept.suppress"), "Concept 2 purged after unregister")
falsy(Registry.GetSpeechAct("act.tactical_order"), "Speech act purged after unregister")
falsy(Registry.Patterns["pattern_order_flank"], "Pattern purged after unregister")
equal(#Registry.LookupAlias("flank"), 0, "Aliases purged after unregister")

-- Verify complete purge from PackRegistry
falsy(PackRegistry.GetPack("pack_combat_tactics"), "Pack purged")
falsy(PackRegistry.GetDialogueBlock("tactical_flank_response"), "Dialogue block purged")
falsy(PackRegistry.GetActionProvider("provider_tactical_commands"), "Provider purged")

-- Verify parsing after unregister produces ZERO match (no residual parsing tokens)
local parsedAfterUnregister = Parser.Parse("flank", { capabilities = { tactical_orders = true } })
falsy(parsedAfterUnregister.speechAct, "No residual speechAct after unregister")
truthy(parsedAfterUnregister.diagnostics.noMatch, "noMatch is true after unregister")
falsy(parsedAfterUnregister.intent, "No intent emitted after unregister")

-- Verify dialogue block selection returns nothing
local blockAfterUnregister = PackRegistry.SelectDialogueBlock("combat_order", {
    capabilities = { tactical_orders = true },
    relationship = { approval = 20 },
})
falsy(blockAfterUnregister, "No dialogue block after unregister")

-- 9. Re-registration works cleanly
local reRegistered = PackRegistry.RegisterPack(testPackSpec)
truthy(reRegistered, "Re-register succeeds")
truthy(Registry.GetConcept("concept.flank"), "Concept restored on re-register")
local parsedRestored = Parser.Parse("flank", { capabilities = { tactical_orders = true } })
equal(parsedRestored.intent, "flank_target", "Parses again after re-register")

print("psychopatz_semantic_pack_lifecycle_smoke: PASS")
