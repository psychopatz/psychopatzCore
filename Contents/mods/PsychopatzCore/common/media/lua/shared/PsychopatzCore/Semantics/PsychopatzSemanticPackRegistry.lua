-- Generic Semantic Pack and Action Provider Registry for PsychopatzCore.
--
-- Core owns the generic registry and capability gating; adopting mods
-- (DynamicTrading, ProjectHoomans) register modular semantic packs and action
-- providers without cross-mod dependencies.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local PackRegistry = {}
PsychopatzCore.Semantics.PackRegistry = PackRegistry

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Flow = require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueFlow"

PackRegistry.Packs = PackRegistry.Packs or {}
PackRegistry.ActionProviders = PackRegistry.ActionProviders or {}
PackRegistry.DialogueBlocks = PackRegistry.DialogueBlocks or {}
PackRegistry.Revision = PackRegistry.Revision or 0

local function bumpRevision()
    PackRegistry.Revision = (PackRegistry.Revision or 0) + 1
end

function PackRegistry.Reset()
    PackRegistry.Packs = {}
    PackRegistry.ActionProviders = {}
    PackRegistry.DialogueBlocks = {}
    bumpRevision()
end

function PackRegistry.GetRevision()
    return PackRegistry.Revision or 0
end

local function hasCapability(capabilities, capabilityID)
    if not capabilityID or capabilityID == "" then return true end
    if type(capabilities) ~= "table" then return false end
    return capabilities[capabilityID] == true
end

function PackRegistry.RegisterActionProvider(providerSpec)
    if type(providerSpec) ~= "table" then
        return nil, "action_provider_spec_required"
    end
    local id = providerSpec.id
    if type(id) ~= "string" or id == "" then
        return nil, "action_provider_id_required"
    end
    if type(providerSpec.collect) ~= "function" then
        return nil, "action_provider_collect_required"
    end

    local provider = {
        id = id,
        ownerModID = providerSpec.ownerModID or "core",
        sourceKind = providerSpec.sourceKind or "generic",
        capabilityRequired = providerSpec.capabilityRequired,
        order = tonumber(providerSpec.order) or 50,
        collect = providerSpec.collect,
        metadata = Util.clone(providerSpec.metadata or {}),
        packID = providerSpec.packID,
    }
    PackRegistry.ActionProviders[id] = provider
    bumpRevision()
    return Util.clone(provider)
end

function PackRegistry.UnregisterActionProvider(providerID)
    if not PackRegistry.ActionProviders[providerID] then
        return false, "action_provider_not_found"
    end
    PackRegistry.ActionProviders[providerID] = nil
    bumpRevision()
    return true
end

function PackRegistry.GetActionProvider(providerID)
    local provider = PackRegistry.ActionProviders[providerID]
    return provider and Util.clone(provider) or nil
end

