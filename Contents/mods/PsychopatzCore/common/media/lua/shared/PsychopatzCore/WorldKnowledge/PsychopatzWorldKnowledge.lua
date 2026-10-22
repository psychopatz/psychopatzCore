local Fact = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFact"
local Ledger = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldFactLedger"
local ActorKnowledge = require "PsychopatzCore/WorldKnowledge/PsychopatzActorWorldKnowledge"

PsychopatzCore = PsychopatzCore or {}
local WKG = PsychopatzCore.WorldKnowledge or {}
PsychopatzCore.WorldKnowledge = WKG

WKG.VERSION = 1
WKG.Fact = Fact
WKG.Ledger = Ledger
WKG.ActorKnowledge = ActorKnowledge
WKG.Providers = WKG.Providers or {}
WKG.LedgerState = WKG.LedgerState or Ledger.New()
WKG.KnowledgeState = WKG.KnowledgeState or ActorKnowledge.NewState()
WKG.Trace = WKG.Trace or {}

function WKG.Reset(options)
    WKG.LedgerState = Ledger.New(nil, options)
    WKG.KnowledgeState = ActorKnowledge.NewState(nil, options)
    WKG.Trace = {}
    return WKG.LedgerState, WKG.KnowledgeState
end

function WKG.RegisterProvider(providerID, provider)
    providerID = tostring(providerID or "")
    if providerID == "" or type(provider) ~= "table" then
        return false, "provider_invalid"
    end
    WKG.Providers[providerID] = provider
    return true
end

function WKG.Publish(specification, options)
    local fact, reason = Ledger.Add(WKG.LedgerState, specification, options)
    if not fact then return nil, reason end
    return fact
end

function WKG.Acquire(actorID, factID, specification)
    return ActorKnowledge.Acquire(
        WKG.KnowledgeState, WKG.LedgerState, actorID, factID, specification
    )
end

function WKG.Share(fromActorID, toActorID, options)
    local transferred, reason = ActorKnowledge.Share(
        WKG.KnowledgeState, WKG.LedgerState, fromActorID, toActorID, options
    )
    if not transferred then return nil, reason end
    for index = 1, #transferred do
        WKG.Trace[#WKG.Trace + 1] = transferred[index]
        while #WKG.Trace > 128 do table.remove(WKG.Trace, 1) end
    end
    return transferred
end

function WKG.Context(actorID, options)
    return ActorKnowledge.BuildContext(
        WKG.KnowledgeState, WKG.LedgerState, actorID, options
    )
end

function WKG.Explain(actorID, factID, now)
    return ActorKnowledge.Explain(
        WKG.KnowledgeState, WKG.LedgerState, actorID, factID, now
    )
end

function WKG.ToPayload(options)
    return {
        schema = "PsychopatzCore.WorldKnowledge",
        schemaVersion = WKG.VERSION,
        ledger = Ledger.ToPayload(WKG.LedgerState, options),
        actors = ActorKnowledge.ToPayload(WKG.KnowledgeState, options),
    }
end

function WKG.FromPayload(payload, options)
    if type(payload) ~= "table"
        or payload.schema ~= "PsychopatzCore.WorldKnowledge"
        or tonumber(payload.schemaVersion) ~= WKG.VERSION
    then return false, "world_knowledge_schema_mismatch" end
    local ledger, ledgerReason = Ledger.FromPayload(payload.ledger, options)
    local knowledge, knowledgeReason = ActorKnowledge.FromPayload(payload.actors, options)
    if not ledger then return false, ledgerReason end
    if not knowledge then return false, knowledgeReason end
    WKG.LedgerState = ledger
    WKG.KnowledgeState = knowledge
    return true
end

return WKG
