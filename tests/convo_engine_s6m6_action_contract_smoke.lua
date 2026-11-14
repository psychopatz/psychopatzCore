local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}

local IR = require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local TextBinding = require "PsychopatzCore/ConvoEngine/TextBinding"
local ActionContract = require "PsychopatzCore/ConvoEngine/ActionContract"
local Affordance = require "PsychopatzCore/ConvoEngine/Affordance"

local function eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s",
            tostring(label or "assertion"), tostring(expected), tostring(actual)))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function falsy(value, label)
    if value then error(label or "expected falsy") end
end

-- 1. result.* public IR paths vs private/lua fail-closed check
truthy(IR.IsPublicContextPath("result.outcome"), "result.outcome public")
truthy(IR.IsPublicContextPath("result.reasonClass"), "result.reasonClass public")
truthy(IR.IsPublicContextPath("result.data.site.label"), "result.data.site.label public")
falsy(IR.IsPublicContextPath("result.private.raw"), "result.private blocked")
falsy(IR.IsPublicContextPath("result.lua"), "result.lua blocked")

-- 2. Register presentation resolver and typed sync + async action contracts
TextBinding.ClearResolvers()
TextBinding.RegisterResolver("test.site_phrase", function(site)
    if type(site) ~= "table" or not site.label then return nil end
    return "at " .. tostring(site.label)
end)

ActionContract.Clear()
local dispatchCount = 0
local okReg = ActionContract.Register({
    id = "test.companion.camp",
    capability = "companion.camp",
    mode = "request_response",
    inputs = {
        target = { type = "location", required = true, source = "target" },
        scope = { type = "string", required = false },
    },
    result = {
        site = { type = "location" },
    },
    outcomeMap = {
        pending = "queued",
        queued = "queued",
        accepted = "queued",
        completed = "completed",
        rejected = "rejected",
        failed = "failed",
    },
}, function(args, _ctx, meta)
    dispatchCount = dispatchCount + 1
    if type(args.target) == "table" and args.target.tooFar == true then
        return {
            accepted = false,
            status = "rejected",
            reason = "camp_site_hint_out_of_range",
        }
    end
    return {
        accepted = true,
        status = "queued",
        data = {
            site = {
                label = args.target.label,
                scope = args.target.scope or "room",
                private = { internalPtr = "strip-me" },
            },
            secretInternal = "never-expose",
            lua = "strip-me",
        },
        requestID = meta.requestID,
    }
end)
truthy(okReg, "camp contract registered")

