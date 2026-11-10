-- Minimal standalone semantic facade used only when the Project Zomboid
-- runtime semantic catalog is not present (for example, from a wheel).
-- In-tree workers resolve the richer mod-runtime module first.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}
local Semantics = PsychopatzCore.Semantics

local function normalized(text)
    text = tostring(text or "")
    text = string.lower(text)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

function Semantics.Parse(text, _options)
    local normalizedText = normalized(text)
    local intent = "UNKNOWN"
    local speechAct = "UNKNOWN"
    local pattern = "standalone.unknown"
    if normalizedText == "hello"
        or normalizedText == "hi"
        or normalizedText == "hey"
    then
        intent = "GREET"
        speechAct = "GREET"
        pattern = "standalone.greeting"
    elseif string.find(normalizedText, "what is your name", 1, true)
        or string.find(normalizedText, "whats your name", 1, true)
        or string.find(normalizedText, "who are you", 1, true)
    then
        intent = "ASK_IDENTITY"
        speechAct = "QUESTION"
        pattern = "standalone.ask_identity"
    end
    return {
        schemaVersion = 1,
        kind = "utterance",
        intent = intent,
        speechAct = speechAct,
        confidence = intent == "UNKNOWN" and 0 or 1,
        diagnostics = {
            source = "standalone_core_fallback",
            pattern = pattern,
        },
        provenance = { provider = "PsychopatzCore" },
        rawText = tostring(text or ""),
        normalizedText = normalizedText,
    }
end

return Semantics
