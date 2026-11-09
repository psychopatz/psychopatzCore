-- Provider-neutral semantic execution callback contract.

local SemanticExecution = {}

SemanticExecution.SCHEMA = "semantic.harness_execution.v1"
SemanticExecution.SCHEMA_VERSION = 1
SemanticExecution.MATERIALIZATION_MODES = {
    none = true,
    abstract = true,
    physical = true,
}

local function callbackStatus(callbacks, name)
    return type(callbacks[name]) == "function"
end

function SemanticExecution.new(spec)
    spec = type(spec) == "table" and spec or {}
    local providerID = tostring(spec.providerID or "")
    if providerID == "" then return nil, "provider_id_required" end
    local materializationMode = tostring(
        spec.materializationMode or "none"
    ):lower()
    if not SemanticExecution.MATERIALIZATION_MODES[materializationMode] then
        return nil, "invalid_materialization_mode"
    end
    local callbacks = type(spec.callbacks) == "table"
        and spec.callbacks or {}
    return setmetatable({
        providerID = providerID,
        materializationMode = materializationMode,
        capabilities = type(spec.capabilities) == "table"
            and spec.capabilities or {},
        context = spec.context,
        callbacks = callbacks,
    }, { __index = SemanticExecution })
end

function SemanticExecution:describe()
    local callbacks = self.callbacks or {}
    return {
        schema = SemanticExecution.SCHEMA,
        schemaVersion = SemanticExecution.SCHEMA_VERSION,
        providerID = self.providerID,
        materializationMode = self.materializationMode,
        capabilities = self.capabilities,
        callbacks = {
            buildContext = callbackStatus(callbacks, "buildContext"),
            submitText = callbackStatus(callbacks, "submitText"),
            previewText = callbackStatus(callbacks, "previewText"),
            submitFrame = callbackStatus(callbacks, "submitFrame"),
            snapshot = callbackStatus(callbacks, "snapshot"),
            interaction = callbackStatus(callbacks, "interaction"),
        },
    }
end

function SemanticExecution:invoke(name, ...)
    local callback = self.callbacks and self.callbacks[name]
    if type(callback) ~= "function" then
        return nil, "callback_unavailable:" .. tostring(name)
    end
    return callback(self.context, ...)
end

function SemanticExecution:buildContext()
    return self:invoke("buildContext")
end

function SemanticExecution:submitText(text)
    return self:invoke("submitText", text)
end

function SemanticExecution:previewText(text)
    return self:invoke("previewText", text)
end

function SemanticExecution:submitFrame(frame)
    return self:invoke("submitFrame", frame)
end

function SemanticExecution:snapshot()
    return self:invoke("snapshot")
end

function SemanticExecution:interaction(operation, payload)
    return self:invoke("interaction", operation, payload)
end

return SemanticExecution
