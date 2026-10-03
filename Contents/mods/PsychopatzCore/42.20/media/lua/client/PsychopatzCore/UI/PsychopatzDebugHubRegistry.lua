PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.DebugHub = PsychopatzCore.DebugHub or {}

local Hub = PsychopatzCore.DebugHub
Hub.tools = Hub.tools or {}
Hub.groupExpanded = Hub.groupExpanded or {}
Hub.DEFAULT_SOURCE = Hub.DEFAULT_SOURCE or "PsychopatzCore"

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

function Hub.GetTools()
    local result = {}
    for _, definition in pairs(Hub.tools) do
        result[#result + 1] = definition
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

function Hub.GetToolGroups()
    local groupsBySource = {}
    local groups = {}

    for _, definition in ipairs(Hub.GetTools()) do
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

return Hub
