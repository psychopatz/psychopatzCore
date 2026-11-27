-- Client cache and command transport for PsychopatzCore actor knowledge.
-- Shared by ProjectHoomans and DynamicTrading (DTAbstract & DTHoomans).
-- Kahlua2-safe Lua 5.1.

require "PsychopatzCore/00_PsychopatzCore_Init"

local Exchange = require "PsychopatzCore/Actors/PsychopatzActorIdentityExchange"

PsychopatzCore.ActorKnowledgeClient = PsychopatzCore.ActorKnowledgeClient or {}
local Client = PsychopatzCore.ActorKnowledgeClient

Client.COMMAND_REQUEST = "ActorKnowledgeRequest"
Client.COMMAND_SNAPSHOT = "ActorKnowledgeSnapshot"
Client.COMMAND_IDENTITY_CLAIM = "ActorIdentityClaimRequest"
Client.COMMAND_IDENTITY_RESULT = "ActorIdentityClaimResult"
Client.COMMAND_DISCLOSE = "ActorKnowledgeDiscloseRequest"
Client.COMMAND_DISCLOSE_RESULT = "ActorKnowledgeDisclosureResult"

Client.Store = Client.Store or {}
Client.Listeners = Client.Listeners or {}
Client._reqSeq = Client._reqSeq or 0

local function commandModule()
    return PsychopatzCore.COMMAND_MODULE or "PsychopatzCore"
end

local function localPlayer()
    return (getSpecificPlayer and getSpecificPlayer(0))
        or (getPlayer and getPlayer())
        or nil
end

local function nextRequestID(prefix)
    Client._reqSeq = (tonumber(Client._reqSeq) or 0) + 1
    return tostring(prefix or "ak") .. ":" .. tostring(Client._reqSeq)
end

local function notifyListeners(actorID, snapshot, sourceActorID)
    for i = 1, #Client.Listeners do
        local fn = Client.Listeners[i]
        if type(fn) == "function" then
            pcall(fn, actorID, snapshot, sourceActorID)
        end
    end
end

local function activeViewFor(actorID, sourceActorID)
    local conv = PsychopatzCore and PsychopatzCore.Conversation or nil
    local view = conv and conv.instance or nil
    if not view or not view.spec then return nil end
    local vID = tostring(view.spec.npcID or "")
    local vSrc = tostring(view.spec.sourceActorID or "")
    local aKey = tostring(actorID or "")
    local sKey = tostring(sourceActorID or "")
    if (aKey ~= "" and (vID == aKey or vSrc == aKey))
        or (sKey ~= "" and (vID == sKey or vSrc == sKey))
    then
        return view
    end
    return nil
end

local function syncViewContext(view, snapshot)
    if not view or not view.spec or type(snapshot) ~= "table" then return end
    local ctx = type(view.spec.context) == "table" and view.spec.context or nil
    if not ctx then return end
    if snapshot.nameKnown == true and snapshot.knownName then
        ctx.npcName = snapshot.knownName
        ctx.knownName = snapshot.knownName
        ctx.identityState = "known"
        ctx.identityNameKnown = true
    end
    if snapshot.nicknameKnown == true and snapshot.knownNickname then
        ctx.nicknameKnown = true
        ctx.knownNickname = snapshot.knownNickname
    end
    if snapshot.surnameKnown == true and snapshot.knownSurname then
        ctx.surnameKnown = true
        ctx.knownSurname = snapshot.knownSurname
    end
    if snapshot.factionKnown == true and snapshot.factionName then
        ctx.factionKnown = true
        ctx.factionID = snapshot.factionID
        ctx.factionName = snapshot.factionName
    end
    if type(ctx.knowledge) == "table" then
        for k, v in pairs(snapshot) do
            ctx.knowledge[k] = v
        end
    end
end

local function dispatchToServer(command, args, serverMethodName)
    local player = localPlayer()
    local isRemoteClient = type(isClient) == "function" and isClient() == true
    if not isRemoteClient then
        local server = PsychopatzCore and PsychopatzCore.ActorKnowledgeServer or nil
        if server and type(server[serverMethodName]) == "function" then
            local ok, accepted, res = pcall(server[serverMethodName], player, args)
            if ok then return accepted == true, res end
            return false, "server_dispatch_error"
        end
    end
    if player and type(sendClientCommand) == "function" then
        sendClientCommand(player, commandModule(), command, args)
        return true, "dispatched"
    end
    return false, "client_transport_unavailable"
