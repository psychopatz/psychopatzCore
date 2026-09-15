-- Reusable Build 42 custom translation catalog manager.
--
-- Native Project Zomboid translation loading only discovers the engine's
-- canonical domain files. This manager deliberately keeps custom catalogs
-- outside that namespace, while using getModFileReader for packaged mod data.
PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Manager = type(CustomTranslationManager) == "table"
    and CustomTranslationManager or {}

CustomTranslationManager = Manager
Core.CustomTranslationManager = Manager

Manager.Data = type(Manager.Data) == "table" and Manager.Data or {}
Manager.Systems = type(Manager.Systems) == "table" and Manager.Systems or {}
Manager.Diagnostics = type(Manager.Diagnostics) == "table"
    and Manager.Diagnostics or {}
Manager._handles = type(Manager._handles) == "table"
    and Manager._handles or {}
Manager._languageOverride = Manager._languageOverride
Manager._initialized = Manager._initialized == true
Manager._bootBound = Manager._bootBound == true

local ENGLISH = "EN"
local MAX_FILE_BYTES = 1048576
local MAX_ENTRIES = 4096
local MAX_KEY_LENGTH = 160

local function log(level, message)
    local prefix = "[PsychopatzCore][CustomTranslationManager]["
        .. tostring(level) .. "] "
    if print then print(prefix .. tostring(message)) end
end

local function validIdentifier(value)
    return type(value) == "string"
        and #value > 0
        and #value <= 96
        and string.match(value, "^[%w_%-%.]+$") ~= nil
end

local function validBasePath(value)
    if type(value) ~= "string" or #value == 0 or #value > 192 then
        return false
    end
    if string.sub(value, 1, 1) == "/"
        or string.find(value, "..", 1, true)
        or string.find(value, "//", 1, true)
    then
        return false
    end
    return string.match(value, "^[%w_%-%./]+$") ~= nil
end

local function trimTrailingSlash(value)
    while #value > 0 and string.sub(value, -1) == "/" do
        value = string.sub(value, 1, -2)
    end
    return value
end

local function normalizeLanguage(value)
    value = tostring(value or "")
    value = string.upper(value)
    if value == "" or string.find(value, "..", 1, true)
        or string.match(value, "^[%w_%-]+$") == nil
    then
        return ENGLISH
    end
    return value
end

local function activeLanguage()
    if Manager._languageOverride then
        return Manager._languageOverride
    end
    if not Translator or not Translator.getLanguage then return ENGLISH end
    local ok, value = pcall(function()
        local language = Translator.getLanguage()
        return language and language:toString() or nil
    end)
    if not ok then return ENGLISH end
    return normalizeLanguage(value)
end

local function invalidateLoadedCatalogs()
    Manager.Data = {}
    Manager.Diagnostics = {}
    for _, systems in pairs(Manager.Systems) do
        for _, source in pairs(systems) do
            source._state = nil
            source._language = nil
        end
    end
end

local function registrationFrom(first, second, third)
    local source = first
    if type(first) ~= "table" then
        -- Positional form is provided for small future mods:
        -- registerSystem("ModID", "System", "media/translation")
        source = { modID = first, systemName = second, basePath = third }
    end
    if type(source) ~= "table"
        or not validIdentifier(source.modID)
        or not validIdentifier(source.systemName)
        or not validBasePath(source.basePath)
    then
        return nil, "invalid_registration"
    end
    return {
        modID = source.modID,
        systemName = source.systemName,
        basePath = trimTrailingSlash(source.basePath),
    }
end

local function systemKey(modID, systemName)
    return modID .. ":" .. systemName
end

-- Core catalogs use one directory per system:
--   media/translation/<LANG>/<SYSTEM>/<SYSTEM>.json
-- The flat path remains a read-only compatibility fallback for existing mods
-- that have not migrated yet.
local function pathFor(source, language)
    return source.basePath .. "/" .. language .. "/"
        .. source.systemName .. "/" .. source.systemName .. ".json"
end

local function legacyPathFor(source, language)
    return source.basePath .. "/" .. language .. "/"
        .. source.systemName .. ".json"
end

