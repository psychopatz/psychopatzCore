-- Shared tooltip resolution for command-hub categories and actions.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local Tooltip = {}

local function trace(definition, result)
    local hub = PsychopatzCore.UI.CommandHub
    if hub and hub.Trace then
        hub.Trace("disabled_tooltip_error", "id="
            .. tostring(definition and definition.id)
            .. " error=" .. tostring(result))
    end
end

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

function Tooltip.TitleFor(definition)
    return tr(definition and definition.titleKey,
        definition and definition.titleFallback or "COMMAND")
end

function Tooltip.For(definition, context, enabled)
    local key = definition and definition.tooltipKey
    local fallback = definition and definition.tooltipFallback
        or Tooltip.TitleFor(definition)
    if enabled ~= false or not definition then
        return tr(key, fallback)
    end

    local resolver = definition.disabledTooltip
    local value
    if type(resolver) == "function" then
        local ok, result = pcall(resolver, definition, context)
        if ok then
            value = result
        else
            trace(definition, result)
        end
    else
        value = resolver
    end
    if type(value) == "table" then
        key = value.key or value.tooltipKey or key
        fallback = value.fallback or value.tooltipFallback or fallback
    elseif type(value) == "string" and value ~= "" then
        return value
    elseif type(definition.disabledTooltipKey) == "string" then
        key = definition.disabledTooltipKey
        fallback = definition.disabledTooltipFallback or fallback
    end
    return tr(key, fallback)
end

return Tooltip
