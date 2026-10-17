local ROOT = "Contents/mods/PsychopatzCore/"
local CLIENT = ROOT .. "42.20/media/lua/client/"
local COMMON = ROOT .. "common/media/lua/shared/"

package.path = CLIENT .. "?.lua;" .. COMMON .. "?.lua;" .. package.path

PsychopatzCore = nil
getFileReader = nil
local savedText
getFileWriter = function()
    return {
        write = function(_, value) savedText = value end,
        close = function() end,
    }
end
local clock = 1000
getTimeInMillis = function()
    clock = clock + 16
    return clock
end
getCore = function()
    return {
        getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 900 end,
    }
end

local Diagnostics = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDiagnostics.lua")
local Settings = PsychopatzCore.DebugSettings

assert(Settings.GetDefinition(Diagnostics.PRESENTATION_SETTING),
    "presentation diagnostic setting was not registered")
assert(Settings.GetDefinition(Diagnostics.PERFORMANCE_SETTING),
    "performance diagnostic setting was not registered")
assert(Settings.GetDefinition(Diagnostics.LAYOUT_INSPECTOR_SETTING),
    "layout inspector setting was not registered")
assert(Settings.GetDefinition(Diagnostics.COMPOSITOR_SETTING),
    "compositor overlay setting was not registered")
assert(Settings.IsRuntimeMutable(Diagnostics.PRESENTATION_SETTING),
    "presentation diagnostic setting is not live-mutable")
assert(Settings.IsRuntimeMutable(Diagnostics.LAYOUT_INSPECTOR_SETTING),
    "layout inspector setting is not live-mutable")
assert(not Diagnostics.IsPresentationEnabled(),
    "presentation diagnostics must start disabled")
assert(not Diagnostics.IsPerformanceEnabled(),
    "performance diagnostics must start disabled")
assert(not Diagnostics.IsLayoutInspectorEnabled(),
    "layout inspector must start disabled")

local window = {
    x = 400, y = 500, width = 300, height = 600,
    visible = true,
    playerNum = 0,
    owner = "auto",
    openSource = "equip",
    presentationMode = "immersive",
    presentationState = "docked",
    context = { fullType = "Base.WalkieTalkie5" },
    dockX = 0.5,
    dockBottomOffset = 12,
    presentationVisibleFraction = 0.75,
    _textures = { shell = true },
    _presentationVisibleHeight = 450,
    visibleBodyBottom = function() return 450 end,
    dockPosition = function() return 490, 500 end,
    hiddenPositionY = function() return 850 end,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getWidth = function(self) return self.width end,
    getHeight = function(self) return self.height end,
    getIsVisible = function(self) return self.visible end,
    setMaxDrawHeight = function() end,
}

local compositorState = false
PsychopatzCore.RadioOS.SetCompositorDebug = function(enabled)
    compositorState = enabled == true
end
Settings.GetDefinition(Diagnostics.COMPOSITOR_SETTING).apply(false)
assert(not compositorState, "compositor setting did not disable overlay")

assert(Settings.Set(Diagnostics.PRESENTATION_SETTING, true, true),
    "presentation setting did not persist")
assert(string.find(savedText,
    "setting.PsychopatzCore.RadioOS.PresentationDiagnostics=true", 1, true),
    "presentation setting was not written to the central debug file")
assert(Settings.ApplyConfigured(), "presentation setting did not apply")
assert(Diagnostics.IsPresentationEnabled(),
    "applied presentation setting did not enable diagnostics")
assert(Diagnostics.RecordWindow("window.open", window, {
    requestedAnimate = true,
}), "presentation event was not recorded")
assert(#Diagnostics.events == 1, "presentation event ring did not append")
assert(Diagnostics.events[1].data.fullType == "Base.WalkieTalkie5",
    "window snapshot omitted device identity")
local presentationSnapshot = Diagnostics.GetSnapshot(window)
assert(presentationSnapshot.artSurfaceClipped == false,
    "diagnostics must prove the authored radio surface is not cropped")
assert(presentationSnapshot.viewportVisibleHeight == 450,
    "diagnostics must report viewport visibility separately from art bounds")

Diagnostics.SetPerformanceEnabled(true)
for _ = 1, 20 do
    local token = Diagnostics.BeginFrame(window, "prerender")
    Diagnostics.EndFrame(window, token)
end
local performance = Diagnostics.GetPerformanceSnapshot(window)
assert(performance.prerender_calls == 20,
    "performance call counter did not advance")
assert(performance.prerender_samples > 0,
    "performance sampler did not capture a bounded sample")

local before = #Diagnostics.events
Diagnostics.SetPresentationEnabled(false)
assert(not Diagnostics.RecordPresentation("should_not_record", window),
    "disabled presentation diagnostics allocated an event")
assert(#Diagnostics.events == before,
    "disabled presentation diagnostics changed the event ring")

print("psychopatz_radio_os_diagnostics_smoke: ok")
