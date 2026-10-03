local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local VERSIONED_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
package.path = VERSIONED_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;" .. package.path

local loadOrder = {}
local function stub(name, value)
    package.preload[name] = function()
        loadOrder[#loadOrder + 1] = name
        return value or true
    end
end

local foundation = {
    "PsychopatzCore/Semantics/PsychopatzSemantic",
    "PsychopatzCore/Runtime/PC_RuntimeRole",
    "PsychopatzCore/Collections/PC_RingBuffer",
    "PsychopatzCore/Events/PC_EventBus",
    "PsychopatzCore/Translation/PsychopatzCustomTranslationManager",
    "PsychopatzCore/Translation/PsychopatzCoreTranslation",
    "PsychopatzCore/Conversation/PsychopatzSocialFlavor",
    "PsychopatzCore/Conversation/PsychopatzNameParts",
    "PsychopatzCore/Voice/PsychopatzVoiceGateway",
    "PsychopatzCore/Journal/PC_JournalService",
    "PsychopatzCore/Radio/PC_RadioDeviceState",
    "PsychopatzCore/World/PC_GridRegion",
    "PsychopatzCore/World/PC_GridRegionEditor",
    "PsychopatzCore/World/PsychopatzSquareRules",
    "PsychopatzCore/World/PC_ZoneRegistry",
}
for _, name in ipairs(foundation) do stub(name) end

local profilerCalls = 0
local bridgeCalls = 0
stub("PsychopatzCore/Profiler/PsychopatzProfilerBootstrap", {
    Initialize = function() profilerCalls = profilerCalls + 1 end,
})
stub("PsychopatzCore/Bridge/PsychopatzBridgeBootstrap", {
    Initialize = function() bridgeCalls = bridgeCalls + 1 end,
})

local features = {
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector",
    "PsychopatzCore/Debug/PsychopatzDebug",
    "PsychopatzCore/Debug/PsychopatzDebugSettings",
    "PsychopatzCore/Translation/PsychopatzCoreTranslationDiagnostics",
    "PsychopatzCore/Debug/PsychopatzDebugTrace",
    "PsychopatzCore/Radio/RadioFrequencies/PsychopatzRadioFrequencies",
    "PsychopatzCore/Radio/CustomChannels/PsychopatzCustomRadio",
    "PsychopatzCore/Traits/PsychopatzTraitRegistry",
    "PsychopatzCore/Traits/PsychopatzTraitRecovery",
}
for _, name in ipairs(features) do stub(name) end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"

assert(Core == PsychopatzCore, "shared init returned a different Core table")
assert(Core.VERSION == "0.5.0", "core version was not initialized")
assert(Core.COMMAND_MODULE == "PsychopatzCore", "command module was not initialized")
assert(profilerCalls == 1, "profiler bootstrap was not initialized once")
assert(bridgeCalls == 1, "bridge bootstrap was not initialized once")

local numericPlayer = {
    getSteamID = function() return 1234 end,
    getUsername = function() return "Other" end,
}
assert(Core.GetSafeSteamID(numericPlayer) == "1234",
    "numeric Steam ID normalization changed")
local owner = {
    getSteamID = function() return Core.OWNER_STEAM_ID end,
    getUsername = function() return "Other" end,
}
assert(Core.IsOwner(owner), "owner authorization changed")

for index, name in ipairs(foundation) do
    assert(loadOrder[index] == name,
        "foundation load order changed at " .. tostring(index))
end
local bootstrapStart = #foundation + 1
assert(loadOrder[bootstrapStart] ==
    "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap",
    "profiler bootstrap load order changed")
assert(loadOrder[bootstrapStart + 1] ==
    "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap",
    "bridge bootstrap load order changed")
local featureStart = bootstrapStart + 2
for index, name in ipairs(features) do
    assert(loadOrder[featureStart + index - 1] == name,
        "feature load order changed at " .. tostring(index))
end

print("psychopatz core composition: ok")
