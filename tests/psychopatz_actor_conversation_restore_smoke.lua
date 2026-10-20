local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local ActorService = require
    "PsychopatzCore/Conversation/PsychopatzActorConversationService"
local Router = require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter"
local State = require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueState"

local registry = Actors.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:c5:conversation-restore",
    identitySeed = "c5-conversation-seed",
})
truthy(actor, actorReason)

local source = ActorService.New({
    actor = actor,
    router = Router.New({
        state = State.New({
            pendingQuestion = { id = "question:home", topic = "residence" },
            pendingRequest = { id = "request:water", topic = "water" },
            recentSemanticEvents = {
                { sequence = 1, topic = "residence", rawText = "where do you live" },
                { sequence = 2, topic = "water", rawText = "can you help" },
            },
        }),
    }),
    conversationID = "c5-restore-source",
})
local snapshot = source:Snapshot()
local restored = ActorService.New({
    actor = actor,
    router = Router.New(),
    conversationID = "c5-restore-target",
})
local restoredSnapshot, restoreReason = restored:Restore(snapshot)
truthy(restoredSnapshot, restoreReason)
equal(restoredSnapshot.actorID, actor.actorId, "restore actor binding")
equal(restoredSnapshot.conversationID, "c5-restore-source",
    "restore keeps bounded conversation identity")
equal(restoredSnapshot.state.pendingQuestion.id, "question:home",
    "restore keeps pending question")
equal(restoredSnapshot.state.pendingRequest.id, "request:water",
    "restore keeps pending request")
equal(#restoredSnapshot.state.recentSemanticEvents, 2,
    "restore keeps bounded event history")

local other = registry:Create({
    actorId = "npc:c5:conversation-other",
    identitySeed = "c5-other-seed",
})
local otherService = ActorService.New({ actor = other, router = Router.New() })
local mismatched, mismatchReason = otherService:Restore(snapshot)
equal(mismatched, nil, "restore cannot cross actor identity")
equal(mismatchReason, "conversation_actor_mismatch",
    "restore actor mismatch reason")

print("psychopatz_actor_conversation_restore_smoke: PASS")
