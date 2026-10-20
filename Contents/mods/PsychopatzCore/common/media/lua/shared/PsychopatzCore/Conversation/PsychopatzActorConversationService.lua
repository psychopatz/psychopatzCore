-- Portable offline actor conversation service.
--
-- This is an orchestration boundary over the existing semantic parser,
-- candidate matcher, DialogueRouter and DialogueState. It owns no grammar,
-- translation catalog, LLM client, or gameplay store.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Service = Conversation.ActorService or {}
Conversation.ActorService = Service

local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Router = Semantics.DialogueRouter
local Turn = Semantics.DialogueTurn
local State = Semantics.DialogueState
local IR = Semantics.IR
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Knowledge = require "PsychopatzCore/Actors/PsychopatzActorKnowledge"

Service.VERSION = 1
Service.MAX_TURNS = 64
Service.MAX_CAPABILITIES = 32

local function tableValue(value)
    return type(value) == "table" and value or {}
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function actorID(actor)
    return actor and tostring(actor.actorId or actor.id or "") or ""
end

local function actorContext(actor, context)
    local output = copy(tableValue(context))
    output.actor = {
        actorId = actorID(actor),
        identity = copy(actor and actor.identity),
        persona = copy(actor and actor.persona),
        personality = copy(actor and actor.social
            and actor.social.personality),
        relationships = copy(actor and actor.social
            and actor.social.relationships),
        providerLease = copy(actor and actor.providerLease),
    }
    return output
end

local function responseFrom(decision)
    local response = decision and decision.response
    if type(response) ~= "table" then return nil end
    return copy(response)
end

local function responseText(self, response, context, options)
    if type(response) ~= "table" then return nil end
    if response.text ~= nil then return tostring(response.text) end
    local key = response.key or response.translationKey
    local fallback = response.fallback or response.default
    if type(self.localize) == "function" and key then
        local ok, value = pcall(
            self.localize,
            key,
            copy(response.args or response.translationArgs),
            options.language,
            fallback,
            context
        )
        if ok and value ~= nil then return tostring(value) end
    end
    return fallback and tostring(fallback) or nil
end

local function buildResponse(self, result, context, options)
    local response = self.responsePlanner
        and self.responsePlanner(
            self.actor,
            result,
            self.router.state,
            context,
            options
        )
        or responseFrom(result and result.decision)
    if type(response) ~= "table" then return nil end
    response.text = responseText(self, response, context, options)
    response.actorID = actorID(self.actor)
    response.language = options.language
    return response
end

local function processPart(self, text, context, options, index)
    local result = self.router:Process(text, context, options)
    result.turnPart = index
    return result
end

function Service.New(spec)
    spec = tableValue(spec)
    if type(spec.actor) ~= "table" then return nil, "actor_required" end
    local parser = Semantics.Parser
    -- Adopters that already own a production router may inject that router
    -- here.  This keeps the Core service as the shared actor boundary while
    -- allowing an adopter to retain its existing response/effect lifecycle.
    -- A missing router keeps the standalone Core-only path unchanged.
    local router = spec.router
    if type(router) ~= "table"
        or type(router.Process) ~= "function"
    then
        router = Router.New({
            state = spec.state,
            stateSpec = spec.stateSpec,
            parser = spec.parser or parser.Parse,
            candidateParser = spec.candidateParser or parser.ParseCandidates,
            candidateSelector = spec.candidateSelector,
            contextResolver = spec.contextResolver,
            policy = spec.policy,
            decide = spec.decide,
            context = spec.context,
            options = spec.options,
        })
    end
    local self = setmetatable({
        version = Service.VERSION,
        actor = spec.actor,
        router = router,
        localize = spec.localize,
        responsePlanner = spec.responsePlanner,
        knowledgeReader = spec.knowledgeReader,
        authority = spec.authority or "server",
        capabilities = {},
        capabilityCount = 0,
        turnCount = 0,
        conversationID = spec.conversationID,
    }, { __index = Service })
    return self
end

-- Shared parser boundary for adopters that need Core's bounded compound-turn
-- semantics while retaining their own presentation and effect pipeline.
function Service:ParseTurn(text, options)
    options = tableValue(options)
    local parseOptions = copy(self.router.options or {})
    for key, value in pairs(options) do parseOptions[key] = value end
    return Turn.Parse(
        text,
        function(clause, clauseOptions)
            return self.router:ParseCandidates(clause, clauseOptions)
        end,
        parseOptions
    )
end

