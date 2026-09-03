require "ISUI/ISPanelJoypad"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Editor = require "PsychopatzCore/World/PC_GridRegionEditor"
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local Selector = ISPanelJoypad:derive("PsychopatzGridRegionSelector")
PsychopatzCore.UI.GridRegionSelector = Selector

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function clone(region)
    return GridRegion.normalize(region or GridRegion.new())
end

local function validationText(reason)
    if reason == "EMPTY_REGION" then
        return tr("UI_PsychopatzRegion_Empty", "Select at least one tile")
    end
    if reason == "REGION_CAPACITY_EXCEEDED" then
        return tr("UI_PsychopatzRegion_CapacityExceeded", "Selection exceeds the tile cap")
    end
    if reason == "INVALID_TILE" then
        return tr("UI_PsychopatzRegion_InvalidTile", "Selection contains an invalid tile")
    end
    return tostring(reason or "")
end

local function invalidPlacementText(reason)
    local prefix = tr("UI_PsychopatzRegion_InvalidPlacement",
        "INVALID PLACEMENT")
    local detail = validationText(reason)
    if detail == "" or detail == "INVALID_TILE" then return prefix end
    return prefix .. " - " .. detail
end

local function nowMs()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function selectorActive()
    return Selector and Selector.instance ~= nil
end

local function renderRegion(playerNum, region, color, forcedZ)
    for z, level in pairs(region and region.levels or {}) do
        local drawZ = forcedZ == nil and z or forcedZ
        for y, spans in pairs(level.rows) do
            for index = 1, #spans, 2 do
                addAreaHighlightForPlayer(playerNum, spans[index], y,
                    spans[index + 1] + 1, y + 1, drawZ,
                    color.r, color.g, color.b, color.a)
            end
        end
    end
end

function Selector:pickSquare(screenX, screenY)
    local z = math.floor(self.player:getZ())
    local x = math.floor(screenToIsoX(self.playerNum, screenX, screenY, z))
    local y = math.floor(screenToIsoY(self.playerNum, screenX, screenY, z))
    return getCell():getGridSquare(x, y, z), x, y, z
end

-- Optional reusable per-tile validation. Region validation remains the final
-- authority for a selector, while this contract lets callers provide the
-- same rule as an immediate world preview.
function Selector:validateTileAt(square, x, y, z)
    if self.requiredSquareRule and square then
        local valid = SquareRules.MatchSquare(
            square, self.requiredSquareRule, self.squareRuleContext)
        if not valid then return false, "INVALID_TILE" end
    end
    if type(self.tileValidator) == "function" then
        local ok, valid, reason, details = pcall(
            self.tileValidator, x, y, z, square, self)
        if not ok then return false, "INVALID_TILE" end
        if valid == false then
            return false, reason or "INVALID_TILE", details
        end
    end
    return true, nil
end

