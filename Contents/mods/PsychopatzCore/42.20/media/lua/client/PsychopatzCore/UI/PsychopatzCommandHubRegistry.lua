-- Shared, mod-agnostic command catalog for PsychopatzCore's command hub.
--
-- A command is either a root button (a category) or a child button.  The
-- registry deliberately contains no UI code so any mod can contribute to the
-- same catalog without depending on Project Hoomans.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Registry = UI.CommandHubRegistry or {}
UI.CommandHubRegistry = Registry

Registry.Nodes = Registry.Nodes or {}
Registry.Categories = Registry.Categories or {}
Registry.OrderedCategories = Registry.OrderedCategories or {}
Registry.Revision = tonumber(Registry.Revision) or 0
Registry.CategoryOrder = Registry.CategoryOrder or {}

local function touch()
    Registry.Revision = Registry.Revision + 1
end

local function nodeID(value)
    local id = tostring(value or "")
    if id == "" then return nil end
    return id
end

local function defaultSource(definition)
    return tostring(definition.source or "PsychopatzCore")
end

local function sortChildren(node)
    if not node or not node.actions then return end
    table.sort(node.actions, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
end

local function sortCategories()
    local output = {}
    for _, category in pairs(Registry.Categories) do
        output[#output + 1] = category
    end

    local orderIndex = {}
    for index, id in ipairs(Registry.CategoryOrder or {}) do
        orderIndex[tostring(id)] = index
    end

    table.sort(output, function(left, right)
        local leftIndex = orderIndex[tostring(left.id)]
        local rightIndex = orderIndex[tostring(right.id)]
        if leftIndex or rightIndex then
            if not leftIndex then return false end
            if not rightIndex then return true end
            if leftIndex ~= rightIndex then return leftIndex < rightIndex end
        end

        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    Registry.OrderedCategories = output
end

local function ensureNode(id)
    local node = Registry.Nodes[id]
    if not node then
        node = {
            id = id,
            actions = {},
            actionsByID = {},
        }
        Registry.Nodes[id] = node
    else
        node.actions = node.actions or {}
        node.actionsByID = node.actionsByID or {}
    end
    return node
end

local function removeChild(parent, childID)
    if not parent then return end
    parent.actionsByID = parent.actionsByID or {}
    parent.actionsByID[childID] = nil
    local output = {}
    for _, child in ipairs(parent.actions or {}) do
        if tostring(child.id) ~= childID then output[#output + 1] = child end
    end
    parent.actions = output
end

local function detach(node)
    if node and node.parentID then
        removeChild(Registry.Nodes[node.parentID], tostring(node.id))
        node.parentID = nil
    end
end

local function copyDefinition(node, definition)
    for key, value in pairs(definition) do
        if key ~= "actions" and key ~= "children" then
            node[key] = value
        end
    end
    node.id = tostring(definition.id)
    node.source = defaultSource(definition)
    node.order = tonumber(definition.order) or 100
end

local function registerAction(parentID, definition)
    local parentKey = nodeID(parentID)
    if not parentKey then return nil, "invalid_command_parent" end
    if type(definition) ~= "table" then
        return nil, "invalid_command_action"
    end

    local id = nodeID(definition.id)
    if not id then return nil, "invalid_command_action" end

    local parent = ensureNode(parentKey)
    local action = ensureNode(id)
    if action.parentID and action.parentID ~= parentKey then
        removeChild(Registry.Nodes[action.parentID], id)
    end

    copyDefinition(action, definition)
    action.parentID = parentKey
    Registry.Categories[id] = nil
    parent.actionsByID[id] = action

    local found = false
    for _, child in ipairs(parent.actions) do
        if tostring(child.id) == id then found = true break end
    end
    if not found then parent.actions[#parent.actions + 1] = action end
    sortChildren(parent)
    touch()

    local nested = definition.actions or definition.children
    if type(nested) == "table" then
        for _, child in ipairs(nested) do
            if type(child) == "table" then registerAction(id, child) end
        end
    end
    return action
end

function Registry.RegisterCategory(definition)
    if type(definition) ~= "table" then
        return nil, "invalid_command_category"
    end

    local id = nodeID(definition.id)
    if not id then return nil, "invalid_command_category" end

    local category = ensureNode(id)
    detach(category)
    copyDefinition(category, definition)
    category.parentID = nil
    Registry.Categories[id] = category
    sortChildren(category)
    sortCategories()
    touch()

    local incomingActions = definition.actions or definition.children
    if type(incomingActions) == "table" then
        for _, action in ipairs(incomingActions) do
            if type(action) == "table" then registerAction(id, action) end
        end
    end
    sortCategories()
    return category
end

function Registry.RegisterAction(categoryID, definition)
    return registerAction(categoryID, definition)
end

function Registry.RegisterButton(definition)
    if type(definition) ~= "table" then
        return nil, "invalid_command_button"
    end
    if definition.parentID ~= nil or definition.parent ~= nil then
        return registerAction(definition.parentID or definition.parent, definition)
    end
    return Registry.RegisterCategory(definition)
end

Registry.Register = Registry.RegisterButton

function Registry.Get(id)
    return Registry.Nodes[nodeID(id)]
end

function Registry.GetAction(parentID, actionID)
    local parent = Registry.Get(parentID)
    return parent and parent.actionsByID
        and parent.actionsByID[nodeID(actionID)] or nil
end

function Registry.GetChildren(parentID)
    local parent = Registry.Get(parentID)
    return parent and parent.actions or {}
end

function Registry.All()
    return Registry.OrderedCategories
end

function Registry.SetCategoryOrder(ids)
    if type(ids) ~= "table" then return false end
    local order, seen = {}, {}
    for _, id in ipairs(ids) do
        local key = nodeID(id)
        if key and not seen[key] then
            order[#order + 1] = key
            seen[key] = true
        end
    end
    Registry.CategoryOrder = order
    sortCategories()
    touch()
    return true
end

Registry.SetRootOrder = Registry.SetCategoryOrder
Registry.SetOrder = Registry.SetCategoryOrder

function Registry.HasActions(category)
    return category ~= nil and #(category.actions or {}) > 0
end

function Registry.IsVisible(definition, context)
    if not definition then return false end
    if type(definition.visible) == "function" then
        local ok, value = pcall(definition.visible, definition, context)
        return ok and value ~= false
    end
    return definition.visible ~= false
end

function Registry.IsEnabled(definition, context)
    if not definition then return false end
    if type(definition.enabled) == "function" then
        local ok, value = pcall(definition.enabled, definition, context)
        return ok and value ~= false
    end
    return definition.enabled ~= false
end

function Registry.IsSelected(definition, context)
    if not definition then return false end
    if type(definition.selected) == "function" then
        local ok, value = pcall(definition.selected, definition, context)
        return ok and value == true
    end
    return definition.selected == true
end

function Registry.UnregisterButton(id)
    local key = nodeID(id)
    local node = key and Registry.Nodes[key] or nil
    if not node then return false end

    local children = {}
    for _, child in ipairs(node.actions or {}) do children[#children + 1] = child.id end
    for _, childID in ipairs(children) do Registry.UnregisterButton(childID) end

    detach(node)
    Registry.Categories[key] = nil
    Registry.Nodes[key] = nil
    sortCategories()
    touch()
    return true
end

function Registry.UnregisterSource(source)
    local target = tostring(source or "")
    if target == "" then return 0 end
    local ids = {}
    for id, node in pairs(Registry.Nodes) do
        if tostring(node.source or "") == target then ids[#ids + 1] = id end
    end
    local function removeOwned(id)
        local node = Registry.Nodes[id]
        if not node then return end
        local children = {}
        for _, child in ipairs(node.actions or {}) do
            children[#children + 1] = child.id
        end
        for _, childID in ipairs(children) do
            local child = Registry.Nodes[tostring(childID)]
            if child and tostring(child.source or "") == target then
                removeOwned(tostring(childID))
            elseif child then
                -- Do not delete another mod's contribution merely because
                -- it is attached below a parent being removed. Promote it to
                -- a root button so it remains visible and registered.
                removeChild(node, tostring(childID))
                child.parentID = nil
                Registry.Categories[tostring(childID)] = child
            end
        end
        detach(node)
        Registry.Categories[id] = nil
        Registry.Nodes[id] = nil
        touch()
    end
    for _, id in ipairs(ids) do
        local node = Registry.Nodes[id]
        if node and tostring(node.source or "") == target then
            removeOwned(id)
        end
    end
    sortCategories()
    return #ids
end

return Registry
