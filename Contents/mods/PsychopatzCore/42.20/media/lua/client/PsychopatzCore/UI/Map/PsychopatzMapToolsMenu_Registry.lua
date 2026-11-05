-- Provider-neutral registry for controls shown by the shared world-map tools
-- menu.  Consumers register actions; Core owns the menu lifecycle and UI.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.MapToolsMenu = PsychopatzCore.MapToolsMenu or {}

local Menu = PsychopatzCore.MapToolsMenu
Menu.EntriesByID = Menu.EntriesByID or {}

local function resolve(entry, field, fallback)
    local value = entry and entry[field]
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

function Menu.IsEntryVisible(entry)
    return resolve(entry, "visible", true) ~= false
end

function Menu.List()
    local entries = {}
    for _, entry in pairs(Menu.EntriesByID) do
        if type(entry) == "table" then
            entries[#entries + 1] = entry
        end
    end
    table.sort(entries, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    return entries
end

function Menu.VisibleEntryCount()
    local count = 0
    for _, entry in ipairs(Menu.List()) do
        if Menu.IsEntryVisible(entry) then count = count + 1 end
    end
    return count
end

function Menu.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.onActivate) ~= "function" then
        return false, "invalid_map_tools_entry"
    end

    definition.id = id
    definition.order = tonumber(definition.order) or 100
    Menu.EntriesByID[id] = definition
    if Menu.instance and type(Menu.instance.syncButtons) == "function" then
        Menu.instance:syncButtons()
    end
    return true
end

function Menu.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Menu.EntriesByID[id] then return false end
    Menu.EntriesByID[id] = nil
    if Menu.instance and type(Menu.instance.syncButtons) == "function" then
        Menu.instance:syncButtons()
    end
    return true
end

return Menu
