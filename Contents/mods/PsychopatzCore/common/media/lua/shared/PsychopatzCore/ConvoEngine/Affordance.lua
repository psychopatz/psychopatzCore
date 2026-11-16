-- ConvoEngine: hand-written
-- Core-owned ConvoEngine exchange-family affordance, slot, reply, and continuation evaluator.
--
-- Evaluates compiled exchangeFamily records from generated Conversation registries
-- with strict text-role separation (button_label vs spoken_action vs response),
-- single-slot candidate expansion, shared player/NPC affordance scoring,
-- and bounded after.recommend / after.goto chaining.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Semantics = PsychopatzCore.Semantics
local ConvoEngine = PsychopatzCore.ConvoEngine
local Affordance = ConvoEngine.Affordance or {}
ConvoEngine.Affordance = Affordance

local Predicate = Semantics.Predicate
    or require "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"
local TextBinding = ConvoEngine.TextBinding
    or require "PsychopatzCore/ConvoEngine/TextBinding"
local Offer = ConvoEngine.Offer
    or require "PsychopatzCore/ConvoEngine/Offer"

Affordance.VERSION = 1
Affordance.MAX_AFTER_HOPS = 4
Affordance.MAX_RECOMMEND = Offer.MAX_OFFERS or 8
Affordance.DEFAULT_SLOT_LIMIT = 4

