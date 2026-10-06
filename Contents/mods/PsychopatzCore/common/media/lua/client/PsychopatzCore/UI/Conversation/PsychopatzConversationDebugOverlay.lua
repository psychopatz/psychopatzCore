require "ISUI/ISPanel"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationRenderDiagnostics"

PsychopatzConversationDebugOverlay = ISPanel:derive(
    "PsychopatzConversationDebugOverlay"
)

local function number(value, fallback)
    value = tonumber(value)
    return value == nil and (fallback or 0) or value
end

local function visible(panel)
    if not panel then return false end
    if type(panel.getIsVisible) == "function" then
        return panel:getIsVisible() == true
    end
    if type(panel.isVisible) == "function" then
        return panel:isVisible() == true
    end
    return panel.visible ~= false
end

local function mounted(owner, panel)
    if not owner or not panel then return false end
    if panel.parent == owner then return true end
    for _, child in ipairs(owner.children or {}) do
        if child == panel then return true end
    end
    return false
end

local function nativeControlCount(owner)
    if owner and type(owner.getControls) == "function" then
        local controls = owner:getControls()
        if controls and type(controls.size) == "function" then
            return controls:size()
        end
    end
    local count = 0
    for _ in pairs(owner and owner.children or {}) do count = count + 1 end
    return count
end

local function bounds(panel)
    if not panel then return "-" end
    local x = type(panel.getX) == "function" and panel:getX() or panel.x
    local y = type(panel.getY) == "function" and panel:getY() or panel.y
    local w = type(panel.getWidth) == "function"
        and panel:getWidth() or panel.width
    local h = type(panel.getHeight) == "function"
        and panel:getHeight() or panel.height
    return string.format(
        "%d,%d %dx%d",
        math.floor(number(x)), math.floor(number(y)),
        math.floor(number(w)), math.floor(number(h))
    )
end

local function partLine(owner, id, definition, part)
    local factory = definition and definition.factory
    local factoryState = type(factory) == "function" and "Y" or "N"
    local mountedState = mounted(owner, part) and "Y" or "N"
    local visibleState = visible(part) and "Y" or "N"
    local reveal = part and part.reveal
    return string.format(
        "part %-12s def=%s factory=%s mounted=%s visible=%s reveal=%.2f %s bounds=%s",
        tostring(id),
        definition and "Y" or "N",
        factoryState,
        mountedState,
        visibleState,
        number(reveal, 0),
        PsychopatzCore.Conversation.RenderDiagnostics.Describe(part),
        bounds(part)
    )
end

local function controlLine(owner, id, control)
    return string.format(
        "control %-10s mounted=%s visible=%s bounds=%s title=%s",
        id,
        mounted(owner, control) and "Y" or "N",
        visible(control) and "Y" or "N",
        bounds(control),
        tostring(control and control.title or "-")
    )
end

function PsychopatzConversationDebugOverlay:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
end

function PsychopatzConversationDebugOverlay:new(owner)
    local width = 690
    local height = 282
    local viewWidth = owner and number(owner.width, 1280) or 1280
    local viewHeight = owner and number(owner.height, 720) or 720
    local x = math.max(8, math.floor((viewWidth - width) / 2))
    local y = math.max(8, math.floor(viewHeight * 0.03))
    local object = ISPanel.new(self, x, y, width, height)
    object.owner = owner
    object.lines = {}
    return object
end

function PsychopatzConversationDebugOverlay:refreshPosition()
    local owner = self.owner
    if not owner then return end
    local width = number(owner.width, 1280)
    local height = number(owner.height, 720)
    self:setX(math.max(8, math.floor((width - self.width) / 2)))
    self:setY(math.max(8, math.floor(height * 0.03)))
end

function PsychopatzConversationDebugOverlay:update()
    if ISPanel.update then ISPanel.update(self) end
    self:refreshPosition()
end

function PsychopatzConversationDebugOverlay:buildLines()
    local owner = self.owner
    if not owner then return {} end
    local spec = owner.spec or {}
    local animator = owner.animator or {}
    local lifecycle = owner.lifecycleState
    local lines = {
        "CONVERSATION DEBUG  [runtime component audit]",
        string.format(
            "view=%s npc=%s namespace=%s children=%d extensions=%d",
            tostring(owner.Type or "PsychopatzConversationView"),
            tostring(spec.npcID or "-"),
            tostring(spec.namespace or "-"),
            nativeControlCount(owner),
            #(spec.extensionParts or {})
        ),
        "module=PsychopatzCore.Conversation.Open [Workshop/PsychopatzCore]",
        "route=" .. tostring(owner.pncRouteSource or "not-attached"),
        string.format(
            "lifecycle started=%s finished=%s closing=%s reason=%s",
            owner.lifecycleStarted and "Y" or "N",
            owner.lifecycleFinished and "Y" or "N",
            owner.closing and "Y" or "N",
            tostring(owner.closeReason or "-")
        ),
        string.format(
            "session=%s interactive=%s animation=%s animateOpening=%s",
            owner.session and "Y" or "N",
            owner:isConversationInteractive() and "Y" or "N",
            tostring(animator.mode or "-"),
            tostring(spec.animateOpening)
        ),
        string.format(
            "lifecycleState=%s token=%s",
            lifecycle and "Y" or "N",
            tostring(lifecycle and lifecycle.token or "-")
        ),
        "-- parts: definition/factory/mount/visibility/reveal/bounds --",
        partLine(owner, "portrait", nil, owner.portraitPart),
        partLine(owner, "history", nil, owner.historyPart),
        partLine(owner, "choices", nil, owner.choicesPart),
    }
    local definitions = {}
    for _, definition in ipairs(spec.extensionParts or {}) do
        definitions[definition.partID] = definition
    end
    local extensionIDs = {}
    for id in pairs(definitions) do extensionIDs[id] = true end
    for id in pairs(owner.extensionParts or {}) do extensionIDs[id] = true end
    local orderedIDs = {}
    for id in pairs(extensionIDs) do orderedIDs[#orderedIDs + 1] = id end
    table.sort(orderedIDs)
    for _, id in ipairs(orderedIDs) do
        lines[#lines + 1] = partLine(
            owner, id, definitions[id], owner.extensionParts[id]
        )
    end
    lines[#lines + 1] = "-- controls: mount/visibility/bounds/title --"
    lines[#lines + 1] = controlLine(owner, "close", owner.closeButton)
    lines[#lines + 1] = controlLine(owner, "layout", owner.layoutButton)
    lines[#lines + 1] = controlLine(owner, "reset", owner.resetLayoutButton)
    lines[#lines + 1] = controlLine(owner, "crtDebug", owner.crtDebugButton)
    return lines
end

function PsychopatzConversationDebugOverlay:prerender()
    self.lines = self:buildLines()
    local lineHeight = 16
    local padding = 10
    local alpha = 0.93
    self:drawRect(0, 0, self.width, self.height, alpha, 0.015, 0.02, 0.025)
    self:drawRectBorder(0, 0, self.width, self.height, 0.98,
        0.95, 0.25, 0.15)
    self:drawRect(0, 0, self.width, 22, 0.98, 0.30, 0.04, 0.03)
    for index, line in ipairs(self.lines) do
        local color = index == 1
            and { r = 1.0, g = 0.68, b = 0.38 }
            or { r = 0.88, g = 0.93, b = 0.95 }
        self:drawText(
            line,
            padding,
            padding + (index - 1) * lineHeight,
            color.r, color.g, color.b, 1, UIFont.Small
        )
    end
end

return PsychopatzConversationDebugOverlay
