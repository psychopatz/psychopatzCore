PsychopatzCore = PsychopatzCore or {}

require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
require "PsychopatzCore/Conversation/PsychopatzNameParts"
-- Public, opt-in voice transport. Loading this module only defines the API;
-- it installs no event or tick listeners until a mod registers a source.
require "PsychopatzCore/Voice/PsychopatzVoiceGateway"
require "PsychopatzCore/Journal/PC_JournalService"

return PsychopatzCore
