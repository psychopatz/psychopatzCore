local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PsychopatzCore = {}
dofile(ROOT .. "PsychopatzCore/Radio/PC_RadioDeviceState.lua")
local State = PsychopatzCore.RadioDeviceState

local volume = 0.1
local mutedMicrophone = false
local turnedOn = true
local power = 1
local data = {
    getIsPortable = function() return true end,
    getIsTwoWay = function() return true end,
    getIsTelevision = function() return false end,
    getIsTurnedOn = function() return turnedOn end,
    getPower = function() return power end,
    getDeviceVolume = function() return volume end,
    getMicIsMuted = function() return mutedMicrophone end,
}
local item = { getDeviceData = function() return data end }
local player = {
    getPrimaryHandItem = function() return item end,
}

equal(State.FindPlayerDevice(player), item,
    "player device lookup accepts a present but inactive radio")
equal(State.HasPlayerDevice(player), true,
    "player radio presence is separate from active radio state")

equal(State.IsActive(data), true, "audible unmuted radio is active")
equal(State.IsActive(item), true, "item device resolves to device data")

volume = 0
local active, reason = State.Validate(data)
equal(active, false, "zero volume disables radio")
equal(reason, "muted_volume", "zero volume reason")

volume = 0.1
mutedMicrophone = true
active, reason = State.Validate(data)
equal(active, false, "muted microphone disables radio")
equal(reason, "muted_microphone", "muted microphone reason")

mutedMicrophone = false
turnedOn = false
active, reason = State.Validate(data)
equal(active, false, "turned off radio disables radio")
equal(reason, "turned_off", "turned off reason")

turnedOn = true
power = 0
active, reason = State.Validate(data)
equal(active, false, "empty radio disables radio")
equal(reason, "no_power", "empty radio reason")

print("psychopatz_radio_device_state_smoke: ok")
