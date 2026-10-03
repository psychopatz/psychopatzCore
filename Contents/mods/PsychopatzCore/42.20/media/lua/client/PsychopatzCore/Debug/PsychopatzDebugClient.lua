require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "PsychopatzCore/00_PsychopatzCore_Init"
local Keybinds = require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/Debug/PsychopatzDebugContextMenu"
require "PsychopatzCore/UI/Inventory/PsychopatzItemTypeLedgerWindow"

if PsychopatzCore._debugClientInstalled then
    return PsychopatzCore
end
PsychopatzCore._debugClientInstalled = true

-- Keep startup composition explicit: tool registration, the owner window,
-- and runtime/keybind effects are independent client concerns.
require "PsychopatzCore/Debug/PsychopatzDebugClient_Tools"
require "PsychopatzCore/Debug/PsychopatzDebugClient_Window"
require "PsychopatzCore/Debug/PsychopatzDebugClient_Runtime"

return PsychopatzCore
