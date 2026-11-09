-- Core-owned compact map-debug menu.  It reads the shared Debug Hub registry
-- but deliberately presents only map actions in the same style as Map Tools.

local Hub = require "PsychopatzCore/UI/PsychopatzDebugHubRegistry"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.MapDebugMenu = PsychopatzCore.MapDebugMenu or {}

local Menu = PsychopatzCore.MapDebugMenu

local function resolve(entry, field, fallback)
    local value = entry and entry[field]
    if field == "title" then
        value = entry and (entry.menuTitle or entry.title)
    elseif field == "tooltip" then
        value = entry and (entry.menuTooltip or entry.description)
    elseif field == "visible" then
        value = entry and entry.menuVisible
        if value == nil then value = true end
    elseif field == "enabled" then
        value = entry and entry.menuEnabled
        if value == nil then value = Hub.IsAvailable(entry) end
    end
    if type(value) == "function" then
        local ok, result = pcall(value, entry)
        if not ok then return fallback end
        value = result
    end
    if value == nil then return fallback end
    return value
end

function Menu.Resolve(entry, field, fallback)
    return resolve(entry, field, fallback)
end

function Menu.Get(id)
    return Hub.tools[tostring(id or "")]
end

function Menu.List()
    return Hub.GetTools("map")
end

function Menu.IsEntryVisible(entry)
    return resolve(entry, "visible", true) ~= false
end

function Menu.IsEntryEnabled(entry)
    return resolve(entry, "enabled", false) ~= false
        and Hub.IsAvailable(entry)
end

function Menu.Open(map)
    require "PsychopatzCore/UI/Map/PsychopatzMapDebugMenu_UI"
    return PsychopatzMapDebugWindow.Open(map)
end

function Menu.Close()
    if Menu.instance and type(Menu.instance.close) == "function" then
        Menu.instance:close()
        return true
    end
    return false
end

return Menu
