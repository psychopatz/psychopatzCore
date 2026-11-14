-- Core-owned ConvoEngine registered semantic action contract & result boundary.
--
-- Keeps read-only discovery (ActionProviders.collect) strictly separate from
-- mutating action dispatch, enforces schema/capability/input contracts,
-- correlates sync and async request_response/long_running outcomes, deduplicates
-- duplicate/stale async updates, and projects strictly bounded public result.*.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Semantics = PsychopatzCore.Semantics
local ConvoEngine = PsychopatzCore.ConvoEngine
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"

local ActionContract = ConvoEngine.ActionContract or {}
ConvoEngine.ActionContract = ActionContract

ActionContract.VERSION = 1
ActionContract.MAX_DATA_KEYS = 16
ActionContract.MAX_AFFECTED = 16
ActionContract.MAX_INSTANCES = 128

ActionContract.MODES = {
    sync = true,
    request_response = true,
    long_running = true,
}

ActionContract.TERMINAL_OUTCOMES = {
    completed = true,
    rejected = true,
    failed = true,
}

ActionContract.DEFAULT_OUTCOME_MAP = {
    pending = "pending",
    network_queued = "queued",
    queued = "queued",
    accepted = "accepted",
    completed = "completed",
    rejected = "rejected",
    failed = "failed",
}

ActionContract.Contracts = ActionContract.Contracts or {}
ActionContract.Adapters = ActionContract.Adapters or {}
ActionContract.Instances = ActionContract.Instances or {}
ActionContract.InstanceOrder = ActionContract.InstanceOrder or {}
ActionContract.Sequence = ActionContract.Sequence or 0

local function cloneShallow(tbl)
    if type(tbl) ~= "table" then return {} end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

local function sanitizeValue(value, depth)
    depth = depth or 0
    if depth > 4 then return nil end
    local t = type(value)
    if t == "string" or t == "number" or t == "boolean" then
        return value
    end
    if t ~= "table" then
        return nil
    end
    local output = {}
    for k, v in pairs(value) do
        local keyStr = string.lower(tostring(k))
        if type(k) ~= "function"
            and type(v) ~= "function"
            and type(v) ~= "thread"
            and type(v) ~= "userdata"
            and string.find(keyStr, "private", 1, true) == nil
            and string.find(keyStr, "secret", 1, true) == nil
            and string.find(keyStr, "undiscovered", 1, true) == nil
            and keyStr ~= "lua"
            and keyStr ~= "callback"
            and keyStr ~= "java"
        then
            local sanitized = sanitizeValue(v, depth + 1)
            if sanitized ~= nil then
                output[k] = sanitized
            end
        end
    end
    return output
end

local function resolveContextPath(context, path)
    if not IR.IsPublicContextPath(path) then
        return nil
    end
    local current = type(context) == "table" and context or nil
    for segment in string.gmatch(tostring(path or ""), "[^%.]+") do
        if type(current) ~= "table" or current[segment] == nil then
            return nil
        end
        current = current[segment]
    end
    return current
end

local function resolveWithValue(rawVal, context)
    if type(rawVal) ~= "string" then
        return sanitizeValue(rawVal, 0)
    end
    if string.sub(rawVal, 1, 6) == "$slot." then
        local slotPath = string.sub(rawVal, 7)
        return resolveContextPath(context, "slot." .. slotPath)
    end
    if rawVal == "$target" then
        return sanitizeValue(context and context.target or nil, 0)
    end
    if string.sub(rawVal, 1, 8) == "$target." then
        return resolveContextPath(context, "target." .. string.sub(rawVal, 9))
    end
    if string.sub(rawVal, 1, 9) == "$context." then
        return resolveContextPath(context, string.sub(rawVal, 10))
    end
    return rawVal
end

local function matchesInputType(value, expectedType)
    if expectedType == nil or expectedType == "" then return true end
    if expectedType == "location" or expectedType == "entity.location" then
        return type(value) == "table" or type(value) == "string"
    end
    if expectedType == "entity" or string.sub(tostring(expectedType), 1, 7) == "entity." then
        return type(value) == "string" or type(value) == "number" or type(value) == "table"
    end
    if expectedType == "boolean" then
        return type(value) == "boolean"
    end
    if expectedType == "number" or expectedType == "integer" then
        return type(value) == "number"
    end
    if expectedType == "string" then
        return type(value) == "string"
    end
    if expectedType == "table" then
        return type(value) == "table"
    end
    return true
end

