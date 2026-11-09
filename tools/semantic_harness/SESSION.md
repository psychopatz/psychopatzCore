# Semantic Harness Session Envelope

`worker/SessionEnvelope.lua` is the provider-neutral projection boundary for a
semantic harness session. It gives Core and every adopter the same description
of source state, effective working state, revision metadata, and opaque
provider payloads without making Core interpret provider policy.

## Contract

The envelope schema is `semantic.harness_session_envelope.v1`. Its top-level
fields are:

- `source`: immutable source data, metadata, and provenance;
- `working`: effective scenario state, baseline, source identity, and revision
  counters;
- `providerPayloads`: namespaced opaque payloads keyed by provider ID;
- `extensions`: namespaced opaque extension data.

`SessionEnvelope.project(runtime, Values)` deep-copies the projection through
Core's bounded value copier. Core preserves provider payload shape but does not
rehydrate, validate, or apply provider gameplay policy.

## Inspector versus mutation responses

An explicit `SNAPSHOT` is an inspector boundary and may retain raw source data,
provenance, and provider payloads for diagnostics. Mutation responses use
`SessionEnvelope.compact`, which removes raw source data, provenance, the
working baseline, and opaque provider payloads while retaining schema,
metadata, effective state, revision counters, and extensions.

Adopters may continue exposing compatibility fields beside this envelope while
their provider-specific migration is in progress. Those fields are not part of
the Core contract and must not be interpreted by Core.
