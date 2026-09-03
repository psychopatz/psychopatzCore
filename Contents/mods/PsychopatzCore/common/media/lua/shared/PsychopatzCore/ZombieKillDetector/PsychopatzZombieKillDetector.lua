-- Reusable zombie-kill detector entry point.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ZombieKillDetector =
    PsychopatzCore.ZombieKillDetector or {}

local Detector = PsychopatzCore.ZombieKillDetector

if Detector.Loaded then
    return Detector
end

Detector.Internal = Detector.Internal or {}

require "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Core"
require "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Transport"
require "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector_Events"

Detector.Loaded = true
return Detector
