-- Provider-neutral source/working-world session envelope.
--
-- This module projects state; it does not own provider rehydration, gameplay
-- policy, or the legacy response fields used by an adopter.

local SessionEnvelope = {}

SessionEnvelope.SCHEMA = "semantic.harness_session_envelope.v1"
SessionEnvelope.SCHEMA_VERSION = 1

function SessionEnvelope.project(runtime, Values)
    runtime = type(runtime) == "table" and runtime or {}
    Values = Values or require "worker/Values"
    local metadata = type(runtime.sourceMetadata) == "table"
        and runtime.sourceMetadata or {}
    local sourceKind = metadata.sourceKind or "MISSING"
    local baseline = runtime.sourceWorkingBaseline
        or runtime.sourceSnapshot

    return {
        schema = SessionEnvelope.SCHEMA,
        schemaVersion = SessionEnvelope.SCHEMA_VERSION,
        source = {
            data = Values.productionCopy(runtime.sourceSnapshot),
            metadata = Values.productionCopy(metadata),
            provenance = Values.productionCopy(runtime.sourceProvenance),
        },
        working = {
            effective = Values.productionCopy(runtime.scenario),
            baseline = Values.productionCopy(baseline),
            sourceKind = sourceKind,
            sourceID = metadata.sourceID,
            revision = runtime.workingWorldRevision or 0,
            resetCount = runtime.workingResetCount or 0,
        },
        -- Provider payloads are opaque and namespaced by provider ID. Core
        -- preserves their shape but never interprets their contents.
        providerPayloads = Values.productionCopy(
            runtime.sourceProviderPayloads or {}
        ),
        extensions = Values.productionCopy(runtime.extensions or {}),
    }
end

function SessionEnvelope.compact(envelope)
    if type(envelope) ~= "table" then return envelope end
    if type(envelope.source) == "table" then
        envelope.source.data = nil
        envelope.source.provenance = nil
    end
    if type(envelope.working) == "table" then
        envelope.working.baseline = nil
    end
    envelope.providerPayloads = nil
    return envelope
end

return SessionEnvelope
