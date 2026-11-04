local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}

local Notifications = require
    "PsychopatzCore/UI/PsychopatzActorNotificationToast"

Notifications.Clear()

local persistent, persistentReason = Notifications.Show({
    id = "toast:actor:persistent",
    actorID = "actor:toast:persistent",
    name = "Trader Persistent",
    message = "A trader is operating nearby.",
    persistent = true,
    portraitSpec = {
        actorID = "actor:toast:persistent",
        face = {},
    },
})
assert(persistent == true, persistentReason)
assert(Notifications.Queue[1].persistent == true,
    "proximity actor notifications must opt into persistent presentation")
assert(type(Notifications.Update) == "function",
    "actor notifications need an in-place update API for proximity refresh")
local updated, updateReason = Notifications.Update(
    "toast:actor:persistent",
    {
        id = "toast:actor:persistent",
        actorID = "actor:toast:persistent",
        name = "Trader Persistent",
        message = "The trader is still operating nearby.",
        persistent = true,
    }
)
assert(updated == true, updateReason)
assert(Notifications.Queue[1].message
        == "The trader is still operating nearby.",
    "persistent actor notifications did not refresh in place")
assert(Notifications.Dismiss("toast:actor:persistent") == true,
    "persistent actor notification did not dismiss explicitly")

assert(Notifications.MAX_QUEUE >= 4,
    "actor notification queue must be bounded but usable")

local shown, reason = Notifications.Show({
    id = "toast:actor:one",
    actorID = "actor:toast:one",
    name = "Trader Ada",
    message = "A trading caravan arrived.",
    portraitSpec = {
        actorID = "actor:toast:one",
        face = {},
    },
    factionBadge = {
        factionID = "faction:toast:one",
        glyph = "T",
    },
    actions = {
        {
            id = "talk",
            label = "Talk",
            callback = function() end,
        },
    },
})
assert(shown == true, reason)
assert(Notifications.Queue[1].actorID == "actor:toast:one",
    "toast did not retain canonical actor identity")
assert(Notifications.Queue[1].portraitSpec.actorID == "actor:toast:one",
    "toast did not retain canonical portrait input")
assert(Notifications.Queue[1].factionBadge.glyph == "T",
    "toast did not retain optional faction badge")
assert(Notifications.Queue[1].actions[1].id == "talk",
    "toast did not retain optional action")

local duplicate, duplicateReason = Notifications.Show({
    id = "toast:actor:one",
    actorID = "actor:toast:one",
    message = "duplicate",
})
assert(duplicate == false and duplicateReason == "duplicate",
    "actor toast duplicate suppression changed")

for index = 2, Notifications.MAX_QUEUE + 3 do
    Notifications.Show({
        id = "toast:bounded:" .. tostring(index),
        actorID = "actor:toast:" .. tostring(index),
        name = "Trader " .. tostring(index),
        message = "short",
    })
end
assert(#Notifications.Queue <= Notifications.MAX_QUEUE,
    "actor toast queue exceeded its bound")

assert(Notifications.Dismiss(Notifications.Queue[1].id) == true,
    "actor toast dismiss did not acknowledge an item")

print("psychopatz_actor_notification_toast_smoke: PASS")
