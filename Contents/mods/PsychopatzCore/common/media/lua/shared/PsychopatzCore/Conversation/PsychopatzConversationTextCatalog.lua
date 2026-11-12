-- Shared strict flat-JSON conversation translation loader for Build 42.20.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Loader = PsychopatzCore.Conversation.TextCatalog or {}
PsychopatzCore.Conversation.TextCatalog = Loader
Loader.cache = Loader.cache or {}
Loader.diagnostics = Loader.diagnostics or {}
Loader.Internal = Loader.Internal or {}
Loader.Internal.MAX_TRANSLATION_BYTES = 1048576
Loader.Internal.MAX_TRANSLATION_LINES = 1048576

require "PsychopatzCore/Conversation/PsychopatzConversationTextCatalog_Decode"
require "PsychopatzCore/Conversation/PsychopatzConversationTextCatalog_Source"

function Loader.EnsureSource(source, requiredKeys)
    local english, reason = Loader.Load(source, "EN")
    if not english then
        Loader.diagnostics[source and source.domain or "unknown"] = {
            valid = false, errors = { reason },
        }
        return false, { reason }
    end
    local errors = {}
    for _, key in ipairs(requiredKeys or {}) do
        if type(english[key]) ~= "string" or english[key] == "" then
            errors[#errors + 1] = "missing EN key " .. tostring(key)
        end
    end
    if #errors > 0 then
        Loader.diagnostics[source.domain] = { valid = false, errors = errors }
        return false, errors
    end
    local language = Loader.GetLanguage()
    local localized = english
    local localizedReason
    local usedFallback = false
    local missingLocalizedKeys = {}
    if language ~= "EN" then
        local candidate
        candidate, localizedReason = Loader.Load(source, language)
        localized = {}
        for key, value in pairs(english) do localized[key] = value end
        if candidate then
            for key, value in pairs(candidate) do
                if type(value) == "string" and value ~= "" then
                    localized[key] = value
                end
            end
        else
            usedFallback = true
        end
        for _, key in ipairs(requiredKeys or {}) do
            if not candidate or type(candidate[key]) ~= "string"
                or candidate[key] == ""
            then
                missingLocalizedKeys[#missingLocalizedKeys + 1] =
                    "missing " .. language .. " key " .. tostring(key)
            end
        end
        if #missingLocalizedKeys > 0 then usedFallback = true end
    end
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    if text and text.RegisterTable then
        text.RegisterTable(source.domain, "EN", english)
        if language ~= "EN" then text.RegisterTable(source.domain, language, localized) end
    end
    Loader.diagnostics[source.domain] = {
        valid = true,
        language = language,
        path = Loader.Internal.ReplaceLanguage(source.pathPattern, language),
        fallbackPath = Loader.Internal.ReplaceLanguage(source.pathPattern, "EN"),
        usedFallback = usedFallback,
        localizedError = localizedReason,
        missingLocalizedKeys = missingLocalizedKeys,
    }
    return true, localized
end

function Loader.Payload(source, key, args)
    return { key = key, domain = source and source.domain, args = args }
end

function Loader.Reset()
    Loader.cache = {}
    Loader.diagnostics = {}
end

return Loader
