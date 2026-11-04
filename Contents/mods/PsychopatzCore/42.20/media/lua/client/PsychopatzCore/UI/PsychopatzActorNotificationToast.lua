-- Compact, non-blocking actor notification surface.
-- Payloads are provider-neutral; callers may add a faction badge and the
-- canonical portrait projection already available to the client.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ActorNotifications =
    PsychopatzCore.ActorNotifications or {}

local Notifications = PsychopatzCore.ActorNotifications
Notifications.MAX_QUEUE = tonumber(Notifications.MAX_QUEUE) or 12
Notifications.DISPLAY_MS = tonumber(Notifications.DISPLAY_MS) or 6500
Notifications.Queue = Notifications.Queue or {}
Notifications.QueuedIDs = Notifications.QueuedIDs or {}
Notifications.instance = Notifications.instance or nil

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 0
end

local function boundedText(value, limit, fallback)
    value = tostring(value or fallback or "")
    if #value > limit then value = string.sub(value, 1, limit) end
    return value
end

local function resolvePortrait(spec)
    if type(spec) == "table" then return spec end
    local ok, Client = pcall(
        require,
        "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
    )
    if ok and Client and type(Client.GetPortraitSpec) == "function" then
        return Client.GetPortraitSpec(spec)
    end
    return nil
end

local function closeWindow(window)
    if not window then return false end
    if window.setVisible then window:setVisible(false) end
    if window.removeFromUIManager then window:removeFromUIManager() end
    if Notifications.instance == window then
        Notifications.instance = nil
    end
    return true
end

local function createWindowSupport()
    if Notifications._windowSupport then
        return Notifications._windowSupport
    end
    if type(ISPanel) ~= "table" and type(ISPanel) ~= "function" then
        return nil
    end

    local ok, UI = pcall(require, "PsychopatzCore/UI/PsychopatzUI")
    if not ok or type(UI) ~= "table" or not UI.Window then return nil end
    local portraitOK, PortraitPanel = pcall(
        require,
        "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
    )
    if not portraitOK or not PortraitPanel then return nil end

    local ToastWindow = UI.Window:derive(
        "PsychopatzActorNotificationToastWindow")

    function ToastWindow:createChildren()
        UI.Window.createChildren(self)
        self.portrait = PortraitPanel:new(
            12, 12, 76, 76,
            {
                faceOnly = true,
                showBackground = true,
                showBorder = true,
                animate = false,
                zoom = 16,
                yOffset = -0.9,
            }
        )
        if self.portrait.initialise then self.portrait:initialise() end
        if self.portrait.instantiate then self.portrait:instantiate() end
        self:addChild(self.portrait)
        self:requestResponsiveLayout(true)
    end

    function ToastWindow:onResponsiveLayout()
        if not self.portrait then return end
        self.portrait.x = 12
        self.portrait.y = 12
        self.portrait.width = 76
        self.portrait.height = 76
    end

    function ToastWindow:applyNotification(definition)
        self.notification = definition
        if self.setTitle then
            self:setTitle(tostring(definition.name or "Notification"))
        end
        if self.portrait and self.portrait.setTarget then
            self.portrait:setTarget(nil, definition.portraitSpec, true)
        end
        self.startedAt = nowMs()
        self.expiresAt = self.startedAt > 0
            and self.startedAt + Notifications.DISPLAY_MS or 0
        self:requestResponsiveLayout(true)
    end

    function ToastWindow:prerender()
        UI.Window.prerender(self)
        if self.expiresAt > 0 and nowMs() >= self.expiresAt then
            Notifications.Dismiss(
                self.notification and self.notification.id,
                self
            )
        end
        local definition = self.notification or {}
        local Theme = UI.Theme
        local color = Theme and Theme.colors and Theme.colors.text
            or { r = 1, g = 1, b = 1, a = 1 }
        local x = 100
        local width = math.max(60, (self:getWidth() or 300) - x - 12)
        self:drawText(
            boundedText(definition.message, 180, ""),
            x,
            48,
            color.r,
            color.g,
            color.b,
            color.a,
            UIFont.Small
        )
        if definition.factionBadge and definition.factionBadge.glyph then
            self:drawTextRight(
                tostring(definition.factionBadge.glyph),
                (self:getWidth() or 300) - 10,
                12,
                color.r,
                color.g,
                color.b,
                color.a,
                UIFont.Small
            )
        end
        if self.drawCircle then
            self:drawCircle(50, 50, 40, 0.9, 0.1, 0.1, 0.1)
        end
    end

    Notifications._windowSupport = {
        Window = ToastWindow,
        Layout = UI.Layout,
    }
    return Notifications._windowSupport
