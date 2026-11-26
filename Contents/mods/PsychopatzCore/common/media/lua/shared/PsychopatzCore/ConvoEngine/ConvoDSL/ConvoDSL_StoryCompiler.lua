-- ConvoEngine: hand-written
-- Provider-neutral runtime compiler for declarative `.convo` branching `story` blocks.
-- Compiles story nodes, per-reply asymmetric personality reactions, and whitelisted `do`
-- capabilities, and routes bounded relationship/morale deltas through PsychopatzCore's
-- PsychopatzActorSocialAuthority (usable by ProjectHoomans, DynamicTrading, and any mod).
-- Kahlua2 / Lua 5.1 safe.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Compiler = PsychopatzCore.ConvoEngine.ConvoDSLStoryCompiler or {}
PsychopatzCore.ConvoEngine.ConvoDSLStoryCompiler = Compiler

Compiler._definitions = Compiler._definitions or {}
Compiler.Metadata = Compiler.Metadata or {}
Compiler._targets = Compiler._targets or {
    Catalog = nil,
    FlowRegistry = nil,
}

-- Whitelisted server-authoritative capabilities & bounded social effects
-- that `.convo` scripts may request via `do <capability> [arg]`.
-- Adopter mods may add domain-specific capabilities via Compiler.RegisterCapabilities(...).
Compiler.CAPABILITIES = Compiler.CAPABILITIES or {
    -- Companion, trader & world actions
    ["camp"] = { kind = "action", action = "CAMP" },
    ["follow"] = { kind = "action", action = "FOLLOW" },
    ["stay"] = { kind = "action", action = "STAY" },
    ["wait"] = { kind = "action", action = "WAIT" },
    ["trade"] = { kind = "action", action = "TRADE" },
    ["trade.discount"] = { kind = "action", action = "TRADE_DISCOUNT", minDelta = -15, maxDelta = 15 },
    ["trade.markup"] = { kind = "action", action = "TRADE_MARKUP", minDelta = -15, maxDelta = 15 },
    ["give_item"] = { kind = "action", action = "GIVE_ITEM" },
    ["guard_perimeter"] = { kind = "action", action = "GUARD" },
    ["medical.check_wounds"] = { kind = "action", action = "MEDICAL_CHECK" },
    ["medical.bandage"] = { kind = "action", action = "MEDICAL_BANDAGE" },
    -- Bounded social, relationship & mood effects (routed through server-authoritative social authority)
    ["relationship.approval"] = { kind = "effect", stat = "approval", minDelta = -10, maxDelta = 10, memoryBound = true },
    ["relationship.respect"] = { kind = "effect", stat = "respect", minDelta = -10, maxDelta = 10, memoryBound = true },
    ["relationship.familiarity"] = { kind = "effect", stat = "familiarity", minDelta = 0, maxDelta = 10, memoryBound = true },
    ["morale"] = { kind = "effect", stat = "morale", minDelta = -10, maxDelta = 10, memoryBound = true },
    -- Friendly aliases mapped to canonical PsychopatzCore / ProjectHoomans axes
    ["relationship.trust"] = { kind = "effect", stat = "respect", minDelta = -5, maxDelta = 5, memoryBound = true },
    ["relationship.warmth"] = { kind = "effect", stat = "approval", minDelta = -5, maxDelta = 5, memoryBound = true },
    ["mood.calm"] = { kind = "effect", mood = "calm" },
    ["mood.cheerful"] = { kind = "effect", mood = "cheerful" },
    ["mood.stressed"] = { kind = "effect", mood = "stressed" },
    ["mood.unhappy"] = { kind = "effect", mood = "unhappy" },
}

function Compiler.RegisterCapabilities(caps)
    if type(caps) ~= "table" then return end
    for k, v in pairs(caps) do
        if type(k) == "string" and type(v) == "table" then
            Compiler.CAPABILITIES[k] = v
        end
    end
end

function Compiler.BindTargets(targets)
    if type(targets) ~= "table" then return end
    if targets.Catalog ~= nil then Compiler._targets.Catalog = targets.Catalog end
    if targets.FlowRegistry ~= nil then Compiler._targets.FlowRegistry = targets.FlowRegistry end
end

local WEATHER_FIELDS = {
    raining = true,
    foggy = true,
    snowing = true,
}

