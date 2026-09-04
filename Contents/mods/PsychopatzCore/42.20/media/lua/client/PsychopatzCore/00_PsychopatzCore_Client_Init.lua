-- Thin early-loading client anchor. Keep composition order explicit.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/PsychopatzAudioSettings"
require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
require "PsychopatzCore/Compatibility/PsychopatzWalkieHotbarGuard"
return require "PsychopatzCore/Composition/PC_ClientComposition"