local campFamily = {
    id = "command.camp",
    kind = "dialogue",
    exchangeFamily = {
        familyID = "command.camp",
        slots = {
            camp_site = { type = "location", required = true },
        },
        bindings = {
            ["camp.locationPhrase"] = {
                resolver = "test.site_phrase",
                from = "result.data.site",
            },
        },
        execute = {
            use = "test.companion.camp",
            with = { target = "$slot.camp_site", scope = "single" },
            mode = "request_response",
        },
        initiatingSay = {
            keyOrder = { "1" },
            realizations = {
                ["1"] = {
                    variants = {
                        {
                            id = "neutral",
                            textRole = "spoken_action",
                            fallback = "Let's camp here.",
                            translations = { EN = { "Let's camp here." } },
                        },
                    },
                },
            },
        },
        replies = {
            queued = {
                outcome = "queued",
                say = {
                    keyOrder = { "1" },
                    realizations = {
                        ["1"] = {
                            variants = {
                                {
                                    id = "neutral",
                                    textRole = "response",
                                    fallback = "I'll set up camp {camp.locationPhrase}.",
                                    translations = { EN = { "I'll set up camp {camp.locationPhrase}." } },
                                },
                            },
                        },
                    },
                },
            },
            completed = {
                outcome = "completed",
                say = {
                    keyOrder = { "1" },
                    realizations = {
                        ["1"] = {
                            variants = {
                                {
                                    id = "neutral",
                                    textRole = "response",
                                    fallback = "We're set up {camp.locationPhrase}.",
                                    translations = { EN = { "We're set up {camp.locationPhrase}." } },
                                },
                            },
                        },
                    },
                },
            },
            rejected_out_of_range = {
                outcome = "rejected_out_of_range",
                when = { path = "result.reasonClass", op = "eq", value = "out_of_range" },
                say = {
                    keyOrder = { "1" },
                    realizations = {
                        ["1"] = {
                            variants = {
                                {
                                    id = "neutral",
                                    textRole = "response",
                                    fallback = "That camp location is too far away.",
                                    translations = { EN = { "That camp location is too far away." } },
                                },
                            },
                        },
                    },
                },
            },
            rejected = {
                outcome = "rejected",
                say = {
                    keyOrder = { "1" },
                    realizations = {
                        ["1"] = {
                            variants = {
                                {
                                    id = "neutral",
                                    textRole = "response",
                                    fallback = "I can't camp there.",
                                    translations = { EN = { "I can't camp there." } },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}

-- 3. Discovery must NOT execute mutating action
local ctx = {
    capability = { ["companion.camp"] = true },
    slot = { camp_site = { label = "Kitchen", scope = "room" } },
}
local discoveryAttempt = Affordance.ExecuteExchange(campFamily, ctx, { discoveryOnly = true })
eq(discoveryAttempt.accepted, false, "discovery mode blocked")
eq(dispatchCount, 0, "discovery mode never dispatches")

-- 4. Execute exchange -> initiating say -> queued reply -> stripped private data
local ex1 = Affordance.ExecuteExchange(campFamily, ctx, { exchangeID = "ex_camp_1" })
eq(dispatchCount, 1, "single dispatch")
eq(ex1.outcome, "queued", "queued outcome")
eq(ex1.spokenAction, "Let's camp here.", "spoken_action")
eq(ex1.reply.text, "I'll set up camp at Kitchen.", "queued reply uses camp.locationPhrase")
eq(ex1.result.data.secretInternal, nil, "undeclared field stripped from result.data")
eq(ex1.result.data.lua, nil, "lua field stripped from result.data")
eq(ex1.result.data.site.private, nil, "nested private table stripped from result.data")

-- 5. Duplicate exchangeID must not re-execute mutation or emit duplicate reply
local dupEx = Affordance.ExecuteExchange(campFamily, ctx, { exchangeID = "ex_camp_1" })
eq(dispatchCount, 1, "duplicate exchangeID does not re-dispatch")
eq(dupEx.duplicate, true, "duplicate flagged")
eq(dupEx.emittedReply, false, "duplicate does not emit reply")

-- 6. Stale duplicate queued async update is ignored; completion advances once; second completion ignored
local dupQueued = Affordance.ApplyActionResult(campFamily, {
    status = "queued",
    data = { site = { label = "Kitchen", scope = "room" } },
}, ctx, { requestID = ex1.requestID, completeAsync = true })
eq(dupQueued.accepted, false, "duplicate queued phase ignored")
eq(dupQueued.duplicate, true, "duplicate queued flagged")
eq(dupQueued.emittedReply, false, "duplicate queued emits no speech")

local completed = Affordance.ApplyActionResult(campFamily, {
    status = "completed",
    data = { site = { label = "Kitchen", scope = "room" } },
}, ctx, { requestID = ex1.requestID, completeAsync = true })
eq(completed.accepted, true, "async completion accepted")
eq(completed.outcome, "completed", "completed outcome")
eq(completed.emittedReply, true, "completion emits reply")
eq(completed.reply.text, "We're set up at Kitchen.", "completed reply uses resolved site")

local staleCompleted = Affordance.ApplyActionResult(campFamily, {
    status = "completed",
    data = { site = { label = "Kitchen", scope = "room" } },
}, ctx, { requestID = ex1.requestID, completeAsync = true })
eq(staleCompleted.accepted, false, "duplicate completion rejected")
eq(staleCompleted.stale, true, "duplicate completion marked stale")
eq(staleCompleted.emittedReply, false, "duplicate completion emits no speech")

-- 7. Rejected reasonClass drives predicated rejection branch
local farCtx = {
    capability = { ["companion.camp"] = true },
    slot = { camp_site = { label = "Warehouse", scope = "room", tooFar = true } },
}
local farEx = Affordance.ExecuteExchange(campFamily, farCtx, { exchangeID = "ex_camp_far" })
eq(farEx.outcome, "rejected_out_of_range", "predicated rejection branch selected")
eq(farEx.reply.text, "That camp location is too far away.", "out_of_range rejection wording")

print("convo_engine_s6m6_action_contract_smoke: PASS")
