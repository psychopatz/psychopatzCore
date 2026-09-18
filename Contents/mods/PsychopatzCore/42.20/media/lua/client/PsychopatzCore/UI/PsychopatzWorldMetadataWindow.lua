require "ISUI/ISLabel"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Components/PsychopatzCheckbox"

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Translation = PsychopatzCore.Translation
local Debug = PsychopatzCore.Debug
local Extractor = require
    "PsychopatzCore/World/PsychopatzWorldMetadataExtractor"

local ZONE_OPTIONS = {
    { key = "Places", translationKey = "UI_PsychopatzWorldMetadata_Include_Places", fallback = "Places", default = true },
    { key = "ZombiesType", translationKey = "UI_PsychopatzWorldMetadata_Include_ZombiesType", fallback = "ZombiesType", default = true },
    { key = "Nav", translationKey = "UI_PsychopatzWorldMetadata_Include_Nav", fallback = "Nav", default = false },
    { key = "ForagingNav", translationKey = "UI_PsychopatzWorldMetadata_Include_ForagingNav", fallback = "ForagingNav", default = false },
    { key = "SpawnPoint", translationKey = "UI_PsychopatzWorldMetadata_Include_SpawnPoint", fallback = "SpawnPoint", default = false },
    { key = "Other", translationKey = "UI_PsychopatzWorldMetadata_Include_OtherZones", fallback = "Other zones", default = true },
}

local Controller = PsychopatzCore.WorldMetadataWindow or {}
PsychopatzCore.WorldMetadataWindow = Controller

