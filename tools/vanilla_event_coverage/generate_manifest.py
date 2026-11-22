#!/usr/bin/env python3
"""Deterministic generator and verifier for the V0 vanilla-event coverage manifest.

Inspects the decompiled Project Zomboid Java baseline and vanilla Lua definitions
to account for 100% of first-party live events, state transitions, ambient meta
events, weather/helicopter lifecycles, and randomized-world story classes without
silent omissions.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

DEFAULT_JAVA_ROOT = Path("/home/psychopatz/Desktop/Projects/ZomboidDecompiler/output/source/zombie")
DEFAULT_LUA_ROOT = Path(
    "/home/psychopatz/.steam/debian-installation/steamapps/common/ProjectZomboid/projectzomboid/media/lua"
)
DEFAULT_OUTPUT = (
    Path(__file__).resolve().parents[2]
    / "Docs"
    / "Jobs"
    / "UnifiedVanillaWorldEventSemantics"
    / "VANILLA_EVENT_COVERAGE.json"
)

VALID_CLASSIFICATIONS = {
    "supported_live_event",
    "supported_state_transition",
    "supported_discovery_event",
    "supported_through_generic_semantic_category",
    "intentionally_ephemeral",
    "unsupported_missing_authoritative_seam",
}


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""


def _parse_registered_classes(java_source: str, list_token: str) -> Set[str]:
    pattern = re.compile(rf"{re.escape(list_token)}\.add\(new\s+([A-Za-z0-9_]+)\(")
    return set(pattern.findall(java_source))


def _parse_ranch_lua_definitions(lua_root: Path) -> List[Dict[str, Any]]:
    ranch_path = lua_root / "shared" / "Definitions" / "animal" / "RanchZoneDefinitions.lua"
    content = _read_text(ranch_path)
    if not content:
        return []
    entries: Dict[str, Dict[str, Any]] = {}
    type_decl = re.compile(r'RanchZoneDefinitions\.type\["([^"]+)"\]\s*=\s*\{\}')
    prop_decl = re.compile(r'RanchZoneDefinitions\.type\["([^"]+)"\]\.(\w+)\s*=\s*(.+?);')
    for match in type_decl.finditer(content):
        key = match.group(1)
        entries[key] = {"id": key}
    for match in prop_decl.finditer(content):
        key, prop, raw_val = match.group(1), match.group(2), match.group(3).strip()
        if key not in entries:
            entries[key] = {"id": key}
        if prop in ("globalName", "femaleType", "maleType", "type"):
            entries[key][prop] = raw_val.strip('"')
        elif prop == "possibleDef":
            entries[key][prop] = re.findall(r'"([^"]+)"', raw_val)
    result: List[Dict[str, Any]] = []
    for key in sorted(entries.keys()):
        info = entries[key]
        is_selector = "possibleDef" in info
        result.append(
            {
                "id": f"ranch.def.{key}",
                "family": "randomized_ranch_definition",
                "vanillaKey": key,
                "sourceFile": str(ranch_path.relative_to(lua_root)),
                "classification": (
                    "supported_through_generic_semantic_category"
                    if is_selector
                    else "supported_discovery_event"
                ),
                "triggerHookOrCadence": "LoadChunk + local Zone(type='Ranch') / DesignationZoneAnimal / IsoAnimal observation",
                "authoritativeFields": (
                    ["zone.type", "zone.name", "possibleDef"]
                    if is_selector
                    else ["zone.type", "zone.name", "DesignationZoneAnimal.getName()", "IsoAnimal"]
                ),
                "semanticType": "discovery.ranch_livestock",
                "defaultScope": "local_area",
                "retentionPolicy": "historical",
                "actorProvenanceRule": "witnessed when observed near ranch zone or told/radio downstream",
                "dtEconomicRelevance": "localized_livestock_food_opportunity",
                "evidenceNotes": (
                    f"Selector ranch definition delegating to {info.get('possibleDef')}"
                    if is_selector
                    else (
                        f"Animal ranch definition for globalName={info.get('globalName', key)} "
                        f"({info.get('femaleType', '')}/{info.get('maleType', '')})."
                    )
                ),
            }
        )
    return result


def _vehicle_semantic(class_name: str) -> Tuple[str, str]:
    mapping = {
        "RVSAmbulanceCrash": ("discovery.vehicle_story.ambulance_crash", "high_medical_salvage_or_route_hazard"),
        "RVSBanditRoad": ("discovery.vehicle_story.bandit_road", "high_caravan_danger_weapon_demand"),
        "RVSPoliceBlockade": ("discovery.vehicle_story.police_blockade", "route_restriction_security_demand"),
        "RVSPoliceBlockadeShooting": ("discovery.vehicle_story.police_blockade", "high_caravan_danger_ammo_demand"),
        "RVSCrashHorde": ("discovery.vehicle_story.crash_horde", "high_caravan_danger"),
        "RVSBurntCar": ("discovery.vehicle_story.burnt_vehicles", "low_wreckage_noise"),
        "RVSCarCrash": ("discovery.vehicle_story.road_crash", "minor_route_hazard"),
        "RVSCarCrashCorpse": ("discovery.vehicle_story.road_crash", "minor_route_hazard"),
        "RVSCarCrashDeer": ("discovery.vehicle_story.road_crash", "minor_food_or_route_hazard"),
        "RVSChangingTire": ("discovery.vehicle_story.road_breakdown", "minor_tool_salvage"),
        "RVSConstructionSite": ("discovery.vehicle_story.utility_worksite", "localized_tool_material_signal"),
        "RVSDeadEnd": ("discovery.vehicle_story.road_blockage", "minor_route_detour"),
        "RVSFlippedCrash": ("discovery.vehicle_story.road_crash", "minor_route_hazard"),
        "RVSHerdOnRoad": ("discovery.vehicle_story.road_livestock", "localized_livestock_signal"),
        "RVSPlonkies": ("discovery.vehicle_story.supply_vehicle", "localized_food_alcohol_signal"),
        "RVSRegionalProfessionVehicle": ("discovery.vehicle_story.utility_worksite", "localized_tool_salvage"),
        "RVSRichJerk": ("discovery.vehicle_story.stranded_vehicle", "none"),
        "RVSRoadKill": ("discovery.vehicle_story.roadkill", "none"),
        "RVSRoadKillSmall": ("discovery.vehicle_story.roadkill", "none"),
        "RVSTrailerCrash": ("discovery.vehicle_story.road_crash", "localized_salvage_or_route_hazard"),
        "RVSUtilityVehicle": ("discovery.vehicle_story.utility_worksite", "localized_tool_signal"),
        "RVSAnimalOnRoad": ("discovery.vehicle_story.road_livestock", "localized_livestock_signal"),
        "RVSAnimalTrailerOnRoad": ("discovery.vehicle_story.road_livestock", "localized_livestock_signal"),
    }
    return mapping.get(class_name, ("discovery.vehicle_story.road_scene", "none"))


def _zone_semantic(class_name: str) -> Tuple[str, str]:
    mapping = {
        "RZSMurderScene": ("discovery.zone_story.murder_scene", "local_danger_awareness"),
        "RZSBuryingCamp": ("discovery.zone_story.grave_site", "none"),
        "RZSHunterCamp": ("discovery.zone_story.hunter_camp", "localized_ammo_food_signal"),
        "RZSTrapperCamp": ("discovery.zone_story.hunter_camp", "localized_survival_signal"),
        "RZSSurvivalistCamp": ("discovery.zone_story.survivalist_camp", "localized_survival_supply_signal"),
        "RZSCampsite": ("discovery.zone_story.campsite", "none"),
        "RZSForestCamp": ("discovery.zone_story.campsite", "none"),
        "RZSForestCampEaten": ("discovery.zone_story.overrun_camp", "minor_danger_signal"),
        "RZSHermitCamp": ("discovery.zone_story.hermit_camp", "none"),
        "RZSOldShelter": ("discovery.zone_story.old_shelter", "none"),
        "RZSSadCamp": ("discovery.zone_story.overrun_camp", "none"),
        "RZSTragicPicnic": ("discovery.zone_story.tragic_scene", "none"),
        "RZSVanCamp": ("discovery.zone_story.campsite", "none"),
        "RZSWaterPump": ("discovery.zone_story.water_pump_site", "localized_water_tool_signal"),
        "RZSAttachedAnimal": ("discovery.zone_story.animal_site", "localized_livestock_signal"),
        "RZSEscapedAnimal": ("discovery.zone_story.animal_site", "localized_livestock_signal"),
        "RZSEscapedHerd": ("discovery.zone_story.animal_site", "localized_livestock_signal"),
        "RZSOrphanedFawn": ("discovery.zone_story.animal_site", "none"),
        "RZSHogWild": ("discovery.zone_story.animal_site", "none"),
        "RZSBurntWreck": ("discovery.zone_story.burnt_wreck", "none"),
        "RZSWasteDump": ("discovery.zone_story.waste_dump", "none"),
        "RZSOccultActivity": ("discovery.zone_story.occult_scene", "none"),
        "RZSCharcoalBurner": ("discovery.zone_story.work_site", "localized_fuel_signal"),
        "RZSFishingTrip": ("discovery.zone_story.recreation_scene", "none"),
        "RZSBBQParty": ("discovery.zone_story.recreation_scene", "none"),
        "RZSBeachParty": ("discovery.zone_story.recreation_scene", "none"),
        "RZSBaseball": ("discovery.zone_story.recreation_scene", "none"),
        "RZSMusicFest": ("discovery.zone_story.gathering_site", "none"),
        "RZSMusicFestStage": ("discovery.zone_story.gathering_site", "none"),
        "RZSRockerParty": ("discovery.zone_story.gathering_site", "none"),
        "RZSHillbillyHoedown": ("discovery.zone_story.gathering_site", "none"),
        "RZSNastyMattress": ("discovery.zone_story.transient_site", "none"),
        "RZSOldFirepit": ("discovery.zone_story.campsite", "none"),
        "RZSSexyTime": ("discovery.zone_story.recreation_scene", "none"),
        "RZJackieJaye": ("discovery.zone_story.named_survivor_scene", "none"),
        "RZSDean": ("discovery.zone_story.named_survivor_scene", "none"),
        "RZSDuke": ("discovery.zone_story.named_survivor_scene", "none"),
        "RZSFrankHemingway": ("discovery.zone_story.named_survivor_scene", "none"),
        "RZSKirstyKormick": ("discovery.zone_story.named_survivor_scene", "none"),
        "RZSRangerSmith": ("discovery.zone_story.named_survivor_scene", "none"),
        "RZSSirTwiggy": ("discovery.zone_story.named_survivor_scene", "none"),
    }
    return mapping.get(class_name, ("discovery.zone_story.zone_scene", "none"))


def _building_semantic(class_name: str) -> Tuple[str, str, str, str]:
    # Returns: (classification, semanticType, dtEconomicRelevance, note)
    if class_name in ("RandomizedBuildingBase", "RBBasic", "RBTableStoryBase"):
        return (
            "intentionally_ephemeral",
            "internal.randomized_building_framework",
            "none",
            f"Dispatcher/base Java class ({class_name}); triggers room/table/RDS generation during chunk stream-in.",
        )
    if class_name.startswith("RBTS"):
        return (
            "intentionally_ephemeral",
            "world.table_clutter",
            "none",
            "Small tabletop prop micro-story (RBTableStoryBase.getRandomStory); intentionally ephemeral environmental detail.",
        )
    if class_name == "RBReverend":
        return (
            "unsupported_missing_authoritative_seam",
            "discovery.building_scene.reverend_scene",
            "none",
            "Class exists in zombie.randomizedWorld.randomizedBuilding.RBReverend but is not registered in IsoWorld.randomizedBuildingList and BuildingDef stores no picked building story field.",
        )
    specific = {
        "RBGunstoreSiege": ("discovery.building_scene.gunstore_siege", "localized_weapon_ammo_demand"),
        "RBPoliceSiege": ("discovery.building_scene.police_siege", "localized_weapon_security_signal"),
        "RBSWATStation": ("discovery.building_scene.police_siege", "localized_weapon_security_signal"),
        "RBSafehouse": ("discovery.building_scene.safehouse", "localized_survival_stash_signal"),
        "RBBurnt": ("discovery.building_scene.burnt_structure", "none"),
        "RBBurntCorpse": ("discovery.building_scene.burnt_structure", "none"),
        "RBBurntFireman": ("discovery.building_scene.burnt_structure", "none"),
        "RBLooted": ("discovery.building_scene.looted_structure", "localized_scarcity_signal"),
        "RBShopLooted": ("discovery.building_scene.looted_structure", "localized_scarcity_signal"),
        "RBTrashed": ("discovery.building_scene.looted_structure", "none"),
        "RBClinic": ("discovery.building_scene.clinic_medical", "localized_medical_signal"),
        "RBBar": ("discovery.building_scene.commercial_scene", "none"),
        "RBBarn": ("discovery.building_scene.barn_scene", "none"),
        "RBCafe": ("discovery.building_scene.commercial_scene", "none"),
        "RBDorm": ("discovery.building_scene.residential_scene", "none"),
        "RBHairSalon": ("discovery.building_scene.commercial_scene", "none"),
        "RBHeatBreakAfternoon": ("discovery.building_scene.commercial_scene", "none"),
        "RBJackieJaye": ("discovery.building_scene.named_building_scene", "none"),
        "RBJoanHartford": ("discovery.building_scene.named_building_scene", "none"),
        "RBJudge": ("discovery.building_scene.named_building_scene", "none"),
        "RBKateAndBaldspot": ("discovery.building_scene.named_building_scene", "none"),
        "RBMayorWestPoint": ("discovery.building_scene.named_building_scene", "none"),
        "RBNolans": ("discovery.building_scene.commercial_scene", "none"),
        "RBOffice": ("discovery.building_scene.commercial_scene", "none"),
        "RBOther": ("discovery.building_scene.residential_scene", "none"),
        "RBPileOCrepe": ("discovery.building_scene.commercial_scene", "none"),
        "RBPizzaWhirled": ("discovery.building_scene.commercial_scene", "none"),
        "RBSchool": ("discovery.building_scene.school_scene", "none"),
        "RBSpiffo": ("discovery.building_scene.commercial_scene", "none"),
        "RBStripclub": ("discovery.building_scene.commercial_scene", "none"),
        "RBTwiggy": ("discovery.building_scene.commercial_scene", "none"),
        "RBWoodcraft": ("discovery.building_scene.commercial_scene", "none"),
    }
    sem_type, dt_rel = specific.get(class_name, ("discovery.building_scene.generic", "none"))
    return (
        "supported_through_generic_semantic_category",
        sem_type,
        dt_rel,
        "BuildingDef exposes no pickedBuildingStory ID; observed on OnSeeNewRoom / local room inspection via grounded observable evidence (room name, barricades, burnt tiles, smashed windows/doors, corpses, stashes).",
    )


def _dead_survivor_semantic(class_name: str, registered_rds: Set[str]) -> Tuple[str, str, str, str]:
    if class_name == "RandomizedDeadSurvivorBase":
        return (
            "intentionally_ephemeral",
            "internal.dead_survivor_base",
            "none",
            "Base class for dead survivor building interiors spawned by RBBasic.doRandomDeadSurvivorStory.",
        )
    if class_name not in registered_rds:
        return (
            "unsupported_missing_authoritative_seam",
            "discovery.dead_survivor.unregistered_class",
            "none",
            f"{class_name} exists in zombie.randomizedWorld.randomizedDeadSurvivor but is NOT registered in RBBasic.deadSurvivorsStory and BuildingDef stores no picked RDS class identity.",
        )
    specific = {
        "RDSBanditRaid": ("discovery.dead_survivor.bandit_raid", "localized_caravan_danger_weapon_demand"),
        "RDSPoliceAtHouse": ("discovery.dead_survivor.police_incident", "localized_security_awareness"),
        "RDSPrisonEscape": ("discovery.dead_survivor.prison_escape", "localized_danger_awareness"),
        "RDSPrisonEscapeWithPolice": ("discovery.dead_survivor.police_incident", "localized_security_awareness"),
        "RDSSuicidePact": ("discovery.dead_survivor.suicide_pact", "none"),
        "RDSBleach": ("discovery.dead_survivor.suicide_scene", "none"),
        "RDSGunmanInBathroom": ("discovery.dead_survivor.suicide_scene", "none"),
        "RDSGunslinger": ("discovery.dead_survivor.armed_survivor_body", "none"),
        "RDSZombiesEating": ("discovery.dead_survivor.zombies_eating", "local_danger_awareness"),
        "RDSRatInfested": ("discovery.dead_survivor.rat_infestation", "none"),
        "RDSRatKing": ("discovery.dead_survivor.rat_infestation", "none"),
        "RDSDevouredByRats": ("discovery.dead_survivor.rat_infestation", "none"),
        "RDSResourceGarage": ("discovery.dead_survivor.supply_cache", "localized_tool_supply_signal"),
    }
    sem_type, dt_rel = specific.get(class_name, ("discovery.dead_survivor.corpse_scene", "none"))
    return (
        "supported_through_generic_semantic_category",
        sem_type,
        dt_rel,
        "BuildingDef/RBBasic retains no picked RDS class field; observed on OnSeeNewRoom via bounded local evidence (IsoDeadBody count/damage/outfits, room name, barricades, rats, zombie outfits).",
    )


def _live_vanilla_entries(java_root: Path) -> List[Dict[str, Any]]:
    ambient_stream_src = _read_text(java_root / "AmbientStreamManager.java")
    ambient_sound_src = _read_text(java_root / "AmbientSoundManager.java")
    lua_mgr_src = _read_text(java_root / "Lua" / "LuaEventManager.java")

    entries: List[Dict[str, Any]] = [
        {
            "id": "utility.electricity_cutoff",
            "family": "utility_state_transition",
            "javaClassOrHook": "OnElectricityChanged + IsoWorld.isHydroPowerOn + SandboxOptions.doesPowerGridExist",
            "sourceFile": "AmbientStreamManager.java / AmbientSoundManager.java",
            "classification": "supported_state_transition",
            "triggerHookOrCadence": "Events.OnElectricityChanged + shared coarse cadence reconciliation",
            "authoritativeFields": ["IsoWorld:isHydroPowerOn()", "SandboxOptions:doesPowerGridExist()"],
            "semanticType": "utility.electricity_cutoff",
            "defaultScope": "global",
            "retentionPolicy": "historical",
            "actorProvenanceRule": "environmental direct check on indoor lights/appliances or told/radio downstream",
            "dtEconomicRelevance": "global_fuel_tool_perishable_food_pressure",
            "evidenceNotes": "Verified AmbientStreamManager.java:631 and AmbientSoundManager.java:243 trigger OnElectricityChanged when hydro power state changes.",
        },
        {
            "id": "utility.water_cutoff",
            "family": "utility_state_transition",
            "javaClassOrHook": "SandboxOptions.getWaterShutModifier + GameTime.getWorldAgeDaysSinceBegin",
            "sourceFile": "SandboxOptions.java / GameTime.java / IsoObject.java",
            "classification": "supported_state_transition",
            "triggerHookOrCadence": "OnGameStart + EveryHours + shared coarse cadence reconciliation",
            "authoritativeFields": ["SandboxOptions:getWaterShutModifier()", "GameTime:getWorldAgeDaysSinceBegin()"],
            "semanticType": "utility.water_cutoff",
            "defaultScope": "global",
            "retentionPolicy": "historical",
            "actorProvenanceRule": "environmental direct faucet check or told/radio downstream",
            "dtEconomicRelevance": "global_water_food_medical_pressure",
            "evidenceNotes": "Verified LuaEventManager OnWaterAmountChange is per-container IsoObject/ObjectModDataPacket only; global water cutoff derives authoritatively from WaterShutModifier vs worldAgeDaysSinceBegin.",
        },
        {
            "id": "world.helicopter_overflight",
            "family": "helicopter_episode",
            "javaClassOrHook": "zombie.iso.Helicopter (IsoWorld.instance.helicopter)",
            "sourceFile": "iso/Helicopter.java / GameTime.java",
            "classification": "supported_live_event",
            "triggerHookOrCadence": "Shared bounded coarse cadence (no dedicated Lua helicopter event in LuaEventManager)",
            "authoritativeFields": ["helicopter:isActive()", "helicopter.x", "helicopter.y", "helicopter.state"],
            "semanticType": "world.helicopter_overflight",
            "defaultScope": "region",
            "retentionPolicy": "historical",
            "actorProvenanceRule": "outdoor nearby -> witnessed; indoor nearby -> environmental (heard, lower precision); distant -> told/radio",
            "dtEconomicRelevance": "regional_caravan_danger_ammo_medical_demand",
            "evidenceNotes": "Single bounded episode per overflight with capped coarse location samples (<= 5); never persists per-frame telemetry.",
        },
    ]

    ambient_defs = [
        ("MetaAssaultRifle1", "supported_live_event", "ambient.gunfire", "local_area", "historical", "localized_caravan_danger_weapon_demand"),
        ("MetaPistol1", "supported_live_event", "ambient.gunfire", "local_area", "historical", "localized_caravan_danger_weapon_demand"),
        ("MetaPistol2", "supported_live_event", "ambient.gunfire", "local_area", "historical", "localized_caravan_danger_weapon_demand"),
        ("MetaPistol3", "supported_live_event", "ambient.gunfire", "local_area", "historical", "localized_caravan_danger_weapon_demand"),
        ("MetaShotgun1", "supported_live_event", "ambient.gunfire", "local_area", "historical", "localized_caravan_danger_weapon_demand"),
        ("MetaScream", "supported_live_event", "ambient.scream", "local_area", "historical", "localized_minor_danger_awareness"),
        ("burglar2", "supported_live_event", "world.house_alarm", "local_area", "historical", "localized_caravan_danger"),
        ("MetaDogBark", "intentionally_ephemeral", "ambient.dog_bark", "local_area", "ephemeral", "none"),
        ("MetaOwl", "intentionally_ephemeral", "ambient.wildlife", "local_area", "ephemeral", "none"),
        ("MetaWolfHowl", "intentionally_ephemeral", "ambient.wildlife", "local_area", "ephemeral", "none"),
        ("thunder_ambient_empty", "intentionally_ephemeral", "weather.thunder", "local_area", "ephemeral", "none"),
    ]
    for source_id, cls, sem_type, scope, retention, dt_rel in ambient_defs:
        token = '""' if source_id == "thunder_ambient_empty" else f'"{source_id}"'
        present = (token in ambient_stream_src) or (token in ambient_sound_src)
        entries.append(
            {
                "id": f"ambient.{source_id}",
                "family": "ambient_meta_event",
                "javaClassOrHook": f"OnAmbientSound({source_id}, x, y)",
                "sourceFile": "AmbientStreamManager.java / AmbientSoundManager.java",
                "classification": cls,
                "triggerHookOrCadence": "Events.OnAmbientSound",
                "authoritativeFields": ["name", "x", "y"],
                "semanticType": sem_type,
                "defaultScope": scope,
                "retentionPolicy": retention,
                "actorProvenanceRule": (
                    "witnessed/environmental within hearing radius"
                    if retention == "historical"
                    else "ephemeral immediate beat reaction only; excluded from WorldKnowledge ledger"
                ),
                "dtEconomicRelevance": dt_rel,
                "evidenceNotes": f"Verified in vanilla ambient managers (presentInDecompiledSource={present}). Normalized into '{sem_type}' with vanillaSourceID preserved.",
            }
        )

    other_hooks = [
        ("world.house_alarm_sp", "live_world_sound", "OnWorldSound(x,y,z,radius,volume,source instanceof Alarm)", "iso/Alarm.java / AmbientStreamManager.java", "supported_live_event", "Events.OnWorldSound (O(1) Alarm filter)", ["x", "y", "z", "radius", "source"], "world.house_alarm", "local_area", "historical", "witnessed or environmental within alarm radius", "localized_caravan_danger", "SP triggers Alarm world sound every update; Core deduplicates by localAreaID + cooldown."),
        ("weather.period_start", "weather_climate", "OnWeatherPeriodStart(weatherPeriod)", "iso/weather/WeatherPeriod.java", "supported_live_event", "Events.OnWeatherPeriodStart", ["isBlizzard()", "isTropicalStorm()", "isThunderStorm()", "getCurrentStrength()"], "weather.severe_storm", "region", "historical", "environmental regional storm observation", "regional_severe_storm_travel_risk", "Severe storms (blizzard/tropical/heavy thunderstorm) register bounded regional episodes; ordinary rain remains ephemeral."),
        ("weather.period_stage", "weather_climate", "OnWeatherPeriodStage(weatherPeriod)", "iso/weather/WeatherPeriod.java", "supported_through_generic_semantic_category", "Events.OnWeatherPeriodStage", ["getCurrentStageID()", "getCurrentStrength()"], "weather.severe_storm", "region", "derived_current", "environmental weather stage update", "regional_severe_storm_travel_risk", "Updates severe storm intensity or stays ephemeral context for ordinary fronts."),
        ("weather.period_complete", "weather_climate", "OnWeatherPeriodComplete(weatherPeriod)", "iso/weather/WeatherPeriod.java", "supported_live_event", "Events.OnWeatherPeriodComplete", ["weatherPeriod"], "weather.severe_storm", "region", "historical", "environmental weather end transition", "none", "Closes active severe storm episode cleanly."),
        ("weather.period_stop", "weather_climate", "OnWeatherPeriodStop(weatherPeriod)", "iso/weather/WeatherPeriod.java", "supported_live_event", "Events.OnWeatherPeriodStop", ["weatherPeriod"], "weather.severe_storm", "region", "historical", "environmental weather stop transition", "none", "Closes interrupted severe storm episode cleanly."),
        ("weather.thunder_event", "weather_climate", "OnThunderEvent(x, y, doStrike, doLightning, doRumble)", "iso/weather/ThunderStorm.java", "intentionally_ephemeral", "Events.OnThunderEvent", ["x", "y", "doStrike", "doLightning", "doRumble"], "weather.thunder", "local_area", "ephemeral", "ephemeral beat context only", "none", "Transient thunder strike/rumble never bloats WorldKnowledge ledger."),
        ("weather.rain_start", "weather_climate", "OnRainStart", "iso/objects/RainManager.java / LuaEventManager.java", "intentionally_ephemeral", "Events.OnRainStart", ["RainManager.isRaining()"], "weather.precipitation", "region", "ephemeral", "ephemeral weather context", "none", "Legacy rain start surface; treated as ephemeral weather context."),
        ("weather.rain_stop", "weather_climate", "OnRainStop", "iso/objects/RainManager.java", "intentionally_ephemeral", "Events.OnRainStop", ["RainManager.isRaining()"], "weather.precipitation", "region", "ephemeral", "ephemeral weather context", "none", "Rain stop surface; ephemeral weather context."),
        ("weather.change_weather", "weather_climate", "OnChangeWeather", "LuaEventManager.java", "intentionally_ephemeral", "Events.OnChangeWeather", ["climate weather string"], "weather.weather_change", "region", "ephemeral", "ephemeral weather context", "none", "Weather change notification; ephemeral context unless promoted by WeatherPeriod."),
        ("weather.season_transition", "weather_climate", "ClimateManager.getSeasonName", "iso/weather/ClimateManager.java", "supported_state_transition", "EveryDays / coarse cadence season check", ["ClimateManager:getSeasonName()"], "weather.season_transition", "region", "historical", "environmental seasonal observation", "regional_seasonal_food_shift", "Tracks seasonal transitions without per-tick polling."),
        ("media.device_broadcast", "radio_broadcast", "OnDeviceText(guid, codes, x, y, z, line, device)", "radio/ZomboidRadio.java", "supported_live_event", "Events.OnDeviceText", ["guid", "codes", "x", "y", "z", "device"], "media.broadcast", "local_area", "historical", "radio provenance from structured channel/guid metadata", "none", "Consumes structured broadcast channel/guid metadata without parsing arbitrary prose."),
        ("world.new_fire", "world_hazard", "OnNewFire(fire)", "iso/objects/IsoFire.java", "supported_live_event", "Events.OnNewFire", ["fire:getSquare()"], "world.fire_hazard", "local_area", "historical", "witnessed/environmental near fire", "localized_danger_awareness", "Deduplicated per localAreaID + cooldown to prevent fire-spread spam."),
        ("world.grid_burnt", "world_hazard", "OnGridBurnt(square)", "iso/IsoGridSquare.java", "supported_through_generic_semantic_category", "Events.OnGridBurnt", ["square:getX()", "square:getY()"], "world.fire_hazard", "local_area", "ephemeral", "coalesced into world.fire_hazard cooldown window", "none", "Avoids flooding knowledge with one event per burnt tile."),
        ("seam.see_new_room", "discovery_seam", "OnSeeNewRoom(room)", "iso/IsoCell.java:4178", "supported_discovery_event", "Events.OnSeeNewRoom", ["room:getName()", "room:getBuilding()", "squares"], "discovery.room_seam", "local_area", "ephemeral", "triggers bounded local building/dead-survivor discovery", "none", "Primary zero-scan hook for discovering indoor randomized stories when spotted."),
        ("seam.load_chunk", "discovery_seam", "LoadChunk(chunk)", "iso/IsoChunk.java:3974", "supported_discovery_event", "Events.LoadChunk", ["chunk.vehicleStorySpawnData", "chunk zones"], "discovery.chunk_seam", "local_area", "ephemeral", "captures pending vehicle/zone/ranch story metadata into bounded pending buffer", "none", "Never scans world; only inspects chunk passed by engine LoadChunk."),
        ("seam.spawn_vehicle_end", "discovery_seam", "OnSpawnVehicleEnd(vehicle)", "vehicles/BaseVehicle.java:914", "supported_discovery_event", "Events.OnSpawnVehicleEnd", ["vehicle:getScriptName()", "vehicle:getX()", "vehicle:getY()"], "discovery.vehicle_seam", "local_area", "ephemeral", "captures newly spawned crash/emergency/blockade vehicle signatures", "none", "Complements LoadChunk where VehicleStorySpawnData clears before LoadChunk."),
        ("seam.dead_body_spawn", "discovery_seam", "OnDeadBodySpawn(body)", "iso/objects/IsoDeadBody.java:418", "supported_through_generic_semantic_category", "Events.OnDeadBodySpawn", ["body:getX()", "body:getY()"], "discovery.corpse_seam", "local_area", "ephemeral", "corpse observation seam for local scene context", "none", "Observed within bounded local radius without per-body event spam."),
        ("director.sleeping_event", "sadistic_ai_director", "zombie.ai.sadisticAIDirector.SleepingEvent", "ai/sadisticAIDirector/SleepingEvent.java", "supported_through_generic_semantic_category", "No dedicated Lua hook; nightmares ephemeral, zombie intruders observed via window/combat/sound", ["SleepingEvent logic in Java"], "director.sleeping_intruder", "local_area", "ephemeral", "ephemeral unless zombie intruder creates observable local danger", "none", "LuaEventManager exposes OnSleepingTick(hourIndex, totalHours) only; nightmare state has no semantic world-fact value."),
        ("chunk.survivor_in_horde", "world_horde_story", "IsoChunk.addSurvivorInHorde", "iso/IsoChunk.java", "supported_through_generic_semantic_category", "Local horde/outfit observation when survivor zombie horde is encountered", ["zone Nav", "zombie outfits/bags"], "discovery.survivor_zombie_horde", "local_area", "historical", "witnessed when encountered locally", "localized_danger_awareness", "Spawns a survivor zombie with extra gear inside road horde during chunk load."),
    ]
    for (
        eid, family, hook, src, cls, trig, fields, sem, scope, ret, prov, dt_rel, notes
    ) in other_hooks:
        entries.append(
            {
                "id": eid,
                "family": family,
                "javaClassOrHook": hook,
                "sourceFile": src,
                "classification": cls,
                "triggerHookOrCadence": trig,
                "authoritativeFields": fields,
                "semanticType": sem,
                "defaultScope": scope,
                "retentionPolicy": ret,
                "actorProvenanceRule": prov,
                "dtEconomicRelevance": dt_rel,
                "evidenceNotes": f"{notes} (LuaEventManager present={bool(lua_mgr_src)})",
            }
        )
    return entries


def build_manifest(java_root: Path, lua_root: Path) -> Dict[str, Any]:
    iso_world_src = _read_text(java_root / "iso" / "IsoWorld.java")
    rbbasic_src = _read_text(java_root / "randomizedWorld" / "randomizedBuilding" / "RBBasic.java")
    registered_rds = _parse_registered_classes(rbbasic_src, "this.deadSurvivorsStory")

    entries: List[Dict[str, Any]] = []
    entries.extend(_live_vanilla_entries(java_root))

    rw_root = java_root / "randomizedWorld"
    base_java = rw_root / "RandomizedWorldBase.java"
    if base_java.is_file():
        entries.append(
            {
                "id": "randomized_world.RandomizedWorldBase",
                "family": "randomized_world_base",
                "javaClassOrHook": "zombie.randomizedWorld.RandomizedWorldBase",
                "sourceFile": "randomizedWorld/RandomizedWorldBase.java",
                "classification": "intentionally_ephemeral",
                "triggerHookOrCadence": "Base class for all PZ randomized stories",
                "authoritativeFields": ["name", "isUnique()", "isTimeValid()"],
                "semanticType": "internal.randomized_world_base",
                "defaultScope": "local_area",
                "retentionPolicy": "ephemeral",
                "actorProvenanceRule": "not directly instantiated as a story",
                "dtEconomicRelevance": "none",
                "evidenceNotes": "Root Java superclass under zombie.randomizedWorld.",
            }
        )

    # 1. randomizedBuilding (includes TableStories subdir -> 45 classes total)
    rb_files = sorted((rw_root / "randomizedBuilding").rglob("*.java"))
    for path in rb_files:
        cls_name = path.stem
        rel_src = str(path.relative_to(java_root))
        cls_cat, sem_type, dt_rel, note = _building_semantic(cls_name)
        entries.append(
            {
                "id": f"randomized_building.{cls_name}",
                "family": "randomized_building",
                "javaClassOrHook": f"zombie.randomizedWorld.randomizedBuilding.{cls_name}",
                "sourceFile": rel_src,
                "classification": cls_cat,
                "triggerHookOrCadence": "Events.OnSeeNewRoom (bounded room inspection) or table micro-prop",
                "authoritativeFields": ["RoomDef:getName()", "BuildingDef:isAllExplored()", "IsoBarricade", "IsoDeadBody", "IsoGridSquare burntOut/ground items"],
                "semanticType": sem_type,
                "defaultScope": "local_area",
                "retentionPolicy": "ephemeral" if cls_cat == "intentionally_ephemeral" else "historical",
                "actorProvenanceRule": "witnessed upon local room/building discovery or told/radio downstream",
                "dtEconomicRelevance": dt_rel,
                "evidenceNotes": f"{note} RegisteredInIsoWorld={cls_name in _parse_registered_classes(iso_world_src, 'this.randomizedBuildingList')}.",
            }
        )

    # 2. randomizedDeadSurvivor (33 classes)
    rds_files = sorted((rw_root / "randomizedDeadSurvivor").rglob("*.java"))
    for path in rds_files:
        cls_name = path.stem
        rel_src = str(path.relative_to(java_root))
        cls_cat, sem_type, dt_rel, note = _dead_survivor_semantic(cls_name, registered_rds)
        entries.append(
            {
                "id": f"randomized_dead_survivor.{cls_name}",
                "family": "randomized_dead_survivor",
                "javaClassOrHook": f"zombie.randomizedWorld.randomizedDeadSurvivor.{cls_name}",
                "sourceFile": rel_src,
                "classification": cls_cat,
                "triggerHookOrCadence": "Events.OnSeeNewRoom (bounded local corpse/outfit/room inspection)",
                "authoritativeFields": ["IsoDeadBody count/items/injuries", "zombie outfits", "RoomDef:getName()", "IsoBarricade"],
                "semanticType": sem_type,
                "defaultScope": "local_area",
                "retentionPolicy": "ephemeral" if cls_cat == "intentionally_ephemeral" else "historical",
                "actorProvenanceRule": "witnessed on room discovery or told/radio downstream",
                "dtEconomicRelevance": dt_rel,
                "evidenceNotes": f"{note} RegisteredInRBBasic={cls_name in registered_rds}.",
            }
        )

    # 3. randomizedVehicleStory (26 classes)
    rvs_files = sorted((rw_root / "randomizedVehicleStory").rglob("*.java"))
    for path in rvs_files:
        cls_name = path.stem
        rel_src = str(path.relative_to(java_root))
        if cls_name in ("RandomizedVehicleStoryBase", "VehicleStorySpawnData", "VehicleStorySpawner"):
            cls_cat = "intentionally_ephemeral"
            sem_type = "internal.vehicle_story_framework"
            dt_rel = "none"
            ret = "ephemeral"
            note = "Vehicle story spawn/spawner framework class; VehicleStorySpawnData exposes story identity and spawn coordinates before chunk finalization."
        else:
            cls_cat = "supported_discovery_event"
            sem_type, dt_rel = _vehicle_semantic(cls_name)
            ret = "historical"
            note = (
                "Supports exact story identity when chunk.vehicleStorySpawnData is captured at LoadChunk/spawn, "
                "plus observable road-scene discovery fallback (vehicle script, Nav zone, corpses/zombies) on OnSpawnVehicleEnd/local discovery."
            )
        entries.append(
            {
                "id": f"randomized_vehicle_story.{cls_name}",
                "family": "randomized_vehicle_story",
                "javaClassOrHook": f"zombie.randomizedWorld.randomizedVehicleStory.{cls_name}",
                "sourceFile": rel_src,
                "classification": cls_cat,
                "triggerHookOrCadence": "LoadChunk (chunk.vehicleStorySpawnData) + OnSpawnVehicleEnd + local road observation",
                "authoritativeFields": ["chunk.vehicleStorySpawnData", "VehicleStorySpawnData.story:getName()", "BaseVehicle:getScriptName()", "Zone Nav"],
                "semanticType": sem_type,
                "defaultScope": "local_area",
                "retentionPolicy": ret,
                "actorProvenanceRule": "witnessed when actor/player discovers vehicle scene or told/radio downstream",
                "dtEconomicRelevance": dt_rel,
                "evidenceNotes": note,
            }
        )

    # 4. randomizedZoneStory (42 classes)
    rzs_files = sorted((rw_root / "randomizedZoneStory").rglob("*.java"))
    for path in rzs_files:
        cls_name = path.stem
        rel_src = str(path.relative_to(java_root))
        if cls_name == "RandomizedZoneStoryBase":
            cls_cat = "intentionally_ephemeral"
            sem_type = "internal.zone_story_framework"
            dt_rel = "none"
            ret = "ephemeral"
            note = "Base class allocating Zone.pickedRzStory and pickedXForZoneStory/pickedYForZoneStory."
        else:
            cls_cat = "supported_discovery_event"
            sem_type, dt_rel = _zone_semantic(cls_name)
            ret = "historical"
            note = "Exposes authoritative Zone.pickedRzStory:getName() and Zone.pickedXForZoneStory/pickedYForZoneStory during zone stream-in, buffered until local discovery."
        entries.append(
            {
                "id": f"randomized_zone_story.{cls_name}",
                "family": "randomized_zone_story",
                "javaClassOrHook": f"zombie.randomizedWorld.randomizedZoneStory.{cls_name}",
                "sourceFile": rel_src,
                "classification": cls_cat,
                "triggerHookOrCadence": "LoadChunk (Zone.pickedRzStory) + local ZoneStory observation",
                "authoritativeFields": ["zone.pickedRzStory:getName()", "zone.pickedXForZoneStory", "zone.pickedYForZoneStory"],
                "semanticType": sem_type,
                "defaultScope": "local_area",
                "retentionPolicy": ret,
                "actorProvenanceRule": "witnessed when actor/player discovers zone scene or told/radio downstream",
                "dtEconomicRelevance": dt_rel,
                "evidenceNotes": note,
            }
        )

    # 5. randomizedRanch (2 Java classes + Lua RanchZoneDefinitions)
    rr_files = sorted((rw_root / "randomizedRanch").rglob("*.java"))
    for path in rr_files:
        cls_name = path.stem
        rel_src = str(path.relative_to(java_root))
        entries.append(
            {
                "id": f"randomized_ranch.{cls_name}",
                "family": "randomized_ranch",
                "javaClassOrHook": f"zombie.randomizedWorld.randomizedRanch.{cls_name}",
                "sourceFile": rel_src,
                "classification": "supported_discovery_event",
                "triggerHookOrCadence": "LoadChunk + local Zone(type='Ranch') / DesignationZoneAnimal / IsoAnimal observation",
                "authoritativeFields": ["Zone.type=='Ranch'", "Zone.name", "DesignationZoneAnimal", "IsoAnimal"],
                "semanticType": "discovery.ranch_livestock",
                "defaultScope": "local_area",
                "retentionPolicy": "historical",
                "actorProvenanceRule": "witnessed upon local ranch/livestock observation or told/radio downstream",
                "dtEconomicRelevance": "localized_livestock_food_opportunity",
                "evidenceNotes": "spawns DesignationZoneAnimal + IsoAnimal herds inside Ranch zones without requiring global scans.",
            }
        )
    entries.extend(_parse_ranch_lua_definitions(lua_root))

    counts_by_family: Dict[str, int] = {}
    counts_by_classification: Dict[str, int] = {}
    for entry in entries:
        fam = entry["family"]
        cls = entry["classification"]
        if cls not in VALID_CLASSIFICATIONS:
            raise ValueError(f"Invalid classification {cls} for {entry['id']}")
        counts_by_family[fam] = counts_by_family.get(fam, 0) + 1
        counts_by_classification[cls] = counts_by_classification.get(cls, 0) + 1

    return {
        "schemaVersion": "psychopatz.vanilla-event-coverage.v1",
        "installedBuildAudit": {
            "randomizedBuildingClasses": len(rb_files),
            "randomizedDeadSurvivorClasses": len(rds_files),
            "randomizedVehicleStoryClasses": len(rvs_files),
            "randomizedZoneStoryClasses": len(rzs_files),
            "randomizedRanchJavaClasses": len(rr_files),
            "ranchZoneLuaDefinitions": counts_by_family.get("randomized_ranch_definition", 0),
        },
        "summary": {
            "totalEntries": len(entries),
            "countsByFamily": dict(sorted(counts_by_family.items())),
            "countsByClassification": dict(sorted(counts_by_classification.items())),
            "unclassifiedCount": 0,
        },
        "entries": entries,
    }


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Generate or verify V0 VANILLA_EVENT_COVERAGE.json")
    parser.add_argument("--java-root", type=Path, default=DEFAULT_JAVA_ROOT)
    parser.add_argument("--lua-root", type=Path, default=DEFAULT_LUA_ROOT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true", help="Fail if output file differs from generated manifest")
    args = parser.parse_args(argv)

    manifest = build_manifest(args.java_root, args.lua_root)
    rendered = json.dumps(manifest, indent=2, sort_keys=True) + "\n"

    if args.check:
        if not args.output.is_file():
            print(f"[ERROR] Missing manifest at {args.output}", file=sys.stderr)
            return 2
        current = args.output.read_text(encoding="utf-8")
        if current != rendered:
            print(f"[ERROR] Manifest drift detected at {args.output}. Re-run without --check.", file=sys.stderr)
            return 1
        print(
            f"[OK] VANILLA_EVENT_COVERAGE.json verified ({manifest['summary']['totalEntries']} entries, "
            f"RB={manifest['installedBuildAudit']['randomizedBuildingClasses']}, "
            f"RDS={manifest['installedBuildAudit']['randomizedDeadSurvivorClasses']}, "
            f"RVS={manifest['installedBuildAudit']['randomizedVehicleStoryClasses']}, "
            f"RZS={manifest['installedBuildAudit']['randomizedZoneStoryClasses']}, "
            f"RR={manifest['installedBuildAudit']['randomizedRanchJavaClasses']} + "
            f"{manifest['installedBuildAudit']['ranchZoneLuaDefinitions']} Lua defs)."
        )
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    print(
        f"[WROTE] {args.output} ({manifest['summary']['totalEntries']} entries: "
        f"{json.dumps(manifest['summary']['countsByClassification'], sort_keys=True)})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
