local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantic.Registry
Registry.Reset()

local function assertEqual(actual, expected, message)
    assert(actual == expected,
        message .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

local function registerConcept(id, aliases, priority)
    assert(Registry.RegisterConcept({
        id = id,
        aliases = aliases,
        priority = priority or 1,
        owner = "test",
    }))
end

local function registerPattern(id, concept, intent, confidence, priority)
    assert(Registry.RegisterPattern({
        id = id,
        match = { { kind = "concept", id = concept } },
        emit = {
            intent = intent,
            speechAct = intent,
            subject = "RECIPIENT",
        },
        confidence = confidence or 0.96,
        priority = priority or 10,
        owner = "test",
    }))
end

registerConcept("INSULT", {
    "fuck you",
    "you idiot",
    "you're useless",
}, 4)
registerConcept("HOSTILE", {
    "shut the fuck up",
    "go away",
}, 3)
registerConcept("THREAT", {
    "i'll kill you",
}, 5)
registerConcept("HELLO", { "hello" }, 1)
registerConcept("THERE", { "there" }, 1)

registerPattern("insult", "INSULT", "INSULT", 0.96, 20)
registerPattern("hostile", "HOSTILE", "HOSTILE_REMARK", 0.96, 20)
registerPattern("threat", "THREAT", "THREATEN", 0.97, 30)

local cases = {
    { "fuckyou", "INSULT", "fuck you", "compact_alias" },
    { "fuckyouuuu", "INSULT", "fuck you", "elongated_compact_alias" },
    { "shutthefuckup", "HOSTILE_REMARK", "shut the fuck up", "compact_alias" },
    { "youidiot", "INSULT", "you idiot", "compact_alias" },
    { "youreuseless", "INSULT", "you're useless", "compact_alias" },
    { "illkillyou", "THREATEN", "i'll kill you", "compact_alias" },
    { "gooo away", "HOSTILE_REMARK", "go away", "elongation" },
}

for _, case in ipairs(cases) do
    local bundle = Semantic.Parser.ParseCandidates(case[1], {
        enableFuzzy = true,
    })
    assert(bundle.selected, "recovery candidate expected for " .. case[1])
    assertEqual(bundle.selected.ir.intent, case[2], "intent " .. case[1])
    assertEqual(bundle.selected.recovered, true, "recovered " .. case[1])
    assertEqual(
        bundle.selected.surfaceRecovery.recoveredNormalizedText,
        case[3],
        "recovered surface " .. case[1]
    )
    assertEqual(
        bundle.selected.surfaceRecovery.kind,
        case[4],
        "recovery kind " .. case[1]
    )
    assertEqual(
        bundle.selected.ir.normalizedText,
        Semantic.Normalizer.NormalizePhrase(case[1]),
        "IR preserves original normalized input " .. case[1]
    )
    assert(
        bundle.selected.ir.provenance.surfaceRecovery ~= nil,
        "IR recovery provenance expected for " .. case[1]
    )
end

local exact = Semantic.Parser.ParseCandidates("fuck you", {
    enableFuzzy = true,
})
assertEqual(exact.selected.exact, true, "exact input remains exact")
assertEqual(exact.selected.recovered, false, "exact input is not recovery")
assert(
    exact.selected.confidence
        > Semantic.Parser.ParseCandidates("fuckyou", {}).selected.confidence,
    "recovered input carries a confidence cost"
)

local segmented = Semantic.SurfaceRecovery.Generate(
    Semantic.Normalizer.Normalize("hellothere"),
    {}
)
assertEqual(#segmented, 1, "unique single-token segmentation")
assertEqual(
    segmented[1].recoveredNormalizedText,
    "hello there",
    "segmented surface"
)
assertEqual(segmented[1].kind, "segmentation", "segmentation kind")

local benign = Semantic.Parser.ParseCandidates("shellow", {})
assertEqual(benign.selected, nil, "benign unknown token remains unknown")

print("psychopatz semantic surface recovery: ok")
