-- Provider-neutral typed context schema for runtime .convo DSL parsing.
-- Adopter mods (ProjectHoomans, DynamicTrading, community packs) can register
-- additional domain predicates via Schema.RegisterFields(...) / Schema.RegisterAliases(...).
-- Kahlua2 / Lua 5.1 safe, zero external dependencies.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Schema = PsychopatzCore.ConvoEngine.ConvoDSLSchema or {}
PsychopatzCore.ConvoEngine.ConvoDSLSchema = Schema

local function setOf(list)
    local out = {}
    for i = 1, #list do
        out[list[i]] = true
    end
    return out
end

local STYLES = setOf({
    "neutral", "supportive", "brave", "aggressive", "shaken",
    "cold", "exhausted", "tactical", "hostile",
})
local SOCIAL_STYLES = setOf({
    "friendly", "protective", "warm", "neutral", "guarded", "withdrawn", "hostile",
})
local ACTOR_ROLES = setOf({
    "colonist", "companion", "trader", "guard", "looter", "bandit", "survivor",
})
local AGE_BANDS = setOf({ "youth", "adult", "elder" })
local REL_BONDS = setOf({
    "lover", "spouse", "parent", "child", "sibling", "family", "friend", "rival", "stranger",
})
local REL_TIERS = setOf({
    "hostile", "wary", "stranger", "acquaintance", "friendly", "trusted", "ally",
})
local IDENTITY_TRUST = setOf({
    "unknown", "claimed", "trusted", "distrusted", "untrustworthy",
})
local PLAYER_TONES = setOf({
    "neutral", "polite", "urgent", "hostile", "casual", "skeptical",
})
local POSTURES = setOf({ "standing", "sitting", "sleeping", "resting", "crouching" })
local ORDER_KINDS = setOf({ "none", "follow", "stay", "guard", "camp", "patrol" })
local MOOD_PRIMARIES = setOf({
    "calm", "cheerful", "bored", "unhappy", "hungry", "tired",
    "stressed", "in_pain", "panicked", "annoyed", "fed_up",
})
local ANNOYANCE_LEVELS = setOf({ "calm", "mild", "annoyed", "fed_up" })
local INTERJECTION_KINDS = setOf({ "calm_down", "back_up", "concern", "chime_in", "disagree" })
local PERSONALITY_BANDS = setOf({ "low", "mid", "high" })

local function spec(luaKey, valueType, allowed)
    return { luaKey = luaKey, valueType = valueType, allowed = allowed }
end

