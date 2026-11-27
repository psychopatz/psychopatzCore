-- Unified conversation topic projection over PsychopatzCore.WorldKnowledge.
-- Consumes existing WorldKnowledge ledger & actor facts (populated by
-- PsychopatzVanillaDiscoveryAdapter, PsychopatzPZWorldEventAdapter, and
-- ScopedWorldEvents), aggregates 7-day rolling threat patterns, and supplies
-- deterministic identity-seeded mundane banter when no hotter fact applies.
-- Shared by ProjectHoomans and DynamicTrading (DTCommon/DTAbstract) with zero
-- duplicate ModData stores. Kahlua2-safe Lua 5.1.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.WorldKnowledge = PsychopatzCore.WorldKnowledge or {}

local Topics = {}

-- Resolve WorldEventLocation lazily from the shared namespace to avoid a
-- recursive require() cycle with PsychopatzVanillaEventObserver in Kahlua2.
local function getLocation()
    return PsychopatzCore and PsychopatzCore.WorldEventLocation or nil
end

local ROLLING_THREAT_HOURS = 168 -- 7 in-game days
local DEFAULT_MAX_DEPTH = 2

-- Map canonical WorldKnowledge fact kinds / semanticTypes to ConvoDSL topic IDs.
local SEMANTIC_TO_TOPIC = {
    ["discovery.vehicle_story.ambulance_crash"] = "medical_wreck",
    ["discovery.vehicle_story.police_blockade"] = "police_blockade",
    ["discovery.vehicle_story.bandit_road"] = "bandit_activity",
    ["discovery.vehicle_story.crash_horde"] = "horde_sighting",
    ["world.helicopter_overflight"] = "helicopter_event",
    ["utility.electricity_cutoff"] = "aebs_utilities",
    ["utility.water_cutoff"] = "aebs_utilities",
    ["radio.aebs_air_activity"] = "aebs_air_activity",
    ["radio.aebs_power_warning"] = "aebs_power_warning",
    ["radio.aebs_weather_warning"] = "aebs_weather_warning",
    ["radio.aebs_utilities"] = "aebs_utilities",
    ["radio.military_comms"] = "military_comms",
    ["radio.survivor_radio"] = "survivor_radio",
    ["radio.news_outbreak"] = "news_outbreak",
    ["radio.news_general"] = "news_general",
    ["radio.skill_show"] = "skill_show",
    ["radio.home_vhs"] = "home_vhs",
    ["radio.music_radio"] = "music_radio",
    ["radio.entertainment_tv"] = "entertainment_tv",
    ["radio.open_band_looter_trap"] = "open_band_looter_trap",
    ["radio.open_band_trader"] = "open_band_trader",
    ["radio.open_band_refugee"] = "open_band_refugee",
    ["radio.open_band_settlement"] = "open_band_settlement",
    ["radio.open_band_conflict"] = "open_band_conflict",
    ["radio.numbers_station"] = "numbers_station",
    ["radio.cannibal_radio"] = "cannibal_radio",
    ["radio.pastor_radio"] = "pastor_radio",
    ["radio.broadcast"] = "radio_broadcast",
    ["meta.gunshot"] = "meta_gunshot",
    ["meta.scream"] = "meta_scream",
}

local THREAT_KINDS = {
    ["raid"] = true,
    ["bandit_raid"] = true,
    ["settlement_raid"] = true,
    ["discovery.vehicle_story.bandit_road"] = true,
    ["discovery.vehicle_story.police_blockade"] = true,
    ["discovery.vehicle_story.crash_horde"] = true,
    ["world.raider_surge"] = true,
}

local MUNDANE_BANTER = {
    { topic = "banter_sunset", subjectLabel = "the sunset", maxDepth = 1 },
    { topic = "banter_coffee", subjectLabel = "real coffee", maxDepth = 1 },
    { topic = "banter_belief", subjectLabel = "getting through this", maxDepth = 1 },
    { topic = "banter_quiet", subjectLabel = "ordinary noise", maxDepth = 1 },
    { topic = "banter_music", subjectLabel = "old music", maxDepth = 1 },
    { topic = "banter_home", subjectLabel = "home", maxDepth = 1 },
}

