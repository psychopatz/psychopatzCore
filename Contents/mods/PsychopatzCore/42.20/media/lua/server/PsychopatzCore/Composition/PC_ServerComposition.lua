PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Composition = PsychopatzCore.Composition or {}

local Composition = PsychopatzCore.Composition.Server or {}
PsychopatzCore.Composition.Server = Composition

if Composition.serverLoaded then
    return Composition
end

local RuntimeRole = PsychopatzCore.RuntimeRole
local allowsServer = RuntimeRole
    and RuntimeRole.AllowsServerCode
    and RuntimeRole.AllowsServerCode()

-- Single-player runs both client and server-authoritative Lua in one process.
-- Gate on authority capability, not dedicated-server identity, otherwise Core
-- projection/discovery request handlers never register in SP.
if not allowsServer then
    return Composition
end

require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldProjectionServer"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiscoveryServer"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldBootstrapServer"
require "PsychopatzCore/WorldEvents/PsychopatzPZWorldEventAdapter"
require "PsychopatzCore/WorldEvents/PsychopatzVanillaDiscoveryAdapter"

Composition.serverLoaded = true

return Composition
