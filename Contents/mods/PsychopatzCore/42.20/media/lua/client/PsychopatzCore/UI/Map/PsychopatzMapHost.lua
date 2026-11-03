-- Generic production world-map host shared by adopter mods.
-- PsychopatzCore owns the single ISWorldMap integration; consumers only
-- register ordered overlays and toolbar tools.

pcall(require, "ISUI/Maps/ISWorldMap")
pcall(require, "ISUI/ISButton")
pcall(require, "ISUI/ISContextMenu")

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.MapOverlayRegistry = PsychopatzCore.MapOverlayRegistry or {}
PsychopatzCore.MapToolRegistry = PsychopatzCore.MapToolRegistry or {}
PsychopatzCore.MapEventRegistry = PsychopatzCore.MapEventRegistry or {}
PsychopatzCore.MapContextRegistry = PsychopatzCore.MapContextRegistry or {}

local Overlays = PsychopatzCore.MapOverlayRegistry
local Tools = PsychopatzCore.MapToolRegistry
local MapEvents = PsychopatzCore.MapEventRegistry
local Contexts = PsychopatzCore.MapContextRegistry

Overlays.ByID = Overlays.ByID or {}
Overlays.Ordered = Overlays.Ordered or {}
Tools.ByID = Tools.ByID or {}
MapEvents.ByID = MapEvents.ByID or {}
Contexts.ByID = Contexts.ByID or {}

local function resolve(definition, field, fallback)
    local value = definition and definition[field]
    if type(value) == "function" then
        local ok, result = pcall(value, definition)
        if not ok then return fallback end
        value = result
    end
    if value == nil then return fallback end
    return value
end

local function rebuildOverlayOrder()
    local output = {}
    for _, definition in pairs(Overlays.ByID) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    Overlays.Ordered = output
end

function Overlays.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.render) ~= "function"
    then
        return false, "invalid_overlay"
    end
    definition.id = id
    definition.order = tonumber(definition.order) or 100
    Overlays.ByID[id] = definition
    rebuildOverlayOrder()
    return true
end

function Overlays.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Overlays.ByID[id] then return false end
    Overlays.ByID[id] = nil
    rebuildOverlayOrder()
    return true
end

function Overlays.List()
    local output = {}
    for index = 1, #Overlays.Ordered do
        output[index] = Overlays.Ordered[index]
    end
    return output
end

function Overlays.Render(map)
    for index = 1, #Overlays.Ordered do
        local definition = Overlays.Ordered[index]
        local visible = resolve(definition, "enabled", true) ~= false
        if visible and type(definition.isVisible) == "function" then
            local ok, result = pcall(definition.isVisible, map)
            visible = ok and result ~= false
        end
        if visible then
            local ok, err = pcall(definition.render, map)
            if not ok and PsychopatzCore and PsychopatzCore.LogWarn then
                PsychopatzCore.LogWarn(
                    "Map overlay failed id=" .. tostring(definition.id)
                        .. " error=" .. tostring(err)
                )
            end
        end
    end
end

local function listTools()
    local output = {}
    for _, definition in pairs(Tools.ByID) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    return output
end

function Tools.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.onActivate) ~= "function"
    then
        return false, "invalid_map_tool"
    end
    definition.id = id
    definition.order = tonumber(definition.order) or 100
    definition.field = definition.field
        or ("psychopatzMapTool_" .. id:gsub("[^%w_]", "_"))
    Tools.ByID[id] = definition
    return true
end

function Tools.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Tools.ByID[id] then return false end
    Tools.ByID[id] = nil
    return true
end

function Tools.List()
    return listTools()
end

local function listMapEvents()
    local output = {}
    for _, definition in pairs(MapEvents.ByID) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    return output
end

function MapEvents.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table" then
        return false, "invalid_map_event_handler"
    end
    definition.id = id
    definition.order = tonumber(definition.order) or 100
    MapEvents.ByID[id] = definition
    return true
end

function MapEvents.Unregister(id)
    id = tostring(id or "")
    if id == "" or not MapEvents.ByID[id] then return false end
    MapEvents.ByID[id] = nil
    return true
end

function MapEvents.List()
    return listMapEvents()
end

function MapEvents.Dispatch(method, map, ...)
    for _, definition in ipairs(listMapEvents()) do
        local handler = definition[method]
        if type(handler) == "function" then
            local ok, handled = pcall(handler, map, ...)
            if ok and handled == true then return true end
            if not ok and PsychopatzCore and PsychopatzCore.LogWarn then
                PsychopatzCore.LogWarn(
                    "Map event handler failed id=" .. tostring(definition.id)
                        .. " method=" .. tostring(method)
                        .. " error=" .. tostring(handled)
                )
            end
        end
    end
    return false
