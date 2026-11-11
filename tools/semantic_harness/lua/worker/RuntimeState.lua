-- Mutable state owned by one isolated semantic harness worker.
--
-- Core owns the container lifecycle and bounded diagnostic collections. Adopter
-- modules may attach provider state to this record, but Core does not interpret
-- provider-specific values.

local RuntimeState = {}

local OBSERVATION_LIMITS = {
    transcript = 16,
    queued = 8,
    trace = 16,
    transport = 16,
    translationLookups = 32,
}

local function trim(list, limit)
    if type(list) ~= "table" then return end
    while #list > limit do
        table.remove(list, 1)
    end
end

function RuntimeState.new()
    return {
        -- Neutral launch selection advertised by every adopter worker.
        launchProfile = "core",
        launchProviders = { "PsychopatzCore" },
        launchMaterializationMode = "none",

        -- Core-owned source/working-world and diagnostic state.
        scenario = nil,
        sourceSnapshot = nil,
        sourceMetadata = nil,
        sourceProvenance = nil,
        sourceProviderPayloads = {},
        sourceWorkingBaseline = nil,
        captureWorkingBaseline = false,
        workingWorldRevision = 0,
        workingResetCount = 0,
        queued = {},
        transcript = {},
        trace = {},
        transport = {},
        translationLookups = {},
        translationLanguage = "EN",
        llmCalls = 0,
        now = 1000,
        turn = 0,
        lastSuggestionRevision = nil,
        semanticClickReceipts = {},
        loadedModules = {},
        moduleManifest = {},
        loadedRuntimeBootstraps = { entries = {}, count = 0 },
        providerBootstrapLogs = {},
        headlessRequires = {},

        -- Adopter extension slots. Core preserves these values as opaque state
        -- so provider modules can migrate incrementally without a second
        -- RuntimeState implementation.
        extensions = {},
        modData = {},
        questBoundary = nil,
        productionQuestRequest = nil,
    }
end

function RuntimeState.resetContainers(runtime)
    runtime.queued = {}
    runtime.transcript = {}
    runtime.trace = {}
    runtime.transport = {}
    runtime.translationLookups = {}
    runtime.llmCalls = 0
    runtime.now = 1000
    runtime.turn = 0
    runtime.lastSuggestionRevision = nil
    runtime.semanticClickReceipts = {}
    runtime.relationships = {}
    runtime.runtimeRelationshipOverrides = {}
    runtime.lastSemanticActionResult = nil
    runtime.playerModData = {}
end

function RuntimeState.resetTurn(runtime)
    runtime.queued = {}
    runtime.transport = {}
    runtime.trace = {}
end

-- Worker diagnostics are presentation-only and must not grow with a long
-- conversation. The semantic lifecycle owns compact meaning separately; this
-- trims only the worker's transient inspection collections.
function RuntimeState.compactDiagnostics(runtime)
    if type(runtime) ~= "table" then return false end
    trim(runtime.transcript, OBSERVATION_LIMITS.transcript)
    trim(runtime.queued, OBSERVATION_LIMITS.queued)
    trim(runtime.trace, OBSERVATION_LIMITS.trace)
    trim(runtime.transport, OBSERVATION_LIMITS.transport)
    trim(runtime.translationLookups, OBSERVATION_LIMITS.translationLookups)
    return true
end

return RuntimeState
