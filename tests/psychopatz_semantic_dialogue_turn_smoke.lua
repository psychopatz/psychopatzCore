local T = require "tests/support/test"
T.addPackagePaths()

local SHARED_ROOT = T.layerRoot("common_shared")
package.path = SHARED_ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local dialogueTurn = require "PsychopatzCore/ConvoEngine/DialogueTurn"
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

local turn, reason = dialogueTurn.Parse(
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

local fallback, fallbackReason = dialogueTurn.Parse(
    "answer, unknown",
    parseCandidates,
    { enableFuzzy = false, maxCandidates = 4 }
)
assert(fallbackReason == "single_clause",
    "unrecognized clauses must preserve ordinary parsing")
assert(fallback.compound ~= true, "unsafe split must not become compound")

-- Sentence-period and conjunction compound splits:
local periodTurn, periodReason = dialogueTurn.Parse(
    "answer. question",
    parseCandidates,
    { enableFuzzy = false, maxCandidates = 4 }
)
assert(periodReason == "compound", "period-separated clauses should form a compound turn")
assert(#periodTurn.parts == 2, "period compound part count")
assert(periodTurn.parts[1].text == "answer", "period first clause")
assert(periodTurn.parts[2].text == "question", "period second clause")

local conjTurn, conjReason = dialogueTurn.Parse(
    "answer and question",
    parseCandidates,
    { enableFuzzy = false, maxCandidates = 4 }
)
assert(conjReason == "compound", "conjunction-separated clauses should form a compound turn")
assert(#conjTurn.parts == 2, "conjunction compound part count")
assert(conjTurn.parts[1].text == "answer", "conjunction first clause")
assert(conjTurn.parts[2].text == "question", "conjunction second clause")

print("psychopatz semantic dialogue turn: ok")
