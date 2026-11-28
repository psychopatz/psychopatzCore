-- Relational & state-driven desperation/hostility evaluator for PsychopatzCore.
-- Shared by ProjectHoomans and DynamicTrading so hostility is never hardcoded
-- solely to a "LOOTER" label:
--   - Looters specifically target settlements and active supply corridors.
--   - Refugees & Scavengers can turn hostile when faction relations are poor
--     OR when starvation/desperation pushes them into opportunistic holdups,
--     and calm back down once resupplied.

local Diplomacy = {}

Diplomacy.DESPERATION_HOSTILE_THRESHOLD = 0.72
Diplomacy.RELATION_HOSTILE_THRESHOLD = -35
Diplomacy.RELATION_FRIENDLY_THRESHOLD = 20

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function normalizeType(raw)
    return string.upper(tostring(raw or "DEFAULT"))
end

function Diplomacy.IsLooterType(groupType)
    local t = normalizeType(groupType)
    return t == "LOOTER" or t == "RAIDER" or t == "BANDIT"
end

-- Computes a 0..1 desperation score from abstracted food/water scarcity,
-- hunger/thirst/fatigue needs, and low morale.
function Diplomacy.ComputeDesperation(group)
    if type(group) ~= "table" then return 0 end
    local score = 0
    local res = type(group.resources) == "table" and group.resources or nil
    if res then
        local food = tonumber(res.food)
        local water = tonumber(res.water)
        if food ~= nil then
            if food <= 5 then score = score + 0.45
            elseif food <= 15 then score = score + 0.25 end
        end
        if water ~= nil then
            if water <= 5 then score = score + 0.35
            elseif water <= 15 then score = score + 0.18 end
        end
    end
    local needs = type(group.needs) == "table" and group.needs or nil
    if needs then
        local hunger = clamp(needs.hunger or 0, 0, 1)
        local thirst = clamp(needs.thirst or 0, 0, 1)
        local morale = clamp(needs.morale ~= nil and needs.morale or 0.6, 0, 1)
        if hunger >= 0.70 then score = score + 0.25 end
        if thirst >= 0.70 then score = score + 0.20 end
        if morale <= 0.25 then score = score + 0.18 end
    end
    if group.displacedFromSettlement == true then
        score = score + 0.12
    end
    return clamp(score, 0, 1)
end

-- Evaluates the emergent encounter stance between two groups (or a group and a
-- settlement/target). Returns:
--   stance: "ALLIED" | "FRIENDLY" | "NEUTRAL" | "DESPERATE_HOSTILE" | "RAID_HOSTILE" | "HOSTILE"
--   isHostile: boolean
--   reason: string
function Diplomacy.EvaluateEncounterStance(actorA, actorB, relationScore)
    actorA = type(actorA) == "table" and actorA or {}
    actorB = type(actorB) == "table" and actorB or {}
    local rel = tonumber(relationScore) or 0

    if actorA.factionId and actorB.factionId
        and tostring(actorA.factionId) == tostring(actorB.factionId)
    then
        return "ALLIED", false, "same_faction"
    end

    if rel <= Diplomacy.RELATION_HOSTILE_THRESHOLD then
        return "HOSTILE", true, "faction_hostility"
    end

    local typeA = normalizeType(actorA.groupType or actorA.archetype or actorA.type)
    local typeB = normalizeType(actorB.groupType or actorB.archetype or actorB.type)

    -- Looters specifically raid settlements and prey on traders/scavengers unless allied.
    if Diplomacy.IsLooterType(typeA) or Diplomacy.IsLooterType(typeB) then
        if rel < Diplomacy.RELATION_FRIENDLY_THRESHOLD then
            if typeA == "SETTLEMENT" or typeB == "SETTLEMENT"
                or typeA == "TRADER" or typeB == "TRADER"
                or typeA == "SCAVENGER" or typeB == "SCAVENGER"
            then
                return "RAID_HOSTILE", true, "looter_predation"
            end
            return "HOSTILE", true, "looter_aggression"
        end
    end

    -- Relational + state-driven desperation flip: starving/cornered Refugees or
    -- Scavengers can turn desperate and hostile if not friendly with the other side.
    local despA = Diplomacy.ComputeDesperation(actorA)
    local despB = Diplomacy.ComputeDesperation(actorB)
    local maxDesp = math.max(despA, despB)
    if maxDesp >= Diplomacy.DESPERATION_HOSTILE_THRESHOLD and rel < 15 then
        return "DESPERATE_HOSTILE", true, "desperation_flip"
    end

    if rel >= Diplomacy.RELATION_FRIENDLY_THRESHOLD then
        return "FRIENDLY", false, "friendly_relations"
    end

    return "NEUTRAL", false, "cautious_neutral"
end

return Diplomacy
