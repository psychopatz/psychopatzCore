-- Smoke test for unified PsychopatzCore.WorldKnowledge conversation topics
-- and PsychopatzCore.WorldEventLocation relative spatial/time phrasing.
local root = "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua"
package.path = root .. ";" .. package.path

local Location = require "PsychopatzCore/WorldEvents/PsychopatzWorldEventLocation"
local WKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

local function assertEqual(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s: expected=%s actual=%s", msg, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTruthy(val, msg)
    if not val then error(msg .. ": expected truthy", 2) end
end

WKG.Reset()

-- 1. Relative time & compass direction on existing WorldEventLocation contract
assertEqual(Location.RelativeTime(22, 34), "last night", "previous night resolves to last night")
assertEqual(Location.RelativeTime(33, 34), "just a little while ago", "1h ago resolves to just a little while ago")
assertEqual(Location.RelativeDirection(100, 100, 50, 150), "southwest of here", "delta (-50,+50) is southwest in PZ coords")
assertEqual(
    Location.DescribeSpatial({ x = 50, y = 150, label = "Spiffo's" }, { x = 100, y = 100 }),
    "southwest of here, near Spiffo's",
    "spatial description combines compass direction and landmark"
)

-- 2. Single WorldKnowledge ledger feeds conversation topics (road story + 7d threat pattern + banter)
local f1 = WKG.Publish({
    id = "story:amb_1",
    kind = "discovery.vehicle_story.ambulance_crash",
    salience = 0.9,
    occurredAt = 22,
    location = { id = "loc:spiffo", kind = "local_area", name = "Spiffo's" },
    payload = { semanticType = "discovery.vehicle_story.ambulance_crash", storyLabel = "ambulance crash", x = 50, y = 150 },
})
assertTruthy(f1, "ambulance crash fact published to unified WorldKnowledge ledger")

local topics = WKG.QueryConversationTopics(nil, { x = 100, y = 100, worldHour = 34, worldDay = 1, identitySeed = 42 }, { limit = 2 })
assertEqual(#topics, 2, "returns world fact plus deterministic banter")
assertEqual(topics[1].topic, "medical_wreck", "maps discovery.vehicle_story.ambulance_crash to ConvoDSL medical_wreck")
assertEqual(topics[1].timeLabel, "last night", "computes relative time label")
assertEqual(topics[1].locationLabel, "southwest of here, near Spiffo's", "computes relative spatial label")
assertEqual(topics[2].source, "banter", "fills remaining slot with deterministic mundane banter")

-- 3. 7-day rolling threat pattern watcher over existing WorldKnowledge ledger (no extra ModData!)
for i = 1, 3 do
    WKG.Publish({
        id = "raid:" .. tostring(i),
        kind = "bandit_raid",
        salience = 0.85,
        occurredAt = 100 + i * 10,
        payload = { semanticType = "bandit_raid" },
    })
end
WKG.Publish({
    id = "chopper:1",
    kind = "world.helicopter_overflight",
    salience = 0.9,
    occurredAt = 125,
    payload = { semanticType = "world.helicopter_overflight" },
})
local threat = WKG.SummarizeRecentThreats({ worldHour = 140 })
assertTruthy(threat, "3 raids within 7d triggers rolling threat pattern")
assertEqual(threat.topic, "threat_pattern_7d", "threat pattern maps to ConvoDSL threat_pattern_7d")
assertEqual(threat.raidCount, 3, "counts 3 recent raids")
assertEqual(threat.chopperLinked, true, "detects chopper-linked raid surge")

-- 4. Bounded follow-up progression reaches clean closure
local step1 = WKG.AdvanceTopicFollowUp(topics[1], "where", 0)
assertEqual(step1.exhausted, false, "first follow-up is not exhausted")
local step2 = WKG.AdvanceTopicFollowUp(topics[1], "when", step1.nextDepth)
assertEqual(step2.exhausted, true, "second follow-up reaches bounded closure")

-- Regression: facts without headline/storyLabel must never leak raw dotted keys like "faction.incident".
local Topics = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledgeTopics"
local rawIncidentTopic = Topics.BuildFromFact({
    id = "fact:faction_incident_1",
    kind = "faction.incident",
    occurredAt = 119.5,
    payload = {},
}, { worldHour = 120 })
assertEqual(rawIncidentTopic.subjectLabel, "trouble between factions",
    "faction.incident humanizes subjectLabel instead of leaking raw fact kind")
assert(not string.find(rawIncidentTopic.subjectLabel, ".", 1, true),
    "subjectLabel must not contain raw dotted identifier")

print("psychopatz_world_knowledge_topics_smoke: ok")
