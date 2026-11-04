-- Generic semantic actor input for the Core conversation shell.
--
-- Integrations provide the actor-service factory, bounded context, and result
-- hook through spec.actorConversation. Core owns the widget lifecycle,
-- player-history append, response queue, and choice restoration so adopters do
-- not grow separate conversation UI implementations.

require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Input = Conversation.ActorInput or {}
Conversation.ActorInput = Input

Input.VERSION = 1
Input.MAX_INPUT_LENGTH = 4000

local function tableValue(value)
    return type(value) == "table" and value or {}
end

local function configFor(view)
    return tableValue(view and view.spec
        and view.spec.actorConversation)
end

local function invoke(callback, ...)
    if type(callback) ~= "function" then return true, nil end
    local ok, first, second, third = pcall(callback, ...)
    if not ok then return false, "callback_failed", tostring(first) end
    return true, first, second, third
end

local function interactive(view)
    if not view or not view.session then return false end
    if type(view.isConversationInteractive) == "function" then
        return view:isConversationInteractive() == true
    end
    return view.closed ~= true
        and view.closing ~= true
        and view.session.busy ~= true
end

local function textValue(value)
    return tostring(value or "")
end

local function isBlank(value)
    value = textValue(value)
    value = string.gsub(value, "%s+", "")
    return value == ""
end

local function serviceFor(view)
    local session = view and view.session or nil
    if not session then return nil, "conversation_unavailable" end
    if session.actorConversationService then
        return session.actorConversationService
    end

    local config = configFor(view)
    if type(config.createService) ~= "function" then
        return nil, "actor_service_factory_unavailable"
    end
    local ok, service, reason = invoke(config.createService, view)
    if not ok then return nil, reason end
    if type(service) ~= "table" then
        return nil, reason or "actor_service_unavailable"
    end
    session.actorConversationService = service
    return service
end

local function contextFor(view)
    local config = configFor(view)
    if type(config.buildContext) == "function" then
        local ok, context, reason = invoke(config.buildContext, view)
        if not ok then return nil, reason end
        return tableValue(context)
    end
    return tableValue(view and view.spec and view.spec.context)
end

local function optionsFor(view, value, part)
    local config = configFor(view)
    if type(config.buildOptions) == "function" then
        local ok, options, reason = invoke(
            config.buildOptions, view, value, part)
        if not ok then return nil, reason end
        return tableValue(options)
    end
    return {}
end

local function appendPlayerInput(view, value, result)
    local session = view and view.session or nil
    if not session or type(session.append) ~= "function" then
        return false, "conversation_session_unavailable"
    end
    return session:append("player", value, {
        source = "actor_semantic_input",
        provenance = result and result.parts or nil,
    }) ~= nil
end

local function queueResponses(view, value, result, responses)
    local session = view and view.session or nil
    if not session then return false, "conversation_session_unavailable" end

    responses = type(responses) == "table" and responses or {}
    session.pendingChoices = session.currentNode
        and session.currentNode.choices or session.pendingChoices
    session.pendingNext = nil
    session.pendingClose = false
    session.pendingCloseReason = nil

    local queued = 0
    for _, response in ipairs(responses) do
        if response ~= nil then
            session:queueMessage("npc", response, {
                source = "actor_semantic_response",
                input = value,
                actorID = result and result.actorID,
            })
            queued = queued + 1
        end
    end
    if queued == 0 and type(session.finishPending) == "function" then
        session:finishPending()
    end
    return true, queued
end

function Input.GetService(view)
    return serviceFor(view)
end

function Input.GetState(view)
    if not view then
        return { visible = false, enabled = false, statusText = "" }
    end
    local session = view.session
    if not session then
        return { visible = true, enabled = false, statusText = "" }
    end
    if session.actorConversationPending == true then
        return {
            visible = true,
            enabled = false,
            statusText = "",
        }
    end
    local config = configFor(view)
    local status = type(config.statusText) == "function"
        and config.statusText(view) or config.statusText
    return {
        visible = true,
        enabled = interactive(view),
        statusText = status or "",
        sendKey = config.sendKey or "UI_PsychopatzConversation_Send",
    }
end

function Input.ResolveText(key, fallback)
    local text = Conversation.Text
    if text and type(text.Resolve) == "function" then
        return text.Resolve({ key = key, fallback = fallback }, fallback)
    end
    return fallback or key or ""
end

function Input.IsAvailable()
    return type(PsychopatzConversationLLMInput) == "table"
        and type(PsychopatzConversationLLMInput.new) == "function"
end

function Input.CreatePart(bounds, options)
    if not Input.IsAvailable() then return nil end
    options = tableValue(options)
    local definition = options.definition
    local definitionPartID = type(definition) == "table"
        and definition.partID or nil
    options.partID = options.partID or definitionPartID or "llmInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.title = options.title or {
        key = "UI_PsychopatzConversation_LLMInput",
        fallback = "TYPE TO TALK",
    }
    options.submit = options.submit or Input.Submit
    options.getState = options.getState or Input.GetState
    options.resolveText = options.resolveText or Input.ResolveText
    options.maxInputLength = options.maxInputLength
        or Input.MAX_INPUT_LENGTH
    options.submitOnEnter = options.submitOnEnter ~= false
    options.tooltipKey = options.tooltipKey
        or "UI_PsychopatzConversation_LLMInputTooltip"
    options.sendKey = options.sendKey
        or "UI_PsychopatzConversation_Send"
    options.sendTitle = options.sendTitle or "SEND"
    return PsychopatzConversationLLMInput:new(
        bounds.x, bounds.y, bounds.width, bounds.height, options
    )
end

function Input.Submit(view, value, part)
    value = textValue(value)
    if isBlank(value) then return false, "utterance_required" end
    if not interactive(view) then return false, "conversation_not_interactive" end

    local session = view and view.session or nil
    if not session or session.actorConversationPending == true then
        return false, "actor_conversation_pending"
    end
    session.actorConversationPending = true

    local service, serviceReason = serviceFor(view)
    local context, contextReason = contextFor(view)
    local options, optionsReason = optionsFor(view, value, part)
    if not service or not context or not options then
        session.actorConversationPending = nil
        local config = configFor(view)
        invoke(config.onRejected, view, value,
            serviceReason or contextReason or optionsReason)
        return false, serviceReason or contextReason
            or optionsReason or "actor_conversation_unavailable"
    end

    local result, reason = service:Submit(value, context, options)
    session.actorConversationPending = nil
    if type(result) ~= "table" or result.accepted ~= true then
        local config = configFor(view)
        invoke(config.onRejected, view, value,
            reason or result and result.reason or "semantic_rejected")
        return false, reason or result and result.reason
            or "semantic_rejected"
    end

    local config = configFor(view)
    local ok, handled, responseOverride = invoke(
        config.onResult, view, value, result, service)
    if not ok then
        invoke(config.onRejected, view, value, handled)
        return false, handled or "semantic_result_handler_failed"
    end
    if handled == false then
        return false, responseOverride or "semantic_result_rejected"
    end

    if not appendPlayerInput(view, value, result) then
        return false, "conversation_history_unavailable"
    end

    local responses = result.responses
    if type(responseOverride) == "table" then
        responses = responseOverride
    end
    local queued, queueReason = queueResponses(
        view, value, result, responses)
    if not queued then return false, queueReason end

    if type(config.onPresented) == "function" then
        invoke(config.onPresented, view, value, result, service)
    end
    return true
end

return Input
