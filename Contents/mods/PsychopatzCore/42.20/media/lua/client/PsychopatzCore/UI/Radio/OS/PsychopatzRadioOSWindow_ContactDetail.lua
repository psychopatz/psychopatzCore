-- Contact detail and portrait presentation for the Core Radio OS window.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window

local function tr(key, fallback)
    return Text.Get(key, fallback)
end

local function text(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

function Window:updatePortrait()
    local panel = self.portraitPanel
    local entry = self.selectedContact
    if not panel or not entry or not entry.portraitDescriptor then
        if panel then panel:setVisible(false) end
        return
    end
    local ok = false
    if type(panel.setTarget) == "function" then
        ok = pcall(panel.setTarget, panel, nil,
            entry.portraitDescriptor, true)
    end
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