end

function Client.Subscribe(listener)
    if type(listener) ~= "function" then return function() end end
    Client.Listeners[#Client.Listeners + 1] = listener
    return function()
        for i = #Client.Listeners, 1, -1 do
            if Client.Listeners[i] == listener then
                table.remove(Client.Listeners, i)
            end
        end
    end
end

function Client.Get(actorID)
    actorID = tostring(actorID or "")
    if actorID == "" then return nil end
    return Client.Store[actorID]
end

function Client.ApplySnapshot(payload)
    if type(payload) ~= "table" or type(payload.knowledge) ~= "table" then
        return false
    end
    local actorID = tostring(payload.actorID or payload.knowledge.actorID or "")
    if actorID == "" then return false end
    local prev = Client.Store[actorID]
    local same = type(prev) == "table"
        and tonumber(prev.revision) == tonumber(payload.knowledge.revision)
        and prev.knownName == payload.knowledge.knownName
        and prev.factionName == payload.knowledge.factionName
    Client.Store[actorID] = payload.knowledge
    local srcID = payload.sourceActorID and tostring(payload.sourceActorID) or nil
    if srcID and srcID ~= "" and srcID ~= actorID then
        Client.Store[srcID] = payload.knowledge
    end
    local view = activeViewFor(actorID, srcID)
    if view then syncViewContext(view, payload.knowledge) end
    if not same then
        notifyListeners(actorID, payload.knowledge, srcID)
    end
    return true
end

function Client.Request(actorID)
    actorID = tostring(actorID or "")
    if actorID == "" then return false, "actor_required" end
    return dispatchToServer(Client.COMMAND_REQUEST, {
        actorID = actorID,
    }, "HandleKnowledgeRequest")
end

function Client.SubmitIdentityClaim(actorID, options)
    actorID = tostring(actorID or "")
    options = type(options) == "table" and options or {}
    if actorID == "" then return false, "actor_required" end
    local reqID = options.requestID or nextRequestID("core_id")
    local args = {
        requestID = reqID,
        actorID = actorID,
        sourceActorID = options.sourceActorID,
        provider = options.provider,
        kind = options.kind or Exchange.EVENT_CLAIM,
        claimMode = options.claimMode,
        claimedName = options.claimedName,
        responseStyle = options.responseStyle,
        origin = options.origin or "trader_conversation",
    }
    return dispatchToServer(Client.COMMAND_IDENTITY_CLAIM, args, "HandleIdentityClaim")
end

function Client.RequestDisclosure(actorID, topicID, options)
    actorID = tostring(actorID or "")
    topicID = tostring(topicID or "")
    options = type(options) == "table" and options or {}
    if actorID == "" or topicID == "" then
        return false, "invalid_disclosure_request"
    end
    local reqID = options.requestID or nextRequestID("core_disc")
    local args = {
        requestID = reqID,
        actorID = actorID,
        sourceActorID = options.sourceActorID,
        provider = options.provider,
        topicID = topicID,
        origin = options.origin or "trader_conversation",
    }
    return dispatchToServer(Client.COMMAND_DISCLOSE, args, "HandleDiscloseTopic")
end

local function deliverResponse(args)
    if type(args) ~= "table" then return end
    if type(args.knowledge) == "table" then
        Client.ApplySnapshot({
            actorID = args.actorID,
            sourceActorID = args.sourceActorID,
            knowledge = args.knowledge,
        })
    end
    local text = args.responseText
    if type(text) ~= "string" or text == "" then return end
    local view = activeViewFor(args.actorID, args.sourceActorID)
    if view and view.session then
        if type(view.session.queueMessage) == "function" then
            view.session:queueMessage("npc", { text = text, fallback = text })
        elseif type(view.session.append) == "function" then
            view.session:append("npc", { text = text, fallback = text })
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= commandModule() then return end
    if command == Client.COMMAND_SNAPSHOT then
        Client.ApplySnapshot(args)
    elseif command == Client.COMMAND_IDENTITY_RESULT
        or command == Client.COMMAND_DISCLOSE_RESULT
    then
        deliverResponse(args)
    end
end

if Events and Events.OnServerCommand and Events.OnServerCommand.Add
    and not Client._serverHook
then
    Client._serverHook = true
    Events.OnServerCommand.Add(onServerCommand)
end

return Client
