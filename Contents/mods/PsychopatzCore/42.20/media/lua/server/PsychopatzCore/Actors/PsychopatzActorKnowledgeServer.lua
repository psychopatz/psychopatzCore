-- Server-authoritative per-player actor knowledge and identity exchange.
-- Shared by ProjectHoomans and DynamicTrading (DTAbstract & DTHoomans).
-- Kahlua2-safe Lua 5.1.

require "PsychopatzCore/00_PsychopatzCore_Init"

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Knowledge = require "PsychopatzCore/Actors/PsychopatzActorKnowledge"
local Exchange = require "PsychopatzCore/Actors/PsychopatzActorIdentityExchange"
local ActorNames = require "PsychopatzCore/Actors/PsychopatzActorNames"

PsychopatzCore.ActorKnowledgeServer = PsychopatzCore.ActorKnowledgeServer or {}
local Server = PsychopatzCore.ActorKnowledgeServer

Server.COMMAND_REQUEST = "ActorKnowledgeRequest"
Server.COMMAND_SNAPSHOT = "ActorKnowledgeSnapshot"
Server.COMMAND_IDENTITY_CLAIM = "ActorIdentityClaimRequest"
Server.COMMAND_IDENTITY_RESULT = "ActorIdentityClaimResult"
Server.COMMAND_DISCLOSE = "ActorKnowledgeDiscloseRequest"
Server.COMMAND_DISCLOSE_RESULT = "ActorKnowledgeDisclosureResult"
Server.AuthorityHooks = Server.AuthorityHooks or {}
Server.FallbackActors = Server.FallbackActors or {}

local function commandModule()
    return PsychopatzCore.COMMAND_MODULE or "PsychopatzCore"
end

local function localPlayer(player)
    local current = getSpecificPlayer and getSpecificPlayer(0) or nil
    return current ~= nil and current == player
end

local function sendToPlayer(player, command, payload)
    if localPlayer(player) and type(triggerEvent) == "function" then
        triggerEvent("OnServerCommand", commandModule(), command, payload)
        return true
    end
    if player and type(sendServerCommand) == "function" then
        sendServerCommand(player, commandModule(), command, payload)
        return true
    end
    if type(triggerEvent) == "function"
        and (not isServer or not isServer())
    then
        triggerEvent("OnServerCommand", commandModule(), command, payload)
        return true
    end
    return false
end

local function playerKeyFor(player)
    if type(player) == "table" and type(player.characterUUID) == "string"
        and player.characterUUID ~= ""
    then
        return Knowledge.NormalizePlayerKey(player.characterUUID)
    end
    local pID = PsychopatzCore and PsychopatzCore.PlayerIdentity or nil
    if pID and type(pID.GetKey) == "function" then
        local ok, key = pcall(pID.GetKey, player)
        if ok and type(key) == "string" and key ~= "" then
            return Knowledge.NormalizePlayerKey(key)
        end
    end
    if player then
        if type(player.getOnlineID) == "function" then
            local ok, oid = pcall(player.getOnlineID, player)
            if ok and tonumber(oid) ~= nil and tonumber(oid) >= 0 then
                return Knowledge.NormalizePlayerKey("online_" .. tostring(math.floor(tonumber(oid))))
            end
        end
        if type(player.getUsername) == "function" then
            local ok, uname = pcall(player.getUsername, player)
            if ok and type(uname) == "string" and uname ~= "" then
                return Knowledge.NormalizePlayerKey(uname)
            end
        end
    end
    return "player:local"
end

local function resolveActor(actorID)
    actorID = tostring(actorID or "")
    if actorID == "" then return nil, nil end
    local registry = PsychopatzCore and PsychopatzCore.ActorRegistry or nil
    if registry then
        local actor = (type(registry.Get) == "function" and registry.Get(actorID))
            or (type(registry.Resolve) == "function" and registry.Resolve(actorID))
            or nil
        if type(actor) == "table" then
            return actor, registry
        end
    end
    local fallback = Server.FallbackActors[actorID]
    if type(fallback) == "table" then
        return fallback, nil
    end
    return nil, nil
end

local function persistActor(actor, registry)
    if not actor then return end
    if registry and type(registry.Put) == "function" then
        pcall(registry.Put, actor)
    end
    local persistence = PsychopatzCore and PsychopatzCore.ActorPersistence or nil
    if persistence and type(persistence.MarkDirty) == "function" then
        pcall(persistence.MarkDirty, actor.actorId or actor.id)
    end
