-- Validation for explicit bounded custom-translation shard manifests.
--
-- The manager reads only paths named by this document. It never scans a
-- translation directory at runtime.
PsychopatzCore = PsychopatzCore or {}

local Manifest = {}
Manifest.VERSION = 1
Manifest.MAX_SHARDS = 32
Manifest.MAX_PATH_LENGTH = 192

local function safePath(value)
    if type(value) ~= "string"
        or #value == 0
        or #value > Manifest.MAX_PATH_LENGTH
        or string.sub(value, 1, 1) == "/"
        or string.find(value, "..", 1, true)
        or string.find(value, "//", 1, true)
        or string.find(value, "\\", 1, true)
        or string.match(value, "^[%w_%-%./]+$") == nil
        or string.sub(value, -5) ~= ".json"
    then
        return false
    end
    return true
end

function Manifest.IsSafePath(value)
    return safePath(value)
end

local function normalizeLanguage(value)
    value = tostring(value or "")
    value = string.upper(value)
    if value == "" or string.match(value, "^[%w_%-]+$") == nil then
        return nil
    end
    return value
end

function Manifest.Validate(value)
    if type(value) ~= "table" then
        return false, "manifest_must_be_object"
    end
    if tonumber(value.version) ~= Manifest.VERSION then
        return false, "manifest_requires_version_" .. tostring(Manifest.VERSION)
    end
    if type(value.languages) ~= "table" then
        return false, "manifest_requires_languages"
    end

    local output = {
        version = Manifest.VERSION,
        languages = {},
    }
    local language
    local shards
    local normalizedLanguage
    local seenLanguage = {}
    for language, shards in pairs(value.languages) do
        normalizedLanguage = normalizeLanguage(language)
        if not normalizedLanguage or seenLanguage[normalizedLanguage] then
            return false, "manifest_invalid_language"
        end
        seenLanguage[normalizedLanguage] = true
        if type(shards) ~= "table" or #shards == 0 then
            return false, "manifest_requires_shards:" .. tostring(language)
        end
        if #shards > Manifest.MAX_SHARDS then
            return false, "manifest_shard_limit:" .. normalizedLanguage
        end
        local normalizedShards = {}
        local seenPath = {}
        local index
        local path
        for index = 1, #shards do
            path = shards[index]
            if not safePath(path) then
                return false, "manifest_path_invalid:" .. tostring(path)
            end
            if seenPath[path] then
                return false, "manifest_duplicate_path:" .. path
            end
            seenPath[path] = true
            normalizedShards[#normalizedShards + 1] = path
        end
        table.sort(normalizedShards)
        output.languages[normalizedLanguage] = normalizedShards
    end

    if not output.languages.EN then
        return false, "manifest_requires_english"
    end
    return true, output
end

return Manifest
