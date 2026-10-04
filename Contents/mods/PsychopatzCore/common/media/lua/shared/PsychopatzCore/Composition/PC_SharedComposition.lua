PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Composition = Core.Composition or {}
Core.Composition = Composition

if Composition.sharedLoaded then
    return Core
end

-- Keep the shared entry point as an ordered hub. Providers must be available
-- before identity-dependent feature registration and optional bootstraps run.
require "PsychopatzCore/Composition/PC_SharedFoundation"
require "PsychopatzCore/Composition/PC_CoreIdentity"
require "PsychopatzCore/Compatibility/PsychopatzMoneyWeight"
require "PsychopatzCore/Compatibility/PsychopatzCurrencyCategory"
require "PsychopatzCore/Economy/PsychopatzCurrency"
require "PsychopatzCore/Economy/PsychopatzMoneyBundler"
require "PsychopatzCore/Composition/PC_SharedFeatures"

Composition.sharedLoaded = true

return Core
