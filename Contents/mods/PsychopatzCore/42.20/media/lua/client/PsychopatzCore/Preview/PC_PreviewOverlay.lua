-- Shared, lazy world-preview renderer.
--
-- There is one native OnPreUIDraw callback for all registered providers, and
-- that callback is installed only while at least one preview session is both
-- enabled and renderable. Providers are never asked to scan from this file.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Preview = PsychopatzCore.Preview or {}

local Preview = PsychopatzCore.Preview
local Registry = Preview.Registry
    or require "PsychopatzCore/Preview/PC_PreviewRegistry"
local Snapshot = Preview.Snapshot
    or require "PsychopatzCore/Preview/PC_PreviewSnapshot"
local Overlay = Preview.Overlay or {}
Preview.Overlay = Overlay

Overlay.VERSION = 1
Overlay.sessions = Overlay.sessions or {}
Overlay.sessionOrder = Overlay.sessionOrder or {}
Overlay.eventsInstalled = Overlay.eventsInstalled == true
Overlay.primitives = nil
Overlay.MAX_RENDER_OBJECTS = 32
Overlay.MAX_RENDER_ZONES = 8
Overlay.MAX_TOOLTIP_LINES = 16

local DEFAULT_COLOR = { r = 0.75, g = 0.85, b = 1.0, a = 0.70 }
local SELECTED_COLOR = { r = 1.0, g = 0.86, b = 0.18, a = 0.96 }

local function text(value, fallback)
    value = tostring(value or "")
    if value == "" then return fallback end
    return value
end

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    return ok and value or nil
end

local function settingsKey(state, settings, revision)
    local provider = state.provider
    local custom = call(provider and provider.settingsKey, settings)
    if custom ~= nil then return tostring(revision or "") .. ":" .. tostring(custom) end
    local key = tostring(revision or "")
    for index = 1, #(provider and provider.layers or {}) do
        local layer = provider.layers[index]
        key = key .. ":" .. tostring(settings[layer.settingKey] == true)
    end
    return key
end

local function settingsFor(state)
    local provider = state.provider
    local revision = call(provider and provider.getSettingsRevision)
    if revision == nil then revision = state.settingsRevision or "static" end
    if state.settings and state.settingsRevision == revision then
        return state.settings, state.settingsKey
    end
    local settings = call(provider and provider.getSettings)
    if type(settings) ~= "table" then settings = state.settings or {} end
    state.settings = settings
    state.settingsRevision = revision
    state.settingsKey = settingsKey(state, settings, revision)
    return state.settings, state.settingsKey
end

local function invalidate(state)
    state.renderPlan = nil
    state.renderPlanSnapshot = nil
    state.renderPlanSettingsKey = nil
    state.hoverKey = nil
    state.hovered = nil
    state.tooltipKey = nil
    state.tooltipLines = nil
    state.tooltipWidth = nil
end

