# Semantic Harness Working World

`worker/WorkingWorld.lua` owns provider-neutral source/working-world
bookkeeping used by semantic harness adopters.

## Core responsibilities

- select the immutable source baseline and effective scenario;
- produce a bounded, deterministic patch list;
- stamp patches with `HARNESS_MUTATION` and the source kind;
- manage working-world revision and reset counters;
- capture the first post-rehydration working baseline for an imported source.

The patch projection is capped at 512 entries and copies values through the
Core bounded value projection. Numeric and string keys are preserved while
paths are rendered deterministically.

## Adopter responsibilities

An adopter still decides how a reset rehydrates provider records, restores
actors, rebuilds relationships, or applies gameplay policy. It calls the Core
bookkeeping functions around that work; Core never invokes provider modules or
interprets merchant, Project Hoomans, or Project Zomboid records.
