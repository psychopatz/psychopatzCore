local Registry = { namespaces = {} }

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

function Registry.UnregisterNamespace(namespace)
    if not Registry.namespaces[namespace] then return false end
    Registry.namespaces[namespace] = nil
    if Registry.onChanged then Registry.onChanged() end
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
