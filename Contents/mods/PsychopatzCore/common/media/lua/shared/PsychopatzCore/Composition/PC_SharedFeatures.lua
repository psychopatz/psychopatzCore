PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore

-- The bootstrap performs one configuration read. The metric backend, callbacks,
-- GUI, networking, and history storage are not required or created in OFF mode.
local ProfilerBootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local BridgeBootstrap = require "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap"

-- Keep diagnostics, radio, and traits in the same order as the original
-- feature list while separating their ownership and failure surfaces.
require "PsychopatzCore/Composition/PC_SharedFeatures_Diagnostics"
require "PsychopatzCore/Composition/PC_SharedFeatures_Radio"
require "PsychopatzCore/Composition/PC_SharedFeatures_Traits"

ProfilerBootstrap.Initialize()
BridgeBootstrap.Initialize()

return Core
