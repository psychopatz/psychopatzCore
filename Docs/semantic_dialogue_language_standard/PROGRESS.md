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

## S5 companion-topics migration chunk

- ProjectHoomans now owns the final `psdl/dialogue/social_companion_topics.json` source for personal trust, relationship affinity, territory claim, and member work-orders topics.
- EN/TL parity covers all 30 legacy text entries; actor-specific `{playerFirstName}` bindings are represented as `{addressee.name}`, and the territory lock diagnostic is retained through a generated PSDL `textRows` entry.
- The adopter adapter projects the shared familiarity/approval predicates plus the existing audience and base-establishment gates, preserving the territory priority, relationship effects, and territory-claim effect.
- The superseded Hoomans 90–93 definition modules and four Core text sources/generated catalogs were removed. The retained needs definition remains loaded unchanged; no unrelated domain was removed from composition.
- Hoomans conversation smoke now checks the migrated block routing, offers, effects, gate diagnostics and block-count parity. Companion text parity, caller/reference-zero, three-repository S0 audit/guard, Core 109-test harness, DynamicTrading smokes, and changed Conversation Kahlua scans pass.

## S5 needs and gift-continuation migration chunk

- ProjectHoomans now owns the final `psdl/dialogue/needs_support.json` source for neutral, member, and special needs conversations.
- EN/TL parity covers all 120 legacy audience-locale entries, including gift offer/received text and existing gift-item placeholders; the PSDL output is now adopter-routed under `psdl/needs/{audience}/support.json`.
- The Hoomans PSDL adapter now projects bounded multi-turn plans into the existing conversation registry nodes, preserving the three opening offers, gift continuation transition, gift continuation turn, and return-to-root outcome without introducing a second runtime.
- The superseded Hoomans needs definition and three Core needs text sources/generated catalogs were removed. The independent `needs/gifts/preference.json` surface remains intact.
- Hoomans conversation/translation checks, needs parity, Core 109-test harness, DynamicTrading smokes, S0 three-repository audit/guard, and changed Conversation Kahlua scans pass.

## S5 task, command, and companion-action migration chunk

- ProjectHoomans now owns four final PSDL dialogue shards for the maintained companion command surface: player commands, companion replies, lifecycle actions, and combat/horde reactions. The four shards preserve all 76 legacy semantic phrase families and route through the Core compiler.
- The authored participants are actor-neutral `speaker`/`addressee` pairs. Legacy player-name and plural-name wording is represented through `{addressee.name}` bindings; one mismatched legacy TL placeholder was corrected during parity validation so EN/TL placeholder contracts are valid.
- The existing Hoomans semantic response catalog remains the gameplay selector and response-plan authority. It now projects wording from Core-generated `Registry.PSDLPlan` variants, with data-driven locale selection and EN fallback; no second command runtime or UI-text reparse path was added.
- Existing companion speech normalization preserves command aliases (`camp_none`/`camp_rejected`) and maps legacy flat render tokens into the actor-neutral binding contract. Existing command execution, horde acknowledgement, effects, and safety authority remain unchanged.
- The superseded Core command/player, command/replies, command/lifecycle, and combat-horde content sources and generated Content modules are removed. Core's manifest now routes the four adopter-owned PSDL shards; Hoomans generated indexes/registries are downstream-only.
- Parity covers 76 records in both EN and TL (152 locale entries), direct command realization and horde acknowledgement smokes pass, Core's semantic harness remains green at 109 tests, and the three-repository S0 audit/guard reports zero violations. The broad presentation-only companion smoke still has its known camp-rejection handoff failure after direct semantic resolution succeeds and is tracked as baseline evidence rather than treated as migration parity.

## S5 social apology, hostility, and reconciliation migration chunk

