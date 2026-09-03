PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore

require "PsychopatzCore/Runtime/PC_RuntimeRole"
require "PsychopatzCore/Collections/PC_RingBuffer"
require "PsychopatzCore/Events/PC_EventBus"
require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
require "PsychopatzCore/Conversation/PsychopatzNameParts"
-- Public, opt-in voice transport. Loading this module only defines the API;
-- it installs no event or tick listeners until a mod registers a source.
require "PsychopatzCore/Voice/PsychopatzVoiceGateway"
require "PsychopatzCore/Journal/PC_JournalService"
require "PsychopatzCore/Radio/PC_RadioDeviceState"
require "PsychopatzCore/World/PC_GridRegion"
require "PsychopatzCore/World/PC_GridRegionEditor"
require "PsychopatzCore/World/PsychopatzSquareRules"
require "PsychopatzCore/World/PC_ZoneRegistry"

Core.VERSION = Core.VERSION or "0.4.0"
Core.OWNER_STEAM_ID = Core.OWNER_STEAM_ID or "76561198137190990"
Core.OWNER_SP_NAME = Core.OWNER_SP_NAME or "Psychopatz"
Core.COMMAND_MODULE = Core.COMMAND_MODULE or "PsychopatzCore"

-- The bootstrap performs one configuration read. The metric backend, callbacks,
-- GUI, networking, and history storage are not required or created in OFF mode.
local ProfilerBootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local BridgeBootstrap = require "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap"

function Core.GetSafeSteamID(player)
    if not player or not player.getSteamID then
        return "0"
    end

    local rawID = player:getSteamID()
    if not rawID or rawID == 0 or rawID == "0" then
        return "0"
    end
    if type(rawID) == "number" then
        return string.format("%.0f", rawID)
    end
    return tostring(rawID)
end

function Core.IsOwner(player)
    if not player then
        return false
    end

    if Core.GetSafeSteamID(player) == Core.OWNER_STEAM_ID then
        return true
    end

    local username = player.getUsername and player:getUsername() or ""
    return Core.GetSafeSteamID(player) == "0" and username == Core.OWNER_SP_NAME
end

require "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"

require "PsychopatzCore/Debug/PsychopatzDebug"
require "PsychopatzCore/Debug/PsychopatzDebugTrace"
require "PsychopatzCore/Radio/RadioFrequencies/PsychopatzRadioFrequencies"
require "PsychopatzCore/Radio/CustomChannels/PsychopatzCustomRadio"
require "PsychopatzCore/Traits/PsychopatzTraitRegistry"

ProfilerBootstrap.Initialize()
BridgeBootstrap.Initialize()

return Core
