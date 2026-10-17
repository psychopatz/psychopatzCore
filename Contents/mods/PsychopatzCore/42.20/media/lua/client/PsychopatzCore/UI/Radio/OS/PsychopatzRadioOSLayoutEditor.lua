-- Conversation-style layout editor for the live Radio OS window.
-- It edits the same Window instance and commits through RadioOSGeometry.

require "ISUI/ISPanel"

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Geometry = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSGeometry"
local Text = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local LayoutPointer = require "PsychopatzCore/UI/PsychopatzLayoutPointer"

local Editor = ISPanel:derive("PsychopatzRadioOSLayoutEditor")
OS.LayoutEditor = Editor

local function number(value, fallback)
    return tonumber(value) or fallback or 0
end

local function screenSize()
    if getCore then
        local core = getCore()
        if core then
            return number(core:getScreenWidth(), 1280),
                number(core:getScreenHeight(), 900)
        end
    end
    return Geometry.GetScreenSize()
end

local function windowPosition(window)
    return number(window.getX and window:getX() or window.x),
        number(window.getY and window:getY() or window.y)
end

local function windowDimensions(window)
    return number(window.getWidth and window:getWidth() or window.width, 1),
        number(window.getHeight and window:getHeight() or window.height, 1)
end

local function setWindowPosition(window, x, y)
    if window.setX then window:setX(x) else window.x = x end
    if window.setY then window:setY(y) else window.y = y end
end

local function layoutInspectorEnabled()
    local diagnostics = OS.Diagnostics
    return diagnostics
        and type(diagnostics.IsLayoutInspectorEnabled) == "function"
        and diagnostics.IsLayoutInspectorEnabled() == true
end

local function inside(rect, x, y)
    return rect and x >= rect.x and y >= rect.y
        and x <= rect.x + rect.w and y <= rect.y + rect.h
end

local function scaledRect(source, scale)
    source = source or {}
    scale = number(scale, 1)
    return {
        x = math.floor((number(source.x) * scale) + 0.5),
        y = math.floor((number(source.y) * scale) + 0.5),
        w = math.max(1, math.floor((number(source.w, 1) * scale) + 0.5)),
        h = math.max(1, math.floor((number(source.h, 1) * scale) + 0.5)),
    }
end

local function record(window, event, extra)
    local diagnostics = OS.Diagnostics
    if diagnostics and diagnostics.RecordWindow then
        diagnostics.RecordWindow(event, window, extra, { print = false })
    end
end

function Editor:new(x, y, width, height, window)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.window = window
    object.closed = false
    object.capturing = false
    object.dragging = false
    object.resizing = false
    object.pointerButton = nil
    object.pointerDown = false
    object.layoutPointer = nil
    object.pointerStartX = 0
    object.pointerStartY = 0
    object.pointerAccumX = 0
    object.pointerAccumY = 0
    object.background = false
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object.inspectorEntries = nil
    object.inspectorControlsReady = false
    object.inspectorUnavailable = false
    object.inspectorStatus = nil
    return object
end

function Editor:initialise()
    ISPanel.initialise(self)
    if self.setWantMouseEvents then self:setWantMouseEvents(true) end
end

function Editor:inspectorRects()
    return {
        x = { x = 58, y = 60, w = 84, h = 24 },
        y = { x = 190, y = 60, w = 84, h = 24 },
        apply = { x = 296, y = 60, w = 92, h = 24 },
    }
end

function Editor:ensureInspectorControls()
    if not layoutInspectorEnabled() then
        for _, entry in pairs(self.inspectorEntries or {}) do
            if entry and entry.setVisible then entry:setVisible(false) end
        end
        return false
    end

    if self.inspectorControlsReady then
        for _, entry in pairs(self.inspectorEntries or {}) do
            if entry and entry.setVisible then entry:setVisible(true) end
        end
        return true
    end
    if self.inspectorUnavailable then return false end

    local loaded, reason = pcall(require, "ISUI/ISTextEntryBox")
    if not loaded or not ISTextEntryBox then
        self.inspectorUnavailable = true
        self.inspectorStatus = "ISTextEntryBox unavailable"
        return false
    end

    local rects = self:inspectorRects()
    local owner = self
    local function createEntry(rect, value, label)
        local entry = ISTextEntryBox:new(tostring(value), rect.x, rect.y,
            rect.w, rect.h)
        entry:initialise()
        entry:instantiate()
        if entry.setMaxTextLength then entry:setMaxTextLength(8) end
        entry.tooltip = "Absolute pixel " .. label .. " coordinate"
        entry.onCommandEntered = function()
            owner:applyInspectorPosition()
        end
        owner:addChild(entry)
        return entry
    end

    local x, y = windowPosition(self.window)
    self.inspectorEntries = {
        x = createEntry(rects.x, math.floor(x + 0.5), "X"),
        y = createEntry(rects.y, math.floor(y + 0.5), "Y"),
    }
    self.inspectorControlsReady = true
    self.inspectorStatus = "ready"
    return true
