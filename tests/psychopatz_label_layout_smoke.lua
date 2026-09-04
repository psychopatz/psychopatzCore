local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/"

PsychopatzCore = {
    UI = {
        Theme = { colors = {} },
        Layout = {
            Scale = function() return 1 end,
            Pixels = function(value) return value end,
        },
    },
}
package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISPanel"] = function() return true end
package.preload["ISUI/ISScrollingListBox"] = function() return true end
package.preload["PsychopatzCore/UI/Core/PsychopatzUITheme"] =
    function() return PsychopatzCore.UI.Theme end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] =
    function() return PsychopatzCore.UI.Layout end
package.preload["PsychopatzCore/UI/Components/PsychopatzVirtualizedList"] =
    function() return {} end

local UI = PsychopatzCore.UI
dofile(ROOT .. "Components/PsychopatzUIControls.lua")

local label = {
    x = 337, y = 5, width = 48, height = 18, name = "46%",
}
function label:getX() return self.x end
function label:getY() return self.y end
function label:getWidth() return self.width end
function label:getHeight() return self.height end
function label:setX(value) self.x = value end
function label:setY(value) self.y = value end
function label:setWidth(value) self.width = value end
function label:setHeight(value) self.height = value end
function label:setNameWithoutMoving(value)
    self.name = value
    self.width = #value
end

UI.SetLabelText(label, "55%")
assert(label.name == "55%", "label text was not updated")
assert(label.x == 337 and label.y == 5,
    "dynamic label moved outside its responsive row")
assert(label.width == 48 and label.height == 18,
    "dynamic label changed its assigned layout bounds")

print("psychopatz_label_layout_smoke: ok")
