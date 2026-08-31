PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Settings = PsychopatzCore.Settings or {}

local Settings = PsychopatzCore.Settings
Settings.stores = Settings.stores or {}

local Store = Settings.Store or {}
Store.__index = Store
Settings.Store = Store

local function copyDefaults(defaults)
    local values = {}
    for key, value in pairs(defaults or {}) do
        values[key] = value
    end
    values.windows = {}
    return values
end

local function sortedKeys(values)
    local keys = {}
    for key, _ in pairs(values or {}) do
        if key ~= "windows" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)
    return keys
end

local function parseValue(raw, defaultValue)
    if type(defaultValue) == "boolean" then
        return raw == "true"
    end
    if type(defaultValue) == "number" then
        return tonumber(raw) or defaultValue
    end
    return tostring(raw or "")
end

local function parseWindow(store, line)
    if string.sub(line, 1, 7) ~= "window_" then return false end
    local separator = string.find(line, "=", 8, true)
    if not separator then return false end
    local key = string.sub(line, 8, separator - 1)
    local rawValues = {}
    for value in string.gmatch(string.sub(line, separator + 1), "([^,]+)") do
        rawValues[#rawValues + 1] = value
    end
    if #rawValues < 4 or #rawValues > 6 then return false end
    local values = {}
    for index = 1, 4 do
        values[index] = tonumber(rawValues[index])
        if values[index] == nil then return false end
    end
    local state = {
        x = values[1], y = values[2], w = values[3], h = values[4],
    }
    if rawValues[5] ~= nil then
        if rawValues[5] ~= "true" and rawValues[5] ~= "false" then return false end
        state.pin = rawValues[5] == "true"
    end
    if rawValues[6] ~= nil then
        if rawValues[6] ~= "true" and rawValues[6] ~= "false" then return false end
        state.collapsed = rawValues[6] == "true"
    end
    store.values.windows[key] = state
    return true
end

function Store:Reset(save)
    local defaults = copyDefaults(self.defaults)
    self.values = self.values or {}
    for key, _ in pairs(self.values) do self.values[key] = nil end
    for key, value in pairs(defaults) do self.values[key] = value end
    if save == true then self:Save() end
    return self.values
end

function Store:Get(key, fallback)
    local value
    if self.values then value = self.values[key] end
    if value == nil then return fallback end
    return value
end

function Store:Set(key, value, save)
    self.values[key] = value
    if save ~= false then self:Save() end
    return value
end

function Store:GetWindowState(key)
    return self.values.windows[tostring(key or "")]
end

function Store:SetWindowState(key, x, y, width, height, save, flags)
    key = tostring(key or "")
    if key == "" then return false end
    local state = {
        x = math.floor(tonumber(x) or 0),
        y = math.floor(tonumber(y) or 0),
        w = math.floor(tonumber(width) or 0),
        h = math.floor(tonumber(height) or 0),
    }
    if type(flags) == "table" then
        if flags.pin ~= nil then state.pin = flags.pin == true end
        if flags.collapsed ~= nil then state.collapsed = flags.collapsed == true end
    end
    self.values.windows[key] = state
    if save ~= false then self:Save() end
    return true
end

function Store:ClearWindowState(key, save)
    self.values.windows[tostring(key or "")] = nil
    if save ~= false then self:Save() end
end

function Store:Save()
    if not getFileWriter then return false end
    local writer = getFileWriter(self.fileName, true, false)
    if not writer then return false end
    local keys = sortedKeys(self.values)
    for index = 1, #keys do
        local key = keys[index]
        writer:write(tostring(key) .. "=" .. tostring(self.values[key]) .. "\r\n")
    end
    local windowKeys = sortedKeys(self.values.windows)
    for index = 1, #windowKeys do
        local key = windowKeys[index]
        local state = self.values.windows[key]
        if state then
            local flags = ""
            if state.pin ~= nil or state.collapsed ~= nil then
                flags = "," .. tostring(state.pin == true) .. ","
                    .. tostring(state.collapsed == true)
            end
            writer:write(string.format("window_%s=%d,%d,%d,%d%s\r\n",
                tostring(key), tonumber(state.x) or 0, tonumber(state.y) or 0,
                tonumber(state.w) or 0, tonumber(state.h) or 0, flags))
        end
    end
    writer:close()
    return true
end

function Store:Load()
    self:Reset(false)
    if not getFileReader then
        self.loaded = true
        return false
    end
    local reader = getFileReader(self.fileName, false)
    if not reader then
        self.loaded = true
        self:Save()
        return false
    end
    local line = reader:readLine()
    while line do
        if not parseWindow(self, line) then
            local separator = string.find(line, "=", 1, true)
            if separator then
                local key = string.sub(line, 1, separator - 1)
                if self.defaults[key] ~= nil then
                    self.values[key] = parseValue(string.sub(line, separator + 1), self.defaults[key])
                end
            end
        end
        line = reader:readLine()
    end
    reader:close()
    self.loaded = true
    return true
end

function Settings.Open(namespace, options)
    namespace = tostring(namespace or "default")
    options = options or {}
    local store = Settings.stores[namespace]
    if store then
        for key, value in pairs(options.defaults or {}) do
            store.defaults[key] = value
            if store.values[key] == nil then store.values[key] = value end
        end
        if options.fileName ~= nil then store.fileName = tostring(options.fileName) end
        if options.autoLoad ~= nil then store.autoLoad = options.autoLoad ~= false end
        return store
    end
    local defaults = {}
    for key, value in pairs(options.defaults or {}) do defaults[key] = value end
    store = setmetatable({
        namespace = namespace,
        fileName = tostring(options.fileName or ("PsychopatzCore_" .. namespace .. ".txt")),
        defaults = defaults,
        autoLoad = options.autoLoad ~= false,
        loaded = false,
    }, Store)
    store:Reset(false)
    Settings.stores[namespace] = store
    return store
end

function Settings.Get(namespace)
    return Settings.stores[tostring(namespace or "default")]
end

function Settings.LoadAll()
    for _, store in pairs(Settings.stores) do
        if store.autoLoad and not store.loaded then store:Load() end
    end
end

if Events and Events.OnGameBoot and not Settings.bootHookRegistered then
    Events.OnGameBoot.Add(Settings.LoadAll)
    Settings.bootHookRegistered = true
end

return Settings
