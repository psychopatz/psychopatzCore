require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"

PsychopatzCore.Notifications = PsychopatzCore.Notifications or {}

local Notifications = PsychopatzCore.Notifications
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

Notifications.Queue = Notifications.Queue or {}
Notifications.QueuedIDs = Notifications.QueuedIDs or {}

PsychopatzNotificationWindow = UI.Window:derive(
    "PsychopatzNotificationWindow")

local function drawDetail(list, y, entry, alternate)
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local row = entry.item or {}
    local color = Theme.colors.text
    list:drawText(tostring(row.text or ""), 8, y + 6,
        color.r, color.g, color.b, color.a, UIFont.Small)
    return y + list.itemheight
end

function PsychopatzNotificationWindow:createChildren()
    UI.Window.createChildren(self)
    self.details = UI.CreateList(self, {
        itemHeight = 25,
        doDrawItem = drawDetail,
    })
    self.dismissButton = UI.CreateButton(self, {
        id = "dismiss", title = "Close", target = self,
        onclick = PsychopatzNotificationWindow.onDismiss,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
end

function PsychopatzNotificationWindow:onResponsiveLayout()
    if not self.details then return end
    local rect = self:getContentRect({ top = 58, bottom = 42 })
    Layout.SetBounds(self.details, rect.x, rect.y, rect.width, rect.height)
    Layout.SetBounds(self.dismissButton,
        self:getWidth() - Layout.Pixels(88, self.uiScale),
        self:getHeight() - Layout.Pixels(34, self.uiScale),
        Layout.Pixels(78, self.uiScale), Layout.Pixels(26, self.uiScale))
end

function PsychopatzNotificationWindow:applyNotification(definition)
    self.notification = definition
    self:setTitle(tostring(definition.title or "Notification"))
    self.details:clear()
    for index, value in ipairs(definition.details or {}) do
        self.details:addItem(tostring(index), { text = tostring(value) })
    end
    self:requestResponsiveLayout(true)
end

function PsychopatzNotificationWindow:prerender()
    UI.Window.prerender(self)
    local rect = self:getContentRect({ top = 30, bottom = 10 })
    local color = Theme.colors.text
    self:drawText(tostring(self.notification
        and self.notification.message or ""), rect.x, rect.y,
        color.r, color.g, color.b, color.a, UIFont.Small)
end

function PsychopatzNotificationWindow:onDismiss()
    local id = self.notification and self.notification.id
    if id then Notifications.QueuedIDs[tostring(id)] = nil end
    self:setVisible(false)
    self:removeFromUIManager()
    Notifications.instance = nil
    Notifications.ShowNext()
end

function PsychopatzNotificationWindow:new(x, y, width, height)
    return UI.Window.new(self, x, y, width, height, {
        title = "Notification", persistGeometry = false,
        responsiveSpec = {
            width = width, height = height,
            minWidth = 360, minHeight = 190,
            maxWidth = 620, maxHeight = 480,
            anchor = "top_right",
        },
    })
end

function Notifications.ShowNext()
    if Notifications.instance or #Notifications.Queue < 1 then return false end
    local definition = table.remove(Notifications.Queue, 1)
    local bounds = Layout.ResolveWindow({
        width = 480, height = 270,
        minWidth = 360, minHeight = 190,
        maxWidth = 620, maxHeight = 480,
        anchor = "top_right",
    })
    local window = PsychopatzNotificationWindow:new(
        bounds.x, bounds.y, bounds.width, bounds.height)
    window:initialise()
    window:instantiate()
    window:applyNotification(definition)
    window:addToUIManager()
    window:bringToTop()
    Notifications.instance = window
    return true
end

function Notifications.Show(definition)
    definition = type(definition) == "table" and definition or {}
    local id = tostring(definition.id or "notification:"
        .. tostring(getTimeInMillis and getTimeInMillis() or 0))
    if Notifications.QueuedIDs[id] then return false, "duplicate" end
    definition.id = id
    definition.details = type(definition.details) == "table"
        and definition.details or {}
    Notifications.QueuedIDs[id] = true
    Notifications.Queue[#Notifications.Queue + 1] = definition
    Notifications.ShowNext()
    return true
end

return Notifications
