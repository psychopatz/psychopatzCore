local ROOT = "Contents/mods/PsychopatzCore/"
local SHARED = ROOT .. "common/media/lua/shared/"
package.path = SHARED .. "?.lua;" .. package.path

PsychopatzCore = {}
CustomTranslationManager = nil

local language = "TL"
local reads = 0
local readersClosed = 0
local files = {
    ["media/translation/manifests/Test.json"] =
        '{"version":1,"languages":{"EN":["EN/Test/A.json","EN/Test/B.json"],"TL":["TL/Test/A.json","TL/Test/B.json"]}}',
    ["media/translation/EN/Test/A.json"] =
        '{"hello":"Hello","shared":"Shared","missing":"English fallback"}',
    ["media/translation/EN/Test/B.json"] =
        '{"bye":"Goodbye"}',
    ["media/translation/TL/Test/A.json"] =
        '{"hello":"Kumusta","shared":"Pareho"}',
    ["media/translation/TL/Test/B.json"] =
        '{"bye":"Paalam"}',
    ["media/translation/manifests/Duplicate.json"] =
        '{"version":1,"languages":{"EN":["EN/Test/A.json","EN/Test/Duplicate.json"]}}',
    ["media/translation/EN/Test/Duplicate.json"] =
        '{"hello":"Another hello"}',
    ["media/translation/manifests/Traversal.json"] =
        '{"version":1,"languages":{"EN":["../escape.json"]}}',
    ["media/translation/manifests/Missing.json"] =
        '{"version":1,"languages":{"EN":["EN/Test/Absent.json"]}}',
    ["media/translation/manifests/Malformed.json"] =
        '{"languages":{"EN":["EN/Test/A.json"]}}',
}

Translator = {
    getLanguage = function()
        return { toString = function() return language end }
    end,
}

getModFileReader = function(modID, path)
    if modID ~= "ManifestMod" then return nil end
    local text = files[path]
    if not text then return nil end
    reads = reads + 1
    local index = 0
    local closed = false
    return {
        readLine = function()
            index = index + 1
            local line = string.match(text, "([^\n]*)\n?", 1)
            local start = 1
            local current = 1
            while current < index and start <= #text do
                local nextStart = string.find(text, "\n", start, true)
                if not nextStart then return nil end
                start = nextStart + 1
                current = current + 1
            end
            if start > #text then return nil end
            line = string.match(string.sub(text, start), "^([^\n]*)")
            return line
        end,
        close = function()
            if not closed then
                closed = true
                readersClosed = readersClosed + 1
            end
        end,
    }
end

local Manager = require
    "PsychopatzCore/Translation/PsychopatzCustomTranslationManager"

local handle, reason = Manager.registerSystem({
    modID = "ManifestMod",
    systemName = "Conversation",
    basePath = "media/translation",
    manifestPath = "manifests/Test.json",
})
assert(handle and not reason, "explicit manifest registration succeeds")
assert(Manager.Data.ManifestMod == nil, "manifest catalog stays lazy")
Manager.setLanguageOverride("TL")

assert(Manager.get("ManifestMod", "Conversation", "hello") == "Kumusta",
    "manifest shards merge in Tagalog")
local warmedReads = reads
assert(Manager.get("ManifestMod", "Conversation", "hello") == "Kumusta"
    and reads == warmedReads,
    "warmed manifest lookup performs no extra reader IO")
local diagnostics = Manager.Diagnostics["ManifestMod:Conversation"]
assert(diagnostics.manifestPath == "media/translation/manifests/Test.json"
    and diagnostics.shardCount == 2,
    "manifest diagnostics expose the explicit source and shard count")

Manager.SetTranslationAuditEnabled(true)
assert(Manager.get("ManifestMod", "Conversation", "missing")
    == "English fallback", "missing Tagalog keys use English fallback")
local audit = Manager.GetTranslationAuditSnapshot()
assert((audit.counts.english_key_fallback or 0) == 1,
    "missing localized key is audited as an English fallback")
local coverage = Manager.GetTranslationCoverageSnapshot("TL")
assert(coverage.counts.missing_key == 1
    and coverage.counts.extra_key == 0,
    "manifest coverage detects the missing localized key")

language = "EN"
Manager.setLanguageOverride("EN")
assert(Manager.get("ManifestMod", "Conversation", "hello") == "Hello",
    "language change invalidates the active shard cache")
assert(readersClosed > 0, "all manifest readers close after decoding")

local conflicting = Manager.registerSystem({
    modID = "ManifestMod",
    systemName = "Conversation",
    basePath = "media/translation",
    manifestPath = "manifests/Other.json",
})
assert(conflicting == nil, "conflicting manifest registration is rejected")

local function expectLoadFailure(systemName, manifestPath, expected)
    local registered = Manager.registerSystem({
        modID = "ManifestMod",
        systemName = systemName,
        basePath = "media/translation",
        manifestPath = manifestPath,
    })
    assert(registered, "failure fixture registration: " .. systemName)
    local loaded, loadReason = Manager.load("ManifestMod", systemName)
    assert(loaded == false and loadReason == expected,
        systemName .. " reports " .. expected .. " (got " .. tostring(loadReason) .. ")")
end

expectLoadFailure(
    "Malformed",
    "manifests/Malformed.json",
    "manifest_requires_version_1"
)
expectLoadFailure(
    "Traversal",
    "manifests/Traversal.json",
    "manifest_path_invalid:../escape.json"
)
expectLoadFailure(
    "Missing",
    "manifests/Missing.json",
    "file_missing:media/translation/EN/Test/Absent.json"
)
expectLoadFailure("Duplicate", "manifests/Duplicate.json", "duplicate_key:hello")

print("psychopatz_custom_translation_manifest_smoke: ok")
