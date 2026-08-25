require "ISUI/ISButton"

local UI = PsychopatzCore.UI
local Sidebar = UI.Sidebar or {}
UI.Sidebar = Sidebar

-- ISEquippedItem uses this spacing between its native controls. Keeping the
-- same value makes registered controls look like part of the vanilla stack.
-- Register({ id, order, image, imageRefreshInterval, title, tooltip,
-- visible, enabled, onClick })
-- is the public extension surface. Dynamic callbacks receive entry, host,
-- and player; onClick additionally receives the button and callback args.
local SIDEBAR_GAP = 15
local CHECK_INTERVAL = 500

Sidebar.registry = Sidebar.registry or {}
Sidebar.registrationOrder = tonumber(Sidebar.registrationOrder) or 0
Sidebar.lastCheckAt = tonumber(Sidebar.lastCheckAt) or 0

local function now()
    if getTimestampMs then return getTimestampMs() end
    if getTimeInMillis then return getTimeInMillis() end
    return 0
end

local function playerFor(host)
    local character = host and host.chr or nil
    if character then return character end
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function valueOf(entry, name, host, player, fallback)
    local value = entry[name]
    if type(value) == "function" then
        value = value(entry, host, player)
    end
    if value == nil then return fallback end
    return value
end

local function sortedEntries()
    local result = {}
    for _, entry in pairs(Sidebar.registry) do
        result[#result + 1] = entry
    end
    table.sort(result, function(left, right)
        local leftOrder = tonumber(left.order) or 1000
        local rightOrder = tonumber(right.order) or 1000
        if leftOrder == rightOrder then
            return (left.registrationOrder or 0) < (right.registrationOrder or 0)
        end
        return leftOrder < rightOrder
    end)
    return result
end

local function nativeBottom(host)
    local bottom = 0
    if host.offHand and host.offHand.getBottom then
        bottom = host.offHand:getBottom()
    end
    local children = host.getChildren and host:getChildren() or {}
    for _, child in pairs(children) do
        if child and not child.psychopatzSidebarEntry
            and child.Type == "ISButton"
            and (not child.getIsVisible or child:getIsVisible())
        then
            bottom = math.max(bottom, child:getBottom())
        end
    end
    return bottom
end

local function controlSize(host)
    local slot = host.invBtn or host.healthBtn or host.craftingBtn
        or host.offHand
    local width = slot and slot.getWidth and slot:getWidth() or 48
    local height = slot and slot.getHeight and slot:getHeight()
        or math.floor(width * 0.75)
    return width, height
end

local function resolveImage(entry, host, player)
    local image = entry.image
    if type(image) == "function" then image = image(entry, host, player) end
    if type(image) == "string" and getTexture then
        image = getTexture(image)
    end
    return image
end

local function tooltipFor(entry, host, player)
    local tooltip = valueOf(entry, "tooltip", host, player, entry.title or "")
    return tostring(tooltip or "")
end

local function updateTooltip(host, button, value)
    if not host then return end
    for _, item in ipairs(host.mouseOverList or {}) do
        if item.object == button then
            item.displayString = value
            return
        end
    end
    if host.addMouseOverToolTipItem then
        host:addMouseOverToolTipItem(button, value)
    end
end

function Sidebar.Get(id)
    return Sidebar.registry[tostring(id or "")]
end

function Sidebar.GetEntries()
    return sortedEntries()
end

function Sidebar.Register(definition)
    if type(definition) ~= "table" or not definition.id then
        return nil, "invalid_sidebar_definition"
    end

    local id = tostring(definition.id)
    local entry = Sidebar.registry[id]
    if not entry then
        Sidebar.registrationOrder = Sidebar.registrationOrder + 1
        entry = { id = id, registrationOrder = Sidebar.registrationOrder }
        Sidebar.registry[id] = entry
    end
    for key, value in pairs(definition) do entry[key] = value end
    entry.id = id

    Sidebar.InstallHooks()
    local host = ISEquippedItem and ISEquippedItem.instance or nil
    if host then
        Sidebar.Attach(host)
        Sidebar.Refresh(host)
    end
    return entry
end

Sidebar.Add = Sidebar.Register

function Sidebar.Unregister(id)
    id = tostring(id or "")
    local entry = Sidebar.registry[id]
    if not entry then return false end
    local button = entry.button
    if button and button.parent and button.parent.removeChild then
        button.parent:removeChild(button)
    end
    local host = ISEquippedItem and ISEquippedItem.instance or nil
    if host and host.psychopatzSidebarEntries then
        host.psychopatzSidebarEntries[id] = nil
    end
    Sidebar.registry[id] = nil
    entry.button = nil
    if host then Sidebar.Layout(host) end
    return true
end

function Sidebar.Attach(host)
    if not host or not host.addChild then return nil end
    local player = playerFor(host)
    if player and player.getPlayerNum and player:getPlayerNum() ~= 0 then
        return nil
    end

    host.psychopatzSidebarEntries = host.psychopatzSidebarEntries or {}
    local width, height = controlSize(host)
    for _, entry in ipairs(sortedEntries()) do
        local button = host.psychopatzSidebarEntries[entry.id]
        if not button then
            button = ISButton:new(0, 0, width, height, "", entry,
                Sidebar.OnClick)
            button.psychopatzSidebarEntry = entry.id
            button.internal = entry.id
            button:initialise()
            button:instantiate()
            button:setDisplayBackground(valueOf(entry,
                "displayBackground", host, player, false))
            local image = resolveImage(entry, host, player)
            if image and button.setImage then
                button:setImage(image)
                button.psychopatzSidebarImage = image
            end
            if button.setTitle then
                button:setTitle(tostring(valueOf(entry, "title", host,
                    player, "") or ""))
            end
            host:addChild(button)
            host.psychopatzSidebarEntries[entry.id] = button
            updateTooltip(host, button, tooltipFor(entry, host, player))
        end
        entry.button = button
    end
    return host
end

function Sidebar.OnClick(entry, button, ...)
    entry = entry or (button and Sidebar.Get(button.internal))
    if not entry or type(entry.onClick) ~= "function" then return end
    local host = button and button.parent or nil
    local player = playerFor(host)
    return entry.onClick(entry, button, host, player, ...)
end

function Sidebar.Layout(host, useCachedState)
    if not host then return end
    local width, height = controlSize(host)
    local y = nativeBottom(host) + SIDEBAR_GAP
    local player = playerFor(host)

    for _, entry in ipairs(sortedEntries()) do
        local button = host.psychopatzSidebarEntries
            and host.psychopatzSidebarEntries[entry.id]
        if button then
            if button:getWidth() ~= width then button:setWidth(width) end
            if button:getHeight() ~= height then button:setHeight(height) end
            local visible
            if useCachedState and entry._visible ~= nil then
                visible = entry._visible
            else
                visible = valueOf(entry, "visible", host, player, true) ~= false
            end
            button:setVisible(visible)
            if visible then
                if button:getX() ~= 0 then button:setX(0) end
                if button:getY() ~= y then button:setY(y) end
                y = button:getBottom() + SIDEBAR_GAP
            end
        end
    end

    host:setHeight(math.max(nativeBottom(host), y - SIDEBAR_GAP))
end

function Sidebar.Refresh(host)
    host = host or (ISEquippedItem and ISEquippedItem.instance or nil)
    if not host then return nil end
    Sidebar.Attach(host)
    local player = playerFor(host)
    for _, entry in ipairs(sortedEntries()) do
        local button = host.psychopatzSidebarEntries
            and host.psychopatzSidebarEntries[entry.id]
        if button then
            local visible = valueOf(entry, "visible", host, player, true) ~= false
            entry._visible = visible
            local enabled = visible
                and valueOf(entry, "enabled", host, player, true) ~= false
            button.enable = enabled
            if button.setTitle then
                button:setTitle(tostring(valueOf(entry, "title", host,
                    player, "") or ""))
            end
            local variant = enabled
                and valueOf(entry, "variant", host, player, "default")
                or valueOf(entry, "disabledVariant", host, player, "quiet")
            if UI.StyleButton then UI.StyleButton(button, variant) end
            updateTooltip(host, button, tooltipFor(entry, host, player))
            local image = resolveImage(entry, host, player)
            if image and button.setImage
                and button.psychopatzSidebarImage ~= image
            then
                button:setImage(image)
                button.psychopatzSidebarImage = image
            end
        end
    end
    Sidebar.Layout(host)
    return host
end

function Sidebar.RefreshImages(host, at)
    host = host or (ISEquippedItem and ISEquippedItem.instance or nil)
    if not host then return nil end
    local player = playerFor(host)
    at = tonumber(at) or now()
    for _, entry in ipairs(sortedEntries()) do
        local interval = tonumber(entry.imageRefreshInterval)
        local button = host.psychopatzSidebarEntries
            and host.psychopatzSidebarEntries[entry.id]
        if button and interval and interval > 0
            and at - (tonumber(entry.lastImageRefreshAt) or 0) >= interval
        then
            entry.lastImageRefreshAt = at
            local image = resolveImage(entry, host, player)
            if image and button.setImage
                and button.psychopatzSidebarImage ~= image
            then
                button:setImage(image)
                button.psychopatzSidebarImage = image
            end
        end
    end
    return host
end

function Sidebar.InstallHooks()
    if not ISEquippedItem then return false end
    if not Sidebar.originalInitialise
        and type(ISEquippedItem.initialise) == "function" then
        Sidebar.originalInitialise = ISEquippedItem.initialise
        ISEquippedItem.initialise = function(host, ...)
            Sidebar.originalInitialise(host, ...)
            Sidebar.Attach(host)
            Sidebar.Refresh(host)
        end
    end
    if not Sidebar.originalPrerender
        and type(ISEquippedItem.prerender) == "function" then
        Sidebar.originalPrerender = ISEquippedItem.prerender
        ISEquippedItem.prerender = function(host, ...)
            Sidebar.originalPrerender(host, ...)
            if not host.getIsVisible or host:getIsVisible() then
                -- The base sidebar renders every frame. State predicates,
                -- textures, tooltips, and styles are refreshed on the bounded
                -- OnTick cadence; only geometry must follow vanilla changes
                -- immediately after prerender.
                Sidebar.Layout(host, true)
            end
        end
    end
    return true
end

function Sidebar.OnTick()
    Sidebar.InstallHooks()
    local at = now()
    Sidebar.RefreshImages(ISEquippedItem and ISEquippedItem.instance or nil,
        at)
    if at - (tonumber(Sidebar.lastCheckAt) or 0) < CHECK_INTERVAL then
        return
    end
    Sidebar.lastCheckAt = at
    Sidebar.Refresh(ISEquippedItem and ISEquippedItem.instance or nil)
end

if Events and Events.OnTick and not Sidebar.tickHooked then
    Events.OnTick.Add(Sidebar.OnTick)
    Sidebar.tickHooked = true
end

return Sidebar
