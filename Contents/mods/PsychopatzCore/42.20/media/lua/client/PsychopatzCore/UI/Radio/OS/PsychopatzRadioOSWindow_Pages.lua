-- Home and extension-page rendering for the Core Radio OS window.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function tr(key, fallback)
    return Text.Get(key, fallback)
end

function Window:drawHome()
    local apps = OS.ListApps(self.context)
    local color = self:screenColors()
    local header = self:drawScreenHeader(
        tr("UI_PsychopatzCore_Radio_Home", "HOME"), self:statusLine())
    if #apps == 0 then
        self:drawTextClipped(tr("UI_PsychopatzCore_Radio_NoApps", "NO APPS"),
            header.metrics.x, header.contentY, header.metrics.width, color)
        return
    end
    self.homeIndex = clamp(self.homeIndex, 1, #apps)
    local layout = self:screenListLayout(#apps, 3, self.homeIndex, header)
    local first = layout.first
    for offset = 0, layout.visible - 1 do
        local row = self:screenRowRect(layout, offset)
        local index = first + offset
        local app = apps[index]
        if not app or not row then break end
        local selected = index == self.homeIndex
        local rowColor = selected and color
            or { r = color.r * 0.62, g = color.g * 0.62,
                b = color.b * 0.62, a = 1 }
        if selected then
            self:drawSprite("home_tile_selected", row.x, row.y,
                row.h, row.h, 0.85)
            self:drawRect(row.x, row.y, row.w, row.h, 0.22,
                color.r * 0.2, color.g * 0.2, color.b * 0.2)
        else
            self:drawSprite("home_tile_idle", row.x, row.y,
                row.h, row.h, 0.7)
        end
        if app.icon then
            local inset = math.max(1, math.floor(row.h * 0.12))
            self:drawSprite(app.icon, row.x + inset, row.y + inset,
                row.h - inset * 2, row.h - inset * 2, selected and 1 or 0.75)
        end
        self:drawTextClipped(app.label or app.id,
            row.x + row.h + math.max(2, math.floor(layout.metrics.scale)),
            row.y, row.w - row.h - math.max(2, math.floor(layout.metrics.scale)),
            rowColor)
    end
end

function Window:homeRowAt(x, y)
    local apps = OS.ListApps(self.context)
    if #apps == 0 then return nil end
    self.homeIndex = clamp(self.homeIndex, 1, #apps)
    local header = self:headerLayout(self:statusLine())
    local layout = self:screenListLayout(#apps, 3, self.homeIndex, header)
    for offset = 0, layout.visible - 1 do
        local row = self:screenRowRect(layout, offset)
        if self:isInside(row, x, y) then
            return { kind = "home", index = layout.first + offset }
        end
    end
    return nil
end

function Window:drawSettings()
    local color = self:screenColors()
    local header = self:drawScreenHeader(
        tr("UI_PsychopatzCore_Radio_Settings", "SETTINGS"), nil,
        { showSubtitle = false })
    self:drawTextClipped(Text.Format("UI_PsychopatzCore_Radio_Scale",
        "SCALE %.1f", self.scale),
        header.metrics.x, header.contentY, header.metrics.width, color)
    self:drawTextClipped(tr("UI_PsychopatzCore_Radio_LeftBack", "LEFT: BACK"),
        header.metrics.x, header.contentY + header.metrics.lineHeight,
        header.metrics.width, color)
end

function Window:drawCustom()
    local app = self.activeApp
    if app and type(app.render) == "function" then
        local screen = self:screenRect()
        local ok, result = pcall(app.render, self.context, self, screen, app)
        if not ok then
            self.statusText = tr("UI_PsychopatzCore_Radio_AppError", "APP ERROR")
            print("[PsychopatzCore][RadioOS] app render failed: "
                .. tostring(result))
        end
        return
    end
    local header = self:drawScreenHeader(app and app.label
        or tr("UI_PsychopatzCore_Radio_App", "APP"), self:statusLine())
    self:drawTextClipped(tr("UI_PsychopatzCore_Radio_NoScreen", "NO SCREEN"),
        header.metrics.x, header.contentY, header.metrics.width,
        self:screenColors())
end

require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Contacts"

return Window
