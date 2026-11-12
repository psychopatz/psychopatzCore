PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Loader = PsychopatzCore.Conversation.TextCatalog or {}
local Internal = Loader.Internal or {}
Loader.Internal = Internal

function Loader.Source(spec)
    if type(spec) ~= "table" then return nil end
    local modID = tostring(spec.modID or "")
    local target = tostring(spec.target or "")
    if modID == "" or target == "" then return nil end
    if string.sub(target, 1, 1) == "/"
        or string.find(target, "..", 1, true)
    then
        return nil
    end
    local domain = tostring(spec.domain or "")
    if domain == "" then domain = string.gsub(target, "/", ".") end
    return {
        modID = modID,
        pathPattern = "media/translation/{language}/Conversation/Text/"
            .. target .. ".json",
        domain = domain,
    }
end

function Internal.ReplaceLanguage(pattern, language)
    return string.gsub(tostring(pattern or ""), "{language}", tostring(language))
end

local function readWithPZ(modID, path)
    if not getModFileReader then return nil end
    local reader = getModFileReader(modID, path, false)
    if not reader then return nil end
    local lines = {}
    local maxLines = Internal.MAX_TRANSLATION_LINES or 1048576
    for lineNumber = 1, maxLines + 1 do
        local line = reader:readLine()
        if line == nil then
            reader:close()
            return table.concat(lines, "\n")
        end
        if lineNumber > maxLines then
            reader:close()
            return nil, "translation file has too many lines"
        end
        lines[#lines + 1] = line
    end
    reader:close()
    return nil, "translation file has too many lines"
end

function Loader.GetLanguage()
    if Translator and Translator.getLanguage and Translator.getLanguage() then
        return tostring(Translator.getLanguage():toString())
    end
    return "EN"
end

function Loader.Load(source, language)
    if type(source) ~= "table" then return nil, "invalid_text_source" end
    language = tostring(language or "EN")
    local path = Internal.ReplaceLanguage(source.pathPattern, language)
    local cacheKey = table.concat({ source.modID, path }, "|")
    if Loader.cache[cacheKey] then return Loader.cache[cacheKey] end
    local raw, readReason = readWithPZ(source.modID, path)
    if not raw then
        return nil, readReason or "translation_file_missing:" .. path
    end
    local values, reason = Loader.Decode(raw)
    if not values then return nil, reason end
    Loader.cache[cacheKey] = values
    return values
end

return Loader
