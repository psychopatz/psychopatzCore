local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Service = require "PsychopatzCore/Conversation/PsychopatzActorConversationService"

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

Semantics.Registry.Reset()

-- 1. Register Core conversation pack
Semantics.RegisterPack({
    id = "pack.core.conversation",
    ownerModID = "PsychopatzCore",
    capabilitiesRequired = { "core.conversation" },
    concepts = {
        { id = "core.concept.greeting", aliases = { "hello", "hi", "greetings" } },
    },
    speechActs = {
        { definition = { id = "act.core.greeting", intent = "GREET" } },
    },
    patterns = {
        {
            id = "core.pattern.greeting",
            capabilitiesRequired = { "core.conversation" },
            match = { { concept = "core.concept.greeting" } },
            emit = { intent = "GREET", speechAct = "act.core.greeting" },
        },
    },
    dialogueBlocks = {
        {
            id = "core_block_greeting",
            capabilitiesRequired = { "core.conversation" },
            gates = {},
            entryNode = "node_greet",
            nodes = {
                node_greet = { textKey = "UI_Core_Greeting", choices = {} },
            },
        },
    },
})

-- 2. Register Dynamic Trading pack (capabilitiesRequired = "dynamictrading.trade")
Semantics.RegisterPack({
    id = "pack.dynamictrading.trade",
    ownerModID = "DynamicTrading",
    capabilitiesRequired = { "dynamictrading.trade" },
    concepts = {
        { id = "dt.concept.trade", aliases = { "trade", "barter", "deal" } },
    },
    speechActs = {
        { definition = { id = "act.dt.trade", intent = "TRADE" } },
    },
    patterns = {
        {
            id = "dt.pattern.trade",
            capabilitiesRequired = { "dynamictrading.trade" },
            match = { { concept = "dt.concept.trade" } },
            emit = { intent = "TRADE", speechAct = "act.dt.trade" },
        },
    },
    dialogueBlocks = {
        {
            id = "dt_block_trade",
            capabilitiesRequired = { "dynamictrading.trade" },
            gates = {},
            entryNode = "node_trade",
            nodes = {
                node_trade = { textKey = "UI_DT_Trade", choices = {} },
            },
        },
    },
})

-- 3. Register Project Hoomans pack (capabilitiesRequired = "hoomans.command")
Semantics.RegisterPack({
    id = "pack.projecthoomans.social",
    ownerModID = "ProjectHoomans",
    capabilitiesRequired = { "hoomans.command" },
    concepts = {
        { id = "hoomans.concept.follow", aliases = { "follow me", "come with me" } },
    },
    speechActs = {
        { definition = { id = "act.hoomans.command", intent = "COMMAND" } },
    },
    patterns = {
        {
            id = "hoomans.pattern.follow",
            capabilitiesRequired = { "hoomans.command" },
            match = { { concept = "hoomans.concept.follow" } },
            emit = { intent = "COMMAND", speechAct = "act.hoomans.command", goal = "FOLLOW" },
        },
    },
    dialogueBlocks = {
        {
            id = "hoomans_block_follow",
            capabilitiesRequired = { "hoomans.command" },
            gates = {},
            entryNode = "node_follow",
            nodes = {
                node_follow = { textKey = "UI_Hoomans_Follow", choices = {} },
            },
        },
    },
})

local testActor = {
    actorId = "actor:isolation:test",
    identity = { displayName = "Isolation Tester" },
    social = { personality = {}, relationships = {} },
}

local convService = Service.New({
    actor = testActor,
    stateSpec = { maxEvents = 8 },
})

print("=== Test 1: DT-only capability conversation cannot parse Hoomans COMMAND ===")
do
    local dtContext = {
        capabilities = { "core.conversation", "dynamictrading.trade" },
        targetKey = "player:user:Tester",
    }
    local res, why = convService:Submit("follow me", dtContext)
    -- Must NOT parse as Hoomans COMMAND
    local matchedPart = res and res.parts and res.parts[1]
    local ir = matchedPart and matchedPart.ir
    if ir and ir.intent == "COMMAND" then
        error("FAIL: Hoomans COMMAND grammar leaked into DT-only conversation!")
    end
    print("PASS: 'follow me' was not parsed as Hoomans COMMAND in DT-only conversation")
end

