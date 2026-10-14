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
    local color = self:screenColors()
    local header = self:drawScreenHeader(
        tr("UI_PsychopatzCore_Radio_Contacts", "CONTACTS"),
        self.contactStatus or self:statusLine())
    if #self.contacts == 0 then
        self:drawTextClipped(
            tr("UI_PsychopatzCore_Radio_NoContacts", "NO CONTACTS"),
            header.metrics.x, header.contentY, header.metrics.width, color)
        return
    end
    self.contactIndex = clamp(self.contactIndex, 1, #self.contacts)
    local layout = self:screenListLayout(#self.contacts, 2,
        self.contactIndex, header)
    local first = layout.first
    for row = 0, layout.visible - 1 do
        local entry = self.contacts[first + row]
        local rect = self:screenRowRect(layout, row)
        if not entry or not rect then break end
        local selected = first + row == self.contactIndex
        if selected then
            self:drawSprite("listrow_green_selected", rect.x, rect.y,
                rect.w, rect.h, 0.9)
        end
        local rowColor = selected and color
            or { r = color.r * 0.62, g = color.g * 0.62,
                b = color.b * 0.62, a = 1 }
        if not selected then
            self:drawSprite("listrow_green_idle", rect.x, rect.y,
                rect.w, rect.h, 0.65)
        end
        self:drawTextClipped(entry.title,
            rect.x + math.max(2, math.floor(layout.metrics.scale)), rect.y,
            rect.w - math.max(2, math.floor(layout.metrics.scale)) * 2,
            rowColor)
    end
end

function Window:contactRowAt(x, y)
    self:ensureContacts(false)
    if #self.contacts == 0 then return nil end
    self.contactIndex = clamp(self.contactIndex, 1, #self.contacts)
    local header = self:headerLayout(self.contactStatus or self:statusLine())
    local layout = self:screenListLayout(#self.contacts, 2,
        self.contactIndex, header)
    for offset = 0, layout.visible - 1 do
        local rect = self:screenRowRect(layout, offset)
        if self:isInside(rect, x, y) then
            return { kind = "contact", index = layout.first + offset }
        end
    end
    return nil
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
    local metrics = self:screenMetrics()
    local height = math.max(1, math.floor(screen.h - metrics.lineHeight * 2
        - metrics.padding * 2))
    local width = math.max(1, math.min(math.floor(screen.w * 0.38), height))
    if panel.setPortraitBounds then
        panel:setPortraitBounds(screen.x + 2 * self.scale,
            screen.y + metrics.lineHeight * 2, width, height)
    else
        panel:setX(screen.x + 2 * self.scale)
        panel:setY(screen.y + metrics.lineHeight * 2)
        panel:setWidth(width)
        panel:setHeight(height)
    end
end

function Window:drawContactDetail()
    local entry = self.selectedContact
    local screen = self:screenRect()
    local color = self:screenColors()
    local header = self:drawScreenHeader(entry and entry.title
        or tr("UI_PsychopatzCore_Radio_Contact", "CONTACT"),
        text(entry and entry.status,
            tr("UI_PsychopatzCore_Radio_Unknown", "unknown")))
    local x = header.metrics.x
    local y = header.contentY
    if entry and entry.portraitDescriptor then
        x = screen.x + math.floor(screen.w * 0.42)
    end
    self:drawTextClipped(Text.Format("UI_PsychopatzCore_Radio_StatusValue",
        "STATUS: %s", text(entry and entry.status,
            tr("UI_PsychopatzCore_Radio_Unknown", "unknown"))),
        x, y, screen.w - (x - screen.x) - header.metrics.padding, color)
    local actions = entry and entry.actions or {}
    if #actions > 0 then
        self:drawTextClipped(Text.Format("UI_PsychopatzCore_Radio_CenterAction",
            "CENTER: %s", actions[1].label),
            x, y + header.metrics.lineHeight,
            screen.w - (x - screen.x) - header.metrics.padding, color)
    else
        self:drawTextClipped(
            tr("UI_PsychopatzCore_Radio_NoAction", "NO ACTION"),
            x, y + header.metrics.lineHeight,
            screen.w - (x - screen.x) - header.metrics.padding, color)
    end
end

function Window:contactDetailActionAt(x, y)
    if not self.selectedContact then return nil end
    local header = self:headerLayout(text(self.selectedContact.status,
        tr("UI_PsychopatzCore_Radio_Unknown", "unknown")))
    if y >= header.contentY and self:isInside(header.metrics.screen, x, y) then
        return { kind = "contact_action" }
    end
    return nil
end

return Window
