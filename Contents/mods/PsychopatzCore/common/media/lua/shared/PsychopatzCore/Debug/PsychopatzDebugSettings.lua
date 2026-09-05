-- Persisted registry for optional diagnostics owned by any mod.
-- The configured value is intentionally separate from the active value:
-- only an explicit ApplyConfigured call may change runtime-mutable settings.
PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Settings = Core.DebugSettings or {}
Core.DebugSettings = Settings

Settings.CONFIG_FILE = Settings.CONFIG_FILE or "PsychopatzCore_Debug.txt"
Settings.COMMAND = Settings.COMMAND or "SetDebugSetting"
Settings.APPLY_COMMAND = Settings.APPLY_COMMAND or "ApplyDebugSettings"
Settings.VERSION = 1
Settings.definitions = Settings.definitions or {}
Settings.configured = Settings.configured or {}
Settings.active = Settings.active or {}
Settings.loaded = Settings.loaded == true

local function trim(value)
    return string.match(tostring(value or ""), "^%s*(.-)%s*$") or ""
end

local function parseBoolean(value)
    value = string.lower(trim(value))
    return value == "true" or value == "1" or value == "yes"
        or value == "on"
end

local function validID(id)
    return id ~= "" and string.match(id, "^[%w_.%-]+$") ~= nil
end

local function defaultValue(definition)
    return definition.defaultEnabled == true or definition.default == true
end