Schema.FIELDS = Schema.FIELDS or {
    -- Core routing
    ["role"] = spec("combatReactionRole", "string"),
    ["event.type"] = spec("eventType", "string"),
    ["event.horde_phase"] = spec("hordePhase", "string"),
    ["topic"] = spec("topic", "string"),
    ["intent"] = spec("intent", "string"),
    ["subject"] = spec("subject", "string"),
    ["action"] = spec("action", "string"),

    -- Speaker (actor.*)
    ["actor.style"] = spec("speakerStyle", "string", STYLES),
    ["actor.injured"] = spec("speakerInjured", "bool"),
    ["actor.social_style"] = spec("socialStyle", "string", SOCIAL_STYLES),
    ["actor.health"] = spec("healthState", "string"),
    ["actor.activity"] = spec("activity", "string"),
    ["actor.busy"] = spec("busy", "bool"),
    ["actor.role"] = spec("actorRole", "string", ACTOR_ROLES),
    ["actor.age_band"] = spec("actorAgeBand", "string", AGE_BANDS),
    ["rel.bond"] = spec("relBond", "string", REL_BONDS),

    -- Banded numeric personality dimensions (low <= 0.35, mid, high >= 0.65)
    ["personality.compassion"] = spec("personalityCompassion", "string", PERSONALITY_BANDS),
    ["personality.sociability"] = spec("personalitySociability", "string", PERSONALITY_BANDS),
    ["personality.forgiveness"] = spec("personalityForgiveness", "string", PERSONALITY_BANDS),
    ["personality.bravery"] = spec("personalityBravery", "string", PERSONALITY_BANDS),
    ["personality.materialism"] = spec("personalityMaterialism", "string", PERSONALITY_BANDS),
    ["personality.aggression"] = spec("personalityAggression", "string", PERSONALITY_BANDS),
    ["personality.loyalty"] = spec("personalityLoyalty", "string", PERSONALITY_BANDS),

    -- Partner & shared state
    ["partner.style"] = spec("partnerStyle", "string", STYLES),
    ["any.injured"] = spec("anyInjured", "bool"),
    ["any.exhausted"] = spec("anyExhausted", "bool"),

    -- Relationship (rel.* / relationship.*)
    ["rel.tier"] = spec("relationshipTier", "string", REL_TIERS),
    ["rel.state"] = spec("relationshipState", "string"),
    ["rel.identity_trust"] = spec("identityTrust", "string", IDENTITY_TRUST),
    ["rel.cross_group"] = spec("isCrossGroup", "bool"),

    -- Environment (env.* / environment.*)
    ["env.night_or_dusk"] = spec("isNightOrDusk", "bool"),
    ["env.time_band"] = spec("timeBand", "string"),
    ["env.raining"] = spec("raining", "bool"),
    ["env.foggy"] = spec("foggy", "bool"),
    ["env.snowing"] = spec("snowing", "bool"),
    ["env.indoors"] = spec("indoors", "bool"),

    -- Player input tone & register
    ["player.tone"] = spec("playerTone", "string", PLAYER_TONES),
    ["player.rude"] = spec("playerRude", "bool"),
    ["player.shouting"] = spec("playerShouting", "bool"),
    ["player.polite"] = spec("playerPolite", "bool"),

    -- Directed memories
    ["mem.has_any"] = spec("memHasAny", "bool"),
    ["mem.saved_me"] = spec("memSavedMe", "bool"),
    ["mem.fought_together"] = spec("memFoughtTogether", "bool"),
    ["mem.treated_me"] = spec("memTreatedMe", "bool"),
    ["mem.betrayed"] = spec("memBetrayed", "bool"),

    -- World & knowledge
    ["world.power_off"] = spec("worldPowerOff", "bool"),
    ["world.water_off"] = spec("worldWaterOff", "bool"),
    ["world.has_event"] = spec("worldHasEvent", "bool"),
    ["world.food_crisis"] = spec("worldFoodCrisis", "bool"),
    ["world.raider_surge"] = spec("worldRaiderSurge", "bool"),
    ["world.event_type"] = spec("worldEventType", "string"),
    ["know.has_gossip"] = spec("knowHasGossip", "bool"),
    ["place.in_settlement"] = spec("placeInSettlement", "bool"),

    -- Live posture, job & orders
    ["state.posture"] = spec("statePosture", "string", POSTURES),
    ["state.job"] = spec("stateJob", "string"),
    ["state.order_kind"] = spec("stateOrderKind", "string", ORDER_KINDS),
    ["state.already_following"] = spec("stateAlreadyFollowing", "bool"),
    ["state.sitting"] = spec("stateSitting", "bool"),
    ["state.sleeping"] = spec("stateSleeping", "bool"),
    ["state.working"] = spec("stateWorking", "bool"),

    -- Mood & patience
    ["mood.primary"] = spec("moodPrimary", "string", MOOD_PRIMARIES),
    ["mood.panicked"] = spec("moodPanicked", "bool"),
    ["mood.in_pain"] = spec("moodInPain", "bool"),
    ["mood.stressed"] = spec("moodStressed", "bool"),
    ["mood.tired"] = spec("moodTired", "bool"),
    ["mood.unhappy"] = spec("moodUnhappy", "bool"),
    ["mood.bored"] = spec("moodBored", "bool"),
    ["mood.hungry"] = spec("moodHungry", "bool"),
    ["mood.cheerful"] = spec("moodCheerful", "bool"),
    ["npc.annoyance"] = spec("npcAnnoyance", "string", ANNOYANCE_LEVELS),
    ["npc.annoyed"] = spec("npcAnnoyed", "bool"),
    ["npc.fed_up"] = spec("npcFedUp", "bool"),
    ["convo.repeat_count"] = spec("convoRepeatCount", "number"),
    ["command.redundant"] = spec("commandRedundant", "bool"),

    -- Multi-party group & shared floor
    ["group.size"] = spec("groupSize", "number"),
    ["group.broadcast"] = spec("groupBroadcast", "bool"),
    ["floor.speaker_is_npc"] = spec("floorSpeakerIsNPC", "bool"),
    ["floor.interjection_kind"] = spec("floorInterjectionKind", "string", INTERJECTION_KINDS),
    ["floor.side_with_speaker"] = spec("floorSideWithSpeaker", "bool"),
    ["floor.speaker_annoyed"] = spec("floorSpeakerAnnoyed", "bool"),
    ["floor.speaker_injured"] = spec("floorSpeakerInjured", "bool"),

    -- Needs, emotions & conversation state
    ["need.type"] = spec("needType", "string"),
    ["need.urgency"] = spec("needUrgency", "string"),
    ["emotion.type"] = spec("emotionType", "string"),
    ["emotion.urgency"] = spec("emotionUrgency", "string"),
    ["social.hostility_count"] = spec("hostilityCount", "number"),
    ["social.insult_count"] = spec("insultCount", "number"),
    ["social.role"] = spec("socialRole", "string"),
    ["social.greeting_state"] = spec("greetingState", "string"),
    ["social.farewell_speaker"] = spec("farewellSpeaker", "string"),
    ["memory.available"] = spec("memoryAvailable", "bool"),
    ["convo.pending_request"] = spec("hasPendingRequest", "bool"),
    ["convo.prev_topic"] = spec("previousTopic", "string"),
    ["convo.prev_action"] = spec("previousAction", "string"),
    ["convo.last_intent"] = spec("lastIntent", "string"),
    ["convo.last_speech_act"] = spec("lastSpeechAct", "string"),
    ["state.value"] = spec("stateValue", "string"),

    -- Trading & economy (shared for DynamicTrading & trader NPCs)
    ["trade.archetype"] = spec("tradeArchetype", "string"),
    ["trade.scarcity"] = spec("tradeScarcity", "string"),
    ["trade.price_tier"] = spec("tradePriceTier", "string"),
    ["trade.is_caravan"] = spec("tradeIsCaravan", "bool"),
    ["trade.has_stock"] = spec("tradeHasStock", "bool"),

    -- Combat, conflict, loot & medical (shared defaults; adopters may extend)
    ["combat.style"] = spec("combatReactionStyle", "string"),
    ["combat.mood"] = spec("combatReactionMood", "string"),
    ["combat.pressure"] = spec("combatPressure", "string"),
    ["combat.weapon_family"] = spec("combatWeaponFamily", "string"),
    ["combat.weapon_named"] = spec("combatWeaponNamed", "bool"),
    ["combat.skill_band"] = spec("combatSkillBand", "string"),
    ["combat.hit_zone"] = spec("combatHitZone", "string"),
    ["combat.wound_type"] = spec("combatWoundType", "string"),
    ["combat.attack_type"] = spec("combatAttackType", "string"),
    ["combat.killer_kind"] = spec("killerActorKind", "string"),
    ["conflict.assault_kind"] = spec("assaultKind", "string"),
    ["conflict.push_tier"] = spec("friendlyPushTier", "string"),
    ["downed.audience"] = spec("downedAudience", "string"),
    ["downed.need"] = spec("downedNeed", "string"),
    ["downed.threat"] = spec("downedThreat", "string"),
    ["loot.category"] = spec("lootCategory", "string"),
    ["medical.bandage_required"] = spec("medicalBandageRequired", "bool"),
    ["medical.bandage_status"] = spec("medicalBandageStatus", "string"),
    ["medical.supply_status"] = spec("medicalSupplyRequestStatus", "string"),
    ["medical.saliva_transmissible"] = spec("salivaTransmissible", "bool"),
    ["medical.is_bitten"] = spec("isBitten", "bool"),
    ["medical.open_wounds"] = spec("hasOpenWounds", "bool"),
    ["medical.knox_exposure"] = spec("knoxExposure", "string"),

    -- Mod compatibility & milestones
    ["compat.alife_kind"] = spec("projectALifeKind", "string"),
    ["compat.alife_stance"] = spec("projectALifeStance", "string"),
    ["compat.alife_conflict_dir"] = spec("projectALifeConflictDirection", "string"),
    ["compat.alife_conflict_dmg"] = spec("projectALifeConflictDamage", "string"),
    ["compat.dog_sex"] = spec("companionDogSex", "string"),
    ["compat.dog_fed"] = spec("companionDogFed", "bool"),
    ["milestone.stage"] = spec("milestoneStage", "string"),
    ["command.id"] = spec("commandID", "string"),
    ["command.reason"] = spec("commandReason", "string"),
    ["command.outcome"] = spec("commandOutcome", "string"),
    ["tool.status"] = spec("toolStatus", "string"),
    ["tool.reason"] = spec("toolReason", "string"),
    ["tool.reaction"] = spec("toolReaction", "string"),
    ["tool.subtype"] = spec("toolSubtype", "string"),
    ["tool.outcome"] = spec("toolOutcome", "string"),
    ["leader.grief"] = spec("leaderGrief", "bool"),
    ["leader.succession"] = spec("leaderSuccession", "bool"),
    ["corpse.revenge"] = spec("corpseRevenge", "bool"),
}

