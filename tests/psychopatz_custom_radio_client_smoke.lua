local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. ROOT .. "shared/?.lua;" .. ROOT .. "client/?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local tickCallback
local originalReads = 0
local clock = 5000
Events = {
    OnTick = { Add = function(callback) tickCallback = callback end },
}
RWMChannel = {
    readFromObject = function() originalReads = originalReads + 1; return true end,
}
package.preload["RadioCom/RadioWindowModules/RWMChannel"] = function()
    return RWMChannel
end
getText = function(key)
    return key == "UI_TestScan" and "Scan for Frequencies" or key
end
getTimestampMs = function() return clock end

local function list()
    local values = {}
    return {
        values = values,
        size = function(self) return #self.values end,
        get = function(self, index) return self.values[index + 1] end,
        add = function(self, value) self.values[#self.values + 1] = value end,
    }
end

PresetEntry = {
    new = function(name, frequency)
        return {
            getName = function() return name end,
            getFrequency = function() return frequency end,
        }
    end,
}

dofile(ROOT .. "shared/PsychopatzCore/00_PsychopatzCore_Init.lua")
local Radio = PsychopatzCore.CustomRadio
Radio.RegisterChannel({
    id = "test.scan", name = "Fallback", nameKey = "UI_TestScan",
    guid = "TEST-SCAN", frequency = 144200, autoPreset = true,
})

local presets = list()
local transmissions = 0
local volume = 0.1
local mutedMicrophone = false
local data = {
    getDevicePresets = function()
        return {
            getPresets = function() return presets end,
            getMaxPresets = function() return 10 end,
        }
    end,
    getMinChannelRange = function() return 75000 end,
    getMaxChannelRange = function() return 150000 end,
    transmitPresets = function() transmissions = transmissions + 1 end,
    getIsTurnedOn = function() return true end,
    getPower = function() return 1 end,
    getIsPortable = function() return true end,
    getIsTwoWay = function() return true end,
    getIsTelevision = function() return false end,
    getDeviceVolume = function() return volume end,
    getMicIsMuted = function() return mutedMicrophone end,
    getChannel = function() return 144200 end,
}

local item = { getDeviceData = function() return data end }
instanceof = function(value, typeName)
    return value == item and typeName == "Radio"
end
local player = {
    isDead = function() return false end,
    getPrimaryHandItem = function() return nil end,
    getSecondaryHandItem = function() return nil end,
    getAttachedItems = function()
        return {
            size = function() return 1 end,
            get = function()
                return { getItem = function() return item end }
            end,
        }
    end,
}
getSpecificPlayer = function(playerNum)
    return playerNum == 0 and player or nil
end

dofile(ROOT .. "client/PsychopatzCore/Radio/PsychopatzCustomRadioClient.lua")
local panel = setmetatable({}, { __index = RWMChannel })
equal(panel:readFromObject(player, item, data, "InventoryItem"), true,
    "vanilla radio panel still runs")
equal(originalReads, 1, "preset injection preserves vanilla read behavior")
equal(presets:size(), 1, "custom channel appears as a vanilla preset")
equal(presets:get(0):getName(), "Scan for Frequencies",
    "preset uses localized channel name")
equal(transmissions, 1, "new preset synchronizes once")
panel:readFromObject(player, item, data, "InventoryItem")
equal(presets:size(), 1, "opening the radio never duplicates the preset")
equal(transmissions, 1, "existing preset does not retransmit")

local listened = 0
Radio.RegisterListener("test.scan", "test", function(context)
    equal(context.deviceData, data, "listener receives native device data")
    listened = listened + 1
end)
tickCallback()
equal(listened, 1, "belt-attached tuned radio activates channel listener")

volume = 0
clock = 10000
tickCallback()
equal(listened, 1, "muted speaker suppresses channel listener")

volume = 0.1
mutedMicrophone = true
clock = 15000
tickCallback()
equal(listened, 1, "muted microphone suppresses channel listener")

print("psychopatz_custom_radio_client_smoke: ok")
