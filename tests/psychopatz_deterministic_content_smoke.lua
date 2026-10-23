local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Content = require
    "PsychopatzCore/Content/PsychopatzDeterministicContent"

local catalog = {
    femaleFirst = { "Ada", "Bea" },
    maleFirst = { "Cal", "Dan" },
    surnames = { "North", "South" },
}
local first = Content.GenerateName({
    saveSeed = "save-a",
    identitySeed = "npc-a",
    gender = "female",
    namespace = "test.names",
}, catalog)
equal(first, Content.GenerateName({
    saveSeed = "save-a",
    identitySeed = "npc-a",
    gender = "female",
    namespace = "test.names",
}, catalog), "same inputs remain stable")
truthy(first == "Ada North" or first == "Bea North"
    or first == "Ada South" or first == "Bea South",
    "generated name uses the supplied catalog")
local changedSave = Content.GenerateName({
    saveSeed = "save-b",
    identitySeed = "npc-a",
    gender = "female",
    namespace = "test.names",
}, catalog)
truthy(changedSave ~= nil, "changed save seed still generates content")
equal(Content.ResolveSaveSeed({ world = { seedString = "world-a" } }),
    "world-a", "scenario world seed is accepted")
equal(Content.ResolveSaveSeed({ saveSeed = "explicit-a" }),
    "explicit-a", "explicit save seed takes precedence")

local factoryCalls = 0
SurvivorFactory = {
    FemaleForenames = { "CoreNativeAda" },
    MaleForenames = { "CoreNativeCal" },
    Surnames = { "CoreNativeNorth" },
    CreateSurvivor = function()
        factoryCalls = factoryCalls + 1
        error("deterministic content must not create a native survivor")
    end,
}
local nativeCatalog = Content.NativeNameCatalog()
equal(nativeCatalog.source, "project_zomboid_survivor_factory",
    "native catalog is reported")
local nativeName = Content.GenerateName({
    saveSeed = "save-a",
    identitySeed = "native-a",
    gender = "female",
    namespace = "test.native_names",
})
truthy(string.find(nativeName, "CoreNative", 1, true) ~= nil,
    "native catalog is used by the Core generator")
equal(factoryCalls, 0, "native catalog selection never creates a survivor")

print("psychopatz_deterministic_content_smoke: PASS")
