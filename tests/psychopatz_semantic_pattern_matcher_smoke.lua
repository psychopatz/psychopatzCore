local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}
local matcher = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher"

local function assertEqual(actual, expected, message)
    assert(actual == expected,
        message .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

local function literal(text, startToken, endToken)
    return {
        kind = "literal",
        text = text,
        value = text,
        startToken = startToken,
        endToken = endToken,
    }
end

local symbols = {
    {
        kind = "concept",
        id = "person",
        text = "bob",
        value = "bob",
        startToken = 1,
        endToken = 1,
    },
    literal("medical", 2, 2),
    literal("supplies", 3, 3),
}

local result = matcher.Match({
    match = {
        { kind = "concept", id = "person", capture = "subject" },
        {
            kind = "any_phrase",
            minTokens = 2,
            maxTokens = 3,
            capture = "target",
        },
    },
}, symbols, { truncated = false })

assert(result, "concept plus phrase pattern should match")
assertEqual(result.consumed, 3, "match consumption")
assertEqual(result.fullCoverage, true, "match coverage")
assertEqual(result.captures.subject.id, "person", "concept capture")
assertEqual(result.captures.target.text, "medical supplies", "phrase capture")
assertEqual(result.captures.target.tokens[2], "supplies", "phrase tokens")

local emitted = matcher.ResolveEmit({
    actor = "$capture.subject.id",
    target = "$capture.target.text",
    nested = { value = "$capture.subject.value" },
}, result.captures)
assertEqual(emitted.actor, "person", "emit concept reference")
assertEqual(emitted.target, "medical supplies", "emit phrase reference")
assertEqual(emitted.nested.value, "bob", "emit nested reference")

local optional = matcher.Match({
    match = {
        { kind = "literal", value = "medical" },
        { kind = "literal", value = "optional", optional = true },
    },
}, { literal("medical", 1, 1) }, { truncated = false })
assert(optional, "optional rule should match when absent")
assertEqual(optional.skipped, 1, "optional rule skip count")

local semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local registry = semantics.Registry
registry.Reset()
assert(registry.RegisterConcept({ id = "person", aliases = { "bob" } }))
assert(registry.RegisterPattern({
    id = "inspect",
    match = {
        { kind = "concept", id = "person", capture = "subject" },
        {
            kind = "any_phrase",
            minTokens = 2,
            maxTokens = 3,
            capture = "target",
        },
    },
    emit = {
        intent = "inspect",
        actor = "$capture.subject.id",
        object = "$capture.target.text",
    },
}))
local ir = semantics.Parse("bob medical supplies", { enableFuzzy = false })
assertEqual(ir.intent, "inspect", "parser intent")
assertEqual(ir.actor, "person", "parser actor")
assertEqual(ir.object, "medical supplies", "parser phrase")
assertEqual(ir.diagnostics.noMatch, false, "parser diagnostics")

print("psychopatz semantic pattern matcher: ok")