Schema.ALIASES = Schema.ALIASES or {
    ["relationship.tier"] = "rel.tier",
    ["relationship.state"] = "rel.state",
    ["relationship.bond"] = "rel.bond",
    ["relationship.identity_trust"] = "rel.identity_trust",
    ["relationship.cross_group"] = "rel.cross_group",
    ["environment.night_or_dusk"] = "env.night_or_dusk",
    ["environment.time_band"] = "env.time_band",
    ["environment.raining"] = "env.raining",
    ["environment.foggy"] = "env.foggy",
    ["environment.snowing"] = "env.snowing",
    ["environment.indoors"] = "env.indoors",
    ["memory.has_any"] = "mem.has_any",
    ["memory.saved_me"] = "mem.saved_me",
    ["memory.fought_together"] = "mem.fought_together",
    ["memory.treated_me"] = "mem.treated_me",
    ["memory.betrayed"] = "mem.betrayed",
    ["knowledge.has_gossip"] = "know.has_gossip",
    ["conversation.repeat_count"] = "convo.repeat_count",
    ["conversation.pending_request"] = "convo.pending_request",
    ["conversation.previous_topic"] = "convo.prev_topic",
    ["conversation.previous_action"] = "convo.prev_action",
    ["conversation.last_intent"] = "convo.last_intent",
    ["conversation.last_speech_act"] = "convo.last_speech_act",
}

