PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.DebugHub = PsychopatzCore.DebugHub or {}

local Hub = PsychopatzCore.DebugHub
Hub.tools = Hub.tools or {}
Hub.groupExpanded = Hub.groupExpanded or {}
Hub.DEFAULT_SOURCE = Hub.DEFAULT_SOURCE or "PsychopatzCore"
Hub.DEFAULT_SURFACE = Hub.DEFAULT_SURFACE or "global"

local function requestedSurface(filter)
    if type(filter) == "table" then
        filter = filter.surface
    end
    if filter == nil then return nil end
    filter = tostring(filter)
    return filter ~= "" and filter or nil
end

function Hub.MatchesSurface(definition, filter)
    if type(definition) ~= "table" then return false end
    local surface = requestedSurface(filter)
    if not surface then return true end
    return tostring(definition.surface or Hub.DEFAULT_SURFACE) == surface
end

function Hub.IsAvailable(definition)
    if type(definition) ~= "table"
        or type(definition.available) ~= "function" then
        return false
    end
    -- Provider availability is an addon-owned callback boundary.  A broken
    -- provider must disable its row without taking down the shared UI.
    local ok, available = pcall(definition.available)
    return ok and available == true
end

function Hub.RegisterTool(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string" or definition.id == "" then
        return false
    end
    if type(definition.title) ~= "string" or type(definition.action) ~= "function" then
        return false
    end

    definition.description = tostring(definition.description or "")
    definition.source = tostring(definition.source or Hub.DEFAULT_SOURCE)
    if definition.source == "" then definition.source = Hub.DEFAULT_SOURCE end
    definition.surface = tostring(definition.surface or Hub.DEFAULT_SURFACE)
    if definition.surface == "" then definition.surface = Hub.DEFAULT_SURFACE end
    definition.order = tonumber(definition.order) or 1000
    definition.available = type(definition.available) == "function" and definition.available or function() return true end
    Hub.tools[definition.id] = definition

    if Hub.Window and Hub.Window.instance then
        Hub.Window.instance:rebuildCards()
    end
    return true
end

function Hub.UnregisterTool(id)
    Hub.tools[tostring(id or "")] = nil
    if Hub.Window and Hub.Window.instance then
        Hub.Window.instance:rebuildCards()
    end
end

function Hub.GetTools(filter)
    local result = {}
    for _, definition in pairs(Hub.tools) do
        if Hub.MatchesSurface(definition, filter) then
            result[#result + 1] = definition
        end
    end
    table.sort(result, function(left, right)
        if left.order == right.order then
            return left.title < right.title
        end
        return left.order < right.order
    end)
    return result
end

function Hub.IsGroupExpanded(source)
    local key = tostring(source or Hub.DEFAULT_SOURCE)
    if Hub.groupExpanded[key] == nil then
        return true
    end
    return Hub.groupExpanded[key] == true
end

function Hub.SetGroupExpanded(source, expanded)
    local key = tostring(source or Hub.DEFAULT_SOURCE)
    Hub.groupExpanded[key] = expanded == true
    if Hub.Window and Hub.Window.instance then
        Hub.Window.instance:rebuildCards()
    end
    return Hub.groupExpanded[key]
end

function Hub.GetToolGroups(filter)
    local groupsBySource = {}
    local groups = {}

    for _, definition in ipairs(Hub.GetTools(filter)) do
        local source = tostring(definition.source or Hub.DEFAULT_SOURCE)
        local group = groupsBySource[source]
        if not group then
            group = {
                source = source,
                order = definition.order,
                tools = {},
            }
            groupsBySource[source] = group
            groups[#groups + 1] = group
        end
        group.tools[#group.tools + 1] = definition
    end

    table.sort(groups, function(left, right)
        if left.order == right.order then
            return left.source < right.source
        end
        return left.order < right.order
    end)
    for _, group in ipairs(groups) do
        group.expanded = Hub.IsGroupExpanded(group.source)
    end
    return groups
end

function Hub.Close(surface)
    local window = Hub.Window and Hub.Window.instance
    if window and surface
        and tostring(window.surface or Hub.DEFAULT_SURFACE)
            ~= tostring(surface) then
        return false
    end
    if window and type(window.close) == "function" then
        window:close()
        return true
    end
    return false
end

return Hub
