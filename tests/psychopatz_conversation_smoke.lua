local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/"
local SHARED = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local values = {}
local worldHours = 30
local now = 1000
local modData = {}

PsychopatzCore = {
    Conversation = {
        Settings = {
            Get = function(key, fallback)
                local value = values[key]
                if value == nil then return fallback end
                return value
            end,
            Set = function(key, value)
                values[key] = value
                return value
            end,
        },
    },
}

package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationText"] =
    function() return PsychopatzCore.Conversation.Text end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"] =
    function() return PsychopatzCore.Conversation.Settings end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationHistory"] =
    function() return PsychopatzCore.Conversation.History end
package.preload["PsychopatzCore/Conversation/PsychopatzConversationMessage"] =
    function() return PsychopatzCore.Conversation.Message end
package.preload["PsychopatzCore/UI/Core/PsychopatzUILayout"] =
    function() return true end

getText = function(key, value)
    if key == "UI_Test_Message" then return "Hello " .. tostring(value) end
    return key
end
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
    }
end
getTimeInMillis = function() return now end
ModData = {
    getOrCreate = function(key)
        modData[key] = modData[key] or {}
        return modData[key]
    end,
}

dofile(ROOT .. "PsychopatzConversationText.lua")
dofile(SHARED .. "PsychopatzCore/Events/PC_EventBus.lua")
dofile(SHARED .. "PsychopatzCore/Conversation/PsychopatzConversationMessage.lua")
dofile(ROOT .. "PsychopatzConversationTheme.lua")
PsychopatzConversation_Text_TestDomain_EN = {
    PNC_Test_Domain = "Hello %1. Status: {status}.",
}
PsychopatzCore.Conversation.Text.RegisterDomain("TestDomain")
dofile(ROOT .. "PsychopatzConversationHistory.lua")
dofile(ROOT .. "PsychopatzConversationLayout.lua")
dofile(ROOT .. "PsychopatzConversationAnimator.lua")
dofile(ROOT .. "PsychopatzConversationSession.lua")
dofile(ROOT .. "PsychopatzConversationLifecycle.lua")

local Text = PsychopatzCore.Conversation.Text
local Theme = PsychopatzCore.Conversation.Theme
local History = PsychopatzCore.Conversation.History
local Layout = PsychopatzCore.Conversation.Layout
local Animator = PsychopatzCore.Conversation.Animator
local Session = PsychopatzCore.Conversation.Session
local Lifecycle = PsychopatzCore.Conversation.Lifecycle
local Message = PsychopatzCore.Conversation.Message
local Events = PsychopatzCore.Events