local function normalizeReasonClass(reason, outcome)
    local lower = string.lower(tostring(reason or ""))
    if lower == "" then
        return tostring(outcome or "unknown")
    end
    if string.find(lower, "out_of_range", 1, true) then
        return "out_of_range"
    end
    if string.find(lower, "stale", 1, true) or string.find(lower, "invalid", 1, true) then
        return "stale_or_invalid"
    end
    if string.find(lower, "hint", 1, true) or string.find(lower, "visible", 1, true)
        or string.find(lower, "no_safe_room", 1, true)
        or string.find(lower, "unresolved", 1, true)
    then
        return "target_unavailable"
    end
    if string.find(lower, "unavailable", 1, true) or string.find(lower, "busy", 1, true) then
        return "unavailable"
    end
    if string.find(lower, "capab", 1, true) or string.find(lower, "authority", 1, true)
        or string.find(lower, "permission", 1, true)
    then
        return "permission_denied"
    end
    return lower
end

local function storeInstance(instance)
    local reqID = tostring(instance.requestID)
    if ActionContract.Instances[reqID] == nil then
        ActionContract.InstanceOrder[#ActionContract.InstanceOrder + 1] = reqID
    end
    ActionContract.Instances[reqID] = instance
    while #ActionContract.InstanceOrder > ActionContract.MAX_INSTANCES do
        local oldest = table.remove(ActionContract.InstanceOrder, 1)
        if oldest and ActionContract.Instances[oldest] ~= nil then
            local oldInst = ActionContract.Instances[oldest]
            if oldInst.exchangeKey then
                ActionContract.Instances["ex:" .. tostring(oldInst.exchangeKey)] = nil
            end
            ActionContract.Instances[oldest] = nil
        end
    end
    if instance.exchangeKey then
        ActionContract.Instances["ex:" .. tostring(instance.exchangeKey)] = instance
    end
end

function ActionContract.Clear()
    ActionContract.Contracts = {}
    ActionContract.Adapters = {}
    ActionContract.Instances = {}
    ActionContract.InstanceOrder = {}
    ActionContract.Sequence = 0
end

function ActionContract.Register(contractDef, adapterFn)
    if type(contractDef) ~= "table" or type(contractDef.id) ~= "string" or contractDef.id == "" then
        return false, "action_contract_id_invalid"
    end
    if type(adapterFn) ~= "function" then
        return false, "action_contract_adapter_invalid"
    end
    local mode = tostring(contractDef.mode or "sync")
    if not ActionContract.MODES[mode] then
        return false, "action_contract_mode_invalid"
    end
    local stored = {
        id = contractDef.id,
        capability = contractDef.capability,
        mode = mode,
        inputs = type(contractDef.inputs) == "table" and sanitizeValue(contractDef.inputs, 0) or {},
        resultSchema = type(contractDef.result) == "table" and sanitizeValue(contractDef.result, 0)
            or (type(contractDef.resultSchema) == "table" and sanitizeValue(contractDef.resultSchema, 0) or {}),
        outcomeMap = type(contractDef.outcomeMap) == "table" and sanitizeValue(contractDef.outcomeMap, 0)
            or cloneShallow(ActionContract.DEFAULT_OUTCOME_MAP),
        defaultOutcome = contractDef.defaultOutcome,
    }
    ActionContract.Contracts[contractDef.id] = stored
    ActionContract.Adapters[contractDef.id] = adapterFn
    return true, stored
end

function ActionContract.Get(id)
    return ActionContract.Contracts[tostring(id or "")]
end

function ActionContract.List()
    local ids = {}
    for k in pairs(ActionContract.Contracts) do
        ids[#ids + 1] = tostring(k)
    end
    table.sort(ids)
    return ids
end

function ActionContract.ProjectResult(contractOrID, rawResult, requestID, options)
    local contract = type(contractOrID) == "table" and contractOrID
        or ActionContract.Get(contractOrID)
    rawResult = type(rawResult) == "table" and rawResult or {}

    local rawStatus = string.lower(tostring(rawResult.status or ""))
    if rawStatus == "" then
        if rawResult.accepted == true then
            rawStatus = "accepted"
        elseif rawResult.accepted == false then
            rawStatus = "rejected"
        else
            rawStatus = "failed"
        end
    end

    local outcomeMap = type(contract) == "table" and contract.outcomeMap
        or ActionContract.DEFAULT_OUTCOME_MAP
    local outcome = outcomeMap[rawStatus]
        or ActionContract.DEFAULT_OUTCOME_MAP[rawStatus]
        or rawResult.outcome
        or (contract and contract.defaultOutcome)
        or (rawResult.accepted == true and "accepted" or "rejected")
    outcome = string.lower(tostring(outcome))

    local reason = rawResult.reason ~= nil and tostring(rawResult.reason) or nil
    local reasonClass = rawResult.reasonClass ~= nil and tostring(rawResult.reasonClass)
        or normalizeReasonClass(reason, outcome)

    local publicData = {}
    local allowedData = type(contract) == "table"
        and type(contract.resultSchema) == "table"
        and contract.resultSchema
        or {}
    local rawData = type(rawResult.data) == "table" and rawResult.data or rawResult
    local count = 0
    local keys = {}
    for k in pairs(allowedData) do
        keys[#keys + 1] = tostring(k)
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        if count >= ActionContract.MAX_DATA_KEYS then break end
        local val = rawData[key]
        if val == nil and type(rawResult.details) == "table" then
            val = rawResult.details[key]
        end
        if val ~= nil then
            local safe = sanitizeValue(val, 0)
            if safe ~= nil then
                publicData[key] = safe
                count = count + 1
            end
        end
    end

    local affected = nil
    if type(rawResult.affected) == "number" then
        affected = rawResult.affected
    elseif type(rawResult.affected) == "table" then
        affected = {}
        for i = 1, math.min(#rawResult.affected, ActionContract.MAX_AFFECTED) do
            local entry = sanitizeValue(rawResult.affected[i], 0)
            if entry ~= nil then affected[#affected + 1] = entry end
        end
    end

    return {
        requestID = tostring(requestID or rawResult.requestID or ""),
        actionID = contract and contract.id or rawResult.actionID,
        status = rawStatus,
        outcome = outcome,
        accepted = rawResult.accepted == true or outcome == "queued" or outcome == "accepted" or outcome == "completed" or outcome == "pending",
        reason = reason,
        reasonClass = reasonClass,
        target = sanitizeValue(rawResult.target, 0),
        affected = affected,
        data = publicData,
    }
end

function ActionContract.Execute(executeSpecOrID, context, options)
    options = type(options) == "table" and options or {}
    context = type(context) == "table" and context or {}
    if options.discoveryOnly == true then
        return {
            accepted = false,
            outcome = "rejected",
            reason = "action_execution_forbidden_in_discovery",
            duplicate = false,
            result = ActionContract.ProjectResult(nil, {
                accepted = false,
                status = "rejected",
                reason = "action_execution_forbidden_in_discovery",
            }, ""),
        }
    end

    local spec = type(executeSpecOrID) == "table" and executeSpecOrID
        or { use = tostring(executeSpecOrID or "") }
    local actionID = tostring(spec.use or "")
    local contract = ActionContract.Get(actionID)
    local adapter = ActionContract.Adapters[actionID]
    if not contract or type(adapter) ~= "function" then
        local proj = ActionContract.ProjectResult(nil, {
            accepted = false,
            status = "failed",
            reason = "action_contract_not_registered",
        }, options.requestID or context.requestID or "")
        return {
            accepted = false,
            outcome = proj.outcome,
            reason = "action_contract_not_registered",
            duplicate = false,
            result = proj,
        }
    end

    if contract.capability and type(context.capability) == "table" then
        if context.capability[contract.capability] == false then
            local proj = ActionContract.ProjectResult(contract, {
                accepted = false,
                status = "rejected",
                reason = "capability_denied",
            }, options.requestID or context.requestID or "")
            return {
                accepted = false,
                outcome = proj.outcome,
                reason = "capability_denied",
                duplicate = false,
                result = proj,
            }
        end
    end

    local exchangeKey = options.exchangeID or context.exchangeID
    if not exchangeKey and type(spec.idempotencyKey) == "string" then
        exchangeKey = resolveWithValue(spec.idempotencyKey, context)
    end
    if exchangeKey ~= nil and options.allowRetry ~= true then
        local existing = ActionContract.Instances["ex:" .. tostring(exchangeKey)]
        if existing then
            return {
                accepted = existing.result and existing.result.accepted == true,
                outcome = existing.outcome,
                requestID = existing.requestID,
                duplicate = true,
                stale = true,
                reason = "duplicate_exchange_execution",
                result = existing.result,
                instance = existing,
            }
        end
    end

    local resolvedArgs = {}
    local withSpec = type(spec.with) == "table" and spec.with or {}
    for k, v in pairs(withSpec) do
        resolvedArgs[k] = resolveWithValue(v, context)
    end
    for inputName, inputSpec in pairs(contract.inputs or {}) do
        local isTbl = type(inputSpec) == "table"
        local expectedType = isTbl and inputSpec.type or inputSpec
        if resolvedArgs[inputName] == nil and isTbl and inputSpec.source ~= nil then
            resolvedArgs[inputName] = resolveContextPath(context, inputSpec.source)
        end
        if isTbl and inputSpec.required == true and resolvedArgs[inputName] == nil then
            local proj = ActionContract.ProjectResult(contract, {
                accepted = false,
                status = "rejected",
                reason = "missing_required_input:" .. tostring(inputName),
            }, options.requestID or context.requestID or "")
            return {
                accepted = false,
                outcome = proj.outcome,
                reason = proj.reason,
                duplicate = false,
                result = proj,
            }
        end
        if resolvedArgs[inputName] ~= nil and not matchesInputType(resolvedArgs[inputName], expectedType) then
            local proj = ActionContract.ProjectResult(contract, {
                accepted = false,
                status = "rejected",
                reason = "invalid_input_type:" .. tostring(inputName),
            }, options.requestID or context.requestID or "")
            return {
                accepted = false,
                outcome = proj.outcome,
                reason = proj.reason,
                duplicate = false,
                result = proj,
            }
        end
    end

    ActionContract.Sequence = ActionContract.Sequence + 1
    local requestID = tostring(options.requestID or context.requestID
        or ("convo_act_" .. actionID .. "_" .. tostring(ActionContract.Sequence)))

    local instance = {
        requestID = requestID,
        exchangeKey = exchangeKey and tostring(exchangeKey) or nil,
        contractID = actionID,
        mode = contract.mode,
        outcome = "pending",
        status = "pending",
        dispatchCount = 1,
        terminal = false,
        seenPhases = {},
    }
    storeInstance(instance)

    local ok, rawResult = pcall(adapter, resolvedArgs, context, {
        requestID = requestID,
        exchangeKey = instance.exchangeKey,
        contract = contract,
    })
    if not ok then
        rawResult = {
            accepted = false,
            status = "failed",
            reason = "action_adapter_error",
        }
    end

    local projected = ActionContract.ProjectResult(contract, rawResult, requestID, options)
    instance.status = projected.status
    instance.outcome = projected.outcome
    instance.result = projected
    instance.seenPhases[projected.outcome] = true
    if ActionContract.TERMINAL_OUTCOMES[projected.outcome]
        or (contract.mode == "sync" and (projected.outcome == "accepted" or projected.outcome == "queued"))
    then
        instance.terminal = true
    end

    return {
        accepted = projected.accepted,
        outcome = projected.outcome,
        reason = projected.reason,
        requestID = requestID,
        duplicate = false,
        result = projected,
        instance = instance,
    }
end

function ActionContract.CompleteAsync(requestID, rawResult, options)
    options = type(options) == "table" and options or {}
    local reqKey = tostring(requestID or "")
    if reqKey == "" then
        return {
            accepted = false,
            stale = true,
            duplicate = false,
            reason = "request_id_missing",
        }
    end
    local instance = ActionContract.Instances[reqKey]
    if not instance then
        return {
            accepted = false,
            stale = true,
            duplicate = false,
            reason = "unknown_or_expired_request",
        }
    end
    if instance.terminal == true then
        return {
            accepted = false,
            stale = true,
            duplicate = true,
            reason = "duplicate_or_terminal_result",
            outcome = instance.outcome,
            result = instance.result,
        }
    end

    local contract = ActionContract.Get(instance.contractID)
    local projected = ActionContract.ProjectResult(contract, rawResult, reqKey, options)
    if instance.seenPhases[projected.outcome] == true then
        return {
            accepted = false,
            stale = true,
            duplicate = true,
            reason = "duplicate_outcome_phase",
            outcome = instance.outcome,
            result = instance.result,
        }
    end
    -- Guard against out-of-order regression from queued/accepted -> pending.
    if (instance.outcome == "queued" or instance.outcome == "accepted")
        and projected.outcome == "pending"
    then
        return {
            accepted = false,
            stale = true,
            duplicate = false,
            reason = "stale_pending_after_admission",
            outcome = instance.outcome,
            result = instance.result,
        }
    end

    instance.status = projected.status
    instance.outcome = projected.outcome
    instance.result = projected
    instance.seenPhases[projected.outcome] = true
    if ActionContract.TERMINAL_OUTCOMES[projected.outcome] then
        instance.terminal = true
    end

    return {
        accepted = true,
        duplicate = false,
        stale = false,
        requestID = reqKey,
        outcome = projected.outcome,
        result = projected,
        instance = instance,
    }
end

return ActionContract
