require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISPanel"
require "ISUI/ISTickBox"
require "ISSliderPanel"
require "PsychopatzCore/UI/PsychopatzWindow"

PsychopatzCore.InGameSettings = PsychopatzCore.InGameSettings or {}

local Registry = PsychopatzCore.InGameSettings
local UI = PsychopatzCore.UI
local Layout = UI.Layout

Registry.definitions = Registry.definitions or {}
Registry.instances = Registry.instances or {}

local function findControl(definition, controlID)
    for index = 1, #(definition.controls or {}) do
        if tostring(definition.controls[index].id) == tostring(controlID) then
            return definition.controls[index], index
        end
    end
    return nil
end

function Registry.Register(definition)
    if type(definition) ~= "table" or not definition.id then return false end
    definition.id = tostring(definition.id)
    definition.title = tostring(definition.title or (definition.id .. " Settings"))
    definition.controls = definition.controls or {}
    Registry.definitions[definition.id] = definition
    return definition
end

function Registry.RegisterControl(settingsID, control)
    local definition = Registry.definitions[tostring(settingsID or "")]
    if not definition or type(control) ~= "table" or not control.id then return false end
    local existing, index = findControl(definition, control.id)
    if existing then definition.controls[index] = control else definition.controls[#definition.controls + 1] = control end
    return true
end

PsychopatzSettingsWindow = PsychopatzWindow:derive("PsychopatzSettingsWindow")
Registry.Window = PsychopatzSettingsWindow

local function readValue(window, control)
    if control.get then return control.get(window, control) end
    if window.definition.store and control.key then return window.definition.store:Get(control.key, control.default) end
    return control.default
end

local function writeValue(window, control, value)
    if control.set then
        control.set(value, window, control)
    elseif window.definition.store and control.key then
        window.definition.store:Set(control.key, value, true)
    end
    if control.onChange then control.onChange(value, window, control) end
end

function PsychopatzSettingsWindow:initialise()
    PsychopatzWindow.initialise(self)
end

local function createBoolean(window, panel, definition, index)
    local tick = ISTickBox:new(0, 0, 20, 24, "", window, function(_, _, selected)
        writeValue(window, definition, selected == true)
    end)
    tick:initialise()
    tick:addOption(tostring(definition.label or definition.id), 1)
    tick:setSelected(1, readValue(window, definition) == true)
    panel:addChild(tick)
    return { kind = "boolean", control = tick, height = 30 }
end

local function createSlider(window, panel, definition)
    local label = ISLabel:new(0, 0, 20, tostring(definition.label or definition.id), 1, 1, 1, 1, UIFont.Small, true)
    panel:addChild(label)
    local valueLabel = ISLabel:new(0, 0, 20, "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    panel:addChild(valueLabel)
    local slider = ISSliderPanel:new(0, 0, 160, 20, window, function(_, value)
        local step = tonumber(definition.step) or 1
        local snapped = math.floor((value / step) + 0.5) * step
        writeValue(window, definition, snapped)
        valueLabel:setName(definition.format and definition.format(snapped) or tostring(snapped))
    end)
    slider:initialise()
    slider:setValues(tonumber(definition.min) or 0, tonumber(definition.max) or 100,
        tonumber(definition.step) or 1, tonumber(definition.pageStep) or tonumber(definition.step) or 1)
    slider.currentValue = tonumber(readValue(window, definition)) or tonumber(definition.min) or 0
    valueLabel:setName(definition.format and definition.format(slider.currentValue) or tostring(slider.currentValue))
    panel:addChild(slider)
    return { kind = "slider", label = label, valueLabel = valueLabel, control = slider, height = 34 }
end

local function createAction(window, panel, definition)
    local button = UI.CreateButton(panel, {
        id = definition.id,
        title = tostring(definition.label or definition.id),
        target = window,
        onclick = function()
            if definition.action then definition.action(window, definition) end
        end,
        variant = definition.variant or "default",
    })
    return { kind = "action", control = button, height = 36 }
end

function PsychopatzSettingsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.panel = UI.CreatePanel(self)
    self.rows = {}
    for index = 1, #(self.definition.controls or {}) do
        local definition = self.definition.controls[index]
        local row
        if definition.type == "slider" then
            row = createSlider(self, self.panel, definition)
        elseif definition.type == "action" then
            row = createAction(self, self.panel, definition)
        elseif definition.type == "custom" and definition.create then
            row = definition.create(self, self.panel, definition) or { kind = "custom", height = 36 }
        else
            row = createBoolean(self, self.panel, definition, index)
        end
        row.definition = definition
        self.rows[#self.rows + 1] = row
    end
    self:requestResponsiveLayout(true)
end

function PsychopatzSettingsWindow:onResponsiveLayout()
    if not self.panel then return end
    local rect = self:getContentRect({ top = 34, bottom = 12 })
    Layout.SetBounds(self.panel, rect.x, rect.y, rect.width, rect.height)
    local y = 14
    for index = 1, #self.rows do
        local row = self.rows[index]
        if row.kind == "slider" then
            row.label:setX(12)
            row.label:setY(y + 3)
            Layout.SetBounds(row.control, math.max(140, math.floor(rect.width * 0.42)), y,
                math.max(100, math.floor(rect.width * 0.38)), 20)
            row.valueLabel:setX(rect.width - 66)
            row.valueLabel:setY(y + 3)
        elseif row.kind == "action" then
            Layout.SetBounds(row.control, 12, y, math.min(260, rect.width - 24), 28)
        elseif row.kind == "boolean" then
            Layout.SetBounds(row.control, 12, y, rect.width - 24, 24)
        elseif row.definition.layout then
            row.definition.layout(self, row, { x = 12, y = y, width = rect.width - 24, height = row.height })
        end
        y = y + row.height
    end
end

function PsychopatzSettingsWindow:new(x, y, width, height, options)
    local o = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(o, self)
    self.__index = self
    o.definition = options.definition
    return o
end

-- Settings windows stay registered while hidden so they can be reopened without
-- reconstructing every control. Explicit removal still uses the shared base path.
function PsychopatzSettingsWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
end

function Registry.Open(settingsID)
    settingsID = tostring(settingsID or "")
    local definition = Registry.definitions[settingsID]
    if not definition then return nil end
    local window = Registry.instances[settingsID]
    local created = false
    if not window then
        local windowOptions = definition.window or {}
        windowOptions.title = definition.title
        windowOptions.definition = definition
        windowOptions.persistenceNamespace = windowOptions.persistenceNamespace or "Settings"
        windowOptions.persistenceKey = windowOptions.persistenceKey or settingsID
        windowOptions.responsiveSpec = windowOptions.responsiveSpec or {
            width = 560, height = 460, minWidth = 420, minHeight = 300, maxWidth = 800, maxHeight = 760,
        }
        window = UI.NewWindow(PsychopatzSettingsWindow, windowOptions)
        window:initialise()
        window:instantiate()
        Registry.instances[settingsID] = window
        created = true
    end
    if created then window:addToUIManager() end
    window:setVisible(true)
    window:bringToTop()
    return window
end

function Registry.Toggle(settingsID)
    local window = Registry.instances[tostring(settingsID or "")]
    if window and window:getIsVisible() then
        window:close()
        return nil
    end
    return Registry.Open(settingsID)
end

return Registry
