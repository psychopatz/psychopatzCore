-- ConvoEngine: hand-written
-- Bounded clause composition for ConvoEngine realization.
local ClausePlan = {
    MAX_CLAUSES = 3,
    MAX_MODIFIERS = 4,
    MAX_REFERENTS = 4,
}

local RELATIONS = {
    ADD = true, CONTRAST = true, CAUSE = true, CONSEQUENCE = true,
    SEQUENCE = true, CONDITION = true, EXPLANATION = true,
}

local function semanticID(value)
    return type(value) == "string" and #value <= 96 and string.match(value, "^[%w_.:%-]+$") ~= nil
end

local function copyReferent(value)
    if type(value) ~= "table" or not semanticID(value.id) or not semanticID(value.kind) then return nil end
    return { id = value.id, kind = value.kind }
end

local function remember(focus, referent)
    for i = 1, #focus do
        local prior = focus[i]
        if prior.id == referent.id and prior.kind == referent.kind then table.remove(focus, i); break end
    end
    if #focus >= ClausePlan.MAX_REFERENTS then table.remove(focus, 1) end
    focus[#focus + 1] = referent
end

local function referenceMode(focus, referent)
    local count, found = 0, false
    for i = 1, #focus do
        if focus[i].kind == referent.kind then
            count = count + 1
            if focus[i].id == referent.id then found = true end
        end
    end
    if count == 1 and found then return "reference" end
    return "explicit", count > 1 and "REFERENCE_AMBIGUOUS" or nil
end

function ClausePlan.Normalize(spec)
    if type(spec) ~= "table" or type(spec.clauses) ~= "table"
        or #spec.clauses == 0 or #spec.clauses > ClausePlan.MAX_CLAUSES then
        return nil, "clause_count_invalid"
    end
    local plan = { clauses = {}, focus = {} }
    local focus = spec.focus or {}
    if type(focus) ~= "table" or #focus > ClausePlan.MAX_REFERENTS then return nil, "focus_invalid" end
    for i = 1, #focus do
        local referent = copyReferent(focus[i])
        if not referent then return nil, "referent_invalid" end
        remember(plan.focus, referent)
    end

    local modifierCount = 0
    for i = 1, #spec.clauses do
        local clause = spec.clauses[i]
        if type(clause) ~= "table" or not semanticID(clause.strategy) then return nil, "clause_invalid" end
        if (i == 1 and clause.relation ~= nil) or (i > 1 and not RELATIONS[clause.relation]) then
            return nil, "relation_invalid"
        end
        local entry = {
            strategy = clause.strategy, relation = clause.relation, modifiers = {}, claims = {},
            referenceAmbiguous = clause.referenceAmbiguous == true,
        }
        for _, field in ipairs({ "introduces", "reference" }) do
            if clause[field] ~= nil then
                entry[field] = copyReferent(clause[field])
                if not entry[field] then return nil, "referent_invalid" end
            end
        end
        local modifiers, claims = clause.modifiers or {}, clause.claims or {}
        if type(modifiers) ~= "table" or modifierCount + #modifiers > ClausePlan.MAX_MODIFIERS then
            return nil, "modifier_count_invalid"
        end
        for j = 1, #modifiers do
            if not semanticID(modifiers[j]) then return nil, "modifier_invalid" end
            entry.modifiers[j] = modifiers[j]
        end
        modifierCount = modifierCount + #modifiers
        if type(claims) ~= "table" or #claims > 4 then return nil, "claim_count_invalid" end
        for j = 1, #claims do
            if not semanticID(claims[j]) then return nil, "claim_invalid" end
            entry.claims[j] = claims[j]
        end
        plan.clauses[i] = entry
    end
    return plan
end

function ClausePlan.Realize(plan, renderClause, renderRelation)
    local focus, clauses, relations, text = {}, {}, {}, nil
    for i = 1, #plan.focus do focus[i] = plan.focus[i] end
    for i = 1, #plan.clauses do
        local clause, mode, diagnostic = plan.clauses[i], nil, nil
        if clause.referenceAmbiguous then
            mode, diagnostic = "explicit", "REFERENCE_AMBIGUOUS"
        elseif clause.reference then
            mode, diagnostic = referenceMode(focus, clause.reference)
        end
        local result, failure = renderClause(clause, mode, i)
        if not result then return nil, failure end
        clauses[i] = {
            constructionID = result.constructionID, lexemeIDs = result.lexemeIDs,
            claims = clause.claims, modifiers = clause.modifiers,
            introduces = clause.introduces, refersTo = clause.reference,
            referenceMode = mode, diagnostic = diagnostic,
        }
        if i == 1 then
            text = result.text
        else
            local joined, why = renderRelation(clause.relation, text, result.text)
            if not joined then return nil, why end
            text = joined.text
            relations[#relations + 1] = { relation = clause.relation, constructionID = joined.constructionID }
        end
        if clause.introduces then remember(focus, clause.introduces) end
    end
    return { text = text, clauses = clauses, relations = relations, focus = focus }
end

return ClausePlan
