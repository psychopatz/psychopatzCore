local T = require "tests/support/test"
T.addPackagePaths()

local ROOT =
    T.path("runtime_client", "PsychopatzCore/")

local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "mismatch") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local downKey = 0
local pressedKey = 0
local bootCount = 0
local tickCount = 0

getKeyCode = function(name)
    local keys = { T = 20, G = 34, D = 44, H = 50 }
    return keys[name] or 34
end
getTimeInMillis = function() return now end
-- Exercise the same numeric Keyboard API available in the game runtime.
-- The globals below intentionally report false so the raw Keyboard fallback
-- is covered as well. This mirrors multiplayer chat/text-entry suppression.
Keyboard = {
    isKeyDown = function(key) return key == downKey end,
    isKeyPressed = function(key) return key == pressedKey end,
}
isKeyDown = function() return false end
isKeyPressed = function() return false end
getText = function(key) return key end

Events = {
    OnGameBoot = {
        Add = function(callback) Events.boot = callback end,
    },
    OnTick = {
        Add = function(callback)
            Events.tick = callback
            tickCount = tickCount + 1
        end,
    },
}

local options = {
    data = {},
    dict = {},
}
function options:addTitle(name)
    self.data[#self.data + 1] = { type = "title", name = name }
end
function options:addKeyBind(id, name, key, tooltip)
    local option = {
        id = id,
        name = name,
        key = key,
        defaultkey = key,
        tooltip = tooltip,
    }
    function option:getValue() return self.key end
    function option:setValue(v) self.key = v end
    self.data[#self.data + 1] = option
    self.dict[id] = option
    return option
end
function options:getOption(id) return self.dict[id] end

local saveCount = 0
local forceLegacyOnLoad = false
PZAPI = {
    ModOptions = {
        getOptions = function() return options end,
        load = function()
            bootCount = bootCount + 1
            if forceLegacyOnLoad and options.dict["Smoke.Migrated"] then
                options.dict["Smoke.Migrated"].key = 47
            end
        end,
        save = function() saveCount = saveCount + 1 end,
    },
}

PsychopatzCore = {}
local Keybinds = dofile(ROOT .. "Input/PsychopatzKeybinds.lua")

equal(tickCount, 1, "keybind tick hook")
equal(Keybinds.RegisterPress({
    id = "Smoke.Press",
    label = "Smoke press",
    defaultKey = getKeyCode("G"),
    onTrigger = function() _G.pressCount = (_G.pressCount or 0) + 1 end,
}) ~= false, true, "press registration")
equal(Keybinds.RegisterLongPress({
    id = "Smoke.Long",
    label = "Smoke long press",
    defaultKey = getKeyCode("T"),
    longPressMs = 500,
    onTrigger = function() _G.longCount = (_G.longCount or 0) + 1 end,
}) ~= false, true, "long press registration")
equal(Keybinds.RegisterTapLongPress({
    id = "Smoke.TapLong",
    label = "Smoke tap-long press",
    defaultKey = getKeyCode("D"),
    longPressMs = 500,
    onTap = function() _G.tapCount = (_G.tapCount or 0) + 1 end,
    onLongPress = function()
        _G.tapLongCount = (_G.tapLongCount or 0) + 1
    end,
}) ~= false, true, "tap-long press registration")
equal(#options.data, 4, "settings entries")
equal(Keybinds.RegisterPress({
    id = "Smoke.Hidden",
    label = "Hidden press",
    exposeInOptions = false,
    defaultKey = getKeyCode("H"),
    onTrigger = function() end,
}) ~= false, true, "hidden press registration")
equal(#options.data, 4, "hidden binding omitted from settings")

Events.boot()
equal(bootCount, 1, "settings loaded at game boot")

pressedKey = 34
Events.tick()
pressedKey = 0
equal(_G.pressCount, 1, "single press trigger")

downKey = 20
now = 1000
Events.tick()
now = 1499
Events.tick()
equal(_G.longCount, nil, "long press fired too early")
now = 1500
Events.tick()
equal(_G.longCount, 1, "long press trigger")
now = 1800
Events.tick()
equal(_G.longCount, 1, "long press repeated while held")

downKey = 0
Events.tick()
downKey = 20
now = 2000
Events.tick()
now = 2500
Events.tick()
equal(_G.longCount, 2, "long press rearmed after release")

downKey = 0
now = 2600
Events.tick()

local longBinding = Keybinds.Get("Smoke.Long")
longBinding.option.key = 34
equal(Keybinds.GetKeyCode(longBinding), 34,
    "runtime reads the rebindable option value")

downKey = 44
now = 3000
Events.tick()
downKey = 0
now = 3001
Events.tick()
equal(_G.tapCount, 1, "tap-long press tap trigger")
equal(_G.tapLongCount, nil, "tap-long press did not fire on tap")

downKey = 44
now = 4000
Events.tick()
now = 4499
Events.tick()
equal(_G.tapLongCount, nil, "tap-long press fired too early")
now = 4500
Events.tick()
equal(_G.tapLongCount, 1, "tap-long press long trigger")
downKey = 0
now = 4501
Events.tick()
equal(_G.tapCount, 1, "tap-long press did not tap after long press")

-- Regression: PZAPI.ModOptions:load() (called at OnGameBoot and again whenever
-- MainOptions opens via Escape/Options) must never revert a migrated keybind
-- back to its deprecatedDefaultKey (e.g. legacy V=47 -> new SLASH=53).
local migratedTriggers = 0
equal(Keybinds.RegisterPress({
    id = "Smoke.Migrated",
    label = "Migrated press",
    defaultKey = 53,
    deprecatedDefaultKey = 47,
    onTrigger = function() migratedTriggers = migratedTriggers + 1 end,
}) ~= false, true, "migrated press registration")
forceLegacyOnLoad = true
PZAPI.ModOptions:load()
equal(Keybinds.GetKeyCode("Smoke.Migrated"), 53,
    "ModOptions:load() must migrate deprecated default key 47 -> 53")
equal(saveCount >= 1, true, "migrated keybind persists via ModOptions:save()")
pressedKey = 47
Events.tick()
equal(migratedTriggers, 0, "deprecated key 47 must not trigger after migration")
pressedKey = 53
Events.tick()
pressedKey = 0
equal(migratedTriggers, 1, "new default key 53 still triggers after ModOptions:load()")

print("psychopatz keybinds: ok")