local function tr(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

local function currentPlayer()
    return getPlayer and getPlayer() or nil
end

local function canUseDebug()
    return Debug and type(Debug.CanUse) == "function"
        and Debug.CanUse(currentPlayer()) == true
end

local function addLabel(window, text, color)
    local label = ISLabel:new(0, 0, 1, 22, tostring(text or ""),
        1, 1, 1, 1, UIFont.Small, false)
    label:initialise()
    label:instantiate()
    window:addChild(label)
    if UI.SetLabelTheme then UI.SetLabelTheme(label, color or "text") end
    return label
end

local function phaseLabel(phase)
    local labels = {
        idle = "Idle",
        zones = "Scanning zones",
        buildings = "Scanning buildings",
        rooms = "Scanning rooms",
        assign = "Assigning places",
        sort = "Sorting place records",
        write = "Writing place files",
        index = "Writing index",
        complete = "Complete",
        failed = "Failed",
        cancelled = "Cancelled",
    }
    return labels[phase] or tostring(phase or "Idle")
end

PsychopatzWorldMetadataWindow = UI.Window:derive(
    "PsychopatzWorldMetadataWindow")
PsychopatzWorldMetadataWindow.instance = nil

function PsychopatzWorldMetadataWindow:initialise()
    UI.Window.initialise(self)
end

function PsychopatzWorldMetadataWindow:createChildren()
    UI.Window.createChildren(self)
    self.statusLabel = addLabel(self, "Idle", "text")
    self.phaseLabel = addLabel(self, "", "textMuted")
    self.progressLabel = addLabel(self, "", "textMuted")
    self.countLabel = addLabel(self, "", "textMuted")
    self.placeLabel = addLabel(self, "", "textMuted")
    self.selectionTitle = addLabel(self, tr(
        "UI_PsychopatzWorldMetadata_OutputTypes", "Output types"), "accent")
    self.zoneChecks = {}
    for _, option in ipairs(ZONE_OPTIONS) do
        local checkbox = UI.CreateCheckbox(self, {
            id = "worldMetadata_" .. option.key,
            label = tr(option.translationKey, option.fallback),
            value = option.default,
        })
        self.zoneChecks[#self.zoneChecks + 1] = {
            key = option.key,
            control = checkbox,
        }
    end
    self.logTitle = addLabel(self, tr("UI_PsychopatzWorldMetadata_Logs",
        "Recent log (last 5)"), "accent")
    self.logLabels = {}
    for index = 1, Extractor.MAX_LOG_LINES do
        self.logLabels[index] = addLabel(self, "", "textMuted")
    end

    self.startButton = UI.CreateButton(self, {
        id = "start",
        title = tr("UI_PsychopatzWorldMetadata_Start", "Start"),
        target = self,
        onclick = PsychopatzWorldMetadataWindow.onStart,
        variant = "primary",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel",
        title = tr("UI_PsychopatzWorldMetadata_Cancel", "Cancel"),
        target = self,
        onclick = PsychopatzWorldMetadataWindow.onCancel,
        variant = "danger",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PsychopatzWorldMetadata_Close", "Close"),
        target = self,
        onclick = PsychopatzWorldMetadataWindow.onClose,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
end

function PsychopatzWorldMetadataWindow:refreshFromSession()
    local session = Controller.session
    local snapshot = session and session:Snapshot() or {
        state = "idle", phase = "idle", completed = 0, total = 0,
        counts = {}, logs = {}, outputRoot = Extractor.OUTPUT_ROOT,
    }
    local state = tostring(snapshot.state or "idle")
    UI.SetLabelText(self.statusLabel, tr(
        "UI_PsychopatzWorldMetadata_Status", "Status: ") .. state)
    UI.SetLabelText(self.phaseLabel, "Phase: " .. phaseLabel(snapshot.phase))
    local progress = snapshot.total and snapshot.total > 0
        and math.floor(snapshot.completed * 100 / snapshot.total) or 0
    UI.SetLabelText(self.progressLabel, string.format(
        "Progress: %d / %d (%d%%)", snapshot.completed or 0,
        snapshot.total or 0, progress))
    local counts = snapshot.counts or {}
    UI.SetLabelText(self.countLabel, string.format(
        "Unique: %d zones | %d buildings | %d rooms",
        counts.zones or 0, counts.buildings or 0, counts.rooms or 0))
    UI.SetLabelText(self.placeLabel,
        "Output: " .. tostring(snapshot.outputRoot or ""))

    local logs = snapshot.logs or {}
    for index = 1, #self.logLabels do
        UI.SetLabelText(self.logLabels[index], logs[index] or "")
    end
    if self.startButton and self.startButton.setEnable then
        self.startButton:setEnable(state ~= "running")
    end
    if self.cancelButton and self.cancelButton.setEnable then
        self.cancelButton:setEnable(state == "running")
    end
    for _, row in ipairs(self.zoneChecks or {}) do
        if row.control and row.control.setEnable then
            row.control:setEnable(state ~= "running")
        end
    end
end

function PsychopatzWorldMetadataWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 48, bottom = 44 })
    local rowHeight = Layout.Pixels(24, self.uiScale)
    local y = rect.y
    local labels = {
        self.statusLabel, self.phaseLabel, self.progressLabel,
        self.countLabel, self.placeLabel,
    }
    for _, label in ipairs(labels) do
        Layout.SetBounds(label, rect.x, y, rect.width, rowHeight)
        y = y + rowHeight
    end
    y = y + Layout.Pixels(8, self.uiScale)
    Layout.SetBounds(self.selectionTitle, rect.x, y, rect.width, rowHeight)
    y = y + rowHeight
    for _, row in ipairs(self.zoneChecks or {}) do
        Layout.SetBounds(row.control, rect.x, y, rect.width, rowHeight)
        y = y + rowHeight
    end
    y = y + Layout.Pixels(8, self.uiScale)
    Layout.SetBounds(self.logTitle, rect.x, y, rect.width, rowHeight)
    y = y + rowHeight
    for _, label in ipairs(self.logLabels) do
        Layout.SetBounds(label, rect.x, y, rect.width, rowHeight)
        y = y + rowHeight
    end

    local buttonY = self:getHeight() - Layout.Pixels(36, self.uiScale)
    local buttonWidth = Layout.Pixels(100, self.uiScale)
    Layout.SetBounds(self.startButton, rect.x, buttonY,
        buttonWidth, Layout.Pixels(26, self.uiScale))
    Layout.SetBounds(self.cancelButton, rect.x + buttonWidth + 8, buttonY,
        buttonWidth, Layout.Pixels(26, self.uiScale))
    Layout.SetBounds(self.closeButton,
        self:getWidth() - buttonWidth - Layout.Pixels(10, self.uiScale),
        buttonY, buttonWidth, Layout.Pixels(26, self.uiScale))
end

function PsychopatzWorldMetadataWindow:onStart()
    if not canUseDebug() then return end
    if Controller.session and Controller.session.state == "running" then
        return
    end
    local selections = {}
    for _, row in ipairs(self.zoneChecks or {}) do
        selections[row.key] = row.control:getChecked()
    end
    Controller.session = Extractor.CreateSession({
        writeOutput = true,
        zoneSelections = selections,
    })
    Controller.session:Start()
    self:refreshFromSession()
end

function PsychopatzWorldMetadataWindow:onCancel()
    if Controller.session then Controller.session:Cancel() end
    self:refreshFromSession()
end

function PsychopatzWorldMetadataWindow:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    PsychopatzWorldMetadataWindow.instance = nil
end

function PsychopatzWorldMetadataWindow:prerender()
    UI.Window.prerender(self)
    self:refreshFromSession()
end

local function installTick()
    if Controller.tickInstalled or not Events
        or not Events.OnTick or not Events.OnTick.Add
    then
        return
    end
    Controller.tickInstalled = true
    Events.OnTick.Add(function()
        if Controller.session and Controller.session.state == "running" then
            Controller.session:Step()
        end
        local window = PsychopatzWorldMetadataWindow.instance
        if window then window:refreshFromSession() end
    end)
end

function Controller.Open()
    if not canUseDebug() then return nil end
    installTick()
    if PsychopatzWorldMetadataWindow.instance then
        local window = PsychopatzWorldMetadataWindow.instance
        window:setVisible(true)
        window:bringToTop()
        window:refreshFromSession()
        return window
    end

    local window = UI.NewWindow(PsychopatzWorldMetadataWindow, {
        title = tr("UI_PsychopatzWorldMetadata_Title",
            "Export World Place Metadata"),
        persistenceNamespace = "Debug",
        persistenceKey = "WorldPlaceMetadata",
        responsiveSpec = {
            width = 620,
            height = 560,
            minWidth = 460,
            minHeight = 540,
            maxWidth = 900,
            maxHeight = 800,
        },
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    PsychopatzWorldMetadataWindow.instance = window
    window:refreshFromSession()
    return window
end

function Controller.GetSession()
    return Controller.session
end

return Controller
