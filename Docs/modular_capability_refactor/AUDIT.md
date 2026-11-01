# PsychopatzCore Modular Capability & Composition Refactor — Audit

Snapshot: 2026-11-01  
PsychopatzCore revision: `c01daef545fe5a9d2742186eca2bc0aa911f99cc`  
Branch: `main`, equal to `origin/main` at audit time.  
Worktree: clean at audit time.

## Verified current shape

The repository already has useful modular foundations: explicit Composition files, domain directories, opt-in behavior in several services, a lean durable root `AGENTS.md`, and a sizeable focused smoke-test suite.

The remaining architectural weakness is top-level composition. `00_PsychopatzCore_Init.lua` loads `PC_SharedComposition`, which eagerly loads broad shared foundations, Actors, Economy and feature groups. Client and server anchors also eagerly require unrelated feature implementations before entering their composition modules.

Examples verified at this revision:

- Shared foundation loads Semantics, RuntimeRole, RingBuffer, EventBus, Translation, Conversation helpers, Voice, Journal, Radio device state, Spatial, GridRegion/Zone/World helpers and WorldKnowledge.
- Shared composition additionally loads Actors, money compatibility, Currency, MoneyBundler, Diagnostics, Radio, Traits, Profiler bootstrap and Bridge bootstrap.
- Client init eagerly loads Keybinds, Radio OS, Audio Settings, Social Flavor client, Walkie compatibility and Money Bundler UI/action.
- Server init eagerly loads CurrencyServer and MoneyBundlerServer; server composition also installs compatibility/profiler surfaces.
- Several modules are internally dormant until registered/enabled, which is good, but `loaded but dormant` is still different from `never loaded because no consumer requested it`.

## Architecture-analyzer evidence

Current checked-in audit reports:

- 307 production files
- 46,319 production LOC scored
- 30 logical subsystems
- 54 production findings
- 42 `DEPENDENCY_CYCLE` findings
- Composition and root composition at 100/100 refactor pressure
- UI at 100/100 refactor pressure
- Inventory at 20.9 pressure and comparatively healthy
- high-confidence coupling from the client root into six foreign subsystems

This is triage evidence, not permission for blind rewrites. The dominant problem is composition/dependency shape rather than raw file count.

## Runtime-side-effect evidence

A source scan found 29 Core Lua files with PZ event-hook registration surfaces. Potential recurring/event ownership includes Bridge, Inventory initialization, Voice, translation boot, zombie kill detection, Social Flavor, custom radio, money bundling, compatibility guards, Debug, Teleport, Profiler, Traits, Settings, Preview, EventMarkers, Keybinds, Sidebar, Radio OS lifecycle and Player Animation.

The migration must therefore inventory **require-time side effects**, not just static imports.

## Dynamic Trading pilot evidence

`DTCommon` declares `PsychopatzCore` as a dependency and currently consumes Core surfaces including Inventory, InventoryConstants, Currency, Translation, Actors, WorldKnowledge, ActorConversationService, Profiler feature registration, Radio OS/RadioDeviceState in relevant frontends, and Teleport in DTHoomans integration.

This demonstrates that Dynamic Trading needs a meaningful subset of Core, not the whole Core feature set.

At audit time the DynamicTrading worktree contained an unrelated local edit in `DTHoomans_Conversation.lua`. Preserve it. Do not edit or integrate that repository until its current state is re-audited and the intended files can be changed without overwriting user work.

## Refactor conclusion

Target the composition model, lifecycle ownership and public capability seams first. Preserve healthy domain implementations where possible. Split oversized/cohesion-poor files only when doing so reduces retrieval scope, clarifies ownership, or isolates a lifecycle/authority boundary.

Do not optimize for a smaller or larger file count.
