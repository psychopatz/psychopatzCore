require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/World/PsychopatzTeleport"

local Core = PsychopatzCore
local UI = Core.UI
local Teleport = Core.Teleport
local Translation = Core.Translation

local function tr(key, fallback)
    if Translation and Translation.GetKey then
        return Translation.GetKey(key, fallback)
    end
    return fallback or key
end

PsychopatzTeleportWindow = PsychopatzWindow:derive("PsychopatzTeleportWindow")
PsychopatzTeleportWindow.instance = nil

local WIDTH = 320
-- Sized to the content built in createChildren (three fields, a status line and
-- one button row) plus the window chrome.
local HEIGHT = 150

local function playerOrNil()
    if getPlayer then return getPlayer() end
    return nil
end

function PsychopatzTeleportWindow:initialise()
    PsychopatzWindow.initialise(self)
    self.title = tr("UI_PsychopatzTeleport_Title", "Psychopatz Teleport")
    self:setResizable(false)
end

local function addField(window, label, x, y, width)
    window:addChild(ISLabel:new(x, y, 16, label, 1, 1, 1, 1, UIFont.Small, true))
    local entry = ISTextEntryBox:new("0", x, y + 15, width, 20)
    entry:initialise()
    entry:instantiate()
    entry:setClearButton(false)
    window:addChild(entry)
    return entry
end

function PsychopatzTeleportWindow:createChildren()
    PsychopatzWindow.createChildren(self)

    local top = self:titleBarHeight() + 8
    self.xEntry = addField(self, tr("UI_PsychopatzTeleport_X", "X"), 10, top, 92)
    self.yEntry = addField(self, tr("UI_PsychopatzTeleport_Y", "Y"), 112, top, 92)
    self.zEntry = addField(self, tr("UI_PsychopatzTeleport_Z", "Z"), 214, top, 92)

    local y = top + 44
    self.statusLabel = ISLabel:new(10, y, 16,
        tr("UI_PsychopatzTeleport_Hint",
            "Right click the world map for [Debug] Teleport Here."),
        0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self:addChild(self.statusLabel)
    y = y + 22

    self.currentButton = ISButton:new(10, y, 145, 24,
        tr("UI_PsychopatzTeleport_UseCurrent", "USE CURRENT POSITION"),
        self, PsychopatzTeleportWindow.onUseCurrent)
    self.currentButton:initialise()
    self:addChild(self.currentButton)

    self.teleportButton = ISButton:new(165, y, 145, 24,
        tr("UI_PsychopatzTeleport_Go", "TELEPORT"),
        self, PsychopatzTeleportWindow.onTeleport)
    self.teleportButton:initialise()
    self.teleportButton.backgroundColor = { r = 0.28, g = 0.18, b = 0.46, a = 1 }
    self:addChild(self.teleportButton)

    self:setHeight(HEIGHT)
    self:fillFrom(playerOrNil())
end

function PsychopatzTeleportWindow:setStatus(message)
    local label = self.statusLabel
    if not label then return end
    local text = tostring(message or "")
    -- setName() also repositions left-anchored labels; prefer the variant that
    -- only resizes so the row never shifts while a tester reads it.
    if type(label.setNameWithoutMoving) == "function" then
        label:setNameWithoutMoving(text)
    else
        label:setName(text)
    end
end

function PsychopatzTeleportWindow:fillFrom(player)
    if not player then return end
    if self.xEntry then self.xEntry:setText(tostring(math.floor(player:getX()))) end
    if self.yEntry then self.yEntry:setText(tostring(math.floor(player:getY()))) end
    if self.zEntry then self.zEntry:setText(tostring(math.floor(player:getZ()))) end
end

function PsychopatzTeleportWindow:onUseCurrent()
    self:fillFrom(playerOrNil())
    self:setStatus(tr("UI_PsychopatzTeleport_FilledCurrent",
        "Filled with current position."))
end

function PsychopatzTeleportWindow:onTeleport()
    local player = playerOrNil()
    if not player then return end

    -- An explicitly typed level is honoured first, so a tester can target a
    -- basement or an upper floor on purpose.
    local ok, reason, x, y, z = Teleport.ToCoordinates(
        player,
        self.xEntry:getText(),
        self.yEntry:getText(),
        self.zEntry:getText(),
        { exactZ = true }
    )
    if ok then
        self:setStatus(tr("UI_PsychopatzTeleport_Sent", "Teleport sent: ")
            .. math.floor(x) .. ", " .. math.floor(y) .. ", " .. math.floor(z))
    else
        self:setStatus(tr("UI_PsychopatzTeleport_Failed", "Failed: ")
            .. tostring(reason))
    end
end

function PsychopatzTeleportWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if PsychopatzTeleportWindow.instance == self then
        PsychopatzTeleportWindow.instance = nil
    end
end

function PsychopatzTeleportWindow.Open()
    if PsychopatzTeleportWindow.instance then
        local window = PsychopatzTeleportWindow.instance
        window:setVisible(true)
        window:bringToTop()
        window:fillFrom(playerOrNil())
        return window
    end

    local window = UI.NewWindow(PsychopatzTeleportWindow, {
        title = tr("UI_PsychopatzTeleport_Title", "Psychopatz Teleport"),
        persistenceKey = "PsychopatzCore.TeleportCoordinateTool",
        resizable = false,
        width = WIDTH,
        height = HEIGHT,
        responsiveSpec = {
            width = WIDTH, height = HEIGHT,
            minWidth = WIDTH, minHeight = HEIGHT,
            maxWidth = WIDTH, maxHeight = HEIGHT,
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    PsychopatzTeleportWindow.instance = window
    window:fillFrom(playerOrNil())
    return window
end

if Core.DebugHub and type(Core.DebugHub.RegisterTool) == "function" then
    Core.DebugHub.RegisterTool({
        id = "psychopatz.teleport",
        source = "PsychopatzCore",
        order = 15,
        title = tr("UI_PsychopatzDebugHub_Teleport_Title",
            "Teleport To Coordinates"),
        description = tr("UI_PsychopatzDebugHub_Teleport_Description",
            "Teleport to exact world coordinates and resolve a safe level. The world map also offers [Debug] Teleport Here on right click."),
        available = function()
            return Teleport.CanUse(playerOrNil())
        end,
        action = function()
            return PsychopatzTeleportWindow.Open()
        end,
    })
end

return PsychopatzTeleportWindow
