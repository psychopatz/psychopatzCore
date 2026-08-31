PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Keybinds = PsychopatzCore.Keybinds or {}

local Keybinds = PsychopatzCore.Keybinds

Keybinds.TYPE_PRESS = Keybinds.TYPE_PRESS or "press"
Keybinds.TYPE_LONG_PRESS = Keybinds.TYPE_LONG_PRESS or "longpress"
Keybinds.DEFAULT_LONG_PRESS_MS = Keybinds.DEFAULT_LONG_PRESS_MS or 500
Keybinds.bindings = Keybinds.bindings or {}

-- PZAPI owns the native Options > Mods presentation and persistence.
pcall(require, "PZAPI/ModOptions")

local OPTIONS_ID = "PsychopatzCore"

local function resolveKeyCode(value)
    if type(value) == "number" then
        return math.floor(value)
    end
    if type(value) == "string" and getKeyCode then
        return tonumber(getKeyCode(value)) or 0
    end
    return 0
end

local function settingsOptions()
    local modOptions = PZAPI and PZAPI.ModOptions
    if not modOptions then return nil end

    local options = modOptions.getOptions
        and modOptions:getOptions(OPTIONS_ID)
        or nil
    if not options and modOptions.create then
        options = modOptions:create(
            OPTIONS_ID,
            "UI_PsychopatzCore_SettingsTitle"
        )
    end
    if not options then return nil end

    if not options._psychopatzCoreKeybindTitleAdded
        and options.addTitle then
        options:addTitle("UI_PsychopatzCore_KeybindingsSection")
        options._psychopatzCoreKeybindTitleAdded = true
    end
    return options
end

local function createOption(definition)
    local options = settingsOptions()
    if not options then return nil end

    local option = options.getOption
        and options:getOption(definition.id)
        or nil
    if option then return option end
    if not options.addKeyBind then return nil end

    return options:addKeyBind(
        definition.id,
        definition.label or definition.id,
        definition.defaultKey,
        definition.tooltip
    )
end

local function bindingFrom(value)
    if type(value) == "table" then return value end
    return Keybinds.bindings[tostring(value or "")]
end

local function keyCodeFor(binding)
    if not binding then return 0 end
    if binding.option and binding.option.getValue then
        return tonumber(binding.option:getValue()) or 0
    end
    return tonumber(binding.defaultKey) or 0
end

local function isKeyDown(key)
    if key <= 0 or not isKeyDown then return false end
    local ok, value = pcall(_G.isKeyDown, key)
    return ok and value == true
end

local function isKeyPressed(key)
    if key <= 0 or not isKeyPressed then return false end
    local ok, value = pcall(_G.isKeyPressed, key)
    return ok and value == true
end

local function nowMs()
    if getTimeInMillis then
        return tonumber(getTimeInMillis()) or 0
    end
    return 0
end

local function isEnabled(binding)
    if type(binding.isEnabled) ~= "function" then return true end
    local ok, enabled = pcall(binding.isEnabled, binding)
    return ok and enabled == true
end

local function invoke(binding)
    if type(binding.onTrigger) ~= "function" then return end
    local ok, reason = pcall(binding.onTrigger, binding)
    if not ok and print then
        print("[PsychopatzCore.Keybinds] " .. tostring(binding.id)
            .. " failed: " .. tostring(reason))
    end
end

local function resetLongPressState(binding, key)
    local state = binding.state or {}
    binding.state = state
    state.key = key
    state.startedAt = nil
    state.triggered = false
    return state
end

local function processLongPress(binding, key)
    local state = binding.state
    if not state or state.key ~= key then
        state = resetLongPressState(binding, key)
    end

    if key <= 0 or not isKeyDown(key) then
        state.startedAt = nil
        state.triggered = false
        return
    end

    if not state.startedAt then
        state.startedAt = nowMs()
    end

    local threshold = math.max(
        1,
        tonumber(binding.longPressMs) or Keybinds.DEFAULT_LONG_PRESS_MS
    )
    if not state.triggered and nowMs() - state.startedAt >= threshold then
        state.triggered = true
        invoke(binding)
    end
end

function Keybinds.Register(definition)
    if type(definition) ~= "table" then return false end

    local id = tostring(definition.id or "")
    if id == "" then return false end
    if definition.type ~= Keybinds.TYPE_PRESS
        and definition.type ~= Keybinds.TYPE_LONG_PRESS then
        return false
    end
    if type(definition.onTrigger) ~= "function" then return false end

    definition.id = id
    definition.defaultKey = resolveKeyCode(
        definition.defaultKey or definition.key
    )
    definition.longPressMs = math.max(
        1,
        tonumber(definition.longPressMs) or Keybinds.DEFAULT_LONG_PRESS_MS
    )
    definition.option = createOption(definition)

    local existing = Keybinds.bindings[id]
    if existing then
        existing.type = definition.type
        existing.label = definition.label or existing.label or id
        existing.tooltip = definition.tooltip or existing.tooltip
        existing.defaultKey = definition.defaultKey
        existing.longPressMs = definition.longPressMs
        existing.onTrigger = definition.onTrigger
        existing.isEnabled = definition.isEnabled
        existing.option = definition.option or existing.option
        return existing
    end

    definition.state = {}
    Keybinds.bindings[id] = definition
    return definition
end

function Keybinds.RegisterPress(definition)
    if type(definition) ~= "table" then return false end
    local copy = {}
    for key, value in pairs(definition) do copy[key] = value end
    copy.type = Keybinds.TYPE_PRESS
    return Keybinds.Register(copy)
end

function Keybinds.RegisterLongPress(definition)
    if type(definition) ~= "table" then return false end
    local copy = {}
    for key, value in pairs(definition) do copy[key] = value end
    copy.type = Keybinds.TYPE_LONG_PRESS
    return Keybinds.Register(copy)
end

function Keybinds.Unregister(id)
    id = tostring(id or "")
    if not Keybinds.bindings[id] then return false end
    Keybinds.bindings[id] = nil
    return true
end

function Keybinds.Get(id)
    return bindingFrom(id)
end

function Keybinds.GetKeyCode(value)
    return keyCodeFor(bindingFrom(value))
end

function Keybinds.IsDown(value)
    return isKeyDown(Keybinds.GetKeyCode(value))
end

function Keybinds.IsPressed(value)
    return isKeyPressed(Keybinds.GetKeyCode(value))
end

function Keybinds.OnTick()
    for _, binding in pairs(Keybinds.bindings) do
        local key = keyCodeFor(binding)
        if not isEnabled(binding) then
            if binding.type == Keybinds.TYPE_LONG_PRESS then
                resetLongPressState(binding, key)
            end
        elseif binding.type == Keybinds.TYPE_PRESS then
            if isKeyPressed(key) then invoke(binding) end
        elseif binding.type == Keybinds.TYPE_LONG_PRESS then
            processLongPress(binding, key)
        end
    end
end

if Events and Events.OnTick and not Keybinds._tickHookRegistered then
    Events.OnTick.Add(Keybinds.OnTick)
    Keybinds._tickHookRegistered = true
end

local function loadOptions()
    if Keybinds._optionsLoaded then return end
    local modOptions = PZAPI and PZAPI.ModOptions
    if modOptions and modOptions.load then
        pcall(function() modOptions:load() end)
    end
    Keybinds._optionsLoaded = true
end

if Events and Events.OnGameBoot and not Keybinds._optionsLoadHookRegistered then
    Events.OnGameBoot.Add(loadOptions)
    Keybinds._optionsLoadHookRegistered = true
end

return Keybinds
