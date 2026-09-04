local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/Radio/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PsychopatzCore = {}
getTexture = function(path) return path end
getTimestampMs = function() return 1000 end
dofile(ROOT .. "PC_RadioImageAnimation.lua")

local Animation = PsychopatzCore.RadioImageAnimation
local controller = Animation.New({ frameDuration = 200 })

equal(Animation.SignalPath("found", 2),
    "media/ui/Radio/Signal_found/2.png",
    "core exposes the shared found signal asset path")
equal(Animation.SignalPath("none", 1),
    "media/ui/Radio/Signal_none/1.png",
    "core exposes the shared no-signal asset path")
equal(Animation.SignalPath("search", 5),
    "media/ui/Radio/Signal_search/5.png",
    "core exposes the shared search signal asset path")
equal(controller:GetPath(false, 1000),
    "media/ui/Radio/Signal_found/2.png",
    "inactive radio uses the idle frame")
equal(controller:GetPath(true, 1000),
    "media/ui/Radio/Signal_search/1.png",
    "active radio starts at search frame one")
equal(controller:GetPath(true, 1199),
    "media/ui/Radio/Signal_search/1.png",
    "search frame holds for its duration")
equal(controller:GetPath(true, 1200),
    "media/ui/Radio/Signal_search/2.png",
    "search frame advances at the configured cadence")
equal(controller:GetPath(true, 2000),
    "media/ui/Radio/Signal_search/1.png",
    "search animation loops")
equal(controller:GetTexture(false, 2200),
    "media/ui/Radio/Signal_found/2.png",
    "idle texture is resolved from the shared radio media path")

print("psychopatz_radio_image_animation_smoke: ok")
