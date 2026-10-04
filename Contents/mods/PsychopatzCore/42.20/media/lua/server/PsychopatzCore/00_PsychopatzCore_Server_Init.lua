-- Thin early-loading server anchor. Keep composition order explicit.
require "PsychopatzCore/Economy/PsychopatzCurrencyServer"
require "PsychopatzCore/Economy/PsychopatzMoneyBundlerServer"
return require "PsychopatzCore/Composition/PC_ServerComposition"