local function deterministicHash(seed)
    local s = tostring(seed or "0")
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + string.byte(s, i)) % 2147483647
    end
    return h
end

local function factTimestamp(fact)
    if type(fact) ~= "table" then return nil end
    return tonumber(
        fact.occurredAt or fact.observedAt or fact.updatedAt
        or fact.createdAt or fact.timestamp
        or (fact.payload and fact.payload.worldHour)
    )
end

local function mapFactTopic(fact)
    local payload = type(fact.payload) == "table" and fact.payload or {}
    local sem = tostring(payload.semanticType or fact.kind or "")
    if SEMANTIC_TO_TOPIC[sem] then return SEMANTIC_TO_TOPIC[sem] end
    if string.find(sem, "ambulance", 1, true) then return "medical_wreck" end
    if string.find(sem, "police", 1, true) then return "police_blockade" end
    if string.find(sem, "bandit", 1, true) or string.find(sem, "raid", 1, true) then return "bandit_activity" end
    if string.find(sem, "horde", 1, true) then return "horde_sighting" end
    if string.find(sem, "helicopter", 1, true) or string.find(sem, "chopper", 1, true) then return "helicopter_event" end
    if string.find(sem, "radio", 1, true) or fact.provenance == "radio" then return "radio_broadcast" end
    if string.find(sem, "gunshot", 1, true) then return "meta_gunshot" end
    if string.find(sem, "scream", 1, true) then return "meta_scream" end
    return sem ~= "" and sem or "world_event"
end

function Topics.SummarizeRecentThreats(ledgerState, opts)
    opts = type(opts) == "table" and opts or {}
    local nowHour = tonumber(opts.worldHour) or 0
    local windowHours = tonumber(opts.windowHours) or ROLLING_THREAT_HOURS
    local minCount = tonumber(opts.minCount) or 3
    local facts = type(ledgerState) == "table" and ledgerState.facts or nil
    if type(facts) ~= "table" then return nil end

    local count = 0
    local latestHour = nil
    local chopperSeen = false
    for _, fact in pairs(facts) do
        if type(fact) == "table" and fact.expired ~= true then
            local ts = factTimestamp(fact)
            if not ts or nowHour == 0 or (nowHour - ts) <= windowHours then
                local payload = type(fact.payload) == "table" and fact.payload or {}
                local sem = tostring(payload.semanticType or fact.kind or "")
                if sem == "world.helicopter_overflight" or string.find(sem, "chopper", 1, true) then
                    chopperSeen = true
                end
                if THREAT_KINDS[sem] or THREAT_KINDS[tostring(fact.kind or "")] then
                    count = count + 1
                    if ts and (latestHour == nil or ts > latestHour) then
                        latestHour = ts
                    end
                end
            end
        end
    end
    if count < minCount then return nil end
    local locApi = getLocation()
    return {
        id = "threat_pattern_7d:" .. tostring(count),
        topic = "threat_pattern_7d",
        source = "world_knowledge",
        subjectLabel = "recent raids",
        timeLabel = (locApi and type(locApi.RelativeTime) == "function")
            and locApi.RelativeTime(latestHour or nowHour, nowHour) or "recently",
        locationLabel = "around here",
        headline = "",
        raidCount = count,
        chopperLinked = chopperSeen,
        maxDepth = DEFAULT_MAX_DEPTH,
        meta = { count = count, chopperLinked = chopperSeen },
    }
end