function Selector:collectInvalidTiles(region)
    local invalid = GridRegion.new()
    local invalidCount, firstReason = 0, nil
    local cell = type(getCell) == "function" and getCell() or nil
    for z, level in pairs(region and region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            local invalidSpans, runStart, runEnd = {}, nil, nil
            local function closeRun()
                if runStart ~= nil then
                    invalidSpans[#invalidSpans + 1] = runStart
                    invalidSpans[#invalidSpans + 1] = runEnd
                    runStart, runEnd = nil, nil
                end
            end
            for index = 1, #spans, 2 do
                local first, last = spans[index], spans[index + 1]
                for x = first, last do
                    local square = cell and cell.getGridSquare
                        and cell:getGridSquare(x, y, z) or nil
                    local valid, reason = self:validateTileAt(
                        square, x, y, z)
                    if not valid then
                        invalidCount = invalidCount + 1
                        firstReason = firstReason or reason
                        if runStart == nil then
                            runStart, runEnd = x, x
                        elseif x == runEnd + 1 then
                            runEnd = x
                        else
                            closeRun()
                            runStart, runEnd = x, x
                        end
                    else
                        closeRun()
                    end
                end
            end
            closeRun()
            if #invalidSpans > 0 then
                invalid.levels[z] = invalid.levels[z] or { rows = {} }
                invalid.levels[z].rows[y] = invalidSpans
            end
        end
    end
    return invalid, invalidCount, firstReason
end

function Selector:refreshTileValidation(region, target)
    if type(self.tileValidator) ~= "function"
        and not self.requiredSquareRule
    then
        if target == "preview" then
            self.previewInvalidRegion = nil
            self.previewInvalidCount = 0
            self.previewInvalidReason = nil
        else
            self.invalidRegion = nil
            self.invalidTileCount = 0
            self.invalidTileReason = nil
        end
        return
    end
    local invalid, count, reason = self:collectInvalidTiles(region)
    if target == "preview" then
        self.previewInvalidRegion = invalid
        self.previewInvalidCount = count
        self.previewInvalidReason = reason
    else
        self.invalidRegion = invalid
        self.invalidTileCount = count
        self.invalidTileReason = reason
    end
end

function Selector:updateHoverValidation(square, x, y, z)
    if not square then
        self.hoverSquare = nil
        self.hoverValid, self.hoverReason = nil, nil
        return
    end
    self.hoverSquare = { x = x, y = y, z = z }
    self.hoverValid, self.hoverReason = self:validateTileAt(
        square, x, y, z)
end

function Selector:pushUndo()
    self.undo[#self.undo + 1] = clone(self.region)
    if #self.undo > 20 then table.remove(self.undo, 1) end
end

function Selector:validateSelection()
    local stats = Editor.stats(self.region)
    local ok, reason = stats.tileCount > 0, "EMPTY_REGION"
    if ok and self.maxTiles and stats.tileCount > self.maxTiles then
        ok, reason = false, "REGION_CAPACITY_EXCEEDED"
    end
    if ok and self.requiredSquareRule then
        local valid, ruleReason, details = SquareRules.ValidateRegion(
            stats.region, self.requiredSquareRule, self.squareRuleContext)
        ok, reason = valid == true, ruleReason
        if type(details) == "table" then
            stats.ruleChecked = details.checked
            stats.invalidX, stats.invalidY, stats.invalidZ =
                details.x, details.y, details.z
        end
    end
    if ok and self.validate then
        local valid, validationReason, extra = self.validate(
            stats.region, stats, self)
        ok, reason = valid == true, validationReason
        if type(extra) == "table" then
            for key, value in pairs(extra) do stats[key] = value end
        end
    end
    self:refreshTileValidation(self.region)
    if ok and (tonumber(self.invalidTileCount) or 0) > 0 then
        ok, reason = false, self.invalidTileReason or "INVALID_TILE"
    end
    self.selectionStats = stats
    self.validationMessage = ok and "" or validationText(reason or "INVALID_REGION")
    return ok, stats
end

function Selector:applyPatch(patch)
    self:pushUndo()
    self.region = Editor.apply(self.region, patch,
        self.selectionKind == "point" and "replace" or self.tool)
    local valid = self:validateSelection()
    local stamp = nowMs()
    if not valid and stamp > 0 then self.invalidFlashUntil = stamp + 450 end
end

function Selector:onControl(button)
    local action = button and button.internal
    if action == "replace" or action == "add" or action == "erase" then
        self.tool = action
        for id, control in pairs(self.toolButtons) do
            UI.SetButtonVariant(control, id == action and "selected" or "quiet")
        end
        return
    end
    if action == "undo" then
        local previous = table.remove(self.undo)
        if previous then self.region = previous; self:validateSelection() end
        return
    end
    if action == "reset" then
        self:pushUndo()
        self.region = clone(self.initialRegion)
        self:validateSelection()
        return
    end
    if action == "cancel" then self:close(false); return end
    if action == "confirm" then
        local ok, stats = self:validateSelection()
        if not ok then return end
        local region = clone(self.region)
        local callback = self.onConfirm
        self:close(true)
        if callback then callback(region, stats, self) end
    end
end

function Selector:createChildren()
    local definitions = {
        { "replace", tr("UI_PsychopatzRegion_Replace", "REPLACE"), "selected" },
        { "add", tr("UI_PsychopatzRegion_Add", "ADD"), "quiet" },
        { "erase", tr("UI_PsychopatzRegion_Erase", "ERASE"), "quiet" },
        { "undo", tr("UI_PsychopatzRegion_Undo", "UNDO"), "quiet" },
        { "reset", tr("UI_PsychopatzRegion_Reset", "RESET"), "quiet" },
        { "confirm", tr("UI_PsychopatzRegion_Confirm", "CONFIRM"), "success" },
        { "cancel", tr("UI_PsychopatzRegion_Cancel", "CANCEL"), "danger" },
    }
    self.controls, self.toolButtons = {}, {}
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1], title = definition[2], target = self,
            onclick = Selector.onControl, variant = definition[3],
        })
        self.controls[#self.controls + 1] = button
        if definition[1] == "replace" or definition[1] == "add"
            or definition[1] == "erase"
        then self.toolButtons[definition[1]] = button end
    end
    if self.selectionKind == "point" then
        self.toolButtons.replace:setVisible(false)
        self.toolButtons.add:setVisible(false)
        self.toolButtons.erase:setVisible(false)
    end
    self:layoutControls()
end

function Selector:layoutControls()
    local x, y, gap, height = 12, self.height - 40, 6, 27
    local visible = {}
    for _, button in ipairs(self.controls or {}) do
        if button:getIsVisible() then visible[#visible + 1] = button end
    end
    local width = math.floor((self.width - 24 - gap * (#visible - 1)) / #visible)
    for _, button in ipairs(visible) do
        button:setX(x); button:setY(y); button:setWidth(width); button:setHeight(height)
        x = x + width + gap
    end
end

function Selector:onMouseDownOutside(x, y)
    local square, worldX, worldY, z = self:pickSquare(
        x + self:getAbsoluteX(), y + self:getAbsoluteY())
    if not square then return end
    self.dragging = true
    self.dragX, self.dragY, self.dragZ = worldX, worldY, z
    self.preview = Editor.point(worldX, worldY, z)
    self:refreshTileValidation(self.preview, "preview")
end

function Selector:onMouseMoveOutside()
    if not self.dragging then return end
    local square, x, y, z = self:pickSquare(getMouseX(), getMouseY())
    if square then
        self.preview = Editor.rectangle(self.dragX, self.dragY, x, y, z)
        self:refreshTileValidation(self.preview, "preview")
    end
end

function Selector:onMouseUpOutside()
    if not self.dragging then return end
    self.dragging = false
    if self.preview then self:applyPatch(self.preview) end
    self.preview = nil
    self.previewInvalidRegion = nil
    self.previewInvalidCount = 0
    self.previewInvalidReason = nil
end

function Selector:tooltipDrawer()
    if not ISUIElement or not ISUIElement.new then return nil end
    local left = getPlayerScreenLeft and getPlayerScreenLeft(self.playerNum) or 0
    local top = getPlayerScreenTop and getPlayerScreenTop(self.playerNum) or 0
    local width = getPlayerScreenWidth and getPlayerScreenWidth(self.playerNum)
        or getCore():getScreenWidth()
    local height = getPlayerScreenHeight and getPlayerScreenHeight(self.playerNum)
        or getCore():getScreenHeight()
    local drawer = self.validationTooltipDrawer
    if not drawer then
        drawer = ISUIElement:new(left, top, width, height)
        if drawer.initialise then drawer:initialise() end
        if drawer.setCapture then drawer:setCapture(false) end
        self.validationTooltipDrawer = drawer
    else
        drawer:setX(left); drawer:setY(top)
        drawer:setWidth(width); drawer:setHeight(height)
    end
    return drawer
end

function Selector:drawValidationTooltip(message)
    if not message or message == "" or type(getMouseX) ~= "function"
        or type(getMouseY) ~= "function"
    then return end
    local drawer = self:tooltipDrawer()
    if not drawer or not drawer.drawText then return end
    local left = tonumber(drawer.x) or 0
    local top = tonumber(drawer.y) or 0
    local x = getMouseX() - left + 16
    local y = getMouseY() - top + 18
    local text = invalidPlacementText(message)
    local width = math.max(190, #text * 7 + 24)
    local height = 30
    if x + width > drawer.width then x = drawer.width - width - 4 end
    if y + height > drawer.height then y = drawer.height - height - 4 end
    x, y = math.max(4, x), math.max(4, y)
    if drawer.drawRect then
        drawer:drawRect(x, y, width, height, 0.92, 0.10, 0.015, 0.015)
    end
    if drawer.drawRectBorder then
        drawer:drawRectBorder(x, y, width, height, 1.0, 1.0, 0.22, 0.16)
    end
    drawer:drawText(text, x + 10, y + 7,
        1, 0.92, 0.92, 1, UIFont and UIFont.Small)
end

function Selector:prerender()
    ISPanelJoypad.prerender(self)
    self:drawRect(0, 0, self.width, self.height, Theme.colors.window.a,
        Theme.colors.window.r, Theme.colors.window.g, Theme.colors.window.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        Theme.colors.borderStrong.a, Theme.colors.borderStrong.r,
        Theme.colors.borderStrong.g, Theme.colors.borderStrong.b)
    self:drawRect(0, 0, self.width, 2, 0.9, Theme.colors.accent.r,
        Theme.colors.accent.g, Theme.colors.accent.b)
    local stats = self.selectionStats or Editor.stats(self.region)
    local textWidth = math.max(40, self.width - 24)
    self:drawText(Layout.Ellipsize(self.titleText, UIFont.Medium, textWidth),
        12, 10, Theme.colors.text.r,
        Theme.colors.text.g, Theme.colors.text.b, 1, UIFont.Medium)
    self:drawText(Layout.Ellipsize(self.instructionText, UIFont.Small, textWidth),
        12, 34, Theme.colors.textMuted.r,
        Theme.colors.textMuted.g, Theme.colors.textMuted.b, 1, UIFont.Small)
    local metric = tostring(stats.tileCount or 0) .. " "
        .. tr("UI_PsychopatzRegion_Tiles", "tiles")
    if self.maxTiles then metric = metric .. " / " .. tostring(self.maxTiles) end
    if stats.width > 0 then
        metric = metric .. "   " .. tostring(stats.width) .. " x "
            .. tostring(stats.height) .. "   " .. tostring(stats.spanCount)
            .. " " .. tr("UI_PsychopatzRegion_Spans", "spans")
    end
    if stats.claimed and stats.capacity then
        metric = metric .. "   " .. tostring(stats.claimed) .. "/"
            .. tostring(stats.capacity) .. " "
            .. tr("UI_PsychopatzRegion_Claimed", "claimed")
    end
    self:drawText(Layout.Ellipsize(metric, UIFont.Small, textWidth), 12, 57,
        Theme.colors.accent.r,
        Theme.colors.accent.g, Theme.colors.accent.b, 1, UIFont.Small)
    local state = self.validationMessage ~= "" and self.validationMessage
        or tr("UI_PsychopatzRegion_Valid", "Selection ready")
    local color = self.validationMessage ~= "" and Theme.colors.danger
        or Theme.colors.success
    self:drawText(Layout.Ellipsize(state, UIFont.Small, textWidth), 12, 79,
        color.r, color.g, color.b, 1, UIFont.Small)

    for _, layer in ipairs(self.guideLayers or {}) do
        renderRegion(self.playerNum, layer.region, layer.color,
            layer.renderZ)
    end
    if self.guideRegion then
        renderRegion(self.playerNum, self.guideRegion, self.guideColor,
            self.guideRenderZ)
    end
    renderRegion(self.playerNum, self.region, self.highlightColor)
    if self.invalidRegion then
        renderRegion(self.playerNum, self.invalidRegion,
            self.invalidColor)
    end
    if self.preview then renderRegion(self.playerNum, self.preview, self.previewColor) end
    if self.previewInvalidRegion then
        renderRegion(self.playerNum, self.previewInvalidRegion,
            self.invalidColor)
    end
    if not self.dragging then
        local square, x, y, z = self:pickSquare(getMouseX(), getMouseY())
        if square then
            self:updateHoverValidation(square, x, y, z)
            local hoverColor = { r = 1, g = 1, b = 1, a = 0.45 }
            if self.requiredSquareRule or self.tileValidator then
                hoverColor = self.hoverValid
                    and { r = 0.2, g = 1, b = 0.35, a = 0.55 }
                    or { r = 1, g = 0.18, b = 0.12, a = 0.62 }
            end
            addAreaHighlightForPlayer(self.playerNum, x, y, x + 1, y + 1, z,
                hoverColor.r, hoverColor.g, hoverColor.b, hoverColor.a)
        else
            self:updateHoverValidation(nil)
        end
    end
    local tooltipMessage
    if self.dragging then
        tooltipMessage = self.previewInvalidReason
    elseif self.hoverValid == false then
        tooltipMessage = self.hoverReason
    elseif (tonumber(self.invalidTileCount) or 0) > 0 then
        tooltipMessage = self.invalidTileReason
    end
    if self.invalidFlashUntil and nowMs() < self.invalidFlashUntil then
        if self.hoverSquare then
            local x, y, z = self.hoverSquare.x, self.hoverSquare.y,
                self.hoverSquare.z
            addAreaHighlightForPlayer(self.playerNum, x, y, x + 1, y + 1, z,
                self.invalidColor.r, self.invalidColor.g,
                self.invalidColor.b, 0.85)
        end
    end
    if tooltipMessage then self:drawValidationTooltip(tooltipMessage) end
end

function Selector:restoreOwner()
    if self.ownerWindow then
        self.ownerWindow:addToUIManager()
        self.ownerWindow:setVisible(true)
        self.ownerWindow:bringToTop()
    end
end

function Selector:close(confirmed)
    if self.closed then return end
    self.closed = true
    ISWorldObjectContextMenu.disableWorldMenu = self.previousWorldMenuDisabled == true
    self:setVisible(false)
    self:removeFromUIManager()
    Selector.instance = nil
    self.validationTooltipDrawer = nil
    self:restoreOwner()
    if confirmed ~= true and self.onCancel then self.onCancel(self) end
end

function Selector:new(options)
    options = type(options) == "table" and options or {}
    local width, height = 610, 145
    local x = math.floor((getCore():getScreenWidth() - width) / 2)
    local object = ISPanelJoypad:new(x, 52, width, height)
    setmetatable(object, self); self.__index = self
    object.playerNum = math.floor(tonumber(options.playerNum) or 0)
    object.player = options.player or getSpecificPlayer(object.playerNum)
    object.titleText = tostring(options.title or tr(
        "UI_PsychopatzRegion_Title", "SELECT WORLD AREA"))
    object.instructionText = tostring(options.instruction or tr(
        "UI_PsychopatzRegion_Help", "Drag on the world; use Add or Erase for irregular shapes."))
    object.selectionKind = options.selectionKind == "point" and "point" or "region"
    object.tool = tostring(options.tool or "replace")
    object.initialRegion = clone(options.initialRegion)
    object.region = clone(options.initialRegion)
    object.guideRegion = options.guideRegion and clone(options.guideRegion) or nil
    object.guideLayers = {}
    for _, layer in ipairs(options.guideLayers or {}) do
        if type(layer) == "table" and layer.region then
            object.guideLayers[#object.guideLayers + 1] = {
                region = clone(layer.region),
                renderZ = layer.renderZ,
                color = layer.color
                    or { r = 1, g = 0.62, b = 0.12, a = 0.30 },
            }
        end
    end
    object.guideRenderZ = options.guideRenderZ
    object.maxTiles = tonumber(options.maxTiles)
    object.requiredSquareRule = options.requiredSquareRule
        and tostring(options.requiredSquareRule) or nil
    object.squareRuleContext = options.squareRuleContext
    object.validate = options.validate
    object.tileValidator = options.tileValidator
    object.suppressPersistentOverlays = options.suppressPersistentOverlays == true
    object.inputOwner = tostring(options.inputOwner
        or "PsychopatzCore.GridRegionSelector")
    object.onConfirm, object.onCancel = options.onConfirm, options.onCancel
    object.ownerWindow = options.ownerWindow
    object.undo = {}
    object.highlightColor = options.highlightColor
        or { r = 0.15, g = 0.72, b = 1, a = 0.45 }
    object.previewColor = options.previewColor
        or { r = 0.35, g = 0.85, b = 1, a = 0.28 }
    object.guideColor = options.guideColor
        or { r = 0.25, g = 0.9, b = 0.3, a = 0.18 }
    object.invalidColor = options.invalidColor
        or { r = 1.0, g = 0.12, b = 0.08, a = 0.62 }
    object.invalidFlashUntil = 0
    object.background = false
    object.validationMessage = validationText("EMPTY_REGION")
    return object
end

function Selector.Open(options)
    if Selector.instance then Selector.instance:close(false) end
    local selector = Selector:new(options)
    if not selector.player then return nil, "PLAYER_UNAVAILABLE" end
    selector:initialise(); selector:instantiate(); selector:createChildren()
    selector.previousWorldMenuDisabled = ISWorldObjectContextMenu.disableWorldMenu
    ISWorldObjectContextMenu.disableWorldMenu = true
    if selector.ownerWindow then
        selector.ownerWindow:setVisible(false)
        selector.ownerWindow:removeFromUIManager()
    end
    selector:addToUIManager(); selector:bringToTop(); selector:validateSelection()
    Selector.instance = selector
    return selector
end

function Selector.IsWorldInputOwned()
    return selectorActive()
end

function Selector.WorldInputOwner()
    return Selector.instance and Selector.instance.inputOwner or nil
end

return Selector