function Service:Preview(text, context, options)
    return self.router:Preview(text, context, options)
end

function Service:ProcessIR(ir, context, options)
    return self.router:ProcessIR(ir, context, options)
end

function Service:Process(text, context, options)
    return self.router:Process(text, context, options)
end

function Service:ObserveResult(result)
    self.lastResult = copy(result)
    self.turnCount = math.min(Service.MAX_TURNS, self.turnCount + 1)
    return self.lastResult
end

function Service:RegisterCapability(capabilityID, handler, metadata)
    if not Util.isNamespacedKey(capabilityID) then
        return nil, "capability_id_invalid"
    end
    if type(handler) ~= "function" then return nil, "capability_handler_required" end
    if not self.capabilities[capabilityID]
        and self.capabilityCount >= Service.MAX_CAPABILITIES
    then return nil, "capability_limit" end
    if not self.capabilities[capabilityID] then self.capabilityCount = self.capabilityCount + 1 end
    self.capabilities[capabilityID] = {
        id = capabilityID,
        handler = handler,
        metadata = copy(metadata),
    }
    return copy(self.capabilities[capabilityID])
end

function Service:GetCapability(capabilityID)
    local capability = self.capabilities[capabilityID]
    return capability and {
        id = capability.id,
        metadata = copy(capability.metadata),
    } or nil
end

function Service:InvokeCapability(capabilityID, payload, context, authority)
    if authority ~= "server" then return nil, "server_authority_required" end
    local capability = self.capabilities[capabilityID]
    if not capability then return nil, "capability_not_registered" end
    local ok, result, reason = pcall(
        capability.handler,
        self.actor,
        copy(payload),
        actorContext(self.actor, context),
        self.router.state
    )
    if not ok then return nil, "capability_failed" end
    if result == nil and reason ~= nil then return nil, reason end
    return result, reason
end

function Service:GetKnowledge(playerKey, factID, authority)
    if authority ~= "server" then return nil, "server_authority_required" end
    if type(self.knowledgeReader) == "function" then
        local ok, value, reason = pcall(
            self.knowledgeReader,
            self.actor,
            playerKey,
            factID
        )
        if not ok then return nil, "knowledge_reader_failed" end
        return value, reason
    end
    local knowledge = self.actor and self.actor.knowledge
    if not knowledge then
        return nil, "knowledge_unavailable"
    end
    return Knowledge.Get(knowledge, playerKey, factID)
end

function Service:Submit(text, context, options)
    options = tableValue(options)
    if type(text) ~= "string" or text == "" then
        return nil, "utterance_required"
    end
    local effectiveContext = actorContext(self.actor, context)
    local parsed, parseReason = self:ParseTurn(text, options)
    if not parsed then return nil, parseReason end

    local results = {}
    local responses = {}
    if parsed.compound == true then
        for index, part in ipairs(parsed.parts or {}) do
            local result = processPart(
                self, part.text, effectiveContext, options, index
            )
            results[#results + 1] = result
            local response = buildResponse(
                self, result, effectiveContext, options
            )
            if response then responses[#responses + 1] = response end
        end
    else
        local result = processPart(
            self, tostring(parsed.rawText or text), effectiveContext, options, 1
        )
        results[1] = result
        local response = buildResponse(
            self, result, effectiveContext, options
        )
        if response then responses[1] = response end
    end
    self:ObserveResult({
        actorID = actorID(self.actor),
        rawText = text,
        parts = results,
        responses = responses,
    })
    return {
        schemaVersion = Service.VERSION,
        kind = "actor_conversation_result",
        actorID = actorID(self.actor),
        rawText = text,
        parseReason = parseReason,
        compound = parsed.compound == true,
        parts = results,
        responses = responses,
        pendingQuestion = copy(self.router.state.pendingQuestion),
        pendingRequest = copy(self.router.state.pendingRequest),
        state = self.router:Snapshot(),
        turnCount = self.turnCount,
    }
end

function Service:Snapshot()
    return {
        schemaVersion = Service.VERSION,
        actorID = actorID(self.actor),
        conversationID = self.conversationID,
        turnCount = self.turnCount,
        state = self.router:Snapshot(),
    }
end

function Service:Reset(keepParticipants)
    self.router.state:Reset(keepParticipants == true)
    self.router.lastResult = nil
    self.router.lastCandidateSet = nil
    self.router.lastCandidateDiagnostics = nil
    self.turnCount = 0
    return self:Snapshot()
end

return Service
