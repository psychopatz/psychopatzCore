# PsychopatzCore Modular Capability & Composition Architecture

## Core principle

> PsychopatzCore provides reusable mechanisms. Installing Core makes capabilities available; only explicit consumer demand makes feature implementations load and become active.

The architecture distinguishes three facts:

`installed != loaded != active`.

## Target layers

```text
Adopter mods
    |
    | request capabilities / packs
    v
Minimal Core Kernel
    - RuntimeRole
    - FeatureRegistry
    - dependency resolver
    - lifecycle coordinator
    - diagnostics
    |
    v
Capability graph
    |
    +--> Inventory
    +--> Currency
    +--> Actors
    +--> WorldKnowledge
    +--> RadioOS
    +--> Conversation
    +--> Traits
    +--> Debug / Profiler / Preview
    +--> ...
```

The root shared/client/server entry points must remain composition roots, not feature implementations.

## Feature contract

Every activatable feature must have one stable ID and an explicit contract equivalent to:

```lua
{
    id = "inventory",
    depends = { "serialization", "runtime" },
    roles = { shared = true, server = true },
    load = function() ... end,
    activate = function(context) ... end,
    deactivate = function(context) ... end, -- when supported
}
```

Exact API names may change during implementation, but the contract must preserve:

- stable feature ID
- explicit dependencies
- allowed runtime roles
- lazy implementation loader
- lifecycle ownership
- diagnostics/status
- failure reason
- consumer attribution

## Lifecycle states

At minimum:

- `REGISTERED` — known to the kernel; implementation not required.
- `LOADED` — implementation loaded but no runtime resources necessarily active.
- `ACTIVE` — callbacks/resources installed for at least one consumer.
- `DORMANT` — implementation remains loaded but active resources are detached when supported.
- `FAILED` — activation/load failed with a bounded reason.

Do not promise perfect Lua module unloading. The primary optimization is to avoid loading unrequested features at all.

## Dependency resolution

Capability activation uses dependency closure, not global booleans. Dependency cycles are invalid and must fail with a useful diagnostic path.

Example:

```text
DTAbstract requests radio.os
    -> ui.core
    -> radio.device_state
    -> input
```

Only that closure is eligible for activation.

Feature packs are convenience aliases over individual feature contracts. They must not become a second hidden dependency system.

## Consumer ownership and reference counting

The registry records which consumers requested a feature. Multiple adopters can share one active feature. Removing one consumer must not deactivate a feature still required by another.

Diagnostics must answer:

- who requested this feature?
- which dependency caused it to load?
- current runtime role/state?
- what callbacks/resources does it own?
- why did activation fail?

## Public API boundary

Adopters should depend on stable Core facades/services, not incidental internal file paths. Direct implementation requires may remain during migration but must be tracked and removed where they prevent safe internal reorganization.

Preferred direction:

```text
Core.Features.Require(...)
Core.Features.RequirePack(...)
Core.Services.Get(...)
```

The exact surface must remain simple; avoid factories/proxies/dispatch layers that increase retrieval depth without adding ownership value.

## Runtime-role separation

A feature declares whether it is shared, client, server, or a combination. Resolving a capability must not activate code invalid for the current role.

Server-only deployments must not load client UI. Client contexts must not own authoritative server services.

## Event and callback ownership

Feature activation owns all callbacks, timers, samplers, command handlers and other recurring resources it introduces. A disabled/unrequested feature must not leave recurring callbacks behind.

Require-time side effects should be migrated behind lifecycle boundaries unless an engine constraint genuinely requires early registration; such exceptions must be documented and tested.

## Domain modularity

Inside a feature capsule, split by meaningful responsibility when it improves MCP retrieval or ownership:

```text
Inventory/
    API
    Commands
    Queries
    Records
    Codecs
    Persistence
    PhysicalAdapter
    Internal
```

Externally, consumers see the feature/facade rather than those internals.

## Failure containment

One optional feature failing to load/activate must not silently corrupt unrelated active features. Mandatory dependency failure prevents the requesting feature from activating and records an actionable dependency path.

## Non-goals

- no arbitrary file-count target
- no rewrite of healthy domains solely for style
- no global enable/disable table as the primary architecture
- no event bus for every direct internal call
- no duplicate gameplay policy moved from Hoomans or DynamicTrading into Core
- no compatibility shim preserved indefinitely when all adopters can migrate safely
- no native PZ or Workshop publication as agent-side acceptance
