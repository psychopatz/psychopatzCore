-- Reusable title-bar toolbar for Core windows.
--
-- The toolbar owns registration and layout of custom title-bar controls. It
-- deliberately does not own window behavior such as pinning or detaching;
-- those behaviors belong to the component that registered the button.

require "PsychopatzCore/UI/Components/PsychopatzUIControls"

local UI = PsychopatzCore.UI
local Toolbar = UI.WindowToolbar or {}
UI.WindowToolbar = Toolbar

local ToolbarState = {}
ToolbarState.__index = ToolbarState

local function readValue(target, methodName, fieldName, fallback)
    if not target then return fallback end
    local method = target[methodName]
    if type(method) == "function" then
        local value = method(target)
        if value ~= nil then return value end
    end
    if fieldName and target[fieldName] ~= nil then
        return target[fieldName]
    end
    return fallback
end

local function titleBarHeight(window)
    local value = window and window.titleBarHeight
    if type(value) == "function" then value = value(window) end
    return math.max(1, math.floor(tonumber(value) or 18))
end

local function nativeTitlebarButton(window)
    local pin = window and (window.psychopatzTitlebarPinButton or window.pinButton)
    local collapse = window and (window.psychopatzTitlebarCollapseButton
        or window.collapseButton)
    if window and window.pin == true and collapse then return collapse end
    return pin or collapse
end

local function stateFor(window)
    if not window then return nil end
    return window.psychopatzWindowToolbar
end

local function imageFor(entry)
    local image = entry.definition.image
    if type(image) == "function" then
        return image(entry.window, entry.button)
    end
    return image
end

local function visibleFor(entry)
    local visible = entry.definition.visible
    if type(visible) == "function" then
        visible = visible(entry.window, entry.button)
    end
    return visible ~= false
end

local function applyImageSize(entry, width, height)
    local button = entry.button
    if not button or not button.forceImageSize then return end

    local imageSize = entry.definition.imageSize
    local imageWidth
    local imageHeight
    if type(imageSize) == "table" then
        imageWidth = tonumber(imageSize.width or imageSize.w)
        imageHeight = tonumber(imageSize.height or imageSize.h)
    elseif imageSize ~= nil then
        imageWidth = tonumber(imageSize)
        imageHeight = imageWidth
    end
    imageWidth = math.max(1, math.floor(imageWidth or (width - 2)))
    imageHeight = math.max(1, math.floor(imageHeight or (height - 2)))
    button:forceImageSize(imageWidth, imageHeight)
end

local function syncButton(entry, width, height)
    local button = entry.button
    local definition = entry.definition
    if not button then return end

    local image = imageFor(entry)
    if image and button.setImage and UI.ImageResolver then
        local texture = UI.ImageResolver.Resolve(image)
        if texture then button:setImage(texture) end
    end
    local tooltip = definition.tooltip
    if type(tooltip) == "function" then
        tooltip = tooltip(entry.window, button)
    end
    if tooltip ~= nil then button.tooltip = tooltip end
    if definition.enabled ~= nil then
        local enabled = definition.enabled
        if type(enabled) == "function" then
            enabled = enabled(entry.window, button)
        end
        if button.setEnable then button:setEnable(enabled ~= false)
        else button.enable = enabled ~= false end
    end
    applyImageSize(entry, width, height)
end

function ToolbarState:Add(definition)
    return Toolbar.Add(self.window, definition)
end

function ToolbarState:Remove(id)
    return Toolbar.Remove(self.window, id)
end

function ToolbarState:Find(id)
    return Toolbar.Find(self.window, id)
end

function ToolbarState:SetVisible(id, visible)
    return Toolbar.SetVisible(self.window, id, visible)
end

function ToolbarState:SetEnabled(id, enabled)
    return Toolbar.SetEnabled(self.window, id, enabled)
end

function ToolbarState:SetImage(id, image)
    return Toolbar.SetImage(self.window, id, image)
end

function ToolbarState:SetTooltip(id, tooltip)
    return Toolbar.SetTooltip(self.window, id, tooltip)
end

function ToolbarState:Sync()
    return Toolbar.Sync(self.window)
end

function Toolbar.Install(window, options)
    if not window then return nil end
    local state = stateFor(window)
    if state then
        if options and options.gap ~= nil then
            state.gap = math.max(0, math.floor(tonumber(options.gap) or 0))
        end
        return state
    end

    state = setmetatable({
        window = window,
        entries = {},
        byId = {},
        nextSequence = 0,
        gap = math.max(0, math.floor(tonumber(options and options.gap) or 1)),
    }, ToolbarState)
    window.psychopatzWindowToolbar = state
    return state
end

