PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Composition = PsychopatzCore.Composition or {}

local Composition = PsychopatzCore.Composition.Server or {}
PsychopatzCore.Composition.Server = Composition

if Composition.serverLoaded then
    return Composition
end

local RuntimeRole = PsychopatzCore.RuntimeRole
local isServer = RuntimeRole
    and RuntimeRole.IsServer
    and RuntimeRole.IsServer()

if not isServer then
    return Composition
end

-- Early-loading vanilla compatibility guards. These only register handlers, so
-- they must run at mod load time: MapObjects matches sprites before any game
-- event fires, and chunk loading starts long before OnGameStart.
require "PsychopatzCore/Compatibility/PsychopatzFeedingTroughGuard"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldProjectionServer"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiscoveryServer"

Composition.serverLoaded = true

return Composition
