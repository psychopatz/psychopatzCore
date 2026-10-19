local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Task = {}

Task.SCHEMA_VERSION = 1
Task.MAX_TASKS = 64

local STATES = {
    queued = true,
    leased = true,
    running = true,
    completed = true,
    failed = true,
    cancelled = true,
}

function Task.New(spec, now)
    spec = type(spec) == "table" and spec or {}
    local taskID = Util.text(spec.taskID or spec.taskId, nil)
    local actorID = Util.text(spec.actorID or spec.actorId, nil)
    local taskType = Util.text(spec.type, nil)
    if spec.state ~= nil and not STATES[spec.state] then
        return nil, "task_state_invalid"
    end
    if not taskID then return nil, "task_id_required" end
    if not actorID then return nil, "actor_id_required" end
    if not taskType then return nil, "task_type_required" end
    local payload = Util.clone(spec.payload or {})
    if not Util.isSerializable(payload) then return nil, "task_payload_invalid" end
    return {
        schemaVersion = Task.SCHEMA_VERSION,
        taskID = taskID,
        actorID = actorID,
        type = taskType,
        state = STATES[spec.state] and spec.state or "queued",
        priority = math.floor(tonumber(spec.priority) or 0),
        dueAt = tonumber(spec.dueAt) or tonumber(now) or 0,
        deadlineAt = tonumber(spec.deadlineAt),
        targetAnchorID = Util.text(spec.targetAnchorID, nil),
        payload = payload,
        attempts = math.max(0, math.floor(tonumber(spec.attempts) or 0)),
        maxAttempts = math.max(1, math.floor(tonumber(spec.maxAttempts) or 3)),
        revision = math.max(1, math.floor(tonumber(spec.revision) or 1)),
    }
end

function Task.NewQueue(source)
    source = type(source) == "table" and source or {}
    local tasks = {}
    local input = source.tasks or source.items or source
    local count = 0
    for key, value in pairs(input or {}) do
        if count >= Task.MAX_TASKS then return nil, "task_limit_exceeded" end
        local task, reason = Task.New(value)
        if not task then return nil, reason end
        task.taskID = Util.text(value.taskID or value.taskId, key)
        if tasks[task.taskID] then return nil, "duplicate_task_id" end
        tasks[task.taskID] = task
        count = count + 1
    end
    return {
        schemaVersion = Task.SCHEMA_VERSION,
        tasks = tasks,
        revision = math.max(0, math.floor(tonumber(source.revision) or 0)),
    }
end

function Task.Validate(task)
    return type(task) == "table"
        and Util.integer(task.schemaVersion, 0) == Task.SCHEMA_VERSION
        and Util.text(task.taskID, nil) ~= nil
        and Util.text(task.actorID, nil) ~= nil
        and Util.text(task.type, nil) ~= nil
        and STATES[task.state] == true
        and type(task.payload) == "table"
        and Util.isSerializable(task)
end

function Task.ValidateQueue(queue)
    if type(queue) ~= "table"
        or Util.integer(queue.schemaVersion, 0) ~= Task.SCHEMA_VERSION
        or type(queue.tasks) ~= "table"
    then return false, "task_queue_schema_mismatch" end
    local count = 0
    for key, task in pairs(queue.tasks) do
        count = count + 1
        if count > Task.MAX_TASKS or type(task) ~= "table"
            or key ~= task.taskID
            or not Task.Validate(task)
        then return false, "task_invalid" end
    end
    return true
end

function Task.Enqueue(queue, task)
    if type(queue) ~= "table" or type(queue.tasks) ~= "table" then
        return nil, "task_queue_required"
    end
    if queue.tasks[task and task.taskID] then return nil, "duplicate_task_id" end
    if Task.MAX_TASKS <= 0 then return nil, "task_limit_exceeded" end
    if not Task.Validate(task) then return nil, "task_invalid" end
    local count = 0
    for _ in pairs(queue.tasks) do count = count + 1 end
    if count >= Task.MAX_TASKS then return nil, "task_limit_exceeded" end
    queue.tasks[task.taskID] = Util.clone(task)
    queue.revision = (tonumber(queue.revision) or 0) + 1
    return Util.clone(task)
end

local function ordered(queue, now, budget)
    local due = {}
    for _, task in pairs(queue.tasks or {}) do
        if task.state == "queued" and tonumber(task.dueAt) <= now then
            due[#due + 1] = task
        end
    end
    table.sort(due, function(left, right)
        if left.dueAt ~= right.dueAt then return left.dueAt < right.dueAt end
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return left.taskID < right.taskID
    end)
    local output = {}
    for index = 1, math.min(#due, math.max(1, budget)) do
        output[#output + 1] = Util.clone(due[index])
    end
    return output
end

function Task.PopDue(queue, now, budget)
    if type(queue) ~= "table" then return nil, "task_queue_required" end
    local due = ordered(queue, tonumber(now) or 0,
        math.floor(tonumber(budget) or Task.MAX_TASKS))
    for index = 1, #due do
        local task = queue.tasks[due[index].taskID]
        task.state = "leased"
        task.attempts = task.attempts + 1
        task.revision = task.revision + 1
    end
    if #due > 0 then queue.revision = queue.revision + 1 end
    return due
end

function Task.Transition(queue, taskID, state, patch)
    if not STATES[state] then return nil, "task_state_invalid" end
    local task = queue and queue.tasks and queue.tasks[taskID]
    if not task then return nil, "task_not_found" end
    local nextTask = Util.clone(task)
    nextTask.state = state
    if type(patch) == "table" then
        for key, value in pairs(patch) do
            if key ~= "taskID" and key ~= "actorID" then
                nextTask[key] = Util.clone(value)
            end
        end
    end
    if not Task.Validate(nextTask) then return nil, "task_invalid" end
    nextTask.revision = task.revision + 1
    queue.tasks[taskID] = nextTask
    queue.revision = (tonumber(queue.revision) or 0) + 1
    return Util.clone(nextTask)
end

return Task
