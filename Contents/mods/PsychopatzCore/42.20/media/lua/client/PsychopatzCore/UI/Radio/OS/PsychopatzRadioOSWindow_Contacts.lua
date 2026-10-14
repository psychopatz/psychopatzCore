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

local MAX_PROVIDER_PAGES = math.ceil(Model.MAX_CONTACTS
    / Model.MAX_PAGE_SIZE) + 1

function Window:ensureContacts(force)
    local revision = OS.GetRegistryRevision()
    if not force and self.contacts and self.contactsRevision == revision then
        return
    end
    local contacts = {}
    local seen = {}
    local selectedKey = self.selectedContact
        and Model.ContactKey(self.selectedContact) or nil
    local failed = false
    for _, provider in ipairs(OS.ListContactProviders(self.context)) do
        if #contacts >= Model.MAX_CONTACTS then break end
        local offset = 0
        for _ = 1, MAX_PROVIDER_PAGES do
            if #contacts >= Model.MAX_CONTACTS then break end
            local ok, page = OS.ListContacts(provider.id, self.context, {
                offset = offset, limit = Model.MAX_PAGE_SIZE, sort = "title",
            })
            if not ok or not page then
                failed = true
                break
            end
            local rows = page.contacts or {}
            for _, entry in ipairs(rows) do
                if #contacts >= Model.MAX_CONTACTS then break end
                local key = Model.ContactKey(entry)
                if not seen[key] then
                    seen[key] = true
                    contacts[#contacts + 1] = entry
                end
            end
            local nextOffset = tonumber(page.nextOffset)
            if #rows == 0 or not nextOffset or nextOffset <= offset then
                break
            end
            offset = math.floor(nextOffset)
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
    local selectedIndex
    if selectedKey then
        for index, entry in ipairs(contacts) do
            if Model.ContactKey(entry) == selectedKey then
                selectedIndex = index
                break
            end
        end
    end
    self.contactIndex = selectedIndex or clamp(self.contactIndex, 1,
        math.max(1, #contacts))
    self.selectedContact = selectedIndex and contacts[selectedIndex] or nil
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

require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_ContactDetail"

return Window
