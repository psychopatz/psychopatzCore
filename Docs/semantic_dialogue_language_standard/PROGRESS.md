# Progress — Psychopatz Semantic Dialogue Language Standard

**Status:** IN PROGRESS — S0-S4 ACCEPTED; continuing automatically through S5-S8.
**Branch:** existing `main` in each participant repository.
**Active phase:** S5 — first-party domain migration and deletion.
**Developer completion boundary:** S8.

## Current verified architecture

Repository audit before implementation found that the required runtime capabilities already exist in separate accepted systems:

- shared bounded predicate evaluation;
- actor traits/personality/identity/relationship projections;
- identity gender projection;
- directed relationship approval/respect/familiarity/state;
- bounded fuzzy semantic recovery with mutation-safety policy;
- item/world/entity matching paths;
- ResponsePlan multi-turn response delivery;
- BranchOffers and generated semantic affordances;
- per-speaker/addressee flow keys;
- Interaction Director beat/behavior arbitration;
- multi-participant InteractionScene runtime;
- autonomous NPC semantic-choice conversation controller;
- dynamic name/address/reference resolution;
- owner-routed CodeBuilder generation and inline locale work currently in progress.

The problem is authoring fragmentation, not absence of those runtime capabilities.

## S0 acceptance now verified

- `S0_AUTHORING_INVENTORY.json` inventories 11 maintained surfaces across all three repositories, including Core mechanism ownership, ProjectHoomans definitions/generated/runtime adapters, and DynamicTrading trader pack/static suggestions/generated/runtime compatibility.
- Each surface records source files, owner/classification, production/test/documentation references, generated outputs, external compatibility status, final PSDL destination and migration/removal status.
- `psdl_authoring_audit.py --check` passes against the current Core, ProjectHoomans and DynamicTrading worktrees.
- The focused guard rejects changed first-party authoring under each frozen old root while accepting Core-compiled PSDL records, generated outputs and compatibility adapters outside those roots.

## S1 acceptance now verified

- Core owns the actor-neutral canonical IR contract with `speaker`, `addressee`, `target`, bounded participants, typed slots/references, public context paths and stable schema validation.
- Core owns the single normalized predicate contract across dialogue/runtime validation, including scalar/logical operations and bounded `contains`, `not_contains`, `contains_any`, and `contains_all` operations.
- ProjectHoomans' former generic predicate evaluator is now a thin compatibility seam to the Core evaluator; its suggestion predicate façade remains an adopter alias rather than a second implementation.
- Controlled Lua fixtures pass for NPC→player and player→NPC actor swaps, generic target references, typed slot/reference projections, collection predicates and fail-closed private paths.
- Core semantic harness tests pass: 100 tests; the focused S1 contract suite is included. Changed Lua runtime and harness files pass the Kahlua error scan.
- DynamicTrading was re-inspected in the same phase; its trader pack/static suggestions remain migration input and do not gain a parallel predicate/IR implementation.

## S2 acceptance now verified

- Core now owns `psdl_compiler.py`, the only PSDL parser/normalizer/compiler entry point; it accepts single records and bounded catalogs for `dialogue`, `behavior`, `beat`, and `realization`.
- The compiler routes every record through the Core canonical IR and shared predicate normalizer, validates owner/package identity, typed slots/references, public bindings, locale fallback and placeholder parity, bounded turns/offers/transitions, beat behavior references, and legacy/ambiguous source rejection.
- Runtime planning emits existing ResponsePlan/semantic-affordance-shaped data with package-routed module identities; it does not create a second dialogue runtime.
- `SemanticLabAuthoringService.preview_psdl_document` and `preview_psdl_sources` expose the same Core compiler without writing generated output.
- The S2 fixture compiles a translated multi-kind catalog deterministically and rejects malformed translations, inaccessible bindings, unknown fields, legacy identities, beat wording and dangling behavior references.
- Full Core semantic harness passes: 105 tests.

## S3 acceptance now verified

