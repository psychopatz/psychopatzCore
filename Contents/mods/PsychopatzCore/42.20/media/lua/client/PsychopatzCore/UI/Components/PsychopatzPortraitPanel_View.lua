local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Descriptor = require
    "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_Descriptor"
local Window = PsychopatzPortraitPanel

local function normalizeScreenVariant(value)
    if value == nil then return nil end
    value = string.lower(tostring(value))
    if value == "crt" or value == "screen" then return "crt" end
    if value == "subtle" or value == "default" or value == "clean" then
        return "subtle"
    end
    if value == "none" or value == "off" then return "none" end
    return nil
end

function Window:applyViewState()
    local model = self.modelView
    if not model or not model.javaObject then return end
    model.animateEnabled = self.animate ~= false
    model:setState(self.stateName or "idle")
    model:setDirection(self.direction or (IsoDirections and IsoDirections.S))
    model:setIsometric(self.isometric == true)
    model:setDoRandomExtAnimations(false)
    model:setZoom(tonumber(self.zoom) or 14)
    model:setXOffset(tonumber(self.xOffset) or 0)
    model:setYOffset(tonumber(self.yOffset) or -0.85)
    if self.portraitAnimationEnabled then
        self:applyAnimationVariables()
    else
        model:setVariable("bMoving", "false")
        model:setVariable("isMoving", "false")
        model:setVariable("Speed", "0.0")
        model:setVariable("MovementSpeed", "0.0")
    end
    model.javaObject:setAnimate(self.animate ~= false)
end

function Window:applyAnimationVariables(state)
    local model = self.modelView
    if not model or not model.javaObject then return end
    state = tostring(state or self.portraitAnimationState or "idle")
    model:setVariable("PNCPortrait", "true")
    model:setVariable("PNCPortraitState", state)
    model:setVariable("bMoving", "false")
    model:setVariable("isMoving", "false")
    model:setVariable("Speed", "0.0")
    model:setVariable("MovementSpeed", "0.0")
    model:setVariable("WalkSpeed", "0.0")
    model:setVariable("RunSpeed", "0.0")
    model:setState("idle")
end

function Window:setScreenVariant(variant)
    self.screenVariant = normalizeScreenVariant(variant)
end

function Window:getScreenVariant()
    return self.screenVariant or "subtle"
end

function Window:refreshAnimationState(current)
    local now = tonumber(current)
        or (getTimeInMillis and getTimeInMillis() or 0)
    local state = "idle"
    if self.portraitAnimationEnabled ~= true then return end
    if self.portraitAnimationUntil
        and now < self.portraitAnimationUntil
    then
        state = self.portraitAnimationState or "idle"
    elseif self.speechAnimationUntil and now < self.speechAnimationUntil then
        state = "speech"
    end
    if self.portraitAnimationUntil and now >= self.portraitAnimationUntil then
        self.portraitAnimationUntil = nil
        self.portraitAnimationState = nil
    end
    if self.modelView and self.animationAppliedState ~= state then
        self.animationAppliedState = state
        self:applyAnimationVariables(state)
    end
end

-- Conversation views can use this lightweight pulse without owning or
-- replacing the portrait renderer. It keeps the reusable model component
-- suitable for map cards and other static consumers.
function Window:pulseSpeech(text)
    local duration = math.max(280, math.min(1200, #tostring(text or "") * 18))
    local current = getTimeInMillis and getTimeInMillis() or 0
    self.speechPulseStartedAt = current
    self.speechPulseUntil = current + duration
    if self.portraitAnimationEnabled then
        self.speechAnimationUntil = current + duration
    end
    self:refreshAnimationState(current)
end

function Window:playAnimation(animationID, durationMs)
    local animation = tostring(animationID or "")
    local state
    local current
    if self.portraitAnimationEnabled ~= true then return false end
    if animation == "greeting.wavehi" or animation == "wavehi" then
        state = "wavehi"
    elseif animation == "reaction.thumbsdown" or animation == "thumbsdown" then
        state = "thumbsdown"
    else
        return false
    end
    current = getTimeInMillis and getTimeInMillis() or 0
    self.portraitAnimationState = state
    self.portraitAnimationUntil = current
        + math.max(400, tonumber(durationMs) or 2200)
    self:refreshAnimationState(current)
    return true
end

function Window:setTarget(character, spec, force)
    local key
    local descriptor
    local descriptorFirst
    spec = type(spec) == "table" and spec or {}
    if self.faceOnly == true and spec.faceOnly == nil then
        spec.faceOnly = true
    end
    descriptorFirst = spec.preferDescriptor == true
    key = table.concat({
        tostring(spec.key or Descriptor.Key(spec)),
        tostring(descriptorFirst and "descriptor" or (character or "descriptor")),
    }, "|")
    if force ~= true and self.targetKey == key then return true end
    self.targetKey = key
    self.targetCharacter = character
    self.targetSpec = spec
    self.speechAnimationUntil = nil
    self.portraitAnimationUntil = nil
    self.portraitAnimationState = nil
    self.animationAppliedState = nil
    local model = self:ensureModelView()
    if not model then return false end
    if model.javaObject and model.javaObject.clearVariables then
        model.javaObject:clearVariables()
    end
    if not descriptorFirst and Descriptor.IsRenderableCharacter(character) then
        model:setCharacter(character)
        self.targetMode = "character"
    else
        descriptor = Descriptor.Build(spec)
        if descriptor then
            model:setCharacter(nil)
            model:setSurvivorDesc(descriptor)
            self.targetMode = "descriptor"
        elseif spec.outfit then
            model:setOutfitName(spec.outfit, spec.isFemale == true, false)
            self.targetMode = "outfit"
        else
            return false
        end
    end
    self:applyViewState()
    return true
end

function Window:setPortraitBounds(x, y, width, height)
    local padding = tonumber(self.padding) or 2
    Layout.SetBounds(self, x, y, width, height)
    if self.modelView then
        Layout.SetBounds(
            self.modelView,
            padding,
            padding,
            math.max(1, width - padding * 2),
            math.max(1, height - padding * 2)
        )
    end
end

return Window
