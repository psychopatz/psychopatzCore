require "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings
local Animator = Conversation.Animator or {}
Conversation.Animator = Animator

Animator.OPEN_PORTRAIT = 260
Animator.OPEN_HISTORY = 190
Animator.OPEN_CHOICES = 170

local function now()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs()
        or (getGameTime and getGameTime()
            and getGameTime():getWorldAgeHours() * 3600000)
        or 0
end

local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function smooth(value)
    value = clamp01(value)
    return value * value * (3 - (2 * value))
end

function Animator.New()
    return {
        mode = "opening",
        startedAt = now(),
        completed = false,
    }
end

function Animator.StartOpening(state)
    state.mode = "opening"
    state.startedAt = now()
    state.completed = false
end

function Animator.StartClosing(state)
    if state.mode == "closing" then return false end
    state.mode = "closing"
    state.startedAt = now()
    state.completed = false
    return true
end

function Animator.SkipOpen(state)
    state.mode = "open"
    state.completed = true
end

function Animator.Get(state)
    if state.mode == "open" then
        return { portrait = 1, history = 1, choices = 1, interactive = true, done = true }
    end

    local enabled = Settings.Get("crtEnabled", true) == true
    local scale = math.max(0.05, tonumber(Settings.Get("animationScale", 1)) or 1)
    if not enabled then scale = 0.05 end

    local portraitDuration = Animator.OPEN_PORTRAIT * scale
    local historyDuration = Animator.OPEN_HISTORY * scale
    local choicesDuration = Animator.OPEN_CHOICES * scale
    local total = portraitDuration + historyDuration + choicesDuration
    local elapsed = math.max(0, now() - (state.startedAt or now()))

    if state.mode == "closing" then
        local choices = 1 - smooth(elapsed / choicesDuration)
        local historyElapsed = elapsed - choicesDuration
        local history = 1 - smooth(historyElapsed / historyDuration)
        local portraitElapsed = historyElapsed - historyDuration
        local portrait = 1 - smooth(portraitElapsed / portraitDuration)
        local done = elapsed >= total
        if done then state.completed = true end
        return {
            portrait = clamp01(portrait),
            history = clamp01(history),
            choices = clamp01(choices),
            interactive = false,
            done = done,
        }
    end

    local portrait = smooth(elapsed / portraitDuration)
    local history = smooth((elapsed - portraitDuration) / historyDuration)
    local choices = smooth((elapsed - portraitDuration - historyDuration) / choicesDuration)
    local done = elapsed >= total
    if done then
        state.mode = "open"
        state.completed = true
    end
    return {
        portrait = clamp01(portrait),
        history = clamp01(history),
        choices = clamp01(choices),
        interactive = done,
        done = done,
    }
end

return Animator
