-- Zero-scan randomized-world discovery adapter for PsychopatzCore.
-- Captures authoritative metadata on chunk/vehicle/room load into a bounded
-- pending buffer and promotes stories to WorldKnowledge ONLY when discovered.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero world scans.

local Observer = require "PsychopatzCore/WorldEvents/PsychopatzVanillaEventObserver"
local Location = require "PsychopatzCore/WorldEvents/PsychopatzWorldEventLocation"
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

PsychopatzCore = PsychopatzCore or {}
local Discovery = PsychopatzCore.VanillaDiscoveryAdapter or {}
PsychopatzCore.VanillaDiscoveryAdapter = Discovery

Discovery.SCHEMA = "PsychopatzCore.VanillaDiscoveryAdapter"
Discovery.SCHEMA_VERSION = 1
Discovery.MAX_PENDING_SITES = 64
Discovery.MAX_ROOM_SQUARES = 64
Discovery.DEFAULT_DISCOVERY_RADIUS = 75

local VEHICLE_STORY_SPECS = {
    RVSAmbulanceCrash = { semanticType = "discovery.vehicle_story.ambulance_crash", label = "ambulance crash", severity = 0.70, salience = 0.90, effects = { medicalDemand = 0.20, travelRisk = 0.15 } },
    RVSBanditRoad = { semanticType = "discovery.vehicle_story.bandit_road", label = "bandit road ambush", severity = 0.80, salience = 0.90, effects = { caravanRisk = 0.35, travelRisk = 0.35, hostileActivityMultiplier = 1.35 } },
    RVSPoliceBlockade = { semanticType = "discovery.vehicle_story.police_blockade", label = "police roadblock", severity = 0.65, salience = 0.85, effects = { travelRisk = 0.25, caravanRisk = 0.20 } },
    RVSPoliceBlockadeShooting = { semanticType = "discovery.vehicle_story.police_blockade", label = "police shootout blockade", severity = 0.80, salience = 0.90, effects = { travelRisk = 0.35, caravanRisk = 0.30, hostileActivityMultiplier = 1.25 } },
    RVSCrashHorde = { semanticType = "discovery.vehicle_story.crash_horde", label = "wrecked car surrounded by horde", severity = 0.75, salience = 0.85, effects = { travelRisk = 0.30, caravanRisk = 0.25 } },
    RVSBurntCar = { semanticType = "discovery.vehicle_story.burnt_vehicles", label = "burnt roadside wrecks", severity = 0.35, salience = 0.50 },
    RVSCarCrash = { semanticType = "discovery.vehicle_story.road_crash", label = "roadside car crash", severity = 0.45, salience = 0.60, effects = { travelRisk = 0.10 } },
    RVSCarCrashCorpse = { semanticType = "discovery.vehicle_story.road_crash", label = "fatal car crash", severity = 0.55, salience = 0.65, effects = { travelRisk = 0.10 } },
    RVSCarCrashDeer = { semanticType = "discovery.vehicle_story.road_crash", label = "animal-collision crash", severity = 0.45, salience = 0.60 },
    RVSFlippedCrash = { semanticType = "discovery.vehicle_story.road_crash", label = "overturned wreck", severity = 0.55, salience = 0.65, effects = { travelRisk = 0.15 } },
    RVSTrailerCrash = { semanticType = "discovery.vehicle_story.road_crash", label = "jackknifed trailer crash", severity = 0.55, salience = 0.70, effects = { travelRisk = 0.15 } },
    RVSChangingTire = { semanticType = "discovery.vehicle_story.road_breakdown", label = "abandoned roadside breakdown", severity = 0.35, salience = 0.55 },
    RVSConstructionSite = { semanticType = "discovery.vehicle_story.utility_worksite", label = "abandoned roadworks site", severity = 0.35, salience = 0.60 },
    RVSUtilityVehicle = { semanticType = "discovery.vehicle_story.utility_worksite", label = "utility truck on the road", severity = 0.35, salience = 0.60 },
    RVSRegionalProfessionVehicle = { semanticType = "discovery.vehicle_story.utility_worksite", label = "regional work vehicle", severity = 0.35, salience = 0.60 },
    RVSDeadEnd = { semanticType = "discovery.vehicle_story.road_blockage", label = "blocked dead-end pileup", severity = 0.60, salience = 0.75, effects = { travelRisk = 0.25, caravanRisk = 0.20 } },
    RVSPlonkies = { semanticType = "discovery.vehicle_story.supply_vehicle", label = "stranded supply van", severity = 0.35, salience = 0.65 },
    RVSAnimalOnRoad = { semanticType = "discovery.vehicle_story.road_livestock", label = "stray livestock on the road", severity = 0.30, salience = 0.55 },
    RVSAnimalTrailerOnRoad = { semanticType = "discovery.vehicle_story.road_livestock", label = "abandoned livestock trailer", severity = 0.35, salience = 0.65 },
    RVSHerdOnRoad = { semanticType = "discovery.vehicle_story.road_livestock", label = "wandering roadside herd", severity = 0.35, salience = 0.65 },
    RVSRichJerk = { semanticType = "discovery.vehicle_story.stranded_vehicle", label = "abandoned luxury car", severity = 0.25, salience = 0.45 },
    RVSRoadKill = { semanticType = "discovery.vehicle_story.roadkill", label = "roadkill carcass", severity = 0.20, salience = 0.40 },
    RVSRoadKillSmall = { semanticType = "discovery.vehicle_story.roadkill", label = "small roadkill carcass", severity = 0.15, salience = 0.35 },
}