- Core owns the reusable participant-neutral semantic offer contract; the Hoomans BranchOffers path is now a compatibility façade rather than a second implementation.
- PSDL response projections map compact/simple and bounded multi-turn text into the accepted ResponsePlan shape, including translation template IDs, EN fallbacks, typed binding metadata and semantic offer frames.
- Offer consumers remain explicit (`participant`, `player`, `npc`) and are preserved for both player presentation and NPC semantic-choice policy; no rendered button text is reparsed.
- Core text bindings resolve actor-neutral context paths and registered typed resolvers, with private/inaccessible paths rejected.
- Core and Hoomans adopter smoke fixtures pass for dynamic `{speaker.name}`, `{addressee.name}`, `{target.name}`-style presentation, two-turn delivery, collection constraints and semantic offer frames.
- Full Core semantic harness remains green at 105 tests; changed Core/Hoomans Lua files pass the Kahlua error scan.

## S4 acceptance now verified

- Core PSDL behavior and beat records validate against the existing Interaction Director contracts; the compiler does not introduce a PSDL-specific director.
- Behavior records retain reusable semantic strategy fields: `act`, `mode`, `stimuli`, capabilities, outputs, relevance modifiers and continuation policy.
- Beat records retain `entry`, `maintain`, `exit`, candidate relevance, cooldown, maximum turns and optional group fields, and must reference behavior records.
- Beat wording is rejected and simple dialogue remains independently expressible; behavior/beat predicates use the same Core predicate normalizer as dialogue and offers.
- `render_psdl_director_plan` projects deterministic Core PSDL records into the existing behavior/beat registry shapes, with no second runtime or wording authority.
- The representative argument-beat fixture compiles and projects through the existing director contract; the full Core semantic harness passes 106 tests.

## S5 bounded adopter chunk now verified

- DynamicTrading/DTCommon's trader conversation pack and static suggestion surface are consolidated into one final `psdl/dialogue/trading.json` dialogue record owned by `DTCommon`.
- ProjectHoomans' companion `whats_up` check-in suggestions are consolidated into `psdl/dialogue/companion_check_in.json` owned by `ProjectHoomans`.
- Both adopter surfaces compile through Core's PSDL compiler; generated pack/UI/index artifacts remain downstream-only and package-routed.
- Existing DT semantic-pack registration, trader conversation parity/pending/roster smokes, and Hoomans static-suggestion/identity availability smokes pass.
- Superseded DT pack/static source files, Hoomans static suggestion source, old generated static/trading modules and the Hoomans static provider's old require path were removed or redirected; targeted caller/reference searches show no remaining production reference to those superseded modules.
- Core recognition projection preserves the existing DT semantic-pack contract, while Hoomans UI projection preserves hub, slot, target, extension, locale and pattern metadata.
- Current Core semantic harness passes 109 tests; changed adopter Lua passes the Kahlua error scan.
- Core's remaining static suggestion authoring surface is now split into final semantic PSDL shards `psdl/dialogue/core_check_in.json` and `psdl/dialogue/core_identity.json`, preserving all ten IDs, EN/TL text, ordering and semantic frame metadata.
- The Core-owned PSDL UI records route to `PsychopatzCore/Semantics/Generated/Conversation/UI/Psdl/Dialogue/CoreCheckIn` and `CoreIdentity`; Hoomans receives only downstream indexes/aggregate runtime output, and no duplicate Core compiler or schema is introduced.
- Core's combined writer now emits the DTCommon provider-local generated manifest alongside its routed registry, so standalone DT runtime metadata remains synchronized with the combined model fingerprint.
- Core static-suggestion parity and caller/reference-zero checks pass; no maintained code references `StaticSuggestionsCore`, `static_suggestions_core.json`, or the superseded static shard ID.

## S5 runtime-plan and social-check-in chunk

