local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local SemanticExecution = require "worker/SemanticExecution"

local execution, reason = SemanticExecution.new({
    providerID = "DTAbstract",
    materializationMode = "abstract",
    capabilities = { "semantic.conversation" },
    context = { provider = "fixture" },
    callbacks = {
        buildContext = function(context)
            return { provider = context.provider }
        end,
        submitText = function(_, text)
            return { accepted = true, text = text }
        end,
        previewText = function(_, text)
            return { preview = text }
        end,
        submitFrame = function(_, frame)
            return { frame = frame }
        end,
        snapshot = function(context)
            return { provider = context.provider }
        end,
    },
})
assert(execution ~= nil and reason == nil,
    "semantic execution contract did not construct")
local description = execution:describe()
assert(description.schema == "semantic.harness_execution.v1"
    and description.materializationMode == "abstract",
    "semantic execution description lost provider mode")
assert(description.callbacks.submitText == true
    and description.callbacks.interaction == false,
    "semantic execution callback availability is incorrect")
assert(execution:buildContext().provider == "fixture",
    "semantic execution context callback failed")
assert(execution:submitText("hello").text == "hello",
    "semantic execution text callback failed")
assert(execution:previewText("draft").preview == "draft",
    "semantic execution preview callback failed")
assert(execution:submitFrame({ id = "choice-1" }).frame.id == "choice-1",
    "semantic execution frame callback failed")
assert(execution:snapshot().provider == "fixture",
    "semantic execution snapshot callback failed")
local missing, missingReason = execution:interaction("apply", {})
assert(missing == nil and missingReason == "callback_unavailable:interaction",
    "semantic execution missing callback did not fail closed")

local invalid, invalidReason = SemanticExecution.new({
    providerID = "ProjectHoomans",
    materializationMode = "invalid",
})
assert(invalid == nil and invalidReason == "invalid_materialization_mode",
    "semantic execution accepted an invalid provider mode")

print("psychopatz semantic harness execution: ok")
