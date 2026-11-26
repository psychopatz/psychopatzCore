-- ConvoEngine: hand-written
-- Provider-neutral actor-agnostic offer realizer and CK3-style AI choice scorer.
-- Shared across ProjectHoomans, DynamicTrading, and any PsychopatzCore adopter mod.
-- Kahlua2 / Lua 5.1 safe.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Realizer = PsychopatzCore.ConvoEngine.OfferRealizer or {}
PsychopatzCore.ConvoEngine.OfferRealizer = Realizer

Realizer._stores = Realizer._stores or {
    OfferBlueprints = {},
    GeneratedOffers = {},
    GeneratedOfferUses = {},
    Lexicon = nil,
}

function Realizer.BindStores(stores)
    if type(stores) ~= "table" then return end
    if stores.OfferBlueprints then Realizer._stores.OfferBlueprints = stores.OfferBlueprints end
    if stores.GeneratedOffers then Realizer._stores.GeneratedOffers = stores.GeneratedOffers end
    if stores.GeneratedOfferUses then Realizer._stores.GeneratedOfferUses = stores.GeneratedOfferUses end
    if stores.Lexicon then Realizer._stores.Lexicon = stores.Lexicon end
end

local function matchesWhen(when, ctx)
    if type(when) ~= "table" then return true end
    if type(ctx) ~= "table" then return false end
    for k, expected in pairs(when) do
        local actual = ctx[k]
        if type(expected) == "table" then
            local matched = false
            local actualStr = tostring(actual or "")
            for i = 1, #expected do
                if actualStr == tostring(expected[i]) then
                    matched = true
                    break
                end
            end
            if not matched then return false end
        elseif type(expected) == "boolean" then
            if (actual == true) ~= expected then return false end
        elseif tostring(actual or "") ~= tostring(expected) then
            return false
        end
    end
    return true
end

local function expandText(text, context, tokens, opts)
    local lex = (type(opts) == "table" and opts.lexicon) or Realizer._stores.Lexicon
    if type(lex) == "table" and type(lex.Expand) == "function" then
        return lex.Expand(text or "", context, tokens, opts)
    end
    return tostring(text or "")
end

local function expandOffer(offer, context, tokens, opts)
    local lang = type(opts) == "table" and opts.language or nil
    local salt = (type(opts) == "table" and opts.salt or "") .. ":" .. tostring(offer.id or "")
    local expOpts = { language = lang, salt = salt, lexicon = type(opts) == "table" and opts.lexicon or nil }
    local label = expandText(offer.label or offer.labelFallback or "", context, tokens, expOpts)
    local say = expandText(offer.say or offer.utteranceFallback or "", context, tokens, expOpts)
    return {
        id = offer.id,
        label = label,
        say = say,
        intent = offer.intent,
        subject = offer.subject,
        claim = offer.claim,
        style = offer.style,
        utility = offer.utility,
        aiBias = offer.aiBias,
        when = offer.when,
    }
end

