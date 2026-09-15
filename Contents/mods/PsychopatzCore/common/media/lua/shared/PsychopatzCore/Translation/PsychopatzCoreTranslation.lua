-- Core-owned catalog registrations and lookup facade.
--
-- The reusable manager is mod-neutral.  This facade gives PsychopatzCore
-- stable system handles and routes only Core-owned keys to custom catalogs;
-- native PZ keys continue through getText().
require "PsychopatzCore/Translation/PsychopatzCustomTranslationManager"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Translation = Core.Translation or {}
Core.Translation = Translation

local Manager = CustomTranslationManager
local MOD_ID = "PsychopatzCore"
local BASE_PATH = "media/translation"

Translation.Systems = Translation.Systems or {}
Translation.KeyPrefixes = Translation.KeyPrefixes or {
    { prefix = "UI_PsychopatzConversation_", system = "Conversation" },
    { prefix = "UI_PsychopatzProfiler_", system = "Profiler" },
    { prefix = "UI_PsychopatzRegion_", system = "WorldRegion" },
    { prefix = "UI_PsychopatzInventory_", system = "Inventory" },
    { prefix = "UI_PsychopatzCore_CommandHub_", system = "CommandHub" },
    { prefix = "UI_PsychopatzCore_Theme_", system = "CommandHub" },
    { prefix = "UI_PsychopatzCore_", system = "Core" },
    { prefix = "ContextMenu_Psychopatz_", system = "Debug" },
    { prefix = "UI_PsychopatzDebug_", system = "Debug" },
    { prefix = "UI_PsychopatzDebugHub_", system = "Debug" },
    { prefix = "UI_PsychopatzDebugTrace_", system = "Debug" },
    { prefix = "UI_PsychopatzDebugSettings_", system = "Debug" },
    { prefix = "UI_PsychopatzObjectName_", system = "Debug" },
}

local systemNames = {
    "Core",
    "Conversation",
    "Debug",
    "CommandHub",
    "Inventory",
    "Profiler",
    "WorldRegion",
}

for _, systemName in ipairs(systemNames) do
    if not Translation.Systems[systemName] then
        Translation.Systems[systemName] = Manager.registerSystem({
            modID = MOD_ID,
            systemName = systemName,
            basePath = BASE_PATH,
        })
    end
end

function Translation.Get(systemName, key, fallback)
    local handle = Translation.Systems[systemName]
    if handle and type(handle.get) == "function" then
        return handle:get(key, fallback)
    end
    return fallback or key or ""
end

function Translation.SystemForKey(key)
    if type(key) ~= "string" then return nil end
    for _, mapping in ipairs(Translation.KeyPrefixes) do
        if string.sub(key, 1, #mapping.prefix) == mapping.prefix then
            return mapping.system
        end
    end
    return nil
end

function Translation.IsCoreKey(key)
    return Translation.SystemForKey(key) ~= nil
end

function Translation.GetKey(key, fallback)
    if type(key) ~= "string" or key == "" then
        return fallback or ""
    end
    local systemName = Translation.SystemForKey(key)
    if systemName then
        return Translation.Get(systemName, key, fallback)
    end
    if getText then
        local value = getText(key)
        if value and value ~= "" and value ~= key then return value end
    end
    return fallback or key or ""
end

function Translation.Format(systemName, key, fallback, args)
    local value = Translation.Get(systemName, key, fallback)
    if type(args) ~= "table" or #args == 0 then return value end
    local ok, formatted = pcall(string.format, value,
        args[1], args[2], args[3], args[4])
    return ok and formatted or value
end

function Translation.FormatKey(key, fallback, args)
    local systemName = Translation.SystemForKey(key)
    if not systemName then return fallback or key or "" end
    return Translation.Format(systemName, key, fallback, args)
end

return Translation
