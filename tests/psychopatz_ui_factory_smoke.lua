local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local parent = { children = {} }
function parent:addChild(child)
    self.children[#self.children + 1] = child
end

PsychopatzCore = { UI = {} }
UIFont = { Small = "small" }
local UI = PsychopatzCore.UI
UI.Theme = {
    colors = {
        text = { r = 1, g = 1, b = 1, a = 1 },
        textMuted = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
        surfaceRaised = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
    },
}
UI.Layout = {
    Pixels = function(value) return value end,
    Ellipsize = function(value) return tostring(value or "") end,
}
UI.DrawListSelection = function(list, y, height, selected, alternate)
    list.selectionDrawn = alternate == true
end
package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] =
    function() return UI end

ISTextEntryBox = {}
function ISTextEntryBox:new(text, x, y, width, height)
    return setmetatable({
        text = text, x = x, y = y, width = width, height = height,
    }, { __index = self })
end
function ISTextEntryBox:initialise() self.initialised = true end
function ISTextEntryBox:instantiate() self.instantiated = true end
function ISTextEntryBox:setClearButton(value) self.clearButton = value end
function ISTextEntryBox:setOnlyNumbers(value) self.onlyNumbers = value end
function ISTextEntryBox:setMaxTextLength(value) self.maxTextLength = value end
function ISTextEntryBox:getText() return self.text or "" end
function ISTextEntryBox:setText(value) self.text = value or "" end
function ISTextEntryBox:clear() self.text = "" end
function ISTextEntryBox:getWidth() return self.width end
function ISTextEntryBox:getHeight() return self.height end
function ISTextEntryBox:setX(value) self.x = value end
function ISTextEntryBox:setY(value) self.y = value end
function ISTextEntryBox:setWidth(value) self.width = value end
function ISTextEntryBox:setHeight(value) self.height = value end
function ISTextEntryBox:focus() self.focused = true end
function ISTextEntryBox:unfocus() self.focused = false end
function ISTextEntryBox:isFocused() return self.focused == true end
package.preload["ISUI/ISTextEntryBox"] = function() return ISTextEntryBox end

ISPanel = {}
function ISPanel:new(x, y, width, height)
    return setmetatable({
        x = x, y = y, width = width, height = height, children = {},
    }, { __index = self })
end
function ISPanel:initialise() self.initialised = true end
function ISPanel:instantiate() self.instantiated = true end
function ISPanel:noBackground() self.noBackgroundCalled = true end
function ISPanel:setWantMouseEvents(value) self.wantMouseEvents = value end
function ISPanel:addChild(child) self.children[#self.children + 1] = child end
function ISPanel:getWidth() return self.width end
function ISPanel:getHeight() return self.height end
function ISPanel:setX(value) self.x = value end
function ISPanel:setY(value) self.y = value end
function ISPanel:setWidth(value) self.width = value end
function ISPanel:setHeight(value) self.height = value end
package.preload["ISUI/ISPanel"] = function() return ISPanel end

ISImage = {}
function ISImage:new(x, y, width, height, texture)
    return setmetatable({
        x = x, y = y, width = width, height = height, texture = texture,
    }, { __index = self })
end
function ISImage:initialise() end
function ISImage:instantiate() end
function ISImage:setWantMouseEvents(value) self.wantMouseEvents = value end
function ISImage:setX(value) self.x = value end
function ISImage:setY(value) self.y = value end
function ISImage:setWidth(value) self.width = value end
function ISImage:setHeight(value) self.height = value end
package.preload["ISUI/ISImage"] = function() return ISImage end
function getTexture(path) return { path = path } end

dofile(ROOT .. "Components/PsychopatzTextEntry.lua")
local changed = false
local entry = UI.CreateTextEntry(parent, {
    text = 12,
    width = 86,
    height = 26,
    clearButton = true,
    onlyNumbers = true,
    maxTextLength = 10,
    onTextChange = function() changed = true end,
    preferredWidth = 86,
})
equal(entry.text, "12", "text entry text")
equal(entry.clearButton, true, "text entry clear button")
equal(entry.onlyNumbers, true, "text entry numeric mode")
equal(entry.maxTextLength, 10, "text entry max length")
equal(entry.psychopatzPreferredWidth, 86, "text entry preferred width")
equal(parent.children[1], entry, "text entry parent")
entry.onTextChange()
equal(changed, true, "text entry callback")

local searchChanged = false
local search = UI.CreateSearchEntry(parent, {
    width = 120,
    height = 28,
    clearButton = true,
    onTextChange = function() searchChanged = true end,
})
equal(search.psychopatzSearchIconPath,
    "media/ui/Search_Icon_On.png", "search icon path")
equal(search.psychopatzSearchEntry.clearButton, true,
    "search clear button")
search.psychopatzSearchEntry.onTextChangeFunction(nil,
    search.psychopatzSearchEntry)
equal(searchChanged, true, "search factory callback")

local legacyChanged = false
search.onTextChangeFunction = function() legacyChanged = true end
search.psychopatzSearchEntry.onTextChangeFunction(nil,
    search.psychopatzSearchEntry)
equal(legacyChanged, true, "legacy search callback bridge")

search:setWidth(200)
equal(search.psychopatzSearchEntry:getWidth(), 168,
    "search text width follows container")

function UI.CreateList(listParent, options)
    local list = {
        width = 320,
        itemheight = options.itemHeight,
        doDrawItem = options.doDrawItem,
        items = {},
    }
    function list:getWidth() return self.width end
    function list:addItem(label, item)
        self.items[#self.items + 1] = { text = label, item = item }
    end
    function list:drawText(text, x, y)
        self.lastText = { text = text, x = x, y = y }
    end
    function list:drawRect() self.rectDrawn = true end
    listParent:addChild(list)
    return list
end

dofile(ROOT .. "Components/PsychopatzKeyValueList.lua")
local details = UI.CreateKeyValueList(parent, {
    itemHeight = 24,
    labelX = 10,
    labelY = 5,
    valueY = 5,
    labelWidth = 100,
    valueXOffset = 2,
})
local item = UI.AddKeyValue(details, "Status", "", true)
equal(item.value, "-", "key value empty value")
equal(item.warning, true, "key value warning")
equal(details.itemheight, 24, "key value row height")
local nextY = details.doDrawItem(details, 0, { item = item }, true)
equal(nextY, 24, "key value next row")
equal(details.selectionDrawn, true, "key value alternate row")
equal(details.lastText.text, "-", "key value rendered value")
equal(details.lastText.x, 112, "key value rendered x")

print("psychopatz_ui_factory_smoke: ok")
