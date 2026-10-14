-- Pure presentation helpers for the Core Radio OS.
-- Providers own acquisition and authorization; this module only bounds and
-- normalizes the data that can enter the reusable UI.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local Model = PsychopatzCore.RadioOS.Model or {}
PsychopatzCore.RadioOS.Model = Model

Model.MAX_PAGE_SIZE = 12
Model.MAX_CONTACTS = 64

local function text(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

local function copyActions(actions)
    local result = {}
    if type(actions) ~= "table" then return result end
    for _, action in ipairs(actions) do
        local id
        local label
        if type(action) == "table" then
            id = tostring(action.id or "")
            label = action.label
        else
            id = tostring(action or "")
        end
        if id ~= "" then
            result[#result + 1] = {
                id = id,
                label = text(label, id),
            }
        end
    end
    return result
end

function Model.NormalizeContact(providerID, raw)
    if type(raw) ~= "table" then return nil end
    local id = tostring(raw.id or "")
    if id == "" then return nil end
    local provider = text(raw.providerID, providerID)
    if provider == "" then return nil end
    return {
        id = id,
        providerID = provider,
        title = text(raw.title or raw.name, id),
        status = text(raw.status, "unknown"),
        portraitDescriptor = raw.portraitDescriptor,
        actions = copyActions(raw.actions),
        capabilities = type(raw.capabilities) == "table"
            and raw.capabilities or nil,
    }
end

function Model.ContactKey(entry)
    return tostring(entry and entry.providerID or "") .. ":"
        .. tostring(entry and entry.id or "")
end

function Model.SortContacts(entries)
    table.sort(entries, function(left, right)
        local leftTitle = string.lower(tostring(left.title or ""))
        local rightTitle = string.lower(tostring(right.title or ""))
        if leftTitle == rightTitle then
            return Model.ContactKey(left) < Model.ContactKey(right)
        end
        return leftTitle < rightTitle
    end)
    return entries
end

function Model.NormalizePage(providerID, payload, page)
    page = type(page) == "table" and page or {}
    local limit = math.max(1, math.min(Model.MAX_PAGE_SIZE,
        math.floor(tonumber(page.limit) or Model.MAX_PAGE_SIZE)))
    local rows = payload
    local total = nil
    local nextOffset = nil
    local revision = nil
    if type(payload) == "table" and type(payload.contacts) == "table" then
        rows = payload.contacts
        total = tonumber(payload.total)
        nextOffset = tonumber(payload.nextOffset)
        revision = payload.revision
    end
    local contacts = {}
    local seen = {}
    if type(rows) == "table" then
        for _, raw in ipairs(rows) do
            if #contacts >= Model.MAX_CONTACTS then break end
            local entry = Model.NormalizeContact(providerID, raw)
            local key = entry and Model.ContactKey(entry) or nil
            if entry and not seen[key] then
                seen[key] = true
                contacts[#contacts + 1] = entry
            end
        end
    end
    Model.SortContacts(contacts)
    if total == nil then total = #contacts end
    if nextOffset == nil and #contacts >= limit then
        nextOffset = (tonumber(page.offset) or 0) + #contacts
    end
    return {
        contacts = contacts,
        total = math.max(0, math.floor(total)),
        nextOffset = nextOffset,
        revision = revision,
    }
end

function Model.Page(entries, offset, limit)
    entries = type(entries) == "table" and entries or {}
    offset = math.max(0, math.floor(tonumber(offset) or 0))
    limit = math.max(1, math.min(Model.MAX_PAGE_SIZE,
        math.floor(tonumber(limit) or Model.MAX_PAGE_SIZE)))
    local page = {}
    for index = offset + 1, math.min(#entries, offset + limit) do
        page[#page + 1] = entries[index]
    end
    return page, {
        offset = offset,
        limit = limit,
        total = #entries,
        hasPrevious = offset > 0,
        hasNext = offset + #page < #entries,
    }
end

return Model
