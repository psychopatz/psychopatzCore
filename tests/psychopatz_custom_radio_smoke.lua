local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. ROOT .. "shared/?.lua;" .. ROOT .. "server/?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local loadCallback
Events = {
    OnLoadRadioScripts = {
        Add = function(callback) loadCallback = callback end,
    },
}
ChannelCategory = {
    Radio = "Radio", Emergency = "Emergency", Television = "Television",
    Military = "Military", Amateur = "Amateur", Bandit = "Bandit",
    Other = "Other",
}

local createdNative
DynamicRadioChannel = {
    new = function(name, frequency, category, guid)
        createdNative = {
            name = name, frequency = frequency,
            category = category, guid = guid,
            setAirCounterMultiplier = function() end,
            setAiringBroadcast = function(self, value)
                self.broadcast = value
            end,
        }
        return createdNative
    end,
}
RadioBroadCast = {
    new = function(id)
        return {
            id = id,
            lines = {},
            AddRadioLine = function(self, line)
                self.lines[#self.lines + 1] = line
            end,
        }
    end,
}
RadioLine = {
    new = function(text, r, g, b, effects)
        return {
            text = text, r = r, g = g, b = b, effects = effects,
            setAirTime = function(self, value) self.airTime = value end,
        }
    end,
}
getTimestampMs = function() return 1234 end

dofile(ROOT .. "shared/PsychopatzCore/00_PsychopatzCore_Init.lua")
local Radio = PsychopatzCore.CustomRadio
equal(Radio.RegisterChannel({
    id = "test.scan", name = "Scan", guid = "TEST-SCAN",
    frequency = 144200, category = "Amateur",
}), true, "custom channel registers")

Radio.RegisterMessagePack("test.generic", {
    channel = "test.scan", eventType = "discovery", priority = 0,
    messages = { { lines = { "Generic {location}" } } },
})
Radio.RegisterMessagePack("test.refugee", {
    channel = "test.scan", eventType = "discovery", priority = 100,
    matches = function(context) return context.kind == "refugee" end,
    messages = { { lines = { "Help near {location}", "<fzzt>" } } },
})

local selected = Radio.SelectMessage("test.scan", "discovery", {
    kind = "refugee", location = "grid 10, 20",
    random = function() return 1 end,
})
equal(selected.packID, "test.refugee",
    "highest-priority matching flavor pack wins")
equal(selected.lines[1].text, "Help near grid 10, 20",
    "message tokens expand from event context")
equal(selected.lines[1].displayText, nil,
    "radio selection keeps Markdown out of the received message")

local manager = {
    getRadioChannel = function() return nil end,
    AddChannel = function(self, channel) self.added = channel end,
}
dofile(ROOT .. "server/PsychopatzCore/Radio/PsychopatzCustomRadioServer.lua")
loadCallback(manager, true)
equal(manager.added, createdNative, "channel uses native radio registration")
local aired = Radio.AirEvent("test.scan", "discovery", {
    kind = "refugee", location = "grid 10, 20",
    random = function() return 1 end,
})
equal(aired, true, "native broadcast airs")
equal(createdNative.broadcast.lines[1].text, "Help near grid 10, 20",
    "native broadcast receives selected custom text")

Radio.RegisterMessagePack("test.markdown", {
    channel = "test.scan", eventType = "markdown", priority = 10,
    messages = { { lines = { "**Help** *chuckles*" } } },
})
local markdownSelected = Radio.SelectMessage("test.scan", "markdown", {
    random = function() return 1 end,
})
equal(markdownSelected.lines[1].text, "**Help** *chuckles*",
    "radio keeps canonical Markdown text for diagnostics")
equal(markdownSelected.lines[1].displayText, nil,
    "radio does not derive display text during message selection")
local markdownAired = Radio.AirEvent("test.scan", "markdown", {
    random = function() return 1 end,
})
equal(markdownAired, true, "Markdown radio broadcast airs")
equal(createdNative.broadcast.lines[1].text, "Help chuckles",
    "native broadcast uses the Markdown display projection")

local listens = 0
Radio.RegisterListener("test.scan", "test.listener", function()
    listens = listens + 1
end)
equal(Radio.NotifyTuned("test.scan", {}), 1,
    "registered tune listeners are reusable across mods")
equal(listens, 1, "tune listener runs")

print("psychopatz_custom_radio_smoke: ok")
