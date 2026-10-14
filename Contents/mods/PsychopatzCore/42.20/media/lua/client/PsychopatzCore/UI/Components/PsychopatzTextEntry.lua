require "ISUI/ISTextEntryBox"
require "ISUI/ISPanel"
require "ISUI/ISImage"

local UI = PsychopatzCore.UI
local SEARCH_ICON_PATH = "media/ui/Search_Icon_On.png"
local SEARCH_ICON_MARGIN = 4
local SEARCH_ICON_SIZE = 18
local SEARCH_TEXT_GAP = 6

local function applyTextEntryOptions(entry, definition)
    if definition.clearButton and entry.setClearButton then
        entry:setClearButton(true)
    end
    if definition.onlyNumbers and entry.setOnlyNumbers then
        entry:setOnlyNumbers(true)
    end
    if definition.maxTextLength and entry.setMaxTextLength then
        entry:setMaxTextLength(tonumber(definition.maxTextLength))
    end
    if definition.onTextChange then
        entry.onTextChange = definition.onTextChange
    elseif definition.onTextChangeFunction then
        entry.onTextChangeFunction = definition.onTextChangeFunction
    end
    if definition.tooltip ~= nil then
        entry.tooltip = definition.tooltip
    end
end

local function newTextEntry(definition, x, y, width, height)
    local text = definition.text
    if text == nil then text = definition.value end
    if text == nil then text = "" end

    local entry = ISTextEntryBox:new(
        tostring(text), x, y, width, height
    )
    entry:initialise()
    entry:instantiate()
    applyTextEntryOptions(entry, definition)
    return entry
end

local function layoutSearchEntry(container)
    local width = math.max(1, tonumber(container:getWidth()) or 1)
    local height = math.max(1, tonumber(container:getHeight()) or 1)
    local iconSize = math.max(12, math.min(SEARCH_ICON_SIZE, height - 6))
    local iconX = SEARCH_ICON_MARGIN
    local iconY = math.floor((height - iconSize) / 2)
    local textX = iconX + iconSize + SEARCH_TEXT_GAP
    local textWidth = math.max(1, width - textX - SEARCH_ICON_MARGIN)

    local icon = container.psychopatzSearchIcon
    if icon then
        icon:setX(iconX)
        icon:setY(iconY)
        icon:setWidth(iconSize)
        icon:setHeight(iconSize)
    end
    local entry = container.psychopatzSearchEntry
    if entry then
        entry:setX(textX)
        entry:setY(0)
        entry:setWidth(textWidth)
        entry:setHeight(height)
    end
end

local function createSearchEntry(parent, definition)
    definition = definition or {}
    local x = tonumber(definition.x) or 0
    local y = tonumber(definition.y) or 0
    local width = tonumber(definition.width) or 1
    local height = tonumber(definition.height) or 1
    local container = ISPanel:new(x, y, width, height)
    container:noBackground()
    container:initialise()
    container:instantiate()
    container:setWantMouseEvents(false)

    local texture = getTexture(SEARCH_ICON_PATH)
    if texture then
        local icon = ISImage:new(0, 0, SEARCH_ICON_SIZE, SEARCH_ICON_SIZE,
            texture)
        icon:initialise()
        icon:instantiate()
        icon:setWantMouseEvents(false)
        container.psychopatzSearchIcon = icon
        container:addChild(icon)
    end

    local entry = newTextEntry(definition, 0, 0, width, height)
    -- The generic factory historically allowed onTextChange to replace the
    -- native method. Search entries use the native method plus the callback
    -- bridge below so post-construction onTextChangeFunction assignments are
    -- handled consistently.
    entry.onTextChange = nil
    container.psychopatzSearchEntry = entry
    container:addChild(entry)
    layoutSearchEntry(container)

    -- Keep the wrapper compatible with callers that historically assigned
    -- ISTextEntryBox.onTextChangeFunction after construction. The native
    -- entry invokes this bridge, so both factory definitions and legacy
    -- assignments continue to use the same search widget.
    container.onTextChange = definition.onTextChange
    container.onTextChangeFunction = definition.onTextChangeFunction
    entry.onTextChangeFunction = function(target, nativeEntry)
        local callback = container.onTextChangeFunction
            or container.onTextChange
        if callback then
            return callback(target, nativeEntry)
        end
    end

    local baseSetWidth = container.setWidth
    local baseSetHeight = container.setHeight
    function container:setWidth(value)
        baseSetWidth(self, value)
        layoutSearchEntry(self)
    end
    function container:setHeight(value)
        baseSetHeight(self, value)
        layoutSearchEntry(self)
    end

    function container:getText()
        return self.psychopatzSearchEntry:getText()
    end
    function container:setText(value)
        return self.psychopatzSearchEntry:setText(value)
    end
    function container:clear()
        return self.psychopatzSearchEntry:clear()
    end
    function container:focus()
        return self.psychopatzSearchEntry:focus()
    end
    function container:unfocus()
        return self.psychopatzSearchEntry:unfocus()
    end
    function container:isFocused()
        return self.psychopatzSearchEntry:isFocused()
    end
    function container:setEditable(value)
        return self.psychopatzSearchEntry:setEditable(value)
    end
    function container:setClearButton(value)
        return self.psychopatzSearchEntry:setClearButton(value)
    end
    function container:hasClearButton()
        return self.psychopatzSearchEntry:hasClearButton()
    end
    function container:setOnTextChange(callback)
        self.onTextChangeFunction = callback
    end
    function container:getNativeEntry()
        return self.psychopatzSearchEntry
    end

    container.psychopatzSearchIconPath = SEARCH_ICON_PATH
    container.psychopatzPreferredWidth = definition.preferredWidth
    if parent then parent:addChild(container) end
    return container
end

function UI.CreateTextEntry(parent, definition)
    definition = definition or {}
    if definition.searchIcon == true then
        return createSearchEntry(parent, definition)
    end

    local entry = newTextEntry(definition,
        tonumber(definition.x) or 0,
        tonumber(definition.y) or 0,
        tonumber(definition.width) or 1,
        tonumber(definition.height) or 1
    )
    if definition.preferredWidth ~= nil then
        entry.psychopatzPreferredWidth = definition.preferredWidth
    end
    if parent then parent:addChild(entry) end
    return entry
end

function UI.CreateSearchEntry(parent, definition)
    definition = definition or {}
    definition.searchIcon = true
    return createSearchEntry(parent, definition)
end

return UI
