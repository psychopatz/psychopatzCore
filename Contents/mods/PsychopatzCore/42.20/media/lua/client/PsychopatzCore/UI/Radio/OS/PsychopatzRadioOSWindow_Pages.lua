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
    local screen = self:screenRect()
    local scale = self.scale
    local color = self:screenColors()
    self:drawScreenHeader(tr("UI_PsychopatzCore_Radio_Home", "HOME"),
        self:statusLine())
    if #apps == 0 then
        self:drawTextClipped(tr("UI_PsychopatzCore_Radio_NoApps", "NO APPS"),
            screen.x + 4 * scale,
            screen.y + 32 * scale, screen.w - 8 * scale, color)
        return
    end
    self.homeIndex = clamp(self.homeIndex, 1, #apps)
    local rowY = screen.y + 29 * scale
    local first = math.floor((self.homeIndex - 1) / 3) * 3 + 1
    for offset = 0, 2 do
        local index = first + offset
        local app = apps[index]
        if not app then break end
        local selected = index == self.homeIndex
        local rowColor = selected and color
            or { r = color.r * 0.62, g = color.g * 0.62,
                b = color.b * 0.62, a = 1 }
        if selected then
            self:drawRect(screen.x + 2 * scale, rowY - scale,
                screen.w - 4 * scale, 13 * scale, 0.3,
                color.r * 0.2, color.g * 0.2, color.b * 0.2)
        end
        self:drawTextClipped(app.label or app.id,
            screen.x + 5 * scale, rowY,
            screen.w - 10 * scale, rowColor,
            math.floor(screen.w / (7 * scale)))
        rowY = rowY + 13 * scale
    end
end

function Window:drawSettings()
    local screen = self:screenRect()
    local scale = self.scale
    local color = self:screenColors()
    self:drawScreenHeader(tr("UI_PsychopatzCore_Radio_Settings", "SETTINGS"),
        tr("UI_PsychopatzCore_Radio_CoreSubtitle", "CORE RADIO OS"))
    self:drawTextClipped(Text.Format("UI_PsychopatzCore_Radio_Scale",
        "SCALE %.1f", self.scale),
        screen.x + 4 * scale, screen.y + 32 * scale,
        screen.w - 8 * scale, color)
    self:drawTextClipped(tr("UI_PsychopatzCore_Radio_LeftBack", "LEFT: BACK"),
        screen.x + 4 * scale,
        screen.y + 45 * scale, screen.w - 8 * scale, color)
end

function Window:drawCustom()
    local app = self.activeApp
    local screen = self:screenRect()
    if app and type(app.render) == "function" then
        local ok, result = pcall(app.render, self.context, self, screen, app)
        if not ok then
            self.statusText = tr("UI_PsychopatzCore_Radio_AppError", "APP ERROR")
            print("[PsychopatzCore][RadioOS] app render failed: "
                .. tostring(result))
        end
        return
    end
    self:drawScreenHeader(app and app.label
        or tr("UI_PsychopatzCore_Radio_App", "APP"), self:statusLine())
    self:drawTextClipped(tr("UI_PsychopatzCore_Radio_NoScreen", "NO SCREEN"),
        screen.x + 4 * self.scale,
        screen.y + 32 * self.scale, screen.w - 8 * self.scale,
        self:screenColors())
end

require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Contacts"

return Window
