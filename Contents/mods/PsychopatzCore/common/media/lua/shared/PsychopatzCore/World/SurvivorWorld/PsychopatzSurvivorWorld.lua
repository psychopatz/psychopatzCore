local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"
local Persistence =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPersistence"
local Registry =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldRegistry"
local Import =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldImport"
local Generation =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldGeneration"

local SurvivorWorld = {
    Types = Types,
    Persistence = Persistence,
    Registry = Registry,
    Import = Import,
    Generation = Generation,
}

function SurvivorWorld.NewRegistry(spec)
    return Registry.new(spec)
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorld = SurvivorWorld

return SurvivorWorld
