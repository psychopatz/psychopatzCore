PsychopatzCore = PsychopatzCore or {}

require "PsychopatzCore/Traits/PsychopatzTraitRegistry"
-- Must load after the registry so unknown traits are judged against the same
-- catalog the registry populates. Self-installs its OnCreatePlayer hook.
require "PsychopatzCore/Traits/PsychopatzTraitRecovery"

return PsychopatzCore
