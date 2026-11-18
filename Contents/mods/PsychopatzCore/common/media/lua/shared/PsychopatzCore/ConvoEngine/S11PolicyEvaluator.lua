-- ConvoEngine: hand-written
-- S11A3 generic ConvoEngine policy, role-binding, query, and consequence evaluator.
-- Consumes compiled Portable Dialogue Plan / runtime plan structures directly.
-- Kahlua2-safe (Lua 5.1 compatible).

local Predicate = require "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"

local S11PolicyEvaluator = {}

local FORBIDDEN_POSITIONAL_ROLES = {
    actor1 = true,
    actor2 = true,
    actor3 = true,
    speaker1 = true,
    speaker2 = true,
    speaker3 = true,
    npc1 = true,
    npc2 = true,
}

local function copyArray(list)
    local out = {}
    if type(list) ~= "table" then
        return out
    end
    for i = 1, #list do
        out[i] = list[i]
    end
    return out
end

local function appendAll(dst, src)
    if type(src) ~= "table" then
        return
    end
    for i = 1, #src do
        dst[#dst + 1] = src[i]
    end
end

local function readContextPath(context, path)
    if type(context) ~= "table" or type(path) ~= "string" or path == "" then
        return nil
    end
    local current = context
    for segment in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[segment]
        if current == nil then
            return nil
        end
    end
    return current
end

local function kindAllowed(entityKind, allowedKinds)
    if type(allowedKinds) ~= "table" or #allowedKinds == 0 then
        return true
    end
    for i = 1, #allowedKinds do
        if allowedKinds[i] == entityKind then
            return true
        end
    end
    return false
end

function S11PolicyEvaluator.ValidateRoleBindings(roleSpecs, roleBindings, participantSet)
    local bindings = type(roleBindings) == "table" and roleBindings or {}
    if type(participantSet) == "table" then
        local maxSize = participantSet.maxSize
        local parts = participantSet.participants
        if type(maxSize) == "number" and type(parts) == "table" and #parts > maxSize then
            return {
                ok = false,
                reason = "participant_set_exceeds_max_size",
            }
        end
    end

    for roleName, _ in pairs(bindings) do
        if FORBIDDEN_POSITIONAL_ROLES[roleName] then
            return {
                ok = false,
                reason = "forbidden_positional_role:" .. tostring(roleName),
            }
        end
    end

    local specs = type(roleSpecs) == "table" and roleSpecs or {}
    local boundRoles = {}
    for roleName, spec in pairs(specs) do
        if FORBIDDEN_POSITIONAL_ROLES[roleName] then
            return {
                ok = false,
                reason = "forbidden_positional_role:" .. tostring(roleName),
            }
        end
        local entities = bindings[roleName]
        if type(entities) ~= "table" then
            entities = {}
        end
        local count = #entities
        local card = type(spec) == "table" and tostring(spec.cardinality or "ONE") or "ONE"

        if card == "ONE" and count ~= 1 then
            return { ok = false, reason = "role_cardinality_mismatch:" .. roleName .. ":ONE" }
        elseif card == "OPTIONAL_ONE" and count > 1 then
            return { ok = false, reason = "role_cardinality_mismatch:" .. roleName .. ":OPTIONAL_ONE" }
        elseif card == "ONE_OR_MORE" and count < 1 then
            return { ok = false, reason = "role_cardinality_mismatch:" .. roleName .. ":ONE_OR_MORE" }
        elseif card == "BOUNDED_MANY" then
            local lo = tonumber(spec.min) or 0
            local hi = tonumber(spec.max) or count
            if count < lo or count > hi then
                return { ok = false, reason = "role_cardinality_mismatch:" .. roleName .. ":BOUNDED_MANY" }
            end
        end

        local allowedKinds = type(spec) == "table" and spec.kinds or nil
        for i = 1, count do
            local ent = entities[i]
            local entKind = type(ent) == "table" and ent.kind or nil
            if not kindAllowed(entKind, allowedKinds) then
                return { ok = false, reason = "role_entity_kind_mismatch:" .. roleName }
            end
        end
        boundRoles[roleName] = count
    end

    local out = {
        ok = true,
        reason = "roles_valid",
    }
    for _, _ in pairs(boundRoles) do
        out.boundRoles = boundRoles
        break
    end
    return out
end

function S11PolicyEvaluator.EvaluateStatePolicy(planEntry, context)
    local familyId = type(planEntry) == "table" and tostring(planEntry.id or "") or ""
    local rules = type(planEntry) == "table" and planEntry.statePolicy or nil
    local postconditions = copyArray(type(planEntry) == "table" and planEntry.postconditions or nil)
    local ctx = type(context) == "table" and context or {}

    if type(rules) ~= "table" or #rules == 0 then
        local out = {
            familyId = familyId,
            matchedRuleId = "default_actionable",
            outcome = "actionable",
            reason = "ready",
            admission = "dispatch",
            stateChanged = false,
        }
        if #postconditions > 0 then
            out.postconditions = postconditions
        end
        return out
    end

    for i = 1, #rules do
        local rule = rules[i]
        if type(rule) == "table" then
            local matched = true
            if rule.when ~= nil then
                local evalRes = Predicate.Evaluate(rule.when, ctx)
                matched = type(evalRes) == "table" and evalRes.allowed == true
            end
            if matched then
                local out = {
                    familyId = familyId,
                    matchedRuleId = tostring(rule.id or ""),
                    outcome = tostring(rule.outcome or "actionable"),
                    reason = tostring(rule.reason or rule.outcome or "ready"),
                    admission = tostring(rule.admission or "dispatch"),
                    stateChanged = false,
                }
                if #postconditions > 0 then
                    out.postconditions = postconditions
                end
                if rule.replyOutcome ~= nil then
                    out.replyOutcome = tostring(rule.replyOutcome)
                end
                return out
            end
        end
    end

    local out = {
        familyId = familyId,
        matchedRuleId = "default_unavailable",
        outcome = "unavailable",
        reason = "no_state_rule_matched",
        admission = "no_op",
        stateChanged = false,
    }
    if #postconditions > 0 then
        out.postconditions = postconditions
    end
    return out
end

function S11PolicyEvaluator.EvaluateQueries(planEntry, context)
    local queries = type(planEntry) == "table" and planEntry.queries or nil
    local ctx = type(context) == "table" and context or {}
    local results = {}
    if type(queries) ~= "table" then
        return results
    end
    for i = 1, #queries do
        local q = queries[i]
        if type(q) == "table" and type(q.id) == "string" then
            local actual = readContextPath(ctx, q.path)
            if actual == nil and q.default ~= nil then
                actual = q.default
            end
            local passed = actual ~= nil
            if q.op ~= nil then
                local predRes = Predicate.Evaluate({
                    path = q.path,
                    op = q.op,
                    value = q.value,
                }, ctx)
                passed = type(predRes) == "table" and predRes.allowed == true
            end
            results[#results + 1] = {
                id = q.id,
                path = q.path,
                value = actual,
                passed = passed,
            }
        end
    end
    return results
end

function S11PolicyEvaluator.ProjectConsequences(planEntry, replyOutcome)
    local effects = {}
    local modifiers = {}
    local postconditions = {}
    local closure = { closureClass = "none" }
    local continuation = "close"

    if type(planEntry) ~= "table" then
        return {
            effects = effects,
            modifiers = modifiers,
            postconditions = postconditions,
            closure = closure,
            continuation = continuation,
        }
    end

    appendAll(effects, planEntry.effects)
    appendAll(modifiers, planEntry.modifiers)
    appendAll(postconditions, planEntry.postconditions)
    if type(planEntry.closure) == "table" then
        closure = planEntry.closure
    end
    if planEntry.continuation ~= nil then
        continuation = planEntry.continuation
    end

    if type(replyOutcome) == "string" and replyOutcome ~= "" and type(planEntry.reply) == "table" then
        local branch = planEntry.reply[replyOutcome]
        if type(branch) == "table" then
            appendAll(effects, branch.effects)
            appendAll(modifiers, branch.modifiers)
            appendAll(postconditions, branch.postconditions)
            if type(branch.closure) == "table" then
                closure = branch.closure
            end
        end
    end

    return {
        effects = effects,
        modifiers = modifiers,
        postconditions = postconditions,
        closure = closure,
        continuation = continuation,
    }
end

function S11PolicyEvaluator.EvaluateFamily(planEntry, context, roleBindings, participantSet, replyOutcome)
    local roleCheck = S11PolicyEvaluator.ValidateRoleBindings(
        type(planEntry) == "table" and planEntry.roles or nil,
        roleBindings,
        participantSet or (type(planEntry) == "table" and planEntry.participantSet or nil)
    )
    local stateOutcome = S11PolicyEvaluator.EvaluateStatePolicy(planEntry, context)
    local effectiveReply = replyOutcome
    if (effectiveReply == nil or effectiveReply == "") and stateOutcome.replyOutcome ~= nil then
        effectiveReply = stateOutcome.replyOutcome
    end
    local queryResults = S11PolicyEvaluator.EvaluateQueries(planEntry, context)
    local consequences = S11PolicyEvaluator.ProjectConsequences(planEntry, effectiveReply)
    return {
        roleValidation = roleCheck,
        stateOutcome = stateOutcome,
        queries = queryResults,
        consequences = consequences,
    }
end

return S11PolicyEvaluator