function Schema.RegisterFields(fields)
    if type(fields) ~= "table" then return end
    for k, v in pairs(fields) do
        if type(k) == "string" and type(v) == "table" then
            Schema.FIELDS[k] = v
        end
    end
end

function Schema.RegisterAliases(aliases)
    if type(aliases) ~= "table" then return end
    for k, v in pairs(aliases) do
        if type(k) == "string" and type(v) == "string" then
            Schema.ALIASES[k] = v
        end
    end
end

local function trim(s)
    return string.match(tostring(s or ""), "^%s*(.-)%s*$") or ""
end

local function stripOuterQuotes(s)
    s = trim(s)
    local len = #s
    if len >= 2 then
        local first = string.sub(s, 1, 1)
        local last = string.sub(s, len, len)
        if (first == '"' and last == '"') or (first == "'" and last == "'") then
            return string.sub(s, 2, len - 1)
        end
    end
    return s
end

function Schema.ResolvePredicate(rawToken, sourceFile, lineNo)
    local token = trim(rawToken)
    if token == "" then
        return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo) .. ": empty predicate token"
    end

    local eqPos = string.find(token, "=", 1, true)
    if not eqPos then
        local negated = false
        local key = token
        if string.sub(key, 1, 1) == "!" then
            negated = true
            key = trim(string.sub(key, 2))
        end
        key = Schema.ALIASES[key] or key
        local fieldSpec = Schema.FIELDS[key]
        if not fieldSpec then
            return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                .. ": unknown context predicate '" .. key .. "'"
        end
        if fieldSpec.valueType ~= "bool" then
            return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                .. ": predicate '" .. key .. "' requires '=value' (type=" .. tostring(fieldSpec.valueType) .. ")"
        end
        return fieldSpec.luaKey, (not negated), nil
    end

    local key = trim(string.sub(token, 1, eqPos - 1))
    key = Schema.ALIASES[key] or key
    local rawVal = stripOuterQuotes(string.sub(token, eqPos + 1))
    local fieldSpec = Schema.FIELDS[key]
    if not fieldSpec then
        return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
            .. ": unknown context predicate '" .. key .. "'"
    end

    if fieldSpec.valueType == "bool" then
        local lowered = string.lower(rawVal)
        if lowered ~= "true" and lowered ~= "false" then
            return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                .. ": boolean predicate '" .. key .. "' expects true/false, got '" .. rawVal .. "'"
        end
        return fieldSpec.luaKey, (lowered == "true"), nil
    end

    local parts = {}
    if string.find(rawVal, "|", 1, true) then
        local pos = 1
        while true do
            local bar = string.find(rawVal, "|", pos, true)
            if not bar then
                parts[#parts + 1] = stripOuterQuotes(string.sub(rawVal, pos))
                break
            end
            parts[#parts + 1] = stripOuterQuotes(string.sub(rawVal, pos, bar - 1))
            pos = bar + 1
        end
    else
        parts[1] = rawVal
    end

    if fieldSpec.valueType == "number" then
        local nums = {}
        for i = 1, #parts do
            local n = tonumber(parts[i])
            if n == nil then
                return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                    .. ": predicate '" .. key .. "' expects number, got '" .. parts[i] .. "'"
            end
            nums[i] = n
        end
        return fieldSpec.luaKey, (#nums > 1 and nums or nums[1]), nil
    end

    if fieldSpec.allowed then
        for i = 1, #parts do
            if not fieldSpec.allowed[parts[i]] then
                return nil, nil, tostring(sourceFile) .. ":" .. tostring(lineNo)
                    .. ": invalid value '" .. parts[i] .. "' for '" .. key .. "'"
            end
        end
    end

    return fieldSpec.luaKey, (#parts > 1 and parts or parts[1]), nil
end

function Schema.BandPersonalityValue(value)
    local n = tonumber(value)
    if n == nil then return "mid" end
    if n <= 0.35 then return "low" end
    if n >= 0.65 then return "high" end
    return "mid"
end

function Schema.ProjectPersonalityContext(personality, outCtx)
    local ctx = type(outCtx) == "table" and outCtx or {}
    if type(personality) ~= "table" then return ctx end
    if personality.socialStyle and not ctx.socialStyle then
        ctx.socialStyle = tostring(personality.socialStyle)
    end
    ctx.personalityCompassion = Schema.BandPersonalityValue(personality.compassion)
    ctx.personalitySociability = Schema.BandPersonalityValue(personality.sociability)
    ctx.personalityForgiveness = Schema.BandPersonalityValue(personality.forgiveness)
    ctx.personalityBravery = Schema.BandPersonalityValue(personality.bravery)
    ctx.personalityMaterialism = Schema.BandPersonalityValue(personality.materialism)
    ctx.personalityAggression = Schema.BandPersonalityValue(personality.aggression)
    ctx.personalityLoyalty = Schema.BandPersonalityValue(personality.loyalty)
    return ctx
end

return Schema