end

local function actorFamiliarity(actor, playerKey)
    local social = type(actor) == "table" and actor.social or nil
    local rels = type(social) == "table" and social.relationships or nil
    local rel = type(rels) == "table" and (rels[playerKey] or rels[string.gsub(playerKey, "^player:", "")]) or nil
    if type(rel) ~= "table" then return 0 end
    return math.max(0, tonumber(rel.familiarity) or tonumber(rel.trust) or tonumber(rel.affinity) or 0)
end

local function actorParts(actor)
    if type(actor) ~= "table" then return {} end
    local identity = type(actor.identity) == "table" and actor.identity or {}
    return ActorNames.ResolveParts({
        identity = identity,
        displayName = identity.displayName or actor.displayName or actor.name,
        identitySeed = actor.identitySeed or actor.actorId or actor.id,
        isFemale = actor.isFemale,
    }, { resolveNickname = true, includeNickname = true }) or {}
end

local function projectForPlayer(actor, playerKey)
    local actorID = tostring(actor.actorId or actor.id or "")
    local state = type(actor.knowledge) == "table" and actor.knowledge or nil
    local playerRec = state and type(state.byPlayer) == "table"
        and state.byPlayer[playerKey] or nil
    local facts = playerRec and type(playerRec.facts) == "table"
        and playerRec.facts or {}
    local nameFact = facts["identity.name"]
    local nickFact = facts["identity.nickname"]
    local fullFact = facts["identity.full_name"]
    local factionFact = facts["faction.identity"]
    local nameKnown = (nameFact ~= nil) or (nickFact ~= nil) or (fullFact ~= nil)
    local knownName = (fullFact and tostring(fullFact.value))
        or (nameFact and tostring(nameFact.value))
        or (nickFact and tostring(nickFact.value))
        or nil
    local knownNickname = nickFact and tostring(nickFact.value) or nil
    local knownSurname = nil
    if fullFact and type(fullFact.value) == "string" then
        local _, sur = ActorNames.Split(fullFact.value)
        knownSurname = sur
    end
    local factionVal = factionFact and factionFact.value or nil
    local factionName = type(factionVal) == "table" and factionVal.factionName
        or (type(factionVal) == "string" and factionVal or nil)
    local factionID = type(factionVal) == "table" and factionVal.factionID or nil
    return {
        actorID = actorID,
        provider = actor.provider or "Core",
        state = nameKnown and "known" or "unknown",
        nameKnown = nameKnown,
        knownName = knownName,
        nicknameKnown = knownNickname ~= nil,
        knownNickname = knownNickname,
        surnameKnown = knownSurname ~= nil,
        knownSurname = knownSurname,
        factionKnown = factionName ~= nil and factionName ~= "",
        factionID = factionID,
        factionName = factionName,
        revision = playerRec and tonumber(playerRec.revision) or 0,
    }
end

local function ensureKnowledgeState(actor)
    if type(actor.knowledge) ~= "table"
        or type(actor.knowledge.byPlayer) ~= "table"
    then
        actor.knowledge = Knowledge.NewState()
    end
    return actor.knowledge
end

local function nowHour()
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getWorldAgeHours) == "function" then
            return tonumber(gt:getWorldAgeHours()) or 0
        end
    end
    return 0
end

local function recordFact(actor, playerKey, factID, value, sourceType, reqID)
    local state = ensureKnowledgeState(actor)
    local updated, err = Knowledge.Record(state, {
        playerKey = playerKey,
        factID = factID,
        status = "confirmed",
        value = value,
        confidence = 1.0,
        discoveredAt = nowHour(),
        evidence = {
            id = tostring(reqID or factID) .. ":" .. tostring(factID),
            sourceType = sourceType or "conversation",
        },
    }, "server")
    if updated then
        actor.knowledge = updated
        return true
    end
    return false, err
end

function Server.RegisterAuthorityHook(providerID, hooks)
    providerID = tostring(providerID or "")
    if providerID == "" or type(hooks) ~= "table" then return false end
    Server.AuthorityHooks[providerID] = hooks
    return true
end

function Server.HandleKnowledgeRequest(player, args)
    args = type(args) == "table" and args or {}
    local playerKey = playerKeyFor(player)
    local actorID = tostring(args.actorID or "")
    if actorID ~= "" then
        local actor = resolveActor(actorID)
        if not actor then return false, "actor_not_found" end
        local snapshot = projectForPlayer(actor, playerKey)
        sendToPlayer(player, Server.COMMAND_SNAPSHOT, {
            actorID = actorID,
            knowledge = snapshot,
        })
        return true, snapshot
    end
    return false, "actor_required"
