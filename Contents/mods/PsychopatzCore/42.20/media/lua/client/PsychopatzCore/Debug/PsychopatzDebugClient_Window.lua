local Core = PsychopatzCore
local Debug = Core.Debug
local UI = Core.UI
local Translation = Core.Translation

local function tr(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

PsychopatzDebugWindow = PsychopatzWindow:derive("PsychopatzDebugWindow")
PsychopatzDebugWindow.instance = nil

function PsychopatzDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
    self.title = tr("UI_PsychopatzDebug_Admin_Title", "Psychopatz Admin Control")
    self:setResizable(false)
end

function PsychopatzDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if PsychopatzDebugWindow.instance == self then
        PsychopatzDebugWindow.instance = nil
    end
end

local function addQuantityEntry(window, y, defaultValue)
    local entry = ISTextEntryBox:new(tostring(defaultValue), 170, y, 50, 20)
    entry:initialise()
    entry:instantiate()
    entry:setOnlyNumbers(true)
    window:addChild(entry)
    return entry
end

local function addToggleButton(window, y, offTitle, onTitle, selected,
    onChange)
    local button = UI.CreateToggleButton(window, {
        id = "debug_access",
        offTitle = offTitle,
        onTitle = onTitle,
        target = window,
        value = selected == true,
        autoToggle = true,
        onChange = onChange,
        offVariant = "quiet",
        onVariant = "success",
    })
    button:setX(10)
    button:setY(y)
    button:setWidth(230)
    button:setHeight(20)
    return button
end

local function debugAccessState(window)
    local control = window.debugAccessButton or window.chkDebugAccess
    if control and control.getToggleState then
        return control:getToggleState() == true
    end
    return control and control.isSelected
        and control:isSelected(1) == true or false
end

local function applyDebugAccess(enabled, player)
    Debug.SetLocalOverride(enabled, player)
    if player and sendClientCommand then
        sendClientCommand(player, Core.COMMAND_MODULE,
            Debug.COMMAND, { enabled = enabled })
    end
end

function PsychopatzDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)

    local y = self:titleBarHeight() + 10
    self.chkHeal = UI.CreateCheckbox(self, {
        id = "heal_wounds", label = tr("UI_PsychopatzDebug_Action_HealWounds", "Heal Wounds"), value = true,
        x = 10, y = y, target = self, font = UIFont.Small,
    }); y = y + 25
    self.chkStats = UI.CreateCheckbox(self, {
        id = "reset_stats", label = tr("UI_PsychopatzDebug_Action_ResetStats", "Reset Stats"), value = true,
        x = 10, y = y, target = self, font = UIFont.Small,
    }); y = y + 30
    self.chkSpawn = UI.CreateCheckbox(self, {
        id = "spawn_item", label = tr("UI_PsychopatzDebug_Action_SpawnItem", "Spawn Item"), value = false,
        x = 10, y = y, target = self, font = UIFont.Small,
    }); y = y + 25
    self.chkMoney = UI.CreateCheckbox(self, {
        id = "add_money", label = tr("UI_PsychopatzDebug_Action_AddMoney", "Add Money"), value = false,
        x = 10, y = y, width = 150, target = self, font = UIFont.Small,
    })
    self.qtyMoney = addQuantityEntry(self, y, 100); y = y + 25
    self.chkWalkie = UI.CreateCheckbox(self, {
        id = "add_walkie", label = tr("UI_PsychopatzDebug_Action_AddWalkieTalkie", "Add Walkie Talkie"), value = false,
        x = 10, y = y, width = 150, target = self, font = UIFont.Small,
    })
    self.qtyWalkie = addQuantityEntry(self, y, 1); y = y + 25
    self.chkNight = UI.CreateCheckbox(self, {
        id = "night_vision", label = tr("UI_PsychopatzDebug_Action_NightVision", "Night Vision"),
        value = _G.PsychopatzNightVisionActive == true,
        x = 10, y = y, target = self, font = UIFont.Small,
    }); y = y + 25
    self.debugAccessButton = addToggleButton(self, y,
        tr("UI_PsychopatzDebug_Access_Off", "Debug Access: OFF"),
        tr("UI_PsychopatzDebug_Access_On", "Debug Access: ON"),
        Debug.IsLocalOverrideEnabled(getPlayer and getPlayer() or nil),
        function(_, _, enabled)
            applyDebugAccess(enabled == true,
                getPlayer and getPlayer() or nil)
        end)
    self.chkDebugAccess = self.debugAccessButton
    y = y + 25

    self:addChild(ISLabel:new(10, y, 20,
        tr("UI_PsychopatzDebug_ItemID", "Item ID"), 1, 1, 1, 1, UIFont.Small, true))
    self:addChild(ISLabel:new(200, y, 20,
        tr("UI_PsychopatzDebug_Quantity", "Qty"), 1, 1, 1, 1, UIFont.Small, true))
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

    self.executeBtn = ISButton:new(10, y, 230, 25,
        tr("UI_PsychopatzDebug_Execute", "EXECUTE"), self,
        PsychopatzDebugWindow.onExecute)
    self.executeBtn:initialise()
    self:addChild(self.executeBtn)
    y = y + 30

    self.debugHubBtn = ISButton:new(10, y, 230, 25,
        tr("UI_PsychopatzDebug_OpenHub", "OPEN DEBUG HUB"), self,
        PsychopatzDebugWindow.onOpenDebugHub)
    self.debugHubBtn:initialise()
    self.debugHubBtn.backgroundColor = { r = 0.28, g = 0.18, b = 0.46, a = 1 }
    self:addChild(self.debugHubBtn)
    self:setHeight(y + 35)
end

function PsychopatzDebugWindow:onExecute()
    local player = getPlayer()
    if player then
        local debugAccess = debugAccessState(self)
        applyDebugAccess(debugAccess, player)
        sendClientCommand(player, Core.COMMAND_MODULE, "GrantPowers", {
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
            HaloTextHelper.addTextWithArrow(player,
                tr("UI_PsychopatzDebug_CommandSent", "COMMAND SENT"), true,
                HaloTextHelper.getColorGreen())
        end
    end
end

function PsychopatzDebugWindow:onOpenDebugHub()
    local player = getPlayer and getPlayer() or nil
    applyDebugAccess(debugAccessState(self), player)
    Core.DebugHub.Open()
end

return Core
