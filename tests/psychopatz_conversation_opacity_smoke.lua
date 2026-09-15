local ROOT =
    "Contents/mods/PsychopatzCore/common/media/lua/client/PsychopatzCore/"

local values = {
    conversationOpacityBase = 0.82,
    portraitSurfaceOpacityLift = 0.10,
    portraitDetailOpacityLift = 0.18,
    historySurfaceOpacityLift = 0,
    historyDetailOpacityLift = 0.18,
    relationshipSurfaceOpacityLift = 0.04,
    relationshipDetailOpacityLift = 0.12,
    choicesSurfaceOpacityLift = 0,
    choicesDetailOpacityLift = 0.18,
    llmInputSurfaceOpacityLift = 0,
    llmInputDetailOpacityLift = 0.18,
}

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function assertNear(actual, expected, label)
    if math.abs(actual - expected) > 0.0001 then
        error((label or "assertNear") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

PsychopatzCore = {
    Conversation = {
        Settings = {
            Get = function(key, fallback)
                return values[key] == nil and fallback or values[key]
            end,
        },
    },
}

package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"] =
    function() return PsychopatzCore.Conversation.Settings end

dofile(ROOT .. "UI/Conversation/PsychopatzConversationOpacity.lua")

local Opacity = PsychopatzCore.Conversation.Opacity
assertNear(Opacity.Get("portrait", "surface"), 0.92,
    "portrait surface uses parent plus lift")
assertNear(Opacity.Get("history", "detail"), 1,
    "history detail reaches readable opacity")
assertNear(Opacity.Get("relationship", "surface"), 0.86,
    "relationship surface remains independently adjustable")
assertNear(Opacity.Get("relationship", "detail"), 0.94,
    "relationship detail uses its own lift")

values.conversationOpacityBase = 0.70
assertNear(Opacity.Get("choices", "detail"), 0.88,
    "base changes propagate without changing module lifts")
assertEqual(Opacity.GetSignature() ~= "", true,
    "opacity signature is available for live control refresh")

print("psychopatz_conversation_opacity_smoke: ok")