- ProjectHoomans now owns `psdl/dialogue/social_apology.json` as the final authored source for the four apology/reconciliation families: default, friendly, stressed, and withdrawn. Each family is split into four bounded style plans (neutral, warm, terse, guarded), preserving 160 EN/TL phrase pairs through the Core PSDL compiler.
- The existing Hoomans response catalog remains the selector. Its social adapter projects Core-generated plans back into the existing `PHRASE_FAMILIES` authority, grouping variants by authored style and retaining the existing `SpeechRealization`, relationship, stress, and withdrawal behavior.
- Core validation now recognizes a PSDL-declared `responseTemplateID` alias when an existing Core-owned behavior references that semantic content template. This is a generic compiler validation seam; it does not create a second content schema or runtime.
- Superseded Core `content/social_apology.json`, Core/Hoomans Apology translation files, generated SocialApology/Apology outputs, and their translation-manifest entries are removed. The old semantic IDs remain only as runtime contract IDs and PSDL metadata lineage, not as parallel authoring sources.
- Source parity reports 4 families, 16 style plans, and 320 locale values with zero differences. Core's 109-test harness, PSDL build, S0 guard, social source/plan tests, direct Lua style-family load, and changed-file Kahlua scans pass. The Lua worker remains blocked by the pre-existing duplicate automatic-flow registration `semantic.generated.simple_command.camp.failed` after startup advances past the former apology-template check.

## S5 navigation migration chunk

- ProjectHoomans now owns the final `psdl/dialogue/navigation.json` source for the five maintained navigation families: camp, empty camp, default, orders, and subject change. Each family is represented by four bounded style plans (neutral, warm, terse, guarded), preserving 200 EN/TL entries and 400 locale values.
- The existing Hoomans navigation response catalog remains the selector. Its adapter loads Core-generated `Registry.PSDLPlan` variants into the existing phrase-family/SpeechRealization authority, preserving navigation subjects, priorities, and gameplay branch ownership without adding a PSDL runtime.
- The superseded Core navigation content source, Hoomans navigation phrase-family source, generated Content modules, and split EN/TL Navigation translation files are removed. Core's manifest routes the adopter-owned PSDL shard; generated indexes and registries remain downstream-only.
- Navigation parity reports 5 families, 20 style plans, and 400 EN/TL locale values with zero differences. Core's 109-test harness, PSDL build, S0 guard, focused navigation/response-catalog smokes, generated ownership tests, direct Lua family load, and changed-file Kahlua scan pass.

## S5 knowledge, identity, activity, and gossip migration chunk

- PsychopatzCore now owns four final PSDL shards: `core_knowledge_activity.json`, `core_knowledge_gossip.json`, `core_knowledge_identity.json`, and `core_knowledge_facts.json`. They preserve seven semantic families as 32 bounded style plans, 320 phrase pairs, and 640 EN/TL locale values.
- The existing ProjectHoomans question response catalog remains the selector. Its Core-content adapter projects Core-generated `Registry.PSDLPlan` variants into the established phrase-family and `SpeechRealization` authorities; knowledge, activity, identity, and gossip gameplay/context selection remains adopter-owned.
- Actor-neutral presentation uses `{speaker.name}`, `{target.name}`, and `{addressee.name}` through the existing Core text-binding contract, with Hoomans context projections retaining legacy flat arguments only at the adopter boundary.
- Superseded Core knowledge content sources/generated modules/translations and the Hoomans Knowledge phrase-family source/generated index/split translations are removed. The Core manifest routes the four final PSDL shards; no second compiler, schema, predicate evaluator, binding engine, or runtime is added.
- Knowledge parity reports 7 families, 32 style plans, 320 phrase pairs, and 640 EN/TL locale values with zero differences. Core's 109-test harness, PSDL build, S0 three-repository guard, focused Hoomans knowledge/world-knowledge smokes, generated ownership tests, direct Lua family load, and changed-file Kahlua scans pass. The broader worker trio retains its known startup transport baseline and is not counted as a migration failure.

## S5 world-event warning migration chunk

- PsychopatzCore now owns final PSDL dialogue records for `semantic.interaction.world_event.warning` and `semantic.interaction.world_event.warning_flavor`, preserving two semantic families, eight bounded style plans, 80 phrase pairs, and 160 EN/TL locale values.
- The existing Interaction Director behavior is now authored as the Core PSDL `behavior.world_event_warn` record. Its `WARN_GROUP` act, `WORLD_EVENT`/`DANGER_CHANGED` stimuli, `world.immediateDanger` predicate, relevance, emote, and speech/flavor template contracts remain unchanged; no PSDL-specific director was introduced.
- ProjectHoomans' social response adapter projects the Core-generated plans into the existing phrase-family and SpeechRealization authority, while interaction arbitration and world-event lifecycle ownership remain unchanged. DynamicTrading receives only generated routing/fingerprint output and no parallel event dialogue mechanism.
- Superseded Core world-event content and behavior sources/generated modules/translations are removed. The Core manifest routes two PSDL dialogue shards and one PSDL behavior shard; caller/reference-zero searches are clean outside lineage metadata and generated outputs.
- World-event parity, direct Lua family/behavior loads, Core's 109-test harness, PSDL build, three-repository S0 guard, and changed-file Kahlua scans pass. The worker authoring suite still hits the pre-existing duplicate automatic-flow registration `semantic.generated.simple_command.camp.failed`; temporary-copy compiler tests retain the existing mandatory external-adopter fixture assumption.

