# Core NPC Foundation — Architecture and Authority Contract

Status: TARGET CONTRACT, not implemented. Date: 2026-10-18.
This contract supersedes only proposed extraction boundaries. Existing Hoomans and Dynamic Trading production APIs remain authoritative until each migration gate is verified.

## Ownership
| Domain | Canonical owner after migration | Adapters / policies |
| --- | --- | --- |
| Stable actor/NPC identity; identity generation and resolved SurvivorFactory data | PsychopatzCore Actors/Identity/Factory | Hoomans registers archetypes/traits; DT registers merchant archetypes |
| Appearance, voice, worn visuals and portrait descriptor | Core ActorAppearance and personal inventory | Core existing PortraitPanel renders; Hoomans materializes on body |
| Personal items, containers, worn/equipped slots and item-state ledger | Core ActorInventory, reusing current Core portable-item/transfer primitives | Hoomans body synchronization as leased projection |
| Directional personal relationships, personality and bounded memories | Core Relationships/Social | Hoomans social events/knowledge; DT pricing policy |
| World location, abstract journey, scheduling primitives | Core Locations/Journeys/AgentRuntime | Hoomans detailed AI and live paths; DT merchant route decisions |
| Generic map layer registry, markers, hover portrait, nearby tray, notifications | Core client presentation | Hoomans maps colonies; DT maps trader discovery |
| Merchant identity mapping, merchandise stock, funds, pricing, trade access, fulfilment, restocking | DTCommon | DTAbstract radio, DTHoomans live NPC encounter |
| Physical IsoZombie/IsoPlayer shell, combat, needs, colony jobs, community/faction director, body lifecycle | ProjectHoomans | Never initialized by trading-only Core |

Core must not require PNC, DTHoomans, DTCommon, MarketSense, a radio, nor a complete ProjectHoomans lifecycle to create an NPC.

## Canonical actor schema (proposed version 1)
- actorId (stable namespaced ID), ownerMod, schemaVersion, revision
- identity: identitySeed, resolved immutable/generated names, gender, survivor visual/voice fields, archetypeID, generatorVersion
- appearance: sanitized skin/hair/beard/colors/outfit/visual profile; render revision
- personalInventory: portable item records with stable IDs; container refs; worn, attached and equipped references; inventory revision; deterministic generation seed/version and baseline-delta/FULL fallback
- social: directed relationships keyed by stable NPC/player-character keys, approval, respect, familiarity, memory/event IDs, personality, social revision
- world: x/y/z, journey/route state, anchor/destination, travel clock, state revision
- extensions: validated namespaced mod-owned data only; no Java userdata/engine objects serialized

No generated field may be rerolled on save, load, portrait preview, backend change or materialization. Missing mods/items require a typed unavailable placeholder or deferred reconciliation, never silent item loss. Separate generated defaults from post-generation edits with item IDs and revisions. Never equate portable NPC belongings with DT merchant virtual stock.

## Core API proposals (names are NOT implemented)
- Actors.Create(spec), Actors.Get(id), Actors.GetView(id,viewer), Actors.MigrateLegacy(source), Actors.Commit(id,patch,expectedRevision)
- ActorFactory.RegisterArchetype(owner,id,definition), ActorFactory.Generate(spec), ActorInventory.ApplyMutation(...)
- Relationships.Get(observerActorId,targetEntityKey), Relationships.RecordAuthorizedEvent(...)
- Locations.RegisterAnchor(owner,location), Journeys.Begin/Advance/Cancel/Resume(...)
- AgentRuntime.RegisterCapability(owner,id,policy), AgentRuntime.Schedule(...)
- MapLayers.Register(owner,id,renderer), ActorPortrait.SetTarget(actorView), Interactions.Register(owner,...)
- PresenceProviders.Register(id,adapter), PresenceProviders.Switch(actorId,mode,expectedRevision)

Actual public names and schemas must be checked against installed Core APIs. PNC compatibility wrappers preserve Hoomans callers until migration completes.