print("=== Test 2: DT-only capability conversation allows DT trade grammar ===")
do
    local dtContext = {
        capabilities = { "core.conversation", "dynamictrading.trade" },
        targetKey = "player:user:Tester",
    }
    local res, why = convService:Submit("trade", dtContext)
    truthy(res and res.accepted, "Submit('trade') accepted")
    local ir = res.parts and res.parts[1] and res.parts[1].ir
    truthy(ir, "IR produced for trade")
    equal(ir.intent, "TRADE", "Trade intent matched in DT-capable conversation")
    print("PASS: 'trade' parsed successfully in DT-capable conversation")
end

print("=== Test 3: Hoomans-only capability conversation cannot parse DT trade ===")
do
    local hoomansContext = {
        capabilities = { "core.conversation", "hoomans.command" },
        targetKey = "player:user:Tester",
    }
    local res, why = convService:Submit("trade", hoomansContext)
    local matchedPart = res and res.parts and res.parts[1]
    local ir = matchedPart and matchedPart.ir
    if ir and ir.intent == "TRADE" then
        error("FAIL: DT trade grammar leaked into Hoomans-only conversation!")
    end
    print("PASS: 'trade' was not parsed in Hoomans-only conversation")
end

print("=== Test 4: Hoomans-capable conversation parses Hoomans COMMAND ===")
do
    local hoomansContext = {
        capabilities = { "core.conversation", "hoomans.command" },
        targetKey = "player:user:Tester",
    }
    local res, why = convService:Submit("follow me", hoomansContext)
    truthy(res and res.accepted, "Submit('follow me') accepted")
    local ir = res.parts and res.parts[1] and res.parts[1].ir
    truthy(ir, "IR produced for follow me")
    equal(ir.intent, "COMMAND", "Command intent matched in Hoomans-capable conversation")
    equal(ir.speechAct, "act.hoomans.command", "SpeechAct is act.hoomans.command")
    print("PASS: 'follow me' parsed as COMMAND in Hoomans-capable conversation")
end

print("=== Test 5: Compound turn cannot smuggle forbidden adopter clause ===")
do
    local dtContext = {
        capabilities = { "core.conversation", "dynamictrading.trade" },
        targetKey = "player:user:Tester",
    }
    -- User attempts compound utterance with one allowed clause ("trade") and one forbidden ("follow me")
    local res, why = convService:Submit("trade; follow me", dtContext)
    -- The forbidden clause cannot be matched as COMMAND
    if res and res.parts then
        for _, part in ipairs(res.parts) do
            local ir = part.ir
            if ir and ir.intent == "COMMAND" then
                error("FAIL: Compound turn smuggled forbidden COMMAND clause!")
            end
        end
    end
    print("PASS: Compound turn with forbidden clause did not execute forbidden COMMAND")
end

print("=== Test 6: Explicit caller options cannot broaden effective capabilities ===")
do
    local dtContext = {
        capabilities = { "core.conversation", "dynamictrading.trade" },
        targetKey = "player:user:Tester",
    }
    -- Caller passes malicious or overly broad options.capabilities attempting to unlock hoomans.command
    local bypassOptions = {
        capabilities = { ["hoomans.command"] = true, ["dynamictrading.trade"] = true },
    }
    local res, why = convService:Submit("follow me", dtContext, bypassOptions)
    local matchedPart = res and res.parts and res.parts[1]
    local ir = matchedPart and matchedPart.ir
    if ir and ir.intent == "COMMAND" then
        error("FAIL: Explicit caller options broadened privileges beyond effective context!")
    end
    print("PASS: Explicit caller options could not broaden privileges beyond effective context")
end

print("=== Test 7: Unregister/re-register remains residue-free ===")
do
    Semantics.UnregisterPack("pack.dynamictrading.trade")
    local dtContext = {
        capabilities = { "core.conversation", "dynamictrading.trade" },
        targetKey = "player:user:Tester",
    }
    local res, why = convService:Submit("trade", dtContext)
    local matchedPart = res and res.parts and res.parts[1]
    local ir = matchedPart and matchedPart.ir
    falsy(ir and ir.intent == "TRADE", "Unregistered DT pack leaves no trade grammar residue")
    print("PASS: Unregistered pack left no residue")
end

print("psychopatz_conversation_capability_isolation_smoke: PASS")
