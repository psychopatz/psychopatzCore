-- Shared physical-radio drawing and frame lifecycle for the Radio OS window.
-- Page-specific presentation lives in PsychopatzRadioOSWindow_Pages.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Manifest = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioManifest"
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window

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

function Window:drawSprite(id, x, y, width, height, alpha)
    local path, rect = Manifest.GetSprite(id)
    local texture = path and self:atlasTexture(path) or nil
    if not texture or not rect or not self.drawSubTexture then return false end
    self:drawSubTexture(texture, rect.x, rect.y, rect.w, rect.h,
        x, y, width, height, tonumber(alpha) or 1, 1, 1, 1)
    return true
end

function Window:drawShell()
    local skin = self.skin
    local base = skin and skin.baseSize or {}
    local path, rect = Manifest.GetSprite(skin and skin.sprite)
    local texture = path and self:atlasTexture(path) or nil
    if texture and rect and self.drawSubTexture then
        self:drawSubTexture(texture, rect.x, rect.y, rect.w, rect.h,
            0, 0, base.w * self.scale, base.h * self.scale, 1, 1, 1, 1)
    end
end

function Window:drawTextClipped(value, x, y, width, color, maxChars)
    value = tostring(value or "")
    maxChars = math.max(1, math.floor(tonumber(maxChars) or width / 7))
    if #value > maxChars then
        value = string.sub(value, 1, math.max(1, maxChars - 3)) .. "..."
    end
    color = color or { r = 0.75, g = 1, b = 0.75, a = 1 }
    self:drawText(value, x, y, color.r, color.g, color.b, color.a, self._font)
end

function Window:screenColors()
    local theme = self.skin and self.skin.theme or "green"
    if theme == "amber" then
        return { r = 1, g = 0.78, b = 0.32, a = 1 }
    end
    return { r = 0.65, g = 1, b = 0.65, a = 1 }
end

function Window:drawScreenHeader(title, subtitle)
    local screen = self:screenRect()
    local scale = self.scale
    local color = self:screenColors()
    self:drawTextClipped(string.upper(title), screen.x + 4 * scale,
        screen.y + 3 * scale, screen.w - 8 * scale, color,
        math.floor(screen.w / (7 * scale)))
    if subtitle then
        local muted = { r = color.r * 0.75, g = color.g * 0.75,
            b = color.b * 0.75, a = 1 }
        self:drawTextClipped(subtitle, screen.x + 4 * scale,
            screen.y + 15 * scale, screen.w - 8 * scale, muted,
            math.floor(screen.w / (7 * scale)))
    end
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
    if self.clearStencilRect then self:clearStencilRect() end
end

function Window:drawControls()
    local theme = self.skin and self.skin.theme or "green"
    for _, name in ipairs({ "left", "center", "right" }) do
        local rect = self:controlRect(name)
        local state = self._pressedControl == name and "pressed"
            or self._hoverControl == name and "hover" or "idle"
        self:drawSprite("btn_sq_" .. theme .. "_" .. state,
            rect.x, rect.y, rect.w, rect.h, 1)
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
