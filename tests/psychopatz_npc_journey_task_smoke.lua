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
local World = Actors.World
local Task = Actors.Task
local Scheduler = Actors.Scheduler

local registry = Actors.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:p5:merchant",
    identitySeed = "p5-journey-seed",
    world = {
        position = { x = 10, y = 20, z = 0 },
        anchors = {
            ["anchor:home"] = {
                anchorID = "anchor:home",
                kind = "settlement",
                point = { x = 10, y = 20, z = 0 },
                metadata = { owner = "core" },
            },
            ["anchor:market"] = {
                anchorID = "anchor:market",
                kind = "market",
                point = { x = 110, y = 20, z = 0 },
                metadata = { owner = "core" },
            },
        },
        activeAnchorID = "anchor:home",
    },
})
truthy(actor, actorReason)
truthy(actor.world, "actor world state created")
equal(actor.world.location.activeAnchorID, "anchor:home",
    "location anchor created")

local world, worldReason = World.StartJourney(actor.world, actor.actorId, {
    journeyID = "journey:p5:merchant",
    originAnchorID = "anchor:home",
    destinationAnchorID = "anchor:market",
    origin = { x = 10, y = 20, z = 0 },
    destination = { x = 110, y = 20, z = 0 },
    speed = 10,
    startAt = 0,
    arrivalAction = { type = "visit_market" },
    metadata = { reason = "restock" },
}, 0)
truthy(world, worldReason)
equal(world.journey.state, "en_route", "journey starts en route")
equal(world.journey.distanceTotal, 100, "journey distance")

local task, taskReason = Task.New({
    taskID = "task:p5:visit",
    actorID = actor.actorId,
    type = "travel_to_anchor",
    dueAt = 0,
    priority = 4,
    targetAnchorID = "anchor:market",
    payload = { journeyID = "journey:p5:merchant" },
})
truthy(task, taskReason)
truthy(Task.Enqueue(world.tasks, task), "task queued")
local due = Task.PopDue(world.tasks, 0, 4)
equal(#due, 1, "bounded task pop")
equal(world.tasks.tasks[task.taskID].state, "leased",
    "task lease state persisted")

local schedule, scheduleReason = Scheduler.Schedule(world.scheduler, {
    entryID = "schedule:p5:visit",
    actorID = actor.actorId,
    taskID = task.taskID,
    dueAt = 5,
    priority = 4,
})
truthy(schedule, scheduleReason)
world.scheduler = schedule
local scheduledDue, scheduledEntries = Scheduler.PopDue(world.scheduler, 4, 4)
equal(#scheduledEntries, 0, "future schedule is not due")
local dueState, dueEntries = Scheduler.PopDue(scheduledDue, 5, 4)
equal(#dueEntries, 1, "schedule becomes due")
world.scheduler = dueState

local committed, commitReason = registry:Commit(actor.actorId, {
    world = world,
}, actor.revision)
truthy(committed, commitReason)

local saved, saveReason = registry:Save()
truthy(saved, saveReason)
local fresh = Actors.NewRegistry()
truthy(fresh:Load(saved), "journey registry reload")
local restored = fresh:Get(actor.actorId)
truthy(restored, "journey actor reload")
equal(restored.world.journey.journeyID, "journey:p5:merchant",
    "journey identity survives reload")
equal(restored.world.tasks.tasks[task.taskID].state, "leased",
    "task state survives reload")
equal(restored.world.scheduler.entries["schedule:p5:visit"], nil,
    "consumed schedule does not replay")

local advanced = World.AdvanceJourney(restored.world, 9)
equal(advanced.journey.state, "en_route", "journey remains en route")
equal(advanced.journey.progress, 0.9, "journey progress deterministic")
local arrived = World.AdvanceJourney(advanced, 10)
equal(arrived.journey.state, "arrived", "journey arrives once")
equal(arrived.location.position.x, 110, "arrival position restored")
equal(arrived.location.activeAnchorID, "anchor:market",
    "arrival anchor restored")

local handled, handledReason = World.MarkArrivalHandled(arrived, "p5-test")
truthy(handled, handledReason)
local repeated, repeatedReason = World.MarkArrivalHandled(handled, "p5-test")
equal(repeated, nil, "arrival handler replay rejected")
equal(repeatedReason, "arrival_already_handled", "arrival replay reason")

local committedArrival, arrivalCommitReason = fresh:Commit(actor.actorId, {
    world = handled,
}, restored.revision)
truthy(committedArrival, arrivalCommitReason)
local finalPayload = fresh:Save()
local finalRegistry = Actors.NewRegistry()
truthy(finalRegistry:Load(finalPayload), "arrival final reload")
local finalActor = finalRegistry:Get(actor.actorId)
equal(finalActor.world.journey.arrivalHandled, true,
    "arrival handled state survives reload")
equal(finalActor.world.journey.arrivalHandledBy, "p5-test",
    "arrival handler identity survives reload")

print("psychopatz_npc_journey_task_smoke: PASS")
