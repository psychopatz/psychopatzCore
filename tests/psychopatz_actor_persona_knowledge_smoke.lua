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

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Persona = Actors.Persona
local Knowledge = Actors.Knowledge
local registry = Actors.NewRegistry()

local actor, actorReason = registry:Create({
    actorId = "actor:portable:one",
    identitySeed = "portable-stable-seed",
    starterItems = {},
    persona = {
        backstory = {
            selectionSetVersion = "hoomans:2",
            selections = {
                former_job = {
                    id = "former_job.mechanic",
                    version = 2,
                    sourceKey = "pnc.backstory",
                },
                hometown = { id = "hometown.rosewood", version = 1 },
            },
        },
    },
})
truthy(actor, actorReason)
equal(actor.identity.identitySeed, "portable-stable-seed", "stable identity seed")
truthy(actor.persona, "persona is Core-owned")
local backstory = Persona.GetBackstory(actor.persona, "former_job")
equal(backstory.id, "former_job.mechanic", "versioned backstory selection")
equal(backstory.version, 2, "backstory version")
equal(actor.persona.biography, nil, "no biography paragraph stored")

local unauthorized, unauthorizedReason = Knowledge.Record(actor.knowledge, {
    playerKey = "char:alice",
    factID = "history.hometown",
    value = "hometown.rosewood",
    status = "confirmed",
    evidence = { id = "client-forged", sourceType = "conversation" },
}, "client")
equal(unauthorized, nil, "client Knowledge mutation rejected")
equal(unauthorizedReason, "server_authority_required", "Knowledge authority")

local learned, learnedReason = Knowledge.Record(actor.knowledge, {
    playerKey = "char:alice",
    factID = "history.hometown",
    value = "hometown.rosewood",
    status = "confirmed",
    confidence = 0.95,
    discoveredAt = 10,
    evidence = {
        id = "alice-disclosure",
        sourceType = "radio_disclosure",
        direction = "npc_to_player",
        sourceEventID = "conversation:one",
        payload = { selection = "hometown.rosewood" },
    },
}, "server", actor.knowledge.revision)
truthy(learned, learnedReason)

local second, secondReason = Knowledge.Record(learned, {
    playerKey = "char:bob",
    factID = "history.hometown",
    value = "hometown.muldraugh",
    status = "suspected",
    confidence = 0.2,
    discoveredAt = 11,
    evidence = {
        id = "bob-rumor",
        sourceType = "trusted_gossip",
        payload = { rumor = true },
    },
}, "server", learned.revision)
truthy(second, secondReason)

local aliceFact = Knowledge.Get(second, "char:alice", "history.hometown")
local bobFact = Knowledge.Get(second, "char:bob", "history.hometown")
equal(aliceFact.status, "confirmed", "confirmed fact status")
equal(aliceFact.value, "hometown.rosewood", "Alice fact value")
equal(aliceFact.evidence[1].sourceType, "radio_disclosure",
    "disclosure evidence preserved")
equal(bobFact.status, "suspected", "Bob fact status isolated")
equal(bobFact.value, "hometown.muldraugh", "Bob fact value isolated")
equal(Knowledge.Get(second, "char:alice", "history.education"), nil,
    "Alice has no unlearned fact")

local committed, commitReason = registry:Commit(actor.actorId, {
    knowledge = second,
}, actor.revision)
truthy(committed, commitReason)
local saved, saveReason = registry:Save()
truthy(saved, saveReason)

local fresh = Actors.NewRegistry()
truthy(fresh:Load(saved), "persona and Knowledge reload")
local restored = fresh:Get(actor.actorId)
equal(restored.identity.identitySeed, actor.identity.identitySeed,
    "identity seed survives reload")
equal(Persona.GetBackstory(restored.persona, "hometown").id,
    "hometown.rosewood", "backstory survives reload")
equal(Knowledge.Get(restored.knowledge, "char:alice", "history.hometown").status,
    "confirmed", "Alice Knowledge survives reload")
equal(Knowledge.Get(restored.knowledge, "char:bob", "history.hometown").value,
    "hometown.muldraugh", "Bob Knowledge survives reload")
equal(restored.knowledge.byPlayer["player:char:alice"].facts
    ["history.hometown"].evidence[1].sourceEventID,
    "conversation:one", "evidence survives reload")

local valid, validReason = Knowledge.Validate(restored.knowledge)
truthy(valid, validReason)
local personaValid, personaReason = Persona.Validate(restored.persona)
truthy(personaValid, personaReason)

print("psychopatz_actor_persona_knowledge_smoke: PASS")
