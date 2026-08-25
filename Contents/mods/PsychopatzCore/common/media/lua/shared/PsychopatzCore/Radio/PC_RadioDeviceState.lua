PsychopatzCore = PsychopatzCore or {}

local RadioDeviceState = PsychopatzCore.RadioDeviceState or {}
PsychopatzCore.RadioDeviceState = RadioDeviceState

local function getDeviceData(device)
    if not device then return nil end
    if device.getDeviceData then
        return device:getDeviceData()
    end
    return device
end

-- DeviceData stores volume as a normalized value from 0 to 1.  The vanilla
-- radio UI treats any value above zero as at least one audible volume step.
function RadioDeviceState.Validate(device)
    local data = getDeviceData(device)
    if not data then return false, "missing_device_data" end
    if not data.getIsPortable or not data:getIsPortable() then
        return false, "not_portable"
    end
    if not data.getIsTwoWay or not data:getIsTwoWay() then
        return false, "not_two_way"
    end
    if not data.getIsTelevision or data:getIsTelevision() then
        return false, "television"
    end
    if not data.getIsTurnedOn or not data:getIsTurnedOn() then
        return false, "turned_off"
    end
    if not data.getPower or data:getPower() <= 0 then
        return false, "no_power"
    end
    if not data.getDeviceVolume or data:getDeviceVolume() <= 0 then
        return false, "muted_volume"
    end
    if not data.getMicIsMuted or data:getMicIsMuted() then
        return false, "muted_microphone"
    end
    return true, nil
end

function RadioDeviceState.IsActive(device)
    local valid = RadioDeviceState.Validate(device)
    return valid == true
end

function RadioDeviceState.GetDeviceData(device)
    return getDeviceData(device)
end

local function isRadioItem(item)
    if not item then return false end
    if instanceof then return instanceof(item, "Radio") end
    local data = getDeviceData(item)
    return data and data.getIsPortable and data:getIsPortable()
        and data.getIsTwoWay and data:getIsTwoWay() or false
end

function RadioDeviceState.GetPlayerDevices(player)
    local output, seen = {}, {}
    local function add(item)
        if not isRadioItem(item) or seen[item] then return end
        seen[item] = true
        output[#output + 1] = item
    end
    if player and player.getEquipedRadio then
        add(player:getEquipedRadio())
    end
    if player and player.getPrimaryHandItem then
        add(player:getPrimaryHandItem())
    end
    if player and player.getSecondaryHandItem then
        add(player:getSecondaryHandItem())
    end
    local attached = player and player.getAttachedItems
        and player:getAttachedItems() or nil
    if attached then
        for index = 0, attached:size() - 1 do
            local attachment = attached:get(index)
            add(attachment and attachment:getItem() or nil)
        end
    end
    return output
end

function RadioDeviceState.FindPlayerDevice(player)
    for _, item in ipairs(RadioDeviceState.GetPlayerDevices(player)) do
        return item
    end
    return nil
end

function RadioDeviceState.HasPlayerDevice(player)
    return RadioDeviceState.FindPlayerDevice(player) ~= nil
end

function RadioDeviceState.FindActivePlayerDevice(player)
    for _, item in ipairs(RadioDeviceState.GetPlayerDevices(player)) do
        if RadioDeviceState.IsActive(item) then return item end
    end
    return nil
end

return RadioDeviceState