local VEHICLE_NAME_ALIASES = {
    ["ambulance crash"] = "RVSAmbulanceCrash",
    ["bandits on road"] = "RVSBanditRoad",
    ["police blockade"] = "RVSPoliceBlockade",
    ["police blockade shooting"] = "RVSPoliceBlockadeShooting",
    ["crash horde"] = "RVSCrashHorde",
    ["burnt car"] = "RVSBurntCar",
    ["basic car crash"] = "RVSCarCrash",
    ["basic car crash corpse"] = "RVSCarCrashCorpse",
    ["car crash deer"] = "RVSCarCrashDeer",
    ["flipped crash"] = "RVSFlippedCrash",
    ["trailer crash"] = "RVSTrailerCrash",
    ["changing tire"] = "RVSChangingTire",
    ["construction site"] = "RVSConstructionSite",
    ["utility vehicle"] = "RVSUtilityVehicle",
    ["dead end"] = "RVSDeadEnd",
    ["plonkies"] = "RVSPlonkies",
    ["animal on road"] = "RVSAnimalOnRoad",
    ["livestock trailer on road"] = "RVSAnimalTrailerOnRoad",
    ["herd on road"] = "RVSHerdOnRoad",
    ["rich jerk"] = "RVSRichJerk",
    ["roadkill - large farm animal struck by vehicle"] = "RVSRoadKill",
    ["roadkill - small animal run over by vehicle"] = "RVSRoadKillSmall",
}

