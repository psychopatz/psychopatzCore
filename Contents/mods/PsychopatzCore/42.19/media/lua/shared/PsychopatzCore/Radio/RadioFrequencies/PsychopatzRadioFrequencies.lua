-- Reusable frequency allocation and broadcast-provider entry point.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioFrequencies =
    PsychopatzCore.RadioFrequencies or {}
PsychopatzCore.RadioFrequencies.Internal =
    PsychopatzCore.RadioFrequencies.Internal or {}

require "PsychopatzCore/Radio/RadioFrequencies/PsychopatzRadioFrequencies_Allocator"
require "PsychopatzCore/Radio/RadioFrequencies/PsychopatzRadioFrequencies_Providers"

return PsychopatzCore.RadioFrequencies