end

function Editor:syncInspectorControls()
    if not self:ensureInspectorControls() then return end
    local x, y = windowPosition(self.window)
    local values = {
        x = math.floor(x + 0.5),
        y = math.floor(y + 0.5),
    }
    for key, value in pairs(values) do
        local entry = self.inspectorEntries[key]
        local focused = false
        if entry and entry.isFocused then
            local ok, result = pcall(entry.isFocused, entry)
            focused = ok and result == true
        end
        if entry and not focused and entry.setText then
            entry:setText(tostring(value))
        end
    end
end

function Editor:applyInspectorPosition()
    if not layoutInspectorEnabled() or not self.inspectorEntries then
        return false
    end
    local x = tonumber(self.inspectorEntries.x:getText())
    local y = tonumber(self.inspectorEntries.y:getText())
    if x == nil or y == nil then
        self.inspectorStatus = "invalid X/Y"
        self:syncInspectorControls()
        return false
    end

    -- This is deliberately an absolute debug path.  It bypasses the editor's
    -- normal recovery-grip bounds so a tester can prove whether the engine
    -- or the editor is stopping an off-screen coordinate.
    self.window.keepOnScreen = false
    setWindowPosition(self.window, math.floor(x + 0.5), math.floor(y + 0.5))
    if self.window.markGeometryChanged then self.window:markGeometryChanged() end
    local appliedX, appliedY = windowPosition(self.window)
    self.inspectorStatus = string.format("applied %d,%d", appliedX, appliedY)
    record(self.window, "layout_editor.absolute_position", {
        requestedX = x,
        requestedY = y,
        appliedX = appliedX,
        appliedY = appliedY,
        screenWidth = select(1, screenSize()),
        screenHeight = select(2, screenSize()),
        keepOnScreen = self.window.keepOnScreen == true,
    })
    self:syncInspectorControls()
    return true
end

function Editor:controlRects()
    local width = number(self.getWidth and self:getWidth() or self.width)
    local controls = {
        reset = { x = width - 332, y = 10, w = 100, h = 30 },
        save = { x = width - 222, y = 10, w = 100, h = 30 },
        cancel = { x = width - 112, y = 10, w = 100, h = 30 },
    }
    if layoutInspectorEnabled() then
        controls.applyXY = self:inspectorRects().apply
    end
    return controls
end

function Editor:frameRect()
    if not self.window then return nil end
    local x, y = windowPosition(self.window)
    local w, h = windowDimensions(self.window)
    return { x = x, y = y, w = w, h = h }
end

function Editor:resizeHandleRect(frame)
    if not frame then return nil end
    local _, screenHeight = screenSize()
    local edgeY = math.min(frame.y + frame.h, screenHeight)
    return {
        x = frame.x + frame.w - 22,
        y = edgeY - 22,
        w = 22,
        h = 22,
    }
end

function Editor:isResizeHandle(x, y, frame)
    local rect = self:resizeHandleRect(frame or self:frameRect())
    return inside(rect, x, y)
end

function Editor:drawButton(rect, title, accent)
    self:drawRect(rect.x, rect.y, rect.w, rect.h,
        0.90, accent.r * 0.18, accent.g * 0.18, accent.b * 0.18)
    self:drawRectBorder(rect.x, rect.y, rect.w, rect.h,
        0.92, accent.r, accent.g, accent.b)
    self:drawText(title, rect.x + 8, rect.y + 8,
        accent.r, accent.g, accent.b, 1, UIFont.Small)
end