end

function Notifications.Show(definition)
    definition = type(definition) == "table" and definition or {}
    local id = boundedText(
        definition.id or definition.notificationID,
        192,
        "actor-toast:" .. tostring(nowMs())
    )
    if Notifications.QueuedIDs[id] then
        return false, "duplicate"
    end

    local item = {
        id = id,
        actorID = boundedText(
            definition.actorID or definition.actorId, 192, nil
        ),
        name = boundedText(
            definition.name or definition.title,
            96,
            definition.actorID or "Actor"
        ),
        message = boundedText(definition.message, 180, ""),
        secondary = boundedText(definition.secondary, 96, nil),
        portraitSpec = resolvePortrait(
            definition.portraitSpec or definition.actorID
        ),
        factionBadge = type(definition.factionBadge) == "table"
            and definition.factionBadge or nil,
        createdAt = nowMs(),
    }

    while #Notifications.Queue >= Notifications.MAX_QUEUE do
        local removed = table.remove(Notifications.Queue, 1)
        if removed and removed.id then
            Notifications.QueuedIDs[removed.id] = nil
        end
    end
    Notifications.Queue[#Notifications.Queue + 1] = item
    Notifications.QueuedIDs[id] = true
    Notifications.ShowNext()
    return true, item
end

function Notifications.ShowNext()
    if Notifications.instance or #Notifications.Queue < 1 then
        return false
    end
    local support = createWindowSupport()
    if not support then return false, "ui_unavailable" end
    local definition = table.remove(Notifications.Queue, 1)
    local Layout = support.Layout
    local bounds
    if Layout and Layout.ResolveWindow then
        bounds = Layout.ResolveWindow({
            width = 430,
            height = 116,
            minWidth = 340,
            minHeight = 100,
            maxWidth = 620,
            maxHeight = 160,
            anchor = "top_right",
        })
    else
        bounds = { x = 20, y = 20, width = 430, height = 116 }
    end
    local window = support.Window:new(
        bounds.x, bounds.y, bounds.width, bounds.height)
    window:initialise()
    window:instantiate()
    window:applyNotification(definition)
    window:addToUIManager()
    window:bringToTop()
    Notifications.instance = window
    return true
end

function Notifications.Dismiss(id, window)
    id = tostring(id or "")
    if id == "" then return false end
    local found = false
    for index = #Notifications.Queue, 1, -1 do
        if tostring(Notifications.Queue[index].id or "") == id then
            table.remove(Notifications.Queue, index)
            found = true
        end
    end
    if Notifications.instance
        and tostring(Notifications.instance.notification
            and Notifications.instance.notification.id or "") == id
    then
        closeWindow(Notifications.instance)
        found = true
    elseif window and Notifications.instance == window then
        closeWindow(window)
        found = true
    end
    if Notifications.QueuedIDs[id] then
        Notifications.QueuedIDs[id] = nil
        found = true
    end
    if found then Notifications.ShowNext() end
    return found
end

function Notifications.Clear()
    Notifications.Queue = {}
    Notifications.QueuedIDs = {}
    closeWindow(Notifications.instance)
    return true
end

return Notifications