function PackRegistry.ListActionProviders()
    local output = {}
    for _, provider in pairs(PackRegistry.ActionProviders) do
        output[#output + 1] = Util.clone(provider)
    end
    table.sort(output, function(left, right)
        if left.order ~= right.order then
            return left.order < right.order
        end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function PackRegistry.CollectActions(context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}

    -- capabilities may be passed via context.capabilities or options.capabilities
    local capabilities = context.capabilities or options.capabilities
    local choices = {}
    local seenIDs = {}

    local providers = PackRegistry.ListActionProviders()
    for _, provider in ipairs(providers) do
        local allowed = true
        if provider.capabilityRequired then
            -- Capability-gated: provider is only active if capability is present
            if capabilities ~= nil then
                allowed = hasCapability(capabilities, provider.capabilityRequired)
            elseif options.strictCapabilities == true then
                allowed = false
            end
        end

        if allowed then
            local ok, collected = pcall(provider.collect, context)
            if ok and type(collected) == "table" then
                for _, choice in ipairs(collected) do
                    if type(choice) == "table" and choice.id then
                        local choiceAllowed = true
                        local choiceCap = choice.capabilityRequired
                            or provider.capabilityRequired
                        if choiceCap and capabilities ~= nil then
                            choiceAllowed = hasCapability(capabilities, choiceCap)
                        end

                        if choiceAllowed and not seenIDs[choice.id] then
                            seenIDs[choice.id] = true
                            local item = Util.clone(choice)
                            item.sourceProviderID = provider.id
                            item.sourceKind = item.sourceKind or provider.sourceKind
                            item.order = tonumber(item.order)
                                or tonumber(provider.order) or 50
                            choices[#choices + 1] = item
                        end
                    end
                end
            end
        end
    end

    table.sort(choices, function(left, right)
        if left.order ~= right.order then
            return left.order < right.order
        end
        return tostring(left.id) < tostring(right.id)
    end)

    return choices
end

function PackRegistry.RegisterDialogueBlock(blockSpec)
    if type(blockSpec) ~= "table" then
        return nil, "block_spec_required"
    end
    local id = blockSpec.id
    if type(id) ~= "string" or id == "" then
        return nil, "block_id_required"
    end
    local block = {
        id = id,
        category = tostring(blockSpec.category or "general"),
        ownerModID = blockSpec.ownerModID or "core",
        priority = tonumber(blockSpec.priority) or 100,
        weight = tonumber(blockSpec.weight) or 100,
        gates = Util.clone(blockSpec.gates or {}),
        entryNode = blockSpec.entryNode or "opening",
        nodes = Util.clone(blockSpec.nodes or {}),
        metadata = Util.clone(blockSpec.metadata or {}),
        packID = blockSpec.packID,
    }
    PackRegistry.DialogueBlocks[id] = block
    bumpRevision()
    return Util.clone(block)
end

function PackRegistry.UnregisterDialogueBlock(blockID)
    if not PackRegistry.DialogueBlocks[blockID] then
        return false, "block_not_found"
    end
    PackRegistry.DialogueBlocks[blockID] = nil
    bumpRevision()
    return true
end

function PackRegistry.GetDialogueBlock(blockID)
    local block = PackRegistry.DialogueBlocks[blockID]
    return block and Util.clone(block) or nil
end

function PackRegistry.ListDialogueBlocks(category)
    local output = {}
    for _, block in pairs(PackRegistry.DialogueBlocks) do
        if category == nil or block.category == category then
            output[#output + 1] = Util.clone(block)
        end
    end
    table.sort(output, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function PackRegistry.SelectDialogueBlock(category, context, seed)
    local blocks = PackRegistry.ListDialogueBlocks(category)
    local eligible = {}
    for _, block in ipairs(blocks) do
        if Flow.EvaluateGates(block.gates, context) then
            eligible[#eligible + 1] = block
        end
    end
    if #eligible == 0 then return nil, "no_eligible_blocks" end
    if #eligible == 1 then return eligible[1] end

    -- Highest priority tier
    local topPriority = eligible[1].priority
    local tier = {}
    local totalWeight = 0
    for _, block in ipairs(eligible) do
        if block.priority == topPriority then
            tier[#tier + 1] = block
            totalWeight = totalWeight + math.max(1, tonumber(block.weight) or 100)
        end
    end
    if #tier == 1 then return tier[1] end

    local hash = Util.hash(tostring(seed or "flow_block") .. ":" .. tostring(category or ""))
    local roll = (hash % totalWeight) + 1
    local current = 0
    for _, block in ipairs(tier) do
        current = current + math.max(1, tonumber(block.weight) or 100)
        if roll <= current then return block end
    end
    return tier[#tier]
end

function PackRegistry.RegisterPack(spec)
    if type(spec) ~= "table" then
        return nil, "pack_spec_required"
    end
    local packID = spec.id
    if type(packID) ~= "string" or packID == "" then
        return nil, "pack_id_required"
    end
    if type(spec.ownerModID) ~= "string" or spec.ownerModID == "" then
        return nil, "pack_owner_required"
    end

    if PackRegistry.Packs[packID] then
        PackRegistry.UnregisterPack(packID)
    end

    local pack = {
        id = packID,
        ownerModID = spec.ownerModID,
        version = tonumber(spec.version) or 1,
        capabilitiesRequired = Util.clone(spec.capabilitiesRequired or {}),
        metadata = Util.clone(spec.metadata or {}),
        registeredActionProviders = {},
        registeredDialogueBlocks = {},
        onRegister = spec.onRegister,
        onUnregister = spec.onUnregister,
    }

    local Semantics = PsychopatzCore.Semantics

    -- 1. Concepts
    if type(spec.concepts) == "table" and Semantics and Semantics.Registry then
        for _, conceptDef in ipairs(spec.concepts) do
            if type(conceptDef) == "table" then
                conceptDef.owner = packID
                Semantics.Registry.RegisterConcept(conceptDef)
            end
        end
    end

    -- 2. Speech acts
    if type(spec.speechActs) == "table" and Semantics and Semantics.Registry then
        for _, actEntry in ipairs(spec.speechActs) do
            if type(actEntry) == "table" then
                local def = actEntry.definition or actEntry
                local meta = actEntry.metadata or {}
                meta.owner = packID
                Semantics.Registry.RegisterSpeechAct(def, meta)
            end
        end
    end

    -- 3. Patterns
    if type(spec.patterns) == "table" and Semantics and Semantics.Registry then
        for _, patternDef in ipairs(spec.patterns) do
            if type(patternDef) == "table" then
                patternDef.owner = packID
                Semantics.Registry.RegisterPattern(patternDef)
            end
        end
    end

    -- 4. Action Providers
    if type(spec.actionProviders) == "table" then
        for _, provSpec in ipairs(spec.actionProviders) do
            if type(provSpec) == "table" then
                local copy = Util.clone(provSpec)
                copy.ownerModID = copy.ownerModID or spec.ownerModID
                copy.packID = packID
                copy.collect = provSpec.collect -- keep function reference
                local registered, reason = PackRegistry.RegisterActionProvider(copy)
                if registered then
                    pack.registeredActionProviders[#pack.registeredActionProviders + 1] = copy.id
                end
            end
        end
    end

    -- 5. Context Resolvers
    if type(spec.contextResolvers) == "table" and Semantics and Semantics.Context then
        for _, res in ipairs(spec.contextResolvers) do
            if type(res) == "table" and res.id and res.resolver then
                Semantics.Context.RegisterResolver(res.id, res.resolver, res.priority)
            end
        end
    end

    -- 6. Social Flavors
    if type(spec.flavors) == "table" and PsychopatzCore.SocialFlavor then
        for _, flav in ipairs(spec.flavors) do
            if type(flav) == "table" and flav.id and flav.definition then
                PsychopatzCore.SocialFlavor.Register(flav.id, flav.definition)
            end
        end
    end

    -- 7. Dialogue Blocks
    if type(spec.dialogueBlocks) == "table" then
        for key, blockSpec in pairs(spec.dialogueBlocks) do
            if type(blockSpec) == "table" then
                local copy = Util.clone(blockSpec)
                copy.id = copy.id or tostring(key)
                copy.ownerModID = copy.ownerModID or spec.ownerModID
                copy.packID = packID
                local registered, reason = PackRegistry.RegisterDialogueBlock(copy)
                if registered then
                    pack.registeredDialogueBlocks[#pack.registeredDialogueBlocks + 1] = copy.id
                end
            end
        end
    end

    if type(spec.onRegister) == "function" then
        pcall(spec.onRegister, pack)
    end

    PackRegistry.Packs[packID] = pack
    bumpRevision()
    return Util.clone(pack)
end

function PackRegistry.UnregisterPack(packID)
    local pack = PackRegistry.Packs[packID]
    if not pack then return false, "pack_not_found" end

    -- Unregister associated action providers
    for _, provID in ipairs(pack.registeredActionProviders or {}) do
        PackRegistry.UnregisterActionProvider(provID)
    end

    -- Unregister associated dialogue blocks
    for _, blockID in ipairs(pack.registeredDialogueBlocks or {}) do
        PackRegistry.UnregisterDialogueBlock(blockID)
    end

    if type(pack.onUnregister) == "function" then
        pcall(pack.onUnregister, pack)
    end

    PackRegistry.Packs[packID] = nil
    bumpRevision()
    return true
end

function PackRegistry.GetPack(packID)
    local pack = PackRegistry.Packs[packID]
    return pack and Util.clone(pack) or nil
end

function PackRegistry.ListPacks()
    local output = {}
    for _, pack in pairs(PackRegistry.Packs) do
        output[#output + 1] = Util.clone(pack)
    end
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function PackRegistry.GetDiagnostics()
    local packList = PackRegistry.ListPacks()
    local providerList = PackRegistry.ListActionProviders()
    local blockList = PackRegistry.ListDialogueBlocks()
    return {
        revision = PackRegistry.GetRevision(),
        packCount = #packList,
        packs = packList,
        actionProviderCount = #providerList,
        actionProviders = providerList,
        dialogueBlockCount = #blockList,
        dialogueBlocks = blockList,
    }
end

return PackRegistry