local ZONE_STORY_SPECS = {
    RZSMurderScene = { semanticType = "discovery.zone_story.murder_scene", label = "murder scene", severity = 0.60, salience = 0.80, effects = { travelRisk = 0.15 } },
    RZSSurvivalistCamp = { semanticType = "discovery.zone_story.survivalist_camp", label = "survivalist campsite", severity = 0.40, salience = 0.75 },
    RZSHunterCamp = { semanticType = "discovery.zone_story.hunter_camp", label = "hunter camp", severity = 0.40, salience = 0.70 },
    RZSTrapperCamp = { semanticType = "discovery.zone_story.hunter_camp", label = "trapper forest camp", severity = 0.35, salience = 0.65 },
    RZSCampsite = { semanticType = "discovery.zone_story.campsite", label = "abandoned campsite", severity = 0.30, salience = 0.55 },
    RZSForestCamp = { semanticType = "discovery.zone_story.campsite", label = "forest camp", severity = 0.30, salience = 0.55 },
    RZSVanCamp = { semanticType = "discovery.zone_story.campsite", label = "camped van site", severity = 0.35, salience = 0.60 },
    RZSOldFirepit = { semanticType = "discovery.zone_story.campsite", label = "old firepit camp", severity = 0.25, salience = 0.50 },
    RZSForestCampEaten = { semanticType = "discovery.zone_story.overrun_camp", label = "overrun forest camp", severity = 0.55, salience = 0.75, effects = { travelRisk = 0.15 } },
    RZSSadCamp = { semanticType = "discovery.zone_story.overrun_camp", label = "abandoned camp with corpses", severity = 0.50, salience = 0.70 },
    RZSBuryingCamp = { semanticType = "discovery.zone_story.grave_site", label = "shallow grave site", severity = 0.45, salience = 0.65 },
    RZSTragicPicnic = { semanticType = "discovery.zone_story.tragic_scene", label = "overrun picnic site", severity = 0.45, salience = 0.65 },
    RZSWaterPump = { semanticType = "discovery.zone_story.water_pump_site", label = "field water pump site", severity = 0.30, salience = 0.65 },
    RZSAttachedAnimal = { semanticType = "discovery.zone_story.animal_site", label = "tethered livestock", severity = 0.25, salience = 0.65 },
    RZSEscapedAnimal = { semanticType = "discovery.zone_story.animal_site", label = "stray livestock", severity = 0.25, salience = 0.60 },
    RZSEscapedHerd = { semanticType = "discovery.zone_story.animal_site", label = "escaped herd", severity = 0.30, salience = 0.70 },
    RZSOrphanedFawn = { semanticType = "discovery.zone_story.animal_site", label = "orphaned fawn", severity = 0.20, salience = 0.50 },
    RZSHogWild = { semanticType = "discovery.zone_story.animal_site", label = "wild hog site", severity = 0.30, salience = 0.55 },
    RZSBurntWreck = { semanticType = "discovery.zone_story.burnt_wreck", label = "burnt wreck", severity = 0.30, salience = 0.50 },
    RZSWasteDump = { semanticType = "discovery.zone_story.waste_dump", label = "dumped waste site", severity = 0.25, salience = 0.45 },
    RZSOccultActivity = { semanticType = "discovery.zone_story.occult_scene", label = "ritual site", severity = 0.45, salience = 0.70 },
    RZSCharcoalBurner = { semanticType = "discovery.zone_story.work_site", label = "charcoal burner camp", severity = 0.25, salience = 0.55 },
    RZSOldShelter = { semanticType = "discovery.zone_story.old_shelter", label = "old woodland shelter", severity = 0.30, salience = 0.60 },
    RZSHermitCamp = { semanticType = "discovery.zone_story.hermit_camp", label = "hermit shelter", severity = 0.30, salience = 0.60 },
}

local ZONE_NAME_ALIASES = {
    ["murder scene"] = "RZSMurderScene",
    ["survivalist campsite"] = "RZSSurvivalistCamp",
    ["hunter forest camp"] = "RZSHunterCamp",
    ["trappers forest camp"] = "RZSTrapperCamp",
    ["campsite"] = "RZSCampsite",
    ["basic forest camp"] = "RZSForestCamp",
    ["van camp"] = "RZSVanCamp",
    ["old firepit"] = "RZSOldFirepit",
    ["forest camp eaten"] = "RZSForestCampEaten",
    ["sad campsite"] = "RZSSadCamp",
    ["burying camp"] = "RZSBuryingCamp",
    ["tragic picnic"] = "RZSTragicPicnic",
    ["water pump"] = "RZSWaterPump",
    ["attached animal"] = "RZSAttachedAnimal",
    ["escaped animal"] = "RZSEscapedAnimal",
    ["escaped herd"] = "RZSEscapedHerd",
    ["orphaned fawn"] = "RZSOrphanedFawn",
    ["hog wild"] = "RZSHogWild",
    ["burnt wreck"] = "RZSBurntWreck",
    ["waste dump"] = "RZSWasteDump",
    ["occult activity"] = "RZSOccultActivity",
    ["charcoal burner"] = "RZSCharcoalBurner",
    ["oldshelter"] = "RZSOldShelter",
    ["hermit campsite"] = "RZSHermitCamp",
}

local function finite(value, fallback)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return fallback
    end
    return num
end

local function objOrNil(value)
    local kind = type(value)
    if kind == "table" or kind == "userdata" then return value end
    return nil
end

local function allowed(opts)
    if type(opts) == "table" and opts.force == true then return true end
    if RuntimeRole and type(RuntimeRole.AllowsServerCode) == "function" then
        return RuntimeRole.AllowsServerCode()
    end
    return true
end

local function worldHours(opts)
    if type(opts) == "table" and finite(opts.nowHours, nil) ~= nil then
        return math.max(0, finite(opts.nowHours, 0))
    end
    if type(getGameTime) == "function" then
        local gt = objOrNil(getGameTime())
        if gt and type(gt.getWorldAgeHours) == "function" then
            return math.max(0, finite(gt:getWorldAgeHours(), 0))
        end
    end
    return 0
