local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON_CLIENT = "Contents/mods/PsychopatzCore/common/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON_CLIENT .. "?.lua;"
    .. COMMON .. "?.lua;" .. package.path

getModFileReader = function(_, filename, _)
    local handle = assert(io.open("Contents/mods/PsychopatzCore/common/"
        .. filename, "r"))
    return {
        readLine = function() return handle:read("*l") end,
        close = function() handle:close() end,
    }
end

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy", 2) end
end

local function near(actual, expected, tolerance, label)
    if math.abs(actual - expected) > (tolerance or 0.01) then
        error((label or "near") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local Base = {}
Base.__index = Base
function Base:derive(name)
    local class = setmetatable({ __name = name }, { __index = self })
    class.__index = class
    return class
end
function Base:new(x, y, width, height)
    return setmetatable({ x = x, y = y, width = width, height = height,
        visible = true, children = {}, events = {} }, self)
end
function Base:initialise() end
function Base:createChildren() end
function Base:instantiate() self:createChildren() end
function Base:addChild(child)
    self.children[#self.children + 1] = child
    child.parent = self
end
function Base:setVisible(value) self.visible = value end
function Base:getIsVisible() return self.visible end
function Base:addToUIManager() self.added = true end
function Base:removeFromUIManager() self.added = false end
function Base:bringToTop() self.broughtToTop = true end
function Base:setX(value) self.x = value end
function Base:setY(value) self.y = value end
function Base:setWidth(value) self.width = value end
function Base:setHeight(value) self.height = value end
function Base:setMaxDrawHeight(value) self.maxDrawHeight = value end
function Base:clearMaxDrawHeight() self.maxDrawHeight = nil end
function Base:getX() return self.x end
function Base:getY() return self.y end
function Base:getWidth() return self.width end
function Base:getHeight() return self.height end
function Base:setCapture(value) self.captured = value end
function Base:drawSubTexture(texture, sx, sy, sw, sh, ...)
    self.draws = (self.draws or 0) + 1
    self.events[#self.events + 1] = {
        kind = "sprite", path = texture and texture.path,
        x = sx, y = sy, w = sw, h = sh,
    }
end
function Base:drawTextureScaled(texture, x, y, w, h, ...)
    self.draws = (self.draws or 0) + 1
    self.events[#self.events + 1] = {
        kind = "texture", path = texture and texture.path,
        x = x, y = y, w = w, h = h,
    }
end
function Base:drawText(...)
    self.textDraws = (self.textDraws or 0) + 1
    self.events[#self.events + 1] = { kind = "text" }
end
function Base:drawRect(...)
    self.events[#self.events + 1] = { kind = "matte" }
end
function Base:drawRectBorder(...)
    self.events[#self.events + 1] = { kind = "border" }
end
function Base:setStencilRect(...)
    self.stenciled = true
    self.events[#self.events + 1] = { kind = "stencil_on" }
end
function Base:clearStencilRect()
    self.stenciled = false
    self.events[#self.events + 1] = { kind = "stencil_off" }
end
function Base:prerender() end
function Base:render() end

package.preload["ISUI/ISPanel"] = function()
    _G.ISPanel = Base
    return Base
end
package.preload["ISUI/ISUI3DModel"] = function()
    error("portrait engine intentionally unavailable in this UI mock")
end
package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISContextMenu"] = function() return true end
package.preload["RadioCom/ISRadioWindow"] = function() return true end

UIFont = { Tiny = 1, Small = 2 }
local viewportWidth, viewportHeight = 1280, 900
getTextManager = function()
    return {
        MeasureStringX = function(_, _, value) return #tostring(value) * 6 end,
        MeasureStringY = function() return 10 end,
    }
end
getCore = function()
    return {
        getScreenWidth = function() return viewportWidth end,
        getScreenHeight = function() return viewportHeight end,
    }
end
getTexture = function(path) return { path = path } end

PsychopatzCore = {}
dofile(COMMON .. "PsychopatzCore/Radio/PC_RadioDeviceState.lua")
local player = {}
getSpecificPlayer = function() return player end
local device = {
    fullType = "Base.WalkieTalkie5",
    getFullType = function(self) return self.fullType end,
    getIsPortable = function() return true end,
    getIsTwoWay = function() return true end,
    getIsTelevision = function() return false end,
    powered = true,
    getIsTurnedOn = function(self) return self.powered end,
    setIsTurnedOn = function(self, value) self.powered = value end,
    getPower = function() return 1 end,
    getDeviceVolume = function() return 1 end,
    getMicIsMuted = function() return false end,
}

local OS = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS.lua")

-- The real layout inspector uses the vanilla ISTextEntryBox.  Keep this
-- smoke test headless while still exercising the debug-only absolute pixel
-- path when it is enabled below.
local TestTextEntry = {}
TestTextEntry.__index = TestTextEntry
function TestTextEntry:new(text, x, y, width, height)
    return setmetatable({ text = tostring(text or ""), x = x, y = y,
        width = width, height = height, visible = true }, self)
end
function TestTextEntry:initialise() end
function TestTextEntry:instantiate() end
function TestTextEntry:setMaxTextLength(value) self.maxTextLength = value end
function TestTextEntry:setVisible(value) self.visible = value end
function TestTextEntry:getText() return self.text end
function TestTextEntry:setText(value) self.text = tostring(value or "") end
function TestTextEntry:isFocused() return false end
package.preload["ISUI/ISTextEntryBox"] = function()
    _G.ISTextEntryBox = TestTextEntry
    return TestTextEntry
end

local customMoves = 0
local customSelected = false
local customScreenSelected = false
truthy(OS.RegisterApp({
    id = "mock:custom",
    ownerModID = "MockPlugin",
    label = "Custom",
    order = 30,
    open = function() return "custom" end,
    onMove = function(_, _, delta) customMoves = customMoves + delta end,
    onSelect = function() customSelected = true; return true end,
    hitTest = function() return { row = 1 } end,
    onScreenClick = function(_, _, value)
        customScreenSelected = value and value.row == 1
        return customScreenSelected
    end,
}), "custom app registration")
local requested = 0
truthy(OS.RegisterContactProvider({
    id = "mock:contacts",
    ownerModID = "MockPlugin",
    list = function()
        return { contacts = {
            { id = "npc-1", title = "Riley", status = "known",
                actions = { "mock:call" } },
        } }
    end,
    invoke = function()
        requested = requested + 1
        return true
    end,
}), "window provider")
local pagedCalls = {}
truthy(OS.RegisterContactProvider({
    id = "mock:paged",
    ownerModID = "MockPlugin",
    list = function(_, page)
        pagedCalls[#pagedCalls + 1] = page.offset
        if page.offset == 0 then
            return {
                contacts = {
                    { id = "paged-1", title = "Yankee", status = "known",
                        actions = {} },
                },
                nextOffset = 1,
            }
        end
        return {
            contacts = {
                { id = "paged-2", title = "Zulu", status = "unknown",
                    actions = {} },
            },
        }
    end,
}), "paged window provider")

local window = assert(OS.Open(0, device, { scale = 0.3 }))
truthy(window.keepOnScreen == false,
    "Radio OS root window must allow vanilla-style off-screen coordinates")
local originalX, originalY = window:getX(), window:getY()
window:setX(-64)
window:setY(viewportHeight + 32)
equal(window:getX(), -64, "root window x can move outside viewport")
equal(window:getY(), viewportHeight + 32,
    "root window y can move below viewport")
window:setX(originalX)
window:setY(originalY)
equal(window.page, "home", "initial page")
truthy(window._presentationVisibleHeight
    and window._presentationVisibleHeight < window:getHeight(),
    "immersive presentation records viewport visibility without cropping art")
equal(window.maxDrawHeight, nil,
    "immersive clip does not gate engine pointer release")
truthy(window._radioOSEngineClipDisabled,
    "engine max-draw input gate is disabled")
window:prerender()
window:render()
truthy((window.draws or 0) >= 5, "atlas rendering")
truthy((window.textDraws or 0) >= 1, "screen text rendering")
truthy(window.skin.chassis.pristine.image
    == "media/ui/Radio/WalkieTalkie/Base.WalkieTalkie5/Chassis/Pristine.png",
    "runtime chassis manifest is rendered")
truthy(#window.skin.interactiveComponents == 8,
    "runtime interactive control manifest is loaded")
local iconPath, iconRect = window:spriteDefinition("icon_contacts")
truthy(iconPath == "media/ui/Radio/OS/Icons.png" and iconRect
    and iconRect.w == 64 and iconRect.h == 64,
    "Core UI icon atlas is loaded from the runtime manifest")
local wrapped = window:wrapText(
    "A deliberately long radio status message that must stay inside the LCD",
    54, 2)
truthy(#wrapped <= 2, "screen text wrapping is bounded")
for _, line in ipairs(wrapped) do
    truthy(window:textWidth(line) <= 54,
        "wrapped screen text fits its LCD width")
end
local powerSwitch = {
    id = "power",
    kind = "switch",
    states = { off = {}, on = {}, pressed = {} },
}
window.context.powered = false
equal(window:componentState(powerSwitch), "off",
    "power switch renders its off state")
window.context.powered = true
equal(window:componentState(powerSwitch), "on",
    "power switch preserves its on state")
local powerRect = window:controlRect("power")
window:onMouseDown(powerRect.x + 1, powerRect.y + 1)
equal(device.powered, true, "power waits for pointer release")
equal(window._pressedControl, "power", "power pressed state is captured")
window:onMouseUp()
equal(device.powered, false, "power toggles on pointer release")
window:onMouseDown(powerRect.x + 1, powerRect.y + 1)
window:onMouseUp()
equal(device.powered, true, "power toggles back on")
local function firstEvent(kind, start)
    for index = start or 1, #window.events do
        if window.events[index].kind == kind then return index end
    end
    return nil
end
truthy(firstEvent("texture") ~= nil, "authored modular layers are rendered")
local staticShellEvent
local glassEvent
local firstTextEvent = firstEvent("text")
for index = 1, #window.events do
    local event = window.events[index]
    if event.kind == "texture" and event.path
        and string.find(event.path, "/Shell/Pristine.png", 1, true)
    then
        staticShellEvent = index
        break
    end
    if event.kind == "texture" and event.path
        and string.find(event.path, "/LCD/Glass.png", 1, true)
    then
        glassEvent = index
    end
end
truthy((staticShellEvent or glassEvent) and firstTextEvent
    and (staticShellEvent or glassEvent) < firstTextEvent,
    "static shell/glass is composited below dynamic screen text")
local stencilOn = firstEvent("stencil_on")
local stencilOff = firstEvent("stencil_off")
truthy(stencilOn and stencilOff and stencilOn < stencilOff,
    "screen stencil is reset")
truthy(window:lcdBackdropRect().w >= window:screenRect().w,
    "LCD aperture contains content viewport")
truthy(window:lcdBackdropRect().h >= window:screenRect().h,
    "LCD aperture height contains content viewport")
local shellEvent
for index = 1, stencilOff do
    local event = window.events[index]
        if (event.kind == "texture" or event.kind == "sprite")
            and event.path
            and (string.find(event.path, "Base.WalkieTalkie5/Chassis/Pristine.png", 1, true)
                or string.find(event.path, "Base.WalkieTalkie5/Shell/Pristine.png", 1, true))
    then
        shellEvent = index
        break
    end
end
truthy(shellEvent and stencilOn and stencilOff
    and shellEvent < stencilOn and stencilOn < stencilOff,
    "full shell is composited before the LCD-only content stencil")
local integerScreen = window:screenRect()
truthy(integerScreen.x == math.floor(integerScreen.x)
    and integerScreen.y == math.floor(integerScreen.y)
    and integerScreen.w == math.floor(integerScreen.w)
    and integerScreen.h == math.floor(integerScreen.h),
    "screen transform is pixel snapped")

local Geometry = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSGeometry"
local minimum720, maximum720 = Geometry.GetScaleLimits(1280, 720, 1024, 1535)
local minimum1080, maximum1080 = Geometry.GetScaleLimits(1920, 1080, 1024, 1535)
local minimum1440, maximum1440 = Geometry.GetScaleLimits(2560, 1440, 1024, 1535)
local minimum4K, maximum4K = Geometry.GetScaleLimits(3840, 2160, 1024, 1535)
truthy(minimum720 <= maximum720 and maximum720 < maximum1080
    and maximum1080 < maximum1440 and maximum1440 < maximum4K,
    "scale limits follow available viewport")

local settingsIndex
for index, app in ipairs(OS.ListApps(window.context)) do
    if app.id == "psychopatzcore:settings" then
        settingsIndex = index
        break
    end
end
truthy(settingsIndex, "settings app is discoverable")
window.homeIndex = settingsIndex
truthy(window:openSelectedApp(), "settings app opens")
equal(window.page, "settings", "settings page")
local settingsScale = window.scale
window.settingsIndex = 2
truthy(window:select(), "zoom in action")
truthy(window.scale > settingsScale, "zoom in changes scale")
window.settingsIndex = 3
truthy(window:select(), "zoom out action")
near(window.scale, settingsScale, 0.001, "zoom out restores scale")
window.settingsIndex = 5
truthy(window:select(), "fit action")
equal(window.scale, window.maxScale, "fit uses viewport maximum")
window.settingsIndex = 4
truthy(window:select(), "reset action")
near(window.scale, Geometry.GetPreferredScale(1280, 900, 1024, 1535), 0.001,
    "reset uses responsive default")
local savedXBeforeEditor, savedYBeforeEditor = window:getX(), window:getY()
window.settingsIndex = 1
truthy(window:select(), "layout editor action")
truthy(window._layoutEditor and not window._layoutEditor.closed,
    "layout editor opens from radio settings")
local editor = window._layoutEditor
editor:prerender()
local editorControls = editor:controlRects()
truthy(editorControls.save and editorControls.cancel and editorControls.reset,
    "layout editor exposes save/cancel/reset controls")
truthy(not editorControls.close,
    "runtime radio layout editor does not expose a misleading close X")
truthy(not editorControls.applyXY,
    "absolute pixel inspector is debug-only")
truthy((editor.textDraws or 0) >= 4,
    "layout editor renders conversation-style labels")

local debugSettings = PsychopatzCore.DebugSettings
truthy(debugSettings.Set(OS.Diagnostics.LAYOUT_INSPECTOR_SETTING, true, false),
    "layout inspector can be staged")
truthy(debugSettings.ApplyConfigured(),
    "layout inspector can be applied live")
editor:prerender()
local inspectorControls = editor:controlRects()
truthy(inspectorControls.applyXY and editor.inspectorEntries,
    "debug layout inspector exposes absolute pixel inputs")
editor.inspectorEntries.x:setText("-42")
editor.inspectorEntries.y:setText(tostring(viewportHeight + 36))
truthy(editor:applyInspectorPosition(),
    "absolute pixel inspector applies coordinates")
equal(window:getX(), -42, "absolute pixel inspector preserves negative x")
equal(window:getY(), viewportHeight + 36,
    "absolute pixel inspector preserves below-viewport y")
truthy(debugSettings.Set(OS.Diagnostics.LAYOUT_INSPECTOR_SETTING, false, false),
    "layout inspector can be disabled live")
truthy(debugSettings.ApplyConfigured(),
    "disabled layout inspector can be applied live")
editor:prerender()
truthy(not editor:controlRects().applyXY,
    "layout inspector controls disappear when disabled")
local frame = editor:frameRect()
local originalX, originalY = window:getX(), window:getY()
local maxEditorX, maxEditorY = window:layoutEditorBounds()
truthy(maxEditorX == viewportWidth - window:getWidth()
    and maxEditorY == viewportHeight - window:layoutEditorGrip(),
    "layout editor keeps only a recoverable grip inside the viewport")
editor:onMouseDown(frame.x + 20, frame.y + 20)
editor:onMouseMove(18, 22)
editor:onMouseUp()
truthy(window:getX() ~= originalX or window:getY() ~= originalY,
    "layout editor drag moves the live radio surface")
editor:perform("cancel")
truthy(not window._layoutEditor and not window._layoutEditing,
    "layout editor cancel restores radio interaction")
truthy(window:getX() == savedXBeforeEditor
    and window:getY() == savedYBeforeEditor,
    "layout editor cancel restores the saved docked radio position")
truthy(window:openLayoutEditor(), "layout editor reopens for resize")
editor = window._layoutEditor
frame = editor:frameRect()
local _, editorMaxY = window:layoutEditorBounds()
editor:onMouseDown(frame.x + 20, frame.y + 20)
editor:onMouseMove(0, editorMaxY - frame.y + 40)
editor:onMouseUp()
equal(window:getY(), editorMaxY,
    "layout editor permits the authored surface to cross the viewport edge")
editor:perform("save")
truthy(window.dockBottomOffset < 0,
    "layout editor persists a signed below-viewport dock offset")
truthy(window:openLayoutEditor(), "layout editor reopens after off-screen crop")
editor = window._layoutEditor
frame = editor:frameRect()
equal(window:getY(), editorMaxY,
    "off-screen chassis crop survives reopening the layout editor")
editor:perform("cancel")
truthy(window:openLayoutEditor(), "layout editor reopens for crop adjustment")
editor = window._layoutEditor
frame = editor:frameRect()
local cropStartY = window:getY()
editor:onMouseDown(frame.x + 20, frame.y + 20)
editor:onMouseMove(0, -800)
editor:onMouseUp()
truthy(window:getY() < cropStartY,
    "layout editor vertical drag changes the visible chassis crop")
local croppedY = window:getY()
editor:perform("save")
truthy(window:getY() == croppedY and window.dockBottomOffset > 0,
    "layout editor save persists the chosen chassis crop")
truthy(window:openLayoutEditor(), "layout editor reopens after crop preview")
editor = window._layoutEditor
frame = editor:frameRect()
local originalWidth = window:getWidth()
local resizeHandle = editor:resizeHandleRect(frame)
truthy(resizeHandle, "layout editor exposes visible resize handle")
editor:onMouseDown(resizeHandle.x + 5, resizeHandle.y + 5)
editor:onMouseMove(40, 20)
editor:onMouseUp()
truthy(window:getWidth() > originalWidth,
    "layout editor bright corner resizes the live radio surface")
editor:perform("save")
truthy(not window._layoutEditor and not window._layoutEditing,
    "layout editor save commits and closes the editor")
window:back()
equal(window.page, "home", "settings back navigation")
window.homeIndex = 1
OS.SetCompositorDebug(true)
window:prerender()
window:render()
truthy(window.debugCompositor, "debug compositor can be enabled")
OS.SetCompositorDebug(false)
viewportWidth, viewportHeight = 1280, 720
window:prerender()
equal(window.maxScale, maximum720, "resolution change updates max scale")
truthy(window:getY() + window:visibleBodyBottom() <= viewportHeight + 1
    and window:getY() + window:visibleBodyBottom()
        >= viewportHeight - window.dockBottomOffset - 1,
    "resolution change preserves immersive dock body anchor")
viewportWidth, viewportHeight = 1920, 1080
window:prerender()
equal(window.maxScale, maximum1080, "larger resolution restores scale ceiling")

local homeLayout = window:screenListLayout(#OS.ListApps(window.context), 3,
    window.homeIndex, window:headerLayout(window:statusLine()))
local homeRow = window:screenRowRect(homeLayout, 0)
truthy(window:homeRowAt(homeRow.x + 1, homeRow.y + 1),
    "home row hit-test")
window:onMouseDown(homeRow.x + 1, homeRow.y + 1)
equal(window.page, "contacts", "home row navigation")

local contactRow = window:screenRowRect(
    window:screenListLayout(#window.contacts, 2, window.contactIndex,
        window:headerLayout(window.contactStatus or window:statusLine())), 0)
truthy(window:contactRowAt(contactRow.x + 1, contactRow.y + 1),
    "contact row hit-test")
window:onMouseDown(contactRow.x + 1, contactRow.y + 1)
equal(window.page, "contact_detail", "contact row navigation")
window:onMouseDown(window:screenRect().x + 2, window:screenRect().y + 40)
equal(requested, 1, "direct contact action dispatch")

local center = window:controlRect("center")
window:onMouseDown(window:controlRect("left").x + 1,
    window:controlRect("left").y + 1)
window:onMouseUp()
equal(window.page, "contacts", "detail back navigation")
window:back()
equal(window.page, "home", "home back navigation")

local callsBeforeRefresh = #pagedCalls
window:ensureContacts(true)
equal(#pagedCalls - callsBeforeRefresh, 2,
    "contact provider pagination is bounded and followed")
truthy(window.contacts[1] and window.contacts[2]
    and window.contacts[3], "paged contacts are collected")
equal(window.selectedContact and window.selectedContact.id, "npc-1",
    "selected contact survives provider refresh")

local beforeX, beforeY = window:getX(), window:getY()
window:onMouseDown(10, 200)
window:onMouseMove(24, 13)
window:onMouseUp()
truthy(window:getX() ~= beforeX or window:getY() ~= beforeY,
    "shell drag moves the window")

local beforeScale = window.scale
truthy(window:beginLayoutEdit(), "layout editor mode starts")
window:onMouseDown(window:getWidth() - 2, window:getHeight() - 2)
window:onMouseMove(24, 24)
window:onMouseUp()
truthy(window.scale > beforeScale, "resize grip changes uniform scale")
near(window:getWidth() / window:getHeight(), 1024 / 1535, 0.01,
    "resize preserves shell aspect ratio")
truthy(window:commitLayoutEdit(), "layout editor mode commits")

local dockX = window:getX()
window:onMouseDown(10, 200)
window:onMouseMove(24, 0)
window:onMouseUp()
truthy(window:getX() ~= dockX,
    "immersive drag moves horizontally while docked")

window:onMouseDown(10, 200)
window:onMouseMove(0, window:hiddenPositionY() - window:getY())
window:onMouseUp()
for _ = 1, 40 do window:stepPresentation() end
truthy(window.presentationState == "hidden" and not window:getIsVisible(),
    "downward drag hides the radio")

-- A release below the visual clip must still reach Lua.  Recreate the
-- failure that previously left _dragging=true, then verify hover motion is
-- harmless and the stale state is recovered rather than moving the window.
window = assert(OS.Open(0, device))
window.presentationState = "docked"
window:applyDockPosition()
local staleX, staleY = window:getX(), window:getY()
window._dragging = true
window._pointerDown = false
window:onMouseMove(80, 80)
equal(window:getX(), staleX, "hover cannot move a stale drag")
equal(window:getY(), staleY, "hover cannot move a stale drag vertically")
equal(window._dragging, false, "stale drag is recovered")
local reopenedHidden = assert(OS.Open(0, device))
truthy(reopenedHidden == window and reopenedHidden:getIsVisible(),
    "opening a hidden radio reuses and reveals it")
truthy(reopenedHidden.chromeRect == nil,
    "device does not expose a close chrome")
reopenedHidden:back()
equal(OS.GetOpenWindow(0), reopenedHidden,
    "Back on home does not close the device")
window = assert(OS.Open(0, device))
local savedX, savedY, savedScale = window:getX(), window:getY(), window.scale
window:close()
equal(OS.GetOpenWindow(0), nil, "window cleanup")

local restored = assert(OS.Open(0, device))
equal(restored:getX(), savedX, "player-local position x persists")
equal(restored:getY(), savedY, "player-local position y persists")
equal(restored.scale, savedScale, "player-local scale persists")
restored:close()

local otherDevice = {}
for key, value in pairs(device) do otherDevice[key] = value end
otherDevice.fullType = "Base.WalkieTalkie1"
local otherWindow = assert(OS.Open(0, otherDevice, { scale = 0.9 }))
otherWindow:moveBy(17, 0)
otherWindow:close()
local firstSkinAgain = assert(OS.Open(0, device))
equal(firstSkinAgain:getX(), savedX,
    "radio geometry is scoped by device skin")
equal(firstSkinAgain.scale, savedScale,
    "radio scale is scoped by device skin")
firstSkinAgain:close()

local animated = assert(OS.Open(0, device, { scale = 0.3 }))
animated:showImmersive({ animate = false })
local animatedDockY = animated:getY()
local animatedHeight = animated:getHeight()
animated:beginPresentationDrag(40, animatedDockY + 20)
animated:trackPresentationDrag(0, 100000)
truthy(animated:getY() > animatedDockY,
    "swipe moves the complete radio surface toward the viewport bottom")
animated:finishPresentationDrag()
equal(animated.presentationState, "hiding",
    "downward swipe enters the hiding animation")
local animationSteps = 0
while animated.presentationState == "hiding" and animationSteps < 40 do
    animated:stepPresentation()
    animationSteps = animationSteps + 1
end
equal(animated.presentationState, "hidden",
    "hiding animation reaches the hidden state")
truthy(not animated:getIsVisible(),
    "radio becomes invisible only after the slide-away animation")
truthy(animated:getY() >= viewportHeight
    and animated:getHeight() == animatedHeight,
    "slide-away keeps the full art dimensions and ends below the viewport")
animated:showImmersive({ animate = false })
animated:close()

local host = { visible = true }
function host:setVisible(value) self.visible = value end
function host:bringToTop() self.broughtToTop = true end
local hosted = assert(OS.Open(0, device, { scale = 1, hostWindow = host }))
equal(host.visible, false, "native host is hidden while OS is open")
hosted:close()
equal(host.visible, true, "native host is restored on close")

OS.UnregisterContactProvider("mock:contacts")
OS.UnregisterContactProvider("mock:paged")

local customWindow = assert(OS.Open(0, device, { scale = 1 }))
customWindow:triggerControl("right")
customWindow:triggerControl("ok")
equal(customWindow.page, "custom", "custom app navigation")
customWindow:triggerControl("right")
equal(customMoves, 1, "custom app movement")
customWindow:triggerControl("ok")
truthy(customSelected, "custom app selection")
local customScreen = customWindow:screenRect()
customWindow:onMouseDown(customScreen.x + 4, customScreen.y + 30)
truthy(customScreenSelected, "custom app screen click")
customWindow.page = "custom"
customWindow.drawScreenContent = function()
    error("intentional compositor smoke failure")
end
customWindow:drawScreen()
truthy(customWindow.stenciled == false,
    "stencil resets after screen render failure")
customWindow:back()
equal(customWindow.page, "home", "custom app back navigation")
customWindow:close()
OS.UnregisterApp("mock:custom")

print("psychopatz_radio_os_window_smoke: ok")