function Editor:drawRadioOverlay(frame)
    if not frame or not self.window then return end
    local window = self.window
    local scale = type(window.currentScale) == "function"
        and window:currentScale() or number(window.scale, 1)
    local cyan = { r = 0.30, g = 0.82, b = 1.0 }
    local magenta = { r = 1.0, g = 0.25, b = 0.82 }
    local green = { r = 0.25, g = 1.0, b = 0.55 }
    local yellow = { r = 1.0, g = 0.85, b = 0.15 }

    self:drawRectBorder(frame.x, frame.y, frame.w, frame.h,
        0.95, cyan.r, cyan.g, cyan.b)
    self:drawText("ARTWORK", frame.x + 4, frame.y + 4,
        cyan.r, cyan.g, cyan.b, 1, UIFont.Small)

    local aperture = window.lcdBackdropRect and window:lcdBackdropRect()
    if aperture then
        self:drawRectBorder(frame.x + aperture.x, frame.y + aperture.y,
            aperture.w, aperture.h, 0.90,
            magenta.r, magenta.g, magenta.b)
        self:drawText("LCD", frame.x + aperture.x + 3,
            frame.y + aperture.y + 3,
            magenta.r, magenta.g, magenta.b, 1, UIFont.Small)
    end

    local screen = window.screenRect and window:screenRect()
    if screen then
        self:drawRectBorder(frame.x + screen.x, frame.y + screen.y,
            screen.w, screen.h, 0.90, green.r, green.g, green.b)
        self:drawText("CONTENT", frame.x + screen.x + 3,
            frame.y + screen.y + 3,
            green.r, green.g, green.b, 1, UIFont.Small)
    end

    for _, component in ipairs(window.skin
        and window.skin.interactiveComponents or {}) do
        local rect = scaledRect(component.hitbox, scale)
        local id = tostring(component.id or "control")
        self:drawRectBorder(frame.x + rect.x, frame.y + rect.y,
            rect.w, rect.h, 0.88, yellow.r, yellow.g, yellow.b)
        self:drawText(string.upper(id), frame.x + rect.x + 3,
            frame.y + rect.y + 3,
            yellow.r, yellow.g, yellow.b, 1, UIFont.Small)
    end

    -- Match the conversation editor's bright resize affordance.  When the
    -- artwork extends below the game viewport, keep the handle on the visible
    -- viewport edge so it remains usable while the player edits the crop.
    local resize = self:resizeHandleRect(frame)
    if resize then
        self:drawRect(resize.x, resize.y, 14, 14,
            0.88, cyan.r, cyan.g, cyan.b)
        self:drawRectBorder(resize.x - 6, resize.y - 6,
            20, 20, 0.95, cyan.r, cyan.g, cyan.b)
    end
end

function Editor:drawViewportGuide()
    local width, height = screenSize()
    local y = math.max(54, height - 2)
    self:drawRect(0, y, width, 1, 0.92, 0.95, 0.82, 0.18)
    self:drawText("GAME VIEWPORT EDGE", 18, math.max(36, height - 18),
        0.95, 0.82, 0.28, 1, UIFont.Small)
end

