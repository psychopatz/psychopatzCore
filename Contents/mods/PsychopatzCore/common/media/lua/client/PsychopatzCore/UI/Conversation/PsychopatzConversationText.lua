PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text or {}
Conversation.Text = Text
Text.domains = Text.domains or {}
Text.tables = Text.tables or {}
Text.fallbacks = Text.fallbacks or {}
local CoreTranslation = PsychopatzCore.Translation

local function copyArgs(values)
    local output = {}
    local key
    local value
    for key, value in pairs(type(values) == "table" and values or {}) do
        output[key] = value
    end
    return output
end

local function languageCode()
    if Translator and Translator.getLanguage and Translator.getLanguage() then
        return Translator.getLanguage():toString()
    end
    return "EN"
end

local function tableName(domain, language)
    return "PsychopatzConversation_Text_"
        .. tostring(domain)
        .. "_"
        .. tostring(language)
end

local function domainTable(domain, language)
    local registered = Text.tables[domain]
    if registered and type(registered[language]) == "table" then
        return registered[language]
    end
    return rawget(_G, tableName(domain, language))
end

function Text.RegisterDomain(domain)
    domain = tostring(domain or "")
    if domain == "" then return false end
    local index
    for index = 1, #Text.domains do
        if Text.domains[index] == domain then return domain end
    end
    Text.domains[#Text.domains + 1] = domain
    return domain
end

function Text.RegisterTable(domain, language, values)
    if type(values) ~= "table" then return false end
    domain = Text.RegisterDomain(domain)
    if not domain then return false end
    language = tostring(language or "EN")
    Text.tables[domain] = Text.tables[domain] or {}
    Text.tables[domain][language] = values
    rawset(_G, tableName(domain, language), values)
    return values
end

-- Register a presentation fallback for a keyed message.  Translations and
-- explicit payload fallbacks still win; this last-resort registry exists so
-- history written by an older build can remain readable after a vocabulary
-- or translation source is temporarily unavailable.
function Text.RegisterFallback(key, fallback)
    key = tostring(key or "")
    fallback = tostring(fallback or "")
    if key == "" or fallback == "" then return false end
    Text.fallbacks[key] = fallback
    return fallback
end

function Text.GetFallback(key)
    return Text.fallbacks[tostring(key or "")]
end

function Text.Payload(value, fallback)
    if type(value) == "table" then
        return {
            key = value.key,
            domain = value.domain,
            args = copyArgs(value.args),
            text = value.text,
            fallback = value.fallback or fallback,
            delayMs = value.delayMs,
            style = value.style,
        }
    end
    if type(value) == "string" then
        return { key = value, fallback = fallback }
    end
    return { text = tostring(value or fallback or "") }
end

local function format(value, args)
    local output = tostring(value or "")
    local key
    local replacement
    for key, replacement in pairs(type(args) == "table" and args or {}) do
        if type(key) == "number" then
            output = string.gsub(output, "%%" .. tostring(key), function()
                return tostring(replacement)
            end)
        else
            output = string.gsub(
                output,
                "{" .. tostring(key) .. "}",
                function() return tostring(replacement) end
            )
        end
    end
    return output
end

local function translate(key, args)
    if not key or key == "" then return nil end
    if CoreTranslation and CoreTranslation.IsCoreKey
        and CoreTranslation.IsCoreKey(key)
    then
        local value = CoreTranslation.GetKey(key, nil)
        if value and value ~= "" and value ~= key then
            return format(value, args)
        end
        return nil
    end
    if not getText then return nil end
    args = args or {}
    local count = #args
    if count == 0 then return getText(key) end
    if count == 1 then return getText(key, tostring(args[1])) end
    if count == 2 then return getText(key, tostring(args[1]), tostring(args[2])) end
    if count == 3 then
        return getText(key, tostring(args[1]), tostring(args[2]), tostring(args[3]))
    end
    return getText(
        key,
        tostring(args[1]),
        tostring(args[2]),
        tostring(args[3]),
        tostring(args[4])
    )
end

local function domainValue(key, domain)
    local language = languageCode()
    local function resolveFrom(selectedDomain, selectedLanguage)
        local values = domainTable(selectedDomain, selectedLanguage)
        local value = values and values[key] or nil
        return type(value) == "string" and value ~= "" and value or nil
    end
    local function resolveAndAudit(selectedDomain)
        local value = resolveFrom(selectedDomain, language)
        if value and language ~= "EN" then
            local english = resolveFrom(selectedDomain, "EN")
            if english and string.find(english, "%s") ~= nil
                and value == english
                and CoreTranslation
                and type(CoreTranslation.RecordAudit) == "function"
            then
                CoreTranslation.RecordAudit(
                    "ProjectHoomans", "Conversation", key,
                    "english_value_fallback", language,
                    "domain=" .. tostring(selectedDomain)
                )
            end
        end
        return value
    end
    if domain then
        local value = resolveAndAudit(domain)
        if not value and language ~= "EN" then value = resolveFrom(domain, "EN") end
        if value then return value end
    end
    local index
    for index = 1, #Text.domains do
        local selected = Text.domains[index]
        if selected ~= domain then
            local value = resolveAndAudit(selected)
            if not value and language ~= "EN" then
                value = resolveFrom(selected, "EN")
            end
            if value then return value end
        end
    end
    return nil
end

function Text.Resolve(value, fallback)
    local payload = Text.Payload(value, fallback)
    local translated = translate(payload.key, payload.args)
    if translated and translated ~= "" and translated ~= payload.key then
        return translated
    end
    translated = domainValue(payload.key, payload.domain)
    if translated then return format(translated, payload.args) end
    if payload.text and payload.text ~= "" then return tostring(payload.text) end
    if payload.fallback and payload.fallback ~= "" then return tostring(payload.fallback) end
    local registeredFallback = Text.GetFallback(payload.key)
    if registeredFallback then
        return format(registeredFallback, payload.args)
    end
    return tostring(payload.key or "")
end

function Text.ToRecord(value)
    local payload = Text.Payload(value)
    local rawText
    local fallback = payload.fallback
    if not payload.key then
        rawText = payload.text
    end
    return {
        k = payload.key,
        d = payload.domain,
        a = copyArgs(payload.args),
        x = rawText,
        -- Keep the fallback with keyed history records.  It is only used when
        -- the active translation/domain cannot resolve the key, so translated
        -- builds retain precedence while an untranslated save remains human
        -- readable.  Older records without f are covered by RegisterFallback.
        f = fallback,
    }
end

function Text.FromRecord(record)
    return {
        key = record and record.k or nil,
        domain = record and record.d or nil,
        args = copyArgs(record and record.a or nil),
        text = record and record.x or nil,
        fallback = record and record.f or nil,
    }
end

return Text
