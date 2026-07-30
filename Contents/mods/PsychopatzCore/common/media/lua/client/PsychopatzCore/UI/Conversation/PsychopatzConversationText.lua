PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text or {}
Conversation.Text = Text
Text.domains = Text.domains or {}
Text.tables = Text.tables or {}

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

local function translate(key, args)
    if not getText or not key or key == "" then return nil end
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

local function domainValue(key, domain)
    local language = languageCode()
    local function resolveFrom(selectedDomain, selectedLanguage)
        local values = domainTable(selectedDomain, selectedLanguage)
        local value = values and values[key] or nil
        return type(value) == "string" and value ~= "" and value or nil
    end
    if domain then
        local value = resolveFrom(domain, language)
        if not value and language ~= "EN" then value = resolveFrom(domain, "EN") end
        if value then return value end
    end
    local index
    for index = 1, #Text.domains do
        local selected = Text.domains[index]
        if selected ~= domain then
            local value = resolveFrom(selected, language)
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
    return tostring(payload.key or "")
end

function Text.ToRecord(value)
    local payload = Text.Payload(value)
    local rawText
    local fallback
    if not payload.key then
        rawText = payload.text
        fallback = payload.fallback
    end
    return {
        k = payload.key,
        d = payload.domain,
        a = copyArgs(payload.args),
        x = rawText,
        -- Keyed messages stay key-and-argument only in persisted history.
        -- Fallback prose is a presentation concern and would duplicate every
        -- translated line in the save.
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
