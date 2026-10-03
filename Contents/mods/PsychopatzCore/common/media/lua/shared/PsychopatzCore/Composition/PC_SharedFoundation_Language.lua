PsychopatzCore = PsychopatzCore or {}

-- Provider-neutral semantic language. This module only defines data and
-- parser APIs; it installs no callbacks and has no LLM dependency.
require "PsychopatzCore/Semantics/PsychopatzSemantic"

require "PsychopatzCore/Runtime/PC_RuntimeRole"
require "PsychopatzCore/Collections/PC_RingBuffer"
require "PsychopatzCore/Events/PC_EventBus"
require "PsychopatzCore/Translation/PsychopatzCustomTranslationManager"
require "PsychopatzCore/Translation/PsychopatzCoreTranslation"

return PsychopatzCore