## Authority and interaction invariants
1. Authoritative server owns identity IDs, canonical state mutations, travel, social effects, eligibility and inventory/stock settlement. Clients get viewer-filtered versioned snapshots.
2. Exactly ONE canonical actor identity and ONE journey movement owner per NPC. A Hoomans body is a runtime lease/projection, never another generator or authoritative actor database.
3. Exactly ONE canonical portable personal-item ledger; physical body items are reconciled using exact item identity and portable state. No double materialization, duplicates, or re-seeding.
4. DTCommon owns merchandise and trader budget independently of personal inventory. Preserve MarketSense as intrinsic-price authority; relationship price effects are capped DT policy applied on the server, not Core item valuation.
5. Core relationship data preserves directed meaning (merchant's opinion of player may differ from reverse), normalized keys, memory IDs, score ranges, cooldown/saturation and revisions.
6. Core map visibility enforces viewer knowledge/discovery; never reveal every abstract NPC/precise position/portrait by default. Hover uses existing Core descriptor-based portrait rendering and portrait revisions.
7. Radio CONTACT does not imply local TRADE. Preserve DTCommon server-side access/replay/version/atomicity checks; add explicit communication vs fulfillment permissions, distance/Z/presence, remote reservation/delivery only if separately implemented.
8. Journey completion and settlement restock events are idempotent, bounded, persisted, and server-owned. Merchant routes and stock policy remain in DTCommon.
9. Disabled capabilities do not register high-frequency hooks or allocate actor state. Hoomans-only mobile group, needs, combat and settlement economy do not boot for DTAbstract.
10. No two world-map render monkey patches: extract the existing ordered Hoomans registry into Core and delegate layers; avoid duplicate callbacks.

## Swap and compatibility
- DTAbstract only: abstract merchant, radio/nearby-contact interface and generic map, without Hoomans dependency.
- DTHoomans only (+ required Hoomans): same Core actor/DT ledger with a live body when eligible.
- Both: one identity, one trade entry, one body lease; provider precedence defined and exercised.
- Neither: persisted Core/DT records remain safe and inaccessible until a frontend registers.
- Module enable/disable across save/restart/load: do not claim Lua hot-unload. In-process provider switch only when both adapters already loaded; quiesce sessions, snapshot/save state, release lease, activate new provider, reconcile/revalidate.
- Legacy migration: explicit readable source-version allowlist, dry-run and backup/report, copy/validate/commit, one-time marker, rollback/recovery; never pass old data through the Hoomans exact-version reset path before conversion. If required source is absent or malformed, fail closed without overwriting.
- Do not alter legacy source until Core round-trip, data parity and rollback tests prove the bridge. Keep compatibility facades and coordinated releases as needed.

## Native and parity acceptance
One generated merchant must have bitwise/semantic parity of persisted common fields across Core-only -> DTAbstract -> DTHoomans -> DTAbstract -> restart. Validate changed worn/weapon/bag state, custom item metadata, social memory, face/voice, location, price/stock, body lease, no duplicates or second server writes. Check SP and dedicated MP, reconnect/replay, stale/invalid requests. Synthetic Lua tests cannot claim user-run live-game acceptance.

## Evidence links at planning baseline
Core portrait: Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Components/PsychopatzPortraitPanel.lua
Hoomans identity: Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Identity/PNC_Identity_Factory.lua and PNC_Identity_Profile.lua
Hoomans generator: .../PNC/Core/Base/PNC_Types/PNC_Types_Record.lua; inventory .../PNC_Inventory_Templates.lua; persistence .../PNC_Inventory_Persistence.lua
Hoomans materialization: .../PNC/Core/Presence/PNC_Presence/PNC_Presence_Materialize.lua
Hoomans map: .../PNC/UI/Map/PNC_MapLayerRegistry.lua, .../PNC_MapHoverPortrait.lua, .../Layers/PNC_MapLayer_Travel.lua
Hoomans relationship contract: docs/Systems/Relationships.md; persistence reset: docs/Systems/Persistence.md
DT trade authority: Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_TraderService.lua
