-- Minimal Core-only semantic harness worker.
--
-- This is the first executable migration seam. It intentionally loads only
-- PsychopatzCore and provides a small lifecycle surface while the full
-- authoring/runtime application moves behind the provider registry.

local coreRepository = arg[1]
    or os.getenv("SEMANTIC_HARNESS_CORE_REPOSITORY")
    or "."
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME")

local function path(root, relative)
    return root .. "/" .. relative
end

local packagePaths = {
    path(coreRepository, "tools/semantic_harness/lua/?.lua"),
    path(coreRepository, "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua"),
}
if coreRuntime and coreRuntime ~= "" then
    packagePaths[#packagePaths + 1] = path(
        coreRepository,
        "Contents/mods/PsychopatzCore/" .. coreRuntime
            .. "/media/lua/shared/?.lua"
    )
end
package.path = table.concat(packagePaths, ";") .. ";" .. package.path

local Protocol = require "Protocol"
local LaunchMetadata = require "worker/LaunchMetadata"
local RuntimeState = require "worker/RuntimeState"
local Values = require "worker/Values"
local SessionEnvelope = require "worker/SessionEnvelope"
local WorkingWorld = require "worker/WorkingWorld"
local Router = require "worker/Router"
local WorkerLoop = require "worker/WorkerLoop"
local SemanticExecution = require "worker/SemanticExecution"
local ProviderLoader = require "worker/ProviderLoader"
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"

local providerLaunch = ProviderLoader.readConfiguration()
ProviderLoader.extendPackagePaths(packagePaths, providerLaunch.modulePaths)
package.path = table.concat(packagePaths, ";") .. ";" .. package.path

local launch = LaunchMetadata.read({
    profile = "core",
    providers = { "PsychopatzCore" },
    materializationMode = "none",
})
local profileID = launch.profile
local selectedProviders = launch.providers
local materializationMode = launch.materializationMode

local Runtime = RuntimeState.new()
local Context = {
    Runtime = Runtime,
    profile = profileID,
    providers = selectedProviders,
    materializationMode = materializationMode,
}

local function callbackContext(context)
    return {
        profile = context.profile,
        providers = context.providers,
        materializationMode = context.materializationMode,
    }
end

local callbacks = {
    buildContext = function(context)
        return callbackContext(context)
    end,
    submitText = function(context, text)
        return {
            accepted = false,
            reason = "provider_callback_unconfigured",
            profile = context.profile,
            text = text,
        }
    end,
    previewText = function(context, text)
        return {
            accepted = false,
            reason = "provider_callback_unconfigured",
            profile = context.profile,
            text = text,
        }
    end,
    submitFrame = function(context, frame)
        return {
            accepted = false,
            reason = "provider_callback_unconfigured",
            profile = context.profile,
            frame = frame,
        }
    end,
    snapshot = function(context)
        return callbackContext(context)
    end,
    interaction = function(context, operation, payload)
        return {
            accepted = false,
            reason = "provider_callback_unconfigured",
            profile = context.profile,
            operation = operation,
            payload = payload,
        }
    end,
}

local providerRuntime, providerLoadReason = ProviderLoader.load(
    SemanticExecution,
    providerLaunch,
    Context,
    callbacks,
    selectedProviders
)
if not providerRuntime then
    error(providerLoadReason)
end

local function hello()
    return {
        ok = true,
        type = "hello",
        profile = profileID,
        providers = selectedProviders,
        materializationMode = materializationMode,
        capabilities = {
            "semantic.parse",
            "semantic.ir",
            "semantic.conversation",
            "harness.runtime_state",
            "harness.value_projection",
            "harness.session_envelope",
            "harness.working_world",
            "harness.router",
            "harness.semantic_execution",
            "harness.provider_loader",
            "semantic.provider_execution",
        },
        sessionEnvelope = {
            schema = SessionEnvelope.SCHEMA,
            schemaVersion = SessionEnvelope.SCHEMA_VERSION,
        },
        workingWorld = {
            maxPatches = WorkingWorld.MAX_PATCHES,
        },
        router = {
            dispatch = type(Router.dispatch) == "function",
        },
        semanticExecution = {
            schema = SemanticExecution.SCHEMA,
            schemaVersion = SemanticExecution.SCHEMA_VERSION,
            materializationMode = materializationMode,
        },
        providerAdapters = providerRuntime.descriptions,
        executionProviderID = providerRuntime.executionProviderID,
    }
end

local function capabilities()
    local result = hello()
    result.type = "capabilities"
    return result
end

local function dispatch(request)
    local command = string.upper(request.command)
    local payload = type(request.payload) == "table" and request.payload or {}
    if command == "PING" then
        return { ok = true, type = "pong", profile = profileID }, nil, false
    end
    if command == "CAPABILITIES" then
        return capabilities(), nil, false
    end
    if command == "PARSE" then
        if type(payload.text) ~= "string" or payload.text == "" then
            return nil, "parse_text_required", false
        end
        local result = Semantics.Parse(payload.text, payload.options)
        return {
            ok = true,
            type = "semantic_parse",
            result = result,
        }, nil, false
    end
    if command == "SEMANTIC_PROVIDER" then
        local operation = tostring(payload.operation or "")
        local providerID = payload.providerID
            or providerRuntime.executionProviderID
        local execution = providerID and providerRuntime.executions[providerID]
        if not execution then
            return nil, "provider_execution_unavailable", false
        end
        local ok, result, reason = pcall(function()
            if operation == "buildContext" then
                return execution:buildContext()
            end
            if operation == "submitText" then
                return execution:submitText(payload.text)
            end
            if operation == "previewText" then
                return execution:previewText(payload.text)
            end
            if operation == "submitFrame" then
                return execution:submitFrame(payload.frame)
            end
            if operation == "snapshot" then
                return execution:snapshot()
            end
            if operation == "interaction" then
                return execution:interaction(
                    payload.interaction,
                    payload.value
                )
            end
            return nil, "provider_operation_unknown:" .. operation
        end)
        if not ok then
            return nil, "provider_callback_failed:" .. tostring(result), false
        end
        if result == nil and reason ~= nil then
            return nil, tostring(reason), false
        end
        return {
            ok = true,
            type = "semantic_provider",
            providerID = providerID,
            operation = operation,
            result = result,
        }, nil, false
    end
    if command == "QUIT" then
        return { ok = true, type = "goodbye", profile = profileID }, nil, true
    end
    return nil, "unknown_command:" .. tostring(request.command), false
end

WorkerLoop.run(Protocol, dispatch, { hello = hello })
