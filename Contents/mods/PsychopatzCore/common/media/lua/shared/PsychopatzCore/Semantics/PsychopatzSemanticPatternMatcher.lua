PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
Semantics.Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"

local PatternMatcher = Semantics.PatternMatcher or {}
Semantics.PatternMatcher = PatternMatcher

local Support = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher_Support"
local Rules = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher_Rules"
local Captures = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher_Captures"
local Match = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher_Match"

Match.Install(PatternMatcher, Rules, Captures, Support)

function PatternMatcher.ResolveEmit(value, captures)
    return Captures.resolveEmit(value, captures)
end

return PatternMatcher
