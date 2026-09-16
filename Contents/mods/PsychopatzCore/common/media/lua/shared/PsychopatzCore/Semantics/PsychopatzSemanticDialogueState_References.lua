-- Reference bookkeeping for bounded semantic dialogue state.
-- This spoke exposes only small internal helpers plus the public resolver.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local State = Semantics.DialogueState
local Internal = State.Internal or {}
State.Internal = Internal
local copyValue = Internal.CopyValue

local function referenceFrom(field, value)
    if type(value) ~= "table" then return nil end
    if value.reference then
        return {
            field = field,
            reference = value.reference,
            value = value.value,
        }
    end
    if value.unresolved == true then
        return {
            field = field,
            reference = nil,
            value = value.value or value.text,
        }
    end
    return nil
end

local function addUnresolvedReference(state, reference)
    if type(reference) ~= "table" then return end
    local key = tostring(reference.field or "")
        .. "|" .. tostring(reference.reference or "")
        .. "|" .. tostring(reference.value or "")
    local index
    local existing
    for index = 1, #state.unresolvedReferences do
        existing = state.unresolvedReferences[index]
        if existing.key == key then return end
    end
    reference.key = key
    state.unresolvedReferences[#state.unresolvedReferences + 1] = reference
    while #state.unresolvedReferences > state.maxReferences do
        table.remove(state.unresolvedReferences, 1)
    end
end

function Internal.ReferenceFrom(field, value)
    return referenceFrom(field, value)
end

function Internal.AddUnresolvedReference(state, reference)
    return addUnresolvedReference(state, reference)
end

function State:ResolveReference(value)
    local reference = type(value) == "table" and value.reference or value
    reference = string.upper(tostring(reference or ""))
    local event = self.lastEvent or {}
    if reference == "THIS" or reference == "IT" or reference == "THAT" then
        return copyValue(event.object), "last_object"
    end
    if reference == "HIM" or reference == "HER" or reference == "THEM" then
        return copyValue(event.recipient or event.target), "last_person"
    end
    return nil, "unresolved_reference"
end

return State