local function sortedKeys(tbl)
    local keys = {}
    if type(tbl) ~= "table" then return keys end
    for k in pairs(tbl) do
        keys[#keys + 1] = tostring(k)
    end
    table.sort(keys)
    return keys
end

local function tableHasEntries(tbl)
    if type(tbl) ~= "table" then return false end
    for _ in pairs(tbl) do
        return true
    end
    return false
end

local function cloneShallow(tbl)
    if type(tbl) ~= "table" then return {} end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

local function activeRegistry(options)
    if type(options) == "table" and type(options.registry) == "table" then
        return options.registry
    end
    if type(ConvoEngine.Foundation) == "table" and type(ConvoEngine.Foundation.Registry) == "table" then
        return ConvoEngine.Foundation.Registry
    end
    return require "PsychopatzCore/ConvoEngine/FoundationRegistry"
end

local function activeLanguage(options)
    local lang = type(options) == "table" and options.language or nil
    if type(lang) == "string" and lang ~= "" then
        return string.upper(lang)
    end
    return "EN"
end

local function stableIndex(seed, count)
    if count <= 1 then return 1 end
    local text = tostring(seed or "")
    local acc = 0
    for i = 1, #text do
        acc = (acc * 31 + string.byte(text, i)) % 2147483647
    end
    return (acc % count) + 1
end

local function hasConsumer(consumers, wanted)
    if type(consumers) ~= "table" or #consumers == 0 then
        return wanted == "participant" or wanted == "player" or wanted == "npc"
    end
    wanted = tostring(wanted or "participant")
    for _, entry in ipairs(consumers) do
        if entry == wanted then return true end
        if entry == "participant" and (wanted == "player" or wanted == "npc") then
            return true
        end
    end
    return false
end

function Affordance.SupportsConsumer(planOrFamily, consumer)
    local family = type(planOrFamily) == "table"
        and (planOrFamily.exchangeFamily or planOrFamily)
        or nil
    if type(family) ~= "table" or type(family.affordance) ~= "table" then
        return false
    end
    return hasConsumer(family.affordance.consumers, consumer)
end

local function evalPredicate(predicate, context)
    if predicate == nil then return true, "unconstrained" end
    local result = Predicate.Evaluate(predicate, context or {})
    return result.allowed == true, result.reason or result.status
end

local function hasAnyGroup(actual, wanted)
    if type(wanted) ~= "table" or #wanted == 0 then return true end
    if type(actual) ~= "table" or #actual == 0 then return false end
    local lookup = {}
    for _, item in ipairs(actual) do
        lookup[tostring(item)] = true
    end
    for _, item in ipairs(wanted) do
        if lookup[tostring(item)] then return true end
    end
    return false
end

local function resolveLocalizedList(translations, fallback, language, seed, explicitIndex)
    local tbl = type(translations) == "table" and translations or {}
    local list = tbl[language] or tbl.EN
    if type(list) == "table" and #list > 0 then
        local idx = tonumber(explicitIndex)
        if not idx then
            idx = stableIndex(seed, #list)
        else
            idx = ((math.floor(idx) - 1) % #list) + 1
        end
        return list[idx]
    end
    if type(list) == "string" and list ~= "" then
        return list
    end
    return type(fallback) == "string" and fallback ~= "" and fallback or nil
end

local function selectRealizationTemplate(sayBlock, options)
    if type(sayBlock) ~= "table" or type(sayBlock.realizations) ~= "table" then
        return nil
    end
    local rkey = tostring((type(options) == "table" and options.realizationKey) or "")
    local keyOrder = type(sayBlock.keyOrder) == "table" and sayBlock.keyOrder or nil
    if rkey == "" then
        if keyOrder and #keyOrder > 0 then
            local seed = type(options) == "table" and options.seed or ""
            if type(options) == "table" and options.realizationIndex ~= nil then
                local idx = ((math.floor(tonumber(options.realizationIndex) or 1) - 1) % #keyOrder) + 1
                rkey = tostring(keyOrder[idx])
            else
                rkey = tostring(keyOrder[stableIndex(seed, #keyOrder)])
            end
        else
            rkey = "1"
        end
    end
    local realization = sayBlock.realizations[rkey] or sayBlock.realizations["1"]
    if type(realization) ~= "table" or type(realization.variants) ~= "table" then
        return nil
    end
    local wanted = tostring((type(options) == "table" and options.style) or "neutral")
    local chosen, neutralVar = nil, nil
    for _, v in ipairs(realization.variants) do
        if type(v) == "table" then
            if tostring(v.id or "") == wanted then chosen = v break end
            if neutralVar == nil and tostring(v.id or "") == "neutral" then neutralVar = v end
        end
    end
    return chosen or neutralVar or realization.variants[1], rkey
end

local function renderTemplateText(rawText, context, bindings)
    if type(rawText) ~= "string" or rawText == "" then
        return nil, "role_text_missing"
    end
    if string.find(rawText, "{", 1, true) then
        return TextBinding.Render(rawText, context or {}, bindings)
    end
    return rawText
end

function Affordance.RenderRoleText(planOrFamily, role, context, options)
    local family = type(planOrFamily) == "table"
        and (planOrFamily.exchangeFamily or planOrFamily)
        or nil
    if type(family) ~= "table" then
        return nil, "exchange_family_missing"
    end
    local language = activeLanguage(options)
    local seed = type(options) == "table" and options.seed or family.familyID
    local explicitIndex = type(options) == "table" and options.index or nil
    local bindings = family.bindings

    if role == "button_label" then
        local aff = family.affordance
        if type(aff) ~= "table" then
            return nil, "button_label_missing"
        end
        local raw = resolveLocalizedList(aff.translations, aff.labelFallback, language, seed, 1)
        if not raw then return nil, "button_label_missing" end
        return renderTemplateText(raw, context, bindings)
    elseif role == "spoken_action" then
        local chosen = selectRealizationTemplate(family.initiatingSay, options)
        if type(chosen) ~= "table" then
            return nil, "spoken_action_missing"
        end
        local raw = resolveLocalizedList(chosen.translations, chosen.fallback, language, seed, explicitIndex)
        if not raw then return nil, "spoken_action_missing" end
        return renderTemplateText(raw, context, bindings)
    elseif role == "response" then
        local outcome = type(options) == "table" and tostring(options.outcome or "") or ""
        local replies = type(family.replies) == "table" and family.replies or nil
        local branch = replies and replies[outcome] or nil
        if type(branch) ~= "table" then
            return nil, "response_outcome_missing"
        end
        local chosen = nil
        if type(branch.say) == "table" then
            chosen = selectRealizationTemplate(branch.say, options)
        elseif type(branch.variants) == "table" then
            local wanted = tostring((type(options) == "table" and options.style) or "neutral")
            local neutralVar = nil
            for _, v in ipairs(branch.variants) do
                if type(v) == "table" then
                    if tostring(v.id or "") == wanted then chosen = v break end
                    if neutralVar == nil and tostring(v.id or "") == "neutral" then neutralVar = v end
                end
            end
            chosen = chosen or neutralVar or branch.variants[1]
        end
        if type(chosen) ~= "table" then
            return nil, "response_text_missing"
        end
        local raw = resolveLocalizedList(chosen.translations, chosen.fallback, language, seed, explicitIndex)
        if not raw then return nil, "response_text_missing" end
        return renderTemplateText(raw, context, bindings)
    end
    return nil, "unknown_text_role"
end

local function utilityDimensionValue(context, dim)
    if type(context) ~= "table" then return 0 end
    for _, bagName in ipairs({ "utility", "motivation", "traits", "relationship" }) do
        local bag = context[bagName]
        if type(bag) == "table" and type(bag[dim]) == "number" then
            return bag[dim]
        end
    end
    if type(context.npc) == "table" then
        for _, bagName in ipairs({ "utility", "motivation", "traits" }) do
            local bag = context.npc[bagName]
            if type(bag) == "table" and type(bag[dim]) == "number" then
                return bag[dim]
            end
        end
    end
    return 1
end

function Affordance.Score(planOrFamily, context)
    local family = type(planOrFamily) == "table"
        and (planOrFamily.exchangeFamily or planOrFamily)
        or nil
    local aff = type(family) == "table" and family.affordance or nil
    if type(aff) ~= "table" then return 0 end
    local score = tonumber(aff.priority) or 0
    if type(aff.utility) == "table" then
        for _, dim in ipairs(sortedKeys(aff.utility)) do
            local weight = tonumber(aff.utility[dim]) or 0
            local factor = utilityDimensionValue(context, dim)
            score = score + (weight * factor)
        end
    end
    return score
end

local function bindSlotContext(baseContext, slotName, value)
    local ctx = cloneShallow(baseContext)
    local slotMap = cloneShallow(type(baseContext) == "table" and baseContext.slot or nil)
    slotMap[slotName] = value
    ctx.slot = slotMap
    return ctx
end

function Affordance.ExpandSlots(planOrFamily, context)
    local family = type(planOrFamily) == "table"
        and (planOrFamily.exchangeFamily or planOrFamily)
        or nil
    local slots = type(family) == "table" and family.slots
        or (type(planOrFamily) == "table" and planOrFamily.slots)
        or nil
    if not tableHasEntries(slots) then
        return { { context = context or {}, slotBindings = {} } }
    end

    local expanded = { { context = context or {}, slotBindings = {} } }
    for _, slotName in ipairs(sortedKeys(slots)) do
        local slotDef = type(slots[slotName]) == "table" and slots[slotName] or {}
        local bound = type(context) == "table" and type(context.slot) == "table" and context.slot[slotName] or nil
        if bound ~= nil then
            for _, entry in ipairs(expanded) do
                entry.context = bindSlotContext(entry.context, slotName, bound)
                entry.slotBindings[slotName] = bound
            end
        elseif slotDef.suggest == true or (type(slotDef.suggest) == "string" and slotDef.suggest ~= "") then
            local list = type(context) == "table" and type(context.slots) == "table"
                and (context.slots[slotName] or (type(slotDef.suggest) == "string" and context.slots[slotDef.suggest] or nil))
                or (type(context) == "table" and type(context.candidates) == "table" and context.candidates[slotName])
                or nil
            if type(list) ~= "table" or #list == 0 then
                if slotDef.required == true then return {}, "slot_missing:" .. slotName end
                return {}, "slot_suggest_empty:" .. slotName
            end
            local limit = tonumber(slotDef.limit) or Affordance.DEFAULT_SLOT_LIMIT
            local nextExpanded = {}
            for _, baseEntry in ipairs(expanded) do
                for i = 1, math.min(#list, limit) do
                    local candidate = list[i]
                    local nextBindings = cloneShallow(baseEntry.slotBindings)
                    nextBindings[slotName] = candidate
                    nextExpanded[#nextExpanded + 1] = {
                        context = bindSlotContext(baseEntry.context, slotName, candidate),
                        slotBindings = nextBindings,
                    }
                    if #nextExpanded >= Offer.MAX_OFFERS then break end
                end
                if #nextExpanded >= Offer.MAX_OFFERS then break end
            end
            expanded = nextExpanded
        elseif slotDef.required == true then
            return {}, "slot_missing:" .. slotName
        end
    end
    return expanded
end

local function buildCandidate(plan, family, consumer, bindingEntry, options)
    local familyID = tostring(family.familyID or plan.id or "")
    local labelText, labelErr = Affordance.RenderRoleText(family, "button_label", bindingEntry.context, options)
    if not labelText then return nil, labelErr end
    local speechText, speechErr = Affordance.RenderRoleText(family, "spoken_action", bindingEntry.context, options)
    if not speechText then return nil, speechErr end

    local aff = family.affordance
    return {
        familyID = familyID,
        id = familyID,
        consumer = consumer,
        label = labelText,
        utterance = speechText,
        labelRole = "button_label",
        utteranceRole = "spoken_action",
        score = Affordance.Score(family, bindingEntry.context),
        priority = tonumber(aff.priority) or 0,
        groups = type(aff.groups) == "table" and aff.groups or {},
        slot = bindingEntry.slotBindings,
        context = bindingEntry.context,
        invoke = family.invoke,
        after = family.after,
        plan = plan,
        family = family,
    }
end

function Affordance.Collect(consumer, context, options)
    options = type(options) == "table" and options or {}
    consumer = tostring(consumer or "participant")
    local registry = activeRegistry(options)
    if type(registry) ~= "table" or type(registry.CONVO_PLANS) ~= "table" then
        return {}
    end

    local wantedGroups = type(options.groups) == "table" and options.groups or nil
    local candidates = {}
    for _, planID in ipairs(sortedKeys(registry.CONVO_PLANS)) do
        local plan = registry.CONVO_PLANS[planID]
        local family = type(plan) == "table" and type(plan.exchangeFamily) == "table"
            and plan.exchangeFamily or nil
        if family and type(family.affordance) == "table"
            and hasConsumer(family.affordance.consumers, consumer)
            and hasAnyGroup(family.affordance.groups, wantedGroups)
        then
            local allowed = evalPredicate(family.affordance.when, context)
            if allowed then
                local slotEntries = Affordance.ExpandSlots(plan, context)
                for _, entry in ipairs(slotEntries) do
                    local row = buildCandidate(plan, family, consumer, entry, options)
                    if row then
                        candidates[#candidates + 1] = row
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return tostring(a.familyID) < tostring(b.familyID)
    end)

    local limit = tonumber(options.limit) or Affordance.MAX_RECOMMEND
    if #candidates > limit then
        local trimmed = {}
        for i = 1, limit do trimmed[i] = candidates[i] end
        return trimmed
    end
    return candidates
end

function Affordance.SelectNpcAffordance(context, options)
    local opts = cloneShallow(options)
    opts.limit = 1
    local list = Affordance.Collect("npc", context, opts)
    return list[1]
end

local function findPlan(familyOrID, options)
    if type(familyOrID) == "table" then
        if type(familyOrID.exchangeFamily) == "table" then
            return familyOrID, familyOrID.exchangeFamily
        end
        return familyOrID, familyOrID
    end
    local registry = activeRegistry(options)
    local plan = registry and type(registry.ConvoPlan) == "function"
        and registry.ConvoPlan(tostring(familyOrID or "")) or nil
    local family = type(plan) == "table" and plan.exchangeFamily or nil
    return plan, family
end

function Affordance.SelectReply(familyOrID, context, options)
    options = type(options) == "table" and options or {}
    local _plan, family = findPlan(familyOrID, options)
    if type(family) ~= "table" or type(family.replies) ~= "table" then
        return nil, "replies_missing"
    end

    local chosenOutcome = nil
    local explicitOutcome = options.outcome and tostring(options.outcome) or nil
    if not options.forceExactOutcome then
        for _, outcomeName in ipairs(sortedKeys(family.replies)) do
            local branch = family.replies[outcomeName]
            if type(branch) == "table" and branch.when ~= nil then
                if evalPredicate(branch.when, context) then
                    chosenOutcome = outcomeName
                    break
                end
            end
        end
    end
    if not chosenOutcome and explicitOutcome and type(family.replies[explicitOutcome]) == "table" then
        chosenOutcome = explicitOutcome
    elseif not chosenOutcome then
        local defaultOutcome = nil
        for _, outcomeName in ipairs(sortedKeys(family.replies)) do
            local branch = family.replies[outcomeName]
            if type(branch) == "table" then
                if branch.when ~= nil then
                    if evalPredicate(branch.when, context) then
                        chosenOutcome = outcomeName
                        break
                    end
                elseif defaultOutcome == nil then
                    defaultOutcome = outcomeName
                end
            end
        end
        chosenOutcome = chosenOutcome or defaultOutcome
    end
    if not chosenOutcome then return nil, "no_matching_reply" end

    local branch = family.replies[chosenOutcome]
    local renderOpts = cloneShallow(options)
    renderOpts.outcome = chosenOutcome
    local text, err = Affordance.RenderRoleText(family, "response", context, renderOpts)
    return {
        familyID = family.familyID,
        outcome = chosenOutcome,
        act = branch.act,
        text = text,
        textRole = "response",
        error = err,
        after = branch.after or family.after,
        branch = branch,
    }
end

function Affordance.ResolveAfter(familyOrID, outcomeName, context, options)
    options = type(options) == "table" and options or {}
    local _plan, family = findPlan(familyOrID, options)
    if type(family) ~= "table" then return { mode = "none" } end

    local replies = type(family.replies) == "table" and family.replies or nil
    local branch = replies and outcomeName and replies[tostring(outcomeName)] or nil
    local after = (type(branch) == "table" and type(branch.after) == "table" and branch.after)
        or (type(family.after) == "table" and family.after)
        or nil
    if type(after) ~= "table" then return { mode = "none" } end

    if after["end"] == true then
        return { mode = "end" }
    end
    if after.resume == true then
        return { mode = "resume" }
    end

    local visited = cloneShallow(type(options.visited) == "table" and options.visited or nil)
    if family.familyID then visited[tostring(family.familyID)] = true end
    local hopCount = tonumber(options.hopCount) or 0
    local maxHops = tonumber(options.maxHops) or Affordance.MAX_AFTER_HOPS

    if type(after["goto"]) == "table" then
        local gt = after["goto"]
        local targetID = tostring(gt.target or "")
        if hopCount >= maxHops then
            return { mode = "blocked", reason = "after_hop_limit", target = targetID }
        end
        if targetID ~= "" and visited[targetID] then
            return { mode = "blocked", reason = "after_cycle_detected", target = targetID }
        end
        if gt.when == nil or evalPredicate(gt.when, context) then
            visited[targetID] = true
            return {
                mode = "goto",
                target = targetID,
                hopCount = hopCount + 1,
                visited = visited,
            }
        end
    end

    if after.recommend ~= nil then
        local consumer = tostring(options.consumer or "player")
        local recommended = {}
        local registry = activeRegistry(options)
        if type(after.recommend[1]) == "string" then
            for _, targetID in ipairs(after.recommend) do
                if not visited[targetID] and registry and type(registry.ConvoPlan) == "function" then
                    local tPlan = registry.ConvoPlan(targetID)
                    local tFamily = type(tPlan) == "table" and tPlan.exchangeFamily or nil
                    if tFamily and type(tFamily.affordance) == "table"
                        and hasConsumer(tFamily.affordance.consumers, consumer)
                        and evalPredicate(tFamily.affordance.when, context)
                    then
                        local slots = Affordance.ExpandSlots(tPlan, context)
                        for _, entry in ipairs(slots) do
                            local row = buildCandidate(tPlan, tFamily, consumer, entry, options)
                            if row then recommended[#recommended + 1] = row end
                            if #recommended >= Affordance.MAX_RECOMMEND then break end
                        end
                    end
                end
                if #recommended >= Affordance.MAX_RECOMMEND then break end
            end
        elseif type(after.recommend) == "table" and type(after.recommend.groups) == "table" then
            local recOpts = cloneShallow(options)
            recOpts.groups = after.recommend.groups
            recOpts.limit = math.min(
                tonumber(after.recommend.limit) or Affordance.MAX_RECOMMEND,
                Affordance.MAX_RECOMMEND
            )
            local recConsumer = tostring(after.recommend.consumer or consumer)
            for _, row in ipairs(Affordance.Collect(recConsumer, context, recOpts)) do
                if not visited[row.familyID] then
                    recommended[#recommended + 1] = row
                end
            end
        end
        return { mode = "recommend", recommendations = recommended }
    end

    if after.transition ~= nil then
        return { mode = "transition", transition = after.transition }
    end
    return { mode = "none" }
end

local function actionContractModule()
    if ConvoEngine.ActionContract then
        return ConvoEngine.ActionContract
    end
    return require "PsychopatzCore/ConvoEngine/ActionContract"
end

function Affordance.ApplyActionResult(familyOrID, actionResponse, context, options)
    options = type(options) == "table" and options or {}
    context = type(context) == "table" and context or {}
    local _plan, family = findPlan(familyOrID, options)
    if type(family) ~= "table" then
        return nil, "exchange_family_missing"
    end

    local resolved = actionResponse
    if type(options.requestID) == "string" and options.requestID ~= ""
        and options.completeAsync == true
    then
        resolved = actionContractModule().CompleteAsync(options.requestID, actionResponse, options)
        if not resolved or resolved.accepted ~= true then
            return {
                familyID = family.familyID,
                accepted = false,
                duplicate = resolved and resolved.duplicate == true,
                stale = resolved and resolved.stale == true,
                reason = resolved and resolved.reason or "async_result_rejected",
                result = resolved and resolved.result or nil,
                emittedReply = false,
            }
        end
    end

    if type(resolved) ~= "table" then
        return nil, "action_result_missing"
    end

    local replyCtx = cloneShallow(context)
    replyCtx.result = resolved.result or resolved
    local selectOpts = cloneShallow(options)
    selectOpts.outcome = resolved.outcome or (replyCtx.result and replyCtx.result.outcome)

    local reply, replyErr = Affordance.SelectReply(family, replyCtx, selectOpts)
    local afterResult = Affordance.ResolveAfter(
        family,
        reply and reply.outcome or selectOpts.outcome,
        replyCtx,
        options
    )
    return {
        familyID = family.familyID,
        accepted = resolved.accepted ~= false,
        requestID = resolved.requestID or (replyCtx.result and replyCtx.result.requestID),
        outcome = reply and reply.outcome or selectOpts.outcome,
        result = replyCtx.result,
        reply = reply,
        replyError = replyErr,
        after = afterResult,
        emittedReply = reply ~= nil,
        duplicate = false,
        stale = false,
    }
end

function Affordance.ExecuteExchange(familyOrID, context, options)
    options = type(options) == "table" and options or {}
    context = type(context) == "table" and context or {}
    if options.discoveryOnly == true then
        return {
            accepted = false,
            reason = "action_execution_forbidden_in_discovery",
            emittedReply = false,
        }
    end
    local _plan, family = findPlan(familyOrID, options)
    if type(family) ~= "table" then
        return nil, "exchange_family_missing"
    end

    local spokenText = nil
    if options.renderSpokenAction ~= false and type(family.initiatingSay) == "table" then
        spokenText = Affordance.RenderRoleText(family, "spoken_action", context, options)
    end

    if type(family.execute) ~= "table" then
        local reply, err = Affordance.SelectReply(family, context, options)
        return {
            familyID = family.familyID,
            accepted = true,
            spokenAction = spokenText,
            outcome = reply and reply.outcome or nil,
            reply = reply,
            replyError = err,
            after = Affordance.ResolveAfter(family, reply and reply.outcome, context, options),
            emittedReply = reply ~= nil,
        }
    end

    local execRes = actionContractModule().Execute(family.execute, context, options)
    if execRes.duplicate == true then
        return {
            familyID = family.familyID,
            accepted = execRes.accepted,
            duplicate = true,
            stale = true,
            reason = execRes.reason,
            requestID = execRes.requestID,
            outcome = execRes.outcome,
            result = execRes.result,
            spokenAction = spokenText,
            emittedReply = false,
        }
    end

    local applied = Affordance.ApplyActionResult(family, execRes, context, options)
    if type(applied) == "table" then
        applied.spokenAction = spokenText
    end
    return applied
end

return Affordance
