-- Shared physical-radio drawing and frame lifecycle for the Radio OS window.
-- Page-specific presentation lives in PsychopatzRadioOSWindow_Pages.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Manifest = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioManifest"
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Layout"

local function text(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

function Window:screenRect()
    local screen = self.skin and self.skin.screen or {}
    local scale = tonumber(self.scale) or 1
    return {
        x = (tonumber(screen.x) or 0) * scale,
        y = (tonumber(screen.y) or 0) * scale,
        w = (tonumber(screen.w) or 1) * scale,
        h = (tonumber(screen.h) or 1) * scale,
    }
end

function Window:controlRect(name)
    local control = self.skin and self.skin.controls
        and self.skin.controls[name] or nil
    if not control then return nil end
    local scale = tonumber(self.scale) or 1
    return {
        x = control.x * scale,
        y = control.y * scale,
        w = control.w * scale,
        h = control.h * scale,
    }
end

function Window:isInside(rect, x, y)
    return rect and x >= rect.x and y >= rect.y
        and x <= rect.x + rect.w and y <= rect.y + rect.h
end

function Window:hitControl(x, y)
    for _, name in ipairs({ "left", "center", "right" }) do
        if self:isInside(self:controlRect(name), x, y) then return name end
    end
    return nil
end

function Window:atlasTexture(path)
    if not path or not getTexture then return nil end
    if self._textures[path] == nil then
        self._textures[path] = getTexture(path)
    end
    return self._textures[path]
end

function Window:spriteDefinition(id)
    if not id then return nil, nil, nil end
    local cached = self._spriteDefinitions[id]
    if cached then return cached.path, cached.rect, cached.capInsets end
    local path, rect, capInsets = Manifest.GetSprite(id)
    if not path or not rect then return nil, nil, nil end
    cached = { path = path, rect = rect, capInsets = capInsets }
    self._spriteDefinitions[id] = cached
    return path, rect, capInsets
end

function Window:drawSprite(id, x, y, width, height, alpha)
    local path, rect = self:spriteDefinition(id)
    local texture = path and self:atlasTexture(path) or nil
    if not texture or not rect or not self.drawSubTexture then return false end
    self:drawSubTexture(texture, rect.x, rect.y, rect.w, rect.h,
        x, y, width, height, tonumber(alpha) or 1, 1, 1, 1)
    return true
end

function Window:drawShell()
    local skin = self.skin
    local base = skin and skin.baseSize or {}
    local path, rect = self:spriteDefinition(skin and skin.sprite)
    local texture = path and self:atlasTexture(path) or nil
    if texture and rect and self.drawSubTexture then
        self:drawSubTexture(texture, rect.x, rect.y, rect.w, rect.h,
            0, 0, base.w * self.scale, base.h * self.scale, 1, 1, 1, 1)
    end
end

function Window:drawTextClipped(value, x, y, width, color, maxChars)
    value = self:fitText(value, width, maxChars)
    local font = self:screenFont()
    color = color or { r = 0.75, g = 1, b = 0.75, a = 1 }
    self:drawText(value, x, y, color.r, color.g, color.b, color.a, font)
end

function Window:screenColors()
    local theme = self.skin and self.skin.theme or "green"
    if theme == "amber" then
        return { r = 1, g = 0.78, b = 0.32, a = 1 }
    end
    return { r = 0.65, g = 1, b = 0.65, a = 1 }
end

function Window:drawScreenHeader(title, subtitle, options)
    options = options or {}
    local metrics = self:screenMetrics()
    local screen = metrics.screen
    local color = self:screenColors()
    local y = screen.y + metrics.padding
    self:drawTextClipped(string.upper(text(title, "RADIO OS")), metrics.x,
        y, metrics.width, color)
    local header = self:headerLayout(subtitle, options)
    if header.lines == 2 then
        local muted = { r = color.r * 0.75, g = color.g * 0.75,
            b = color.b * 0.75, a = 1 }
        self:drawTextClipped(subtitle, metrics.x,
            y + metrics.lineHeight, metrics.width, muted)
    end
    self._headerLayout = header
    return self._headerLayout
end

function Window:drawStatusWidget()
    local context = self.context or {}
    local id = context.active and (context.audible and "ind_rx"
        or "chip_standby") or "ind_offline"
    local screen = self:screenRect()
    local scale = tonumber(self.scale) or 1
    local width = math.max(6, math.floor(14 * scale))
    local height = math.max(3, math.floor(5 * scale))
    self:drawSprite(id, screen.x + screen.w - width - 2 * scale,
        screen.y + screen.h - height - 2 * scale, width, height, 0.9)
end

function Window:drawScreen()
    local screen = self:screenRect()
    if self.setStencilRect then
        self:setStencilRect(screen.x, screen.y, screen.w, screen.h)
    end
    local theme = self.skin and self.skin.theme or "green"
    self:drawSprite("screen_bg_" .. theme, screen.x, screen.y,
        screen.w, screen.h, 1)
    if self.page == "home" then
        self:drawHome()
    elseif self.page == "contacts" then
        self:drawContacts()
    elseif self.page == "contact_detail" then
        self:drawContactDetail()
    elseif self.page == "settings" then
        self:drawSettings()
    else
        self:drawCustom()
    end
    self:drawStatusWidget()
    self:drawSprite("overlay_scanlines_" .. theme, screen.x, screen.y,
        screen.w, screen.h, 0.16)
    if self.clearStencilRect then self:clearStencilRect() end
end

function Window:drawControls()
    local theme = self.skin and self.skin.theme or "green"
    for _, name in ipairs({ "left", "center", "right" }) do
        local rect = self:controlRect(name)
        if not rect then return end
        local state = self._pressedControl == name and "pressed"
            or self._hoverControl == name and "hover" or "idle"
        self:drawSprite("btn_sq_" .. theme .. "_" .. state,
            rect.x, rect.y, rect.w, rect.h, 1)
        local icon = ({ left = "icon_left", center = "icon_radio_call",
            right = "icon_right" })[name]
        if icon then
            local inset = math.max(2, math.floor(math.min(rect.w, rect.h) * 0.18))
            self:drawSprite(icon, rect.x + inset, rect.y + inset,
                rect.w - inset * 2, rect.h - inset * 2, 0.95)
        end
    end
    if self._hoverResize or self._resizing then
        local width = self.getWidth and self:getWidth() or self.width or 0
        local height = self.getHeight and self:getHeight() or self.height or 0
        local size = math.max(8, math.floor((self.resizeHandleSize or 14) * 0.6))
        self:drawRectBorder(width - size, height - size, size, size,
            0.9, 0.75, 1, 0.75)
    end
end

function Window:statusLine()
    if self.statusText then return self.statusText end
    if self.context.active then
        return Text.Get("UI_PsychopatzCore_Radio_Ready", "RADIO READY")
    end
    return Text.Format("UI_PsychopatzCore_Radio_Status", "RADIO %s",
        string.upper(text(self.context.reason, "UNKNOWN")))
end

function Window:prerender()
    ISPanel.prerender(self)
    if self._closed then return end
    self:drawScreen()
    self:layoutPortrait()
end

function Window:render()
    ISPanel.render(self)
    if self._closed then return end
    self:drawShell()
    self:drawControls()
end

require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Pages"

return Window
