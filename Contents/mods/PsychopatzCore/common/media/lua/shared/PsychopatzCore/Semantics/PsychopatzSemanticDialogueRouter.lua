PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local State = Semantics.DialogueState
    or require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueState"
local Router = Semantics.DialogueRouter or {}
Semantics.DialogueRouter = Router

Router.VERSION = 1

local function asTable(value)
    return type(value) == "table" and value or {}
end

local function defaultDecision(ir, state)
    return {
        schemaVersion = Router.VERSION,
        kind = "semantic_dialogue_decision",
        route = "semantic",
        branch = "UNHANDLED",
        confidence = tonumber(ir and ir.confidence) or 0,
        intent = ir and ir.intent,
        speechAct = ir and ir.speechAct,
        action = ir and ir.action,
        diagnostics = {
            reason = "no_policy",
            stateSequence = state and state.sequence or nil,
        },
    }
end

function Router.New(spec)
    spec = asTable(spec)
    local self = {
        version = Router.VERSION,
        state = spec.state or State.New(spec.stateSpec),
        parser = spec.parser or Semantics.Parser.Parse,
        contextResolver = spec.contextResolver,
        policy = spec.policy,
        decide = spec.decide,
        context = spec.context or {},
        options = spec.options or {},
        lastResult = nil,
    }
    setmetatable(self, { __index = Router })
    return self
end

function Router:SetContext(context)
    self.context = asTable(context)
    return self.context
end

function Router:SetParser(parser)
    if type(parser) ~= "function" then return false, "invalid_parser" end
    self.parser = parser
    return true, parser
end

function Router:SetContextResolver(resolver)
    if resolver ~= nil and type(resolver) ~= "function" then
        return false, "invalid_context_resolver"
    end
    self.contextResolver = resolver
    return true, resolver
end

function Router:SetPolicy(policy)
    self.policy = policy
    return policy
end

function Router:SetState(state)
    if type(state) ~= "table"
        or type(state.Record) ~= "function"
    then
        return false, "invalid_state"
    end
    self.state = state
    return true, state
end

function Router:Parse(text, options)
    if type(self.parser) ~= "function" then
        return nil, "parser_unavailable"
    end
    return self.parser(text, options or self.options)
end

function Router:Decide(ir, context, options)
    context = context or self.context
    options = options or self.options
    if type(self.decide) == "function" then
        return self.decide(ir, self.state, context, options)
    end
    if self.policy and type(self.policy.Decide) == "function" then
        return self.policy.Decide(ir, self.state, context, options)
    end
    return defaultDecision(ir, self.state)
end

function Router:ResolveIR(ir, context, options)
    if type(self.contextResolver) ~= "function" then return ir end

    context = context or self.context
    options = options or self.options
    local ok, resolved = pcall(
        self.contextResolver,
        ir,
        self.state,
        context,
        options
    )
    if not ok or type(resolved) ~= "table" then return ir end

    local valid = IR.Validate(resolved)
    if valid ~= true then return ir end
    return resolved
end

function Router:Preview(text, context, options)
    options = options or self.options
    local ir, parseReason = self:Parse(text, options)
    if not ir then
        return {
            schemaVersion = Router.VERSION,
            kind = "semantic_dialogue_preview",
            accepted = false,
            reason = parseReason or "parse_failed",
            state = self.state,
        }
    end
    ir = self:ResolveIR(ir, context, options)
    return {
        schemaVersion = Router.VERSION,
        kind = "semantic_dialogue_preview",
        accepted = true,
        ir = ir,
        decision = self:Decide(ir, context, options),
        state = self.state,
        sequence = self.state.sequence,
    }
end

function Router:ProcessIR(ir, context, options)
    options = options or self.options
    ir = self:ResolveIR(ir, context, options)
    local valid, validationReason = IR.Validate(ir)
    if valid ~= true then
        return {
            schemaVersion = Router.VERSION,
            kind = "semantic_dialogue_result",
            accepted = false,
            reason = validationReason or "invalid_ir",
            ir = ir,
            state = self.state,
        }
    end

    local recorded, eventOrReason = self.state:Record(ir, options)
    if recorded ~= true then
        return {
            schemaVersion = Router.VERSION,
            kind = "semantic_dialogue_result",
            accepted = false,
            reason = eventOrReason or "state_rejected",
            ir = ir,
            state = self.state,
        }
    end

    local decision = self:Decide(ir, context, options)
    local result = {
        schemaVersion = Router.VERSION,
        kind = "semantic_dialogue_result",
        accepted = true,
        ir = ir,
        decision = decision,
        event = eventOrReason,
        state = self.state,
        sequence = self.state.sequence,
    }
    if self.state and type(self.state.CompletePending) == "function" then
        -- Decide before completing so response composition can still use the
        -- request/question that this turn answers.
        self.state:CompletePending(ir)
    end
    self.lastResult = result
    return result
end

function Router:Process(text, context, options)
    local preview = self:Preview(text, context, options)
    if preview.accepted ~= true then
        preview.kind = "semantic_dialogue_result"
        return preview
    end
    return self:ProcessIR(preview.ir, context, options)
end

function Router:Snapshot()
    return self.state and self.state:Snapshot() or nil
end

function Router:Reset()
    if self.state and self.state.Reset then self.state:Reset() end
    self.lastResult = nil
    return self.state
end

return Router
