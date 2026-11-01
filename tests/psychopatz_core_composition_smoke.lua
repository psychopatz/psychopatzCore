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

-- Stub heavy feature modules to observe whether they are eagerly loaded
local features = {
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector",
    "PsychopatzCore/Debug/PsychopatzDebug",
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
assert(Core.Capabilities ~= nil, "capabilities kernel was not initialized")

local numericPlayer = {
    getSteamID = function() return 1234 end,
    getUsername = function() return "Other" end,
}
assert(Core.GetSafeSteamID(numericPlayer) == "1234", "numeric Steam ID normalization changed")
local owner = {
    getSteamID = function() return Core.OWNER_STEAM_ID end,
    getUsername = function() return "Other" end,
}
assert(Core.IsOwner(owner), "owner authorization changed")

-- Inverted composition check: unrequested features must NOT have been loaded on boot
for _, featureMod in ipairs(features) do
    for _, loadedName in ipairs(loadOrder) do
        assert(loadedName ~= featureMod, "feature '" .. featureMod .. "' was eagerly loaded at boot!")
    end
end

-- Demand-driven activation check: requesting legacy full or specific capability activates it
local ok = Core.RequireLegacySharedFull("CompositionSmokeTest")
assert(ok == true, "RequireLegacySharedFull failed")

print("psychopatz core composition: ok")
