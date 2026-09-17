-- Provider and layer registry for the client-only preview framework.
--
-- This module is deliberately independent from Project Zomboid world objects,
-- UI classes, and event hooks. A provider describes primitive records and
-- presentation callbacks; the renderer consumes that description later.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Preview = PsychopatzCore.Preview or {}

local Preview = PsychopatzCore.Preview
local Registry = Preview.Registry or {}
Preview.Registry = Registry

Registry.VERSION = 1
Registry.providers = Registry.providers or {}

local function text(value, fallback)
    value = tostring(value or "")
    if value == "" then return fallback end
    return value
end

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value then return fallback end
    return value
end

local function copyColor(value, fallback)
    value = type(value) == "table" and value or fallback
    if type(value) ~= "table" then
        return { r = 0.75, g = 0.85, b = 1.0, a = 0.70 }
    end
    return {
        r = number(value.r, 0.75),
        g = number(value.g, 0.85),
        b = number(value.b, 1.0),
        a = number(value.a, 0.70),
    }
end

local function normalizeLayer(layer, index)
    if type(layer) ~= "table" then return nil, "layer_required" end
    local id = text(layer.id, nil)
    if not id then return nil, "layer_id_required" end
    local kind = text(layer.kind, "object")
    if kind ~= "object" and kind ~= "zone" and kind ~= "both" then
        return nil, "layer_kind_invalid"
    end
    local normalized = {
        id = id,
        title = text(layer.title, id),
        titleKey = text(layer.titleKey, nil),
        kind = kind,
        tag = text(layer.tag, id),
        settingKey = text(layer.settingKey, id),
        renderable = layer.renderable ~= false,
        defaultEnabled = layer.defaultEnabled ~= false,
        priority = number(layer.priority, 0),
        color = copyColor(layer.color),
        order = number(layer.order, index * 10),
    }
    return normalized
end