end

function Server.HandleIdentityClaim(player, args)
    args = type(args) == "table" and args or {}
    local actorID = tostring(args.actorID or "")
    local actor, registry = resolveActor(actorID)
    if not actor then
        local result = {
            actorID = actorID,
            requestID = args.requestID,
            accepted = false,
            reason = "actor_not_found",
        }
        sendToPlayer(player, Server.COMMAND_IDENTITY_RESULT, result)
        return false, "actor_not_found"
    end
    local playerKey = playerKeyFor(player)
    local kind = tostring(args.kind or Exchange.EVENT_CLAIM)
    local providerID = tostring(args.provider or actor.provider or "Core")
    local hook = Server.AuthorityHooks[providerID]
    local reqID = tostring(args.requestID or ("claim:" .. actorID .. ":" .. tostring(nowHour())))

    if kind == Exchange.EVENT_EVASION then
        local result = {
            actorID = actorID,
            sourceActorID = args.sourceActorID,
            requestID = reqID,
            kind = kind,
            accepted = true,
            truthful = false,
            disclosed = false,
            responseText = "Fair enough. Then I'll keep mine to myself too.",
        }
        if hook and type(hook.onIdentityClaim) == "function" then
            pcall(hook.onIdentityClaim, player, actor, result)
        end
        sendToPlayer(player, Server.COMMAND_IDENTITY_RESULT, result)
        return true, result
    end

    local canonicalPlayerName = Exchange.ResolvePlayerName(player)
    local truthful, verifiedName, verifyErr = Exchange.VerifyClaim(
        args.claimedName, canonicalPlayerName, args.claimMode
    )
    if verifyErr == "identity_claim_missing" or verifyErr == "identity_alias_conflict" then
        local result = {
            actorID = actorID,
            sourceActorID = args.sourceActorID,
            requestID = reqID,
            kind = kind,
            accepted = false,
            reason = verifyErr,
            responseText = "I couldn't verify your name just now. Could you tell me again?",
        }
        sendToPlayer(player, Server.COMMAND_IDENTITY_RESULT, result)
        return false, verifyErr
    end

    if truthful ~= true then
        -- Lie detected: never persist the fake alias and do not reveal NPC name.
        local result = {
            actorID = actorID,
            sourceActorID = args.sourceActorID,
            requestID = reqID,
            kind = kind,
            accepted = true,
            truthful = false,
            disclosed = false,
            trustLabel = Exchange.TRUST_UNTRUSTWORTHY,
            responseText = "That isn't your exact name. Don't lie to me.",
        }
        if hook and type(hook.onIdentityClaim) == "function" then
            pcall(hook.onIdentityClaim, player, actor, result)
        end
        sendToPlayer(player, Server.COMMAND_IDENTITY_RESULT, result)
        return true, result
    end

    local familiarity = actorFamiliarity(actor, playerKey)
    local parts = actorParts(actor)
    local disclosedName, level = Exchange.ResolveInitialDisclosedName(parts, familiarity)
    if disclosedName == "" then disclosedName = tostring(actor.displayName or actor.name or "the trader") end

    recordFact(actor, playerKey, "identity.name", disclosedName, "identity_exchange", reqID)
    if level == "nickname" then
        recordFact(actor, playerKey, "identity.nickname", disclosedName, "identity_exchange", reqID)
    elseif level == "full_name" then
        recordFact(actor, playerKey, "identity.full_name", parts.fullName or disclosedName, "identity_exchange", reqID)
        if parts.nickname and parts.nickname ~= "" then
            recordFact(actor, playerKey, "identity.nickname", parts.nickname, "identity_exchange", reqID)
        end
    end
    persistActor(actor, registry)

    local snapshot = projectForPlayer(actor, playerKey)
    local playerFirst = Exchange.FirstName(verifiedName)
    local reply = playerFirst ~= ""
        and ("Okay " .. playerFirst .. ", nice to meet you. I'm " .. disclosedName .. ".")
        or ("I'm " .. disclosedName .. ".")
    local result = {
        actorID = actorID,
        sourceActorID = args.sourceActorID,
        requestID = reqID,
        kind = kind,
        accepted = true,
        truthful = true,
        disclosed = true,
        disclosedName = disclosedName,
        identityLevel = level,
        responseText = reply,
        knowledge = snapshot,
    }
    if hook and type(hook.onIdentityClaim) == "function" then
        pcall(hook.onIdentityClaim, player, actor, result)
    end
    sendToPlayer(player, Server.COMMAND_SNAPSHOT, {
        actorID = actorID,
        sourceActorID = args.sourceActorID,
        knowledge = snapshot,
    })
    sendToPlayer(player, Server.COMMAND_IDENTITY_RESULT, result)
    return true, result
