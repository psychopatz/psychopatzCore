require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISTickBox"
require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/Debug/PsychopatzDebugContextMenu"
require "PsychopatzCore/UI/Inventory/PsychopatzItemTypeLedgerWindow"

if PsychopatzCore._debugClientInstalled then
    return PsychopatzCore
end
PsychopatzCore._debugClientInstalled = true

local KEY_NUMPAD_0 = 82
local Debug = PsychopatzCore.Debug

PsychopatzDebugWindow = ISCollapsableWindow:derive("PsychopatzDebugWindow")
PsychopatzDebugWindow.instance = nil

function PsychopatzDebugWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self.title = "Psychopatz Admin Control"
    self:setResizable(false)
end

function PsychopatzDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if PsychopatzDebugWindow.instance == self then
        PsychopatzDebugWindow.instance = nil
    end
end

local function addTickBox(window, y, label, selected, width, onChange)
    local callback
    if onChange then
        callback = function(target, _, value)
            onChange(target, value == true)
        end
    end
    local tickBox = ISTickBox:new(10, y, width or 230, 20, "", window, callback)
    tickBox:initialise()
    tickBox:instantiate()
    tickBox:addOption(label)
    tickBox:setSelected(1, selected == true)
    tickBox:setFont(UIFont.Small)
    window:addChild(tickBox)
    return tickBox
end

local function addQuantityEntry(window, y, defaultValue)
    local entry = ISTextEntryBox:new(tostring(defaultValue), 170, y, 50, 20)
    entry:initialise()
    entry:instantiate()
    entry:setOnlyNumbers(true)
    window:addChild(entry)
    return entry
end

function PsychopatzDebugWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local y = self:titleBarHeight() + 10
    self.chkHeal = addTickBox(self, y, "Heal Wounds", true); y = y + 25
    self.chkStats = addTickBox(self, y, "Reset Stats", true); y = y + 30
    self.chkSpawn = addTickBox(self, y, "Spawn Item", false); y = y + 25
    self.chkMoney = addTickBox(self, y, "Add Money", false, 150)
    self.qtyMoney = addQuantityEntry(self, y, 100); y = y + 25
    self.chkWalkie = addTickBox(self, y, "Add Walkie Talkie", false, 150)
    self.qtyWalkie = addQuantityEntry(self, y, 1); y = y + 25
    self.chkNight = addTickBox(self, y, "Night Vision", _G.PsychopatzNightVisionActive == true); y = y + 25
    self.chkDebugAccess = addTickBox(self, y,
        "Debug Access",
        Debug.IsLocalOverrideEnabled(getPlayer and getPlayer() or nil), 230,
        function(_, enabled)
            local player = getPlayer and getPlayer() or nil
            Debug.SetLocalOverride(enabled, player)
            if player and sendClientCommand then
                sendClientCommand(player, PsychopatzCore.COMMAND_MODULE,
                    Debug.COMMAND, { enabled = enabled })
            end
        end)
    y = y + 25

    self:addChild(ISLabel:new(10, y, 20, "Item ID", 1, 1, 1, 1, UIFont.Small, true))
    self:addChild(ISLabel:new(200, y, 20, "Qty", 1, 1, 1, 1, UIFont.Small, true))
    y = y + 18

    self.itemEntry = ISTextEntryBox:new("Base.Katana", 10, y, 180, 20)
    self.itemEntry:initialise()
    self.itemEntry:instantiate()
    self.itemEntry:setClearButton(true)
    function self.itemEntry:clear() self:setText("Base.") end
    self:addChild(self.itemEntry)

    self.qtyEntry = ISTextEntryBox:new("1", 200, y, 40, 20)
    self.qtyEntry:initialise()
    self.qtyEntry:instantiate()
    self.qtyEntry:setOnlyNumbers(true)
    self:addChild(self.qtyEntry)
    y = y + 30

    self.executeBtn = ISButton:new(10, y, 230, 25, "EXECUTE", self, PsychopatzDebugWindow.onExecute)
    self.executeBtn:initialise()
    self:addChild(self.executeBtn)
    y = y + 30

    self.debugHubBtn = ISButton:new(10, y, 230, 25, "OPEN DEBUG HUB", self, PsychopatzDebugWindow.onOpenDebugHub)
    self.debugHubBtn:initialise()
    self.debugHubBtn.backgroundColor = { r = 0.28, g = 0.18, b = 0.46, a = 1 }
    self:addChild(self.debugHubBtn)
    self:setHeight(y + 35)
