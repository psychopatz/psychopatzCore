-- Lifecycle, navigation and input for the physical Radio OS window.
-- Rendering is isolated in PsychopatzRadioOSWindow_Renderer.lua.

require "ISUI/ISPanel"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local OS = PsychopatzCore.RadioOS
local Geometry = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSGeometry"
local Window = ISPanel:derive("PsychopatzRadioOSWindow")
OS.Window = Window

function Window:new(x, y, width, height, context, options)
    local object = ISPanel:new(x, y, width, height)
    -- Vanilla UIDebugConsole is a root zombie.ui.NewWindow and therefore
    -- allows its x/y to move outside the viewport.  ISUIElement instead
    -- defaults root panels to keepOnScreen=true, which clamps setX/setY and
    -- setWidth/setHeight at the screen edge.  Radio OS is an intentionally
    -- off-screen-capable presentation surface: the viewport clips the
    -- pixels, while the authored artwork remains intact for the swipe-away
    -- animation and persisted crop.  Match the vanilla root-window model.
    object.keepOnScreen = false
    options = type(options) == "table" and options or {}
    setmetatable(object, self)
    self.__index = self
    object.context = context or {}
    object.playerNum = tonumber(object.context.playerNum) or 0
    object.scale = tonumber(options.scale) or 1
    local automaticMinimum, automaticMaximum = Geometry.GetScaleLimits()
    object.minScale = tonumber(options.minScale) or automaticMinimum
    object.maxScale = tonumber(options.maxScale) or automaticMaximum
    object.persistGeometry = options.persistGeometry ~= false
    object.geometryKey = options.geometryKey
    object.owner = options.owner
    object.openSource = options.source
    object.autoDevice = options.autoDevice
    object.hostWindow = options.hostWindow
    object.geometryIdentity = options.geometryIdentity
    object.presentationMode = options.presentationMode or "immersive"
    object.presentationState = options.hidden == true and "hidden" or "docked"
    object.dockX = tonumber(options.dockX) or 0.5
    -- Keep the signed layout offset intact.  Geometry.DockPosition applies
    -- the screen/height safety bounds after the actual surface dimensions are
    -- known; clamping it to zero here would erase an intentional off-screen
    -- chassis crop during reopen.
    object.dockBottomOffset = tonumber(options.dockBottomOffset) or 12
    object.presentationPeekHeight = math.max(
        0, tonumber(options.presentationPeekHeight) or 0)
    object.presentationVisibleFraction = math.max(0.35, math.min(1,
        tonumber(options.presentationVisibleFraction) or 0.75))
    object.animationDuration = math.max(
        1, tonumber(options.animationDuration) or 360)
    -- Runtime presentation gestures may overscroll the docked surface, but
    -- this feedback is never part of persisted layout geometry.  The layout
    -- editor remains the only owner allowed to change the vertical anchor.
    object.rubberBandMaxDistance = math.max(24,
        tonumber(options.rubberBandMaxDistance) or 120)
    object.rubberBandResistance = math.max(0.05, math.min(1,
        tonumber(options.rubberBandResistance) or 0.35))
    object.rubberBandDuration = math.max(120,
        tonumber(options.rubberBandDuration) or 280)
    object.autoManaged = options.autoManaged == true
    object._animationStartY = nil
    object._animationTargetY = nil
    object._animationElapsed = 0
    object._layoutEditing = false
    object._layoutEditor = nil
    object._layoutSnapshot = nil
    object.skin = object.context.skin
    object.variant = options.variant or object.context.variant or "pristine"
    object.page = "home"
    object.homeIndex = 1
    object.contactIndex = 1
    object.contacts = nil
    object.contactsRevision = nil
    object.contactStatus = nil
    object.selectedContact = nil
    object.activeApp = nil
    object.customState = {}
    object.statusText = nil
    object._textures = {}
    object._spriteDefinitions = {}
    object._closed = false
    object._hoverControl = nil
    object._hoverScreenAction = nil
    object._hoverResize = false
    object._pressedControl = nil
    object._pointerControl = nil
    object._pointerDown = false
    object._pointerCancelled = false
    object._pttHeld = false
    object._dragging = false
    object._resizing = false
    object._dragOverscrollY = nil
    object._presentationVisibleHeight = nil
    object._radioOSEngineClipDisabled = false
    object.debugCompositor = options.debugCompositor == true
    object.screenEffects = options.screenEffects ~= false
    object.settingsIndex = 1
    object._lastScreenWidth = nil
    object._lastScreenHeight = nil
    object.resizeHandleSize = math.max(12, math.floor(18 * object.scale))
    object._geometryDirty = false
    object._savedGeometrySignature = nil
    object.background = false
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object._font = UIFont and UIFont.Small or nil
    return object
end

function Window:initialise()
    ISPanel.initialise(self)
    if self.setWantMouseEvents then self:setWantMouseEvents(true) end
    -- The radio artwork is the top-level presentation surface.  Child
    -- clipping belongs to authored LCD/control stencils, not the viewport.
    if self.setRenderClippedChildren then
        self:setRenderClippedChildren(false)
    end
    self.background = false
    self:createPortraitPanel()
end

function Window:createChildren()
    ISPanel.createChildren(self)
end

function Window:createPortraitPanel()
    if self.portraitPanel then return self.portraitPanel end
    local ok, PortraitPanel = pcall(require,
        "PsychopatzCore/UI/Components/PsychopatzPortraitPanel")
    PortraitPanel = ok and PortraitPanel or nil
    if not PortraitPanel then return nil end
    local panel = PortraitPanel:new(0, 0, 1, 1, {
        animate = false,
        faceOnly = true,
        showBackground = false,
        showBorder = false,
        screenVariant = "none",
        padding = 0,
    })
    panel:initialise()
    panel:instantiate()
    panel:setVisible(false)
    self:addChild(panel)
    self.portraitPanel = panel
    return panel
end

function Window:close(reason)
    if self._closed then return end
    self:saveGeometry(true)
    self.closeReason = reason
    self.presentationState = "closed"
    self._closed = true
    if self._layoutEditor then
        local editor = self._layoutEditor
        self._layoutEditor = nil
        if editor.close then editor:close("window_closed") end
    end
    if self.portraitPanel then self.portraitPanel:setVisible(false) end
    if self.removeFromUIManager then self:removeFromUIManager() end
    self:setVisible(false)
    if self.hostWindow and self.hostWindow.setVisible then
        self.hostWindow:setVisible(true)
        if self.hostWindow.bringToTop then self.hostWindow:bringToTop() end
    end
    local diagnostics = OS.Diagnostics
    if diagnostics and diagnostics.RecordWindow then
        diagnostics.RecordWindow("window.closed", self, {
            reason = reason or "unspecified",
        })
    end
    if OS._ForgetWindow then OS._ForgetWindow(self) end
end

require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Navigation"
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Interaction"
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Geometry"
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Presentation"
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Input"
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Renderer"

return Window
