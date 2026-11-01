-- Built-in Capability Catalog for PsychopatzCore
-- Defines descriptors for all Core capability capsules and convenience packs.

local Contract = require "PsychopatzCore/Kernel/PC_CapabilityContract"

local Catalog = {
    descriptors = {},
    packs = {},
}

local function addDescriptor(desc)
    local ok, err = Contract.ValidateDescriptor(desc)
    if not ok then
        error("Invalid descriptor '" .. tostring(desc and desc.id) .. "': " .. tostring(err))
    end
    Catalog.descriptors[desc.id] = desc
end

local function addPack(pack)
    local ok, err = Contract.ValidatePack(pack)
    if not ok then
        error("Invalid pack '" .. tostring(pack and pack.id) .. "': " .. tostring(err))
    end
    Catalog.packs[pack.id] = pack
end

-- 1. Runtime
addDescriptor({
    id = "core.runtime",
    domain = "Runtime",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Runtime/PC_RuntimeRole"
    end,
    facade = function()
        return PsychopatzCore.RuntimeRole
    end,
})

-- 2. Collections
addDescriptor({
    id = "core.collections",
    domain = "Collections",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Collections/PC_RingBuffer"
    end,
})

-- 3. Events
addDescriptor({
    id = "core.events",
    domain = "Events",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Events/PC_EventBus"
    end,
})

-- 4. Semantics
addDescriptor({
    id = "core.semantics",
    domain = "Semantics",
    roles = { shared = true, client = true, server = true },
    depends = { "core.collections", "core.events", "core.runtime" },
    load = function()
        return require "PsychopatzCore/Semantics/PsychopatzSemantic"
    end,
    facade = function()
        return PsychopatzCore.Semantics
    end,
})

-- 5. Translation
addDescriptor({
    id = "core.translation",
    domain = "Translation",
    roles = { shared = true, client = true, server = true },
    load = function()
        require "PsychopatzCore/Translation/PsychopatzCustomTranslationManager"
        return require "PsychopatzCore/Translation/PsychopatzCoreTranslation"
    end,
    facade = function()
        return PsychopatzCore.Translation
    end,
})

-- 6. Conversation
addDescriptor({
    id = "core.conversation",
    domain = "Conversation",
    roles = { shared = true, client = true, server = true },
    depends = { "core.semantics", "core.translation" },
    load = function()
        require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
        require "PsychopatzCore/Conversation/PsychopatzNameParts"
        return require "PsychopatzCore/Conversation/PsychopatzActorConversationService"
    end,
    facade = function()
        return PsychopatzCore.Conversation
    end,
})

-- 7. Voice
addDescriptor({
    id = "core.voice",
    domain = "Voice",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Voice/PsychopatzVoiceGateway"
    end,
    facade = function()
        return PsychopatzCore.VoiceGateway
    end,
})

-- 8. Journal
addDescriptor({
    id = "core.journal",
    domain = "Journal",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Journal/PC_JournalService"
    end,
    facade = function()
        return PsychopatzCore.Journal
    end,
})

-- 9. Spatial
addDescriptor({
    id = "core.spatial",
    domain = "Spatial",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"
    end,
    facade = function()
        return PsychopatzCore.SpatialRelation
    end,
})

-- 10. World Region
addDescriptor({
    id = "core.world_region",
    domain = "World",
    roles = { shared = true, client = true, server = true },
    load = function()
        require "PsychopatzCore/World/PsychopatzSquareRules"
        require "PsychopatzCore/World/PC_ZoneRegistry"
        return require "PsychopatzCore/World/PC_GridRegion"
    end,
    facade = function()
        return PsychopatzCore.World
    end,
})

-- 11. Deterministic Content
addDescriptor({
    id = "core.deterministic_content",
    domain = "Content",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Content/PsychopatzDeterministicContent"
    end,
    facade = function()
        return PsychopatzCore.DeterministicContent
    end,
})

-- 12. Actors
addDescriptor({
    id = "core.actors",
    domain = "Actors",
    roles = { shared = true, client = true, server = true },
    depends = { "core.deterministic_content" },
    load = function()
        return require "PsychopatzCore/Actors/PsychopatzActors"
    end,
    facade = function()
        return PsychopatzCore.Actors
    end,
})

-- 13. Inventory
addDescriptor({
    id = "core.inventory",
    domain = "Inventory",
    roles = { shared = true, client = true, server = true },
    load = function()
        require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
        return require "PsychopatzCore/Inventory/PsychopatzInventory"
    end,
    facade = function()
        return PsychopatzCore.Inventory
    end,
})

-- 14. Currency
addDescriptor({
    id = "core.currency",
    domain = "Economy",
    roles = { shared = true, client = true, server = true },
    load = function()
        require "PsychopatzCore/Compatibility/PsychopatzMoneyWeight"
        require "PsychopatzCore/Compatibility/PsychopatzCurrencyCategory"
        require "PsychopatzCore/Economy/PsychopatzMoneyBundler"
        return require "PsychopatzCore/Economy/PsychopatzCurrency"
    end,
    facade = function()
        return PsychopatzCore.Currency
    end,
})

-- 15. Currency Server
addDescriptor({
    id = "core.currency_server",
    domain = "Economy",
    roles = { server = true },
    depends = { "core.currency" },
    load = function()
        require "PsychopatzCore/Economy/PsychopatzMoneyBundlerServer"
        return require "PsychopatzCore/Economy/PsychopatzCurrencyServer"
    end,
})