- Core now emits registry-addressable PSDL runtime plans through the existing conversation registry/discovery/generation path. `Registry.PSDLPlan(id)` is a lookup seam for adopters; it is not a second dialogue runtime.
- Core's compiler projects explicitly opted-in PSDL inline response/offer text into downstream `Conversation/Text` catalogs with data-driven locale discovery and the existing text-catalog contract. PSDL remains the only maintained source for those records.
- ProjectHoomans now owns six actor-neutral PSDL dialogue records for wellbeing and small talk, preserving the existing opening turns, semantic offer frames, relationship gates, effects, EN/TL text and runtime block identities.
- The Hoomans adapter maps those Core-generated plans into the existing `Registry.RegisterBlock` authority; no PSDL-specific lifecycle, choice evaluator or effect runtime was added.
- Superseded Hoomans `00`, `40`, and `50` conversation definition files and five Core social text source files are removed. Caller/reference-zero searches are clean, and the Hoomans block smoke now checks text routing, opening text, choice keys and response keys directly.
- Core harness (109 tests), Hoomans conversation/authority/composition/semantic smokes, DynamicTrading trader/PSDL smokes, the three-repository S0 guard and changed Conversation Kahlua scans pass.

## S5 greetings chunk

- ProjectHoomans now owns `psdl/dialogue/social_greetings.json`, with 21 final dialogue records: 20 relationship/time greeting variants plus hostile parley.
- Core compiler text projection now handles response variants and explicit bounded compatibility text rows, preserving all 210 EN/TL legacy greeting keys. The generated Hoomans catalogs contain only downstream PSDL text output; two semantic offer utterance rows are intentional additional bindings.
- The Hoomans PSDL adapter maps actor-neutral relationship state and world-hour predicates to the existing PNC relationship/time gates, preserves randomized greeting variants and portrait animation, and maps hostile parley to the existing ceasefire effect/close authority.
- The superseded Hoomans greetings definition, 21 Core greeting text sources, old generated Core/Hoomans greeting catalogs, and the stale ceasefire text path are removed or redirected. Reference searches are clean for the old authoring paths.
- Core registry generation now appends required modules directly, avoiding a persistent Lua local per generated module and keeping the Build 42 200-local limit safe as PSDL plans grow.
- Greeting parity, all Hoomans conversation/authority/composition smokes, all DT smokes, Core 109-test harness, three-repository S0 guard, and changed Conversation Kahlua scans pass.

## S5 ask-about migration chunk

- ProjectHoomans now owns the final `psdl/dialogue/social_ask_about.json` source for the neutral, member, and special ask-about records.
- EN/TL parity covers all 30 legacy ask-about entries; the two legacy player-name occurrences are intentionally represented as `{addressee.name}`.
- Core's shared text formatter now invokes the existing Core-owned public-path binding contract, and the Hoomans adopter projects native NPC/player identity into actor-neutral `speaker` and `addressee` bindings while retaining legacy flat fields for existing catalogs.
- The superseded Hoomans ask-about definition and three Core-owned ask-about text sources/generated catalogs were removed. Exact caller/reference-zero and frozen-old-surface checks pass.
- Hoomans conversation smoke, Core 109-test harness, DynamicTrading conversation/adopter smokes, S0 three-repository audit/guard, and changed Conversation Kahlua scans pass.

## S5 settlement-admission migration chunk

- ProjectHoomans now owns the final `psdl/dialogue/social_settlement_admission.json` record, with three preserved opening variants and the accepted-response text row.
- The adopter adapter projects the shared `relationship.settlementVisit.active` predicate to the existing `pnc:settlement_visit` authority gate and preserves the existing admission request, server authority, diary, and relationship-refresh flow.
- The superseded Hoomans settlement-admission definition and Core-owned arrival text source/generated catalogs were removed. EN/TL parity covers all 8 legacy entries, with exact caller/reference-zero evidence.
- Hoomans settlement selector/variant/gate smoke, Core 109-test harness, DynamicTrading conversation/adopter smokes, S0 three-repository audit/guard, and changed Conversation Kahlua scans pass.

## Normative decisions now frozen

