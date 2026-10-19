# Core NPC Foundation — Ownership Boundaries

| Domain | Canonical owner after migration | Adapter or policy boundary |
| --- | --- | --- |
| Stable actor identity, generation, and resolved survivor data | PsychopatzCore Actors Factory/Registry | Hoomans archetypes and DT merchant definitions provide policy input only |
| Appearance, voice, worn visuals, and portraits | Core actor appearance and personal inventory | Hoomans applies a leased projection to a body; Core presentation builds portraits |
| Personal items, containers, worn/equipped slots, and item state | Core ActorInventory and portable-item primitives | Hoomans body synchronization is a projection; DT stock and budget are separate |
| Directional relationships, personality, and bounded memories | Core Social | Hoomans events/knowledge and DT pricing consume authorized projections |
| World location, anchors, abstract journeys, tasks, and scheduling | Core actor world modules | Hoomans owns detailed AI/live paths; DT consumes merchant route decisions |
| Provider lease, materialization state, and single-body claim | Core ActorProvider and registry | DTAbstract/DTHoomans request transitions; Hoomans body lifecycle stamps the Core lease ID |
| Map markers, portrait interaction, nearby access, and notifications | Core presentation/map/interaction contracts | Hoomans and DT project into existing UI and discovery surfaces |
| Merchant identity mapping, stock, funds, pricing, access, fulfillment, and restocking | DTCommon | DTAbstract radio and DTHoomans encounter are providers; none owns personal inventory |
| IsoZombie/IsoPlayer shell, combat, needs, colony jobs, faction director, and body lifecycle | ProjectHoomans | Core and trading adapters never duplicate these systems |

## Provider transition contract

Core stores a stable actor projection and one provider lease per actor. A lease has a deterministic lease ID, provider, owner, state (`released`, `abstract`, or `materialized`), optional body ID, revision, and transition timestamps. A materialized body ID cannot be claimed by another actor in the same Core registry. Provider adapters receive the projection and injected lifecycle callbacks; they do not import or initialize one another.

DTAbstract is an abstract provider adapter. DTHoomans is a body-backed provider adapter. Project Hoomans maps the projection into its existing record and `PNC.BodyLifecycle`, using the Core lease ID as `runtime.bodyLease`, then releases the body before the Core lease returns to `abstract`.
