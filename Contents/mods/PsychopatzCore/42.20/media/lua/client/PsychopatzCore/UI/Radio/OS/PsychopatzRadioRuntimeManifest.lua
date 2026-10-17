-- Core-owned modular radio manifest loader.
--
-- DeviceManifest.json is generated from the canonical pilot projects.  Lua
-- consumes that same data at runtime; it does not maintain a second atlas or
-- device catalog.

local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local M = {
    schemaVersion = 2,
    manifestKind = "psychopatz_radio_runtime",
    path = "media/ui/Radio/DeviceManifest.json",
    devices = {},
    ui = {},
    byID = {},
    byFullType = {},
    loaded = false,
    error = nil,
}

local MAX_BYTES = 2 * 1024 * 1024

local function number(value, fallback)
    value = tonumber(value)
    return value ~= nil and value or fallback
end

local function rect(value)
    if type(value) ~= "table" then return nil end
    local x = value.x or value[1]
    local y = value.y or value[2]
    local w = value.w or value[3]
    local h = value.h or value[4]
    if tonumber(x) == nil or tonumber(y) == nil
        or tonumber(w) == nil or tonumber(h) == nil
        or tonumber(w) <= 0 or tonumber(h) <= 0
    then
        return nil
    end
    return {
        x = number(x, 0), y = number(y, 0),
        w = number(w, 0), h = number(h, 0),
    }
end