local canonicalMessages = {}
local publishedMessage
Events.subscribe(Message.EVENT_TYPE, function(message)
    publishedMessage = message
end, "conversation-smoke")
local canonicalSession = Session.New({
    choicesPart = { setChoices = function() end },
    historyPart = {
        addMessage = function(_, message)
            canonicalMessages[#canonicalMessages + 1] = message
        end,
        setTyping = function() end,
    },
}, {
    namespace = "CanonicalTest",
    npcID = "npc-canonical",
    characterUUID = "player-canonical",
    context = {
        npcName = "Canonical NPC",
        playerName = "Canonical Player",
    },
    persistHistory = false,
    conversationID = "canonical-conversation",
    saveUUID = "canonical-save",
    participants = {
        { id = "player-canonical", kind = "player" },
        { id = "npc-canonical", kind = "npc" },
    },
})
canonicalSession:append("npc", { text = "A dated reply." })
assertEqual(#canonicalMessages, 1, "canonical message reaches chat")
assertEqual(canonicalMessages[1].messageID, "canonical-conversation:1",
    "canonical message ID")
assertEqual(canonicalMessages[1].conversationID, "canonical-conversation",
    "canonical conversation ID")
assertEqual(canonicalMessages[1].saveUUID, "canonical-save",
    "canonical save ID")
assertEqual(canonicalMessages[1].speakerID, "npc-canonical",
    "canonical NPC ID")
assertEqual(canonicalMessages[1].speakerName, "Canonical NPC",
    "canonical NPC name")
assertEqual(canonicalMessages[1].playerUUID, "player-canonical",
    "canonical player scope")
assertEqual(canonicalMessages[1].npcUUID, "npc-canonical",
    "canonical NPC scope")
assertEqual(canonicalMessages[1].namespace, "CanonicalTest",
    "canonical namespace")
assertEqual(canonicalMessages[1].gameDay, 1, "canonical game day")
assertEqual(canonicalMessages[1].worldAgeHours, 30,
    "canonical world age")
assertEqual(canonicalMessages[1].text, "A dated reply.",
    "canonical resolved text")
assertEqual(canonicalMessages[1].presentationState.conversationUI, true,
    "canonical UI presentation state")
assertEqual(publishedMessage, canonicalMessages[1],
    "canonical message publication")
assertEqual(canonicalMessages[1].participants[2].id, "npc-canonical",
    "canonical participants")
canonicalSession:append({
    kind = "npc",
    id = "npc-second",
    name = "Second NPC",
}, { text = "A second speaker." })
assertEqual(canonicalMessages[2].sequence, 2, "multi-NPC sequence")
assertEqual(canonicalMessages[2].speakerID, "npc-second",
    "multi-NPC speaker ID")
assertEqual(canonicalMessages[2].speakerName, "Second NPC",
    "multi-NPC speaker name")
Events.clearOwner("conversation-smoke")

assertEqual(Text.Resolve({ key = "UI_Test_Message", args = { "Alex" } }),
    "Hello Alex", "translation payload")
local hostileAccent = Theme.Resolve({
    theme = { accent = { r = 1, g = 0.25, b = 0.20 } },
})
assertEqual(hostileAccent.r, 1, "conversation theme red channel")
assertEqual(hostileAccent.g, 0.25, "conversation theme green channel")
assertEqual(Text.Resolve({
    key = "PNC_Test_Domain",
    domain = "TestDomain",
    args = { [1] = "Alex", status = "safe" },
}), "Hello Alex. Status: safe.", "modular domain translation")

local mappedChoices
local choiceSession = Session.New({
    choicesPart = {
        setChoices = function(_, choices) mappedChoices = choices end,
    },
}, { context = {} })
choiceSession:setChoices({
    { id = "hello", textKey = "UI_Test_Message", textArgs = { "Alex" } },
})
assertEqual(mappedChoices[1].text.key, "UI_Test_Message", "choice text key mapping")
assertEqual(mappedChoices[1].text.args[1], "Alex", "choice text argument mapping")

local selectedActions = 0
local sessionMessages = {}
local navigationChoices
local navigationSession = Session.New({
    choicesPart = {
        setChoices = function(_, choices) navigationChoices = choices end,
    },
    historyPart = {
        addMessage = function(_, message)
            sessionMessages[#sessionMessages + 1] = message
        end,
        setTyping = function() end,
    },
}, { namespace = "NavigationTest", npcID = "npc-navigation", context = {} })
navigationSession:setChoices({
    {
        id = "topics",
        text = { text = "Ask about..." },
        log = false,
        action = function() selectedActions = selectedActions + 1 end,
    },
})
navigationSession:selectChoice(navigationChoices[1])
assertEqual(selectedActions, 1, "navigation choice action runs")
assertEqual(#sessionMessages, 0, "navigation choice is not added to log")

local capturedCloseReason
local closingChoices
local closingSession = Session.New({
    choicesPart = {
        setChoices = function(_, choices) closingChoices = choices end,
    },
    historyPart = {
        addMessage = function() end,
        setTyping = function() end,
    },
    close = function(_, reason) capturedCloseReason = reason end,
}, { context = {} })
closingSession:setChoices({
    {
        id = "terminal",
        text = { text = "Leave" },
        log = false,
        close = true,
        closeReason = "authored_terminal:test",
    },
})
closingSession:selectChoice(closingChoices[1])
assertEqual(capturedCloseReason, "authored_terminal:test",
    "authored close reason reaches the view")

local sandboxMessages = {}
local sandboxSession = Session.New({
    choicesPart = { setChoices = function() end },
    historyPart = {
        addMessage = function(_, message)
            sandboxMessages[#sandboxMessages + 1] = message
        end,
        setMessages = function() end,
        setTyping = function() end,
    },
}, {
    namespace = "SandboxTest",
    npcID = "debug-npc",
    persistHistory = false,
    nodes = {},
})
sandboxSession:append("npc", { fallback = "Sandbox only" })
assertEqual(#sandboxMessages, 1, "sandbox still renders conversation messages")
assertEqual(modData[History.STORAGE_KEY], nil,
    "non-persistent sandbox does not create conversation history")

History.Append("Test", "npc-1", "npc", {
    key = "PNC_Test_Domain",
    domain = "TestDomain",
    args = { [1] = "Alex", status = "safe" },
    fallback = "Duplicated resolved prose",
})
History.Append("Test", "npc-1", "player", {
    key = "UI_Test_Player",
    fallback = "Hi.",
})
local records = History.Get("Test", "npc-1")
assertEqual(#records, 2, "same-day history")
assertEqual(records[1].speaker, "npc", "NPC speaker")
assertEqual(records[2].speaker, "player", "player speaker")
local compact = modData[History.STORAGE_KEY].threads["unbound:Test:npc-1"][1]
assertEqual(compact.k, "PNC_Test_Domain", "translation key serialized")
assertEqual(compact.d, "TestDomain", "translation domain serialized")
assertEqual(compact.a[1], "Alex", "translation argument serialized")
assertEqual(compact.a.status, "safe", "named translation argument serialized")
assertEqual(compact.text, nil, "resolved text is not serialized")
assertEqual(compact.f, nil, "keyed fallback prose is not serialized")

History.Append("Test", "canonical-history", "npc", { fallback = "Connected" },
    "char_canonical", canonicalMessages[1])
local historical = History.Get("Test", "canonical-history", "char_canonical")[1]
assertEqual(historical.messageID, canonicalMessages[1].messageID,
    "history preserves canonical message ID")
assertEqual(historical.conversationID, canonicalMessages[1].conversationID,
    "history preserves canonical conversation ID")

History.Append("Test", "npc-scoped", "npc", { fallback = "Alpha" },
    "char_alpha")
History.Append("Test", "npc-scoped", "npc", { fallback = "Beta" },
    "char_beta")
assertEqual(#History.Get("Test", "npc-scoped", "char_alpha"), 1,
    "history is scoped to first survivor")
assertEqual(#History.Get("Test", "npc-scoped", "char_beta"), 1,
    "history is scoped to second survivor")
assertEqual(
    PsychopatzCore.Conversation.Text.Resolve(
        History.Get("Test", "npc-scoped", "char_alpha")[1].payload
    ),
    "Alpha", "survivor histories do not cross"
)

worldHours = 49
assertEqual(#History.Get("Test", "npc-1"), 0, "history clears on next day")

Layout.Save("portrait", { x = 100, y = 80, width = 300, height = 240 },
    1000, 800, true)
local bounds = Layout.Resolve("portrait", 2000, 1600)
assertEqual(bounds.x, 200, "normalized layout x scales")
assertEqual(bounds.width, 600, "normalized layout width scales")

values.crtEnabled = true
values.animationScale = 1
local animation = Animator.New()
now = animation.startedAt + Animator.OPEN_PORTRAIT
local state = Animator.Get(animation)
assert(state.portrait > 0.99, "portrait animation phase")
assert(state.history < 0.01, "history waits for portrait")
now = now + Animator.OPEN_HISTORY + Animator.OPEN_CHOICES
state = Animator.Get(animation)
assertEqual(state.done, true, "opening animation completes")
Animator.StartClosing(animation)
now = animation.startedAt + Animator.OPEN_CHOICES + Animator.OPEN_HISTORY
state = Animator.Get(animation)
assert(state.choices < 0.01 and state.history < 0.01,
    "reverse close hides choices and history first")

local lifecycleEvents = {}
local view = {
    spec = {
        lifecycle = {
            begin = function()
                lifecycleEvents[#lifecycleEvents + 1] = "begin"
                return { marker = "active" }
            end,
            update = function(_, _, lifecycleState)
                assertEqual(lifecycleState.marker, "active",
                    "lifecycle state passed to update")
                lifecycleEvents[#lifecycleEvents + 1] = "update"
                return "distance"
            end,
            finish = function(_, _, lifecycleState, reason)
                assertEqual(lifecycleState.marker, "active",
                    "lifecycle state passed to finish")
                lifecycleEvents[#lifecycleEvents + 1] = reason
            end,
        },
    },
}
assertEqual(Lifecycle.Begin(view), true, "lifecycle begins")
assertEqual(Lifecycle.Update(view), "distance", "lifecycle interrupts")
assertEqual(Lifecycle.Finish(view, "distance"), true, "lifecycle finishes")
assertEqual(Lifecycle.Finish(view, "duplicate"), false,
    "lifecycle finish is idempotent")
assertEqual(table.concat(lifecycleEvents, ","), "begin,update,distance",
    "lifecycle callback order")

-- Headless hosts do not have an ISPanel update loop, but integrations must be
-- able to drive the same lifecycle heartbeat explicitly.
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationBackgrounds"] =
    function() return {} end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationView"] =
    function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationSession"] =
    function() return PsychopatzCore.Conversation.Session end
dofile(ROOT .. "PsychopatzConversation.lua")
local headlessEvents = {}
local headless = PsychopatzCore.Conversation.CreateHeadless({
    namespace = "HeadlessTest",
    npcID = "headless-npc",
    characterUUID = "headless-player",
    persistHistory = false,
    context = {},
    start = "start",
    nodes = { start = { choices = {} } },
    lifecycle = {
        begin = function() return { marker = "headless-active" } end,
        update = function(_, _, state)
            assertEqual(state.marker, "headless-active",
                "headless lifecycle state")
            headlessEvents[#headlessEvents + 1] = "update"
        end,
        finish = function(_, _, _, reason)
            headlessEvents[#headlessEvents + 1] = reason
        end,
    },
})
assertEqual(headless.lifecycleError, nil, "headless lifecycle begins")
assertEqual(headless:updateLifecycle(), nil, "headless lifecycle heartbeat")
headless:close("headless_done")
assertEqual(table.concat(headlessEvents, ","), "update,headless_done",
    "headless lifecycle callback order")

print("psychopatz_conversation_smoke: ok")