end

local function listContexts()
    local output = {}
    for _, definition in pairs(Contexts.ByID) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    return output
end

function Contexts.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.augment) ~= "function"
    then
        return false, "invalid_map_context_provider"
    end
    definition.id = id
    definition.order = tonumber(definition.order) or 100
    Contexts.ByID[id] = definition
    return true
end

function Contexts.Unregister(id)
    id = tostring(id or "")
    if id == "" or not Contexts.ByID[id] then return false end
    Contexts.ByID[id] = nil
    return true
end

function Contexts.List()
    return listContexts()
end

function Contexts.HasAvailable(map, x, y)
    for _, definition in ipairs(listContexts()) do
        local available = true
        if type(definition.available) == "function" then
            local ok, result = pcall(definition.available, map, x, y)
            available = ok and result == true
        end
        if available then return true end
    end
    return false
end

function Contexts.Augment(map, context, x, y)
    local added = 0
    for _, definition in ipairs(listContexts()) do
        local available = true
        if type(definition.available) == "function" then
            local ok, result = pcall(definition.available, map, x, y)
            available = ok and result == true
        end
        if available then
            local ok, result = pcall(
                definition.augment, map, context, x, y)
            if ok and result == true then
                added = added + 1
            elseif not ok and PsychopatzCore and PsychopatzCore.LogWarn then
                PsychopatzCore.LogWarn(
                    "Map context provider failed id="
                        .. tostring(definition.id)
                        .. " error=" .. tostring(result)
                )
            end
        end
    end
    return added
end

local function numberFrom(object, field, method, fallback)
    local value = object and tonumber(object[field]) or nil
    if value == nil and object and type(object[method]) == "function" then
        value = tonumber(object[method](object))
    end
    return value or fallback
end

local function setVisible(button, visible)
    if button.setVisible then button:setVisible(visible)
    else button.visible = visible end
end

local function setPosition(button, x, y, height)
    if button.setX then button:setX(x) else button.x = x end
    if button.setY then button:setY(y) else button.y = y end
    if button.setHeight then button:setHeight(height)
    else button.height = height end
end

local function activate(map, definition)
    if resolve(definition, "visible", true) == false
        or resolve(definition, "enabled", true) == false
    then
        return false
    end
    return definition.onActivate(map) ~= false
end

local function addButton(map, definition)
    local width = tonumber(resolve(definition, "width", 100)) or 100
    local button = ISButton:new(
        0, 0, width, 32,
        tostring(resolve(definition, "title", definition.id)),
        map,
        function() return activate(map, definition) end
    )
    button.internal = definition.id
    button.mapToolDefinition = definition
    local iconPath = resolve(definition, "icon", nil)
    if iconPath and getTexture then
        local icon = type(iconPath) == "string" and getTexture(iconPath) or iconPath
        if icon then
            button.iconTexture = icon
            button.joypadTextureWH =
                tonumber(resolve(definition, "iconSize", 22)) or 22
        end
    end
    if button.initialise then button:initialise() end
    if button.instantiate then button:instantiate() end
    if map.addChild then map:addChild(button) end
    map[definition.field] = button
    return button
end

function Tools.LayoutButtons(map)
    local panel = map and map.buttonPanel or nil
    if not panel then return false end

    local entries = listTools()
    local panelX = numberFrom(panel, "x", "getX", 0)
    local panelY = numberFrom(panel, "y", "getY", 0)
    local height = math.max(24, numberFrom(panel, "height", "getHeight", 32))
    local right = panelX
    local gap = 8

    for index = #entries, 1, -1 do
        local definition = entries[index]
        local button = map[definition.field]
        local visible = resolve(definition, "visible", true) ~= false
        if button then setVisible(button, visible) end
        if button and visible then
            local width = numberFrom(button, "width", "getWidth", 100)
            right = right - width
            setPosition(button, right, panelY, height)
            local title = tostring(resolve(definition, "title", definition.id))
            if button.setTitle then button:setTitle(title)
            else button.title = title end
            local enabled = resolve(definition, "enabled", true) ~= false
            if button.setEnable then button:setEnable(enabled)
            else button.enable = enabled end
            button.tooltip = resolve(definition, "tooltip", nil)
            right = right - gap
        end
    end
    return true
end

function Tools.EnsureButtons(map)
    if not map or not map.buttonPanel or not ISButton or not ISButton.new then
        return nil
    end
    for _, definition in ipairs(listTools()) do
        if not map[definition.field] then addButton(map, definition) end
    end
    Tools.LayoutButtons(map)
    return true
end