local TOPIC_SUBJECT_LABELS = {
    ["faction.incident"] = "trouble between factions",
    ["faction.status"] = "a shift in faction standings",
    ["zombie.pressure"] = "heavy zombie movement",
    ["npc.death"] = "someone getting killed out there",
    ["actor.milestone"] = "a survival milestone",
    ["world.event"] = "trouble on the road",
    ["world.state"] = "changing conditions",
    ["utility.state"] = "the utilities",
    ["medical_wreck"] = "a wrecked ambulance",
    ["police_blockade"] = "a police blockade",
    ["bandit_activity"] = "bandit activity",
    ["horde_sighting"] = "a large horde",
    ["helicopter_event"] = "a helicopter overhead",
    ["aebs_utilities"] = "the power and water",
    ["aebs_air_activity"] = "air activity on the emergency band",
    ["aebs_power_warning"] = "a power grid warning",
    ["aebs_weather_warning"] = "rough weather coming in",
    ["military_comms"] = "military chatter on the radio",
    ["survivor_radio"] = "survivors on the radio",
    ["news_outbreak"] = "outbreak news on the radio",
    ["news_general"] = "news on the radio",
    ["radio_broadcast"] = "a radio broadcast",
    ["meta_gunshot"] = "gunshots",
    ["meta_scream"] = "screams",
    ["world_event"] = "trouble on the road",
}

local function humanizeSubject(rawLabel, topicID, factKind)
    local text = type(rawLabel) == "string" and (rawLabel:gsub("^%s+", ""):gsub("%s+$", "")) or ""
    if text ~= "" and TOPIC_SUBJECT_LABELS[text] then
        return TOPIC_SUBJECT_LABELS[text]
    end
    -- Reject raw internal dotted/underscored identifiers (e.g. "faction.incident").
    if text ~= "" and not string.find(text, "^[%w_]+%.[%w_.]+$") and not string.find(text, "^[%l%d]+_[%l%d_]+$") then
        return text
    end
    local tid = tostring(topicID or "")
    local fkind = tostring(factKind or "")
    if TOPIC_SUBJECT_LABELS[tid] then return TOPIC_SUBJECT_LABELS[tid] end
    if TOPIC_SUBJECT_LABELS[fkind] then return TOPIC_SUBJECT_LABELS[fkind] end
    local fallback = tid ~= "" and tid or fkind
    if fallback ~= "" then
        local cleaned = string.gsub(fallback, "[%._]+", " ")
        cleaned = (cleaned:gsub("^%s+", ""):gsub("%s+$", ""))
        if cleaned ~= "" then return cleaned end
    end
    return "trouble on the road"
end

function Topics.BuildFromFact(fact, observer)
    if type(fact) ~= "table" then return nil end
    observer = type(observer) == "table" and observer or {}
    local payload = type(fact.payload) == "table" and fact.payload or {}
    local nowHour = tonumber(observer.worldHour)
    local evHour = factTimestamp(fact)
    local topicID = mapFactTopic(fact)
    local loc = type(fact.location) == "table" and fact.location or {}
    local spatialLoc = {
        x = loc.x or payload.x,
        y = loc.y or payload.y,
        label = loc.label or loc.name or payload.locationLabel or loc.settlementID or loc.region,
    }
    local locApi = getLocation()
    local rawHeadline = payload.headline or payload.storyLabel or payload.summary or payload.label or payload.text or ""
    local subjectLabel = humanizeSubject(payload.storyLabel or payload.headline or payload.summary or payload.label, topicID, fact.kind)
    return {
        id = tostring(fact.id or topicID),
        factID = fact.id,
        topic = topicID,
        source = "world_knowledge",
        subjectLabel = subjectLabel,
        timeLabel = (locApi and type(locApi.RelativeTime) == "function")
            and locApi.RelativeTime(evHour, nowHour) or "recently",
        locationLabel = (locApi and type(locApi.DescribeSpatial) == "function")
            and locApi.DescribeSpatial(spatialLoc, observer) or "nearby",
        headline = type(rawHeadline) == "string" and rawHeadline or "",
        raidCount = tonumber(payload.raidCount) or 0,
        chopperLinked = payload.chopperLinked == true,
        maxDepth = (fact.provenance == "radio" or payload.theme ~= nil) and 3 or DEFAULT_MAX_DEPTH,
        salience = tonumber(fact.salience) or 0.5,
        timestamp = evHour or 0,
        meta = {
            channelName = payload.channelName,
            showName = payload.showName,
            episode = payload.headline or payload.storyLabel,
            topicLabel = payload.topicLabel or payload.storyLabel,
            theme = payload.theme,
        },
    }
