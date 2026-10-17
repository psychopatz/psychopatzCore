-- Shared physical-radio drawing and frame lifecycle for the Radio OS window.
-- Page-specific presentation lives in PsychopatzRadioOSWindow_Pages.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Manifest = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioRuntimeManifest"
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Layout"

local function text(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

local function snap(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function scaledRect(source, scale)
    source = source or {}
    scale = tonumber(scale) or 1
    return {
        x = snap((tonumber(source.x) or 0) * scale),
        y = snap((tonumber(source.y) or 0) * scale),
        w = math.max(1, snap((tonumber(source.w) or 1) * scale)),
        h = math.max(1, snap((tonumber(source.h) or 1) * scale)),
    }
end

function Window:screenRect()
    local lcd = self.skin and self.skin.lcd or {}
    return scaledRect(lcd.content or lcd.backing or lcd.aperture, self.scale)
end

function Window:lcdBackdropRect()
    local lcd = self.skin and self.skin.lcd or {}
    return scaledRect(lcd.aperture or lcd.backing or lcd.content, self.scale)
end

function Window:controlRect(name)
    for _, control in ipairs(self.skin and self.skin.interactiveComponents or {}) do
        if control.id == name then return scaledRect(control.hitbox, self.scale) end
    end
    return nil
end

function Window:isInside(rect, x, y)
    return rect and x >= rect.x and y >= rect.y
        and x <= rect.x + rect.w and y <= rect.y + rect.h
end

function Window:hitControl(x, y)
    for _, control in ipairs(self.skin and self.skin.interactiveComponents or {}) do
        if self:isInside(scaledRect(control.hitbox, self.scale), x, y) then
            return control.id
        end
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
    local path, rect = Manifest.GetIcon(id)
    return path, rect, nil
end

function Window:drawSprite(id, x, y, width, height, alpha)
    local path, rect = self:spriteDefinition(id)
    local texture = path and self:atlasTexture(path) or nil
    if not texture or not rect or not self.drawSubTexture then return false end
    self:drawSubTexture(texture, rect.x, rect.y, rect.w, rect.h,
        snap(x), snap(y), math.max(1, snap(width)), math.max(1, snap(height)),
        tonumber(alpha) or 1, 1, 1, 1)
    return true
end

function Window:drawAsset(entry, alpha)
    if type(entry) ~= "table" or type(entry.image) ~= "string"
        or (not self.drawTextureScaled and not self.drawSubTexture)
    then
        return false
    end
    local texture = self:atlasTexture(entry.image)
    if not texture then return false end
    local scale = tonumber(self.scale) or 1
    local canvas = self.skin and self.skin.canvas or {}
    local sourceWidth = tonumber(canvas.width) or 1
    local sourceHeight = tonumber(canvas.height) or 1
    local textureWidth = texture.getWidth and texture:getWidth() or sourceWidth
    local textureHeight = texture.getHeight and texture:getHeight() or sourceHeight
    local x = snap((tonumber(entry.x) or 0) * scale)
    local y = snap((tonumber(entry.y) or 0) * scale)
    local width = snap(textureWidth * scale)
    local height = snap(textureHeight * scale)
    if textureWidth == sourceWidth and textureHeight == sourceHeight
        and x == 0 and y == 0
    then
        width = self.getWidth and self:getWidth() or snap(sourceWidth * scale)
        height = self.getHeight and self:getHeight() or snap(sourceHeight * scale)
    end
    if self.drawTextureScaled then
        self:drawTextureScaled(texture, x, y, math.max(1, width),
            math.max(1, height), tonumber(alpha) or 1, 1, 1, 1)
    else
        self:drawSubTexture(texture, 0, 0, textureWidth, textureHeight,
            x, y, math.max(1, width), math.max(1, height),
            tonumber(alpha) or 1, 1, 1, 1)
    end
    return true
end

function Window:componentState(component)
    if type(component) ~= "table" then return "idle" end
    local states = component.states or {}
    local id = tostring(component.id or "")
    if self._pressedControl == id and states.pressed then return "pressed" end
    local kind = tostring(component.kind or "")
    -- Switch art has an authored on/off state. Without this branch Lua's
    -- pairs() order selects an arbitrary state, so a real power switch can
    -- disagree with DeviceData after toggling or reopening.
    if kind == "switch" or id == "power" then
        local stateName = self.context and self.context.powered
            and "on" or "off"
        if states[stateName] then return stateName end
    end
    if kind == "led" then
        local lower = string.lower(id)
        if string.find(lower, "pwr", 1, true)
            or string.find(lower, "power", 1, true)
        then
            return self.context and self.context.powered and "on" or "off"
        end
        if string.find(lower, "rx", 1, true) then
            return self.context and self.context.audible and "on" or "off"
        end
        return "off"
    end
    if kind == "hold" or kind == "ptt" then
        return self._pttHeld and "held" or "idle"
    end
    if states.idle then return "idle" end
    for stateName, _ in pairs(states) do return stateName end
    return "idle"
end

function Window:drawComponents()
    for _, component in ipairs(self.skin and self.skin.components or {}) do
        if component.visible ~= false then
            local stateName = self:componentState(component)
            local state = (component.states or {})[stateName]
            if not state then
                for _, candidate in pairs(component.states or {}) do
                    state = candidate
                    break
                end
            end
            self:drawAsset(state, 1)
        end
    end
end

function Window:hasStaticShell()
    local skin = self.skin
    if not skin then return false end
    local variant = self.variant or skin.defaultVariant or "pristine"
    return type(skin.shell) == "table"
        and type(skin.shell[variant]) == "table"
        and type(skin.shell[variant].image) == "string"
end

function Window:drawShell()
    local skin = self.skin
    if not skin then return end
    local variant = self.variant or skin.defaultVariant or "pristine"
    if self:hasStaticShell() then
        self:drawAsset(skin.shell[variant], 1)
    else
        self:drawAsset((skin.chassis or {})[variant], 1)
        self:drawAsset((skin.lcd_layers or {}).matte, 1)
    end
    self:drawComponents()
end

function Window:drawLCDOverlays()
    if self:hasStaticShell() then return end
    local layers = self.skin and self.skin.lcd_layers or {}
    self:drawAsset(layers.glass, 1)
    self:drawAsset(layers.bezel_overlay, 1)
end

function Window:drawTextClipped(value, x, y, width, color, maxChars,
    maxLines)
    local font = self:screenFont()
    color = color or { r = 0.75, g = 1, b = 0.75, a = 1 }
    local lines = self:wrapText(value, width, maxLines or 1)
    local lineHeight = self:screenMetrics().lineHeight
    for index, line in ipairs(lines) do
        self:drawText(line, x, y + (index - 1) * lineHeight,
            color.r, color.g, color.b, color.a, font)
    end
    return #lines
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
    local header = self:headerLayout(subtitle, options)
    local y = screen.y + metrics.padding
    self:drawTextClipped(string.upper(text(title, "RADIO OS")), metrics.x,
        y, metrics.width, color)
    if header.lines == 2 then
        local muted = { r = color.r * 0.75, g = color.g * 0.75,
            b = color.b * 0.75, a = 1 }
        self:drawTextClipped(subtitle, metrics.x,
            y + metrics.lineHeight, metrics.width, muted, nil, 1)
    elseif header.lines > 2 then
        local muted = { r = color.r * 0.75, g = color.g * 0.75,
            b = color.b * 0.75, a = 1 }
        self:drawTextClipped(subtitle, metrics.x,
            y + metrics.lineHeight, metrics.width, muted, nil,
            header.lines - 1)
    end
    self._headerLayout = header
    return self._headerLayout
end

function Window:drawStatusWidget()
    local context = self.context or {}
    local screen = self:screenRect()
    local scale = tonumber(self.scale) or 1
    local width = math.max(6, snap(14 * scale))
    local height = math.max(3, snap(5 * scale))
    if self.drawRect then
        local color = context.active and { 0.35, 0.9, 0.45 }
            or { 0.25, 0.35, 0.25 }
        self:drawRect(screen.x + screen.w - width - 2 * scale,
            screen.y + screen.h - height - 2 * scale, width, height,
            0.9, color[1], color[2], color[3])
    end
end

function Window:lcdMatteColor()
    local theme = self.skin and self.skin.theme or "green"
    if theme == "amber" then
        return { r = 0.10, g = 0.055, b = 0.015, a = 1 }
    elseif theme == "dark" then
        return { r = 0.015, g = 0.020, b = 0.020, a = 1 }
    end
    return { r = 0.015, g = 0.055, b = 0.025, a = 1 }
end

function Window:drawLCDMatte()
    if self.skin and self.skin.lcd_layers
        and self.skin.lcd_layers.matte
    then
        return
    end
    if not self.drawRect then return end
    local aperture = self:lcdBackdropRect()
    local color = self:lcdMatteColor()
    self:drawRect(aperture.x, aperture.y, aperture.w, aperture.h,
        color.a, color.r, color.g, color.b)
end

function Window:drawScreenContent()
    if not (self.context and self.context.powered) then
        local screen = self:screenRect()
        local color = self:screenColors()
        self:drawTextClipped("POWER OFF", screen.x + 4,
            screen.y + screen.h * 0.42, screen.w - 8, color)
        self:drawTextClipped("Press Power", screen.x + 4,
            screen.y + screen.h * 0.58, screen.w - 8,
            { r = color.r * 0.65, g = color.g * 0.65,
                b = color.b * 0.65, a = 1 })
        return
    end
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
end

function Window:drawScreen()
    local screen = self:screenRect()
    local aperture = self:lcdBackdropRect()
    local theme = self.skin and self.skin.theme or "green"

    -- The modular shell pass already draws the authored matte when present.
    -- Synthetic fill is retained only for a manifest that omits that layer.
    self:drawLCDMatte()
    if not (self.skin and self.skin.lcd_layers
        and self.skin.lcd_layers.matte) and self.drawRect
    then
        local content = self:screenRect()
        local color = self:lcdMatteColor()
        self:drawRect(content.x, content.y, content.w, content.h,
            color.a, color.r, color.g, color.b)
    end

    local clipped = false
    if self.setStencilRect then
        self:setStencilRect(screen.x, screen.y, screen.w, screen.h)
        clipped = true
    end
    local ok, result = pcall(self.drawScreenContent, self)
    if clipped and self.clearStencilRect then
        self:clearStencilRect()
    end
    if not ok then
        self.statusText = Text.Get("UI_PsychopatzCore_Radio_AppError",
            "APP ERROR")
        print("[PsychopatzCore][RadioOS] screen render failed: "
            .. tostring(result))
    end

    -- Scanline sprites belonged to the retired atlas.  The authored glass
    -- layer owns the physical LCD finish; dynamic text remains uncluttered.
end

function Window:drawControls()
    if self._hoverResize or self._resizing then
        local width = self.getWidth and self:getWidth() or self.width or 0
        local height = self.getHeight and self:getHeight() or self.height or 0
        local size = math.max(8, math.floor((self.resizeHandleSize or 14) * 0.6))
        self:drawRectBorder(width - size, height - size, size, size,
            0.9, 0.75, 1, 0.75)
    end
end

function Window:drawCompositorDebug()
    if self.debugCompositor ~= true or not self.drawRectBorder then return end
    local aperture = self:lcdBackdropRect()
    local screen = self:screenRect()
    local width = self.getWidth and self:getWidth() or self.width or 0
    local height = self.getHeight and self:getHeight() or self.height or 0
    -- Cyan = full authored surface, magenta = opaque LCD aperture,
    -- green = actual game viewport edge, yellow = physical hitboxes.
    self:drawRectBorder(0, 0, width, height, 0.95, 0.15, 0.85, 1)
    self:drawRectBorder(aperture.x, aperture.y, aperture.w, aperture.h,
        0.95, 1, 0.15, 0.85)
    self:drawRectBorder(screen.x, screen.y, screen.w, screen.h,
        0.95, 0.15, 1, 0.25)
    -- This is a viewport diagnostic, not a clipping rectangle.  The full
    -- radio surface remains drawable below it so the slide-away animation is
    -- visible and the authored sprite is never cut internally.
    local viewportHeight
    if type(getCore) == "function" then
        local ok, core = pcall(getCore)
        if ok and core and type(core.getScreenHeight) == "function" then
            local okHeight, screenHeight = pcall(core.getScreenHeight, core)
            if okHeight and screenHeight ~= nil then
                local windowY = self.getY and self:getY() or self.y or 0
                viewportHeight = tonumber(screenHeight) - tonumber(windowY)
            end
        end
    end
    if viewportHeight and viewportHeight > 0 and viewportHeight < height then
        self:drawRectBorder(0, snap(viewportHeight), width, 1,
            0.95, 0.25, 1, 0.70)
        self:drawText("GAME VIEWPORT EDGE", 2,
            snap(viewportHeight) + 2, 0.55, 0.85, 1, 1,
            self:screenFont())
    end
    for _, component in ipairs(self.skin and self.skin.interactiveComponents or {}) do
        local rect = scaledRect(component.hitbox, self.scale)
        if rect then
            self:drawRectBorder(rect.x, rect.y, rect.w, rect.h,
                0.95, 1, 0.85, 0.15)
        end
    end
    local debugText = Text.Format("UI_PsychopatzCore_Radio_DebugScale",
        "SCALE %.2f / MATTE 1.00", self:currentScale())
    self:drawText(debugText, 2, 2, 1, 1, 1, 1, self:screenFont())
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
    local diagnostics = OS.Diagnostics
    local performanceToken = diagnostics and diagnostics.BeginFrame
        and diagnostics.BeginFrame(self, "prerender") or nil
    if self.stepPresentation then self:stepPresentation() end
    if self.refreshPowerState then self:refreshPowerState(false) end
    if self.reconcileScreenGeometry then self:reconcileScreenGeometry() end
    if self.applyPresentationClip then self:applyPresentationClip() end
    ISPanel.prerender(self)
    if self._closed then
        if diagnostics and diagnostics.EndFrame then
            diagnostics.EndFrame(self, performanceToken)
        end
        return
    end
    -- Draw the entire authored shell.  Immersive placement is an anchor
    -- policy, not an image crop; the LCD content pass below remains clipped
    -- to its physical aperture.
    self:drawShell()
    -- Glass is an authored, mostly opaque LCD layer.  It must be composited
    -- before the dynamic OS content; drawing it after the child render hides
    -- every label and makes the native window look like a blank green panel.
    self:drawLCDOverlays()
    self:drawScreen()
    self:layoutPortrait()
    if diagnostics and diagnostics.EndFrame then
        diagnostics.EndFrame(self, performanceToken)
    end
end

function Window:render()
    local diagnostics = OS.Diagnostics
    local performanceToken = diagnostics and diagnostics.BeginFrame
        and diagnostics.BeginFrame(self, "render") or nil
    if self._closed then
        if diagnostics and diagnostics.EndFrame then
            diagnostics.EndFrame(self, performanceToken)
        end
        return
    end
    -- PortraitPanel is a child of the radio window.  Keep the actual stencil
    -- active across ISPanel.render so it cannot escape the LCD safe viewport.
    local screen = self:screenRect()
    local clipped = false
    if self.setStencilRect then
        self:setStencilRect(screen.x, screen.y, screen.w, screen.h)
        clipped = true
    end
    local ok, result = pcall(ISPanel.render, self)
    if clipped and self.clearStencilRect then
        self:clearStencilRect()
    end
    if not ok then
        print("[PsychopatzCore][RadioOS] portrait render failed: "
            .. tostring(result))
    end
    self:drawControls()
    self:drawCompositorDebug()
    if diagnostics and diagnostics.EndFrame then
        diagnostics.EndFrame(self, performanceToken)
    end
end

require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Pages"

return Window
