local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local WKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"
local Fact = WKG.Fact
local Ledger = WKG.Ledger
local Knowledge = WKG.ActorKnowledge

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local ledger, actors = WKG.Reset({ maxFacts = 3, maxRefs = 4 })
local first, reason = WKG.Publish({
    producer = "hoomans:faction",
    kind = "faction.member_death",
    subject = { id = "npc:alice", kind = "npc" },
    location = { id = "rosewood", kind = "region" },
    cause = { id = "zombie", kind = "cause" },
    eventID = "death:one",
    occurredAt = 10,
    observedAt = 10,
    severity = 0.9,
    retention = "historical",
    payload = { factionID = "faction:one", causeKnown = true },
})
truthy(first, reason)
local duplicate = WKG.Publish({
    factID = first.factID, kind = first.kind, producer = first.producer,
    occurredAt = first.occurredAt, observedAt = first.observedAt,
    retention = "historical", payload = first.payload,
})
truthy(duplicate, "dedupe publish")
truthy(ledger.metrics.deduped >= 1, "dedupe metric")

truthy(WKG.Acquire("actor:alice", first.factID, {
    authorized = true, provenance = "witnessed", confidence = 0.95,
    source = "nearby_death", acquisitionPath = "perception", learnedAt = 11,
}), "alice acquisition")
local bobFact = WKG.Context("actor:bob", {
    max = 4,
    renderFact = function() return "unreachable" end,
})
if #bobFact.npcGossip.statements ~= 0 then error("Bob learned without authorization") end

local aliceContext = WKG.Context("actor:alice", {
    max = 4,
    now = 12,
    renderFact = function(fact, reference)
        return reference.provenance == "witnessed"
            and "I saw that someone died near Rosewood."
            or "I heard something happened."
    end,
})
truthy(#aliceContext.npcGossip.statements == 1, "Alice grounded statement")
truthy(aliceContext.worldKnowledge.candidates[1].factID == first.factID,
    "Alice candidate fact ID")

local transfer, transferReason = WKG.Share("actor:alice", "actor:bob", {
    authorized = true, now = 20, source = "conversation:alice:bob",
    acquisitionPath = "conversation", max = 2,
})
truthy(transfer, transferReason)
truthy(#transfer == 1, "one bounded transfer")
truthy(transfer[1].provenance == "told", "told provenance")
local bobAfter = WKG.Context("actor:bob", {
    max = 4,
    renderFact = function(_, reference)
        return reference.provenance == "told" and "I heard about a death near Rosewood." or nil
    end,
})
truthy(#bobAfter.npcGossip.statements == 1, "Bob after propagation")

local explanation, explanationReason = WKG.Explain("actor:bob", first.factID, 20)
truthy(explanation, explanationReason)
truthy(explanation.provenance == "told", "explain provenance")
truthy(explanation.acquisitionPath == "conversation", "explain acquisition path")
truthy(explanation.producer == "hoomans:faction", "explain producer")

local payload = WKG.ToPayload()
truthy(#payload.ledger.facts == 1, "historical fact persisted")
local ephemeral = Ledger.Add(ledger, {
    producer = "hoomans:zombie", kind = "zombie.pressure",
    subject = "region:rosewood", eventID = "sample", retention = "ephemeral",
    occurredAt = 30, observedAt = 30, expiresAt = 31,
})
truthy(ephemeral, "ephemeral fact")
payload = WKG.ToPayload()
truthy(#payload.ledger.facts == 1, "ephemeral observation excluded from save")
truthy(Fact.ShouldPersist(ephemeral) == false, "ephemeral persistence policy")

local restored, restoredReason = WKG.FromPayload(payload, { maxFacts = 3 })
truthy(restored, restoredReason)
truthy(WKG.Ledger.Get(WKG.LedgerState, first.factID), "fact reload")
truthy(WKG.ActorKnowledge.Get(WKG.KnowledgeState, "actor:bob", first.factID),
    "actor reference reload")

print("psychopatz_world_knowledge_smoke: PASS")
