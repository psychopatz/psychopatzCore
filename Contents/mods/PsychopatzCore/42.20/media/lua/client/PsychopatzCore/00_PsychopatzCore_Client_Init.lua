-- Thin early-loading client anchor. Keep composition order explicit.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/PsychopatzAudioSettings"
require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
return require "PsychopatzCore/Composition/PC_ClientComposition"
