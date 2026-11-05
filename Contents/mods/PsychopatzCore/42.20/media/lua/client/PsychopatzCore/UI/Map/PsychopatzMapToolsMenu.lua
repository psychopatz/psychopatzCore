-- Shared Core map-tools surface.  The toolbar host and menu presentation live
-- here; adopters register only their own provider-specific actions.

local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu_Registry"
require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu_UI"
local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

local function text(key, fallback)
    local core = PsychopatzCore and PsychopatzCore.Translation
    if core and type(core.GetKey) == "function" then
        local ok, value = pcall(core.GetKey, key, fallback)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end
    return fallback or key
end

if not Menu._toolbarRegistered then
    Menu._toolbarRegistered = true
    Host.Tools.Register("PsychopatzCore:mapTools", {
        order = 20,
        field = "psychopatzMapToolsButton",
        width = 112,
        title = function()
            return text("UI_PsychopatzMapTools_Button", "Map Tools")
        end,
        tooltip = function()
            return text("UI_PsychopatzMapTools_ButtonHelp",
                "Open shared map controls and debug tools.")
        end,
        icon = "media/ui/inventoryPanes/Button_Settings.png",
        iconSize = 22,
        onActivate = function(map)
            return Menu.Open(map) ~= nil
        end,
        onMapClose = Menu.Close,
    })
end

return Menu