-- 16. Radio Device State
addDescriptor({
    id = "core.radio_device_state",
    domain = "Radio",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Radio/PC_RadioDeviceState"
    end,
    facade = function()
        return PsychopatzCore.RadioDeviceState
    end,
})

-- 17. Radio Channels
addDescriptor({
    id = "core.radio_channels",
    domain = "Radio",
    roles = { shared = true, client = true, server = true },
    depends = { "core.translation" },
    load = function()
        require "PsychopatzCore/Radio/RadioFrequencies/PsychopatzRadioFrequencies"
        return require "PsychopatzCore/Radio/CustomChannels/PsychopatzCustomRadio"
    end,
    facade = function()
        return PsychopatzCore.CustomRadio
    end,
})

-- 18. Radio OS
addDescriptor({
    id = "core.radio_os",
    domain = "Radio",
    roles = { client = true },
    depends = { "core.radio_device_state" },
    load = function()
        return require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS"
    end,
    facade = function()
        return PsychopatzCore.RadioOS
    end,
})

-- 19. Traits
addDescriptor({
    id = "core.traits",
    domain = "Traits",
    roles = { shared = true, client = true, server = true },
    load = function()
        require "PsychopatzCore/Traits/PsychopatzTraitRegistry"
        return require "PsychopatzCore/Traits/PsychopatzTraitRecovery"
    end,
    facade = function()
        return PsychopatzCore.Traits
    end,
})

-- 20. Zombie Kill Detector
addDescriptor({
    id = "core.zombie_kill_detector",
    domain = "ZombieKillDetector",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"
    end,
    facade = function()
        return PsychopatzCore.ZombieKillDetector
    end,
})

-- 21. Debug
addDescriptor({
    id = "core.debug",
    domain = "Debug",
    roles = { shared = true, client = true, server = true },
    load = function()
        require "PsychopatzCore/Debug/PsychopatzDebugSettings"
        require "PsychopatzCore/Debug/PsychopatzDebugTrace"
        return require "PsychopatzCore/Debug/PsychopatzDebug"
    end,
    facade = function()
        return PsychopatzCore.Debug
    end,
})

-- 22. Debug Hub
addDescriptor({
    id = "core.debug_hub",
    domain = "UI",
    roles = { client = true },
    depends = { "core.debug" },
    load = function()
        return require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
    end,
    facade = function()
        return PsychopatzCore.DebugHub
    end,
})

-- 23. Profiler
addDescriptor({
    id = "core.profiler",
    domain = "Profiler",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
    end,
    facade = function()
        return PsychopatzCore.Profiler
    end,
})

-- 24. Bridge
addDescriptor({
    id = "core.bridge",
    domain = "Bridge",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap"
    end,
    facade = function()
        return PsychopatzCore.Bridge
    end,
})

-- 25. Input Keybinds
addDescriptor({
    id = "core.input_keybinds",
    domain = "Input",
    roles = { client = true },
    load = function()
        return require "PsychopatzCore/Input/PsychopatzKeybinds"
    end,
    facade = function()
        return PsychopatzCore.Keybinds
    end,
})

-- 26. Audio Settings
addDescriptor({
    id = "core.audio_settings",
    domain = "UI",
    roles = { client = true },
    load = function()
        return require "PsychopatzCore/UI/PsychopatzAudioSettings"
    end,
    facade = function()
        return PsychopatzCore.Audio
    end,
})

-- 27. Teleport
addDescriptor({
    id = "core.teleport",
    domain = "World",
    roles = { shared = true, client = true, server = true },
    load = function()
        return require "PsychopatzCore/World/PsychopatzTeleport"
    end,
    facade = function()
        return PsychopatzCore.Teleport
    end,
})

-- 28. Preview
addDescriptor({
    id = "core.preview",
    domain = "Preview",
    roles = { client = true },
    load = function()
        return require "PsychopatzCore/Preview/PC_Preview"
    end,
    facade = function()
        return PsychopatzCore.Preview
    end,
})

-- Convenience Adopter Packs
addPack({
    id = "pack.trading_common",
    capabilities = {
        "core.runtime",
        "core.inventory",
        "core.currency",
        "core.actors",
        "core.conversation",
        "core.debug",
    },
})

addPack({
    id = "pack.trading_abstract",
    capabilities = {
        "core.runtime",
        "core.inventory",
        "core.currency",
        "core.actors",
        "core.conversation",
        "core.debug",
        "core.radio_device_state",
        "core.radio_os",
    },
})

addPack({
    id = "pack.trading_hoomans",
    capabilities = {
        "core.runtime",
        "core.inventory",
        "core.currency",
        "core.actors",
        "core.conversation",
        "core.debug",
        "core.radio_device_state",
        "core.radio_os",
        "core.debug_hub",
        "core.teleport",
    },
})

addPack({
    id = "pack.core_legacy_full",
    capabilities = {
        "core.runtime",
        "core.collections",
        "core.events",
        "core.semantics",
        "core.translation",
        "core.conversation",
        "core.voice",
        "core.journal",
        "core.spatial",
        "core.world_region",
        "core.deterministic_content",
        "core.actors",
        "core.inventory",
        "core.currency",
        "core.radio_device_state",
        "core.radio_channels",
        "core.traits",
        "core.zombie_kill_detector",
        "core.debug",
        "core.profiler",
        "core.bridge",
        "core.teleport",
    },
})

return Catalog
