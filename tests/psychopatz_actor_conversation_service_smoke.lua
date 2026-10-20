local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Knowledge = require "PsychopatzCore/Actors/PsychopatzActorKnowledge"
local Service = require
    "PsychopatzCore/Conversation/PsychopatzActorConversationService"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

Semantics.Registry.Reset()
truthy(Semantics.Registry.RegisterPattern({
    id = "service.answer",
    match = { { kind = "literal", value = "answer" } },
    emit = { intent = "INFORM", speechAct = "INFORM", subject = "ANSWER" },
}))
truthy(Semantics.Registry.RegisterPattern({
    id = "service.question",
    match = { { kind = "literal", value = "question" } },
    emit = { intent = "QUESTION", speechAct = "QUESTION", subject = "TOPIC" },
}))

local actor = {
    actorId = "actor:conversation:one",
    identity = { displayName = "Offline Actor" },
    persona = { backstory = { selections = {
        hometown = { id = "hometown.rosewood", version = 1 },
    } } },
    social = { personality = { patience = 0.8 }, relationships = {} },
    knowledge = Knowledge.NewState({
        byPlayer = {
            ["player:alice"] = {
                facts = {
                    ["history.hometown"] = {
                        status = "confirmed",
                        value = "hometown.rosewood",
                        confidence = 1,
                        evidence = {
                            { id = "evidence:home", sourceType = "conversation" },
                        },
                    },
                },
            },
        },
    }),
}

local service, serviceReason = Service.New({
    actor = actor,
    stateSpec = { maxEvents = 4 },
    policy = {
        Decide = function(ir)
            if ir.intent == "QUESTION" then
                return {
                    branch = "QUESTION_RECEIVED",
                    response = {
                        key = "service.question",
                        fallback = "What would you like to know?",
                    },
                }
            end
            return {
                branch = "ANSWER_RECEIVED",
                response = {
                    key = "service.answer",
                    fallback = "Thank you.",
                },
            }
        end,
    },
    localize = function(key, _, language, fallback)
        if key == "service.question" and language == "TL" then
            return "Ano ang gusto mong malaman?"
        end
        return fallback
    end,
})
truthy(service, serviceReason)

local injectedRouter = {
    state = service.router.state,
    Process = function() return { accepted = true } end,
    ParseCandidates = function(_, text, options)
        return service.router:ParseCandidates(text, options)
    end,
}
local injected = Service.New({ actor = actor, router = injectedRouter })
truthy(injected, "injected router service")
equal(injected.router, injectedRouter, "production router is retained")
local injectedTurn, injectedReason = injected:ParseTurn("answer, question")
truthy(injectedTurn, injectedReason)
equal(injectedTurn.compound, true, "injected router uses Core turn parser")

local called = false
truthy(service:RegisterCapability("test:notify", function()
    called = true
    return { accepted = true }
end))
equal(service:GetCapability("test:notify").id, "test:notify",
    "registered capability")

local clientCapability, clientCapabilityReason = service:InvokeCapability(
    "test:notify", {}, {}, "client")
equal(clientCapability, nil, "client capability invocation rejected")
equal(clientCapabilityReason, "server_authority_required",
    "capability authority")
local capabilityResult, capabilityReason = service:InvokeCapability(
    "test:notify", {}, {}, "server")
truthy(capabilityResult, capabilityReason)
truthy(called, "server capability was not invoked")

local compound, compoundReason = service:Submit(
    "answer, question", {}, { language = "TL", enableFuzzy = false })
truthy(compound, compoundReason)
equal(compound.compound, true, "compound turn preserved")
equal(#compound.parts, 2, "multiple speech acts processed")
equal(#compound.responses, 2, "responses planned for each speech act")
equal(compound.responses[2].text, "Ano ang gusto mong malaman?",
    "response localization")
equal(compound.parts[1].decision.branch, "ANSWER_RECEIVED",
    "first speech act decision")
equal(compound.parts[2].decision.branch, "QUESTION_RECEIVED",
    "second speech act decision")
truthy(compound.pendingQuestion, "question obligation retained")
equal(#compound.state.recentSemanticEvents, 2,
    "bounded semantic event history")

local fact, factReason = service:GetKnowledge(
    "alice", "history.hometown", "server")
truthy(fact, factReason)
equal(fact.value, "hometown.rosewood", "grounded personal fact")
local clientFact, clientFactReason = service:GetKnowledge(
    "alice", "history.hometown", "client")
equal(clientFact, nil, "client Knowledge read rejected")
equal(clientFactReason, "server_authority_required", "Knowledge read authority")

local snapshot = service:Snapshot()
equal(snapshot.actorID, actor.actorId, "actor identity in bounded snapshot")
truthy(snapshot.state.pendingQuestion, "pending question in snapshot")
equal(snapshot.state.actor, nil, "snapshot contains no duplicated actor biography")

print("psychopatz_actor_conversation_service_smoke: PASS")