## S5 medical-event migration chunk

- ProjectHoomans now owns six final PSDL medical-event shards named by semantic response surface: `medical_event_call.json`, `medical_event_overview.json`, `medical_event_repeat.json`, `medical_event_teammate.json`, `medical_event_treatment.json`, and `medical_event_update.json`. Together they preserve 32 semantic families, 32 bounded records, 320 phrase pairs, and 640 EN/TL locale values without numeric or legacy shard copies.
- The existing Hoomans medical response catalog remains the selector and its Core adapter projects PSDL plans into the established phrase-family/SpeechRealization authority. Medical distress predicates, follow-up offers, response plans, treatment logic, and health gameplay remain adopter-owned.
- Superseded Core medical content sources/generated modules and split Event translations are removed. The Core manifest routes the six adopter-owned PSDL shards; DynamicTrading receives only generated manifest/registry routing and no medical dialogue authority.
- Medical parity reports 32 families, 320 phrase pairs, and 640 EN/TL locale values with zero differences. Core's 109-test harness, PSDL build, direct Lua family loads, three-repository S0 guard, and changed-file Kahlua scans pass. The broader worker startup and temporary-copy compiler fixture baselines remain separate from this parity gate.

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

Continue **S5** across ProjectHoomans and DynamicTrading/DTCommon through the Core compiler: migrate the next coherent event-reaction/combat surface, then remaining ProjectHoomans and DynamicTrading/DTCommon surfaces. For each domain, prove parity and caller/reference zero, remove its superseded source, and keep Core as the sole mechanism owner; S5-S8 remain open.

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
- `TEST_VERIFIED`: task/command/companion-action PSDL preserves 76 semantic phrase families and 152 EN/TL locale entries; direct command realization, horde acknowledgement, Core 109-test, three-repository audit/guard, and changed Conversation Kahlua gates pass.
- `TEST_VERIFIED`: navigation PSDL preserves 5 semantic families, 20 bounded style plans, and 400 EN/TL locale values; navigation/response-catalog smokes, generated ownership tests, Core 109-test, three-repository audit/guard, direct Lua family load, and changed-file Kahlua gates pass.
- `TEST_VERIFIED`: knowledge PSDL preserves 7 semantic families, 32 bounded style plans, 320 phrase pairs, and 640 EN/TL locale values; Core 109-test, PSDL build, three-repository audit/guard, focused knowledge/world-knowledge smokes, generated ownership tests, direct Lua family load, and changed-file Kahlua scans pass.
- `TEST_VERIFIED`: world-event PSDL preserves 2 semantic families, 8 bounded style plans, 80 phrase pairs, and 160 EN/TL locale values; the existing behavior contract, direct Lua family/behavior loads, Core 109-test harness, PSDL build, three-repository audit/guard, and changed-file Kahlua scans pass.
- `TEST_VERIFIED`: medical-event PSDL preserves 32 semantic families/records, 320 phrase pairs, and 640 EN/TL locale values across six semantic shards; Core 109-test harness, PSDL build, direct Lua family loads, three-repository audit/guard, and changed-file Kahlua scans pass.
- `BASELINE_EVIDENCE`: the broad `pnc_companion_commands_smoke` still fails at its pre-existing presentation-path camp-rejection handoff after the direct semantic resolver succeeds; no new Core or PSDL caller/reference failure is present.
- `STATIC_ONLY`: S5–S8 migration and final acceptance gates remain open.

## Stop conditions

Do not stop after producing only schemas or examples.

Stop only when:

- S0–S8 developer objective is complete;
- a genuine ownership/auth/tooling blocker prevents safe progress;
- or all developer work is complete and only explicit user-owned native acceptance remains.

No push or Workshop publication.
