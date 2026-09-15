-- Backwards-compatible module path. JSON is now shared by Core subsystems,
-- including the custom translation manager, without coupling them to Bridge.
return require "PsychopatzCore/Serialization/PsychopatzJson"