end

function Topics.PickBanter(observer)
    observer = type(observer) == "table" and observer or {}
    local seed = tostring(observer.identitySeed or observer.npcID or observer.actorID or "0")
        .. ":" .. tostring(observer.worldDay or 0)
    local idx = (deterministicHash(seed) % #MUNDANE_BANTER) + 1
    local entry = MUNDANE_BANTER[idx]
    return {
        id = "banter:" .. entry.topic,
        topic = entry.topic,
        source = "banter",
        subjectLabel = entry.subjectLabel,
        timeLabel = "lately",
        locationLabel = "around here",
        headline = "",
        raidCount = 0,
        chopperLinked = false,
        maxDepth = entry.maxDepth or 1,
        salience = 0.2,
        timestamp = tonumber(observer.worldHour) or 0,
    }
end

function Topics.Query(wkg, actorID, observer, opts)
    opts = type(opts) == "table" and opts or {}
    observer = type(observer) == "table" and observer or {}
    local limit = math.max(1, math.min(tonumber(opts.limit) or 3, 8))
    local results = {}
    local seen = {}

    -- 1. Rolling 7-day threat pattern from the single WorldKnowledge ledger.
    local threat = Topics.SummarizeRecentThreats(wkg and wkg.LedgerState, {
        worldHour = observer.worldHour,
    })
    if threat then
        results[#results + 1] = threat
        seen[threat.topic] = true
    end

    -- 2. Existing WorldKnowledge actor facts (if actorID known), else recent ledger facts.
    local candidates = {}
    if wkg and actorID and type(wkg.Context) == "function" then
        local ctx = wkg.Context(actorID, {
            now = observer.worldHour,
            limit = limit + 2,
        })
        if type(ctx) == "table" and type(ctx.facts) == "table" then
            for i = 1, #ctx.facts do
                local item = ctx.facts[i]
                if type(item) == "table" and type(item.fact) == "table" then
                    candidates[#candidates + 1] = item.fact
                end
            end
        end
    end
    if #candidates == 0 and wkg and type(wkg.LedgerState) == "table"
        and type(wkg.LedgerState.facts) == "table"
    then
        for _, fact in pairs(wkg.LedgerState.facts) do
            if type(fact) == "table" and fact.expired ~= true then
                candidates[#candidates + 1] = fact
            end
        end
        table.sort(candidates, function(a, b)
            local sa = tonumber(a.salience) or 0
            local sb = tonumber(b.salience) or 0
            if sa ~= sb then return sa > sb end
            return (factTimestamp(a) or 0) > (factTimestamp(b) or 0)
        end)
    end

    for i = 1, #candidates do
        if #results >= limit then break end
        local built = Topics.BuildFromFact(candidates[i], observer)
        if built and not seen[built.id] then
            seen[built.id] = true
            results[#results + 1] = built
        end
    end

    -- 3. Deterministic identity-seeded mundane banter fallback so every actor
    -- always has a grounded conversation starter.
    if #results < limit and opts.includeBanter ~= false then
        results[#results + 1] = Topics.PickBanter(observer)
    end

    return results
end

function Topics.AdvanceFollowUp(topic, kind, depth)
    if type(topic) ~= "table" then return nil end
    local cur = tonumber(depth) or 0
    local maxDepth = tonumber(topic.maxDepth) or DEFAULT_MAX_DEPTH
    local nextDepth = cur + 1
    return {
        kind = tostring(kind or "more"),
        nextDepth = nextDepth,
        exhausted = nextDepth >= maxDepth,
    }
end

return Topics
