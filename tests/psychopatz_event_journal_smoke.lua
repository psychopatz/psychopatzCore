local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local RingBuffer = require "PsychopatzCore/Collections/PC_RingBuffer"
local ring = RingBuffer.new(3)
ring:append("a")
ring:append("b")
equal(ring:count(), 2, "ring under capacity")
ring:append("c")
ring:append("d")
equal(table.concat(ring:snapshot(), ","), "b,c,d", "ring overwrite order")
equal(table.concat(ring:snapshot(true), ","), "d,c,b", "ring newest order")
local restored = RingBuffer.new(2)
restored:restore(ring:snapshot())
equal(table.concat(restored:snapshot(), ","), "c,d", "ring restore")
restored:clear()
equal(restored:count(), 0, "ring clear")

local Events = require "PsychopatzCore/Events/PC_EventBus"
local calls = {}
local function first(a, b) calls[#calls + 1] = a + b end
local function second(a, b) calls[#calls + 1] = a * b end
equal(Events.emit("smoke.none", 1), 0, "no listener emit")
equal(Events.subscribe("smoke.event", first), true, "subscribe")
Events.subscribe("smoke.event", second)
equal(Events.emit("smoke.event", 2, 3), 2, "multiple delivery")
equal(calls[1], 5, "event args")
equal(calls[2], 6, "second listener")
equal(Events.unsubscribe("smoke.event", first), true, "unsubscribe")
equal(Events.getListenerCount("smoke.event"), 1, "compact listener list")
Events.subscribe("smoke.safe", function() error("optional failure") end,
    "smoke.owner")
Events.subscribe("smoke.safe", function() calls[#calls + 1] = "safe" end,
    "smoke.owner")
equal(Events.emit("smoke.safe"), 1, "listener failure isolated")
equal(Events.clearOwner("smoke.owner"), 2, "owner listeners cleared")
equal(Events.hasSubscribers("smoke.safe"), false, "owner list compacted")

local Journals = require "PsychopatzCore/Journal/PC_JournalService"
Journals.registerType("smoke.ring", { storage = "boundedRing", capacity = 2 })
Journals.registerType("smoke.other", { storage = "ring", capacity = 3 })
equal(Journals.hasJournal("smoke.ring", "a"), false, "lazy registration")
Journals.append("smoke.ring", "a", "smoke.one", 1)
Journals.append("smoke.ring", "a", "smoke.two", 2)
Journals.append("smoke.ring", "a", "smoke.three", 3)
Journals.append("smoke.ring", "b", "smoke.subjectB", 4)
Journals.append("smoke.other", "a", "smoke.otherType", 5)
equal(#Journals.getRecent("smoke.ring", "a"), 2, "journal capacity")
equal(Journals.getRecent("smoke.ring", "a")[1][1], "smoke.two",
    "journal oldest retained")
equal(Journals.getRecent("smoke.ring", "b")[1][1], "smoke.subjectB",
    "subjects isolated")
equal(Journals.getRecent("smoke.other", "a")[1][1], "smoke.otherType",
    "types isolated")
local exported = Journals.export("smoke.ring", "a")
Journals.remove("smoke.ring", "a")
equal(Journals.hasJournal("smoke.ring", "a"), false, "journal remove")
local ok, count = Journals.import("smoke.ring", "a", exported)
equal(ok, true, "journal import")
equal(count, 2, "journal round trip count")
Journals.clear("smoke.ring", "a")
equal(#Journals.getRecent("smoke.ring", "a"), 0, "journal clear")

Journals.registerType("smoke.unique", { storage = "uniqueArchive" })
equal(Journals.append("smoke.unique", "a", "discover", "station.one"), true,
    "unique append")
equal(Journals.append("smoke.unique", "a", "discover", "station.one"), false,
    "unique duplicate")

print("psychopatz_event_journal_smoke: ok")