local function sortedIDs(values)
    local ids = {}
    for id, _ in pairs(values or {}) do ids[#ids + 1] = tostring(id) end
    table.sort(ids)
    return ids
end

local function invokeApply(definition, enabled, previous)
    if not definition.apply then return true end
    local ok, result = pcall(definition.apply, enabled, previous, definition)
    if not ok then return false, tostring(result) end
    if result == false then return false, "apply_rejected" end
    return true
end

local function readConfigured()
    local values = {}
    if not getFileReader then return values, "file_reader_unavailable" end
    local reader = getFileReader(Settings.CONFIG_FILE, false)
    if not reader or not reader.readLine then return values, "file_not_found" end

    local line = reader:readLine()
    while line do
        local key, value = string.match(line, "^%s*(.-)%s*=%s*(.-)%s*$")
        if key and string.sub(key, 1, 8) == "setting." then
            local id = string.sub(key, 9)
            if validID(id) then values[id] = parseBoolean(value) end
        end
        line = reader:readLine()
    end
    if reader.close then reader:close() end
    return values
end

function Settings.Load()
    if Settings.loaded then return true end
    local values = readConfigured()
    Settings.configured = values or {}
    Settings.active = {}
    for id, value in pairs(Settings.configured) do
        Settings.active[id] = value == true
    end
    Settings.loaded = true
    return true
end

-- Explicitly re-read the file without touching active values. The UI can then
-- call ApplyConfigured to make runtime-mutable settings take effect once.
function Settings.Reload()
    Settings.Load()
    local values, reason = readConfigured()
    if reason == "file_reader_unavailable" then return false, reason end
    values = values or {}
    for id, definition in pairs(Settings.definitions) do
        if values[id] == nil then values[id] = definition.defaultEnabled == true end
    end
    Settings.configured = values
    return true, reason
end

function Settings.Register(definition)
    if type(definition) ~= "table" then return false, "definition_required" end
    local id = trim(definition.id)
    if not validID(id) then return false, "invalid_id" end

    Settings.Load()
    local registered = {
        id = id,
        source = trim(definition.source) ~= ""
            and trim(definition.source) or "PsychopatzCore",
        title = trim(definition.title) ~= ""
            and trim(definition.title) or id,
        description = trim(definition.description),
        order = tonumber(definition.order) or 1000,
        defaultEnabled = defaultValue(definition),
        runtimeMutable = definition.runtimeMutable == true,
        apply = type(definition.apply) == "function" and definition.apply or nil,
    }
    Settings.definitions[id] = registered
    if Settings.configured[id] == nil then
        Settings.configured[id] = registered.defaultEnabled
    end
    if Settings.active[id] == nil then
        Settings.active[id] = Settings.configured[id] == true
    end
    local applied, reason = invokeApply(registered, Settings.active[id], nil)
    if not applied and print then
        print("[PsychopatzCore.DebugSettings] initial_apply_failed setting="
            .. id .. " reason=" .. tostring(reason))
    end
    return registered
end

function Settings.GetDefinition(id)
    return Settings.definitions[trim(id)]
end

function Settings.GetDefinitions()
    local output = {}
    for _, id in ipairs(sortedIDs(Settings.definitions)) do
        output[#output + 1] = Settings.definitions[id]
    end
    table.sort(output, function(left, right)
        if left.source ~= right.source then return left.source < right.source end
        if left.order ~= right.order then return left.order < right.order end
        if left.title ~= right.title then return left.title < right.title end
        return left.id < right.id
    end)
    return output
end

function Settings.IsEnabled(id)
    id = trim(id)
    return Settings.definitions[id] ~= nil and Settings.active[id] == true
end

function Settings.IsRuntimeMutable(id)
    local definition = Settings.definitions[trim(id)]
    return definition and definition.runtimeMutable == true or false
end

function Settings.GetConfigured(id)
    id = trim(id)
    local value = Settings.configured[id]
    if value ~= nil then return value == true end
    local definition = Settings.definitions[id]
    return definition and definition.defaultEnabled == true or false
end

function Settings.IsPendingRestart(id)
    id = trim(id)
    return not Settings.IsRuntimeMutable(id)
        and Settings.GetConfigured(id) ~= Settings.IsEnabled(id)
end

function Settings.IsPendingApply(id)
    id = trim(id)
    return Settings.IsRuntimeMutable(id)
        and Settings.GetConfigured(id) ~= Settings.IsEnabled(id)
end

function Settings.Save()
    if not getFileWriter then return false, "file_writer_unavailable" end
    local writer = getFileWriter(Settings.CONFIG_FILE, true, false)
    if not writer or not writer.write then
        return false, "file_writer_unavailable"
    end

    local lines = { "config_version=" .. tostring(Settings.VERSION) }
    for _, id in ipairs(sortedIDs(Settings.configured)) do
        lines[#lines + 1] = "setting." .. id .. "="
            .. (Settings.configured[id] == true and "true" or "false")
    end
    lines[#lines + 1] = ""

    local ok, reason = pcall(function()
        writer:write(table.concat(lines, "\n"))
        if writer.close then writer:close() end
    end)
    if not ok then
        if writer.close then pcall(function() writer:close() end) end
        return false, tostring(reason)
    end
    return true
end

-- Applies only settings explicitly marked runtimeMutable. Non-mutable settings
-- stay active until restart, which keeps lifecycle-heavy instrumentation safe.
function Settings.ApplyConfigured()
    Settings.Load()
    local changes, report = {}, {
        applied = {}, pendingRestart = {}, failed = {},
    }
    for _, definition in ipairs(Settings.GetDefinitions()) do
        local desired = Settings.GetConfigured(definition.id)
        local current = Settings.IsEnabled(definition.id)
        if definition.runtimeMutable then
            if desired ~= current then
                changes[#changes + 1] = {
                    definition = definition,
                    desired = desired,
                    previous = current,
                }
            end
        elseif desired ~= current then
            report.pendingRestart[#report.pendingRestart + 1] = definition.id
        end
    end

    local applied = {}
    for index = 1, #changes do
        local change = changes[index]
        Settings.active[change.definition.id] = change.desired
        local ok, reason = invokeApply(
            change.definition, change.desired, change.previous)
        if not ok then
            Settings.active[change.definition.id] = change.previous
            invokeApply(change.definition, change.previous, change.desired)
            for rollback = #applied, 1, -1 do
                local prior = applied[rollback]
                Settings.active[prior.definition.id] = prior.previous
                invokeApply(prior.definition, prior.previous, prior.desired)
            end
            report.failed[#report.failed + 1] = {
                id = change.definition.id, reason = reason,
            }
            return false, report
        end
        applied[#applied + 1] = change
        report.applied[#report.applied + 1] = change.definition.id
    end
    return true, report
end

function Settings.Set(id, enabled, save)
    id = trim(id)
    if not Settings.definitions[id] then return false, "unknown_setting" end
    local previous = Settings.configured[id]
    Settings.configured[id] = enabled == true
    if save ~= false then
        local ok, reason = Settings.Save()
        if not ok then
            Settings.configured[id] = previous
            return false, reason
        end
    end
    return true, Settings.configured[id]
end

function Settings.Reset(save)
    Settings.Load()
    for id, definition in pairs(Settings.definitions) do
        Settings.configured[id] = definition.defaultEnabled == true
    end
    if save ~= false then return Settings.Save() end
    return true
end

function Settings.GetStatus()
    local enabled, pendingApply, pendingRestart = 0, 0, 0
    local definitions = Settings.GetDefinitions()
    for _, definition in ipairs(definitions) do
        if Settings.IsEnabled(definition.id) then enabled = enabled + 1 end
        if Settings.IsPendingApply(definition.id) then pendingApply = pendingApply + 1 end
        if Settings.IsPendingRestart(definition.id) then pendingRestart = pendingRestart + 1 end
    end
    return {
        registered = #definitions,
        enabled = enabled,
        pendingApply = pendingApply,
        pendingRestart = pendingRestart,
    }
end

Settings.Load()

return Settings
