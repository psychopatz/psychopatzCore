-- Normalize external semantic-provider payloads into the Core Semantic IR.
-- Providers may use snake_case wire keys, but the game only consumes the
-- bounded IR returned here after full validation.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
local Provider = Semantics.Provider or {}
Semantics.Provider = Provider

Provider.VERSION = 1

local function tableValue(value)
    return type(value) == "table" and value or {}
end

local function copyMap(value)
    local output = {}
    for key, item in pairs(tableValue(value)) do
        output[key] = item
    end
    return output
end

local function firstValue(primary, secondary)
    if primary ~= nil then return primary end
    return secondary
end

local function nestedPayload(payload)
    if type(payload) ~= "table" then return nil end
    if type(payload.semanticIR) == "table" then return payload.semanticIR end
    if type(payload.semantic_ir) == "table" then return payload.semantic_ir end
    if type(payload.ir) == "table" then return payload.ir end
    return payload
end

function Provider.Normalize(payload, context, options)
    context = tableValue(context)
    options = tableValue(options)
    local raw = nestedPayload(payload)
    if not raw then return nil, "semantic_provider_payload_required" end

    local rawProvenance = tableValue(raw.provenance)
    local diagnostics = copyMap(raw.diagnostics)
    diagnostics.providerNormalized = true

    local ir = IR.New({
        kind = type(raw.kind) == "string" and raw.kind or "utterance",
        rawText = firstValue(
            firstValue(raw.rawText, raw.raw_text),
            firstValue(context.rawText, context.raw_text)
        ),
        normalizedText = firstValue(
            firstValue(raw.normalizedText, raw.normalized_text),
            firstValue(context.normalizedText, context.normalized_text)
        ),
        intent = firstValue(raw.intent, raw.intent_id),
        speechAct = firstValue(raw.speechAct, raw.speech_act),
        action = firstValue(raw.action, raw.action_id),
        subject = firstValue(raw.subject, raw.subject_id),
        actor = firstValue(raw.actor, context.actor),
        recipient = firstValue(raw.recipient, context.recipient),
        target = firstValue(raw.target, context.target),
        object = firstValue(raw.object, context.object),
        source = firstValue(raw.source, context.sourceEntity),
        destination = firstValue(raw.destination, context.destination),
        slots = raw.slots,
        modifiers = raw.modifiers,
        emotionalState = firstValue(raw.emotionalState, raw.emotional_state),
        certainty = raw.certainty,
        socialContext = firstValue(raw.socialContext, raw.social_context),
        references = raw.references,
        confidence = firstValue(raw.confidence, context.confidence),
        confidenceBand = raw.confidenceBand,
        diagnostics = diagnostics,
        provenance = {
            provider = options.provider or rawProvenance.provider or "external",
            parser = options.parser or rawProvenance.parser
                or "semantic_provider",
            source = rawProvenance.source or options.source,
            pattern = rawProvenance.pattern,
        },
        analysis = raw.analysis,
        extensions = raw.extensions,
    })

    local valid, reason = IR.Validate(ir)
    if valid ~= true then return nil, reason or "invalid_semantic_ir" end
    return ir
end

Provider.FromTable = Provider.Normalize

return Provider