function Tools.Close()
    for _, definition in ipairs(listTools()) do
        if type(definition.onMapClose) == "function" then
            pcall(definition.onMapClose)
        end
    end
end

local activeContextCapture = nil
local originalContextGet = ISContextMenu
    and type(ISContextMenu.get) == "function" and ISContextMenu.get or nil

if originalContextGet and not ISContextMenu._psychopatzCoreMapHostPatched then
    ISContextMenu._psychopatzCoreMapHostPatched = true
    ISContextMenu.get = function(playerNum, x, y, ...)
        local context = originalContextGet(playerNum, x, y, ...)
        if activeContextCapture then
            activeContextCapture.context = context
        end
        return context
    end
end

if ISWorldMap and not ISWorldMap._psychopatzCoreMapHostPatched then
    ISWorldMap._psychopatzCoreMapHostPatched = true

    local originalCreateChildren = ISWorldMap.createChildren
    local originalPrerender = ISWorldMap.prerender
    local originalRender = ISWorldMap.render
    local originalClose = ISWorldMap.close
    local originalMouseDown = ISWorldMap.onMouseDown
    local originalMouseMove = ISWorldMap.onMouseMove
    local originalMouseMoveOutside = ISWorldMap.onMouseMoveOutside
    local originalMouseUp = ISWorldMap.onMouseUp
    local originalMouseUpOutside = ISWorldMap.onMouseUpOutside
    local originalRightMouseDown = ISWorldMap.onRightMouseDown
    local originalRightMouseUp = ISWorldMap.onRightMouseUp

    function ISWorldMap:createChildren()
        if originalCreateChildren then originalCreateChildren(self) end
        Tools.EnsureButtons(self)
    end

    function ISWorldMap:prerender()
        if originalPrerender then originalPrerender(self) end
        Tools.EnsureButtons(self)
    end

    function ISWorldMap:render()
        if originalRender then originalRender(self) end
        Overlays.Render(self)
    end

    function ISWorldMap:onMouseDown(x, y)
        if MapEvents.Dispatch("onMouseDown", self, x, y) then return true end
        if originalMouseDown then return originalMouseDown(self, x, y) end
        return false
    end

    function ISWorldMap:onMouseMove(dx, dy)
        if MapEvents.Dispatch("onMouseMove", self, dx, dy) then return true end
        if originalMouseMove then return originalMouseMove(self, dx, dy) end
        return false
    end

    function ISWorldMap:onMouseMoveOutside(dx, dy)
        if MapEvents.Dispatch("onMouseMoveOutside", self, dx, dy) then
            return true
        end
        if originalMouseMoveOutside then
            return originalMouseMoveOutside(self, dx, dy)
        end
        return false
    end

    function ISWorldMap:onMouseUp(x, y)
        if MapEvents.Dispatch("onMouseUp", self, x, y) then return true end
        if originalMouseUp then return originalMouseUp(self, x, y) end
        return false
    end

    function ISWorldMap:onMouseUpOutside(x, y)
        if MapEvents.Dispatch("onMouseUpOutside", self, x, y) then
            return true
        end
        if originalMouseUpOutside then
            return originalMouseUpOutside(self, x, y)
        end
        return false
    end

    function ISWorldMap:onRightMouseDown(x, y)
        if MapEvents.Dispatch("onRightMouseDown", self, x, y) then
            return true
        end
        if originalRightMouseDown then
            return originalRightMouseDown(self, x, y)
        end
        return false
    end

    function ISWorldMap:onRightMouseUp(x, y)
        if MapEvents.Dispatch("onRightMouseUp", self, x, y) then
            return true
        end

        local capture = { context = nil }
        local previousCapture = activeContextCapture
        activeContextCapture = capture

        local result = false
        if originalRightMouseUp then
            result = originalRightMouseUp(self, x, y)
        end
        activeContextCapture = previousCapture

        local context = capture.context
        if not context and originalContextGet
            and Contexts.HasAvailable(self, x, y)
        then
            local playerNum = tonumber(self.playerNum) or 0
            local absoluteX = self.getAbsoluteX and self:getAbsoluteX() or 0
            local absoluteY = self.getAbsoluteY and self:getAbsoluteY() or 0
            context = ISContextMenu.get(
                playerNum, x + absoluteX, y + absoluteY)
        end

        if context then
            local added = Contexts.Augment(self, context, x, y)
            if added > 0 then result = true end
        end
        return result
    end

    function ISWorldMap:close()
        MapEvents.Dispatch("onClose", self)
        Tools.Close()
        if originalClose then return originalClose(self) end
        return false
    end
end

return {
    Overlays = Overlays,
    Tools = Tools,
    Events = MapEvents,
    Contexts = Contexts,
}
