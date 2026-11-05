PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Composition = PsychopatzCore.Composition or {}

local Composition = PsychopatzCore.Composition.Client or {}
PsychopatzCore.Composition.Client = Composition

if Composition.clientLoaded then
    return Composition
end

local RuntimeRole = PsychopatzCore.RuntimeRole
local allowsClient = RuntimeRole
    and RuntimeRole.AllowsClientCode
    and RuntimeRole.AllowsClientCode()

if not allowsClient then
    return Composition
end

-- Walkie hotbar guard is an engine-level patch for Build 42 timed actions on hotbar
require "PsychopatzCore/Compatibility/PsychopatzWalkieHotbarGuard"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"
require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"
require "PsychopatzCore/UI/Map/PsychopatzMapDebugTools"

Composition.clientLoaded = true

return Composition
