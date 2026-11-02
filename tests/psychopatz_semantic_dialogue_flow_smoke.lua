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
local Flow = Semantics.DialogueFlow
local PackRegistry = Semantics.PackRegistry

PackRegistry.Reset()

-- 1. Test Flow.Compare
equal(Flow.Compare(10, ">=", 5), true, "10 >= 5")
equal(Flow.Compare(3, ">=", 5), false, "3 >= 5 is false")
equal(Flow.Compare("guard", "==", "guard"), true, "strings equal")
equal(Flow.Compare("trader", "~=", "guard"), true, "strings not equal")

-- 2. Test Flow.EvaluateGate
local context = {
    capabilities = { ["core.conversation"] = true, ["dynamictrading.trade"] = true },
    traderRole = "merchant",
    actor = {
        relationship = {
            approval = 35,
            respect = 20,
            familiarity = 15,
        },
    },
}

-- Passes
equal(Flow.EvaluateGate({ field = "traderRole", op = "==", value = "merchant" }, context), true, "role gate passes")
equal(Flow.EvaluateGate({ field = "relationship.approval", op = ">=", value = 30 }, context), true, "approval gate passes")
equal(Flow.EvaluateGate({ capabilityRequired = "dynamictrading.trade" }, context), true, "capability gate passes")

-- Fails
equal(Flow.EvaluateGate({ field = "relationship.approval", op = ">=", value = 50 }, context), false, "high approval gate fails")
equal(Flow.EvaluateGate({ capabilityRequired = "projecthoomans.follow" }, context), false, "missing capability fails")

-- 3. Register Pack with Dialogue Blocks
local pack, packReason = Semantics.RegisterPack({
    id = "pack.test.story",
    ownerModID = "DynamicTrading",
    dialogueBlocks = {
        ["block_opening_friendly"] = {
            category = "greeting",
            priority = 200,
            weight = 100,
            gates = {
                { field = "relationship.approval", op = ">=", value = 25 },
            },
            entryNode = "node_welcome_friend",
            nodes = {
                node_welcome_friend = {
                    text = "Welcome back, my good friend! What can I do for you?",
                    choices = {
                        {
                            id = "choice_trade",
                            text = "Let us trade goods.",
                            capabilityRequired = "dynamictrading.trade",
                            outcomes = {
                                { id = "outcome_trade", responseKey = "response.trade.open" },
                            },
                        },
                        {
                            id = "choice_story",
                            text = "Any news from the road?",
                            gates = {
                                { field = "relationship.familiarity", op = ">=", value = 10 },
                            },
                            outcomes = {
                                { id = "outcome_story_1", weight = 50, responseKey = "story.muldraugh" },
                                { id = "outcome_story_2", weight = 50, responseKey = "story.west_point" },
                            },
                        },
                        {
                            id = "choice_forbidden",
                            text = "Follow me.",
                            capabilityRequired = "projecthoomans.follow",
                        },
                    },
                },
            },
        },
        ["block_opening_stranger"] = {
            category = "greeting",
            priority = 100,
            weight = 100,
            gates = {},
            entryNode = "node_welcome_stranger",
            nodes = {
                node_welcome_stranger = {
                    text = "State your business, stranger.",
                },
            },
        },
    },
})
truthy(pack, packReason)

-- 4. Select Dialogue Block with high approval context
local selectedBlock = Semantics.SelectDialogueBlock("greeting", context, "seed123")
truthy(selectedBlock, "block selected")
equal(selectedBlock.id, "block_opening_friendly", "friendly block selected over stranger due to priority 200")
equal(selectedBlock.entryNode, "node_welcome_friend", "entry node matches")

-- 5. Test Choice Filtering
local entryNode = selectedBlock.nodes[selectedBlock.entryNode]
local filteredChoices = Flow.FilterChoices(entryNode.choices, context)
-- In context:
-- choice_trade has capability dynamictrading.trade (present) -> PASS
-- choice_story has familiarity >= 10 (15 >= 10) -> PASS
-- choice_forbidden has capability projecthoomans.follow (absent) -> DROPPED
equal(#filteredChoices, 2, "2 choices eligible")
equal(filteredChoices[1].id, "choice_trade", "trade choice present")
equal(filteredChoices[2].id, "choice_story", "story choice present")

-- 6. Test Outcome Resolution
local storyOutcome = Flow.ResolveOutcome(filteredChoices[2], context, 42)
truthy(storyOutcome, "story outcome resolved")
truthy(storyOutcome.responseKey == "story.muldraugh" or storyOutcome.responseKey == "story.west_point",
    "valid weighted outcome selected")

-- 7. Context with stranger (approval = 0)
local strangerContext = {
    capabilities = { ["core.conversation"] = true },
    actor = {
        relationship = {
            approval = 0,
            respect = 0,
            familiarity = 0,
        },
    },
}
local strangerBlock = Semantics.SelectDialogueBlock("greeting", strangerContext, "seed456")
equal(strangerBlock.id, "block_opening_stranger", "stranger block selected when approval < 25")

print("psychopatz_semantic_dialogue_flow_smoke: PASS")