local function compileActionList(rawActions, meta)
    local out = {}
    for i = 1, #(rawActions or {}) do
        local rawAct = rawActions[i]
        local spec = Compiler.CAPABILITIES[rawAct.capability]
        if not spec then
            meta._errors[#meta._errors + 1] = "unknown capability in 'do " .. tostring(rawAct.capability) .. "'"
        else
            local delta = rawAct.arg ~= nil and tonumber(rawAct.arg) or nil
            if delta ~= nil and spec.minDelta ~= nil and spec.maxDelta ~= nil then
                if delta < spec.minDelta then delta = spec.minDelta end
                if delta > spec.maxDelta then delta = spec.maxDelta end
            end
            out[#out + 1] = {
                capability = rawAct.capability,
                kind = spec.kind,
                action = spec.action,
                stat = spec.stat,
                mood = spec.mood,
                memoryBound = spec.memoryBound == true,
                delta = delta,
                arg = rawAct.arg,
            }
        end
    end
    return out
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

local function compileGate(gate)
    local gateType = WEATHER_FIELDS[gate.luaKey] and "pnc:weather" or "pnc:context"
    local field = gate.luaKey
    return {
        type = gateType,
        field = field,
        operator = "==",
        value = gate.expected,
        passReasonKey = field .. "_pass",
        failReasonKey = field .. "_fail",
        unknownReasonKey = field .. "_unknown",
    }
end

local function buildChoiceFrame(choice)
    local intent = (choice.intent and choice.intent ~= "") and choice.intent or "INFORM"
    local frame = {
        intent = intent,
        speechAct = intent,
    }
    if choice.action and choice.action ~= "" then
        frame.action = choice.action
    end
    if choice.subject and choice.subject ~= "" then
        frame.subject = choice.subject
    end
    if choice.stateValue and choice.stateValue ~= "" then
        frame.stateValue = choice.stateValue
    end
    return frame
end

local function frameSignature(frame)
    return tostring(frame.intent or "") .. "|" .. tostring(frame.speechAct or "")
        .. "|" .. tostring(frame.action or "") .. "|" .. tostring(frame.subject or "")
        .. "|" .. tostring(frame.stateValue or "")
end

local function buildOfferFromChoice(storyID, choice)
    local fullID = string.find(choice.offerID, ".", 1, true)
        and choice.offerID or (storyID .. "." .. choice.offerID)
    local frame = buildChoiceFrame(choice)
    return {
        id = fullID,
        labelKey = fullID .. ".label",
        labelFallback = choice.label ~= "" and choice.label or fullID,
        utteranceKey = fullID .. ".say",
        utteranceFallback = choice.say ~= "" and choice.say or choice.label,
        consumers = { "participant" },
        utility = choice.utility,
        aiBias = choice.aiBias,
        style = choice.style,
        when = choice.when,
        frame = frame,
    }, frame
end

local function registerNodePool(Catalog, script, storyID, node, isExtend)
    if not Catalog or type(Catalog.Register) ~= "function" then return nil end
    if #(node.variants or {}) == 0 then return node.responsePool end

    local poolID = node.responsePool or ("story." .. storyID .. "." .. node.nodeID)
    local variants = {}
    for i = 1, #node.variants do
        local var = node.variants[i]
        local vid = poolID .. "." .. var.variantID
        local tid = script.namespace .. "." .. poolID .. "." .. var.variantID
        variants[i] = {
            id = vid,
            templateID = tid,
            fallback = var.fallback,
            when = var.when,
            priority = var.priority or 6,
            hasTokens = string.find(var.fallback, "{", 1, true) ~= nil,
            theme = var.theme,
        }
    end

    local existingPool = nil
    if isExtend then
        if type(Catalog.GetRaw) == "function" then
            existingPool = Catalog.GetRaw(poolID)
        elseif type(Catalog.POOLS) == "table" then
            existingPool = Catalog.POOLS[tostring(poolID or "")]
        elseif type(Catalog.Get) == "function" then
            existingPool = Catalog.Get(poolID)
        end
    end
    if isExtend and existingPool ~= nil
        and type(Catalog.Extend) == "function"
    then
        Catalog.Extend(poolID, { variants = variants })
    else
        Catalog.Register(poolID, { variants = variants })
    end
    return poolID
end

local function mergeNodeInto(existingNode, incomingNode, storyID, meta, blueprintRawByID)
    existingNode.terminal = incomingNode.terminal or existingNode.terminal == true
    if incomingNode.responsePool then
        existingNode.responsePool = incomingNode.responsePool
    end
    if incomingNode.gate then
        existingNode.gate = compileGate(incomingNode.gate)
        existingNode.onPass = incomingNode.gate.onPass
        existingNode.onFail = incomingNode.gate.onFail
        existingNode.onUnknown = incomingNode.gate.onUnknown
    end

    local allChoices = {}
    for i = 1, #(incomingNode.choices or {}) do
        allChoices[#allChoices + 1] = incomingNode.choices[i]
    end
    if type(blueprintRawByID) == "table" then
        for i = 1, #(incomingNode.uses or {}) do
            local bpOffers = blueprintRawByID[incomingNode.uses[i]]
            if type(bpOffers) == "table" then
                for j = 1, #bpOffers do
                    allChoices[#allChoices + 1] = bpOffers[j]
                end
            end
        end
    end

    if #allChoices > 0 then
        existingNode.branchOffers = existingNode.branchOffers or {}
        existingNode.accepts = existingNode.accepts or {}
        local seenOffer = {}
        for i = 1, #existingNode.branchOffers do
            seenOffer[existingNode.branchOffers[i].id] = true
        end
        local seenFrame = {}
        for i = 1, #existingNode.accepts do
            seenFrame[frameSignature(existingNode.accepts[i])] = true
        end

        for i = 1, #allChoices do
            local ch = allChoices[i]
            local offer, frame = buildOfferFromChoice(storyID, ch)
            if not seenOffer[offer.id] then
                seenOffer[offer.id] = true
                existingNode.branchOffers[#existingNode.branchOffers + 1] = offer
            end
            local sig = frameSignature(frame)
            if not seenFrame[sig] then
                seenFrame[sig] = true
                existingNode.accepts[#existingNode.accepts + 1] = frame
            end
            if ch.target and ch.target ~= "" then
                existingNode.choiceTargets = existingNode.choiceTargets or {}
                existingNode.choiceTargets[offer.id] = ch.target
                meta.choiceTargets[existingNode.id .. ":" .. offer.id] = ch.target
                if frame.intent == "REFUSE" then
                    existingNode.onRefuse = existingNode.onRefuse or ch.target
                elseif (frame.intent == "QUESTION" or frame.intent == "CLARIFY")
                    and not existingNode.onClarify
                then
                    existingNode.onClarify = ch.target
                else
                    existingNode.onMatch = existingNode.onMatch or ch.target
                end
            end
        end
    end

    for trKey, trVal in pairs(incomingNode.transitions or {}) do
        existingNode[trKey] = trVal
    end
    if not existingNode.terminal and not existingNode.gate
        and existingNode.onUnrelated == nil
    then
        existingNode.onUnrelated = "suspend"
    end

    if #(incomingNode.actions or {}) > 0 then
        meta.actions[existingNode.id] = meta.actions[existingNode.id] or {}
        local actList = meta.actions[existingNode.id]
        local compiled = compileActionList(incomingNode.actions, meta)
        for i = 1, #compiled do
            actList[#actList + 1] = compiled[i]
        end
    end

    if #(incomingNode.reactions or {}) > 0 then
        meta.reactions = meta.reactions or {}
        meta.reactions[existingNode.id] = meta.reactions[existingNode.id] or {}
        local rList = meta.reactions[existingNode.id]
        for i = 1, #incomingNode.reactions do
            local r = incomingNode.reactions[i]
            local nextNode = (r.transitions and r.transitions.next) or r.followUpNodeID or nil
            if nextNode and nextNode ~= "" then
                existingNode.choiceTargets = existingNode.choiceTargets or {}
                existingNode.choiceTargets["__reaction:" .. r.reactionID] = nextNode
                existingNode.terminal = false
                existingNode.accepts = existingNode.accepts or {}
                if #existingNode.accepts == 0 then
                    existingNode.accepts[1] = { intent = "INFORM", speechAct = "INFORM" }
                end
            end
            rList[#rList + 1] = {
                reactionID = r.reactionID,
                when = r.when,
                priority = r.priority or 6,
                variants = r.variants or {},
                actions = compileActionList(r.actions, meta),
                recommends = r.recommends or {},
                nextNode = nextNode,
                terminal = r.terminal == true or (nextNode == nil),
            }
        end
    end

    if #(incomingNode.recommends or {}) > 0 then
        meta.recommends[existingNode.id] = meta.recommends[existingNode.id] or {}
        local list = meta.recommends[existingNode.id]
        for i = 1, #incomingNode.recommends do
            list[#list + 1] = incomingNode.recommends[i]
        end
    end
end

function Compiler.ApplyStories(scripts, blueprintRawByID, targets)
    local Catalog = (type(targets) == "table" and targets.Catalog) or Compiler._targets.Catalog
    local FlowRegistry = (type(targets) == "table" and targets.FlowRegistry) or Compiler._targets.FlowRegistry

    local storyCount = 0
    local extendedCount = 0
    local errors = {}

    for sIdx = 1, #scripts do
        local script = scripts[sIdx]
        for i = 1, #(script.stories or {}) do
            local st = script.stories[i]
            local isExtend = st.mode == "extend"
            local def = isExtend and Compiler._definitions[st.storyID] or nil
            local meta = Compiler.Metadata[st.storyID]
            if not def then
                def = {
                    id = st.storyID,
                    version = 1,
                    owner = script.pack or script.namespace or "PsychopatzCore",
                    triggers = {},
                    initial = st.initial,
                    nodes = {},
                }
                meta = {
                    guards = {},
                    choiceTargets = {},
                    actions = {},
                    reactions = {},
                    recommends = {},
                    _errors = {},
                }
            end

            for tIdx = 1, #(st.triggers or {}) do
                def.triggers[#def.triggers + 1] = st.triggers[tIdx]
            end
            for gIdx = 1, #(st.guards or {}) do
                meta.guards[#meta.guards + 1] = st.guards[gIdx]
            end
            if st.initial and st.initial ~= "" then
                def.initial = st.initial
            end

            for nIdx = 1, #(st.nodes or {}) do
                local node = st.nodes[nIdx]
                local poolID = registerNodePool(Catalog, script, st.storyID, node, isExtend)
                node.responsePool = poolID
                local targetNode = def.nodes[node.nodeID]
                if not targetNode then
                    targetNode = { id = node.nodeID, terminal = node.terminal == true }
                    def.nodes[node.nodeID] = targetNode
                end
                if not def.initial then
                    def.initial = node.nodeID
                end
                mergeNodeInto(targetNode, node, st.storyID, meta, blueprintRawByID)
            end

            Compiler._definitions[st.storyID] = def
            Compiler.Metadata[st.storyID] = meta

            for eIdx = 1, #(meta._errors or {}) do
                errors[#errors + 1] = tostring(script.sourcePath) .. ":" .. tostring(st.lineNo)
                    .. ": " .. meta._errors[eIdx]
            end
            meta._errors = {}

            if FlowRegistry and type(FlowRegistry.UpsertStory) == "function" then
                local ok, res = FlowRegistry.UpsertStory(def)
                if not ok then
                    errors[#errors + 1] = tostring(script.sourcePath) .. ":" .. tostring(st.lineNo)
                        .. ": story '" .. st.storyID .. "' invalid (" .. tostring(res) .. ")"
                elseif isExtend then
                    extendedCount = extendedCount + 1
                else
                    storyCount = storyCount + 1
                end
            elseif isExtend then
                extendedCount = extendedCount + 1
            else
                storyCount = storyCount + 1
            end
        end
    end

    return storyCount, extendedCount, errors
end

function Compiler.GetStory(storyID)
    return Compiler._definitions[tostring(storyID or "")]
end

function Compiler.ResolveReaction(storyID, nodeID, context, opts)
    local meta = Compiler.Metadata[tostring(storyID or "")]
    local def = Compiler._definitions[tostring(storyID or "")]
    if type(meta) ~= "table" then return nil end

    local nodeKey = tostring(nodeID or "")
    local rList = meta.reactions and meta.reactions[nodeKey]
    local matched = nil
    local bestPri = -math.huge

    if type(rList) == "table" then
        for i = 1, #rList do
            local r = rList[i]
            if matchesWhen(r.when, context) then
                local pri = tonumber(r.priority) or 1
                if pri > bestPri then
                    matched = r
                    bestPri = pri
                end
            end
        end
    end

    local nodeActions = (meta.actions and meta.actions[nodeKey]) or {}
    local nodeRecommends = (meta.recommends and meta.recommends[nodeKey]) or {}

    local actions = {}
    if matched and #(matched.actions or {}) > 0 then
        for i = 1, #matched.actions do actions[#actions + 1] = matched.actions[i] end
    else
        for i = 1, #nodeActions do actions[#actions + 1] = nodeActions[i] end
    end

    local recommends = {}
    if matched and #(matched.recommends or {}) > 0 then
        for i = 1, #matched.recommends do recommends[#recommends + 1] = matched.recommends[i] end
    else
        for i = 1, #nodeRecommends do recommends[#recommends + 1] = nodeRecommends[i] end
    end

    local line = nil
    if matched and #(matched.variants or {}) > 0 then
        local idx = 1
        if #matched.variants > 1 and type(opts) == "table" and opts.seed then
            local h = 0
            local s = tostring(opts.seed)
            for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 2147483647 end
            idx = (h % #matched.variants) + 1
        end
        line = matched.variants[idx]
    end

    local nextNode = matched and matched.nextNode or nil
    local followUpOffers = nil
    if nextNode and def and def.nodes and def.nodes[nextNode] then
        followUpOffers = def.nodes[nextNode].branchOffers
    elseif def and def.nodes and def.nodes[nodeKey] then
        followUpOffers = def.nodes[nodeKey].branchOffers
    end

    return {
        reactionID = matched and matched.reactionID or nil,
        line = line,
        actions = actions,
        recommends = recommends,
        nextNode = nextNode,
        terminal = (matched and matched.terminal == true and not (followUpOffers and #followUpOffers > 0))
            or (not nextNode and not (followUpOffers and #followUpOffers > 0)),
        followUpOffers = followUpOffers,
    }
end

-- Applies a resolved reaction's bounded relationship/morale deltas through
-- PsychopatzCore's server-authoritative ActorSocialAuthority (or an explicit sink).
-- Works identically for ProjectHoomans NPCs, DynamicTrading traders, and any Core actor.
function Compiler.ApplyReactionEffects(actorID, targetKey, reaction, opts)
    opts = type(opts) == "table" and opts or {}
    if type(reaction) ~= "table" or #(reaction.actions or {}) == 0 then
        return true, { applied = 0, deltas = {} }
    end

    local deltas = { approval = 0, respect = 0, familiarity = 0, morale = 0 }
    local hasRelDelta = false
    local nonRelActions = {}

    for i = 1, #reaction.actions do
        local act = reaction.actions[i]
        if act.kind == "effect" and act.stat and act.delta ~= nil and deltas[act.stat] ~= nil then
            deltas[act.stat] = deltas[act.stat] + act.delta
            hasRelDelta = true
        else
            nonRelActions[#nonRelActions + 1] = act
        end
    end

    if not hasRelDelta then
        return true, { applied = 0, deltas = deltas, actions = nonRelActions }
    end

    if type(opts.sink) == "function" then
        local ok, res = opts.sink(actorID, targetKey, deltas, reaction, opts)
        return ok, { applied = ok and 1 or 0, deltas = deltas, actions = nonRelActions, result = res }
    end

    local okAuth, SocialAuthority = pcall(require, "PsychopatzCore/Actors/PsychopatzActorSocialAuthority")
    if not okAuth or type(SocialAuthority) ~= "table" or type(SocialAuthority.MutateRelationship) ~= "function" then
        return false, "social_authority_unavailable"
    end

    local function clamp(v, lo, hi)
        if v < lo then return lo end
        if v > hi then return hi end
        return v
    end

    local committed, reason = SocialAuthority.MutateRelationship(actorID, targetKey, function(rel)
        rel.approval = clamp((tonumber(rel.approval) or 0) + deltas.approval, -100, 100)
        rel.respect = clamp((tonumber(rel.respect) or 0) + deltas.respect, -100, 100)
        rel.familiarity = clamp((tonumber(rel.familiarity) or 0) + deltas.familiarity, 0, 100)
        rel.morale = clamp((tonumber(rel.morale) or 0) + deltas.morale, -100, 100)
        return rel
    end, opts.core)

    if not committed then
        return false, reason
    end
    return true, { applied = 1, deltas = deltas, actions = nonRelActions, actor = committed }
end

function Compiler.Reset()
    for k in pairs(Compiler._definitions) do
        Compiler._definitions[k] = nil
    end
    for k in pairs(Compiler.Metadata) do
        Compiler.Metadata[k] = nil
    end
end

return Compiler
