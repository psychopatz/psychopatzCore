require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationBackgrounds"

PsychopatzConversationPortrait = PsychopatzConversationPart:derive(
    "PsychopatzConversationPortrait"
)

local Conversation = PsychopatzCore.Conversation
PsychopatzConversationPortrait.Internal = {
    Conversation = Conversation,
}

require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait_Input"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait_Setup"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait_State"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait_View"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait_Renderer"

return PsychopatzConversationPortrait
