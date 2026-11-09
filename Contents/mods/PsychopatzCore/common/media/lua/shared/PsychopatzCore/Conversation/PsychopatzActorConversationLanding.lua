-- Provider-neutral actor conversation landing builder.
--
-- Core owns the landing mechanism: select the applicable semantic greeting,
-- collect capability-gated actions, and compose one stable set of native
-- conversation choices. Adopters supply content and effects through the
-- callbacks in the build spec; Core never names an adopter or a gameplay
-- action.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Landing = {}
PsychopatzCore.Conversation.ActorLanding = Landing

local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"

local function textForAction(action)
    if type(action) ~= "table" then return nil end
    if action.text ~= nil then return action.text end
    if action.textKey ~= nil then
        return {
            key = action.textKey,
            domain = action.textDomain,
            args = action.textArgs,
        }
    end
    return action.fallbackText or action.label or action.id
end

local function greetingFor(spec, block, context)
    if type(spec.resolveGreeting) == "function" then
        local resolved = spec.resolveGreeting(block, context)
        if resolved ~= nil then return resolved end
    end

    if type(spec.npc) == "function" then
        return spec.npc(block, context)
    end
    if spec.npc ~= nil then return spec.npc end

    local node = block and block.nodes
        and block.nodes[block.entryNode or "opening"] or nil
    if type(node) == "table" then
        if node.npc ~= nil then return node.npc end
        if node.message ~= nil then return node.message end
        if node.textKey ~= nil then
            return {
                key = node.textKey,
                domain = node.textDomain,
                args = node.textArgs,
                text = node.fallback or node.text,
            }
        end
        if node.fallback ~= nil then return node.fallback end
        if node.text ~= nil then return node.text end
    end
    return spec.greetingFallback
end

local function appendStaticChoices(output, spec, context, landingID)
    local authored = spec.choices
    if type(authored) == "function" then
        authored = authored(context)
    end
    if type(authored) ~= "table" then return end

    for index = 1, #authored do
        local choice = authored[index]
        if type(choice) == "table" then
            if choice.next == nil and choice.close ~= true then
                choice.next = landingID
            end
            if choice.order == nil then choice.order = 100 + index end
            choice._landingIndex = #output + 1
            output[#output + 1] = choice
        end
    end
end

local function appendActionChoices(output, actions, spec, context, landingID)
    for index = 1, #actions do
        local action = actions[index]
        local choice
        if type(spec.actionChoice) == "function" then
            choice = spec.actionChoice(action, context)
        else
            choice = {
                id = action.id,
                text = textForAction(action),
            }
        end

        if type(choice) == "table" then
            if choice.id == nil then choice.id = action.id end
            if choice.text == nil and choice.textKey == nil then
                choice.text = textForAction(action)
            end
            if choice.next == nil and choice.close ~= true then
                choice.next = landingID
            end
            if choice.order == nil then
                choice.order = tonumber(action.order) or 50 + index
            end
            choice.sourceActionID = action.id
            choice.sourceAction = action
            choice._landingIndex = #output + 1
            output[#output + 1] = choice
        end
    end
end

local function choiceOrder(left, right)
    local leftOrder = tonumber(left.order) or 100
    local rightOrder = tonumber(right.order) or 100
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    if tostring(left.id) ~= tostring(right.id) then
        return tostring(left.id) < tostring(right.id)
    end
    return (left._landingIndex or 0) < (right._landingIndex or 0)
end

function Landing.Build(spec)
    spec = type(spec) == "table" and spec or {}
    local context = type(spec.context) == "table" and spec.context or {}
    local landingID = tostring(spec.landingID or "landing")
    local category = tostring(spec.greetingCategory or "greeting")

    local block, blockReason = Semantics.SelectDialogueBlock(
        category,
        context,
        spec.seed or context.actorID or context.npcID or landingID
    )
    local actions = Semantics.CollectActions(context, {
        strictCapabilities = spec.strictCapabilities ~= false,
    })

    if type(spec.actionFilter) == "function" then
        local filtered = {}
        for index = 1, #actions do
            if spec.actionFilter(actions[index], context) == true then
                filtered[#filtered + 1] = actions[index]
            end
        end
        actions = filtered
    end

    local choices = {}
    appendActionChoices(choices, actions, spec, context, landingID)
    appendStaticChoices(choices, spec, context, landingID)
    table.sort(choices, choiceOrder)

    for index = 1, #choices do
        choices[index]._landingIndex = nil
    end

    return {
        start = landingID,
        nodes = {
            [landingID] = {
                npc = greetingFor(spec, block, context),
                choices = choices,
            },
        },
        actions = actions,
        greetingBlock = block,
        greetingReason = blockReason,
    }
end

return Landing