end

function Server.HandleDiscloseTopic(player, args)
    args = type(args) == "table" and args or {}
    local actorID = tostring(args.actorID or "")
    local topicID = tostring(args.topicID or "")
    local actor, registry = resolveActor(actorID)
    if not actor or topicID == "" then
        return false, "invalid_disclosure_request"
    end
    local playerKey = playerKeyFor(player)
    local familiarity = actorFamiliarity(actor, playerKey)
    local parts = actorParts(actor)
    local reqID = tostring(args.requestID or ("disc:" .. actorID .. ":" .. topicID))
    local reply = nil
    local accepted = false
    local reason = nil

    if topicID == "identity_nickname" then
        if parts.nickname and parts.nickname ~= "" then
            recordFact(actor, playerKey, "identity.nickname", parts.nickname, "conversation", reqID)
            accepted = true
            reply = "Most people call me " .. parts.nickname .. "."
        else
            accepted = true
            reply = "I don't really use a nickname."
        end
    elseif topicID == "identity_full_name" then
        local minFam = Exchange.FAMILIARITY_THRESHOLDS.identity_surname or 20
        if familiarity < minFam then
            reason = "insufficient_familiarity"
            reply = "Let's stick to first names until we know each other a bit better."
        elseif parts.fullName and parts.fullName ~= "" then
            recordFact(actor, playerKey, "identity.full_name", parts.fullName, "conversation", reqID)
            accepted = true
            reply = parts.surname and parts.surname ~= ""
                and ("My surname is " .. parts.surname .. ".")
                or ("My full name is " .. parts.fullName .. ".")
        else
            reason = "not_available"
            reply = "I don't have much more to add to my name."
        end
    elseif topicID == "faction" then
        local minFam = Exchange.FAMILIARITY_THRESHOLDS.faction or 10
        if familiarity < minFam then
            reason = "insufficient_familiarity"
            reply = "We haven't known each other long enough for me to get into who I'm with."
        else
            local fname = actor.factionName or (actor.affiliation and actor.affiliation.factionName)
            local fid = actor.factionID or (actor.affiliation and actor.affiliation.factionID)
            if fname and tostring(fname) ~= "" then
                recordFact(actor, playerKey, "faction.identity", {
                    factionID = tostring(fid or ""),
                    factionName = tostring(fname),
                }, "conversation", reqID)
                accepted = true
                reply = "I'm with " .. tostring(fname) .. "."
            else
                accepted = true
                reply = "I don't belong to any group I can name."
            end
        end
    else
        reason = "unsupported_topic"
    end

    if accepted then persistActor(actor, registry) end
    local snapshot = projectForPlayer(actor, playerKey)
    local result = {
        actorID = actorID,
        sourceActorID = args.sourceActorID,
        requestID = reqID,
        topicID = topicID,
        accepted = accepted,
        reason = reason,
        responseText = reply,
        knowledge = snapshot,
    }
    if accepted then
        sendToPlayer(player, Server.COMMAND_SNAPSHOT, {
            actorID = actorID,
            sourceActorID = args.sourceActorID,
            knowledge = snapshot,
        })
    end
    sendToPlayer(player, Server.COMMAND_DISCLOSE_RESULT, result)
    return accepted, result
end

local function onClientCommand(module, command, player, args)
    if module ~= commandModule() then return end
    if command == Server.COMMAND_REQUEST then
        Server.HandleKnowledgeRequest(player, args)
    elseif command == Server.COMMAND_IDENTITY_CLAIM then
        Server.HandleIdentityClaim(player, args)
    elseif command == Server.COMMAND_DISCLOSE then
        Server.HandleDiscloseTopic(player, args)
    end
end

if Events and Events.OnClientCommand and Events.OnClientCommand.Add
    and not Server._clientCommandHook
then
    Server._clientCommandHook = true
    Events.OnClientCommand.Add(onClientCommand)
end

return Server
