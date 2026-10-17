local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON .. "?.lua;" .. package.path

getModFileReader = function(_, filename, _)
    local handle = assert(io.open("Contents/mods/PsychopatzCore/common/"
        .. filename, "r"))
    return {
        readLine = function() return handle:read("*l") end,
        close = function() handle:close() end,
    }
end

local Manifest = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioRuntimeManifest.lua")
assert(Manifest.loaded and not Manifest.error, "runtime manifest failed to load")
assert(#Manifest.devices == 10, "expected all ten canonical radio devices")

local seen = {}
for _, device in ipairs(Manifest.devices) do
    assert(not seen[device.fullType], "duplicate fullType: " .. device.fullType)
    seen[device.fullType] = true
    assert(device.chassis.pristine and device.chassis.worn,
        "missing chassis variants: " .. device.id)
    local expectedControls = device.id == "ham_makeshift" and 6 or 8
    assert(#device.interactiveComponents == expectedControls,
        "unexpected active control count: " .. device.id)
end

local w5 = assert(Manifest.GetDevice("Base.WalkieTalkie5"))
assert(w5.id == "walkie_5")
assert(w5.components[1].states ~= nil)
print("psychopatz_radio_runtime_manifest_smoke: ok")
