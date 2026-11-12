-- Build 42.20 conversation category/block registry.
-- Stable entry point; registry roles load from the matching subfolder.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.Conversation.Registry = PsychopatzCore.Conversation.Registry or {}
PsychopatzCore.Conversation.Registry.Internal =
    PsychopatzCore.Conversation.Registry.Internal or {}

require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/Utilities"
require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/NodeValidation"
require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/Validation"
require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/Mutations"
require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/Queries"
require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/Handlers"
require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/Fingerprint"

return PsychopatzCore.Conversation.Registry
