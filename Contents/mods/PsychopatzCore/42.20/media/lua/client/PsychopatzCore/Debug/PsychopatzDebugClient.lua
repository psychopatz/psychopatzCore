require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "PsychopatzCore/00_PsychopatzCore_Init"
local Keybinds = require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
require "PsychopatzCore/Debug/PsychopatzDebugContextMenu"
require "PsychopatzCore/UI/Inventory/PsychopatzItemTypeLedgerWindow"

if PsychopatzCore._debugClientInstalled then
    return PsychopatzCore
end
PsychopatzCore._debugClientInstalled = true

local Debug = PsychopatzCore.Debug
local UI = PsychopatzCore.UI
local DebugHub = PsychopatzCore.DebugHub
local Translation = PsychopatzCore.Translation

local function tr(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

local DebugTraceWindow
local function openDebugTrace()
    if not DebugTraceWindow then
        local loaded, module = pcall(require,
            "PsychopatzCore/UI/PsychopatzDebugTraceWindow")
        if not loaded then
            if print then print("[PsychopatzCore.DebugTrace] " .. tostring(module)) end
            return nil
        end
        DebugTraceWindow = module
    end
    return DebugTraceWindow.Open()
end

-- Preview registration is intentionally cheap at startup. The UI window,
-- renderer, and ISUI drawer are loaded only when the tool is launched.
local Preview = require "PsychopatzCore/Preview/PC_Preview"
local PreviewHub
local function openPreviewHub()
    if not PreviewHub then
        local loaded, module = pcall(require,
            "PsychopatzCore/Preview/PC_PreviewHub")
        if not loaded then
            if print then
                print("[PsychopatzCore.Preview] " .. tostring(module))
            end
            return nil
        end
        PreviewHub = module
    end
    return PreviewHub.Open()
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.preview",
        source = "PsychopatzCore",
        order = 25,
        title = tr("UI_PsychopatzPreview_Title",
            "Preview Hub"),
        description = tr("UI_PsychopatzPreview_Description",
            "Inspect registered client-local perception previews."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
                and #Preview.ListProviders() > 0
        end,
        action = function()
            return openPreviewHub()
        end,
    })
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.runtimeTrace",
        source = "PsychopatzCore",
        order = 5,
        title = tr("UI_PsychopatzDebug_RuntimeTrace_Title", "Runtime Debug Trace"),
        description = tr("UI_PsychopatzDebug_RuntimeTrace_Description",
            "Inspect opt-in structured runtime events from any mod."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
        end,
        action = function()
            return openDebugTrace()
        end,
    })
end

local DebugSettingsWindow
local function openDebugSettings()
    if not DebugSettingsWindow then
        local loaded, module = pcall(require,
            "PsychopatzCore/UI/PsychopatzDebugSettingsWindow")
        if not loaded then
            if print then print("[PsychopatzCore.DebugSettings] " .. tostring(module)) end
            return nil
        end
        DebugSettingsWindow = module
    end
    return DebugSettingsWindow.Open()
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.debugSettings",
        source = "PsychopatzCore",
        order = 10,
        title = tr("UI_PsychopatzDebug_Settings_Title", "Debug Settings"),
        description = tr("UI_PsychopatzDebug_Settings_Description",
            "Enable or disable persisted diagnostic instrumentation."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
        end,
        action = function()
            return openDebugSettings()
        end,
    })
end

local TranslationCoverageWindow
local function openTranslationCoverage()
    if not TranslationCoverageWindow then
        local loaded, module = pcall(require,
            "PsychopatzCore/UI/PsychopatzTranslationCoverageWindow")
        if not loaded then
            if print then
                print("[PsychopatzCore.TranslationCoverage] "
                    .. tostring(module))
            end
            return nil
        end
        TranslationCoverageWindow = module
    end
    return TranslationCoverageWindow.Open()
end

if DebugHub and DebugHub.RegisterTool then
    DebugHub.RegisterTool({
        id = "psychopatz.translationCoverage",
        source = "PsychopatzCore",
        order = 20,
        title = tr("UI_PsychopatzDebugHub_TranslationCoverage_Title",
            "Translation Coverage"),
        description = tr(
            "UI_PsychopatzDebugHub_TranslationCoverage_Description",
            "Find missing, untranslated, and extra keys in registered catalogs."),
        available = function()
            return Debug.CanUse(getPlayer and getPlayer() or nil)
        end,
        action = function()
            return openTranslationCoverage()
        end,
    })
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
        sendClientCommand(player, PsychopatzCore.COMMAND_MODULE,
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
            HaloTextHelper.addTextWithArrow(player,
                tr("UI_PsychopatzDebug_CommandSent", "COMMAND SENT"), true,
                HaloTextHelper.getColorGreen())
        end
    end
end

function PsychopatzDebugWindow:onOpenDebugHub()
    local player = getPlayer and getPlayer() or nil
    applyDebugAccess(debugAccessState(self), player)
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
        width, height, {
            persistenceNamespace = "Debug",
            persistenceKey = "AdminControl",
            resizable = false,
            bottomResize = false,
            responsiveSpec = {
                width = width, height = height,
                minWidth = width, minHeight = height,
                maxWidth = width, maxHeight = height,
            },
        }
    )
    window:initialise()
    PsychopatzDebugWindow.instance = window
    window:addToUIManager()
    if not window.psychopatzGeometryRestored then
        window:setX(math.floor((getCore():getScreenWidth()
            - window:getWidth()) / 2))
        window:setY(math.floor((getCore():getScreenHeight()
            - window:getHeight()) / 2))
    end
    if window.itemEntry then window.itemEntry:selectAll() end
    return window
end

local function onDebugTap()
    local player = getPlayer()
    if not PsychopatzCore.IsOwner(player) then return end

    local existing = getOpenDebugWindow()
    if existing then
        existing:onExecute()
    end
end

local function onDebugLongPress()
    local player = getPlayer()
    if not PsychopatzCore.IsOwner(player) then return end

    if not getOpenDebugWindow() then
        openDebugWindow()
    end
end

Keybinds.RegisterTapLongPress({
    id = "PsychopatzCore.DebugControlsNumpad0",
    label = tr("UI_PsychopatzCore_DebugControlsKey",
        "Open Psychopatz Debug Controls (Numpad 0)"),
    tooltip = tr("UI_PsychopatzCore_DebugControlsTooltip",
        "Hold Numpad 0 for 600 ms to open the controls; press and release it while open to execute the current command set."),
    exposeInOptions = false,
    defaultKey = Keyboard and Keyboard.KEY_NUMPAD0 or 82,
    longPressMs = 600,
    isEnabled = function()
        return PsychopatzCore.IsOwner(getPlayer and getPlayer() or nil)
    end,
    onTap = onDebugTap,
    onLongPress = onDebugLongPress,
})

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