- PSDL is the target first-party authoring standard across PsychopatzCore, ProjectHoomans, and DynamicTrading/DTCommon.
- PsychopatzCore is the physical owner of the PSDL language/schema, canonical IR, compiler/normalizer, generic validation, shared predicates/references/slots/bindings and reusable authoring service.
- ProjectHoomans and DynamicTrading are mandatory adopters, not optional future scope, and may not duplicate Core's PSDL mechanism.
- Canonical source is actor-neutral: `speaker`, `addressee`, `target`, typed slots/references.
- New reusable authoring does not use player/NPC-specific name variables.
- Offers are semantic affordances; player buttons and NPC choices are projections.
- Turns, offers and transitions are distinct concepts.
- Behaviors and beats are first-class PSDL module kinds.
- Beats orchestrate behaviors and never become mandatory wrappers around simple dialogue.
- One shared predicate language applies across modules.
- Inline locale maps use EN as required fallback; languages are data-driven.
- Existing old authoring is migration input only.
- No new first-party `Legacy/Compat/Old/V1/PartNN` source copies or broad alias registries.
- Migrated domains delete their superseded first-party source after parity/caller-zero proof.
- Generated Lua/JSON/translations remain downstream-only.

## Workspace/concurrency warning

All three repositories may contain concurrent work. At the latest documentation checkpoint, PsychopatzCore contains the Core-owned PSDL documentation and CodeBuilder changes; ProjectHoomans and DynamicTrading contain the bounded S5 adopter migration alongside unrelated dirty/untracked work that predates this scope clarification.

Do not infer that earlier work was discarded or that HEAD is permanently authoritative. Each phase must re-inspect **all three repositories** and current Git history/worktrees before editing, preserve any concurrent work, and treat exact current source as truth.

## Next Chunk

Continue **S5** across ProjectHoomans and DynamicTrading/DTCommon through the Core compiler: commit the current settlement-admission chunk in adopter repositories first, then migrate the next coherent maintained domain, prove parity and caller/reference zero, and remove its superseded source. Prior adopter chunks, Core static-suggestion/runtime-plan/social-check-in work, greetings, ask-about, and settlement admission remain bounded S5 checkpoints; S5-S8 remain open.

## Evidence status

- `CODE_VERIFIED`: runtime capabilities listed above were inspected in current source before this roadmap was written.
- `TEST_VERIFIED`: S2 Core compiler fixtures and the full 105-test semantic harness pass.
- `TEST_VERIFIED`: S0 guard and focused audit tests pass; the current three-repository guard pass is recorded in the inventory.
- `TEST_VERIFIED`: S1 Core/adopter contract fixtures and the full 100-test semantic harness pass; changed Lua files pass Kahlua verification.
- `TEST_VERIFIED`: S3 Core/Hoomans response, offer and binding fixtures pass; changed Lua files pass Kahlua verification.
- `TEST_VERIFIED`: S4 Core behavior/beat projection fixtures and the full 106-test semantic harness pass.
- `TEST_VERIFIED`: current Core semantic harness passes 109 tests after the bounded S5 adopter projection; DT and Hoomans adopter smokes pass.
- `TEST_VERIFIED`: current Core semantic harness passes 109 tests after runtime-plan/text-catalog integration; the Hoomans social-check-in, DT trader, three-repository guard and changed Conversation Kahlua gates pass.
- `TEST_VERIFIED`: greeting PSDL preserves 210 legacy EN/TL keys, Hoomans greeting selection/variant/ceasefire parity passes, and the generated registry remains Kahlua-safe after the local-budget fix.
- `STATIC_ONLY`: S5–S8 migration and final acceptance gates remain open.

## Stop conditions

Do not stop after producing only schemas or examples.

Stop only when:

- S0–S8 developer objective is complete;
- a genuine ownership/auth/tooling blocker prevents safe progress;
- or all developer work is complete and only explicit user-owned native acceptance remains.

No push or Workshop publication.
