-- End-to-end smoke test for PsychopatzCore unified actor identity exchange
-- and server-authoritative per-player knowledge sync.
package.path = "./Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;"
    .. "./Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;"
    .. "./Contents/mods/PsychopatzCore/42.20/media/lua/server/?.lua;"
    .. "./Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua;"
    .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function assertTruthy(value, label)
    if not value then error((label or "truthy") .. ": expected truthy", 2) end
end

local function assertFalsy(value, label)
    if value then error((label or "falsy") .. ": expected falsy", 2) end
end

-- Strict Kahlua2-like IsoPlayer userdata mock (rejects field writes).
local playerProxy = setmetatable({}, {
    __index = {
        getUsername = function() return "alec_user" end,
        getOnlineID = function() return 4 end,
        getDescriptor = function()
            return setmetatable({}, {
                __index = {
                    getForename = function() return "Alec" end,
                    getSurname = function() return "Engle" end,
                },
                __newindex = function() error("attempted index of non-table (SurvivorDesc)") end,
            })
        end,
    },
    __newindex = function() error("attempted index of non-table (IsoPlayer)") end,
})

local serverListeners = {}
Events = {
    OnServerCommand = {
        Add = function(fn) serverListeners[#serverListeners + 1] = fn end,
    },
    OnClientCommand = { Add = function() end },
}
function triggerEvent(eventName, module, command, args)
    if eventName == "OnServerCommand" then
        for i = 1, #serverListeners do
            serverListeners[i](module, command, args)
        end
    end
end
function getSpecificPlayer() return playerProxy end
function getPlayer() return playerProxy end
function getGameTime() return { getWorldAgeHours = function() return 42.5 end } end
function isClient() return false end
function isServer() return false end

PsychopatzCore = {
    COMMAND_MODULE = "PsychopatzCore",
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local Exchange = require "PsychopatzCore/Actors/PsychopatzActorIdentityExchange"
local Server = require "PsychopatzCore/Actors/PsychopatzActorKnowledgeServer"
local Client = require "PsychopatzCore/Actors/PsychopatzActorKnowledgeClient"

-- 1) Identity exchange primitives: exact matching & nickname-else-firstname policy
assertTruthy(Exchange.ClaimMatchesName("Alec", "Alec Engle"), "first name matches canonical")
assertTruthy(Exchange.ClaimMatchesName("Alec Engle", "Alec Engle"), "full name matches canonical")
assertFalsy(Exchange.ClaimMatchesName("Psycho", "Alec Engle"), "false name rejected as lie")

local dNick, lNick = Exchange.ResolveInitialDisclosedName({ fullName = "Elena Parker", forename = "Elena", nickname = "Ellie" }, 0)
assertEqual(dNick, "Ellie", "low familiarity prefers nickname when present")
assertEqual(lNick, "nickname", "level is nickname")

local dFirst, lFirst = Exchange.ResolveInitialDisclosedName({ fullName = "Elena Parker", forename = "Elena" }, 0)
assertEqual(dFirst, "Elena", "low familiarity falls back to first name when no nickname")
assertEqual(lFirst, "first_name", "level is first_name")

local dFull, lFull = Exchange.ResolveInitialDisclosedName({ fullName = "Elena Parker", forename = "Elena", nickname = "Ellie" }, 30)
assertEqual(dFull, "Elena Parker (Ellie)", "familiarity >= 25 discloses full name with nickname")
assertEqual(lFull, "full_name", "level is full_name")

-- 2) Server <-> Client knowledge sync with mock actor in registry
local actor = {
    actorId = "actor:trader:1",
    provider = "DTAbstract",
    displayName = "Milagros Masters",
    identity = { forename = "Milagros", surname = "Masters", displayName = "Milagros Masters" },
    factionID = "faction_caravan",
    factionName = "Caravan Guild",
    social = { relationships = {} },
}
Server.FallbackActors[actor.actorId] = actor

local queuedReplies = {}
PsychopatzCore.Conversation = {
    instance = {
        spec = { npcID = actor.actorId, context = { npcName = "Stranger", knowledge = {} } },
        session = {
            queueMessage = function(_, speaker, payload)
                queuedReplies[#queuedReplies + 1] = { speaker = speaker, text = payload.text }
            end,
        },
    },
}

local subscriberHits = 0
Client.Subscribe(function(id, snap)
    if id == actor.actorId and snap and snap.nameKnown == true then
        subscriberHits = subscriberHits + 1
    end
end)

-- 2a) Typed false name triggers lie guard, does NOT disclose name, does NOT persist fake alias
local lieOk = Client.SubmitIdentityClaim(actor.actorId, {
    kind = "identity_claim",
    claimedName = "Psycho",
})
assertTruthy(lieOk, "lie claim handled by Core server")
assertEqual(Client.Get(actor.actorId), nil, "lie does not disclose actor knowledge")
assertEqual(actor.knowledge, nil, "lie does not persist fake alias on actor.knowledge")
assertTruthy(string.find(queuedReplies[#queuedReplies].text, "Don't lie", 1, true),
    "lie guard delivers false-name response")

-- 2b) Truthful canonical claim persists knowledge, updates view, notifies subscribers
local trueOk = Client.SubmitIdentityClaim(actor.actorId, {
    kind = "identity_claim",
    claimMode = "canonical",
    claimedName = "Alec Engle",
})
assertTruthy(trueOk, "canonical claim accepted by Core server")
local learned = Client.Get(actor.actorId)
assertTruthy(learned and learned.nameKnown == true, "client cache learns actor name")
assertTruthy(type(learned.knownName) == "string" and learned.knownName ~= "", "knownName populated")
assertEqual(subscriberHits, 1, "knowledge subscriber notified")
assertEqual(PsychopatzCore.Conversation.instance.spec.context.npcName, learned.knownName,
    "active conversation view context updated with learned name")
assertTruthy(string.find(queuedReplies[#queuedReplies].text, "Okay Alec, nice to meet you. I'm ", 1, true),
    "truthful claim delivers mutual introduction reply")

-- 2c) Facet disclosure respects familiarity gate and persists when allowed
local deniedFaction = Client.RequestDisclosure(actor.actorId, "faction")
assertFalsy(deniedFaction, "faction denied at familiarity 0")
actor.social.relationships["player:online_4"] = { familiarity = 15 }
local okFaction = Client.RequestDisclosure(actor.actorId, "faction")
assertTruthy(okFaction, "faction disclosed at familiarity 15")
assertEqual(Client.Get(actor.actorId).factionName, "Caravan Guild", "faction persisted in Core knowledge")

print("psychopatz_actor_knowledge_sync_smoke: PASS")
