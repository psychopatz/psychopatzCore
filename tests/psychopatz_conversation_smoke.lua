local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/UI/Conversation/"

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
local compact = modData[History.STORAGE_KEY].threads["Test:npc-1"][1]
assertEqual(compact.k, "PNC_Test_Domain", "translation key serialized")
assertEqual(compact.d, "TestDomain", "translation domain serialized")
assertEqual(compact.a[1], "Alex", "translation argument serialized")
assertEqual(compact.a.status, "safe", "named translation argument serialized")
assertEqual(compact.text, nil, "resolved text is not serialized")
assertEqual(compact.f, nil, "keyed fallback prose is not serialized")

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

print("psychopatz_conversation_smoke: ok")
