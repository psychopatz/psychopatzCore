local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
    .. "PsychopatzCore/UI/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local UI = {}
PsychopatzCore = { UI = UI }
UI.Theme = {
    Color = function(_, name, alpha)
        return { name = name, a = alpha == nil and 1 or alpha }
    end,
}
UI.ImageResolver = {
    Resolve = function(path) return path end,
}
package.preload[
    "PsychopatzCore/UI/Components/PsychopatzUIControls"] = function()
        return true
    end

function UI.CreateButton(parent, definition)
    local button = {
        title = definition.title,
        target = definition.target,
        onclick = definition.onclick,
        width = 1,
        height = 1,
        visible = false,
    }
    function button:setTitle(value) self.title = value end
    function button:setDisplayBackground(value) self.displayBackground = value end
    function button:setImage(value) self.image = value end
    function button:forceImageSize(width, height)
        self.forcedWidthImage, self.forcedHeightImage = width, height
    end
    function button:setWidth(value) self.width = value end
    function button:setHeight(value) self.height = value end
    function button:setX(value) self.x = value end
    function button:setY(value) self.y = value end
    function button:setVisible(value) self.visible = value end
    function button:bringToTop() self.broughtToTop = true end
    parent:addChild(button)
    return button
end

local nativePin = { x = 100, y = 1, width = 16, height = 16 }
function nativePin:getX() return self.x end
function nativePin:getY() return self.y end
function nativePin:getWidth() return self.width end
function nativePin:getHeight() return self.height end

local window = {
    width = 140,
    children = {},
    psychopatzTitlebarPinButton = nativePin,
}
function window:addChild(child) self.children[#self.children + 1] = child end
function window:titleBarHeight() return 18 end
function window:getWidth() return self.width end
function window:saveGeometry() self.saveCount = (self.saveCount or 0) + 1 end

local changed
local WidgetWindow = dofile(ROOT .. "Components/PsychopatzWidgetWindow.lua")
local button = WidgetWindow.Install(window, {
    id = "smoke-widget",
    onDetachedChanged = function(_, value) changed = value end,
})
equal(button, window.psychopatzWidgetButton, "widget button installed")
equal(button.image, WidgetWindow.ATTACHED_ICON, "attached star icon")
equal(button.visible, true, "widget button visible")
equal(button.x, 83, "widget button beside native pin")
equal(button.y, 1, "widget button title-bar y")
equal(button.forcedWidthImage, 14, "widget icon size")
equal(WidgetWindow.IsDetached(window), false, "default widget state")

equal(WidgetWindow.Toggle(window), true, "widget detaches")
equal(WidgetWindow.IsDetached(window), true, "detached widget state")
equal(button.image, WidgetWindow.DETACHED_ICON, "detached star icon")
equal(changed, true, "detach callback")
equal(window.saveCount, 1, "detach state saved")

nativePin.x = 120
window.width = 160
WidgetWindow.Sync(window)
equal(button.x, 103, "widget button follows resized title bar")
equal(WidgetWindow.Toggle(window), false, "widget reattaches")
equal(button.image, WidgetWindow.ATTACHED_ICON, "reattached star icon")
equal(changed, false, "attach callback")
equal(window.saveCount, 2, "attach state saved")

print("psychopatz_widget_window_smoke: ok")
