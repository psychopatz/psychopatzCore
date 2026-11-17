-- Core-owned production ConvoEngine probe for Semantic Harness GUI/CLI.
--
-- Executes directly against Core Semantics and ConvoEngine Lua modules
-- (Predicate, Affordance, TextBinding, ActionContract) so Semantic Lab and
-- CLI traces never drift into a separate Python interpreter copy.

local ConvoProbe = {}
local _mods = nil

local function modules()
    if _mods ~= nil then return _mods end
    local Predicate = require "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"
    local Affordance = require "PsychopatzCore/ConvoEngine/Affordance"
    local TextBinding = require "PsychopatzCore/ConvoEngine/TextBinding"
    local ActionContract = require "PsychopatzCore/ConvoEngine/ActionContract"
    local S11PolicyEvaluator = require "PsychopatzCore/ConvoEngine/S11PolicyEvaluator"
    _mods = {
        Predicate = Predicate,
        Affordance = Affordance,
        TextBinding = TextBinding,
        ActionContract = ActionContract,
        S11PolicyEvaluator = S11PolicyEvaluator,
    }
    return _mods
end

ConvoProbe.SCHEMA = "semantic.harness.convo_trace.v1"
ConvoProbe.VERSION = 1
ConvoProbe.CAPABILITY = "semantic.convo_probe"
ConvoProbe.OPS = {
    "describe",
    "render_role_text",
    "evaluate_predicate",
    "expand_slots",
    "collect_affordances",
    "score_affordance",
    "select_npc_affordance",
    "select_reply",
    "resolve_after",
    "list_action_contracts",
    "project_action_result",
    "simulate_exchange",
    "evaluate_s11_family",
}

