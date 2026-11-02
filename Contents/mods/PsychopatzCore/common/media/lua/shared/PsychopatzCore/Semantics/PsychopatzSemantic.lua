PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics

Semantics.IR = require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
Semantics.Provider = require
    "PsychopatzCore/Semantics/PsychopatzSemanticProvider"
Semantics.DialogueState = require
    "PsychopatzCore/Semantics/PsychopatzSemanticDialogueState"
Semantics.Normalizer = require
    "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
Semantics.Registry = require
    "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
Semantics.SurfaceRecovery = require
    "PsychopatzCore/Semantics/PsychopatzSemanticSurfaceRecovery"
Semantics.Confidence = require
    "PsychopatzCore/Semantics/PsychopatzSemanticConfidence"
Semantics.Context = require
    "PsychopatzCore/Semantics/PsychopatzSemanticContext"
Semantics.FuzzyMatcher = require
    "PsychopatzCore/Semantics/PsychopatzSemanticFuzzyMatcher"
Semantics.ConceptMatcher = require
    "PsychopatzCore/Semantics/PsychopatzSemanticConceptMatcher"
Semantics.PatternMatcher = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher"
Semantics.Parser = require
    "PsychopatzCore/Semantics/PsychopatzSemanticParser"
Semantics.DialogueRouter = require
    "PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter"
Semantics.DialogueTurn = require
    "PsychopatzCore/Semantics/PsychopatzSemanticDialogueTurn"
Semantics.PackRegistry = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPackRegistry"

Semantics.VERSION = Semantics.VERSION or 1

-- Small convenience facade for domain modules. The underlying registries
-- remain available when a caller needs explicit ownership or diagnostics.
function Semantics.RegisterConcept(definition)
    return Semantics.Registry.RegisterConcept(definition)
end

function Semantics.RegisterSpeechAct(definition, metadata)
    return Semantics.Registry.RegisterSpeechAct(definition, metadata)
end

function Semantics.RegisterPattern(definition)
    return Semantics.Registry.RegisterPattern(definition)
end

function Semantics.Parse(text, options)
    return Semantics.Parser.Parse(text, options)
end

function Semantics.RegisterPack(spec)
    return Semantics.PackRegistry.RegisterPack(spec)
end

function Semantics.UnregisterPack(packID)
    return Semantics.PackRegistry.UnregisterPack(packID)
end

function Semantics.GetPack(packID)
    return Semantics.PackRegistry.GetPack(packID)
end

function Semantics.ListPacks()
    return Semantics.PackRegistry.ListPacks()
end

function Semantics.RegisterActionProvider(providerSpec)
    return Semantics.PackRegistry.RegisterActionProvider(providerSpec)
end

function Semantics.CollectActions(context, options)
    return Semantics.PackRegistry.CollectActions(context, options)
end

return Semantics