local function normalizeProvider(definition)
    if type(definition) ~= "table" then return nil, "provider_required" end
    local id = text(definition.id, nil)
    if not id then return nil, "provider_id_required" end

    local provider = {
        id = id,
        source = text(definition.source, id),
        title = text(definition.title, id),
        titleKey = text(definition.titleKey, nil),
        description = text(definition.description, ""),
        descriptionKey = text(definition.descriptionKey, nil),
        version = number(definition.version, 1),
        maxRenderObjects = number(definition.maxRenderObjects, nil),
        maxRenderZones = number(definition.maxRenderZones, nil),
        getSettings = definition.getSettings,
        getSettingsRevision = definition.getSettingsRevision,
        settingsKey = definition.settingsKey,
        translate = definition.translate,
        refreshSnapshot = definition.refreshSnapshot or definition.refresh,
        getOptionDefinitions = definition.getOptionDefinitions,
        objectRows = definition.objectRows,
        detailRows = definition.detailRows,
        summary = definition.summary,
        campPreviewRows = definition.campPreviewRows,
        hasRenderableLayers = definition.hasRenderableLayers,
        objectVisible = definition.objectVisible,
        objectPriority = definition.objectPriority,
        objectColor = definition.objectColor,
        zoneVisible = definition.zoneVisible,
        zonePriority = definition.zonePriority,
        zoneColor = definition.zoneColor,
        zoneLabel = definition.zoneLabel,
        tooltipLines = definition.tooltipLines,
        onSnapshot = definition.onSnapshot,
    }

    if provider.maxRenderObjects then
        provider.maxRenderObjects = math.max(1,
            math.min(256, math.floor(provider.maxRenderObjects)))
    end
    if provider.maxRenderZones then
        provider.maxRenderZones = math.max(1,
            math.min(64, math.floor(provider.maxRenderZones)))
    end

    provider.layers = {}
    local layerIDs = {}
    for index, layer in ipairs(definition.layers or {}) do
        local normalized, reason = normalizeLayer(layer, index)
        if not normalized then return nil, reason end
        if layerIDs[normalized.id] then return nil, "duplicate_layer_id" end
        layerIDs[normalized.id] = true
        provider.layers[#provider.layers + 1] = normalized
    end
    table.sort(provider.layers, function(left, right)
        if left.order == right.order then return left.id < right.id end
        return left.order < right.order
    end)
    return provider
end

function Registry.Register(definition)
    local provider, reason = normalizeProvider(definition)
    if not provider then return false, reason end
    Registry.providers[provider.id] = provider
    return true, provider
end

function Registry.Unregister(id)
    id = text(id, nil)
    if not id then return false end
    local existed = Registry.providers[id] ~= nil
    Registry.providers[id] = nil
    return existed
end

function Registry.Get(id)
    return Registry.providers[text(id, "")]
end

function Registry.List()
    local result = {}
    for _, provider in pairs(Registry.providers) do
        result[#result + 1] = provider
    end
    table.sort(result, function(left, right)
        if left.source == right.source then return left.id < right.id end
        return left.source < right.source
    end)
    return result
end

local function settingValue(settings, layer)
    if type(settings) ~= "table" then
        return layer.defaultEnabled == true
    end
    local value = settings[layer.settingKey]
    if value == nil then return layer.defaultEnabled == true end
    return value == true
end

function Registry.IsLayerEnabled(layer, settings)
    return type(layer) == "table" and settingValue(settings, layer)
end

local function tagMatches(record, tag)
    if type(record) ~= "table" then return false end
    local tags = record.tags
    if type(tags) ~= "table" then return false end
    if tags[tag] == true then return true end
    for index = 1, #tags do
        if tostring(tags[index] or "") == tag then return true end
    end
    return false
end

function Registry.MatchingLayers(provider, record, kind, settings)
    local matches = {}
    for index = 1, #(provider and provider.layers or {}) do
        local layer = provider.layers[index]
        local kindMatches = layer.kind == "both" or layer.kind == kind
        if kindMatches and layer.renderable
            and Registry.IsLayerEnabled(layer, settings)
            and tagMatches(record, layer.tag)
        then
            matches[#matches + 1] = layer
        end
    end
    table.sort(matches, function(left, right)
        if left.priority == right.priority then return left.id < right.id end
        return left.priority > right.priority
    end)
    return matches
end

function Registry.HasRenderableLayers(provider, settings)
    if provider and type(provider.hasRenderableLayers) == "function" then
        local ok, value = pcall(provider.hasRenderableLayers, settings or {})
        if ok then return value == true end
    end
    for index = 1, #(provider and provider.layers or {}) do
        local layer = provider.layers[index]
        if layer.renderable and Registry.IsLayerEnabled(layer, settings) then
            return true
        end
    end
    return false
end

function Registry.ObjectVisible(provider, record, settings)
    if provider and type(provider.objectVisible) == "function" then
        local ok, value = pcall(provider.objectVisible, record, settings or {})
        return ok and value == true
    end
    return #Registry.MatchingLayers(provider, record, "object", settings) > 0
end

function Registry.ObjectPriority(provider, record, settings)
    if provider and type(provider.objectPriority) == "function" then
        local ok, value = pcall(provider.objectPriority, record, settings or {})
        if ok and tonumber(value) then return tonumber(value) end
    end
    local layers = Registry.MatchingLayers(provider, record, "object", settings)
    return layers[1] and layers[1].priority or 0
end

function Registry.ObjectColor(provider, record, settings)
    if provider and type(provider.objectColor) == "function" then
        local ok, value = pcall(provider.objectColor, record, settings or {})
        if ok and type(value) == "table" then return copyColor(value) end
    end
    local layers = Registry.MatchingLayers(provider, record, "object", settings)
    return copyColor(layers[1] and layers[1].color)
end

function Registry.ZoneVisible(provider, record, settings)
    if provider and type(provider.zoneVisible) == "function" then
        local ok, value = pcall(provider.zoneVisible, record, settings or {})
        return ok and value == true
    end
    return #Registry.MatchingLayers(provider, record, "zone", settings) > 0
end

function Registry.ZonePriority(provider, record, settings)
    if provider and type(provider.zonePriority) == "function" then
        local ok, value = pcall(provider.zonePriority, record, settings or {})
        if ok and tonumber(value) then return tonumber(value) end
    end
    local layers = Registry.MatchingLayers(provider, record, "zone", settings)
    return layers[1] and layers[1].priority or 0
end

function Registry.ZoneColor(provider, record, settings)
    if provider and type(provider.zoneColor) == "function" then
        local ok, value = pcall(provider.zoneColor, record, settings or {})
        if ok and type(value) == "table" then return copyColor(value) end
    end
    local layers = Registry.MatchingLayers(provider, record, "zone", settings)
    return copyColor(layers[1] and layers[1].color)
end

function Registry.ZoneLabel(provider, record, settings)
    if provider and type(provider.zoneLabel) == "function" then
        local ok, value = pcall(provider.zoneLabel, record, settings or {})
        if ok and value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end
    return record and record.label or nil
end

function Registry.TooltipLines(provider, record, settings)
    if provider and type(provider.tooltipLines) == "function" then
        local ok, value = pcall(provider.tooltipLines, record, settings or {})
        if ok and type(value) == "table" then return value end
    end
    if type(record) == "table" then
        if type(record.tooltipLines) == "table" then return record.tooltipLines end
        if type(record.details) == "table" then
            local lines = {}
            for index = 1, #record.details do
                local detail = record.details[index]
                if type(detail) == "table" then
                    local label = detail.label or detail.key
                    local value = detail.value
                    if label and value ~= nil then
                        lines[#lines + 1] = tostring(label) .. ": " .. tostring(value)
                    end
                elseif detail ~= nil then
                    lines[#lines + 1] = tostring(detail)
                end
            end
            return lines
        end
    end
    return {}
end

return Registry
