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
local registry = Actors.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:p6:talker",
    identitySeed = "p6-presentation-seed",
    world = { position = { x = 10, y = 20, z = 0 } },
})
truthy(actor, actorReason)

local map = Actors.Map.NewRegistry()
local entry, entryReason = map:ProjectActor(actor, {
    provider = "PsychopatzCore",
    visibility = "known",
    knownTo = { "player:one" },
    markerID = "npc",
    capabilities = { talk = true, inspect = true, trade = false },
})
truthy(entry, entryReason)
equal(map:Count(), 1, "map entry count")
equal(#map:ListFor("player:one"), 1, "known actor is visible")
equal(#map:ListFor("player:two"), 0, "unknown actor is hidden")
local nearby = map:QueryNearby({ x = 11, y = 20, z = 0 }, 2,
    "player:one")
equal(#nearby, 1, "nearby actor query")
equal(nearby[1].distance, 1, "nearby distance")
equal(nearby[1].portrait.face.hairModel,
    actor.appearance.resolved.hairModel, "portrait face projection")

local request, requestReason = Actors.Interaction.BuildNearbyConversation(
    nearby[1], "player:one", nearby[1].distance)
truthy(request, requestReason)
local unauthorized, unauthorizedReason =
    Actors.Interaction.AuthorizeConversation(request, nearby[1], {
        authority = "client", maxDistance = 2,
    })
equal(unauthorized, false, "client talk request rejected")
equal(unauthorizedReason, "server_authority_required", "authority reason")
local authorized, authorizedResult =
    Actors.Interaction.AuthorizeConversation(request, nearby[1], {
        authority = "server", maxDistance = 2,
    })
truthy(authorized, authorizedResult)
equal(authorizedResult.authorized, true, "server talk request authorized")
local far, farReason = Actors.Interaction.AuthorizeConversation(request,
    nearby[1], { authority = "server", maxDistance = 0.5 })
equal(far, false, "far talk request rejected")
equal(farReason, "actor_not_nearby", "nearby boundary reason")

local mapPayload = map:Save()
local mapReloaded = Actors.Map.NewRegistry()
truthy(mapReloaded:Load(mapPayload), "map payload reload")
equal(#mapReloaded:ListFor("player:one"), 1,
    "map knowledge survives reload")

local queue = Actors.Notifications.NewQueue()
local notice, noticeReason = queue:Publish({
    notificationID = "notice:p6:talker",
    kind = "nearby_actor",
    actorID = actor.actorId,
    createdAt = 12,
    payload = { label = entry.label, action = "talk" },
})
truthy(notice, noticeReason)
local duplicate, duplicateReason = queue:Publish({
    notificationID = "notice:p6:talker", kind = "nearby_actor",
})
equal(duplicate, nil, "duplicate notification rejected")
equal(duplicateReason, "duplicate_notification", "notification dedupe reason")
local drained = queue:Drain(4)
equal(#drained, 1, "notification drained")
equal(#queue:List(), 0, "notification acknowledged")

print("psychopatz_npc_presentation_smoke: PASS")