function Realizer.BuildForPool(poolID, context, tokens, opts)
    opts = type(opts) == "table" and opts or {}
    local maxOffers = tonumber(opts.maxOffers) or 6
    local out = {}
    local seen = {}

    local function collectList(list)
        if type(list) ~= "table" then return end
        for i = 1, #list do
            if #out >= maxOffers then return end
            local offer = list[i]
            if type(offer) == "table" and offer.id and not seen[offer.id] then
                if matchesWhen(offer.when, context) then
                    seen[offer.id] = true
                    out[#out + 1] = expandOffer(offer, context, tokens, opts)
                end
            end
        end
    end

    local genOffers = opts.generatedOffers or Realizer._stores.GeneratedOffers or {}
    local genUses = opts.generatedOfferUses or Realizer._stores.GeneratedOfferUses or {}
    local blueprints = opts.offerBlueprints or Realizer._stores.OfferBlueprints or {}

    collectList(genOffers[tostring(poolID or "")])
    local uses = genUses[tostring(poolID or "")]
    if type(uses) == "table" then
        for i = 1, #uses do
            collectList(blueprints[uses[i]])
        end
    end
    return out
end

local function clamp01(v, fallback)
    local n = tonumber(v)
    if n == nil then return fallback end
    if n < 0 then return 0 end
    if n > 1 then return 1 end
    return n
end

local function hashUnit(seedStr)
    local h = 2166136261
    local s = tostring(seedStr or "")
    for i = 1, #s do
        h = (h * 33 + string.byte(s, i)) % 2147483647
    end
    return (h % 100000) / 100000
end

local function evaluateBiasToken(token, axes, context)
    local sign = string.sub(token, -1)
    local key = token
    local positive = true
    if sign == "+" then
        key = string.sub(token, 1, -2)
        positive = true
    elseif sign == "-" then
        key = string.sub(token, 1, -2)
        positive = false
    end

    if axes[key] ~= nil then
        local v = axes[key]
        return positive and (v - 0.5) * 0.8 or (0.5 - v) * 0.8
    end

    if key == "stressed" then
        local active = context.moodStressed == true or context.moodPrimary == "stressed"
        return active and (positive and 0.35 or -0.25) or 0
    elseif key == "tired" then
        local active = context.moodTired == true or context.moodPrimary == "tired"
        return active and (positive and 0.30 or -0.20) or 0
    elseif key == "cheerful" then
        local active = context.moodCheerful == true or context.moodPrimary == "cheerful"
        return active and (positive and 0.30 or -0.20) or 0
    elseif key == "unhappy" then
        local active = context.moodUnhappy == true or context.moodPrimary == "unhappy"
        return active and (positive and 0.30 or -0.20) or 0
    elseif key == "in_pain" then
        local active = context.moodInPain == true or context.moodPrimary == "in_pain"
        return active and (positive and 0.30 or -0.20) or 0
    elseif key == "friend" then
        local active = context.relationshipState == "friend"
            or context.relationshipTier == "friendly"
            or context.relationshipTier == "trusted"
            or context.relationshipTier == "ally"
        return active and (positive and 0.35 or -0.30) or 0
    elseif key == "rival" then
        local active = context.relationshipState == "rival"
            or context.relationshipState == "enemy"
            or context.relationshipTier == "hostile"
            or context.relationshipTier == "wary"
        return active and (positive and 0.35 or -0.30) or 0
    elseif key == "tactical" then
        local active = context.speakerStyle == "tactical" or context.actorRole == "guard"
        return active and (positive and 0.35 or -0.25) or 0
    elseif key == "trader" then
        local active = context.actorRole == "trader"
        return active and (positive and 0.40 or -0.20) or 0
    elseif key == "protective" then
        local active = context.socialStyle == "protective" or context.speakerStyle == "supportive"
        return active and (positive and 0.35 or -0.25) or 0
    elseif key == "guarded" then
        local active = context.socialStyle == "guarded" or context.socialStyle == "withdrawn"
            or context.speakerStyle == "cold"
        return active and (positive and 0.30 or -0.20) or 0
    elseif key == "warm" then
        local active = context.socialStyle == "warm" or context.socialStyle == "friendly"
        return active and (positive and 0.30 or -0.20) or 0
    end
    return 0
end

function Realizer.ScoreOffer(offer, disposition, context)
    if type(offer) ~= "table" then return 0 end
    disposition = type(disposition) == "table" and disposition or {}
    context = type(context) == "table" and context or {}

    local axes = {
        compassion = clamp01(disposition.compassion, 0.5),
        sociability = clamp01(disposition.sociability, 0.5),
        forgiveness = clamp01(disposition.forgiveness, 0.5),
        bravery = clamp01(disposition.bravery, 0.5),
        materialism = clamp01(disposition.materialism, 0.5),
        aggression = clamp01(disposition.aggression, 0.4),
        loyalty = clamp01(disposition.loyalty, 0.5),
    }

    local u = tostring(offer.utility or "")
    local score = 0.5
    if u == "openness" or u == "compassion" then
        score = axes.sociability * 0.50 + axes.compassion * 0.50
    elseif u == "deception" then
        score = (1 - axes.compassion) * 0.45 + axes.aggression * 0.30 + axes.bravery * 0.25
    elseif u == "caution" then
        score = (1 - axes.sociability) * 0.45 + (1 - axes.aggression) * 0.25
            + (context.isNightOrDusk and 0.20 or 0.10)
    elseif u == "assertive" then
        score = axes.bravery * 0.50 + axes.aggression * 0.50
    elseif u == "materialism" or u == "trade" then
        score = axes.materialism * 0.65 + axes.sociability * 0.35
    elseif u == "loyalty" or u == "protective" then
        score = axes.loyalty * 0.55 + axes.compassion * 0.45
    elseif u == "forgiveness" or u == "deescalate" then
        score = axes.forgiveness * 0.60 + axes.compassion * 0.40
    end

    local biasStr = offer.aiBias
    if type(biasStr) == "string" and biasStr ~= "" then
        local biasSum = 0
        local biasCount = 0
        for token in string.gmatch(biasStr, "[^|,;%s]+") do
            biasSum = biasSum + evaluateBiasToken(token, axes, context)
            biasCount = biasCount + 1
        end
        if biasCount > 0 then
            score = score + (biasSum / math.sqrt(biasCount))
        end
    end

    local relApproval = tonumber(context.relationshipApproval)
    if relApproval ~= nil then
        local normApp = relApproval / 100
        if u == "openness" or u == "compassion" or u == "loyalty" then
            score = score + normApp * 0.20
        elseif u == "assertive" or u == "deception" then
            score = score - normApp * 0.20
        end
    end

    if score < 0.01 then score = 0.01 end
    return score
end

function Realizer.PickAutonomous(offers, disposition, context, opts)
    if type(offers) ~= "table" or #offers == 0 then return nil end
    disposition = type(disposition) == "table" and disposition or {}
    context = type(context) == "table" and context or {}
    opts = type(opts) == "table" and opts or {}

    local scored = {}
    local totalWeight = 0
    local best, bestScore = nil, -math.huge

    for i = 1, #offers do
        local o = offers[i]
        if type(o) == "table" and matchesWhen(o.when, context) then
            local s = Realizer.ScoreOffer(o, disposition, context)
            scored[#scored + 1] = { offer = o, score = s }
            local w = s * s * s
            totalWeight = totalWeight + w
            if s > bestScore then
                best, bestScore = o, s
            end
        end
    end

    if #scored == 0 then return nil end
    if opts.deterministic == true or opts.seed == nil or opts.seed == "" or totalWeight <= 0 then
        return best
    end

    local roll = hashUnit(opts.seed) * totalWeight
    local acc = 0
    for i = 1, #scored do
        local entry = scored[i]
        acc = acc + (entry.score * entry.score * entry.score)
        if roll <= acc then
            return entry.offer
        end
    end
    return best
end

return Realizer
