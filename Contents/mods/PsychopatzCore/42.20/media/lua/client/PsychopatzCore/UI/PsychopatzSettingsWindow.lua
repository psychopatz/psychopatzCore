require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISPanel"
require "ISUI/ISTickBox"
require "PsychopatzCore/UI/PsychopatzWindow"
require "PsychopatzCore/UI/Components/PsychopatzFormRow"
require "PsychopatzCore/UI/Components/PsychopatzSlider"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"

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

local function createGroupedBoolean(window, panel, definition)
    local rowPanel = ISPanel:new(0, 0, 1, 1)
    rowPanel:initialise()
    rowPanel:instantiate()
    rowPanel:noBackground()
    panel:addChild(rowPanel)

    local tick = ISTickBox:new(0, 0, 20, 24, "", window, function(_, _, selected)
        writeValue(window, definition, selected == true)
    end)
    tick:initialise()
    tick:addOption(tostring(definition.label or definition.id), 1)
    tick:setSelected(1, readValue(window, definition) == true)
    rowPanel:addChild(tick)

    local descriptionLabel
    local description = tostring(definition.description or "")
    if description ~= "" then
        descriptionLabel = ISLabel:new(0, 0, 18, description,
            1, 1, 1, 1, UIFont.Small, false)
        descriptionLabel:initialise()
        descriptionLabel:instantiate()
        if UI.SetLabelTheme then UI.SetLabelTheme(descriptionLabel, "textMuted") end
        rowPanel:addChild(descriptionLabel)
    end

    return {
        kind = "boolean",
        control = tick,
        row = rowPanel,
        root = rowPanel,
        descriptionLabel = descriptionLabel,
        height = descriptionLabel and 48 or 30,
    }
end

local function createBoolean(window, panel, definition, index)
    if window.scrollableSections then
        return createGroupedBoolean(window, panel, definition)
    end
    local tick = ISTickBox:new(0, 0, 20, 24, "", window, function(_, _, selected)
        writeValue(window, definition, selected == true)
    end)
    tick:initialise()
    tick:addOption(tostring(definition.label or definition.id), 1)
    tick:setSelected(1, readValue(window, definition) == true)
    panel:addChild(tick)
    return { kind = "boolean", control = tick, root = tick, height = 30 }
end

local function createSlider(window, panel, definition)
    local row
    row = UI.CreateFormRow(panel, {
        id = "settings-row:" .. tostring(definition.id),
        label = definition.label or definition.id,
        valueLabel = true,
        valueText = "",
        labelWidth = 120,
        valueWidth = 66,
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = definition.id,
                target = window,
                min = tonumber(definition.min) or 0,
                max = tonumber(definition.max) or 100,
                step = tonumber(definition.step) or 1,
                value = tonumber(readValue(window, definition))
                    or tonumber(definition.min) or 0,
                onChange = function(_, value)
                    writeValue(window, definition, value)
                    row:setValueText(definition.format
                        and definition.format(value) or tostring(value))
                end,
            })
        end,
    })
    row.height = 34
    row:setValueText(definition.format
        and definition.format(row.control:getValue())
        or tostring(row.control:getValue()))
    return {
        kind = "slider", row = row, root = row, label = row.label,
        valueLabel = row.valueLabel, control = row.control, height = 34,
    }
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
    return { kind = "action", control = button, root = button, height = 36 }
end

local function rowRoot(row)
    return row and (row.root or row.row or row.control or row.label) or nil
end

local function setRowVisible(row, visible)
    local root = rowRoot(row)
    if root and root.setVisible then root:setVisible(visible == true) end
end

local function sectionName(definition)
    return tostring(definition.section or definition.category or "General")
end

local function layoutRow(window, row, x, y, width, absolute)
    local scale = window.uiScale or Layout.Scale()
    if row.kind == "slider" then
        row.row:place(x, y, math.max(1, width), row.height, {
            scale = scale,
            labelWidth = 120,
            valueWidth = 66,
            gap = 8,
            controlHeight = 24,
        })
    elseif row.kind == "boolean" and window.scrollableSections then
        Layout.SetBounds(row.row, x, y, math.max(1, width), row.height)
        Layout.SetBounds(row.control, Layout.Pixels(12, scale), 0,
            math.max(1, width - Layout.Pixels(24, scale)),
            Layout.Pixels(24, scale))
        if row.descriptionLabel then
            local description = tostring(row.definition.description or "")
            local available = math.max(40, width - Layout.Pixels(46, scale))
            UI.SetLabelText(row.descriptionLabel,
                Layout.Ellipsize(description, UIFont.Small, available))
            Layout.SetBounds(row.descriptionLabel, Layout.Pixels(34, scale),
                Layout.Pixels(25, scale), available, Layout.Pixels(18, scale))
        end
    elseif row.kind == "boolean" then
        Layout.SetBounds(row.control, x, y, math.max(1, width),
            Layout.Pixels(24, scale))
    elseif row.kind == "action" then
        Layout.SetBounds(row.control, x, y,
            math.min(Layout.Pixels(260, scale), math.max(1, width)),
            Layout.Pixels(28, scale))
    elseif row.definition.layout then
        row.definition.layout(window, row, {
            x = x, y = y, width = width, height = row.height,
            absolute = absolute == true,
        })
    end
end