function Editor:prerender()
    ISPanel.prerender(self)
    self:syncInspectorControls()
    local width = number(self.getWidth and self:getWidth() or self.width)
    local height = number(self.getHeight and self:getHeight() or self.height)
    -- Keep the live radio visible beneath the editor, like the conversation
    -- layout view.  The colored bounds below provide the editing affordance;
    -- this overlay must not obscure the authored artwork.
    self:drawRect(0, 0, width, height, 0.22, 0.005, 0.01, 0.012)
    local inspectorEnabled = layoutInspectorEnabled()
    local toolbarHeight = inspectorEnabled and 90 or 54
    self:drawRect(0, 0, width, toolbarHeight,
        0.94, 0.012, 0.025, 0.028)
    self:drawRect(0, 53, width, 1, 0.88, 0.28, 0.82, 1.0)
    local title = Text.Get("UI_PsychopatzCore_Radio_LayoutTitle",
        "EDIT RADIO LAYOUT")
    local hint = Text.Get("UI_PsychopatzCore_Radio_LayoutHint",
        "Drag the radio to move it; drag the bright corner to resize.")
    self:drawText(title, 18, 14, 0.42, 0.91, 1.0, 1, UIFont.Small)
    self:drawText(hint, 18, 32, 0.62, 0.70, 0.74, 1, UIFont.Small)

    local controls = self:controlRects()
    local accent = { r = 0.30, g = 0.82, b = 1.0 }
    self:drawButton(controls.reset, Text.Get(
        "UI_PsychopatzCore_Radio_ResetLayout", "RESET"),
        { r = 0.92, g = 0.58, b = 0.24 })
    self:drawButton(controls.save, Text.Get(
        "UI_PsychopatzCore_Radio_SaveLayout", "SAVE"), accent)
    self:drawButton(controls.cancel, Text.Get(
        "UI_PsychopatzCore_Radio_CancelLayout", "CANCEL"),
        { r = 0.72, g = 0.76, b = 0.80 })

    if inspectorEnabled then
        local rects = self:inspectorRects()
        self:drawText("ABS X", 18, 66, 0.95, 0.82, 0.28, 1, UIFont.Small)
        self:drawText("ABS Y", 150, 66, 0.95, 0.82, 0.28, 1, UIFont.Small)
        self:drawButton(rects.apply, "APPLY XY",
            { r = 0.95, g = 0.82, b = 0.28 })
        local x, y = windowPosition(self.window)
        local screenWidth, screenHeight = screenSize()
        self:drawText(string.format("screen %dx%d  actual %d,%d%s",
            screenWidth, screenHeight, math.floor(x + 0.5),
            math.floor(y + 0.5), self.inspectorStatus
                and ("  " .. self.inspectorStatus) or ""),
            406, 66, 0.72, 0.80, 0.84, 1, UIFont.Small)
    end

    local frame = self:frameRect()
    if frame then
        self:drawRadioOverlay(frame)
    end
    self:drawViewportGuide()
end

function Editor:buttonAt(x, y)
    local controls = self:controlRects()
    for id, rect in pairs(controls) do
        if inside(rect, x, y) then return id end
    end
    return nil
end

function Editor:beginPointer(x, y)
    local frame = self:frameRect()
    if not frame or not inside(frame, x, y) then return false end
    if self.pointerDown then return true end
    self.capturing = true
    self.pointerDown = true
    self.pointerButton = nil
    self.dragging = false
    self.resizing = self:isResizeHandle(x, y, frame)
    self.dragging = not self.resizing
    self.layoutPointer = LayoutPointer.Start(x, y, self.resizing)
    self.resizeStartScale = self.window:currentScale()
    self.boundsStart = {
        x = frame.x, y = frame.y, w = frame.w, h = frame.h,
    }
    if self.setCapture then self:setCapture(true) end
    record(self.window, "layout_editor.pointer_down", {
        resizing = self.resizing == true,
        localX = x,
        localY = y,
    })
    return true
end

function Editor:applyPointerDelta(dx, dy)
    if not self.capturing or not self.window or not self.boundsStart
        or not self.layoutPointer
    then
        return false
    end
    local active, deltaX, deltaY = LayoutPointer.Move(
        self.layoutPointer, dx, dy)
    if not active then return false end
    local screenWidth, screenHeight = screenSize()
    if self.resizing then
        local baseWidth, baseHeight = self.window:baseDimensions()
        local scaleDelta = math.abs(deltaX) >= math.abs(deltaY)
            and deltaX / baseWidth or deltaY / baseHeight
        self.window:applyScale(self.resizeStartScale + scaleDelta)
        -- applyScale keeps the editor position inside the usable-control
        -- bounds, not inside the full artwork bounds.  Restore the pointer's
        -- starting anchor after a resize so resizing never silently changes
        -- the chosen visible chassis.
        setWindowPosition(self.window, self.boundsStart.x, self.boundsStart.y)
        if self.window.clampLayoutEditorPosition then
            self.window:clampLayoutEditorPosition()
        end
    elseif self.dragging then
        local width, height = windowDimensions(self.window)
        local maxX, maxY
        if self.window.layoutEditorBounds then
            maxX, maxY = self.window:layoutEditorBounds()
        else
            maxX = math.max(0, screenWidth - width)
            maxY = math.max(0, screenHeight - height)
        end
        local x = math.max(0, math.min(maxX,
            self.boundsStart.x + deltaX))
        -- maxY is intentionally the editor recovery grip, not the full
        -- artwork/control boundary.  The authored surface may pass below
        -- the game viewport while this fixed overlay remains usable and the
        -- chosen crop can be saved.
        local y = math.max(0, math.min(maxY,
            self.boundsStart.y + deltaY))
        setWindowPosition(self.window, x, y)
        self.window:markGeometryChanged()
    end
    return true
