PsychopatzCore = PsychopatzCore or {}

-- Keep the original provider order explicit while giving each foundation
-- domain a small, independently auditable composition boundary.
require "PsychopatzCore/Composition/PC_SharedFoundation_Language"
require "PsychopatzCore/Composition/PC_SharedFoundation_Conversation"
require "PsychopatzCore/Composition/PC_SharedFoundation_World"

return PsychopatzCore