local function ensureSession(providerID)
    providerID = text(providerID, nil)
    local provider = Registry.Get(providerID)
    if not provider then return nil, "provider_not_registered" end
    local state = Overlay.sessions[providerID]
    if not state then
        state = {
            id = providerID,
            provider = provider,
            enabled = false,
            snapshot = nil,
            settings = nil,
            settingsRevision = nil,
            settingsKey = nil,
            renderPlan = nil,
            renderPlanSnapshot = nil,
            renderPlanSettingsKey = nil,
            visibleObjects = {},
            drawer = nil,
        }
        Overlay.sessions[providerID] = state
        Overlay.sessionOrder[#Overlay.sessionOrder + 1] = providerID
    else
        state.provider = provider
    end
    return state
end

function Overlay.RegisterSession(providerID)
    local state, reason = ensureSession(providerID)
    if not state then return false, reason end
    return true, state
end

function Overlay.GetSession(providerID)
    return Overlay.sessions[text(providerID, "")]
end

function Overlay.IsHookInstalled()
    return Overlay.eventsInstalled == true
end

function Overlay.RemoveSession(providerID)
    providerID = text(providerID, nil)
    if not providerID or not Overlay.sessions[providerID] then return false end
    Overlay.sessions[providerID] = nil
    for index = #Overlay.sessionOrder, 1, -1 do
        if Overlay.sessionOrder[index] == providerID then
            table.remove(Overlay.sessionOrder, index)
            break
        end
    end
    Overlay.SyncRenderHook()
    return true
end

local function hasRenderable(state)
    local settings = settingsFor(state)
    return Registry.HasRenderableLayers(state.provider, settings)
end

local function needsHook()
    for index = 1, #Overlay.sessionOrder do
        local state = Overlay.sessions[Overlay.sessionOrder[index]]
        if state and state.enabled and hasRenderable(state) then return true end
    end
    return false
end

function Overlay.Install()
    if Overlay.eventsInstalled then return true end
    if not needsHook() then return true end
    if not Events or not Events.OnPreUIDraw
        or type(Events.OnPreUIDraw.Add) ~= "function"
    then return false end
    local ok = pcall(Events.OnPreUIDraw.Add, Overlay.Render)
    if not ok then return false end
    if Events.OnMainMenuEnter
        and type(Events.OnMainMenuEnter.Add) == "function"
    then
        pcall(Events.OnMainMenuEnter.Add, Overlay.Reset)
    end
    Overlay.eventsInstalled = true
    return true
end

function Overlay.Uninstall()
    if not Overlay.eventsInstalled then return true end
    if not Events or not Events.OnPreUIDraw
        or type(Events.OnPreUIDraw.Remove) ~= "function"
    then return false end
    local ok = pcall(Events.OnPreUIDraw.Remove, Overlay.Render)
    if not ok then return false end
    if Events.OnMainMenuEnter
        and type(Events.OnMainMenuEnter.Remove) == "function"
    then
        pcall(Events.OnMainMenuEnter.Remove, Overlay.Reset)
    end
    Overlay.eventsInstalled = false
    return true
end

function Overlay.SyncRenderHook()
    if needsHook() then return Overlay.Install() end
    return Overlay.Uninstall()
end

function Overlay.SetSettings(providerID, settings, revision)
    local state, reason = ensureSession(providerID)
    if not state then return nil, reason end
    state.settings = type(settings) == "table" and settings or {}
    state.settingsRevision = revision or state.settingsRevision or "manual"
    state.settingsKey = settingsKey(state, state.settings,
        state.settingsRevision)
    invalidate(state)
    Overlay.SyncRenderHook()
    return state.settings
end

function Overlay.SetSnapshot(providerID, value)
    local state, reason = ensureSession(providerID)
    if not state then return nil, reason end
    state.snapshot = Snapshot.Normalize(value, providerID)
    invalidate(state)
    local provider = state.provider
    if provider and type(provider.onSnapshot) == "function" then
        pcall(provider.onSnapshot, state.snapshot)
    end
    return state.snapshot
end

function Overlay.GetSnapshot(providerID)
    local state = Overlay.GetSession(providerID)
    return state and state.snapshot or nil
end

function Overlay.SetEnabled(providerID, enabled)
    local state, reason = ensureSession(providerID)
    if not state then return false, reason end
    state.enabled = enabled == true
    if not state.enabled then
        state.snapshot = nil
        state.visibleObjects = {}
        invalidate(state)
    end
    Overlay.SyncRenderHook()
    return state.enabled
end

function Overlay.IsEnabled(providerID)
    local state = Overlay.GetSession(providerID)
    return state and state.enabled == true or false
end

function Overlay.Clear(providerID)
    local state = Overlay.GetSession(providerID)
    if not state then return false end
    state.snapshot = nil
    state.visibleObjects = {}
    invalidate(state)
    return true
end

function Overlay.HasRenderableLayers(providerID, settings)
    local state = Overlay.GetSession(providerID)
    if not state then return false end
    if type(settings) == "table" then
        return Registry.HasRenderableLayers(state.provider, settings)
    end
    return hasRenderable(state)
end

function Overlay.GetVisibleObjects(providerID)
    local state = Overlay.GetSession(providerID)
    return state and state.visibleObjects or {}
end

local function primitives()
    if Overlay.primitives then return Overlay.primitives end
    local ok, value = pcall(require,
        "PsychopatzCore/Preview/PC_PreviewPrimitives")
    if not ok then return nil end
    Overlay.primitives = value
    return value
end

local function objectTileKey(object)
    return tostring(math.floor(tonumber(object and object.x) or 0)) .. ":"
        .. tostring(math.floor(tonumber(object and object.y) or 0)) .. ":"
        .. tostring(math.floor(tonumber(object and object.z) or 0))
end

local function buildRenderPlan(state, snapshot, settings)
    local provider = state.provider
    local plan = { zones = {}, tiles = {}, objects = {} }
    local maxZones = provider.maxRenderZones or Overlay.MAX_RENDER_ZONES
    local maxObjects = provider.maxRenderObjects
        or Overlay.MAX_RENDER_OBJECTS

    for index = 1, #(snapshot.zones or {}) do
        if #plan.zones >= maxZones then break end
        local zone = snapshot.zones[index]
        if Registry.ZoneVisible(provider, zone, settings) then
            plan.zones[#plan.zones + 1] = zone
        end
    end

    local selectedByTile = {}
    local selectedTileOrder = {}
    for index = 1, #(snapshot.objects or {}) do
        local object = snapshot.objects[index]
        if Registry.ObjectVisible(provider, object, settings) then
            local key = objectTileKey(object)
            local priority = Registry.ObjectPriority(provider, object,
                settings)
            local selected = selectedByTile[key]
            if selected then
                if priority > selected.priority then
                    selected.object = object
                    selected.priority = priority
                    selected.color = Registry.ObjectColor(provider, object,
                        settings)
                end
            elseif #selectedTileOrder < maxObjects then
                selectedByTile[key] = {
                    object = object,
                    priority = priority,
                    color = Registry.ObjectColor(provider, object, settings),
                    x = math.floor(tonumber(object.x) or 0),
                    y = math.floor(tonumber(object.y) or 0),
                    z = math.floor(tonumber(object.z) or 0),
                }
                selectedTileOrder[#selectedTileOrder + 1] = key
            end
        end
    end

    for index = 1, #selectedTileOrder do
        local selected = selectedByTile[selectedTileOrder[index]]
        if selected then
            plan.tiles[#plan.tiles + 1] = {
                x = selected.x,
                y = selected.y,
                z = selected.z,
                color = selected.color or DEFAULT_COLOR,
            }
            plan.objects[#plan.objects + 1] = selected.object
        end
    end
    return plan
end

local function renderPlanFor(state, snapshot, settings, key)
    if state.renderPlan and state.renderPlanSnapshot == snapshot
        and state.renderPlanSettingsKey == key
    then return state.renderPlan end
    state.renderPlan = buildRenderPlan(state, snapshot, settings)
    state.renderPlanSnapshot = snapshot
    state.renderPlanSettingsKey = key
    state.hoverKey = nil
    state.hovered = nil
    state.tooltipKey = nil
    state.tooltipLines = nil
    state.tooltipWidth = nil
    return state.renderPlan
end

local function playerFor()
    if type(getSpecificPlayer) ~= "function" then return nil end
    local ok, player = pcall(getSpecificPlayer, 0)
    return ok and player or nil
end

local function playerNum(player)
    if not player or type(player.getPlayerNum) ~= "function" then return 0 end
    local ok, value = pcall(player.getPlayerNum, player)
    return ok and tonumber(value) or 0
end

local function mousePosition(drawer)
    if type(getMouseX) ~= "function" or type(getMouseY) ~= "function" then
        return nil, nil
    end
    return getMouseX() - (tonumber(drawer.x) or 0),
        getMouseY() - (tonumber(drawer.y) or 0)
end

local function hoverKey(state, index, mouseX, mouseY, plan)
    return tostring(plan) .. ":" .. tostring(index) .. ":"
        .. tostring(mouseX) .. ":" .. tostring(mouseY)
end

local function findHovered(state, drawer, index, objects, mouseX, mouseY, P,
    plan)
    if mouseX == nil or mouseY == nil then return nil end
    local key = hoverKey(state, index, mouseX, mouseY, plan)
    if state.hoverKey == key then return state.hovered end
    local best, bestDistance
    for objectIndex = 1, #(objects or {}) do
        local object = objects[objectIndex]
        local distance = P.HoveredWorld(drawer, index, object, mouseX, mouseY)
        if distance and (not bestDistance or distance < bestDistance) then
            best, bestDistance = object, distance
        end
    end
    state.hovered = best
    state.hoverKey = key
    if state.tooltipKey and state.tooltipObject ~= best then
        state.tooltipKey = nil
        state.tooltipLines = nil
        state.tooltipWidth = nil
    end
    state.tooltipObject = best
    return best
end

local function tooltipLine(value)
    if type(value) == "table" then
        local label = value.label or value.key
        local detail = value.value
        if label and detail ~= nil then
            return tostring(label) .. ": " .. tostring(detail)
        end
    end
    if value == nil then return nil end
    return tostring(value)
end

local function drawTooltip(state, drawer, object, settings, key, mouseX,
    mouseY, P)
    if settings.showTooltip == false or not object
        or mouseX == nil or mouseY == nil
    then return end
    local objectID = object.id or object.objectKey or object.targetID
    local cacheKey = tostring(objectID or object) .. ":" .. tostring(key)
    if state.tooltipKey ~= cacheKey then
        local rawLines = Registry.TooltipLines(state.provider, object, settings)
        local lines = {}
        for index = 1, math.min(Overlay.MAX_TOOLTIP_LINES, #rawLines) do
            local line = tooltipLine(rawLines[index])
            if line and line ~= "" then
                lines[#lines + 1] = P.TruncateText(line, 96)
            end
        end
        state.tooltipKey = cacheKey
        state.tooltipLines = lines
        local width = 190
        for index = 1, #lines do
            width = math.max(width, #lines[index] * 7 + 18)
        end
        state.tooltipWidth = width
    end
    local lines = state.tooltipLines or {}
    if #lines == 0 then return end
    local width = math.min(state.tooltipWidth or 190, 560,
        math.max(190, (tonumber(drawer.width) or 1920) - 16))
    local height = #lines * 17 + 12
    local x, y = mouseX + 14, mouseY + 14
    if x + width > drawer.width then x = drawer.width - width - 4 end
    if y + height > drawer.height then y = drawer.height - height - 4 end
    x, y = math.max(4, x), math.max(4, y)
    if drawer.drawRect then
        drawer:drawRect(x, y, width, height, 0.92, 0.01, 0.02, 0.04)
    end
    if drawer.drawRectBorder then
        drawer:drawRectBorder(x, y, width, height, 0.95,
            SELECTED_COLOR.r, SELECTED_COLOR.g, SELECTED_COLOR.b)
    end
    for index = 1, #lines do
        P.DrawText(drawer, lines[index], x + 8, y + 5 + (index - 1) * 17,
            { r = 1, g = 1, b = 1, a = 1 })
    end
end

local function drawState(state)
    local snapshot = state.snapshot
    if not snapshot or not Snapshot.IsReady(snapshot) then return end
    local settings, key = settingsFor(state)
    if not Registry.HasRenderableLayers(state.provider, settings) then return end
    local plan = renderPlanFor(state, snapshot, settings, key)
    if #plan.tiles == 0 and #plan.zones == 0 then
        state.visibleObjects = plan.objects
        return
    end
    local player = playerFor()
    if not player then return end
    local P = primitives()
    if not P then return end
    local index = playerNum(player)
    local drawer = P.DrawerFor(state, index)
    if not drawer then return end

    for zoneIndex = 1, #plan.zones do
        local zone = plan.zones[zoneIndex]
        local color = Registry.ZoneColor(state.provider, zone, settings)
        P.DrawZone(drawer, index, zone, color)
        local label = Registry.ZoneLabel(state.provider, zone, settings)
        P.DrawZoneLabel(drawer, index, zone, color, label)
    end
    for tileIndex = 1, #plan.tiles do
        local tile = plan.tiles[tileIndex]
        P.WorldTile(drawer, index, tile.x, tile.y, tile.z, tile.color)
    end
    state.visibleObjects = plan.objects
    local mouseX, mouseY = mousePosition(drawer)
    local hovered = findHovered(state, drawer, index, plan.objects, mouseX,
        mouseY, P, plan)
    drawTooltip(state, drawer, hovered, settings, key, mouseX, mouseY, P)
end

function Overlay.Render()
    if not Overlay.eventsInstalled and not needsHook() then return end
    for index = 1, #Overlay.sessionOrder do
        local state = Overlay.sessions[Overlay.sessionOrder[index]]
        if state and state.enabled then drawState(state) end
    end
end

function Overlay.Reset()
    for index = 1, #Overlay.sessionOrder do
        local state = Overlay.sessions[Overlay.sessionOrder[index]]
        if state then
            state.enabled = false
            state.snapshot = nil
            state.visibleObjects = {}
            invalidate(state)
        end
    end
    Overlay.Uninstall()
end

return Overlay