end

local function cleanKey(value)
    local s = string.gsub(tostring(value or ""), "[^%w_%-]", "_")
    if s == "" then s = "site" end
    return string.sub(s, 1, 48)
end

local function areaCellKey(x, y)
    local bx, by = Location.QuantizeArea(x, y)
    if bx == nil or by == nil then return nil end
    return "area:" .. tostring(bx) .. "_" .. tostring(by)
end

Discovery._pendingSites = Discovery._pendingSites or {}
Discovery._pendingOrder = Discovery._pendingOrder or {}

function Discovery.Reset()
    Discovery._pendingSites = {}
    Discovery._pendingOrder = {}
end

function Discovery.ResolveVehicleStorySpec(rawName)
    local text = tostring(rawName or "")
    if VEHICLE_STORY_SPECS[text] then
        return text, VEHICLE_STORY_SPECS[text]
    end
    local canonical = VEHICLE_NAME_ALIASES[string.lower(text)]
    if canonical and VEHICLE_STORY_SPECS[canonical] then
        return canonical, VEHICLE_STORY_SPECS[canonical]
    end
    if string.find(string.lower(text), "ambulance", 1, true) then
        return "RVSAmbulanceCrash", VEHICLE_STORY_SPECS.RVSAmbulanceCrash
    end
    if string.find(string.lower(text), "bandit", 1, true) then
        return "RVSBanditRoad", VEHICLE_STORY_SPECS.RVSBanditRoad
    end
    if string.find(string.lower(text), "police", 1, true) then
        return "RVSPoliceBlockade", VEHICLE_STORY_SPECS.RVSPoliceBlockade
    end
    return nil, {
        semanticType = "discovery.vehicle_story.road_scene",
        label = "road vehicle scene",
        severity = 0.40,
        salience = 0.55,
    }
end

function Discovery.ResolveZoneStorySpec(rawName)
    local text = tostring(rawName or "")
    if ZONE_STORY_SPECS[text] then
        return text, ZONE_STORY_SPECS[text]
    end
    local canonical = ZONE_NAME_ALIASES[string.lower(text)]
    if canonical and ZONE_STORY_SPECS[canonical] then
        return canonical, ZONE_STORY_SPECS[canonical]
    end
    if string.find(text, "Regional Profession Vehicle", 1, true) then
        return nil, nil
    end
    return nil, {
        semanticType = "discovery.zone_story.zone_scene",
        label = "outdoor story site",
        severity = 0.35,
        salience = 0.55,
    }
end

