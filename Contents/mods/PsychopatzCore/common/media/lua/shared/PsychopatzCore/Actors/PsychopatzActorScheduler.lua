local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Scheduler = {}

Scheduler.SCHEMA_VERSION = 1
Scheduler.MAX_ENTRIES = 128

local function entryID(spec)
    return Util.text(spec.entryID or spec.entryId, nil)
end

function Scheduler.NewState(source)
    source = type(source) == "table" and source or {}
    local entries = {}
    local count = 0
    local input = source.entries or source
    for key, value in pairs(input or {}) do
        if count >= Scheduler.MAX_ENTRIES then
            return nil, "schedule_limit_exceeded"
        end
        local id = entryID(value) or Util.text(key, nil)
        local actorID = Util.text(value.actorID or value.actorId, nil)
        local taskID = Util.text(value.taskID or value.taskId, nil)
        if not id or not actorID or not taskID then
            return nil, "schedule_entry_invalid"
        end
        if entries[id] then return nil, "duplicate_schedule_entry" end
        entries[id] = {
            schemaVersion = Scheduler.SCHEMA_VERSION,
            entryID = id,
            actorID = actorID,
            taskID = taskID,
            dueAt = tonumber(value.dueAt) or 0,
            priority = math.floor(tonumber(value.priority) or 0),
            payload = Util.clone(value.payload or {}),
        }
        count = count + 1
    end
    return {
        schemaVersion = Scheduler.SCHEMA_VERSION,
        entries = entries,
        revision = math.max(0, math.floor(tonumber(source.revision) or 0)),
    }
end

function Scheduler.Validate(state)
    if type(state) ~= "table"
        or Util.integer(state.schemaVersion, 0) ~= Scheduler.SCHEMA_VERSION
        or type(state.entries) ~= "table"
    then return false, "scheduler_schema_mismatch" end
    local count = 0
    for key, entry in pairs(state.entries) do
        count = count + 1
        if count > Scheduler.MAX_ENTRIES
            or type(entry) ~= "table"
            or key ~= entry.entryID
            or Util.integer(entry.schemaVersion, 0)
                ~= Scheduler.SCHEMA_VERSION
            or not Util.text(entry.actorID, nil)
            or not Util.text(entry.taskID, nil)
            or tonumber(entry.dueAt) == nil
            or type(entry.payload) ~= "table"
            or not Util.isSerializable(entry)
        then return false, "schedule_entry_invalid" end
    end
    return true
end

function Scheduler.Schedule(state, spec)
    if type(state) ~= "table" or type(spec) ~= "table" then
        return nil, "schedule_required"
    end
    local id = entryID(spec)
    if not id then return nil, "schedule_entry_id_required" end
    if state.entries[id] then return nil, "duplicate_schedule_entry" end
    local count = 0
    for _ in pairs(state.entries) do count = count + 1 end
    if count >= Scheduler.MAX_ENTRIES then return nil, "schedule_limit_exceeded" end
    local nextState = Util.clone(state)
    nextState.entries[id] = {
        schemaVersion = Scheduler.SCHEMA_VERSION,
        entryID = id,
        actorID = Util.text(spec.actorID or spec.actorId, nil),
        taskID = Util.text(spec.taskID or spec.taskId, nil),
        dueAt = tonumber(spec.dueAt) or 0,
        priority = math.floor(tonumber(spec.priority) or 0),
        payload = Util.clone(spec.payload or {}),
    }
    if not nextState.entries[id].actorID or not nextState.entries[id].taskID
        or not Util.isSerializable(nextState.entries[id].payload)
    then return nil, "schedule_entry_invalid" end
    nextState.revision = (tonumber(state.revision) or 0) + 1
    return nextState
end

function Scheduler.Cancel(state, id)
    if type(state) ~= "table" or not state.entries[id] then
        return nil, "schedule_entry_not_found"
    end
    local nextState = Util.clone(state)
    nextState.entries[id] = nil
    nextState.revision = (tonumber(state.revision) or 0) + 1
    return nextState
end

function Scheduler.PopDue(state, now, budget)
    if type(state) ~= "table" then return nil, "scheduler_required" end
    local due = {}
    now = tonumber(now) or 0
    for _, entry in pairs(state.entries) do
        if entry.dueAt <= now then due[#due + 1] = entry end
    end
    table.sort(due, function(left, right)
        if left.dueAt ~= right.dueAt then return left.dueAt < right.dueAt end
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return left.entryID < right.entryID
    end)
    local nextState = Util.clone(state)
    local output = {}
    for index = 1, math.min(#due, math.max(1,
        math.floor(tonumber(budget) or Scheduler.MAX_ENTRIES))) do
        output[#output + 1] = Util.clone(due[index])
        nextState.entries[due[index].entryID] = nil
    end
    if #output > 0 then nextState.revision = state.revision + 1 end
    return nextState, output
end

return Scheduler
