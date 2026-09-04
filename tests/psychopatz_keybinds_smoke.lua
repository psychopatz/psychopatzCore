local ROOT =
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/"

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
    return name == "T" and 20 or 34
end
getTimeInMillis = function() return now end
-- Exercise the same numeric Keyboard API available in the game runtime.
-- The globals below intentionally fail so the compatibility fallback is
-- covered as well.
Keyboard = {
    isKeyDown = function(key) return key == downKey end,
    isKeyPressed = function(key) return key == pressedKey end,
}
isKeyDown = function() error("numeric global stub should not be used") end
isKeyPressed = function() error("numeric global stub should not be used") end
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
    self.data[#self.data + 1] = option
    self.dict[id] = option
    return option
end
function options:getOption(id) return self.dict[id] end

PZAPI = {
    ModOptions = {
        getOptions = function() return options end,
        load = function() bootCount = bootCount + 1 end,
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
equal(#options.data, 3, "settings entries")

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

print("psychopatz keybinds: ok")
