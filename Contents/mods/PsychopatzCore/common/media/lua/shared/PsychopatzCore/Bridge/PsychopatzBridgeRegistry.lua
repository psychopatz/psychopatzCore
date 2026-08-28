local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"
local Registry = { namespaces = {}, tools = {}, toolRevision = 0, toolCatalog = nil }
local MAX_TOOLS = 256

local function valid(value, dotted)
    if type(value) ~= "string" or #value == 0 or #value > 96 then return false end
    if not dotted then return string.match(value, "^[%w_%-]+$") ~= nil end
    if string.sub(value, 1, 1) == "." or string.sub(value, -1) == "."
        or string.find(value, "..", 1, true) then return false end
    for part in string.gmatch(value, "[^.]+") do
        if not string.match(part, "^[%w_%-]+$") then return false end
    end
    return true
end

local function toolKey(namespace, name)
    return namespace .. ":" .. name
end

local function invalidateTools()
    Registry.toolRevision = Registry.toolRevision + 1
    Registry.toolCatalog = nil
    if Registry.onChanged then Registry.onChanged() end
end

function Registry.Register(namespace, command, options)
    if not valid(namespace, true) then return false, "invalid_namespace" end
    if not valid(command, false) then return false, "invalid_command" end
    if type(options) ~= "table" or type(options.handler) ~= "function" then
        return false, "invalid_handler"
    end
    local commands = Registry.namespaces[namespace]
    if not commands then commands = {}; Registry.namespaces[namespace] = commands end
    if commands[command] then return false, "duplicate_command" end
    commands[command] = { handler = options.handler,
        readOnly = options.readOnly == true,
        category = options.category or (options.readOnly and "READ" or "ACTION") }
    if Registry.onChanged then Registry.onChanged() end
    return true
end

function Registry.RegisterTool(namespace, name, definition, options)
    if not valid(namespace, true) then return false, "invalid_namespace" end
    if not valid(name, false) then return false, "invalid_tool" end
    if type(definition) ~= "table" then return false, "invalid_tool_definition" end
    options = type(options) == "table" and options or {}
    local key = toolKey(namespace, name)
    if Registry.tools[key] then return false, "duplicate_tool" end
    local toolCount = 0
    for _, _ in pairs(Registry.tools) do toolCount = toolCount + 1 end
    if toolCount >= MAX_TOOLS then return false, "tool_limit" end
    Registry.tools[key] = {
        id = key, namespace = namespace, name = name,
        kind = options.kind or "llm_tool", definition = definition,
    }
    invalidateTools()
    return true
end

function Registry.UnregisterTool(namespace, name)
    local key = toolKey(namespace, name)
    if not Registry.tools[key] then return false end
    Registry.tools[key] = nil
    invalidateTools()
    return true
end

function Registry.ToolCatalog()
    if Registry.toolCatalog then return Registry.toolCatalog end
    local keys = {}
    for key, _ in pairs(Registry.tools) do keys[#keys + 1] = key end
    table.sort(keys)
    local tools = {}
    for index = 1, #keys do
        local value = Registry.tools[keys[index]]
        tools[#tools + 1] = {
            id = value.id, namespace = value.namespace, name = value.name,
            kind = value.kind, definition = value.definition,
        }
    end
    local encoded = Json.Encode({ revision = Registry.toolRevision, tools = tools }, {
        maxDepth = 24, maxString = 8192, maxCollection = 256,
    })
    Registry.toolCatalog = {
        catalog_id = Json.Fingerprint(encoded),
        catalog_version = Registry.toolRevision,
        tools = tools,
    }
    return Registry.toolCatalog
end

function Registry.Reset()
    Registry.namespaces = {}
    Registry.tools = {}
    Registry.toolRevision = 0
    Registry.toolCatalog = nil
end

function Registry.UnregisterNamespace(namespace)
    local prefix = namespace .. ":"
    local hasTool = false
    for key, _ in pairs(Registry.tools) do
        if string.sub(key, 1, #prefix) == prefix then hasTool = true break end
    end
    if not Registry.namespaces[namespace] and not hasTool then return false end
    Registry.namespaces[namespace] = nil
    local removedTool = false
    for key, _ in pairs(Registry.tools) do
        if string.sub(key, 1, #prefix) == prefix then
            Registry.tools[key] = nil
            removedTool = true
        end
    end
    if removedTool then
        invalidateTools()
    elseif Registry.onChanged then
        Registry.onChanged()
    end
    return true
end

function Registry.Resolve(namespace, command)
    local commands = Registry.namespaces[namespace]
    if not commands then return nil, "UNKNOWN_NAMESPACE" end
    if not commands[command] then return nil, "UNKNOWN_COMMAND" end
    return commands[command]
end

function Registry.Capabilities()
    local result, namespaceNames = {}, {}
    for namespace, _ in pairs(Registry.namespaces) do namespaceNames[#namespaceNames + 1] = namespace end
    table.sort(namespaceNames)
    for index = 1, math.min(#namespaceNames, 32) do
        local namespace = namespaceNames[index]
        local commands, names = Registry.namespaces[namespace], {}
        for name, _ in pairs(commands) do names[#names + 1] = name end
        table.sort(names)
        local rows = {}
        for commandIndex = 1, math.min(#names, 64) do
            local name, metadata = names[commandIndex], commands[names[commandIndex]]
            rows[#rows + 1] = { name = name, read_only = metadata.readOnly,
                category = metadata.category }
        end
        result[namespace] = { commands = rows }
    end
    return result
end

return Registry
