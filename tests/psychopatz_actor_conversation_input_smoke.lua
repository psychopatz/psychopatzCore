local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/client/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {
    Conversation = {
        Text = {
            Resolve = function(_, value, fallback)
                return value.fallback or fallback or value.key
            end,
        },
    },
}

local widget = {}
package.preload[
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
] = function()
    PsychopatzConversationLLMInput = {
        new = function(_, x, y, width, height, options)
            widget = {
                x = x,
                y = y,
                width = width,
                height = height,
                options = options,
            }
            return widget
        end,
    }
    return PsychopatzConversationLLMInput
end

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Input = require
    "PsychopatzCore/UI/Conversation/PsychopatzActorConversationInput"

local serviceCalls = 0
local resultHooks = 0
local history = {}
local queued = {}
local choices = {
    { id = "trade", text = "Trade" },
}

local view = {
    spec = {
        actorConversation = {
            createService = function()
                serviceCalls = serviceCalls + 1
                return {
                    Submit = function(_, value, context, options)
                        equal(value, "where are you heading", "utterance")
                        equal(context.traderID, "trader:input", "context")
                        equal(options.mode, "test", "options")
                        return {
                            accepted = true,
                            actorID = "actor:input",
                            parts = {},
                            responses = {
                                { text = "Rosewood Outpost." },
                            },
                        }
                    end,
                }
            end,
            buildContext = function()
                return { traderID = "trader:input" }
            end,
            buildOptions = function()
                return { mode = "test" }
            end,
            onResult = function(_, value, result)
                equal(value, "where are you heading", "result input")
                truthy(result.accepted, "result hook result")
                resultHooks = resultHooks + 1
            end,
        },
    },
    session = {
        busy = false,
        currentNode = { choices = choices },
        append = function(_, speaker, value, metadata)
            history[#history + 1] = {
                speaker = speaker,
                value = value,
                metadata = metadata,
            }
            return history[#history]
        end,
        queueMessage = function(_, speaker, value, metadata)
            queued[#queued + 1] = {
                speaker = speaker,
                value = value,
                metadata = metadata,
            }
        end,
    },
    isConversationInteractive = function()
        return true
    end,
}

local state = Input.GetState(view)
truthy(state.visible, "input visible")
truthy(state.enabled, "input enabled")

local created = Input.CreatePart(
    { x = 4, y = 8, width = 320, height = 90 },
    { definition = { partID = "llmInput" } }
)
equal(created, widget, "input widget created")
equal(widget.x, 4, "widget x")
equal(widget.options.partID, "llmInput", "widget part id")
equal(widget.options.maxInputLength, 4000, "bounded input length")

local accepted, reason = Input.Submit(
    view, "where are you heading", created)
truthy(accepted, reason)
equal(serviceCalls, 1, "service created once")
equal(resultHooks, 1, "result hook invoked")
equal(#history, 1, "player input appended")
equal(history[1].speaker, "player", "history speaker")
equal(#queued, 1, "response queued")
equal(queued[1].speaker, "npc", "response speaker")
equal(queued[1].value.text, "Rosewood Outpost.", "response payload")
equal(view.session.pendingChoices, choices, "choices restored")
equal(view.session.actorConversationPending, nil, "pending flag cleared")

view.session.actorConversationPending = true
local blocked, blockedReason = Input.Submit(view, "hello", created)
equal(blocked, false, "pending submission blocked")
equal(blockedReason, "actor_conversation_pending", "pending reason")

print("psychopatz_actor_conversation_input_smoke: PASS")
