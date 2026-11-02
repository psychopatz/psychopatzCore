-- Generic, reusable semantic dialogue flow and condition evaluator for PsychopatzCore.
--
-- Provides gate evaluation (numeric, string, relationship, capability) and
-- deterministic weighted outcome selection without any game-specific or adopter policy.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Flow = {}
PsychopatzCore.Semantics.DialogueFlow = Flow

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local function compare(actual, op, expected)
    op = op or "=="
    if op == "==" then
        return tostring(actual or "") == tostring(expected or "")
    elseif op == "~=" then
        return tostring(actual or "") ~= tostring(expected or "")
    end

    local numActual = tonumber(actual)
    local numExpected = tonumber(expected)
    if numActual == nil or numExpected == nil then return false end

    if op == ">=" then return numActual >= numExpected
    elseif op == "<=" then return numActual <= numExpected
    elseif op == ">" then return numActual > numExpected
    elseif op == "<" then return numActual < numExpected
    end
    return false
end

local function getNestedField(root, path)
    if type(root) ~= "table" or type(path) ~= "string" then return nil end
    local current = root
    for token in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[token]
    end
    return current
end

function Flow.Compare(actual, op, expected)
    return compare(actual, op, expected)
end

function Flow.GetField(root, path)
    return getNestedField(root, path)
end

function Flow.EvaluateGate(gate, context)
    if type(gate) ~= "table" then return true end
    context = type(context) == "table" and context or {}

    -- Capability gate
    if gate.capabilityRequired then
        local caps = context.capabilities
        if type(caps) ~= "table" or caps[gate.capabilityRequired] ~= true then
            return false, "capability_missing"
        end
    end

    -- Field comparison gate
    local path = gate.field or gate.path or gate.key
    if path then
        local actual = getNestedField(context, path)
        -- Convenience fallback: check context.actor or context.relationship directly
        if actual == nil and context.actor and type(context.actor) == "table" then
            actual = getNestedField(context.actor, path)
        end
        if actual == nil and context.actor and context.actor.relationship then
            actual = getNestedField(context.actor.relationship, path)
        end

        local expected = gate.value ~= nil and gate.value or gate.expected
        local op = gate.operator or gate.op or "=="
        if not compare(actual, op, expected) then
            return false, gate.failReason or "condition_mismatch"
        end
    end

    return true
end

function Flow.EvaluateGates(gates, context)
    if type(gates) ~= "table" then return true end
    for index = 1, #gates do
        local ok, reason = Flow.EvaluateGate(gates[index], context)
        if not ok then return false, reason end
    end
    return true
end

function Flow.FilterChoices(choices, context)
    if type(choices) ~= "table" then return {} end
    context = type(context) == "table" and context or {}
    local caps = context.capabilities
    local output = {}

    for index = 1, #choices do
        local choice = choices[index]
        if type(choice) == "table" then
            local allowed = true
            -- Check choice capability
            if choice.capabilityRequired and caps ~= nil then
                if caps[choice.capabilityRequired] ~= true then
                    allowed = false
                end
            end
            -- Check choice gates
            if allowed and choice.gates then
                allowed = Flow.EvaluateGates(choice.gates, context)
            end

            if allowed then
                output[#output + 1] = Util.clone(choice)
            end
        end
    end

    return output
end

function Flow.ResolveOutcome(choice, context, seed)
    if type(choice) ~= "table" then return nil end
    local outcomes = choice.outcomes
    if type(outcomes) ~= "table" or #outcomes == 0 then
        return {
            id = "default",
            text = choice.text,
            textKey = choice.textKey,
            responseKey = choice.responseKey,
            next = choice.next or "$root",
        }
    end

    local eligible = {}
    local totalWeight = 0
    for index = 1, #outcomes do
        local outcome = outcomes[index]
        if type(outcome) == "table" then
            local allowed = true
            if outcome.gates then
                allowed = Flow.EvaluateGates(outcome.gates, context)
            end
            if allowed then
                local weight = math.max(1, tonumber(outcome.weight) or 100)
                eligible[#eligible + 1] = {
                    outcome = outcome,
                    weight = weight,
                }
                totalWeight = totalWeight + weight
            end
        end
    end

    if #eligible == 0 then
        return outcomes[1]
    end

    if #eligible == 1 then
        return eligible[1].outcome
    end

    -- Deterministic weighted selection using seed
    local hash = Util.hash(tostring(seed or "flow_seed") .. ":" .. tostring(choice.id or ""))
    local roll = (hash % totalWeight) + 1
    local current = 0
    for index = 1, #eligible do
        current = current + eligible[index].weight
        if roll <= current then
            return eligible[index].outcome
        end
    end

    return eligible[#eligible].outcome
end

return Flow
