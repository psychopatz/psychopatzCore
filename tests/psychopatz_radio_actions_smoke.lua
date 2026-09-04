local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISContextMenu"] = function() return true end
package.preload["RadioCom/ISRadioWindow"] = function() return true end

local function fakeButton(title)
    return {
        width = 118,
        height = 20,
        title = title or "",
        visible = true,
        initialise = function() end,
        instantiate = function() end,
        setVisible = function(self, value) self.visible = value end,
        setTitle = function(self, value) self.title = value end,
        getTitle = function(self) return self.title end,
        setX = function(self, value) self.x = value end,
        setY = function(self, value) self.y = value end,
        setWidth = function(self, value) self.width = value end,
        setHeight = function(self, value) self.height = value end,
        getWidth = function(self) return self.width end,
        getHeight = function(self) return self.height end,
    }
end

ISButton = {
    new = function(_, _, _, width, height, title, target, onclick)
        local button = fakeButton(title)
        button.width = width
        button.height = height
        button.target = target
        button.onclick = onclick
        return button
    end,
}

ISRadioWindow = {
    createChildren = function() end,
    prerender = function() end,
}
PsychopatzCore = {}
dofile("Contents/mods/PsychopatzCore/common/media/lua/shared/"
    .. "PsychopatzCore/Radio/PC_RadioDeviceState.lua")

dofile(ROOT .. "UI/Radio/PsychopatzRadioActions.lua")

