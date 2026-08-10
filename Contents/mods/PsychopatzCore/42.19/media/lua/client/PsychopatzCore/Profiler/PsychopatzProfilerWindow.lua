local Bootstrap = PsychopatzCore and PsychopatzCore.ProfilerBootstrap
if not Bootstrap or not Bootstrap.IsEnabled() then return nil end

require "PsychopatzCore/UI/PsychopatzUI"

PsychopatzCore.ProfilerWindow = PsychopatzCore.ProfilerWindow or {}
local Controller = PsychopatzCore.ProfilerWindow
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

local VIEWS = { "Overview", "CPU", "Metrics", "Growth", "Network", "Events", "History" }

local function drawMetric(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(item.name, 10, y + 6, color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawTextRight(item.value, list:getWidth() - 10, y + 6, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
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
            onclick = function(target) target.view = name; target:refreshMetrics(true) end,
            variant = "quiet",
        })
        self.tabButtons[#self.tabButtons + 1] = button
    end
    self.metricList = UI.CreateList(self, { itemHeight = 26, doDrawItem = drawMetric })
    self.resetButton = UI.CreateButton(self, { title = getText("UI_PsychopatzProfiler_Reset"), target = self, onclick = self.onReset })
    self.exportButton = UI.CreateButton(self, { title = getText("UI_PsychopatzProfiler_Export"), target = self, onclick = self.onExport })
    self.closeButton = UI.CreateButton(self, { title = "Close", target = self, onclick = self.close, variant = "quiet" })
    self:requestResponsiveLayout(true)
    self:refreshMetrics(true)
end

function PsychopatzProfilerWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 82, bottom = 48 })
    Layout.Flow(self.tabButtons, { x = rect.x, y = rect.y - 34, width = rect.width }, { scale = self.uiScale })
    Layout.SetBounds(self.metricList, rect.x, rect.y, rect.width, rect.height)
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

function PsychopatzProfilerWindow:refreshMetrics(force)
    local now = getTimeInMillis and getTimeInMillis() or 0
    if not force and now - (self.lastRefreshAt or 0) < 1000 then return end
    self.lastRefreshAt = now
    local profiler = PsychopatzCore.Profiler
    if not profiler or not profiler.IsRunning() then self:close(); return end
    self.metricList:clear()
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
    PsychopatzCore.Profiler.ResetPeaks()
    PsychopatzCore.Profiler.ResetHistories()
    PsychopatzCore.Profiler.ResetWarnings()
    self:refreshMetrics(true)
end

function PsychopatzProfilerWindow:onExport()
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
