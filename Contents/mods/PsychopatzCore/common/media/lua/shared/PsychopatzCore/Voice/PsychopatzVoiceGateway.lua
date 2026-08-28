--[[-
    Optional, mod-agnostic conversation voice gateway.

    Conversation.Message is the canonical message bus. This module only
    adapts resolved NPC messages into a bounded Core packet stream; it does
    not know about a particular mod's NPC registry, TTS provider, or UI.
    Integrations register a source and may enrich a message with a compact
    voice binding and speech policy.

    The gateway is deliberately opt-in. With no registered source it owns no
    event subscription and no tick callback, so Core users that do not need
    voice pay no per-frame cost.
]]

require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Events/PC_EventBus"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.VoiceGateway = PsychopatzCore.VoiceGateway or {}

local Gateway = PsychopatzCore.VoiceGateway
local Message = PsychopatzCore.Conversation.Message
local EventBus = PsychopatzCore.Events
local PZEvents = Events

Gateway.VERSION = 1
Gateway.NAMESPACE = "psychopatzcore.voice"
Gateway.CHANNEL = "utterances"
Gateway.EVENT_TYPE = "PsychopatzCore.Voice.Utterance"
Gateway.LIFECYCLE_EVENT_TYPE = "PsychopatzCore.Voice.Lifecycle"
Gateway.ENQUEUE_EVENT = "speech.enqueue"
Gateway.MAX_TEXT = 3900
Gateway.MAX_PENDING = 64
Gateway.MAX_RECENT = 256
Gateway.PENDING_TTL_MS = 15000
Gateway.CHANNEL_EVENTS = 128

local OWNER_TOKEN = Gateway
local sources = {}
local sourceOrder = {}
local pending = {}
local recent = {}
local recentOrder = {}
local channelReady = false
local commandsRegistered = false
local tickInstalled = false
local resetInstalled = false
local lastEnsureAt = 0

local function nowMs()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function text(value, limit)
    local result = tostring(value or "")
    result = string.gsub(result, "^%s+", "")
    result = string.gsub(result, "%s+$", "")
    if limit and #result > limit then result = string.sub(result, 1, limit) end
    return result
end

local function copyScalarMap(value, limit)
    local output = {}
    if type(value) ~= "table" then return output end
    local count = 0
    local key
    local item
    for key, item in pairs(value) do
        if count >= (limit or 16) then break end
        if type(key) == "string" and (
            type(item) == "string"
            or type(item) == "number"
            or type(item) == "boolean"
        ) then
            output[key] = item
            count = count + 1
        end
    end
    return output
end

local function copySource(value)
    local output = {}
    if type(value) ~= "table" then return output end
    local allowed = {
        kind = true, channel = true, requestID = true, request_id = true,
        sessionID = true, session_id = true, source = true, modID = true,
        mod_id = true,
    }
    local key
    local item
    for key, item in pairs(value) do
        if allowed[key] and (
            type(item) == "string"
            or type(item) == "number"
            or type(item) == "boolean"
        ) then
            output[key] = item
        end
    end
    return output
end

local function copySpeech(value)
    if type(value) ~= "table" then return nil end
    local output = {}
    local fields = {
        mode = true, speech_mode = true, priority = true,
        allow_overlap = true, allowOverlap = true,
        can_interrupt = true, canInterrupt = true,
        cancel_group = true, cancelGroup = true,
        expires_after_ms = true, expiresAfterMs = true,
    }
    local key
    local item
    for key, item in pairs(value) do
        if fields[key] and (
            type(item) == "string"
            or type(item) == "number"
            or type(item) == "boolean"
        ) then
            output[key] = item
        end
    end
    return output
end

local function bridge()
    return PsychopatzCore and PsychopatzCore.Bridge or nil
end

local function bridgeCanPublish()
    local current = bridge()
    if not current or type(current.RegisterPacketChannel) ~= "function"
        or type(current.PublishPacket) ~= "function"
    then
        return false
    end
    return current.lifecycle == nil or current.lifecycle == "READY"
end

local function bridgeConfigured()
    local bootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap or nil
    if bootstrap and bootstrap.GetConfig then
        local ok, config = pcall(bootstrap.GetConfig)
        return ok and type(config) == "table" and config.enabled == true
    end
    return bridgeCanPublish()
end