local function readManifest()
    if not getModFileReader then return nil, "mod_reader_unavailable" end
    local reader = getModFileReader("PsychopatzCore", M.path, false)
    if not reader or not reader.readLine then return nil, "manifest_missing" end
    local lines, size = {}, 0
    local line = reader:readLine()
    while line do
        size = size + #line + 1
        if size > MAX_BYTES then
            if reader.close then reader:close() end
            return nil, "manifest_too_large"
        end
        lines[#lines + 1] = line
        line = reader:readLine()
    end
    if reader.close then reader:close() end
    return table.concat(lines, "\n")
end

local function normalizeState(state)
    if type(state) == "string" then state = { image = state } end
    if type(state) ~= "table" or type(state.image) ~= "string"
        or state.image == ""
    then
        return nil
    end
    return {
        image = state.image,
        x = number(state.x, 0),
        y = number(state.y, 0),
        anchor = state.anchor,
    }
end

local function normalizeLayer(layer)
    return normalizeState(layer)
end

local function normalizeComponent(raw)
    if type(raw) ~= "table" or type(raw.id) ~= "string"
        or raw.id == ""
    then
        return nil
    end
    local hitbox = rect(raw.hitbox)
    if not hitbox then return nil end
    local states = {}
    for stateName, state in pairs(raw.states or {}) do
        local normalized = normalizeState(state)
        if normalized then states[tostring(stateName)] = normalized end
    end
    return {
        id = raw.id,
        kind = tostring(raw.kind or "momentary"),
        action = tostring(raw.action or raw.id),
        hitbox = hitbox,
        interactive = raw.interactive == true,
        visible = raw.visible ~= false,
        pivot = raw.pivot,
        detents = number(raw.detents, 0),
        states = states,
    }
end

local function normalizeDevice(raw)
    if type(raw) ~= "table" or type(raw.id) ~= "string"
        or type(raw.fullType) ~= "string"
    then
        return nil
    end
    local canvas = raw.canvas or {}
    local device = {
        id = raw.id,
        family = tostring(raw.family or "radio"),
        model = tostring(raw.model or raw.fullType),
        fullType = raw.fullType,
        canvas = {
            width = number(canvas.width, 0),
            height = number(canvas.height, 0),
            origin = tostring(canvas.origin or "top_left"),
        },
        lcd = {},
        chassis = {},
        shell = {},
        lcd_layers = {},
        interaction = raw.interaction or {},
        components = {},
        interactiveComponents = {},
    }
    for _, key in ipairs({ "aperture", "backing", "content" }) do
        device.lcd[key] = rect((raw.lcd or {})[key])
    end
    for _, variant in ipairs({ "pristine", "worn" }) do
        local source = (raw.chassis or {})[variant]
        local normalized = normalizeLayer(source)
        if normalized then device.chassis[variant] = normalized end
        local shell = normalizeLayer((raw.shell or {})[variant])
        if shell then device.shell[variant] = shell end
    end
    for _, layerName in ipairs({ "matte", "glass", "bezel_overlay" }) do
        local normalized = normalizeLayer((raw.lcd_layers or {})[layerName])
        if normalized then device.lcd_layers[layerName] = normalized end
    end
    for _, rawComponent in ipairs(raw.components or {}) do
        local component = normalizeComponent(rawComponent)
        if component then
            device.components[#device.components + 1] = component
            if component.interactive then
                device.interactiveComponents[#device.interactiveComponents + 1] = component
            end
        end
    end
    table.sort(device.components, function(left, right)
        return left.id < right.id
    end)
    table.sort(device.interactiveComponents, function(left, right)
        return left.id < right.id
    end)
    return device
end

local function normalizeUI(raw)
    if type(raw) ~= "table" then return {} end
    local icons = raw.icons
    if type(icons) ~= "table" or type(icons.image) ~= "string"
        or icons.image == ""
    then
        return {}
    end
    local regions = {}
    for name, value in pairs(icons.regions or {}) do
        local normalized = rect(value)
        if normalized then regions[tostring(name)] = normalized end
    end
    return {
        icons = {
            image = icons.image,
            width = number(icons.width, 0),
            height = number(icons.height, 0),
            cell = number(icons.cell, 0),
            regions = regions,
        },
    }
end

local function indexDevices(document)
    M.devices, M.byID, M.byFullType = {}, {}, {}
    for _, rawDevice in ipairs(document.devices or {}) do
        local device = normalizeDevice(rawDevice)
        if device then
            M.devices[#M.devices + 1] = device
            M.byID[device.id] = device
            M.byFullType[device.fullType] = device
        end
    end
    table.sort(M.devices, function(left, right)
        return left.fullType < right.fullType
    end)
end

function M.Load()
    if M.loaded then return M.error == nil, M.error end
    local text, readError = readManifest()
    if not text then
        M.error = readError or "manifest_unreadable"
        M.loaded = true
        print("[PsychopatzCore][RadioOS] runtime manifest unavailable: "
            .. tostring(M.error))
        return false, M.error
    end
    local document, parseError = Json.Decode(text, {
        maxString = MAX_BYTES,
        maxDepth = 24,
        maxCollection = 4096,
    })
    if type(document) ~= "table" then
        M.error = parseError or "manifest_invalid"
        M.loaded = true
        print("[PsychopatzCore][RadioOS] runtime manifest invalid: "
            .. tostring(M.error))
        return false, M.error
    end
    if tonumber(document.schema_version) ~= M.schemaVersion
        or document.manifest_kind ~= M.manifestKind
    then
        M.error = "manifest_schema_unsupported"
        M.loaded = true
        print("[PsychopatzCore][RadioOS] runtime manifest schema rejected")
        return false, M.error
    end
    M.ui = normalizeUI(document.ui)
    indexDevices(document)
    M.loaded = true
    M.error = nil
    local iconCount = 0
    if M.ui.icons then
        for _ in pairs(M.ui.icons.regions or {}) do iconCount = iconCount + 1 end
    end
    print("[PsychopatzCore][RadioOS] runtime manifest loaded: devices="
        .. tostring(#M.devices) .. " icons=" .. tostring(iconCount))
    return true
end

function M.GetDevice(value)
    M.Load()
    value = tostring(value or "")
    return M.byFullType[value] or M.byID[value]
end

function M.GetSkin(value)
    return M.GetDevice(value)
end

function M.GetIcon(value)
    M.Load()
    local icons = M.ui and M.ui.icons
    local name = tostring(value or "")
    if not icons or name == "" then return nil, nil end
    return icons.image, icons.regions[name]
end

function M.ListDevices()
    M.Load()
    local result = {}
    for index, device in ipairs(M.devices) do result[index] = device end
    return result
end

M.Load()

return M
