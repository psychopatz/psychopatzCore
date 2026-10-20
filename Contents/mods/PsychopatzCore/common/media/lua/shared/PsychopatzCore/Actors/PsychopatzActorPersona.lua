local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Persona = {}

Persona.SCHEMA_VERSION = 1
Persona.BACKSTORY_SCHEMA_VERSION = 1
Persona.DEFAULT_SELECTION_SET_VERSION = "1"
Persona.MAX_SELECTIONS = 32
Persona.MAX_ID_LENGTH = 160
Persona.MAX_VERSION_LENGTH = 64

local function text(value, limit)
    value = Util.text(value, nil)
    if not value or #value > (limit or Persona.MAX_ID_LENGTH)
        or string.match(value, "[%c]")
    then return nil end
    return value
end

local function key(value)
    value = text(value)
    if not value or not string.match(value, "^[%w_%.:%-]+$") then return nil end
    return value
end

local function version(value)
    if type(value) == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return nil
        end
        value = math.floor(value)
        return value >= 1 and value or nil
    end
    return text(value, Persona.MAX_VERSION_LENGTH)
end

local function normalizeSelection(value)
    if type(value) == "string" then value = { id = value } end
    if type(value) ~= "table" then return nil, "backstory_selection_invalid" end
    local id = key(value.id or value.selectionID or value.key)
    if not id then return nil, "backstory_selection_id_required" end
    local version = value.version or value.selectionVersion or 1
    if type(version) ~= "string" and type(version) ~= "number" then
        return nil, "backstory_selection_version_invalid"
    end
    if type(version) == "string" then
        version = text(version, Persona.MAX_VERSION_LENGTH)
        if not version then return nil, "backstory_selection_version_invalid" end
    else
        version = math.floor(version)
        if version < 1 then return nil, "backstory_selection_version_invalid" end
    end
    local sourceKey = value.sourceKey or value.source or value.catalogKey
    if sourceKey ~= nil then
        sourceKey = key(sourceKey)
        if not sourceKey then return nil, "backstory_selection_source_invalid" end
    end
    return {
        id = id,
        version = version,
        sourceKey = sourceKey,
    }
end

local function normalizeBackstory(source)
    local input = type(source) == "table" and source or {}
    local selections = input.selections or input.selectionMap or {}
    if type(selections) ~= "table" then return nil, "backstory_selections_required" end
    local output = {
        schemaVersion = Persona.BACKSTORY_SCHEMA_VERSION,
        selectionSetVersion = version(input.selectionSetVersion
            or input.catalogVersion) or Persona.DEFAULT_SELECTION_SET_VERSION,
        selectionClass = text(input.selectionClass, Persona.MAX_VERSION_LENGTH),
        selections = {},
        overrides = {},
    }
    local count = 0
    for kind, value in pairs(selections) do
        local normalizedKind = key(kind)
        if not normalizedKind then return nil, "backstory_kind_invalid" end
        count = count + 1
        if count > Persona.MAX_SELECTIONS then
            return nil, "backstory_selection_limit"
        end
        local selection, reason = normalizeSelection(value)
        if not selection then return nil, reason end
        output.selections[normalizedKind] = selection
    end
    local overrides = input.overrides
    if type(overrides) == "table" then
        for kind, value in pairs(overrides) do
            local normalizedKind = key(kind)
            if not normalizedKind then return nil, "backstory_override_invalid" end
            local selection, reason = normalizeSelection(value)
            if not selection then return nil, reason end
            output.overrides[normalizedKind] = selection
        end
    end
    return output
end

function Persona.NewState(source)
    local input = type(source) == "table" and source or {}
    local rawBackstory = input.backstory or input
    if type(rawBackstory) ~= "table" then rawBackstory = {} end
    local backstory, reason = normalizeBackstory(rawBackstory)
    if not backstory then return nil, reason end
    return {
        schemaVersion = Persona.SCHEMA_VERSION,
        backstory = backstory,
    }
end

function Persona.Validate(state)
    if type(state) ~= "table"
        or tonumber(state.schemaVersion) ~= Persona.SCHEMA_VERSION
        or type(state.backstory) ~= "table"
    then return false, "persona_schema_mismatch" end
    if tonumber(state.backstory.schemaVersion)
        ~= Persona.BACKSTORY_SCHEMA_VERSION
        or type(state.backstory.selections) ~= "table"
    then return false, "backstory_schema_mismatch" end
    local normalized, reason = Persona.NewState(state)
    if not normalized then return false, reason end
    if normalized.backstory.selectionSetVersion
        ~= state.backstory.selectionSetVersion
    then return false, "backstory_selection_set_invalid" end
    if normalized.backstory.selectionClass ~= state.backstory.selectionClass then
        return false, "backstory_selection_class_invalid"
    end
    for kind, selection in pairs(state.backstory.selections) do
        if not normalized.backstory.selections[kind]
            or selection.id ~= normalized.backstory.selections[kind].id
            or selection.version ~= normalized.backstory.selections[kind].version
        then return false, "backstory_selection_invalid" end
    end
    for kind, selection in pairs(state.backstory.overrides or {}) do
        if not normalized.backstory.overrides[kind]
            or selection.id ~= normalized.backstory.overrides[kind].id
            or selection.version ~= normalized.backstory.overrides[kind].version
        then return false, "backstory_override_invalid" end
    end
    return true
end

function Persona.GetBackstory(state, kind)
    local normalizedKind = key(kind)
    if not normalizedKind then return nil, "backstory_kind_invalid" end
    local selection = state and state.backstory
        and state.backstory.selections[normalizedKind]
    if not selection then return nil, "backstory_selection_not_found" end
    return Util.clone(selection)
end

function Persona.ToPayload(state)
    local normalized, reason = Persona.NewState(state)
    if not normalized then return nil, reason end
    local valid
    valid, reason = Persona.Validate(normalized)
    if not valid then return nil, reason end
    return normalized
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ActorPersona = Persona
return Persona
