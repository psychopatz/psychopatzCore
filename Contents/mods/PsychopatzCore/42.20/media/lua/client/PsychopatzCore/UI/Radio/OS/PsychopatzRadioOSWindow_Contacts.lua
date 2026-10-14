-- Contacts-provider page rendering for the Core Radio OS window.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Model = OS.Model or require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSModel"
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function tr(key, fallback)
    return Text.Get(key, fallback)
end

local function text(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

local function safeCall(target, method, ...)
    if not target or type(target[method]) ~= "function" then
        return false, nil
    end
    return pcall(target[method], target, ...)
end

function Window:ensureContacts(force)
    local revision = OS.GetRegistryRevision()
    if not force and self.contacts and self.contactsRevision == revision then
        return
    end
    local contacts = {}
    local failed = false
    for _, provider in ipairs(OS.ListContactProviders(self.context)) do
        if #contacts >= Model.MAX_CONTACTS then break end
        local ok, page = OS.ListContacts(provider.id, self.context, {
            offset = 0, limit = Model.MAX_PAGE_SIZE, sort = "title",
        })
        if ok and page then
            for _, entry in ipairs(page.contacts or {}) do
                if #contacts >= Model.MAX_CONTACTS then break end
                contacts[#contacts + 1] = entry
            end
        else
            failed = true
        end
    end
    Model.SortContacts(contacts)
    self.contacts = contacts
    self.contactsRevision = revision
    self.contactStatus = failed
        and tr("UI_PsychopatzCore_Radio_ContactError", "CONTACT ERROR")
        or (#contacts == 0
            and tr("UI_PsychopatzCore_Radio_NoContacts", "NO CONTACTS")
            or nil)
    self.contactIndex = clamp(self.contactIndex, 1, math.max(1, #contacts))
end

function Window:drawContacts()
    self:ensureContacts(false)
    local screen = self:screenRect()
    local scale = self.scale
    local color = self:screenColors()
    self:drawScreenHeader(tr("UI_PsychopatzCore_Radio_Contacts", "CONTACTS"),
        self.contactStatus or self:statusLine())
    if #self.contacts == 0 then
        self:drawTextClipped(
            tr("UI_PsychopatzCore_Radio_NoContacts", "NO CONTACTS"),
            screen.x + 4 * scale,
            screen.y + 33 * scale, screen.w - 8 * scale, color)
        return
    end
    self.contactIndex = clamp(self.contactIndex, 1, #self.contacts)
    local first = math.floor((self.contactIndex - 1) / 2) * 2 + 1
    for row = 0, 1 do
        local entry = self.contacts[first + row]
        if not entry then break end
        local y = screen.y + (29 + row * 13) * scale
        local selected = first + row == self.contactIndex
        if selected then
            self:drawRect(screen.x + 2 * scale, y - scale,
                screen.w - 4 * scale, 12 * scale, 0.3,
                color.r * 0.2, color.g * 0.2, color.b * 0.2)
        end
        local rowColor = selected and color
            or { r = color.r * 0.62, g = color.g * 0.62,
                b = color.b * 0.62, a = 1 }
        self:drawTextClipped(entry.title,
            screen.x + 5 * scale, y, screen.w - 10 * scale,
            rowColor, math.floor(screen.w / (7 * scale)))
    end
end

function Window:updatePortrait()
    local panel = self.portraitPanel
    local entry = self.selectedContact
    if not panel or not entry or not entry.portraitDescriptor then
        if panel then panel:setVisible(false) end
        return
    end
    local ok = safeCall(panel, "setTarget", nil,
        entry.portraitDescriptor, true)
    if ok then panel:setVisible(true) else panel:setVisible(false) end
end

function Window:layoutPortrait()
    local panel = self.portraitPanel
    if not panel then return end
    local screen = self:screenRect()
    local width = math.max(1, math.floor(screen.w * 0.38))
    local height = math.max(1, math.floor(screen.h - 22 * self.scale))
    if panel.setPortraitBounds then
        panel:setPortraitBounds(screen.x + 2 * self.scale,
            screen.y + 20 * self.scale, width, height)
    else
        panel:setX(screen.x + 2 * self.scale)
        panel:setY(screen.y + 20 * self.scale)
        panel:setWidth(width)
        panel:setHeight(height)
    end
end

function Window:drawContactDetail()
    local entry = self.selectedContact
    local screen = self:screenRect()
    local scale = self.scale
    local color = self:screenColors()
    self:drawScreenHeader(entry and entry.title
        or tr("UI_PsychopatzCore_Radio_Contact", "CONTACT"),
        entry and entry.status
        or tr("UI_PsychopatzCore_Radio_Unknown", "unknown"))
    local x = screen.x + 4 * scale
    local y = screen.y + 31 * scale
    if entry and entry.portraitDescriptor then x = screen.x + screen.w * 0.42 end
    self:drawTextClipped(Text.Format("UI_PsychopatzCore_Radio_StatusValue",
        "STATUS: %s", text(entry and entry.status,
            tr("UI_PsychopatzCore_Radio_Unknown", "unknown"))),
        x, y, screen.w - (x - screen.x) - 4 * scale,
        color, math.floor((screen.w - (x - screen.x)) / (7 * scale)))
    local actions = entry and entry.actions or {}
    if #actions > 0 then
        self:drawTextClipped(Text.Format("UI_PsychopatzCore_Radio_CenterAction",
            "CENTER: %s", actions[1].label),
            x, y + 14 * scale, screen.w - (x - screen.x) - 4 * scale,
            color, math.floor((screen.w - (x - screen.x)) / (7 * scale)))
    else
        self:drawTextClipped(
            tr("UI_PsychopatzCore_Radio_NoAction", "NO ACTION"),
            x, y + 14 * scale,
            screen.w - (x - screen.x) - 4 * scale, color)
    end
end

return Window