local function readText(modID, path)
    if type(getModFileReader) ~= "function" then
        return nil, "getModFileReader_unavailable"
    end

    local ok, reader = pcall(getModFileReader, modID, path, false)
    if not ok then return nil, "getModFileReader_failed" end
    if not reader then return nil, "file_missing:" .. path end

    local lines = {}
    local totalBytes = 0
    local readOK, readResult = pcall(function()
        local line = reader:readLine()
        while line ~= nil do
            line = tostring(line)
            totalBytes = totalBytes + #line + 1
            if totalBytes > MAX_FILE_BYTES then
                error("file_too_large")
            end
            lines[#lines + 1] = line
            line = reader:readLine()
        end
        return table.concat(lines, "\n")
    end)

    -- Close even when readLine throws. This is the important packaged-file
    -- lifetime boundary: only the decoded result survives this function.
    pcall(function() reader:close() end)

    if not readOK then return nil, tostring(readResult) end
    return readResult
end

local function decodeCatalog(raw, path)
    if type(raw) ~= "string" then return nil, "json_text_missing:" .. path end
    local value, reason = Json.Decode(raw, {
        maxString = MAX_FILE_BYTES,
        maxDepth = 4,
        maxCollection = MAX_ENTRIES,
        preserveNull = true,
    })
    if type(value) ~= "table" then
        return nil, "json_root_must_be_object:" .. tostring(reason or path)
    end

    local count = 0
    for key, text in pairs(value) do
        count = count + 1
        if count > MAX_ENTRIES then return nil, "too_many_entries:" .. path end
        if type(key) ~= "string" or #key == 0 or #key > MAX_KEY_LENGTH then
            return nil, "invalid_key:" .. path
        end
        if type(text) ~= "string" or text == "" then
            return nil, "translation_values_must_be_nonempty_strings:" .. key
        end
    end
    return value
end

local function isMissingReason(reason)
    return type(reason) == "string"
        and string.sub(reason, 1, 13) == "file_missing:"
end

local function readCatalog(source, language)
    local nestedPath = pathFor(source, language)
    local raw, readReason = readText(source.modID, nestedPath)
    if raw then
        local catalog, decodeReason = decodeCatalog(raw, nestedPath)
        return catalog, decodeReason, nestedPath
    end

    -- Keep old flat catalogs working for external mods while new Core-owned
    -- catalogs use the clearer per-system directory layout.
    if isMissingReason(readReason) then
        local legacyPath = legacyPathFor(source, language)
        if legacyPath ~= nestedPath then
            raw, readReason = readText(source.modID, legacyPath)
            if raw then
                local catalog, decodeReason = decodeCatalog(raw, legacyPath)
                return catalog, decodeReason, legacyPath
            end
            return nil, readReason, legacyPath
        end
    end

    return nil, readReason, nestedPath
end

local function dataFor(modID)
    local data = Manager.Data[modID]
    if not data then
        data = {}
        Manager.Data[modID] = data
    end
    return data
end

local function setDiagnostic(source, values)
    Manager.Diagnostics[systemKey(source.modID, source.systemName)] = values
end

local function loadSystem(source)
    if source._state == "loaded" then
        return true, Manager.Data[source.modID]
            and Manager.Data[source.modID][source.systemName]
    end
    if source._state == "loading" then return false, "recursive_load" end
    source._state = "loading"

    local language = activeLanguage()
    local english, englishReason, englishPath = readCatalog(source, ENGLISH)
    if not english then
        source._state = "error"
        setDiagnostic(source, {
            state = "error",
            language = language,
            englishPath = englishPath or pathFor(source, ENGLISH),
            reason = englishReason,
        })
        log("ERROR", "Unable to load " .. systemKey(source.modID,
            source.systemName) .. ": " .. tostring(englishReason))
        return false, englishReason
    end

    -- Merge into a new table. The source tables are local and are not stored,
    -- so the cache retains only the active-language result plus EN fallback.
    local resolved = {}
    for key, text in pairs(english) do resolved[key] = text end

    local localizedReason
    local localizedPath
    local usedEnglishFallback = false
    if language ~= ENGLISH then
        local localized, reason, path = readCatalog(source, language)
        localizedPath = path
        if localized then
            for key, text in pairs(localized) do resolved[key] = text end
        else
            localizedReason = reason
            usedEnglishFallback = true
        end
    end

    dataFor(source.modID)[source.systemName] = resolved
    source._state = "loaded"
    source._language = language
    setDiagnostic(source, {
        state = "loaded",
        language = language,
        englishPath = englishPath or pathFor(source, ENGLISH),
        localizedPath = localizedPath or pathFor(source, language),
        usedEnglishFallback = usedEnglishFallback,
        localizedReason = localizedReason,
        entryCount = 0,
    })
    for _, _ in pairs(resolved) do
        Manager.Diagnostics[systemKey(source.modID, source.systemName)].entryCount =
            Manager.Diagnostics[systemKey(source.modID, source.systemName)].entryCount + 1
    end
    return true, resolved
end

local function makeHandle(source)
    local key = systemKey(source.modID, source.systemName)
    if Manager._handles[key] then return Manager._handles[key] end
    local handle = {
        modID = source.modID,
        systemName = source.systemName,
    }
    function handle:get(keyName, fallback)
        return Manager.get(self.modID, self.systemName, keyName, fallback)
    end
    function handle:load()
        return Manager.load(self.modID, self.systemName)
    end
    Manager._handles[key] = handle
    return handle
end

function Manager.getLanguage()
    return activeLanguage()
end

function Manager.setLanguageOverride(language)
    if language == nil or tostring(language) == "" then
        Manager._languageOverride = nil
        invalidateLoadedCatalogs()
        return activeLanguage()
    end

    language = normalizeLanguage(language)
    Manager._languageOverride = language
    invalidateLoadedCatalogs()
    return language
end

function Manager.clearLanguageOverride()
    return Manager.setLanguageOverride(nil)
end

function Manager.getLanguageOverride()
    return Manager._languageOverride
end

function Manager.registerSystem(first, second, third)
    local source, reason = registrationFrom(first, second, third)
    if not source then
        log("ERROR", "Registration rejected: " .. tostring(reason))
        return nil, reason
    end

    local systems = Manager.Systems[source.modID]
    if not systems then
        systems = {}
        Manager.Systems[source.modID] = systems
    end
    local existing = systems[source.systemName]
    if existing then
        if existing.basePath ~= source.basePath then
            log("ERROR", "Conflicting registration for "
                .. systemKey(source.modID, source.systemName))
            return nil, "conflicting_registration"
        end
        return makeHandle(existing)
    end

    systems[source.systemName] = source
    local handle = makeHandle(source)
    return handle
end

function Manager.forMod(modID)
    if not validIdentifier(modID) then
        log("ERROR", "Invalid mod scope: " .. tostring(modID))
        return nil, "invalid_mod_id"
    end

    local scope = {
        modID = modID,
    }

    function scope.registerSystem(systemName, basePath)
        return Manager.registerSystem({
            modID = modID,
            systemName = systemName,
            basePath = basePath,
        })
    end

    function scope.get(systemName, keyName, fallback)
        return Manager.get(modID, systemName, keyName, fallback)
    end

    function scope.load(systemName)
        return Manager.load(modID, systemName)
    end

    return scope
end

function Manager.load(modID, systemName)
    local systems = Manager.Systems[modID]
    local source = systems and systems[systemName] or nil
    if not source then return nil, "system_not_registered" end
    return loadSystem(source)
end

function Manager.get(modID, systemName, keyName, fallback)
    if type(keyName) ~= "string" or keyName == "" then
        return fallback or ""
    end
    local systems = Manager.Systems[modID]
    local source = systems and systems[systemName] or nil
    if source and not source._state then loadSystem(source) end
    local data = Manager.Data[modID]
    local catalog = data and data[systemName] or nil
    local value = catalog and catalog[keyName] or nil
    if type(value) == "string" and value ~= "" then return value end
    return fallback or keyName
end

function Manager.Initialize()
    if Manager._initialized then return true end
    Manager._initialized = true
    -- Catalogs remain lazy.  Registration is safe during shared boot, while
    -- the first client-side lookup loads only the system that is actually used.
    return true
end

if not Manager._bootBound and Events and Events.OnGameBoot
    and Events.OnGameBoot.Add
then
    Events.OnGameBoot.Add(function() Manager.Initialize() end)
    Manager._bootBound = true
end

return Manager
