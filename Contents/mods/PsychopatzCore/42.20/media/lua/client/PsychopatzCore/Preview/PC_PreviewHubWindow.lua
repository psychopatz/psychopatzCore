-- Generic preview dashboard.
--
-- Providers supply snapshot refresh and presentation callbacks; this window
-- owns only selection, explicit refresh, settings filtering, and the shared
-- overlay toggle. It is loaded by the debug action, never by the renderer.
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/PsychopatzWindow"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Preview = PsychopatzCore.Preview or {}

local Preview = require "PsychopatzCore/Preview/PC_Preview"
local Presentation = require "PsychopatzCore/Preview/PC_PreviewPresentation"
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Translation = PsychopatzCore.Translation

local function tr(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    return ok and value or nil
end

local function providerText(provider, key, fallback)
    fallback = fallback or key
    local value = safeCall(provider and provider.translate, key, fallback)
    if value and tostring(value) ~= "" and tostring(value) ~= tostring(key) then
        return tostring(value)
    end
    return tr(key, fallback)
end

local function providerTitle(provider)
    if not provider then return tr("UI_PsychopatzPreview_NoProvider", "No provider") end
    if provider.titleKey then
        local translatedTitle = safeCall(provider.translate,
            provider.titleKey, provider.title)
        if translatedTitle and tostring(translatedTitle) ~= "" then
            return tostring(translatedTitle)
        end
        local resolved = tr(provider.titleKey, provider.title)
        if resolved and tostring(resolved) ~= "" then
            return tostring(resolved)
        end
    end
    return tostring(provider.title or provider.id or "provider")
end

local function providerDescription(provider)
    if provider and provider.descriptionKey then
        return tostring(safeCall(provider.translate, provider.descriptionKey,
            provider.description) or tr(provider.descriptionKey,
            provider.description))
    end
    return tostring(provider and provider.description or "")
end

local function definitionValue(definition, settings)
    local value = safeCall(definition and definition.get)
    if value == nil and definition then value = settings[definition.id] end
    return value == true
end

local function selectedItem(list)
    local entry = list and list.getItem and list:getItem() or nil
    return entry and entry.item or nil
end

local function drawProviderItem(list, y, entry, alternate)
    local item = entry.item or {}
    local selected = list.selected == entry.index
    local height = list.itemheight
    UI.DrawListSelection(list, y, height, selected, alternate)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    local title = Layout.Ellipsize(item.title or item.id or "provider",
        UIFont.Medium, math.max(40, list:getWidth() - 18))
    local description = Layout.Ellipsize(item.description or "", UIFont.Small,
        math.max(40, list:getWidth() - 18))
    list:drawText(title, 10, y + 6, text.r, text.g, text.b, text.a,
        UIFont.Medium)
    list:drawText(description, 10, y + 28, muted.r, muted.g, muted.b,
        muted.a, UIFont.Small)
    return y + height
end

local function drawObjectItem(list, y, entry, alternate)
    local item = entry.item or {}
    local selected = list.selected == entry.index
    local height = list.itemheight
    UI.DrawListSelection(list, y, height, selected, alternate)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    local label = Layout.Ellipsize(item.label or tr(
        "UI_PsychopatzPreview_WorldObject", "world object"), UIFont.Small,
        math.max(40, list:getWidth() - 18))
    local detail = Layout.Ellipsize(item.detail or "", UIFont.Small,
        math.max(40, list:getWidth() - 18))
    list:drawText(label, 10, y + 5, text.r, text.g, text.b, text.a,
        UIFont.Small)
    list:drawText(detail, 10, y + 25, muted.r, muted.g, muted.b, muted.a,
        UIFont.Small)
    return y + height
end

local function providerRows()
    local rows = {}
    for index, provider in ipairs(Preview.ListProviders()) do
        rows[#rows + 1] = {
            id = provider.id,
            title = providerTitle(provider),
            description = providerDescription(provider),
            provider = provider,
            order = index,
        }
    end
    return rows
end

ISPsychopatzPreviewHubWindow = PsychopatzWindow:derive(
    "ISPsychopatzPreviewHubWindow")

function ISPsychopatzPreviewHubWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPsychopatzPreviewHubWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.topControls = {}
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = tr("UI_PsychopatzPreview_Refresh", "REFRESH SNAPSHOT"),
        target = self,
        onclick = ISPsychopatzPreviewHubWindow.onAction,
        variant = "quiet",
    })
    self.overlayButton = UI.CreateButton(self, {
        id = "overlay",
        title = tr("UI_PsychopatzPreview_EnableOverlay", "ENABLE OVERLAY"),
        target = self,
        onclick = ISPsychopatzPreviewHubWindow.onAction,
        variant = "selected",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PsychopatzPreview_Close", "CLOSE"),
        target = self,
        onclick = ISPsychopatzPreviewHubWindow.onAction,
        variant = "quiet",
    })
    self.topControls = { self.refreshButton, self.overlayButton,
        self.closeButton }

    self.providerList = UI.CreateList(self, {
        itemHeight = Layout.Pixels(48, self.uiScale),
        doDrawItem = drawProviderItem,
    })
    self.providerList.onMouseDown = function(list, x, y)
        return self:onProviderMouseDown(list, x, y)
    end
    self.objectList = UI.CreateList(self, {
        itemHeight = Layout.Pixels(43, self.uiScale),
        doDrawItem = drawObjectItem,
    })
    self.objectList.onMouseDown = function(list, x, y)
        return self:onObjectMouseDown(list, x, y)
    end
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = Layout.Pixels(150, self.uiScale),
        valueRightPadding = 8,
        labelWidthRatio = 0.38,
    })
    self.campPreview = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = Layout.Pixels(150, self.uiScale),
        valueRightPadding = 8,
        labelWidthRatio = 0.38,
    })
    self.optionControls = {}
    self.activeOptionControls = {}
    self.providers = {}
    self.selectedProviderID = nil
    self.selectedObjectID = nil
    self.snapshot = nil
    self.refreshError = nil
    self:refreshProviders()
    self:requestResponsiveLayout(true)
