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

local function isCoreKey(key)
    local translation = PsychopatzCore and PsychopatzCore.Translation
    return translation
        and type(translation.IsCoreKey) == "function"
        and translation.IsCoreKey(key) == true
end

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
        if not isCoreKey(key)
            and (type(english[key]) ~= "string" or english[key] == "")
        then
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
            if not isCoreKey(key)
                and (not candidate or type(candidate[key]) ~= "string"
                or candidate[key] == ""
                )
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

-- Validate either a file-backed dialogue source or a Core-owned translation
-- key set.  UI catalogs are registered through CoreTranslation and therefore
-- must not be forced through the semantic Conversation/Text loader.
function Loader.ValidateSource(source, requiredKeys)
    if source then return Loader.EnsureSource(source, requiredKeys) end
    local errors = {}
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    local translation = PsychopatzCore and PsychopatzCore.Translation or nil
    for _, key in ipairs(requiredKeys or {}) do
        local value
        if text and type(text.Resolve) == "function" then
            value = text.Resolve({ key = key })
        elseif translation and type(translation.GetKey) == "function" then
            value = translation.GetKey(key, nil)
        end
        if type(value) ~= "string" or value == "" or value == key then
            errors[#errors + 1] = "missing Core translation key " .. tostring(key)
        end
    end
    if #errors > 0 then return false, errors end
    return true
end

function Loader.Payload(source, key, args)
    return { key = key, domain = source and source.domain, args = args }
end

function Loader.Reset()
    Loader.cache = {}
    Loader.diagnostics = {}
end

return Loader