local function sortedKeys(tbl)
    local keys = {}
    if type(tbl) ~= "table" then return keys end
    for k in pairs(tbl) do
        keys[#keys + 1] = tostring(k)
    end
    table.sort(keys)
    return keys
end

local function isArray(tbl)
    if type(tbl) ~= "table" then return false end
    local maxIdx = 0
    local count = 0
    for k in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
            return false
        end
        if k > maxIdx then maxIdx = k end
        count = count + 1
    end
    return maxIdx == count and count > 0
end

local function sanitizeJson(value, depth)
    depth = tonumber(depth) or 0
    if depth > 12 then return nil end
    local t = type(value)
    if t == "string" or t == "number" or t == "boolean" then
        return value
    end
    if t ~= "table" then
        return nil
    end
    local out = {}
    if isArray(value) then
        for i = 1, #value do
            local item = sanitizeJson(value[i], depth + 1)
            if item ~= nil then
                out[#out + 1] = item
            end
        end
        return out
    end
    for k, v in pairs(value) do
        if type(k) == "string" or type(k) == "number" then
            local item = sanitizeJson(v, depth + 1)
            if item ~= nil then
                out[k] = item
            end
        end
    end
    return out
end

local function makeRegistry(payload)
    local plans = payload and payload.plans
    local single = payload and (payload.plan or payload.family)
    if type(plans) ~= "table" then
        plans = single and { single } or {}
    end
    local byID = {}
    for k, plan in pairs(plans) do
        if type(plan) == "table" then
            local family = plan.exchangeFamily or plan
            local fid = tostring(plan.id or (type(family) == "table" and family.familyID) or k)
            if fid ~= "" then
                byID[fid] = plan
            end
        end
    end
    return {
        CONVO_PLANS = byID,
        ConvoPlan = function(id)
            return byID[tostring(id or "")]
        end,
    }
end

local function sanitizeCandidate(row)
    if type(row) ~= "table" then return nil end
    return sanitizeJson({
        familyID = row.familyID,
        id = row.id,
        consumer = row.consumer,
        label = row.label,
        utterance = row.utterance,
        labelRole = row.labelRole,
        utteranceRole = row.utteranceRole,
        score = row.score,
        priority = row.priority,
        groups = row.groups,
        slot = row.slot,
        invoke = row.invoke,
        after = row.after,
    })
end

local function firstTranslationLine(choiceBlock, locale)
    if type(choiceBlock) ~= "table" then return "" end
    local trans = type(choiceBlock.translations) == "table" and choiceBlock.translations
        or (type(choiceBlock.text) == "table" and choiceBlock.text)
        or {}
    local lines = trans[locale] or trans.EN
    if type(lines) == "table" and #lines > 0 then
        return tostring(lines[1] or "")
    end
    if type(lines) == "string" then
        return lines
    end
    return tostring(choiceBlock.fallback or choiceBlock.labelFallback or "")
end

local function selectPreviewVariant(variants, style)
    if type(variants) ~= "table" or #variants == 0 then return nil end
    local chosen, neutralVar = nil, nil
    for _, v in ipairs(variants) do
        if type(v) == "table" then
            if tostring(v.id or "") == style then
                chosen = v
                break
            end
            if neutralVar == nil and tostring(v.id or "") == "neutral" then
                neutralVar = v
            end
        end
    end
    return chosen or neutralVar or variants[1]
end

local function inspectInitiatingMeta(sayProj, realizationKey, style, locale)
    if type(sayProj) ~= "table" then return nil end
    local realizations = type(sayProj.realizations) == "table" and sayProj.realizations or {}
    local keyOrder = type(sayProj.keyOrder) == "table" and sayProj.keyOrder or sortedKeys(realizations)
    local selectedKey = (realizationKey ~= "" and realizations[realizationKey] ~= nil) and realizationKey
        or (keyOrder[1] or sortedKeys(realizations)[1])
    if not selectedKey or type(realizations[selectedKey]) ~= "table" then return nil end
    local entry = realizations[selectedKey]
    local chosen = selectPreviewVariant(entry.variants, style)
    if not chosen then return nil end
    local translations = type(chosen.text) == "table" and chosen.text or {}
    local chosenLocale = translations[locale] ~= nil and locale or "EN"
    return {
        realizationKey = selectedKey,
        variantID = chosen.id,
        templateID = chosen.templateID,
        textRole = sayProj.textRole,
        locale = chosenLocale,
        rawText = firstTranslationLine(chosen, locale),
    }
end

local function inspectReplyMeta(branch, style, locale)
    if type(branch) ~= "table" then return {} end
    if type(branch.say) == "table" then
        return inspectInitiatingMeta(branch.say, "", style, locale) or { textRole = branch.textRole }
    end
    local chosen = selectPreviewVariant(branch.variants, style)
    local rawText = chosen and firstTranslationLine(chosen, locale) or ""
    return {
        variantID = chosen and chosen.id or nil,
        templateID = chosen and chosen.templateID or nil,
        textRole = branch.textRole,
        locale = locale,
        rawText = rawText,
    }
end

local function resolveDotted(mapping, path)
    local cur = mapping
    for seg in string.gmatch(tostring(path or ""), "[^%.]+") do
        if type(cur) == "table" and cur[seg] ~= nil then
            cur = cur[seg]
        else
            return nil
        end
    end
    return cur
end

local function listActionContracts()
    local ActionContract = modules().ActionContract
    local items = {}
    for _, id in ipairs(ActionContract.List()) do
        local c = ActionContract.Get(id)
        if type(c) == "table" then
            items[#items + 1] = sanitizeJson({
                id = c.id,
                capability = c.capability,
                mode = c.mode,
                inputs = c.inputs,
                resultSchema = c.resultSchema,
                outcomeMap = c.outcomeMap,
                defaultOutcome = c.defaultOutcome,
            })
        end
    end
    return {
        ok = true,
        schema = ConvoProbe.SCHEMA,
        contracts = items,
    }
end

local function simulateExchange(payload)
    local mods = modules()
    local Predicate = mods.Predicate
    local Affordance = mods.Affordance
    local ActionContract = mods.ActionContract
    local plan = payload.plan
    if type(plan) ~= "table" then
        return nil, "convo_probe_plan_required"
    end
    local family = type(plan.exchangeFamily) == "table" and plan.exchangeFamily or plan
    local ctx = type(payload.context) == "table" and payload.context or {}
    local opts = type(payload.options) == "table" and payload.options or {}
    local locale = string.upper(tostring(opts.language or opts.locale or "EN"))
    local style = tostring(opts.style or "neutral")
    local realizationKey = tostring(opts.realizationKey or "")
    local registry = makeRegistry(payload)
    local affOpts = {
        language = locale,
        style = style,
        realizationKey = realizationKey ~= "" and realizationKey or nil,
        registry = registry,
        consumer = tostring(opts.consumer or ctx.speaker or "player"),
        outcome = type(ctx.result) == "table" and ctx.result.outcome or opts.outcome,
    }

    -- 1. Predicate stage (authoritative PsychopatzSemanticPredicate)
    local whenPred = plan.when
    if whenPred == nil and type(family.affordance) == "table" then
        whenPred = family.affordance.when
    end
    local predResult
    if whenPred ~= nil then
        predResult = Predicate.Evaluate(whenPred, ctx)
    else
        predResult = {
            status = "allowed",
            allowed = true,
            reason = "unconstrained",
            trace = {},
            truncated = false,
        }
    end

    -- 2. Affordance + Slot + Utility Scoring stage
    local slotEntries, slotErr = Affordance.ExpandSlots(plan, ctx)
    local scoreVal = Affordance.Score(plan, ctx)
    local buttonPreview = nil
    if type(family.affordance) == "table" then
        local renderedLabel, labelErr = Affordance.RenderRoleText(family, "button_label", ctx, affOpts)
        buttonPreview = {
            textRole = family.affordance.textRole,
            labelKey = family.affordance.labelKey,
            consumers = family.affordance.consumers or {},
            score = scoreVal,
            slotCount = #slotEntries,
            slotError = slotErr,
            renderedLabel = renderedLabel,
            renderError = labelErr,
        }
    end

    -- 3. Spoken action stage
    local speechPreview = inspectInitiatingMeta(family.initiatingSay, realizationKey, style, locale)
    if speechPreview ~= nil then
        local renderedSpeech, speechErr = Affordance.RenderRoleText(family, "spoken_action", ctx, affOpts)
        speechPreview.renderedText = renderedSpeech
        speechPreview.renderError = speechErr
    end

    -- 4. Execute & ActionContract stage
    local executeSpec = type(family.execute) == "table" and family.execute or nil
    local executeTrace = nil
    local resultEnv = type(ctx.result) == "table" and sanitizeJson(ctx.result) or {}
    if executeSpec ~= nil then
        local actionID = tostring(executeSpec.use or executeSpec.action or "")
        local contract = ActionContract.Get(actionID)
        local resolvedWith = {}
        if type(executeSpec.with) == "table" then
            for k, v in pairs(executeSpec.with) do
                if type(v) == "string" and string.sub(v, 1, 1) == "$" then
                    resolvedWith[k] = resolveDotted(ctx, string.sub(v, 2))
                else
                    resolvedWith[k] = v
                end
            end
        end
        if resultEnv.outcome == nil or resultEnv.outcome == "" then
            local replyKeys = sortedKeys(family.replies)
            if contract and contract.defaultOutcome then
                resultEnv.outcome = contract.defaultOutcome
            elseif #replyKeys > 0 then
                resultEnv.outcome = replyKeys[1]
            end
        end
        if type(ctx.result) ~= "table" then
            ctx.result = resultEnv
        elseif ctx.result.outcome == nil then
            ctx.result.outcome = resultEnv.outcome
        end
        affOpts.outcome = resultEnv.outcome
        executeTrace = {
            action = actionID,
            mode = executeSpec.mode or (contract and contract.mode) or "sync",
            resolvedWith = resolvedWith,
            discoveryOnly = false,
            publicResult = resultEnv,
            contractRegistered = contract ~= nil,
        }
    end

    -- 5. Reply stage (authoritative Affordance.SelectReply)
    local replyRes, replyErr = Affordance.SelectReply(family, ctx, affOpts)
    local selectedOutcome = replyRes and replyRes.outcome or nil
    local replySpeech = nil
    if replyRes ~= nil and selectedOutcome ~= nil then
        local branch = type(family.replies) == "table" and family.replies[selectedOutcome] or nil
        replySpeech = inspectReplyMeta(branch, style, locale)
        replySpeech.renderedText = replyRes.text
        replySpeech.renderError = replyRes.error
    end

    -- 6. After / continuation stage (authoritative Affordance.ResolveAfter)
    local afterResult = Affordance.ResolveAfter(family, selectedOutcome, ctx, affOpts)
    local branch = type(family.replies) == "table" and selectedOutcome and family.replies[selectedOutcome] or nil
    local rawAfter = (type(branch) == "table" and branch.after) or family.after

    local trace = {
        {
            stage = "predicate",
            passed = predResult.allowed == true,
            status = predResult.status,
            reason = predResult.reason,
            when = whenPred,
            luaTrace = predResult.trace or {},
        },
        {
            stage = "affordance",
            button = buttonPreview,
            score = scoreVal,
        },
        {
            stage = "invoke",
            invoke = family.invoke,
        },
        {
            stage = "speech",
            speaker = ctx.speaker or "player",
            say = speechPreview,
        },
        {
            stage = "execute",
            action = executeTrace,
        },
        {
            stage = "result",
            publicResult = resultEnv,
        },
        {
            stage = "reply",
            speaker = ctx.addressee or "npc",
            outcome = selectedOutcome,
            say = replySpeech,
            error = replyErr,
        },
        {
            stage = "after",
            after = rawAfter,
            resolved = afterResult,
        },
    }

    local payloadTbl = type(plan.payload) == "table" and plan.payload or {}
    return sanitizeJson({
        ok = true,
        schema = ConvoProbe.SCHEMA,
        previewOnly = true,
        effectFree = true,
        familyID = plan.id or family.familyID,
        kind = plan.kind,
        owner = plan.owner,
        buttonPreview = buttonPreview,
        initiatingSpeechPreview = speechPreview,
        executePreview = executeTrace,
        replyPreview = {
            outcome = selectedOutcome,
            speech = replySpeech,
            error = replyErr,
        },
        afterPreview = rawAfter,
        resolvedAfter = afterResult,
        textRoles = plan.textRoles or {},
        beatBehaviorPreview = (plan.kind == "beat" or plan.kind == "behavior") and {
            group = payloadTbl.group,
            candidates = payloadTbl.candidates,
            entry = payloadTbl.entry,
            maintain = payloadTbl.maintain,
            exit = payloadTbl.exit,
        } or nil,
        trace = trace,
    })
end

function ConvoProbe.handle(_context, command, payload)
    if command ~= "CONVO_PROBE" then
        return false
    end
    local mods = modules()
    local Predicate = mods.Predicate
    local Affordance = mods.Affordance
    local ActionContract = mods.ActionContract
    payload = type(payload) == "table" and payload or {}
    local op = tostring(payload.op or payload.action or "describe")
    local ctx = type(payload.context) == "table" and payload.context or {}
    local opts = type(payload.options) == "table" and payload.options or {}

    if op == "describe" then
        return {
            ok = true,
            schema = ConvoProbe.SCHEMA,
            version = ConvoProbe.VERSION,
            capability = ConvoProbe.CAPABILITY,
            ops = ConvoProbe.OPS,
            registeredActionContracts = ActionContract.List(),
        }, nil, false
    elseif op == "evaluate_predicate" then
        if payload.predicate == nil then
            return {
                ok = true,
                schema = ConvoProbe.SCHEMA,
                allowed = true,
                status = "allowed",
                reason = "unconstrained",
                trace = {},
                truncated = false,
            }, nil, false
        end
        local res = Predicate.Evaluate(payload.predicate, ctx)
        return sanitizeJson({
            ok = true,
            schema = ConvoProbe.SCHEMA,
            allowed = res.allowed == true,
            status = res.status,
            reason = res.reason,
            trace = res.trace or {},
            truncated = res.truncated == true,
        }), nil, false
    elseif op == "render_role_text" then
        local target = payload.plan or payload.family
        local role = tostring(payload.role or "button_label")
        local text, err = Affordance.RenderRoleText(target, role, ctx, opts)
        return sanitizeJson({
            ok = text ~= nil,
            schema = ConvoProbe.SCHEMA,
            role = role,
            text = text,
            error = err,
        }), nil, false
    elseif op == "expand_slots" then
        local target = payload.plan or payload.family
        local entries, err = Affordance.ExpandSlots(target, ctx)
        local out = {}
        for _, entry in ipairs(entries or {}) do
            out[#out + 1] = sanitizeJson({ slotBindings = entry.slotBindings })
        end
        return sanitizeJson({
            ok = err == nil,
            schema = ConvoProbe.SCHEMA,
            count = #out,
            entries = out,
            error = err,
        }), nil, false
    elseif op == "score_affordance" then
        local target = payload.plan or payload.family
        return {
            ok = true,
            schema = ConvoProbe.SCHEMA,
            score = Affordance.Score(target, ctx),
        }, nil, false
    elseif op == "collect_affordances" then
        local collectOpts = {}
        for k, v in pairs(opts) do collectOpts[k] = v end
        collectOpts.registry = makeRegistry(payload)
        local list = Affordance.Collect(tostring(payload.consumer or "participant"), ctx, collectOpts)
        local rows = {}
        for _, row in ipairs(list) do
            rows[#rows + 1] = sanitizeCandidate(row)
        end
        return sanitizeJson({
            ok = true,
            schema = ConvoProbe.SCHEMA,
            count = #rows,
            affordances = rows,
        }), nil, false
    elseif op == "select_npc_affordance" then
        local selectOpts = {}
        for k, v in pairs(opts) do selectOpts[k] = v end
        selectOpts.registry = makeRegistry(payload)
        local chosen = Affordance.SelectNpcAffordance(ctx, selectOpts)
        return sanitizeJson({
            ok = true,
            schema = ConvoProbe.SCHEMA,
            selected = sanitizeCandidate(chosen),
        }), nil, false
    elseif op == "select_reply" then
        local selectOpts = {}
        for k, v in pairs(opts) do selectOpts[k] = v end
        selectOpts.registry = makeRegistry(payload)
        local target = payload.plan or payload.family or payload.familyID
        local reply, err = Affordance.SelectReply(target, ctx, selectOpts)
        return sanitizeJson({
            ok = reply ~= nil,
            schema = ConvoProbe.SCHEMA,
            reply = reply and {
                familyID = reply.familyID,
                outcome = reply.outcome,
                act = reply.act,
                text = reply.text,
                textRole = reply.textRole,
                after = reply.after,
                error = reply.error,
            } or nil,
            error = err,
        }), nil, false
    elseif op == "resolve_after" then
        local afterOpts = {}
        for k, v in pairs(opts) do afterOpts[k] = v end
        afterOpts.registry = makeRegistry(payload)
        local target = payload.plan or payload.family or payload.familyID
        local afterRes = Affordance.ResolveAfter(target, payload.outcome, ctx, afterOpts)
        return sanitizeJson({
            ok = true,
            schema = ConvoProbe.SCHEMA,
            after = afterRes,
        }), nil, false
    elseif op == "list_action_contracts" then
        return listActionContracts(), nil, false
    elseif op == "project_action_result" then
        local target = payload.contract or payload.contractID
        if type(target) == "table" and target.resultSchema == nil and type(target.result) == "table" then
            target = {
                id = target.id,
                capability = target.capability,
                mode = target.mode,
                inputs = target.inputs,
                resultSchema = target.result,
                outcomeMap = target.outcomeMap,
                defaultOutcome = target.defaultOutcome,
            }
        end
        local projected, err = ActionContract.ProjectResult(
            target,
            payload.rawResult,
            payload.requestID,
            opts
        )
        return sanitizeJson({
            ok = projected ~= nil,
            schema = ConvoProbe.SCHEMA,
            result = projected,
            error = err,
        }), nil, false
    elseif op == "simulate_exchange" then
        local res, err = simulateExchange(payload)
        if not res then
            return nil, err or "simulate_exchange_failed", false
        end
        return res, nil, false
    elseif op == "evaluate_s11_family" then
        local entry = payload.planEntry
        if type(entry) ~= "table" then
            return nil, "convo_probe_plan_entry_required", false
        end
        local eval = mods.S11PolicyEvaluator.EvaluateFamily(
            entry,
            payload.context,
            payload.roleBindings,
            payload.participantSet,
            payload.replyOutcome
        )
        return sanitizeJson({
            ok = true,
            schema = ConvoProbe.SCHEMA,
            evaluation = eval,
        }), nil, false
    end
    return nil, "convo_probe_unknown_op:" .. op, false
end

return ConvoProbe