end

function Editor:perform(action)
    if not self.window then return end
    if action == "applyXY" then
        self:applyInspectorPosition()
    elseif action == "save" or action == "apply" then
        record(self.window, "layout_editor.save")
        self.window:commitLayoutEdit()
        self:close("save")
    elseif action == "cancel" or action == "close" then
        record(self.window, "layout_editor.cancel")
        self.window:cancelLayoutEdit()
        self:close("cancel")
    elseif action == "reset" then
        record(self.window, "layout_editor.reset")
        local width, height = screenSize()
        self.window.dockX = 0.5
        self.window.dockBottomOffset = 12
        self.window.presentationVisibleFraction = 0.75
        self.window:resetScale()
        local windowWidth, windowHeight = windowDimensions(self.window)
        setWindowPosition(self.window,
            math.max(0, (width - windowWidth) / 2),
            math.max(0, (height - windowHeight) / 2))
        self.window:markGeometryChanged()
    end
end

function Editor:onMouseDown(x, y)
    if self.pointerDown then return true end
    local button = self:buttonAt(x, y)
    if button then
        self.pointerButton = button
        self.capturing = true
        self.pointerDown = true
        if self.setCapture then self:setCapture(true) end
        return true
    end
    self:beginPointer(x, y)
    -- The editor is modal.  Even a click outside the radio frame must not
    -- fall through to the world or an underlying vanilla window.
    return true
end

function Editor:onMouseMove(dx, dy)
    return self:applyPointerDelta(dx, dy)
end

function Editor:onMouseMoveOutside(dx, dy)
    return self:applyPointerDelta(dx, dy)
end

function Editor:onMouseUp()
    if self.pointerButton then
        local button = self.pointerButton
        self.pointerButton = nil
        self.capturing = false
        self.pointerDown = false
        LayoutPointer.Stop(self.layoutPointer)
        self.layoutPointer = nil
        if self.setCapture then self:setCapture(false) end
        self:perform(button)
        return true
    end
    self.capturing = false
    self.pointerDown = false
    LayoutPointer.Stop(self.layoutPointer)
    self.layoutPointer = nil
    self.dragging = false
    self.resizing = false
    if self.setCapture then self:setCapture(false) end
    return true
end

function Editor:onMouseUpOutside()
    return self:onMouseUp()
end

function Editor:onKeyPress(key)
    if Keyboard and key == Keyboard.KEY_ESCAPE then
        self:perform("cancel")
        return true
    end
    return false
end

function Editor:close(reason)
    if self.closed then return end
    self.closed = true
    self.closeReason = reason
    self.capturing = false
    self.pointerDown = false
    LayoutPointer.Stop(self.layoutPointer)
    self.layoutPointer = nil
    if self.setCapture then self:setCapture(false) end
    if reason == "window_closed" and self.window
        and self.window._layoutEditing
        and self.window.cancelLayoutEdit
    then
        self.window:cancelLayoutEdit()
    end
    if self.removeFromUIManager then self:removeFromUIManager() end
    if self.setVisible then self:setVisible(false) end
    if self.window and self.window._layoutEditor == self then
        self.window._layoutEditor = nil
    end
end

function OS.OpenLayoutEditor(window)
    if not window or window._closed then return false end
    if window._layoutEditor then
        if window._layoutEditor.bringToTop then
            window._layoutEditor:bringToTop()
        end
        return window._layoutEditor
    end
    if not window.beginLayoutEdit or not window:beginLayoutEdit() then
        return false
    end
    local width, height = screenSize()
    local editor = Editor:new(0, 0, width, height, window)
    editor:initialise()
    editor:instantiate()
    if editor.addToUIManager then editor:addToUIManager() end
    if editor.setAlwaysOnTop then editor:setAlwaysOnTop(true) end
    if editor.setVisible then editor:setVisible(true) end
    if editor.bringToTop then editor:bringToTop() end
    window._layoutEditor = editor
    record(window, "layout_editor.open", {
        x = windowPosition(window),
        y = select(2, windowPosition(window)),
        width = windowDimensions(window),
        height = select(2, windowDimensions(window)),
    })
    return editor
end

return Editor