local function registerLifecycleCommands()
    if commandsRegistered then return true end
    local current = bridge()
    if not current or type(current.RegisterCommand) ~= "function" then
        return false
    end
    local commands = { "speechStarted", "speechFinished", "speechFailed" }
    local function lifecycleHandler(command)
        return function(_, arguments)
            return Gateway.ReceiveLifecycle(command, arguments)
        end
    end
    local index
    for index = 1, #commands do
        local command = commands[index]
        local ok, reason = current.RegisterCommand(
            Gateway.NAMESPACE,
            command,
            {
                readOnly = false,
                category = "voice",
                handler = lifecycleHandler(command),
            }
        )
        if not ok and reason ~= "duplicate_command" then return false end
    end
    commandsRegistered = true
    return true
end

local function ensureChannel(force)
    if not bridgeCanPublish() then
        channelReady = false
        return false
    end
    local currentTime = nowMs()
    if not force and currentTime - lastEnsureAt < 500 then
        return channelReady
    end
    lastEnsureAt = currentTime
    local current = bridge()
    if not channelReady then
        local ok, reason = current.RegisterPacketChannel(
            Gateway.NAMESPACE,
            Gateway.CHANNEL,
            { maxEvents = Gateway.CHANNEL_EVENTS }
        )
        channelReady = ok == true or reason == "duplicate_channel"
        if channelReady and type(current.SetPacketSnapshot) == "function" then
            -- Voice packets are ephemeral. The empty snapshot lets a
            -- consumer advance past a retention gap without replaying stale
            -- speech or getting stuck on the same gap forever.
            pcall(
                current.SetPacketSnapshot,
                Gateway.NAMESPACE,
                Gateway.CHANNEL,
                { schema_version = Gateway.VERSION, ephemeral = true }
            )
        end
    end
    if channelReady then registerLifecycleCommands() end
    return channelReady
end

local function recentKey(sourceID, message)
    return tostring(sourceID) .. ":" .. tostring(message.messageID or "")
end

local function hasRecent(key)
    return recent[key] == true
end

