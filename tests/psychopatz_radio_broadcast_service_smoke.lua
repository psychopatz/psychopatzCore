local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. ROOT .. "shared/?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local callbackCount = 0
local aired
PsychopatzCore = {
    CustomRadio = {
        AirEvent = function(channelID, eventType, context)
            aired = {
                channelID = channelID,
                eventType = eventType,
                context = context,
            }
            return true, { lines = { { text = "broadcast" } } }
        end,
    },
}

dofile(ROOT .. "shared/PsychopatzCore/Radio/PsychopatzRadioBroadcasts.lua")
local Broadcasts = PsychopatzCore.RadioBroadcasts
equal(Broadcasts.RegisterProvider("test.provider", {
    channelID = "core.open_band",
    onAired = function(result)
        equal(result.channelID, "core.open_band",
            "callback receives the resolved channel")
        callbackCount = callbackCount + 1
    end,
}), true, "provider registers")

local context = { eventType = "news" }
local accepted, message, returnedContext = Broadcasts.Air("test.provider", {
    eventType = "news", context = context,
})
equal(accepted, true, "broadcast is accepted")
equal(message.lines[1].text, "broadcast", "message is preserved")
equal(returnedContext, context, "context is preserved")
equal(aired.channelID, "core.open_band", "provider channel is used")
equal(aired.eventType, "news", "event type is preserved")
equal(callbackCount, 1, "post-air hook runs once")

local rejected, reason = Broadcasts.Air("missing.provider", {})
equal(rejected, false, "unknown provider is rejected")
equal(reason, "broadcast_provider_unavailable",
    "unknown provider reports a stable reason")

print("psychopatz_radio_broadcast_service_smoke: ok")