local Actions = PsychopatzCore.RadioActions
local calls = {}
assertEqual(Actions.Register({
    id = "smoke.second",
    label = "Second",
    order = 20,
    onClick = function() calls[#calls + 1] = "second" end,
}), true, "register second")
assertEqual(Actions.Register({
    id = "smoke.first",
    label = "First",
    order = 10,
    onClick = function() calls[#calls + 1] = "first" end,
}), true, "register first")
assertEqual(Actions.Register({ id = "invalid" }), false, "invalid registration")

local registered = Actions.List()
assertEqual(#registered, 2, "registered count")
assertEqual(registered[1].id, "smoke.first", "sorted order")

getSpecificPlayer = function() return { id = "player" } end
local radio = {
    playerNum = 0,
    deviceData = {
        isTelevision = function() return false end,
        getIsTwoWay = function() return true end,
        getIsPortable = function() return true end,
        getIsTelevision = function() return false end,
        getIsTurnedOn = function() return true end,
        getPower = function() return 1 end,
        getDeviceVolume = function() return 0.1 end,
        getMicIsMuted = function() return false end,
    },
}
assertEqual(#Actions.GetAvailable(radio), 2, "two available actions")

local boundButton = fakeButton("")
Actions.BindButton(boundButton, registered[1], radio)
assertEqual(boundButton.enable, true, "active radio enables actions")
radio.deviceData.getDeviceVolume = function() return 0 end
Actions.BindButton(boundButton, registered[1], radio)
assertEqual(boundButton.enable, false, "muted speaker disables actions")
radio.deviceData.getDeviceVolume = function() return 0.1 end
radio.deviceData.getMicIsMuted = function() return true end
Actions.BindButton(boundButton, registered[1], radio)
assertEqual(boundButton.enable, false, "muted microphone disables actions")
radio.deviceData.getMicIsMuted = function() return false end

Actions.Register({
    id = "smoke.hidden",
    label = "Hidden",
    isAvailable = function() return false end,
    onClick = function() end,
})
assertEqual(#Actions.GetAvailable(radio), 2, "hidden action excluded")
assertEqual(Actions.Unregister("smoke.second"), true, "unregister action")
assertEqual(Actions.Unregister("smoke.second"), false, "unregister missing action")
assertEqual(#Actions.List(), 2, "remaining actions")

-- A host button supplied by another radio patch is reused, so the shared
-- registry does not place a duplicate service control over the radio window.
Actions.Unregister("smoke.first")
Actions.Unregister("smoke.hidden")
local hostedCalls = 0
Actions.Register({
    id = "smoke.hosted",
    label = "Colony Management",
    shortLabel = "Colony",
    hostButton = "btnColonyManagement",
    hostRequired = true,
    onClick = function() hostedCalls = hostedCalls + 1 end,
})
assertEqual(Actions.HasHostRequest("btnColonyManagement"), true,
    "host request is discoverable by radio integrations")
radio.width = 320
radio.addChild = function(self, child) child.parent = self end
radio.bringChildToFront = function() end
radio.titleBarHeight = function() return 18 end
radio.btnColonyManagement = fakeButton("Legacy Colony")
Actions.Refresh(radio)
assertEqual(radio.btnColonyManagement.title, "Colony", "host gets compact title")
assertEqual(radio.btnColonyManagement.psychopatzRadioActionID,
    "smoke.hosted", "host bound to registered action")
assertEqual(radio.psychopatzRadioActionsButton.visible, false,
    "duplicate shared button hidden")
radio.btnColonyManagement.onclick(radio)
assertEqual(hostedCalls, 1, "host invokes registered action")

-- A host-required action must remain hidden until the owning integration
-- creates its control; it must never fall back into the General header.
radio.btnColonyManagement = nil
Actions.Refresh(radio)
assertEqual(radio.psychopatzRadioActionsButton.visible, false,
    "host-required action has no top-level fallback")

Actions.Unregister("smoke.hosted")
Actions.Register({
    id = "smoke.signal",
    label = "Separate Signal Action",
    placement = Actions.PLACEMENT_SIGNAL,
    onClick = function() hostedCalls = hostedCalls + 1 end,
})
local signalActions = Actions.GetAvailableForPlacement(
    radio,
    Actions.PLACEMENT_SIGNAL
)
assertEqual(#signalActions, 1, "signal placement returns its own actions")
Actions.Refresh(radio)
assertEqual(radio.psychopatzRadioActionsButton.visible, false,
    "placed action never creates a duplicate top-level control")
local separateButton = fakeButton("")
assertEqual(Actions.BindButton(
    separateButton,
    signalActions[1],
    radio,
    { title = "Hoomans Colony" }
), true, "modular signal button binds")
assertEqual(separateButton.title, "Hoomans Colony",
    "modular signal button keeps its distinct label")
separateButton.onclick(radio)
assertEqual(hostedCalls, 2, "modular signal button invokes its action")

-- The native Build 42 host owns Signal layout directly, so placed actions do
-- not depend on DynamicTrading being installed or loaded.
Actions.Register({
    id = "smoke.legacy_signal",
    label = "Legacy Placement",
    placement = Actions.LEGACY_PLACEMENT_SIGNAL,
    order = 200,
    onClick = function() hostedCalls = hostedCalls + 10 end,
})
local panel = {
    width = 320,
    height = 64,
    cacheHeight = 50,
    fontheight = 12,
    drawDistance = true,
    incomingSignal = false,
    deviceData = {
        getLastRecordedDistance = function() return -1 end,
    },
    sineWaveDisplay = {},
    children = {},
    addChild = function(self, child)
        child.parent = self
        self.children[#self.children + 1] = child
    end,
    removeChild = function(self, child) child.parent = nil end,
    setHeight = function(self, value) self.height = value end,
}
local signalElement = {
    subpanel = panel,
    calculateHeights = function(self)
        self.height = 18 + self.subpanel.height
    end,
}
radio.modules = { { element = signalElement } }
radio.children = {}
radio.addChild = function(self, child)
    child.parent = self
    self.children[#self.children + 1] = child
end
package.preload["PsychopatzCore/UI/Radio/PsychopatzRadioActions"] =
    function() return Actions end
dofile(ROOT .. "UI/Radio/PsychopatzRadioSignalHost.lua")
ISRadioWindow.createChildren(radio)
ISRadioWindow.prerender(radio)
local signalButton = radio.psychopatzSignalActionButtons["smoke.signal"]
local legacySignalButton = radio.psychopatzSignalActionButtons[
    "smoke.legacy_signal"
]
assertEqual(signalButton ~= nil, true,
    "native Signal host creates placed action without DynamicTrading")
assertEqual(signalButton.parent, panel,
    "placed action is a child of the collapsible Signal panel")
assertEqual(legacySignalButton.y > signalButton.y, true,
    "additional actions append in registry order")
assertEqual(panel.height > 64, true,
    "Signal panel expands for its action stack")
assertEqual(panel.drawDistance, false,
    "unmeasured native distance placeholder is suppressed")
assertEqual(signalButton.y, panel.cacheHeight + 4,
    "first action does not reserve a placeholder distance row")

panel.incomingSignal = true
panel.deviceData.getLastRecordedDistance = function() return 125 end
PsychopatzCore.RadioSignalHost.Refresh(radio)
assertEqual(panel.drawDistance, true,
    "real received-signal distance remains visible")
assertEqual(signalButton.y,
    panel.cacheHeight + panel.fontheight + 2 + 4,
    "actions flow below a real distance reading")
signalButton.onclick(radio)
legacySignalButton.onclick(radio)
assertEqual(hostedCalls, 13,
    "native Signal buttons retain independent callbacks")

print("psychopatz_radio_actions_smoke: ok")