function PsychopatzSettingsWindow:updateSectionHeader(section)
    if not section or not section.header then return end
    local indicator = section.expanded and "[-] " or "[+] "
    local count = tostring(#(section.rows or {}))
    section.header:setTitle(indicator .. tostring(section.label) .. " (" .. count .. ")")
end

function PsychopatzSettingsWindow:toggleSection(key)
    local section = self.sectionsByKey and self.sectionsByKey[tostring(key or "")]
    if not section then return end
    section.expanded = not section.expanded
    self:updateSectionHeader(section)
    for _, row in ipairs(section.rows or {}) do
        setRowVisible(row, section.expanded)
    end
    self:requestResponsiveLayout(true)
end

function PsychopatzSettingsWindow:layoutSectioned()
    local rect = self:getContentRect({ top = 34, bottom = 12 })
    local scale = self.uiScale or Layout.Scale()
    local gap = Layout.Pixels(8, scale)
    local contentPadding = Layout.Pixels(10, scale)
    local headerHeight = Layout.Pixels(30, scale)
    local rowGap = Layout.Pixels(5, scale)
    local topRows = {}
    local footerRows = {}

    for _, row in ipairs(self.rows or {}) do
        local sticky = row.definition and row.definition.sticky
        if sticky == "top" or row.definition.id == "status" then
            topRows[#topRows + 1] = row
        elseif sticky == "footer" or row.kind == "action" then
            footerRows[#footerRows + 1] = row
        end
    end

    local topHeight = 0
    for index, row in ipairs(topRows) do
        topHeight = topHeight + row.height
        if index < #topRows then topHeight = topHeight + gap end
    end

    local footerHeight = 0
    local buttons = {}
    for _, row in ipairs(footerRows) do
        if row.control then buttons[#buttons + 1] = row.control end
    end
    if #buttons > 0 then
        local flow = Layout.Flow(buttons, {
            x = rect.x, y = rect.y, width = rect.width,
        }, { scale = scale, height = 28, minWidth = 110 })
        footerHeight = flow.height
    end

    local footerGap = #buttons > 0 and gap or 0
    local scrollY = rect.y + topHeight + (#topRows > 0 and gap or 0)
    local scrollBottom = rect.y + rect.height - footerHeight - footerGap
    local scrollHeight = math.max(Layout.Pixels(120, scale), scrollBottom - scrollY)
    Layout.SetBounds(self.panel, rect.x, scrollY, rect.width, scrollHeight)

    local y = rect.y
    for _, row in ipairs(topRows) do
        layoutRow(self, row, rect.x, y, rect.width, true)
        y = y + row.height + gap
    end

    if #buttons > 0 then
        Layout.Flow(buttons, {
            x = rect.x, y = rect.y + rect.height - footerHeight,
            width = rect.width,
        }, { scale = scale, height = 28, minWidth = 110 })
    end

    local contentWidth = math.max(1, rect.width - contentPadding * 2)
    y = contentPadding
    for _, section in ipairs(self.sections or {}) do
        self:updateSectionHeader(section)
        setRowVisible(section.header, true)
        Layout.SetBounds(section.header, contentPadding, y,
            contentWidth, headerHeight)
        y = y + headerHeight + rowGap
        for _, row in ipairs(section.rows or {}) do
            local visible = section.expanded == true
            setRowVisible(row, visible)
            if visible then
                layoutRow(self, row, contentPadding, y, contentWidth, false)
                y = y + row.height + rowGap
            end
        end
    end
    self.panel:setContentHeight(y + contentPadding)
end

function PsychopatzSettingsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.panel = self.scrollableSections
        and UI.CreateScrollPanel(self) or UI.CreatePanel(self)
    self.rows = {}
    self.sections = {}
    self.sectionsByKey = {}
    for index = 1, #(self.definition.controls or {}) do
        local definition = self.definition.controls[index]
        local sticky = definition.sticky
        if not sticky and definition.id == "status" then sticky = "top" end
        if not sticky and definition.type == "action" then sticky = "footer" end
        local host = self.panel
        local section
        if self.scrollableSections and not sticky then
            local key = sectionName(definition)
            section = self.sectionsByKey[key]
            if not section then
                section = {
                    key = key,
                    label = tostring(definition.sectionLabel or key),
                    expanded = self.sectionExpandedByDefault,
                    rows = {},
                }
                section.header = UI.CreateButton(self.panel, {
                    id = "section:" .. key,
                    title = "",
                    target = self,
                    onclick = function(target)
                        target:toggleSection(key)
                    end,
                    variant = "quiet",
                })
                self.sectionsByKey[key] = section
                self.sections[#self.sections + 1] = section
            end
        elseif self.scrollableSections then
            host = self
        end
        local row
        if definition.type == "slider" then
            row = createSlider(self, host, definition)
        elseif definition.type == "action" then
            row = createAction(self, host, definition)
        elseif definition.type == "custom" and definition.create then
            row = definition.create(self, host, definition) or { kind = "custom", height = 36 }
        else
            row = createBoolean(self, host, definition, index)
        end
        row.definition = definition
        row.root = row.root or rowRoot(row)
        row.sticky = sticky
        if definition.id == "status" then self.statusRow = row end
        self.rows[#self.rows + 1] = row
        if section then section.rows[#section.rows + 1] = row end
    end
    for _, section in ipairs(self.sections) do
        self:updateSectionHeader(section)
    end
    self:requestResponsiveLayout(true)
end

function PsychopatzSettingsWindow:onResponsiveLayout()
    if not self.panel then return end
    if self.scrollableSections then
        self:layoutSectioned()
        return
    end
    local rect = self:getContentRect({ top = 34, bottom = 12 })
    Layout.SetBounds(self.panel, rect.x, rect.y, rect.width, rect.height)
    local y = 14
    for index = 1, #self.rows do
        local row = self.rows[index]
        layoutRow(self, row, 12, y, rect.width - 24, false)
        y = y + row.height
    end
end

function PsychopatzSettingsWindow:new(x, y, width, height, options)
    local o = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(o, self)
    self.__index = self
    o.definition = options.definition
    o.scrollableSections = options.scrollableSections == true
    o.sectionExpandedByDefault = options.sectionExpandedByDefault ~= false
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