local function remember(key)
    if recent[key] then return end
    recent[key] = true
    recentOrder[#recentOrder + 1] = key
    while #recentOrder > Gateway.MAX_RECENT do
        local expired = table.remove(recentOrder, 1)
        recent[expired] = nil
    end
end

local function messageSpeech(message, enriched)
    local state = type(message.presentationState) == "table"
        and message.presentationState or {}
    local speech = enriched and (enriched.speech or enriched.speech_policy)
        or state.speech or state.speechPolicy
    return copySpeech(speech)
end

local function voiceBinding(message, enriched)
    local state = type(message.presentationState) == "table"
        and message.presentationState or {}
    return (enriched and (enriched.voice_binding or enriched.voiceBinding))
        or message.voiceBinding
        or state.voice_binding
        or state.voiceBinding
end

local function buildEnvelope(sourceID, message, enriched)
    local rawText = tostring(message.text or "")
    local resolved = text(rawText, Gateway.MAX_TEXT)
    if resolved == "" then return nil end
    local payload = type(message.payload) == "table" and message.payload or {}
    local state = type(message.presentationState) == "table"
        and message.presentationState or {}
    local source = copySource(message.source)
    local speech = messageSpeech(message, enriched)
    local binding = voiceBinding(message, enriched)
    local envelope = {
        schema_version = Gateway.VERSION,
        event_type = Gateway.ENQUEUE_EVENT,
        utterance_id = tostring(
            enriched and enriched.utterance_id or message.messageID
        ),
        message_id = tostring(message.messageID or ""),
        source_mod = tostring(sourceID),
        save_uuid = tostring(message.saveUUID or ""),
        conversation_id = tostring(message.conversationID or ""),
        sequence = tonumber(message.sequence) or 0,
        game_day = tonumber(message.gameDay) or 0,
        world_age_hours = tonumber(message.worldAgeHours) or 0,
        speaker_id = tostring(message.speakerID or message.npcUUID or ""),
        speaker_name = text(message.speakerName, 256),
        speaker_kind = tostring(message.speakerKind or message.speaker or "npc"),
        player_uuid = tostring(message.playerUUID or ""),
        npc_uuid = tostring(message.npcUUID or message.speakerID or ""),
        namespace = tostring(message.namespace or ""),
        text = resolved,
        text_truncated = #rawText > Gateway.MAX_TEXT,
        text_key = text(payload.key, 256),
        text_domain = text(payload.domain, 256),
        text_args = copyScalarMap(payload.args, 16),
        source = source,
        presentation = {
            conversation_ui = state.conversationUI ~= false,
            nameplate = state.nameplate == true,
            tts = state.tts ~= false,
        },
        created_real_time_ms = nowMs(),
    }
    if type(binding) == "table" then
        envelope.voice_binding = {
            npc_uuid = tostring(binding.npc_uuid or binding.npcUUID or envelope.npc_uuid),
            slot = text(binding.slot, 128),
            pitch = tonumber(binding.pitch) or 0,
        }
    end
    if speech then envelope.speech = speech end
    if enriched and type(enriched.audience) == "table" then
        envelope.audience = copyScalarMap(enriched.audience, 16)
    end
    return envelope
end

local function queuePending(envelope, source)
    local ttl = tonumber(source.pendingTTL or source.pending_ttl_ms)
        or Gateway.PENDING_TTL_MS
    ttl = math.max(1000, math.min(ttl, 60000))
    if #pending >= Gateway.MAX_PENDING then table.remove(pending, 1) end
    pending[#pending + 1] = {
        envelope = envelope,
        expiresAt = nowMs() + ttl,
    }
    return true
end

local function publishEnvelope(envelope, source)
    if not ensureChannel(false) then
        if source.bufferUntilReady == true or source.buffer_until_ready == true then
            return queuePending(envelope, source), "queued"
        end
        return false, "bridge_unavailable"
    end
    local current = bridge()
    local ok, reason = current.PublishPacket(
        Gateway.NAMESPACE, Gateway.CHANNEL, envelope
    )
    if ok then return true, "published" end
    channelReady = false
    if source.bufferUntilReady == true or source.buffer_until_ready == true then
        return queuePending(envelope, source), reason or "queued"
    end
    return false, reason or "publish_failed"
end

local function flushPending()
    if #pending == 0 or not ensureChannel(false) then return end
    local currentTime = nowMs()
    local retained = {}
    local index = 1
    while index <= #pending do
        local item = pending[index]
        if item.expiresAt > currentTime then
            local ok = bridge().PublishPacket(
                Gateway.NAMESPACE, Gateway.CHANNEL, item.envelope
            )
            if ok then
                -- It was already deduplicated at enqueue time.
            else
                channelReady = false
                retained[#retained + 1] = item
                index = index + 1
                break
            end
        end
        index = index + 1
    end
    while index <= #pending do
        retained[#retained + 1] = pending[index]
        index = index + 1
    end
    pending = retained
end

local function sourceAccepts(source, message)
    if type(source.filter) ~= "function" then
        return message.speakerKind == "npc" and text(message.text) ~= ""
    end
    local ok, accepted = pcall(source.filter, message)
    return ok and accepted == true
end

local function enrich(source, message)
    if type(source.enrich) ~= "function" then return {} end
    local ok, value = pcall(source.enrich, message)
    return ok and type(value) == "table" and value or {}
end

local function onMessage(message)
    if type(message) ~= "table" or #sourceOrder == 0 then return end
    -- Avoid running any mod-specific resolver while the optional bridge is
    -- disabled. The adapter remains registered and becomes live as soon as
    -- Core's bridge is enabled.
    if not bridgeConfigured() then return end
    local index
    for index = 1, #sourceOrder do
        local sourceID = sourceOrder[index]
        local source = sources[sourceID]
        if source and sourceAccepts(source, message) then
            local key = recentKey(sourceID, message)
            if not hasRecent(key) then
                local envelope = buildEnvelope(sourceID, message, enrich(source, message))
                if envelope then
                    local accepted = publishEnvelope(envelope, source)
                    if accepted then remember(key) end
                end
            end
            -- A canonical message belongs to its first accepting source.
            return
        end
    end
end

local function onTick()
    if #sourceOrder == 0 then return end
    if bridgeConfigured() then
        ensureChannel(false)
        flushPending()
    end
end

local function coreTickRequired()
    local index
    for index = 1, #sourceOrder do
        local source = sources[sourceOrder[index]]
        if source and source.externalTick ~= true then return true end
    end
    return false
end

local function refreshTickSubscription()
    local required = coreTickRequired()
    if required and not tickInstalled
        and PZEvents and PZEvents.OnTick and PZEvents.OnTick.Add
    then
        PZEvents.OnTick.Add(onTick)
        tickInstalled = true
    elseif not required and tickInstalled
        and PZEvents and PZEvents.OnTick and PZEvents.OnTick.Remove
    then
        PZEvents.OnTick.Remove(onTick)
        tickInstalled = false
    end
end

local function resetRuntime()
    pending = {}
    recent = {}
    recentOrder = {}
    channelReady = false
    commandsRegistered = false
    lastEnsureAt = 0
end

function Gateway.ReceiveLifecycle(command, arguments)
    if type(arguments) ~= "table" then
        return nil, "INVALID_ARGUMENTS", "Voice lifecycle payload is not an object."
    end
    local event = copyScalarMap(arguments, 24)
    event.event = command
    event.version = Gateway.VERSION
    if EventBus and EventBus.emit then
        EventBus.emit(Gateway.LIFECYCLE_EVENT_TYPE, event)
    end
    return { accepted = true, event = command }
end

function Gateway.RegisterSource(sourceID, options)
    sourceID = text(sourceID, 96)
    if sourceID == "" then return false, "invalid_source" end
    options = type(options) == "table" and options or {}
    if not sources[sourceID] then sourceOrder[#sourceOrder + 1] = sourceID end
    sources[sourceID] = options
    if #sourceOrder == 1 then
        if EventBus and EventBus.subscribe then
            EventBus.subscribe(Message.EVENT_TYPE, onMessage, OWNER_TOKEN)
        end
        if PZEvents and PZEvents.OnResetLua and PZEvents.OnResetLua.Add then
            PZEvents.OnResetLua.Add(resetRuntime)
            resetInstalled = true
        end
    end
    refreshTickSubscription()
    ensureChannel(true)
    return true
end

function Gateway.UnregisterSource(sourceID)
    sourceID = text(sourceID, 96)
    if not sources[sourceID] then return false end
    sources[sourceID] = nil
    local retainedPending = {}
    local pendingIndex
    for pendingIndex = 1, #pending do
        if pending[pendingIndex].envelope.source_mod ~= sourceID then
            retainedPending[#retainedPending + 1] = pending[pendingIndex]
        end
    end
    pending = retainedPending
    local index
    for index = #sourceOrder, 1, -1 do
        if sourceOrder[index] == sourceID then table.remove(sourceOrder, index) end
    end
    refreshTickSubscription()
    if #sourceOrder == 0 then
        if EventBus and EventBus.clearOwner then EventBus.clearOwner(OWNER_TOKEN) end
        if resetInstalled and PZEvents and PZEvents.OnResetLua
            and PZEvents.OnResetLua.Remove
        then
            PZEvents.OnResetLua.Remove(resetRuntime)
        end
        tickInstalled = false
        resetInstalled = false
        resetRuntime()
    end
    return true
end

-- Convenience alias for integrations that own only one source.
function Gateway.Enable(options)
    options = type(options) == "table" and options or {}
    return Gateway.RegisterSource(
        options.source_mod or options.sourceMod or "default",
        options
    )
end

function Gateway.Disable(sourceID)
    return Gateway.UnregisterSource(sourceID or "default")
end

function Gateway.Reset()
    resetRuntime()
end

-- A host that already owns one safe game tick can drive the gateway itself.
-- This avoids installing another Core callback for integrations such as the
-- Hoomans client bridge while keeping the default source API standalone.
Gateway.Update = onTick

function Gateway.Cancel(cancelGroup)
    cancelGroup = text(cancelGroup, 128)
    if cancelGroup == "" then return 0 end
    local retained = {}
    local removed = 0
    local index
    for index = 1, #pending do
        local speech = pending[index].envelope.speech
        if speech and text(speech.cancel_group or speech.cancelGroup) == cancelGroup then
            removed = removed + 1
        else
            retained[#retained + 1] = pending[index]
        end
    end
    pending = retained
    return removed
end

function Gateway.GetStatus()
    local registered = {}
    local index
    for index = 1, #sourceOrder do registered[index] = sourceOrder[index] end
    return {
        version = Gateway.VERSION,
        namespace = Gateway.NAMESPACE,
        channel = Gateway.CHANNEL,
        channel_ready = channelReady,
        pending = #pending,
        sources = registered,
        enabled = #sourceOrder > 0,
    }
end

return Gateway
