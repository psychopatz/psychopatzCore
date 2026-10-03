require "ISUI/ISCollapsableWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Components/PsychopatzWindowToolbar"
require "PsychopatzCore/UI/Components/PsychopatzLayoutHost"
require "PsychopatzCore/Settings/PsychopatzSettings"

local UI = PsychopatzCore.UI
local Geometry = require "PsychopatzCore/UI/PsychopatzWindow_Geometry"

PsychopatzWindow = ISCollapsableWindow:derive("PsychopatzWindow")
UI.Window = PsychopatzWindow

-- Keep the base class identity and public methods stable while loading each
-- responsibility behind the same legacy module boundary.
require "PsychopatzCore/UI/PsychopatzWindow_Controls"
require "PsychopatzCore/UI/PsychopatzWindow_Persistence"
require "PsychopatzCore/UI/PsychopatzWindow_Responsive"

return PsychopatzWindow
