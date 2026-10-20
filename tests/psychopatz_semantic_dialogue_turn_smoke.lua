local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local registry = semantics.Registry
registry.Reset()

assert(registry.RegisterPattern({
    id = "answer",
    match = { { kind = "literal", value = "answer" } },
    emit = { intent = "INFORM", speechAct = "INFORM" },
}))
assert(registry.RegisterPattern({
    id = "question",
    match = { { kind = "literal", value = "question" } },
    emit = { intent = "QUESTION", speechAct = "QUESTION" },
}))

local function parseCandidates(value, options)
    return semantics.Parser.ParseCandidates(value, options)
end

local turn, reason = semantics.DialogueTurn.Parse(
    "answer, question?",
    parseCandidates,
    { enableFuzzy = false, maxCandidates = 4 }
)
assert(reason == "compound", "recognized clauses should form a compound turn")
assert(turn.compound == true, "compound marker")
assert(#turn.parts == 2, "compound part count")
assert(turn.parts[1].text == "answer", "first clause boundary")
assert(turn.parts[2].text == "question", "second clause boundary")
assert(turn.parts[1].candidates.selected.patternID == "answer",
    "first clause uses the existing candidate parser")
assert(turn.parts[2].candidates.selected.patternID == "question",
    "second clause uses the existing candidate parser")

local fallback, fallbackReason = semantics.DialogueTurn.Parse(
    "answer, unknown",
    parseCandidates,
    { enableFuzzy = false, maxCandidates = 4 }
)
assert(fallbackReason == "single_clause",
    "unrecognized clauses must preserve ordinary parsing")
assert(fallback.compound ~= true, "unsafe split must not become compound")

print("psychopatz semantic dialogue turn: ok")