end

function ISPsychopatzPreviewHubWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local top = Layout.Flow(self.topControls, {
        x = rect.x, y = rect.y, width = rect.width,
    }, { scale = self.uiScale, minWidth = 120 })
    local settingsY = top.bottom + Layout.Pixels(8, self.uiScale)
    local settings = Layout.Grid(self.activeOptionControls, {
        x = rect.x, y = settingsY, width = rect.width,
    }, {
        scale = self.uiScale,
        columns = 3,
        height = 24,
        gap = 8,
        rowGap = 3,
    })
    local mainY = settings.bottom + Layout.Pixels(22, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    local height = math.max(Layout.Pixels(160, self.uiScale),
        rect.y + rect.height - mainY)
    local providerWidth = math.floor(rect.width * 0.23)
    local objectWidth = math.floor(rect.width * 0.30)
    local rightWidth = rect.width - providerWidth - objectWidth - gap * 2
    if rightWidth < Layout.Pixels(190, self.uiScale) then
        providerWidth = math.max(Layout.Pixels(150, self.uiScale),
            providerWidth - Layout.Pixels(20, self.uiScale))
        objectWidth = math.max(Layout.Pixels(210, self.uiScale),
            objectWidth - Layout.Pixels(20, self.uiScale))
        rightWidth = rect.width - providerWidth - objectWidth - gap * 2
    end
    local previewHeight = math.min(Layout.Pixels(170, self.uiScale),
        math.max(Layout.Pixels(90, self.uiScale), math.floor(height * 0.32)))
    local detailHeight = math.max(Layout.Pixels(70, self.uiScale),
        height - previewHeight - gap)
    self.layout = {
        providers = { x = rect.x, y = mainY, width = providerWidth,
            height = height },
        objects = { x = rect.x + providerWidth + gap, y = mainY,
            width = objectWidth, height = height },
        details = { x = rect.x + providerWidth + objectWidth + gap * 2,
            y = mainY, width = rightWidth, height = detailHeight },
        campPreview = { x = rect.x + providerWidth + objectWidth + gap * 2,
            y = mainY + detailHeight + gap, width = rightWidth,
            height = previewHeight },
    }
    Layout.SetBounds(self.providerList, self.layout.providers.x,
        self.layout.providers.y, self.layout.providers.width,
        self.layout.providers.height)
    Layout.SetBounds(self.objectList, self.layout.objects.x,
        self.layout.objects.y, self.layout.objects.width,
        self.layout.objects.height)
    Layout.SetBounds(self.details, self.layout.details.x,
        self.layout.details.y, self.layout.details.width,
        self.layout.details.height)
    Layout.SetBounds(self.campPreview, self.layout.campPreview.x,
        self.layout.campPreview.y, self.layout.campPreview.width,
        self.layout.campPreview.height)
end

function ISPsychopatzPreviewHubWindow:provider()
    return self.selectedProviderID
        and Preview.GetProvider(self.selectedProviderID) or nil
end

function ISPsychopatzPreviewHubWindow:selectedObject()
    local row = selectedItem(self.objectList)
    return row and row.object or nil
end

function ISPsychopatzPreviewHubWindow:refreshProviders()
    local previous = self.selectedProviderID
    self.providers = providerRows()
    self.providerList:clear()
    local selectedIndex
    for index, row in ipairs(self.providers) do
        self.providerList:addItem(row.title, row)
        if previous and row.id == previous then selectedIndex = index end
    end
    if not selectedIndex and #self.providers > 0 then selectedIndex = 1 end
    self.providerList.selected = selectedIndex or 0
    local row = self.providerList:getItem()
    self:selectProvider(row and row.item and row.item.id or nil)
end

function ISPsychopatzPreviewHubWindow:refreshOptionControls()
    for _, control in pairs(self.optionControls) do
        if control and control.setVisible then control:setVisible(false) end
    end
    self.activeOptionControls = {}
    local provider = self:provider()
    if not provider then
        self:requestResponsiveLayout(true)
        return
    end
    local settings = safeCall(provider.getSettings) or {}
    local definitions = Presentation.OptionDefinitions(provider, settings)
    for index = 1, #definitions do
        local definition = definitions[index]
        local id = tostring(definition.id or "option_" .. tostring(index))
        local key = tostring(provider.id) .. ":" .. id
        local control = self.optionControls[key]
        if not control then
            local capturedProviderID = provider.id
            local capturedDefinition = definition
            control = UI.CreateCheckbox(self, {
                id = key,
                label = providerText(provider, capturedDefinition.label,
                    capturedDefinition.label or id),
                value = definitionValue(capturedDefinition, settings),
                target = self,
                onChange = function(owner, value)
                    local applied = false
                    if type(capturedDefinition.set) == "function" then
                        local ok = pcall(capturedDefinition.set, value)
                        applied = ok
                    end
                    if not applied then
                        local current = safeCall(provider.getSettings) or {}
                        current[capturedDefinition.id] = value == true
                        Preview.SetSettings(capturedProviderID, current,
                            "ui")
                    end
                    if owner then
                        owner:refreshOptionControls()
                        owner:refreshPresentation()
                    end
                end,
            })
            self.optionControls[key] = control
        end
        if control.setChecked then
            control:setChecked(definitionValue(definition, settings))
        end
        if control.setVisible then control:setVisible(true) end
        self.activeOptionControls[#self.activeOptionControls + 1] = control
    end
    self:requestResponsiveLayout(true)
end

function ISPsychopatzPreviewHubWindow:refreshDetails()
    self.details:clear()
    local provider = self:provider()
    for index, row in ipairs(Presentation.DetailRows(provider,
        self:selectedObject(), safeCall(provider and provider.getSettings) or {})) do
        self.details:addItem("detail_" .. tostring(index), row)
    end
end

function ISPsychopatzPreviewHubWindow:refreshCampPreview()
    self.campPreview:clear()
    local provider = self:provider()
    for index, row in ipairs(Presentation.CampPreviewRows(provider,
        self.snapshot)) do
        self.campPreview:addItem("camp_" .. tostring(index), row)
    end
end

function ISPsychopatzPreviewHubWindow:refreshPresentation()
    local previous = selectedItem(self.objectList)
    local previousID = previous and previous.id or self.selectedObjectID
    local provider = self:provider()
    local settings = safeCall(provider and provider.getSettings) or {}
    local rows = Presentation.ObjectRows(provider, self.snapshot, settings)
    self.objectList:clear()
    local selectedIndex
    for index = 1, #rows do
        self.objectList:addItem(rows[index].label, rows[index])
        if previousID and tostring(rows[index].id) == tostring(previousID) then
            selectedIndex = index
        end
    end
    if not selectedIndex and #rows > 0 then selectedIndex = 1 end
    self.objectList.selected = selectedIndex or 0
    local selected = selectedItem(self.objectList)
    self.selectedObjectID = selected and selected.id or previousID
    self:refreshDetails()
    self:refreshCampPreview()
    self:syncControls()
end

function ISPsychopatzPreviewHubWindow:selectProvider(providerID)
    providerID = providerID and tostring(providerID) or nil
    if providerID and not Preview.GetProvider(providerID) then providerID = nil end
    self.selectedProviderID = providerID
    self.selectedObjectID = nil
    self.refreshError = nil
    self.snapshot = providerID and Preview.GetSnapshot(providerID) or nil
    self:refreshOptionControls()
    self:refreshPresentation()
end

function ISPsychopatzPreviewHubWindow:refreshSnapshot()
    local provider = self:provider()
    if not provider then return end
    local snapshot, reason = Preview.Refresh(provider.id, {
        source = "preview_hub_refresh",
    })
    self.refreshError = snapshot and nil or tostring(reason or "refresh failed")
    self.snapshot = snapshot or Preview.GetSnapshot(provider.id)
    self:refreshPresentation()
end

function ISPsychopatzPreviewHubWindow:syncControls()
    local provider = self:provider()
    if self.refreshButton then
        self.refreshButton:setEnable(provider
            and type(provider.refreshSnapshot) == "function" or false)
    end
    if self.overlayButton then
        local enabled = provider and Preview.IsEnabled(provider.id) or false
        self.overlayButton:setTitle(enabled
            and tr("UI_PsychopatzPreview_DisableOverlay", "DISABLE OVERLAY")
            or tr("UI_PsychopatzPreview_EnableOverlay", "ENABLE OVERLAY"))
        UI.SetButtonVariant(self.overlayButton,
            enabled and "danger" or "selected")
        self.overlayButton:setEnable(provider ~= nil)
    end
end

function ISPsychopatzPreviewHubWindow:onProviderMouseDown(list, x, y)
    local result = ISScrollingListBox.onMouseDown(list, x, y)
    local row = list:getItem()
    local item = row and row.item or nil
    if item and item.id then self:selectProvider(item.id) end
    return result
end

function ISPsychopatzPreviewHubWindow:onObjectMouseDown(list, x, y)
    local result = ISScrollingListBox.onMouseDown(list, x, y)
    local row = list:getItem()
    local item = row and row.item or nil
    self.selectedObjectID = item and item.id or nil
    self:refreshDetails()
    return result
end

function ISPsychopatzPreviewHubWindow:onAction(button)
    local id = button and button.internal or ""
    if id == "refresh" then
        self:refreshSnapshot()
    elseif id == "overlay" then
        local provider = self:provider()
        if provider then Preview.Toggle(provider.id) end
        self:syncControls()
    elseif id == "close" then
        self:close()
    end
end

function ISPsychopatzPreviewHubWindow:prerender()
    local selected = selectedItem(self.objectList)
    local selectedID = selected and selected.id or nil
    if selectedID ~= self.selectedObjectID then
        self.selectedObjectID = selectedID
        self:refreshDetails()
    end
    PsychopatzWindow.prerender(self)
end

function ISPsychopatzPreviewHubWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local provider = self:provider()
    local summary = Presentation.Summary(provider, self.snapshot)
    local suffix = tostring(summary.status or "UNAVAILABLE")
        .. " | " .. tostring(summary.objects or 0) .. " "
        .. tr("UI_PsychopatzPreview_ObjectsWord", "objects")
    if summary.zones ~= nil then suffix = suffix .. " | "
        .. tostring(summary.zones) .. " "
        .. tr("UI_PsychopatzPreview_ZonesWord", "zones") end
    if self.refreshError then suffix = suffix .. " | " .. self.refreshError end
    UI.DrawSectionTitle(self,
        tr("UI_PsychopatzPreview_Providers", "PREVIEW PROVIDERS"),
        self.layout.providers.x, self.layout.providers.y
            - Layout.Pixels(20, self.uiScale), self.layout.providers.width,
        providerTitle(provider))
    UI.DrawSectionTitle(self,
        tr("UI_PsychopatzPreview_Objects", "OBSERVED OBJECTS"),
        self.layout.objects.x, self.layout.objects.y
            - Layout.Pixels(20, self.uiScale), self.layout.objects.width,
        suffix)
    UI.DrawSectionTitle(self,
        tr("UI_PsychopatzPreview_Details", "OBJECT DETAILS"),
        self.layout.details.x, self.layout.details.y
            - Layout.Pixels(20, self.uiScale), self.layout.details.width,
        "")
    UI.DrawSectionTitle(self,
        tr("UI_PsychopatzPreview_CampPreview", "CAMP PREVIEW"),
        self.layout.campPreview.x, self.layout.campPreview.y
            - Layout.Pixels(20, self.uiScale), self.layout.campPreview.width,
        "")
end

function ISPsychopatzPreviewHubWindow:close()
    local provider = self:provider()
    if provider and not Preview.IsEnabled(provider.id) then
        Preview.Clear(provider.id)
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if ISPsychopatzPreviewHubWindow.instance == self then
        ISPsychopatzPreviewHubWindow.instance = nil
    end
end

function ISPsychopatzPreviewHubWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function ISPsychopatzPreviewHubWindow.Open(providerID)
    local window = ISPsychopatzPreviewHubWindow.instance
    if window then
        window:setVisible(true)
        window:bringToTop()
        window:refreshProviders()
        if providerID then window:selectProvider(providerID) end
        return window
    end
    window = UI.NewWindow(ISPsychopatzPreviewHubWindow, {
        title = tr("UI_PsychopatzPreview_Title", "Psychopatz Preview Hub"),
        resizable = true,
        responsiveSpec = {
            width = 980,
            height = 650,
            minWidth = 720,
            minHeight = 460,
            maxWidth = 1400,
            maxHeight = 900,
        },
        persistenceNamespace = "Preview",
        persistenceKey = "Hub",
    })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    ISPsychopatzPreviewHubWindow.instance = window
    if providerID then window:selectProvider(providerID) end
    return window
end

return ISPsychopatzPreviewHubWindow
