local Registry = PsychopatzCore.Conversation.Registry
local Internal = Registry.Internal

function Internal.ValidateAudiences(audiences, errors)
    local audienceIDs = {}
    local index
    local audience
    if type(audiences) ~= "table" or #audiences == 0 then
        Internal.AddError(
            errors,
            "audiences must contain at least one audience"
        )
        return
    end
    for index, audience in ipairs(audiences) do
        if not Internal.ValidAudiences[audience] then
            Internal.AddError(
                errors,
                "audiences[" .. tostring(index) .. "] is invalid"
            )
        elseif audienceIDs[audience] then
            Internal.AddError(
                errors,
                "audiences contains duplicate " .. audience
            )
        end
        audienceIDs[audience] = true
    end
end

local function validateNodeText(node, errors, nodePath)
    local textIndex
    local textKey
    if node.textKey ~= nil and type(node.textKey) ~= "string" then
        Internal.AddError(
            errors,
            nodePath .. ".textKey must be a string"
        )
    end
    if node.textKeys ~= nil then
        if type(node.textKeys) ~= "table" or #node.textKeys == 0 then
            Internal.AddError(
                errors,
                nodePath .. ".textKeys must contain keys"
            )
        else
            for textIndex, textKey in ipairs(node.textKeys) do
                if type(textKey) ~= "string" or textKey == "" then
                    Internal.AddError(
                        errors,
                        nodePath .. ".textKeys["
                            .. tostring(textIndex) .. "] is invalid"
                    )
                end
            end
        end
    end
    if node.textKey == nil and node.textKeys == nil then
        Internal.AddError(
            errors,
            nodePath .. " requires textKey or textKeys"
        )
    end
end

local function validateOutcome(
    outcome,
    outcomePath,
    definition,
    outcomeIDs,
    errors
)
    if type(outcome) ~= "table"
        or type(outcome.id) ~= "string"
        or outcome.id == ""
    then
        Internal.AddError(errors, outcomePath .. " requires an id")
    end
    if type(outcome) ~= "table" then return end
    if type(outcome.id) == "string" then
        if outcomeIDs[outcome.id] then
            Internal.AddError(
                errors,
                outcomePath .. ".id is duplicated"
            )
        end
        outcomeIDs[outcome.id] = true
    end
    if (tonumber(outcome.weight) or 0) <= 0 then
        Internal.AddError(
            errors,
            outcomePath .. ".weight must be positive"
        )
    end
    if type(outcome.responseKey) ~= "string"
        or outcome.responseKey == ""
    then
        Internal.AddError(
            errors,
            outcomePath .. ".responseKey is required"
        )
    end
    if outcome.next == nil and outcome.close ~= true then
        Internal.AddError(
            errors,
            outcomePath .. " requires next or close"
        )
    end
    if outcome.next ~= nil
        and outcome.next ~= "$root"
        and not definition.nodes[outcome.next]
    then
        Internal.AddError(errors, outcomePath .. ".next is dangling")
    end
    if outcome.next ~= nil and outcome.close == true then
        Internal.AddError(
            errors,
            outcomePath .. " cannot both next and close"
        )
    end
    Internal.ValidateGates(
        outcome.gates,
        errors,
        outcomePath .. ".gates"
    )
    Internal.ValidateEffects(
        outcome.effects,
        errors,
        outcomePath .. ".effects"
    )
end

local function validateChoice(
    choice,
    choicePath,
    definition,
    choiceIDs,
    errors
)
    local outcomeIDs = {}
    local outcomes
    local outcomeIndex
    local outcome
    if type(choice) ~= "table"
        or type(choice.id) ~= "string"
        or choice.id == ""
    then
        Internal.AddError(errors, choicePath .. " requires an id")
        return
    end
    if choiceIDs[choice.id] then
        Internal.AddError(errors, choicePath .. ".id is duplicated")
    end
    choiceIDs[choice.id] = true
    if type(choice.textKey) ~= "string" or choice.textKey == "" then
        Internal.AddError(
            errors,
            choicePath .. ".textKey is required"
        )
    end
    if choice.lockedMode ~= nil
        and choice.lockedMode ~= "hidden"
        and choice.lockedMode ~= "disabled"
    then
        Internal.AddError(
            errors,
            choicePath .. ".lockedMode is invalid"
        )
    end
    if choice.lockedMode == "disabled"
        and (
            type(choice.lockedReasonKey) ~= "string"
            or choice.lockedReasonKey == ""
        )
    then
        Internal.AddError(
            errors,
            choicePath
                .. ".lockedReasonKey is required when disabled"
        )
    end
    Internal.ValidateGates(choice.gates, errors, choicePath .. ".gates")
    Internal.ValidateRepeat(
        choice["repeat"],
        errors,
        choicePath .. ".repeat"
    )
    if type(choice.outcomes) ~= "table" or #choice.outcomes == 0 then
        Internal.AddError(
            errors,
            choicePath .. ".outcomes are required"
        )
    end
    outcomes =
        type(choice.outcomes) == "table" and choice.outcomes or {}
    for outcomeIndex, outcome in ipairs(outcomes) do
        validateOutcome(
            outcome,
            choicePath .. ".outcomes[" .. tostring(outcomeIndex) .. "]",
            definition,
            outcomeIDs,
            errors
        )
    end
end

local function validateNode(
    nodeID,
    node,
    definition,
    nodeIDs,
    errors
)
    local nodePath = "nodes." .. tostring(nodeID)
    local choices = {}
    local choiceIDs = {}
    local choiceIndex
    local choice
    if type(nodeID) ~= "string" or nodeID == "" then
        Internal.AddError(errors, nodePath .. " has an invalid id")
    elseif nodeIDs[nodeID] then
        Internal.AddError(errors, nodePath .. " is duplicated")
    else
        nodeIDs[nodeID] = true
    end
    if type(node) ~= "table" then
        Internal.AddError(errors, nodePath .. " must be a table")
        return
    end
    validateNodeText(node, errors, nodePath)
    Internal.ValidateGates(node.gates, errors, nodePath .. ".gates")
    if node.choices ~= nil and type(node.choices) ~= "table" then
        Internal.AddError(
            errors,
            nodePath .. ".choices must be a table"
        )
    elseif type(node.choices) == "table" then
        choices = node.choices
    end
    for choiceIndex, choice in ipairs(choices) do
        validateChoice(
            choice,
            nodePath .. ".choices[" .. tostring(choiceIndex) .. "]",
            definition,
            choiceIDs,
            errors
        )
    end
end

function Internal.ValidateNodes(definition, errors)
    local nodeIDs = {}
    local nodeID
    local node
    if type(definition.nodes) ~= "table" then
        Internal.AddError(errors, "nodes are required")
        return
    end
    if not definition.nodes[definition.entryNode] then
        Internal.AddError(errors, "entryNode does not exist")
        return
    end
    for nodeID, node in pairs(definition.nodes) do
        validateNode(nodeID, node, definition, nodeIDs, errors)
    end
end
