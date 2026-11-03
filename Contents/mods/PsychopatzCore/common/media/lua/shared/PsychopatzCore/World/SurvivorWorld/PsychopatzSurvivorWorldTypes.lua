local ROOT =
    "PsychopatzCore/World/SurvivorWorld/Types/"

local Types = require(
    ROOT .. "PsychopatzSurvivorWorldTypesCore"
)

require(ROOT .. "PsychopatzSurvivorWorldTypesFaction")
require(ROOT .. "PsychopatzSurvivorWorldTypesCommunity")
require(ROOT .. "PsychopatzSurvivorWorldTypesGroup")
require(ROOT .. "PsychopatzSurvivorWorldTypesPopulation")
require(ROOT .. "PsychopatzSurvivorWorldTypesDiscovery")
require(ROOT .. "PsychopatzSurvivorWorldTypesSnapshot")

return Types
