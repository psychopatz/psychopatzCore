local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Predicate = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"
local IR = require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local State = require
    "PsychopatzCore/Semantics/PsychopatzSemanticDialogueState"

local context = {
    speaker = {id = "npc:alice", traits = {"brave", "kind"}},
    addressee = {id = "player:one", traits = {"patient"}},
    relationship = {speakerToAddressee = {approval = 30}},
    target = {kind = "door"},
}
local predicate = {
    all = {
        {path = "speaker.traits", op = "contains", value = "brave"},
        {path = "speaker.traits", op = "contains_all", values = {"brave", "kind"}},
        {path = "relationship.speakerToAddressee.approval", op = "gte", value = 30},
        {path = "target.kind", op = "eq", value = "door"},
    },
}
local result = Predicate.Evaluate(predicate, context)
truthy(result.allowed, "actor-neutral predicate evaluation")

local swapped = Predicate.Evaluate(predicate, {
    speaker = {id = "player:one", traits = {"brave", "kind"}},
    addressee = {id = "npc:alice"},
    relationship = {speakerToAddressee = {approval = 30}},
    target = {kind = "door"},
})
truthy(swapped.allowed, "actor-swapped predicate evaluation")

local rejected = Predicate.Evaluate({
    path = "speaker.privateMemory",
    op = "exists",
}, context)
equal(rejected.allowed, false, "private predicate is fail-closed")
equal(rejected.status, "private", "private predicate status")

local ir = IR.New({
    kind = "dialogue",
    speaker = {id = "npc:alice"},
    addressee = {id = "player:one"},
    target = {type = "entity", id = "door:front"},
    participants = {
        {role = "speaker", id = "npc:alice"},
        {role = "addressee", id = "player:one"},
    },
    slotDefinitions = {
        {name = "person", type = "entity.person", required = true},
    },
    referenceDefinitions = {
        {name = "door", type = "entity.location", required = true},
    },
})
local valid, reason = IR.Validate(ir)
truthy(valid, reason)
equal(ir.speaker.id, ir.actor.id, "speaker actor alias")
equal(ir.addressee.id, ir.recipient.id, "addressee recipient alias")
truthy(IR.IsPublicContextPath("slot.person.name"), "typed slot path")
equal(IR.IsPublicContextPath("speaker.privateMemory"), false,
    "private context path rejected")

local state = State.New({
    speaker = context.speaker,
    addressee = context.addressee,
    target = context.target,
    relationship = context.relationship,
    slots = {person = {id = "player:one"}},
    references = {door = {id = "door:front"}},
})
local projected = state:ToContext()
equal(projected.speaker.id, "npc:alice", "state speaker projection")
equal(projected.addressee.id, "player:one", "state addressee projection")
equal(projected.slot.person.id, "player:one", "typed slot projection")
equal(projected.reference.door.id, "door:front", "typed reference projection")

print("psychopatz_semantic_dialogue_contract_smoke: PASS")
