local Bootstrap = PsychopatzCore and PsychopatzCore.ProfilerBootstrap
if not Bootstrap then return nil end

require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISLabel"
require "ISUI/ISTickBox"

PsychopatzCore.ProfilerWindow = PsychopatzCore.ProfilerWindow or {}
local Controller = PsychopatzCore.ProfilerWindow
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

local VIEWS = { "Overview", "CPU", "Metrics", "Growth", "Network", "Events", "History", "Settings" }
local MODES = { Bootstrap.MODE_OFF, Bootstrap.MODE_BASIC, Bootstrap.MODE_DETAILED }

local function nextMode(mode)
    for index = 1, #MODES do
        if MODES[index] == mode then return MODES[index % #MODES + 1] end
    end
    return Bootstrap.MODE_OFF
end

local function drawMetric(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(item.name, 10, y + 6, color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawTextRight(item.value, list:getWidth() - 10, y + 6, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

local function createSettingsLabel(parent, text)
    local label = ISLabel:new(0, 0, 20, tostring(text or ""), 1, 1, 1, 1, UIFont.Small, true)
    label:initialise()
    label:instantiate()
    parent:addChild(label)
    return label
end

local function createSettingsToggle(parent, target, text, onChange)
    local tick = ISTickBox:new(0, 0, 20, 24, "", target, function(_, _, selected)
        onChange(target, selected == true)
    end)
    tick:initialise()
    tick:instantiate()
    tick:addOption(tostring(text or ""), 1)
    parent:addChild(tick)
    return tick
end

PsychopatzProfilerWindow = PsychopatzWindow:derive("PsychopatzProfilerWindow")

function PsychopatzProfilerWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function PsychopatzProfilerWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.view = "Overview"
    self.tabButtons = {}
    for index = 1, #VIEWS do
        local name = VIEWS[index]
        local button = UI.CreateButton(self, {
            title = name, target = self,
            onclick = function(target)
                target.view = name
                target:requestResponsiveLayout(true)
                target:refreshMetrics(true)
            end,
            variant = "quiet",
        })
        self.tabButtons[#self.tabButtons + 1] = button
    end
    self.metricList = UI.CreateList(self, { itemHeight = 26, doDrawItem = drawMetric })
    self.settingsPanel = UI.CreatePanel(self)
    self.settingsTitleLabel = createSettingsLabel(self.settingsPanel, "Capture settings")
    self.settingsMode = Bootstrap.GetMode()
    self.settingsDirty = false
    self.settingsModeButton = UI.CreateButton(self.settingsPanel, {
        title = "Mode: " .. tostring(self.settingsMode), target = self,
        onclick = self.onSettingsModeCycle, variant = "primary",
    })
    self.settingsPerformance = createSettingsToggle(self.settingsPanel, self,
        "Performance capture", function(target) target.settingsDirty = true end)
    self.settingsModData = createSettingsToggle(self.settingsPanel, self,
        "ModData summary capture", function(target) target.settingsDirty = true end)
    self.settingsNPC = createSettingsToggle(self.settingsPanel, self,
        "NPC data capture", function(target) target.settingsDirty = true end)
    self.settingsHintLabel = createSettingsLabel(self.settingsPanel,
        "Changes apply to the current runtime and the shared profiler config file.")
    self.settingsStatusLabel = createSettingsLabel(self.settingsPanel, "")
    self.settingsApplyButton = UI.CreateButton(self.settingsPanel, {
        title = "Apply settings", target = self, onclick = self.onSettingsApply,
        variant = "success",
    })
    self.resetButton = UI.CreateButton(self, { title = getText("UI_PsychopatzProfiler_Reset"), target = self, onclick = self.onReset })
    self.exportButton = UI.CreateButton(self, { title = getText("UI_PsychopatzProfiler_Export"), target = self, onclick = self.onExport })
    self.closeButton = UI.CreateButton(self, { title = "Close", target = self, onclick = self.close, variant = "quiet" })
    self:requestResponsiveLayout(true)
    self:refreshMetrics(true)
end

function PsychopatzProfilerWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 82, bottom = 48 })
    Layout.Flow(self.tabButtons, { x = rect.x, y = rect.y - 34, width = rect.width }, { scale = self.uiScale })
    local settingsVisible = self.view == "Settings"
    self.metricList:setVisible(not settingsVisible)
    self.settingsPanel:setVisible(settingsVisible)
    Layout.SetBounds(self.metricList, rect.x, rect.y, rect.width, rect.height)
    Layout.SetBounds(self.settingsPanel, rect.x, rect.y, rect.width, rect.height)
    if settingsVisible then
        self.settingsTitleLabel:setX(16)
        self.settingsTitleLabel:setY(16)
        Layout.SetBounds(self.settingsModeButton, 16, 48, math.min(260, rect.width - 32), 28)
        Layout.SetBounds(self.settingsPerformance, 16, 88, rect.width - 32, 24)
        Layout.SetBounds(self.settingsModData, 16, 118, rect.width - 32, 24)
        Layout.SetBounds(self.settingsNPC, 16, 148, rect.width - 32, 24)
        self.settingsHintLabel:setX(16)
        self.settingsHintLabel:setY(190)
        self.settingsStatusLabel:setX(16)
        self.settingsStatusLabel:setY(218)
        Layout.SetBounds(self.settingsApplyButton, 16, 254, math.min(260, rect.width - 32), 28)
    end
    local buttons = { self.resetButton, self.exportButton, self.closeButton }
    for _, button in ipairs(buttons) do button.psychopatzPreferredWidth = Layout.Pixels(150, self.uiScale) end
    Layout.Flow(buttons, { x = rect.x, y = rect.y + rect.height + 8, width = rect.width }, { scale = self.uiScale })
end

local function add(list, name, value)
    list:addItem(name, { name = name, value = tostring(value) })
end

local function formatted(value, suffix)
    return string.format("%.2f%s", tonumber(value) or 0, suffix or "")
end

local function sectionSummary(config)
    if not config or #(config.sections or {}) == 0 then return "none" end
    return table.concat(config.sections, ", ")
end

function PsychopatzProfilerWindow:refreshSettingsControls(force)
    local config = Bootstrap.GetCaptureConfig()
    if force or not self.settingsDirty then
        self.settingsMode = config.mode
        self.settingsPerformance:setSelected(1, config.enabled.performance == true)
        self.settingsModData:setSelected(1, config.enabled.moddata == true)
        self.settingsNPC:setSelected(1, config.enabled.npc == true)
    end
    self.settingsModeButton:setTitle("Mode: " .. tostring(self.settingsMode))
    local profiler = PsychopatzCore.Profiler
    local running = profiler and profiler.IsRunning and profiler.IsRunning()
    local status
    if self.settingsDirty then
        status = "Unsaved changes — press Apply settings."
    elseif running then
        status = "LIVE — capturing: " .. sectionSummary(config)
    else
        status = "OFF — no profiler sampler or capture callback is installed."
    end
    self.settingsStatusLabel:setName(status)
    return config
end

function PsychopatzProfilerWindow:onSettingsModeCycle()
    self.settingsMode = nextMode(self.settingsMode)
    self.settingsDirty = true
    self.settingsModeButton:setTitle("Mode: " .. tostring(self.settingsMode))
    self.settingsStatusLabel:setName("Unsaved changes — press Apply settings.")
end

function PsychopatzProfilerWindow:onSettingsApply()
    local current = Bootstrap.GetCaptureConfig()
    local capture = {}
    if self.settingsPerformance:isSelected(1) then capture[#capture + 1] = "performance" end
    if self.settingsModData:isSelected(1) then capture[#capture + 1] = "moddata" end
    if self.settingsNPC:isSelected(1) then capture[#capture + 1] = "npc" end
    local result, reason = Bootstrap.ApplyCaptureConfig({
        mode = self.settingsMode,
        capture = capture,
        performance_interval_ms = current.performanceIntervalMs,
        moddata_interval_ms = current.modDataIntervalMs,
        npc_interval_ms = current.npcIntervalMs,
        npc_scope = current.npcScope,
        npc_ids = current.npcIDs,
    })
    if not result then
        self.settingsStatusLabel:setName("Could not apply: " .. tostring(reason))
        return
    end
    local persisted, persistReason = Bootstrap.WriteConfiguredConfig(Bootstrap.GetCaptureConfig())
    self.settingsDirty = false
    self:refreshSettingsControls(true)
    if persisted then
        self.settingsStatusLabel:setName("Applied live and saved to the shared profiler config.")
    else
        self.settingsStatusLabel:setName("Applied live; config save failed: " .. tostring(persistReason))
    end
    self:refreshMetrics(true)
end

function PsychopatzProfilerWindow:refreshMetrics(force)
    local now = getTimeInMillis and getTimeInMillis() or 0
    if not force and now - (self.lastRefreshAt or 0) < 1000 then return end
    self.lastRefreshAt = now
    local profiler = PsychopatzCore.Profiler
    local running = profiler and profiler.IsRunning and profiler.IsRunning()
    local config = self:refreshSettingsControls(false)
    self.metricList:clear()
    if self.resetButton.setEnable then self.resetButton:setEnable(running == true) end
    if self.exportButton.setEnable then self.exportButton:setEnable(running == true) end
    if self.view == "Settings" then
        add(self.metricList, "Mode", config.mode)
        add(self.metricList, "Capture sections", sectionSummary(config))
        add(self.metricList, "Performance interval", tostring(config.performanceIntervalMs) .. " ms")
        add(self.metricList, "ModData interval", tostring(config.modDataIntervalMs) .. " ms")
        add(self.metricList, "NPC interval", tostring(config.npcIntervalMs) .. " ms")
        add(self.metricList, "NPC scope", config.npcScope)
        add(self.metricList, "Runtime", running and "active" or "inactive")
        add(self.metricList, "Config fingerprint", config.fingerprint)
        return
    end
    if not running then
        add(self.metricList, "Profiler", "OFF")
        add(self.metricList, "Capture", "No sampling callbacks installed")
        add(self.metricList, "Capture sections", sectionSummary(config))
        add(self.metricList, "Settings", "Use the Settings tab to enable profiling")
        return
    end
    local state = profiler.GetState()
    if self.view == "Overview" then
        add(self.metricList, "Mode", profiler.GetMode())
        local calls, cpu = 0, 0
        local namespaceCPU = {}
        for _, metric in ipairs(profiler.GetMetrics("timer")) do
            calls = calls + metric.callsPerSec
            cpu = cpu + metric.msPerSec
            namespaceCPU[metric.namespace] = (namespaceCPU[metric.namespace] or 0) + metric.msPerSec
        end
        add(self.metricList, "Profiled CPU", formatted(cpu, " ms/s"))
        add(self.metricList, "Profiled calls", formatted(calls, " /s"))
        add(self.metricList, "Warnings", #(profiler.GetWarnings() or {}))
        for namespace, value in pairs(namespaceCPU) do add(self.metricList, namespace, formatted(value, " ms/s")) end
    elseif self.view == "CPU" then
        local timers = profiler.GetMetrics("timer")
        table.sort(timers, function(left, right) return left.msPerSec > right.msPerSec end)
        for _, metric in ipairs(timers) do
            add(self.metricList, metric.name, string.format("%.2f ms/s | %.2f avg | %.2f peak | %.1f/s",
                metric.msPerSec, metric.averageMs, metric.peakMs, metric.callsPerSec))
        end
    elseif self.view == "Growth" then
        for _, metric in ipairs(profiler.GetMetrics("gauge")) do
            add(self.metricList, metric.name, string.format("%.2f | 1m %+.2f | 5m %+.2f",
                metric.value, profiler.GetGrowth(metric.name, 60) or 0, profiler.GetGrowth(metric.name, 300) or 0))
        end
    elseif self.view == "Network" then
        for _, metric in ipairs(profiler.GetMetrics("rate")) do
            if string.find(string.lower(metric.name), "network", 1, true) then add(self.metricList, metric.name, formatted(metric.perSec, " /s")) end
        end
        local remote = PsychopatzCore.ProfilerClient and PsychopatzCore.ProfilerClient.serverSnapshot
        add(self.metricList, "Server snapshot", remote and "available" or "not requested / unavailable")
        for namespaceName, namespace in pairs(remote and remote.namespaces or {}) do
            for metricName, metric in pairs(namespace.timers or {}) do
                if string.find(string.lower(metricName), "network", 1, true) then
                    add(self.metricList, "Server | " .. namespaceName .. "." .. metricName,
                        formatted(metric.callsPerSec, " /s") .. " | " .. formatted(metric.msPerSec, " ms/s"))
                end
            end
            for metricName, metric in pairs(namespace.rates or {}) do
                add(self.metricList, "Server | " .. namespaceName .. "." .. metricName,
                    formatted(metric.perSec, " /s"))
            end
        end
    elseif self.view == "Events" then
        local values = profiler.GetMetrics("rate")
        for _, metric in ipairs(profiler.GetMetrics("timer")) do values[#values + 1] = metric end
        table.sort(values, function(left, right) return (left.perSec or left.callsPerSec or 0) > (right.perSec or right.callsPerSec or 0) end)
        for _, metric in ipairs(values) do add(self.metricList, metric.name, formatted(metric.perSec or metric.callsPerSec, " /s")) end
    elseif self.view == "History" then
        add(self.metricList, "History", state.mode == "DETAILED" and "bounded to " .. tostring(state.historyCapacity) .. " samples" or "available in DETAILED mode")
        for _, metric in ipairs(profiler.GetMetrics()) do
            if metric.history then add(self.metricList, metric.name, tostring(metric.history.count) .. " samples") end
        end
    else
        for _, metric in ipairs(profiler.GetMetrics()) do
            local value = metric.value or metric.perSec or metric.msPerSec or 0
            add(self.metricList, metric.name, formatted(value))
        end
    end
    if isClient and isClient() and PsychopatzCore.ProfilerClient then
        if now - (self.lastServerRequestAt or 0) >= 2000 then
            PsychopatzCore.ProfilerClient.RequestServerSnapshot()
            self.lastServerRequestAt = now
        end
    end
end

function PsychopatzProfilerWindow:update()
    PsychopatzWindow.update(self)
    self:refreshMetrics(false)
end

function PsychopatzProfilerWindow:onReset()
    if not PsychopatzCore.Profiler or not PsychopatzCore.Profiler.IsRunning
        or not PsychopatzCore.Profiler.IsRunning() then return end
    PsychopatzCore.Profiler.ResetPeaks()
    PsychopatzCore.Profiler.ResetHistories()
    PsychopatzCore.Profiler.ResetWarnings()
    self:refreshMetrics(true)
end

function PsychopatzProfilerWindow:onExport()
    if not PsychopatzCore.Profiler or not PsychopatzCore.Profiler.IsRunning
        or not PsychopatzCore.Profiler.IsRunning() then return end
    PsychopatzCore.Profiler.ExportSnapshot()
end

function PsychopatzProfilerWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    PsychopatzProfilerWindow.instance = nil
end

function PsychopatzProfilerWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function Controller.Open()
    if PsychopatzProfilerWindow.instance then
        PsychopatzProfilerWindow.instance:setVisible(true)
        PsychopatzProfilerWindow.instance:bringToTop()
        return PsychopatzProfilerWindow.instance
    end
    local window = UI.NewWindow(PsychopatzProfilerWindow, {
        title = getText("UI_PsychopatzProfiler_Title"),
        persistenceKey = "psychopatzProfiler",
        responsiveSpec = { width = 900, height = 620, minWidth = 600, minHeight = 400 },
    })
    window:initialise(); window:instantiate(); window:addToUIManager()
    PsychopatzProfilerWindow.instance = window
    return window
end

function Controller.Close()
    if PsychopatzProfilerWindow.instance then PsychopatzProfilerWindow.instance:close() end
end

Controller.Window = PsychopatzProfilerWindow
return Controller
