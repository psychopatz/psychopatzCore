local Portrait = PsychopatzConversationPortrait
local Conversation = PsychopatzCore.Conversation
local Input = require
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait_Input"

function Portrait:setScreenVariant(variant)
    self.screenVariant = Input.NormalizeScreenVariant(variant)
    if self.portrait and self.portrait.setScreenVariant then
        self.portrait:setScreenVariant(self:getScreenVariant())
    end
end

function Portrait:setTemporaryScreenVariant(variant)
    self.temporaryScreenVariant = Input.NormalizeScreenVariant(variant)
    self:syncScreenVariant()
end

function Portrait:getScreenVariant()
    local temporaryVariant = Input.NormalizeScreenVariant(
        self.temporaryScreenVariant
    )
    if temporaryVariant then return temporaryVariant end
    local variant = Input.NormalizeScreenVariant(self.screenVariant)
    if variant then return variant end
    return Input.IsCRTEnabled(self) and "crt" or "subtle"
end

function Portrait:syncScreenVariant()
    if self.portrait and self.portrait.setScreenVariant then
        self.portrait:setScreenVariant(self:getScreenVariant())
    end
end

function Portrait:setBackground(id)
    self.backgroundID = id or "twilight"
    self.backgroundDefinition = Conversation.Backgrounds.Get(self.backgroundID)
    self.backgroundTexture = nil
    if getTexture and self.backgroundDefinition then
        self.backgroundTexture = getTexture(self.backgroundDefinition.texture)
    end
end

return Portrait
