local ROOT = "Contents/mods/PsychopatzCore/"
local SHARED = ROOT .. "common/media/lua/shared/"
package.path = SHARED .. "?.lua;" .. package.path

PsychopatzCore = {}
CustomTranslationManager = nil
local language = "TL"
local readersClosed = 0

Translator = {
    getLanguage = function()
        return { toString = function() return language end }
    end,
}

Events = {
    OnGameBoot = {
        Add = function(callback) Events.boot = callback end,
    },
}

getText = function(key) return key end

getModFileReader = function(modID, path)
    if modID ~= "PsychopatzCore" then return nil end
    local file = io.open(ROOT .. "common/" .. path, "r")
    if not file then return nil end
    return {
        readLine = function() return file:read("*l") end,
        close = function()
            if file then file:close(); file = nil; readersClosed = readersClosed + 1 end
        end,
    }
end

local Translation = require "PsychopatzCore/Translation/PsychopatzCoreTranslation"
local Manager = CustomTranslationManager
assert(require "CustomTranslationManager" == Manager,
    "short compatibility entry point returns the same manager")

assert(Manager.Data.PsychopatzCore == nil,
    "catalogs are lazy before the first lookup")
assert(Events.boot, "boot initializes the manager")
Events.boot()
assert(Manager._initialized == true, "boot callback initializes the manager")

assert(Manager.getLanguage() == "TL",
    "the manager follows the native language selector")
assert(Translation.Get("Conversation", "UI_PsychopatzConversation_Goodbye")
    == "Paalam.", "Tagalog catalog resolves through the Core facade")
local conversationDiagnostics = Manager.Diagnostics["PsychopatzCore:Conversation"]
assert(conversationDiagnostics
    and conversationDiagnostics.englishPath
        == "media/translation/EN/Conversation/Conversation.json",
    "Core uses the per-system English catalog path")
assert(conversationDiagnostics.localizedPath
    == "media/translation/TL/Conversation/Conversation.json",
    "Core uses the per-system Tagalog catalog path")
assert(Translation.Get("Core", "UI_PsychopatzCore_SettingsTitle")
    == "Psychopatz Core", "Core catalog resolves shared settings text")

language = "FR"
-- PZ recreates Lua state after changing the native language. In this isolated
-- test, clear the cache to model that reset while keeping the native selector
-- as the source of truth.
Manager.clearLanguageOverride()
assert(Manager.getLanguage() == "FR",
    "the manager follows a different native language selection")
assert(Translation.Get("Conversation", "UI_PsychopatzConversation_Goodbye")
    == "Goodbye.", "unsupported language falls back to English")
assert(Translation.Get("Conversation", "missing.key", "Visible fallback")
    == "Visible fallback", "caller fallback remains available")
assert(Manager.Data.PsychopatzCore.Conversation ~= nil,
    "only the requested system is loaded")
assert(Manager.Data.PsychopatzCore.Profiler == nil,
    "unused systems stay unloaded")
assert(readersClosed >= 3,
    "catalog readers close after each English/localized read")

local scoped = Manager.forMod("PsychopatzCore")
assert(scoped, "mod-scoped facade is available")
local scopedConversation = scoped.registerSystem(
    "Conversation", "media/translation")
assert(scopedConversation:get("UI_PsychopatzConversation_Goodbye")
    == "Goodbye.", "scoped facade keeps two-argument registration clean")

print("psychopatz_custom_core_translation_smoke: ok")
