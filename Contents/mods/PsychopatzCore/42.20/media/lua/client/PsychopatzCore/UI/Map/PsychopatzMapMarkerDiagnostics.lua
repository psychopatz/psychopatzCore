-- Provider-neutral map-marker inspection registry.
--
-- Core owns the diagnostic contract and bounded aggregation. Providers only
-- contribute read-only rows; they never register a second map renderer.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.MapMarkerDiagnostics =
    PsychopatzCore.MapMarkerDiagnostics or {}

local Diagnostics = PsychopatzCore.MapMarkerDiagnostics
Diagnostics.Sources = Diagnostics.Sources or {}
Diagnostics.Enabled = Diagnostics.Enabled == true
Diagnostics.MaxRows = tonumber(Diagnostics.MaxRows) or 1000
Diagnostics.LastErrors = Diagnostics.LastErrors or {}

local function sourceList()
    local output = {}
    for id, definition in pairs(Diagnostics.Sources) do
        output[#output + 1] = {
            id = id,
            kind = definition.kind,
            priority = tonumber(definition.priority) or 0,
            list = definition.list,
        }
    end
    table.sort(output, function(left, right)
        if left.priority == right.priority then
            return tostring(left.id) < tostring(right.id)
        end
        return left.priority > right.priority
    end)
    return output
end

local function copyRow(row)
    local output = {}
    for key, value in pairs(row) do output[key] = value end
    return output
end

local function normalize(row, source, index)
    if type(row) ~= "table" then return nil end
    local output = copyRow(row)
    output.source = tostring(output.source or source.id)
    output.kind = tostring(output.kind or source.kind or "unknown")
    output.id = tostring(output.id or output.actorID or output.groupID
        or output.entityID or output.siteID or "")
    if output.id == "" then
        output.id = output.source .. ":" .. tostring(index)
    end
    output.label = tostring(output.label or output.name or output.id)
    if not output.position and tonumber(output.x) and tonumber(output.y) then
        output.position = {
            x = tonumber(output.x),
            y = tonumber(output.y),
            z = tonumber(output.z) or 0,
        }
    end
    local rawPresence = output.presence or output.providerState or "unknown"
    local presence = string.lower(tostring(rawPresence))
    if presence == "physical" or presence == "live"
        or presence == "materialized"
    then
        presence = "materialized"
    elseif presence == "remote" or presence == "virtual"
        or presence == "abstract"
    then
        presence = "abstract"
    elseif output.bodyID and (not output.presence
        or presence == "" or presence == "unknown")
    then
        presence = "materialized"
    elseif not output.presence or presence == "" then
        presence = "unknown"
    end
    output.presence = presence
    return output
end

function Diagnostics.RegisterSource(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.list) ~= "function"
    then
        return false, "invalid_marker_diagnostic_source"
    end
    Diagnostics.Sources[id] = {
        kind = definition.kind,
        priority = tonumber(definition.priority) or 0,
        list = definition.list,
    }
    return true, id
end

function Diagnostics.UnregisterSource(id)
    id = tostring(id or "")
    if id == "" or Diagnostics.Sources[id] == nil then return false end
    Diagnostics.Sources[id] = nil
    return true
end

function Diagnostics.SetEnabled(enabled)
    Diagnostics.Enabled = enabled == true
    return Diagnostics.Enabled
end

function Diagnostics.IsEnabled()
    return Diagnostics.Enabled == true
end

function Diagnostics.List()
    local output = {}
    Diagnostics.LastErrors = {}
    local limit = math.max(1, math.floor(tonumber(Diagnostics.MaxRows) or 1000))
    for _, source in ipairs(sourceList()) do
        if #output >= limit then break end
        -- Source callbacks are addon-owned integration boundaries. Keep a
        -- broken optional provider from taking down the shared debug surface.
        local ok, rows = pcall(source.list)
        if not ok then
            Diagnostics.LastErrors[#Diagnostics.LastErrors + 1] = {
                source = source.id,
                error = tostring(rows),
            }
        elseif type(rows) == "table" then
            for index, row in ipairs(rows) do
                if #output >= limit then break end
                local normalized = normalize(row, source, index)
                if normalized then output[#output + 1] = normalized end
            end
        end
    end
    table.sort(output, function(left, right)
        if left.kind ~= right.kind then return left.kind < right.kind end
        if left.source ~= right.source then
            return left.source < right.source
        end
        return left.id < right.id
    end)
    return output
end

function Diagnostics.Summarize(rows)
    rows = type(rows) == "table" and rows or Diagnostics.List()
    local summary = {
        total = #rows,
        byKind = {},
        byPresence = {},
        bySource = {},
        errors = #Diagnostics.LastErrors,
    }
    for _, row in ipairs(rows) do
        summary.byKind[row.kind] = (summary.byKind[row.kind] or 0) + 1
        summary.byPresence[row.presence] =
            (summary.byPresence[row.presence] or 0) + 1
        summary.bySource[row.source] =
            (summary.bySource[row.source] or 0) + 1
    end
    return summary
end

return Diagnostics
