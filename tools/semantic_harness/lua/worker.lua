-- Minimal Core-only semantic harness worker.
--
-- This is the first executable migration seam. It intentionally loads only
-- PsychopatzCore and provides a small lifecycle surface while the full
-- authoring/runtime application moves behind the provider registry.

local coreRepository = arg[1]
    or os.getenv("SEMANTIC_HARNESS_CORE_REPOSITORY")
    or "."
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME")
local profileID = tostring(
    os.getenv("SEMANTIC_HARNESS_PROFILE") or "core"
)
local materializationMode = tostring(
    os.getenv("SEMANTIC_HARNESS_MATERIALIZATION_MODE") or "none"
)

local function providerIDs()
    local value = os.getenv("SEMANTIC_HARNESS_PROVIDER_IDS")
    if not value or value == "" then return { "PsychopatzCore" } end
    local result = {}
    for providerID in string.gmatch(value, "[^,]+") do
        providerID = string.gsub(providerID, "^%s+", "")
        providerID = string.gsub(providerID, "%s+$", "")
        if providerID ~= "" then result[#result + 1] = providerID end
    end
    if #result == 0 then result[1] = "PsychopatzCore" end
    return result
end

local selectedProviders = providerIDs()

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
local RuntimeState = require "worker/RuntimeState"
local Values = require "worker/Values"
local SessionEnvelope = require "worker/SessionEnvelope"
local WorkingWorld = require "worker/WorkingWorld"
local Router = require "worker/Router"
local WorkerLoop = require "worker/WorkerLoop"
local SemanticExecution = require "worker/SemanticExecution"
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"

local Runtime = RuntimeState.new()

local function hello()
    return {
        ok = true,
        type = "hello",
        profile = profileID,
        providers = selectedProviders,
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
    if command == "QUIT" then
        return { ok = true, type = "goodbye", profile = profileID }, nil, true
    end
    return nil, "unknown_command:" .. tostring(request.command), false
end

WorkerLoop.run(Protocol, dispatch, { hello = hello })