function Discovery.RecordPendingSite(spec)
    if type(spec) ~= "table" then return nil end
    local x, y = finite(spec.x, nil), finite(spec.y, nil)
    if x == nil or y == nil then return nil end
    local ak = areaCellKey(x, y)
    if not ak then return nil end
    local id = tostring(spec.kind or "story") .. ":" .. cleanKey(spec.storyID or spec.semanticType) .. ":" .. ak
    if not Discovery._pendingSites[id] then
        Discovery._pendingOrder[#Discovery._pendingOrder + 1] = id
        while #Discovery._pendingOrder > Discovery.MAX_PENDING_SITES do
            local evicted = table.remove(Discovery._pendingOrder, 1)
            if evicted then Discovery._pendingSites[evicted] = nil end
        end
    end
    Discovery._pendingSites[id] = {
        id = id,
        kind = spec.kind,
        storyID = spec.storyID,
        semanticType = spec.semanticType,
        label = spec.label,
        x = math.floor(x),
        y = math.floor(y),
        z = math.floor(finite(spec.z, 0) or 0),
        severity = spec.severity,
        salience = spec.salience,
        effects = spec.effects,
        animalType = spec.animalType,
    }
    return id
end

local function publishDiscovery(input, x, y, z, opts)
    opts = type(opts) == "table" and opts or {}
    local now = worldHours(opts)
    local locRef, locErr = Location.Resolve(x, y, z or 0, opts)
    if not locRef then return nil, locErr end
    local ak = locRef.localAreaID or ("area:" .. tostring(math.floor(x)) .. "_" .. tostring(math.floor(y)))
    local fp = "disc:" .. cleanKey(input.semanticType) .. ":" .. cleanKey(ak)
    local factID = "fact:core:" .. input.semanticType .. ":" .. ak

    return Observer.Observe({
        eventID = "core:disc:" .. cleanKey(input.semanticType) .. ":" .. ak,
        factID = factID,
        semanticType = input.semanticType,
        factKind = input.semanticType,
        sourceKind = input.sourceKind or "randomized_story",
        vanillaSourceID = input.vanillaSourceID or "observable_scene",
        phase = "discovery",
        retention = "historical",
        provenance = opts.provenance or "witnessed",
        preferredScope = "local_area",
        locationRef = locRef,
        occurredAt = now,
        observedAt = now,
        durationHours = input.durationHours or 72,
        factTTLHours = input.factTTLHours or 168,
        fingerprint = fp,
        severity = input.severity or 0.50,
        salience = input.salience or 0.75,
        subject = { id = "site:" .. ak, kind = "local_area", name = input.label },
        effects = input.effects,
        metadata = {
            storyLabel = input.label,
            x = math.floor(x),
            y = math.floor(y),
        },
        payload = {
            storyLabel = input.label,
            animalType = input.animalType,
            x = math.floor(x),
            y = math.floor(y),
        },
    }, opts)
end

function Discovery.DiscoverVehicleStory(rawStoryName, x, y, opts)
    if not allowed(opts) then return nil, "server_authority_required" end
    local nx, ny = finite(x, nil), finite(y, nil)
    if nx == nil or ny == nil then return nil, "discovery_coordinates_required" end
    local canonicalID, spec = Discovery.ResolveVehicleStorySpec(rawStoryName)
    return publishDiscovery({
        semanticType = spec.semanticType,
        sourceKind = "randomized_vehicle_story",
        vanillaSourceID = canonicalID or tostring(rawStoryName or "observable_vehicle_scene"),
        label = spec.label,
        severity = spec.severity,
        salience = spec.salience,
        effects = spec.effects,
    }, nx, ny, 0, opts)
end

function Discovery.DiscoverZoneStory(rawStoryName, x, y, opts)
    if not allowed(opts) then return nil, "server_authority_required" end
    local nx, ny = finite(x, nil), finite(y, nil)
    if nx == nil or ny == nil then return nil, "discovery_coordinates_required" end
    local canonicalID, spec = Discovery.ResolveZoneStorySpec(rawStoryName)
    if not spec then return nil, "unsupported_zone_story" end
    return publishDiscovery({
        semanticType = spec.semanticType,
        sourceKind = "randomized_zone_story",
        vanillaSourceID = canonicalID or tostring(rawStoryName or "observable_zone_scene"),
        label = spec.label,
        severity = spec.severity,
        salience = spec.salience,
        effects = spec.effects,
    }, nx, ny, 0, opts)
end

function Discovery.DiscoverRanch(animalTypeOrName, x, y, opts)
    if not allowed(opts) then return nil, "server_authority_required" end
    local nx, ny = finite(x, nil), finite(y, nil)
    if nx == nil or ny == nil then return nil, "discovery_coordinates_required" end
    local animal = tostring(animalTypeOrName or "livestock")
    return publishDiscovery({
        semanticType = "discovery.ranch_livestock",
        sourceKind = "randomized_ranch",
        vanillaSourceID = "RandomizedRanchBase",
        label = "livestock ranch (" .. animal .. ")",
        animalType = animal,
        severity = 0.30,
        salience = 0.70,
        effects = { foodAvailabilityPressure = -0.10 },
    }, nx, ny, 0, opts)
end

function Discovery.ClassifyRoomObservation(obs)
    if type(obs) ~= "table" then return nil end
    local room = string.lower(tostring(obs.roomName or ""))
    local barricades = tonumber(obs.barricadeCount) or 0
    local burnt = tonumber(obs.burntTileCount) or 0
    local bodies = tonumber(obs.deadBodyCount) or 0
    local weaponBags = tonumber(obs.weaponBagCount) or 0
    local medBags = tonumber(obs.medBagCount) or 0
    local survivorBags = tonumber(obs.survivorBagCount) or 0
    local rats = tonumber(obs.ratCount) or 0
    local bandits = tonumber(obs.banditCount) or 0
    local police = tonumber(obs.policeCount) or 0
    local smashed = tonumber(obs.smashedWindowCount) or 0
    local suicideClues = obs.hasSuicideClues == true
    local zombiesEating = obs.hasZombiesEating == true

    if string.find(room, "gunstore", 1, true) and (barricades > 0 or weaponBags > 0 or bodies >= 2) then
        return "discovery.building_scene.gunstore_siege", "sieged gunstore", 0.70, { travelRisk = 0.20 }
    elseif (string.find(room, "police", 1, true) or string.find(room, "armory", 1, true))
        and (barricades > 0 or bodies >= 2 or police >= 2)
    then
        return "discovery.building_scene.police_siege", "sieged police station", 0.70, { travelRisk = 0.20 }
    elseif string.find(room, "clinic", 1, true) or string.find(room, "doctor", 1, true) then
        if medBags > 0 or bodies >= 1 or barricades > 0 then
            return "discovery.building_scene.clinic_medical", "abandoned medical clinic scene", 0.50, { medicalDemand = -0.10 }
        end
    end

    if burnt >= 4 then
        return "discovery.building_scene.burnt_structure", "fire-gutted building", 0.50, nil
    end
    if barricades >= 2 and (survivorBags > 0 or weaponBags > 0) then
        return "discovery.building_scene.safehouse", "barricaded survivor safehouse", 0.45, nil
    end
    if bandits >= 2 and bodies >= 1 then
        return "discovery.dead_survivor.bandit_raid", "bandit-raided house", 0.75, { caravanRisk = 0.25, travelRisk = 0.25 }
    end
    if police >= 2 and bodies >= 1 then
        return "discovery.dead_survivor.police_incident", "police response scene at house", 0.55, nil
    end
    if suicideClues and bodies >= 1 then
        return "discovery.dead_survivor.suicide_pact", "grim survivor death scene", 0.50, nil
    end
    if zombiesEating and bodies >= 1 then
        return "discovery.dead_survivor.zombies_eating", "zombies feeding on survivors indoors", 0.65, { travelRisk = 0.15 }
    end
    if rats >= 3 then
        return "discovery.dead_survivor.rat_infestation", "rat-infested interior", 0.40, nil
    end
    if smashed >= 2 and bodies == 0 then
        return "discovery.building_scene.looted_structure", "ransacked building", 0.35, nil
    end
    if bodies >= 2 then
        return "discovery.dead_survivor.corpse_scene", "scene with fallen survivors", 0.55, nil
    end
    return nil
end

function Discovery.InspectRoomObservation(obs, opts)
    if not allowed(opts) then return nil, "server_authority_required" end
    if type(obs) ~= "table" then return nil, "room_observation_required" end
    local nx, ny = finite(obs.x, nil), finite(obs.y, nil)
    if nx == nil or ny == nil then return nil, "room_coordinates_required" end
    local semType, label, sev, effects = Discovery.ClassifyRoomObservation(obs)
    if not semType then return nil, "no_distinct_story_evidence" end
    return publishDiscovery({
        semanticType = semType,
        sourceKind = "observable_building_scene",
        vanillaSourceID = "observable_room_scene",
        label = label,
        severity = sev,
        salience = 0.75,
        effects = effects,
    }, nx, ny, finite(obs.z, 0) or 0, opts)
end

local function extractRoomSummary(room)
    local r = objOrNil(room)
    if not r then return nil end
    local def = type(r.getRoomDef) == "function" and objOrNil(r:getRoomDef()) or nil
    local roomName = (type(r.getName) == "function" and r:getName())
        or (def and type(def.getName) == "function" and def:getName())
        or r.name or ""
    local squares = type(r.getSquares) == "function" and objOrNil(r:getSquares()) or nil
    local sx, sy, sz = finite(r.x, nil), finite(r.y, nil), 0
    if def and (sx == nil or sy == nil) then
        sx = finite(def.x, nil)
        sy = finite(def.y, nil)
    end
    local count = squares and type(squares.size) == "function" and math.min(squares:size(), Discovery.MAX_ROOM_SQUARES) or 0
    local stats = {
        roomName = roomName,
        x = sx,
        y = sy,
        z = sz,
        barricadeCount = 0,
        burntTileCount = 0,
        deadBodyCount = 0,
        weaponBagCount = 0,
        medBagCount = 0,
        survivorBagCount = 0,
        ratCount = 0,
        smashedWindowCount = 0,
    }
    for idx = 0, count - 1 do
        local sq = squares:get(idx)
        if sq then
            if stats.x == nil and type(sq.getX) == "function" then
                stats.x, stats.y, stats.z = sq:getX(), sq:getY(), sq:getZ()
            end
            if IsoFlagType and IsoFlagType.burntOut and type(sq.has) == "function" and sq:has(IsoFlagType.burntOut) then
                stats.burntTileCount = stats.burntTileCount + 1
            end
            if type(sq.getDeadBodys) == "function" then
                local bodies = sq:getDeadBodys()
                if bodies and type(bodies.size) == "function" then
                    stats.deadBodyCount = stats.deadBodyCount + bodies:size()
                end
            end
            if type(sq.getObjects) == "function" then
                local objs = sq:getObjects()
                local oSize = objs and type(objs.size) == "function" and math.min(objs:size(), 16) or 0
                for o = 0, oSize - 1 do
                    local obj = objs:get(o)
                    if type(instanceof) == "function" then
                        if instanceof(obj, "IsoWindow") and type(obj.isSmashed) == "function" and obj:isSmashed() then
                            stats.smashedWindowCount = stats.smashedWindowCount + 1
                        end
                        if (instanceof(obj, "IsoWindow") or instanceof(obj, "IsoDoor"))
                            and type(obj.isBarricaded) == "function" and obj:isBarricaded()
                        then
                            stats.barricadeCount = stats.barricadeCount + 1
                        end
                    end
                end
            end
        end
    end
    return stats
end

function Discovery.OnSeeNewRoom(room, opts)
    local stats = extractRoomSummary(room)
    if not stats then return nil, "room_unavailable" end
    return Discovery.InspectRoomObservation(stats, opts)
end

function Discovery.OnSpawnVehicleEnd(vehicle, opts)
    if not allowed(opts) then return nil, "server_authority_required" end
    local v = objOrNil(vehicle)
    if not v then return nil, "vehicle_unavailable" end
    local scriptName = (type(v.getScriptName) == "function" and v:getScriptName()) or v.scriptName or ""
    local vx = finite(type(v.getX) == "function" and v:getX() or v.x, nil)
    local vy = finite(type(v.getY) == "function" and v:getY() or v.y, nil)
    if vx == nil or vy == nil then return nil, "vehicle_coordinates_required" end
    local lower = string.lower(tostring(scriptName))
    local pendingKind = nil
    if string.find(lower, "ambulance", 1, true) then
        pendingKind = "RVSAmbulanceCrash"
    elseif string.find(lower, "police", 1, true) then
        pendingKind = "RVSPoliceBlockade"
    elseif string.find(lower, "burnt", 1, true) then
        pendingKind = "RVSBurntCar"
    end
    if not pendingKind then return nil, "non_story_vehicle" end

    opts = type(opts) == "table" and opts or {}
    if opts.observerPresent == true then
        return Discovery.DiscoverVehicleStory(pendingKind, vx, vy, opts)
    end
    local canonicalID, spec = Discovery.ResolveVehicleStorySpec(pendingKind)
    return Discovery.RecordPendingSite({
        kind = "randomized_vehicle_story",
        storyID = canonicalID,
        semanticType = spec.semanticType,
        label = spec.label,
        x = vx,
        y = vy,
        severity = spec.severity,
        salience = spec.salience,
        effects = spec.effects,
    }), "pending_recorded"
end

function Discovery.InspectChunk(chunk, opts)
    if not allowed(opts) then return 0 end
    local c = objOrNil(chunk)
    if not c then return 0 end
    local recorded = 0

    -- 1. Check pending VehicleStorySpawnData on this loaded chunk
    local spawnData = objOrNil(c.vehicleStorySpawnData)
        or (type(c.getRandomVehicleStoryToSpawnLater) == "function" and objOrNil(c:getRandomVehicleStoryToSpawnLater()) or nil)
    if spawnData then
        local story = objOrNil(spawnData.story)
        local storyName = (story and type(story.getName) == "function" and story:getName())
            or spawnData.storyName or nil
        local sx = finite(spawnData.spawnX or spawnData.x, nil)
        local sy = finite(spawnData.spawnY or spawnData.y, nil)
        if storyName and sx and sy then
            local canonicalID, spec = Discovery.ResolveVehicleStorySpec(storyName)
            if Discovery.RecordPendingSite({
                kind = "randomized_vehicle_story",
                storyID = canonicalID or storyName,
                semanticType = spec.semanticType,
                label = spec.label,
                x = sx,
                y = sy,
                severity = spec.severity,
                salience = spec.salience,
                effects = spec.effects,
            }) then
                recorded = recorded + 1
            end
        end
    end

    -- 2. Check Zone.pickedRzStory / Ranch on zones touched by this chunk (bounded)
    local zones = objOrNil(c.zones)
    local count = zones and type(zones.size) == "function" and math.min(zones:size(), 16)
        or (type(zones) == "table" and math.min(#zones, 16) or 0)
    for idx = 1, count do
        local z = type(zones.get) == "function" and objOrNil(zones:get(idx - 1)) or objOrNil(zones[idx])
        if z then
            local rzStory = objOrNil(z.pickedRzStory)
            if rzStory then
                local sName = (type(rzStory.getName) == "function" and rzStory:getName()) or rzStory.name
                local zx = finite(z.pickedXForZoneStory or z.x, nil)
                local zy = finite(z.pickedYForZoneStory or z.y, nil)
                local canonicalID, spec = Discovery.ResolveZoneStorySpec(sName)
                if spec and zx and zy then
                    Discovery.RecordPendingSite({
                        kind = "randomized_zone_story",
                        storyID = canonicalID or sName,
                        semanticType = spec.semanticType,
                        label = spec.label,
                        x = zx,
                        y = zy,
                        severity = spec.severity,
                        salience = spec.salience,
                        effects = spec.effects,
                    })
                    recorded = recorded + 1
                end
            elseif tostring(z.type or "") == "Ranch" and finite(z.x, nil) and finite(z.y, nil) then
                Discovery.RecordPendingSite({
                    kind = "randomized_ranch",
                    storyID = "RandomizedRanchBase",
                    semanticType = "discovery.ranch_livestock",
                    label = "livestock ranch (" .. tostring(z.name or "livestock") .. ")",
                    animalType = tostring(z.name or "livestock"),
                    x = finite(z.x, 0),
                    y = finite(z.y, 0),
                    severity = 0.30,
                    salience = 0.70,
                })
                recorded = recorded + 1
            end
        end
    end
    return recorded
end

function Discovery.DiscoverNearPoint(x, y, radius, opts)
    if not allowed(opts) then return {} end
    local nx, ny = finite(x, nil), finite(y, nil)
    if nx == nil or ny == nil then return {} end
    local rad = math.max(8, finite(radius, Discovery.DEFAULT_DISCOVERY_RADIUS) or Discovery.DEFAULT_DISCOVERY_RADIUS)
    local radSq = rad * rad
    local promoted = {}
    for i = #Discovery._pendingOrder, 1, -1 do
        local id = Discovery._pendingOrder[i]
        local site = Discovery._pendingSites[id]
        if site then
            local dx = site.x - nx
            local dy = site.y - ny
            if (dx * dx + dy * dy) <= radSq then
                local res = publishDiscovery({
                    semanticType = site.semanticType,
                    sourceKind = site.kind,
                    vanillaSourceID = site.storyID,
                    label = site.label,
                    animalType = site.animalType,
                    severity = site.severity,
                    salience = site.salience,
                    effects = site.effects,
                }, site.x, site.y, site.z, opts)
                if res then
                    promoted[#promoted + 1] = res
                end
                Discovery._pendingSites[id] = nil
                table.remove(Discovery._pendingOrder, i)
            end
        end
    end
    return promoted
end

function Discovery.InstallHooks()
    if Discovery._hooksInstalled then return true end
    if type(Events) ~= "table" then return false, "events_unavailable" end
    if not allowed() then return false, "server_authority_required" end
    Discovery._hooksInstalled = true
    if type(Events.LoadChunk) == "table" and type(Events.LoadChunk.Add) == "function" then
        Events.LoadChunk.Add(function(chunk) Discovery.InspectChunk(chunk) end)
    end
    if type(Events.OnSpawnVehicleEnd) == "table" and type(Events.OnSpawnVehicleEnd.Add) == "function" then
        Events.OnSpawnVehicleEnd.Add(function(vehicle) Discovery.OnSpawnVehicleEnd(vehicle) end)
    end
    if type(Events.OnSeeNewRoom) == "table" and type(Events.OnSeeNewRoom.Add) == "function" then
        Events.OnSeeNewRoom.Add(function(room) Discovery.OnSeeNewRoom(room) end)
    end
    return true
end

Discovery.InstallHooks()

return Discovery
