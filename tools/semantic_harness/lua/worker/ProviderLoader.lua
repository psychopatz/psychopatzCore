-- Provider-neutral optional-adopter loader for the semantic harness worker.
--
-- Core accepts package-path templates and module names from the launch
-- environment.  It never names or imports an adopter.  A loaded module must
-- expose New, new, or create(SemanticExecution, context, callbacks) and return
-- a Core SemanticExecution instance.

local ProviderLoader = {}

local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local function environment(name)
    if os and type(os.getenv) == "function" then
        return os.getenv(name)
    end
    return nil
end

local function split(value, separator)
    local result = {}
    if type(value) ~= "string" or value == "" then
        return result
    end
    for item in string.gmatch(value, "[^" .. separator .. "]+") do
        item = string.gsub(item, "^%s+", "")
        item = string.gsub(item, "%s+$", "")
        if item ~= "" then
            result[#result + 1] = item
        end
    end
    return result
end

local function routes(value)
    local result = {}
    for _, entry in ipairs(split(value, ";")) do
        local capability, providerID = string.match(entry, "^([^=]+)=(.+)$")
        if capability and providerID then
            capability = string.gsub(capability, "^%s+", "")
            capability = string.gsub(capability, "%s+$", "")
            providerID = string.gsub(providerID, "^%s+", "")
            providerID = string.gsub(providerID, "%s+$", "")
            if capability ~= "" and providerID ~= "" then
                result[capability] = providerID
            end
        end
    end
    return result
end

local function activationPlan(defaults)
    local encoded = environment("SEMANTIC_HARNESS_ACTIVATION_PLAN")
    if type(encoded) == "string" and encoded ~= "" then
        local decoded, reason = Json.Decode(encoded)
        if type(decoded) ~= "table" then
            error("invalid semantic harness activation plan: " .. tostring(reason))
        end
        return decoded, encoded
    end
    if type(defaults.activationPlan) == "table" then
        return defaults.activationPlan, nil
    end
    return {}, nil
end

function ProviderLoader.readConfiguration(defaults)
    defaults = type(defaults) == "table" and defaults or {}
    local plan, encodedPlan = activationPlan(defaults)
    local moduleDocument = type(plan.modules) == "table" and plan.modules or {}
    local modulePaths = split(
        environment("SEMANTIC_HARNESS_PROVIDER_MODULE_PATHS"),
        ";"
    )
    local modules = split(
        environment("SEMANTIC_HARNESS_PROVIDER_MODULES"),
        ","
    )
    if #modulePaths == 0 and type(defaults.modulePaths) == "table" then
        modulePaths = defaults.modulePaths
    end
    if #modulePaths == 0 and type(moduleDocument.paths) == "table" then
        modulePaths = moduleDocument.paths
    end
    if #modules == 0 and type(defaults.modules) == "table" then
        modules = defaults.modules
    end
    if #modules == 0 and type(moduleDocument.names) == "table" then
        modules = moduleDocument.names
    end
    local executionProviderID = environment(
        "SEMANTIC_HARNESS_EXECUTION_PROVIDER_ID"
    ) or defaults.executionProviderID or plan.executionProviderID
    if type(executionProviderID) == "string" then
        executionProviderID = string.gsub(executionProviderID, "^%s+", "")
        executionProviderID = string.gsub(executionProviderID, "%s+$", "")
        if executionProviderID == "" then
            executionProviderID = nil
        end
    end
    local routeTable = routes(environment("SEMANTIC_HARNESS_ROUTE_TABLE"))
    if next(routeTable) == nil and type(defaults.routes) == "table" then
        routeTable = defaults.routes
    end
    if next(routeTable) == nil and type(plan.routes) == "table" then
        routeTable = plan.routes
    end
    return {
        modulePaths = modulePaths,
        modules = modules,
        executionProviderID = executionProviderID,
        routes = routeTable,
        runtimeBootstraps = type(plan.runtimeBootstraps) == "table"
            and plan.runtimeBootstraps
            or defaults.runtimeBootstraps
            or {},
        activationPlan = plan,
        activationPlanJSON = encodedPlan,
    }
end

function ProviderLoader.extendPackagePaths(packagePaths, modulePaths)
    for _, modulePath in ipairs(type(modulePaths) == "table" and modulePaths or {}) do
        if type(modulePath) == "string" and modulePath ~= "" then
            packagePaths[#packagePaths + 1] = modulePath
        end
    end
    return packagePaths
end

function ProviderLoader.extendRuntimePackagePaths(packagePaths, bootstraps)
    for _, bootstrap in ipairs(type(bootstraps) == "table" and bootstraps or {}) do
        ProviderLoader.extendPackagePaths(packagePaths, bootstrap.modulePaths)
    end
    return packagePaths
end

function ProviderLoader.installActivationGlobals(selectedProviders)
    local active = {}
    for _, providerID in ipairs(
        type(selectedProviders) == "table" and selectedProviders or {}
    ) do
        active[tostring(providerID)] = true
    end
    -- The real game supplies getActivatedMods.  The headless worker supplies
    -- the same observation contract from the validated activation plan before
    -- provider bootstraps execute, so conflict policies cannot depend on
    -- fixture scenario data.
    getActivatedMods = function()
        return {
            contains = function(_, providerID)
                return active[tostring(providerID or "")] == true
            end,
        }
    end
    return active
end

function ProviderLoader.loadRuntime(configuration)
    configuration = type(configuration) == "table" and configuration or {}
    local loaded = {}
    for _, bootstrap in ipairs(configuration.runtimeBootstraps or {}) do
        local entrypoint = type(bootstrap) == "table"
            and tostring(bootstrap.entrypoint or "")
            or ""
        local required = type(bootstrap) ~= "table"
            or bootstrap.required ~= false
        local bootstrapID = type(bootstrap) == "table"
            and tostring(bootstrap.id or "")
            or ""
        if entrypoint == "" then
            if required then
                return nil, "runtime_bootstrap_entrypoint_missing:" .. bootstrapID
            end
        else
            local handle = io.open(entrypoint, "rb")
            if not handle then
                if required then
                    return nil, "runtime_bootstrap_file_missing:" .. entrypoint
                end
            else
                handle:close()
                -- A manifest-selected repository is an external provider
                -- boundary. Keep its startup failure bounded and report it
                -- through the normal worker handshake.
                local ok, reason = pcall(dofile, entrypoint)
                if not ok then
                    return nil, "runtime_bootstrap_failed:" .. bootstrapID
                        .. ":" .. tostring(reason)
                end
                loaded[#loaded + 1] = {
                    id = bootstrapID,
                    providerID = type(bootstrap) == "table"
                        and bootstrap.providerID
                        or nil,
                    entrypoint = entrypoint,
                    status = "loaded",
                }
            end
        end
    end
    return { entries = loaded, count = #loaded }
end

local function contains(values, wanted)
    for _, value in ipairs(type(values) == "table" and values or {}) do
        if value == wanted then
            return true
        end
    end
    return false
end

local function describe(execution)
    if type(execution) ~= "table"
        or type(execution.describe) ~= "function"
    then
        return nil, "provider_execution_contract_required"
    end
    local called, descriptionOrReason = pcall(execution.describe, execution)
    if not called then
        return nil, "provider_execution_describe_failed:"
            .. tostring(descriptionOrReason)
    end
    local description = descriptionOrReason
    if type(description) ~= "table"
        or type(description.providerID) ~= "string"
        or description.providerID == ""
    then
        return nil, "provider_execution_provider_id_required"
    end
    return description
end

function ProviderLoader.load(
    SemanticExecution,
    configuration,
    context,
    callbacks,
    selectedProviders
)
    configuration = type(configuration) == "table" and configuration or {}
    local executions = {}
    local descriptions = {}
    for _, moduleName in ipairs(configuration.modules or {}) do
        -- Adopter factories are an unavoidable external callback boundary.
        -- Convert load/factory failures into bounded startup diagnostics so an
        -- optional provider cannot corrupt the Core worker process state.
        local loaded, moduleOrReason = pcall(require, moduleName)
        if not loaded then
            return nil, "provider_module_load_failed:" .. tostring(moduleName)
                .. ":" .. tostring(moduleOrReason)
        end
        if type(moduleOrReason) ~= "table" then
            return nil, "provider_module_invalid:" .. tostring(moduleName)
        end
        local factory = moduleOrReason.New
            or moduleOrReason.new
            or moduleOrReason.create
        if type(factory) ~= "function" then
            return nil, "provider_module_factory_missing:" .. tostring(moduleName)
        end
        local called, executionOrReason, factoryReason = pcall(
            factory,
            SemanticExecution,
            context,
            callbacks
        )
        if not called then
            return nil, "provider_factory_failed:" .. tostring(moduleName)
                .. ":" .. tostring(executionOrReason)
        end
        if not executionOrReason then
            return nil, "provider_factory_rejected:" .. tostring(moduleName)
                .. ":" .. tostring(factoryReason)
        end
        local description, descriptionReason = describe(executionOrReason)
        if not description then
            return nil, "provider_module_invalid:" .. tostring(moduleName)
                .. ":" .. tostring(descriptionReason)
        end
        if not contains(selectedProviders, description.providerID) then
            return nil, "provider_not_selected:" .. description.providerID
        end
        if executions[description.providerID] ~= nil then
            return nil, "provider_duplicate:" .. description.providerID
        end
        executions[description.providerID] = executionOrReason
        descriptions[#descriptions + 1] = description
    end

    local executionProviderID = configuration.executionProviderID
    if executionProviderID ~= nil
        and executions[executionProviderID] == nil
    then
        return nil, "execution_provider_not_loaded:" .. executionProviderID
    end
    if executionProviderID == nil and #descriptions == 1 then
        executionProviderID = descriptions[1].providerID
    end
    for capability, providerID in pairs(configuration.routes or {}) do
        if providerID ~= "PsychopatzCore" and executions[providerID] == nil then
            return nil, "route_provider_not_loaded:" .. tostring(capability)
                .. ":" .. tostring(providerID)
        end
    end
    return {
        executions = executions,
        descriptions = descriptions,
        executionProviderID = executionProviderID,
        routes = configuration.routes or {},
        activationPlan = configuration.activationPlan,
    }
end

return ProviderLoader