end

function PsychopatzDebugWindow:onExecute()
    local player = getPlayer()
    if player then
        local debugAccess = self.chkDebugAccess
            and self.chkDebugAccess:isSelected(1) == true or false
        Debug.SetLocalOverride(debugAccess, player)
        if sendClientCommand then
            sendClientCommand(player, PsychopatzCore.COMMAND_MODULE,
                Debug.COMMAND, { enabled = debugAccess })
        end
        sendClientCommand(player, PsychopatzCore.COMMAND_MODULE, "GrantPowers", {
            itemID = self.itemEntry:getText(),
            quantity = tonumber(self.qtyEntry:getText()) or 1,
            doSpawn = self.chkSpawn:isSelected(1),
            doHeal = self.chkHeal:isSelected(1),
            doStats = self.chkStats:isSelected(1),
            doMoney = self.chkMoney:isSelected(1),
            qtyMoney = tonumber(self.qtyMoney:getText()) or 100,
            doWalkie = self.chkWalkie:isSelected(1),
            qtyWalkie = tonumber(self.qtyWalkie:getText()) or 1,
        })
        _G.PsychopatzNightVisionActive = self.chkNight:isSelected(1)
        if HaloTextHelper then
            HaloTextHelper.addTextWithArrow(player, "COMMAND SENT", true, HaloTextHelper.getColorGreen())
        end
    end
end

function PsychopatzDebugWindow:onOpenDebugHub()
    local player = getPlayer and getPlayer() or nil
    if self.chkDebugAccess then
        local enabled = self.chkDebugAccess:isSelected(1) == true
        Debug.SetLocalOverride(enabled, player)
        if player and sendClientCommand then
            sendClientCommand(player, PsychopatzCore.COMMAND_MODULE,
                Debug.COMMAND, { enabled = enabled })
        end
    end
    PsychopatzCore.DebugHub.Open()
end

local function getOpenDebugWindow()
    local window = PsychopatzDebugWindow.instance
    if not window then return nil end

    if window.getIsVisible and not window:getIsVisible() then
        if PsychopatzDebugWindow.instance == window then
            PsychopatzDebugWindow.instance = nil
        end
        return nil
    end

    return window
end

local function openDebugWindow()
    local existing = getOpenDebugWindow()
    if existing then
        existing:setVisible(true)
        existing:bringToTop()
        return existing
    end

    local player = getPlayer()
    if not PsychopatzCore.IsOwner(player) then return end

    local width, height = 250, 100
    local window = PsychopatzDebugWindow:new(
        math.floor((getCore():getScreenWidth() - width) / 2),
        math.floor((getCore():getScreenHeight() - height) / 2),
        width,
        height
    )
    window:initialise()
    PsychopatzDebugWindow.instance = window
    window:addToUIManager()
    window:setY(math.floor((getCore():getScreenHeight() - window:getHeight()) / 2))
    if window.itemEntry then window.itemEntry:selectAll() end
    return window
end

local function onPsychopatzKey(key)
    if key ~= KEY_NUMPAD_0 then return end
    local player = getPlayer()
    if not PsychopatzCore.IsOwner(player) then return end

    local existing = getOpenDebugWindow()
    if existing then
        existing:onExecute()
        return
    end

    openDebugWindow()
end

Events.OnKeyPressed.Add(onPsychopatzKey)

local nightVisionLight = nil
local updateTick = 0
_G.PsychopatzNightVisionActive = _G.PsychopatzNightVisionActive or false

local function updateNightVision()
    local player = getPlayer()
    if not player then return end

    if _G.PsychopatzNightVisionActive then
        updateTick = updateTick + 1
        if not nightVisionLight or updateTick % 300 == 0 then
            if nightVisionLight then getCell():removeLamppost(nightVisionLight) end
            nightVisionLight = IsoLightSource.new(
                math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()),
                1.0, 1.0, 1.0, 20
            )
            getCell():addLamppost(nightVisionLight)
        else
            nightVisionLight:setX(math.floor(player:getX()))
            nightVisionLight:setY(math.floor(player:getY()))
            nightVisionLight:setZ(math.floor(player:getZ()))
        end
    elseif nightVisionLight then
        getCell():removeLamppost(nightVisionLight)
        nightVisionLight = nil
    end
end

Events.OnTick.Add(updateNightVision)

return PsychopatzCore