function Toolbar.Add(window, definition)
    if not window then return nil end
    definition = definition or {}
    local id = tostring(definition.id or "")
    if id == "" then return nil end

    local state = Toolbar.Install(window)
    local existing = state.byId[id]
    if existing then return existing.button end

    state.nextSequence = state.nextSequence + 1
    local image = type(definition.image) == "function" and nil
        or definition.image
    local callback = definition.onclick or definition.onClick
    local button = UI.CreateButton(window, {
        id = id,
        title = definition.title or "",
        target = definition.target or window,
        onclick = callback,
        image = image,
        variant = definition.variant or "quiet",
    })
    if not button then return nil end

    local entry = {
        id = id,
        window = window,
        button = button,
        definition = definition,
        sequence = state.nextSequence,
    }
    state.entries[#state.entries + 1] = entry
    state.byId[id] = entry
    button.psychopatzToolbarId = id
    if definition.title == nil and button.setTitle then button:setTitle("") end
    Toolbar.Sync(window)
    return button
end

function Toolbar.Find(window, id)
    local state = stateFor(window)
    local entry = state and state.byId[tostring(id or "")] or nil
    return entry and entry.button or nil
end

local function updateDefinition(window, id, key, value)
    local state = stateFor(window)
    local entry = state and state.byId[tostring(id or "")] or nil
    if not entry then return false end
    entry.definition[key] = value
    Toolbar.Sync(window)
    return true
end

function Toolbar.SetVisible(window, id, visible)
    return updateDefinition(window, id, "visible", visible ~= false)
end

function Toolbar.SetEnabled(window, id, enabled)
    return updateDefinition(window, id, "enabled", enabled ~= false)
end

function Toolbar.SetImage(window, id, image)
    return updateDefinition(window, id, "image", image)
end

function Toolbar.SetTooltip(window, id, tooltip)
    return updateDefinition(window, id, "tooltip", tooltip)
end

function Toolbar.Remove(window, id)
    local state = stateFor(window)
    if not state then return false end
    local key = tostring(id or "")
    local entry = state.byId[key]
    if not entry then return false end

    state.byId[key] = nil
    for index, candidate in ipairs(state.entries) do
        if candidate == entry then
            table.remove(state.entries, index)
            break
        end
    end
    if entry.button then
        entry.button:setVisible(false)
        if window.removeChild then window:removeChild(entry.button) end
    end
    Toolbar.Sync(window)
    return true
end

function Toolbar.Sync(window)
    local state = stateFor(window)
    if not state then return false end

    local native = nativeTitlebarButton(window)
    local height = titleBarHeight(window)
    local defaultSize = math.max(1, math.floor(height - 2))
    local windowWidth = math.max(1, math.floor(tonumber(
        readValue(window, "getWidth", "width", defaultSize)) or defaultSize))
    local nativeWidth = math.max(1, math.floor(tonumber(
        readValue(native, "getWidth", "width", defaultSize)) or defaultSize))
    local nativeHeight = math.max(1, math.floor(tonumber(
        readValue(native, "getHeight", "height", defaultSize)) or defaultSize))
    local observedNativeX = tonumber(readValue(native, "getX", "x", nil))
    local fallbackNativeX = windowWidth - nativeWidth - 1

    -- ISCollapsableWindow does not consistently update a title-bar child
    -- before custom children are laid out. Preserve the native control's right
    -- margin, then derive its current x from the current window width. This
    -- makes toolbar buttons follow a resize immediately, even if the native
    -- pin/collapse button still contains its previous x for one or more
    -- frames.
    if state.nativeControl ~= native then
        state.nativeControl = native
        state.nativeRightMargin = nil
    end
    if state.nativeRightMargin == nil then
        state.nativeRightMargin = native and observedNativeX
            and math.max(0, windowWidth - observedNativeX - nativeWidth) or 1
    end
    local nativeX = windowWidth - state.nativeRightMargin - nativeWidth
    if nativeX < 0 or nativeX > windowWidth then
        nativeX = observedNativeX or fallbackNativeX
    end
    if native and native.setX then native:setX(math.floor(nativeX)) end
    local nativeY = tonumber(readValue(native, "getY", "y", 1)) or 1
    local cursor = math.floor(nativeX - state.gap)

    table.sort(state.entries, function(left, right)
        local leftOrder = tonumber(left.definition.order) or 100
        local rightOrder = tonumber(right.definition.order) or 100
        if leftOrder == rightOrder then return left.sequence < right.sequence end
        return leftOrder < rightOrder
    end)

    for _, entry in ipairs(state.entries) do
        local button = entry.button
        if button then
            local visible = visibleFor(entry)
            if visible then
                local width = math.max(1, math.floor(tonumber(entry.definition.width)
                    or nativeWidth))
                local buttonHeight = math.max(1, math.floor(
                    tonumber(entry.definition.height) or nativeHeight))
                local x = cursor - width
                button.anchorLeft = false
                button.anchorRight = true
                button.anchorTop = true
                button.anchorBottom = false
                button:setWidth(width)
                button:setHeight(buttonHeight)
                button:setX(x)
                button:setY(math.floor(nativeY))
                button:setVisible(true)
                syncButton(entry, width, buttonHeight)
                button:bringToTop()
                cursor = x - state.gap
            else
                button:setVisible(false)
            end
        end
    end
    state.lastWindowWidth = windowWidth
    state.lastNativeX = nativeX
    state.lastNativeRightMargin = state.nativeRightMargin
    return true
end

return Toolbar
