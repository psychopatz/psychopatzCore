-- Provider-facing presentation fallbacks for the generic preview window.
-- Domain providers can replace every section with their own primitive-row
-- callback; these defaults keep a new provider inspectable on day one.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Preview = PsychopatzCore.Preview or {}

local Preview = PsychopatzCore.Preview
local Presentation = Preview.Presentation or {}
Preview.Presentation = Presentation

local Translation = PsychopatzCore.Translation

local function translated(key, fallback)
    if Translation and type(Translation.GetKey) == "function" then
        return Translation.GetKey(key, fallback)
    end
    return fallback or key
end

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    return ok and value or nil
end

local function text(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

local function listText(values, fallback)
    if type(values) ~= "table" then
        return fallback or translated("UI_PsychopatzPreview_None", "none")
    end
    local result = {}
    for index = 1, #values do
        if values[index] ~= nil then
            result[#result + 1] = tostring(values[index])
        end
    end
    if #result > 0 then return table.concat(result, ", ") end
    return fallback or translated("UI_PsychopatzPreview_None", "none")
end

local function objectLabel(record)
    local facts = record and record.facts or {}
    local metadata = record and record.metadata or {}
    return text(record and (record.label or record.displayName), nil)
        or text(facts.nativeName or facts.displayName or facts.objectName,
            nil)
        or text(metadata.displayName or metadata.objectName
            or metadata.spriteName, nil)
        or text(record and (record.objectKey or record.targetID or record.id),
            translated("UI_PsychopatzPreview_WorldObject", "world object"))
end

local function objectID(record, index)
    return tostring(record and (record.id or record.objectKey
        or record.targetID) or index or "object")
end

function Presentation.OptionDefinitions(provider, settings)
    local definitions = call(provider and provider.getOptionDefinitions)
    if type(definitions) == "table" and #definitions > 0 then
        return definitions
    end
    settings = type(settings) == "table" and settings or {}
    local result, seen = {}, {}
    for index = 1, #(provider and provider.layers or {}) do
        local layer = provider.layers[index]
        local key = tostring(layer.settingKey or layer.id or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            result[#result + 1] = {
                id = key,
                label = layer.titleKey or layer.title or key,
                value = settings[key] == true,
                get = function() return settings[key] == true end,
            }
        end
    end
    return result
end

function Presentation.ObjectRows(provider, snapshot, settings)
    local result = call(provider and provider.objectRows, snapshot, settings)
    if type(result) == "table" then return result end
    result = {}
    for index = 1, #(snapshot and snapshot.objects or {}) do
        local object = snapshot.objects[index]
        local detail = object and (object.detail or object.usage)
        if type(detail) == "table" then detail = listText(detail) end
        result[#result + 1] = {
            id = objectID(object, index),
            label = objectLabel(object),
            detail = text(detail, translated(
                "UI_PsychopatzPreview_Unclassified", "unclassified")),
            object = object,
        }
    end
    table.sort(result, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return result
end

function Presentation.DetailRows(provider, object, settings)
    local result = call(provider and provider.detailRows, object, settings)
    if type(result) == "table" then return result end
    if not object then
        return { { label = translated("UI_PsychopatzPreview_Selection",
            "selection"), value = translated(
            "UI_PsychopatzPreview_NoObjectSelected", "no object selected") } }
    end
    local facts = object.facts or {}
    local rows = {
        { label = translated("UI_PsychopatzPreview_ObjectID", "object ID"),
            value = objectID(object) },
        { label = translated("UI_PsychopatzPreview_Position", "position"),
            value = string.format(translated(
                "UI_PsychopatzPreview_PositionFormat", "%.2f, %.2f, %.0f"),
            tonumber(object.x) or 0, tonumber(object.y) or 0,
            tonumber(object.z) or 0) },
        { label = translated("UI_PsychopatzPreview_Usage", "usage"),
            value = listText(facts.usage) },
        { label = translated("UI_PsychopatzPreview_SemanticKinds",
            "semantic kinds"), value = listText(facts.semanticKinds) },
    }
    return rows
end

function Presentation.Summary(provider, snapshot)
    local result = call(provider and provider.summary, snapshot)
    if type(result) == "table" then return result end
    return {
        status = text(snapshot and snapshot.status, "UNAVAILABLE"),
        objects = #(snapshot and snapshot.objects or {}),
        zones = #(snapshot and snapshot.zones or {}),
    }
end

function Presentation.CampPreviewRows(provider, snapshot)
    local result = call(provider and provider.campPreviewRows, snapshot)
    if type(result) == "table" then return result end
    local preview = snapshot and snapshot.campPreview or nil
    if type(preview) ~= "table" then
        return { { label = translated("UI_PsychopatzPreview_Preview", "preview"),
            value = translated("UI_PsychopatzPreview_Unavailable", "unavailable") } }
    end
    local rows = {}
    local labels = {
        status = "UI_PsychopatzPreview_Status",
        policy = "UI_PsychopatzPreview_Policy",
        source = "UI_PsychopatzPreview_Source",
        scope = "UI_PsychopatzPreview_Scope",
        label = "UI_PsychopatzPreview_Label",
        roomType = "UI_PsychopatzPreview_RoomType",
        siteID = "UI_PsychopatzPreview_SiteID",
        campfireID = "UI_PsychopatzPreview_CampfireID",
        reason = "UI_PsychopatzPreview_Reason",
    }
    local keys = { "status", "policy", "source", "scope", "label",
        "roomType", "siteID", "campfireID", "reason" }
    for index = 1, #keys do
        local key = keys[index]
        if preview[key] ~= nil then
            rows[#rows + 1] = {
                label = translated(labels[key], key),
                value = tostring(preview[key]),
            }
        end
    end
    return rows
end

function Presentation.TooltipLines(provider, object, settings)
    local result = call(provider and provider.tooltipLines, object, settings)
    if type(result) == "table" then return result end
    return { objectLabel(object) }
end

return Presentation
