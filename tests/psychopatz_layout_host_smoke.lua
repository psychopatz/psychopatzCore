local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/"

PsychopatzCore = {
    UI = {
        Layout = {
            Scale = function() return 1 end,
        },
    },
}
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] =
    function() return PsychopatzCore.UI.Layout end
local LayoutHost = dofile(ROOT .. "Components/PsychopatzLayoutHost.lua")

local window = { width = 100, height = 80, uiScale = 1 }
function window:getWidth() return self.width end
function window:getHeight() return self.height end
local layoutCalls = 0
function window:onResponsiveLayout() layoutCalls = layoutCalls + 1 end

LayoutHost.Install(window)
assert(LayoutHost.Perform(window, false) == true,
    "initial layout was not performed")
assert(layoutCalls == 1, "initial layout callback count changed")
assert(LayoutHost.Perform(window, false) == false,
    "unchanged layout was performed again")
LayoutHost.Invalidate(window, "test_change")
assert(LayoutHost.Perform(window, false) == true,
    "invalidated layout was not performed")
assert(layoutCalls == 2, "invalidated layout callback did not run")

local failingWindow = { width = 100, height = 80, uiScale = 1 }
function failingWindow:getWidth() return self.width end
function failingWindow:getHeight() return self.height end
function failingWindow:onResponsiveLayout() error("expected layout failure") end
LayoutHost.Install(failingWindow)
local failed = pcall(function() LayoutHost.Perform(failingWindow, false) end)
assert(failed == false, "layout failure was silently swallowed")
assert(LayoutHost.IsDirty(failingWindow),
    "failed layout was incorrectly committed as clean")

print("psychopatz_layout_host_smoke: ok")
