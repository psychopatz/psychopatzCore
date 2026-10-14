-- Lifecycle, navigation and input for the physical Radio OS window.
-- Rendering is isolated in PsychopatzRadioOSWindow_Renderer.lua.

require "ISUI/ISPanel"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local OS = PsychopatzCore.RadioOS
local Window = ISPanel:derive("PsychopatzRadioOSWindow")
OS.Window = Window

function Window:new(x, y, width, height, context, options)
    local object = ISPanel:new(x, y, width, height)
    options = type(options) == "table" and options or {}
    setmetatable(object, self)
    self.__index = self
    object.context = context or {}
    object.playerNum = tonumber(object.context.playerNum) or 0
    object.scale = tonumber(options.scale) or 1
    object.owner = options.owner
    object.skin = object.context.skin
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
    object._closed = false
    object._hoverControl = nil
    object._pressedControl = nil
    object.background = false
    object.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    object.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    object._font = UIFont and UIFont.Small or nil
    return object
end

function Window:initialise()
    ISPanel.initialise(self)
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

function Window:close()
    if self._closed then return end
    self._closed = true
    if self.portraitPanel then self.portraitPanel:setVisible(false) end
    if self.removeFromUIManager then self:removeFromUIManager() end
    self:setVisible(false)
    if OS._ForgetWindow then OS._ForgetWindow(self) end
end

require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Navigation"
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Input"
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Renderer"

return Window
