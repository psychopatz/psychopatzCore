-- Reusable conversation text input for integrations backed by an external
-- language model. The owner supplies submission and state callbacks so the
-- component works in a full conversation view or a compact host.
require "ISUI/ISButton"
require "PsychopatzCore/UI/Core/PsychopatzUITheme"
require "PsychopatzCore/UI/Components/PsychopatzImageResolver"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Components/PsychopatzTextEntry"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"

PsychopatzConversationLLMInput = PsychopatzConversationPart:derive(
    "PsychopatzConversationLLMInput"
)

local Internal = require
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput_Foundation"
PsychopatzConversationLLMInput.Internal = Internal

require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput_Setup"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput_Controls"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput_Layout"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput_Interaction"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput_Visuals"

return PsychopatzConversationLLMInput
