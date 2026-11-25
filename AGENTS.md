# PsychopatzCore — Agent Repository Instructions

## Durable-policy rule

Keep this file limited to repository-wide rules that remain useful across unrelated goals.

- Do not place active goals, phases, Next Chunks, progress, completed-phase history, migration status, or superseded instructions in `AGENTS.md`.
- Put goal-specific state in the appropriate `Docs/` roadmap, progress, runbook, and architecture documents.
- Delete obsolete instructions instead of keeping historical goal text in this always-loaded file. Git history is the archive.
- Keep executable `/goal` prompts in ChatGPT unless the user explicitly asks for a checked-in prompt.

## Git safety

- Do not create new Git branches for PsychopatzCore work. The same standing rule applies when coordinating ProjectHoomans and DynamicTrading.
- Use existing `main` only after checking local and remote state, dirty work, worktrees, and concurrent edits.
- Preserve unrelated work. Do not blind-pull, force-push, destructively reset/rebase, auto-stash/discard, or overwrite uncertain changes.
- Remote GitHub state does not prove a local worktree is clean.
- If integration safety is unclear, report the concrete conflict instead of creating another branch or discarding work.

## Ownership boundary

- PsychopatzCore owns reusable mechanisms and portable contracts.
- Product-specific gameplay rules remain with the adopting repository unless an explicit shared contract moves that responsibility.
- Reuse established public seams rather than duplicating adopter-owned state in Core.

## PZ Build 42 engine gotchas

- `instanceof(obj, "ClassName")` only checks `LuaManager.exposer.typeMap` and returns `false` for unexposed Java classes (e.g., `zombie.iso.Alarm` in SP). Verify exposure in `pz-java-baseline` or also check `typeof(obj)` / `getClassSimpleName(obj)` directly.
- SP (`AmbientStreamManager`) and MP dedicated server (`AmbientSoundManager`) can emit different Lua events for the same world occurrence (e.g., SP house alarms fire `OnWorldSound` with `zombie.iso.Alarm`, not `OnAmbientSound("burglar2")`). Verify both paths in `pz-java-baseline`.

## Semantic CodeBuilder generated artifacts

- Treat canonical semantic source/manifests and `tools/semantic_harness/codebuilder/generation_recipe.json` (`reconcile.py --check` / `--apply`) as authority. Generated Lua/translation artifacts are downstream output, not hand-edit targets.
- For semantic generation drift or cleanup, use the canonical recipe-driven check/apply workflow. Do not manually delete or patch suspected generated leftovers, and do not infer staleness from hash-suffixed filenames.
- Safe cleanup must be owner-scoped and closed-set: remove only artifacts/keys proven CodeBuilder-owned, preserve authored or mixed-package content, and treat unexpected leftovers as a generator-lifecycle defect to fix at the source.
- Normal semantic content must not grow per-file preserve/retirement lists. Keep dialogue wording in canonical CodeBuilder families, ordinary application/tooling text outside generated ownership, and preserve the accepted ConvoEngine semantic naming/sharding rules (including valid deterministic hash shards and the ban on arbitrary `PartNN`/migration-history source trees).
- Keep reusable dialogue semantics portable: declarative dialogue/behavior/beat/recognition logic belongs in canonical ConvoEngine source, reusable algorithms (for example fuzzy matching/directors/predicates) belong in the standard runtime, and game/backend-specific mechanics belong behind typed capability adapters rather than in the language/IR core.
- ConvoEngine is pre-release and its one first-party authoring target is `psychopatz.convo-engine.v1` with package schema `psychopatz.convo-engine.package.v1`; do not add a v2 or preserve `psychopatz.psdl.*` as a parallel first-party schema after migration/caller-zero.
- Author/rewrite dialogue by the dynamic-composition rule in `Docs/semantic_dialogue_language_standard/DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md`: one family owns reusable semantic meaning and conversational policy; runtime binds roles/slots/typed context and may compose only validated pieces; wording belongs in realization; gameplay truth/effects remain behind adopter-owned typed authorities.
- Keep ConvoEngine physical layout single-authority: one full generated semantic artifact per canonical family; consumer-specific views may be compact indexes only, never duplicate full `Behavior`/`Behaviors/Director` or `Beat`/`Beats/Director` payload trees.
- Keep localized prose out of maintained semantic family bodies: use the canonical owner-local translation source/catalog pipeline defined by `Docs/semantic_dialogue_language_standard/CONVOENGINE_PHYSICAL_LAYOUT_AND_LOCALIZATION.md`; generated ConvoEngine Lua must not carry complete multi-locale corpora.
- The post-S12 Conversation Director must follow `Docs/semantic_dialogue_language_standard/CONVERSATION_DIRECTOR_ARCHITECTURE.md`: it consumes canonical ConvoEngine metadata through sparse derived indexes and ephemeral scene context, and must never become a second semantic/gameplay/translation authority.
- Optimize ConvoEngine for compact human/agent authoring through explicit semantic IDs, shallow package/profile defaults and progressive-disclosure tooling; keep the normalized canonical IR explicit and validation-friendly rather than minifying semantics with cryptic keys or deep inheritance.
- Each adopter owns its game/domain ConvoEngine package and semantic programs; Core owns reusable compiler/stdlib semantics and must not hard-code adopter source roots. Generated grouping must split by coherent semantic domain/subdomain before byte/record safety sharding, generated modules must mirror source-package ownership, and compact hashes are only a last-resort collision fallback.
- Prefer the provider-owned declarative Semantic Test fixture system as the behavioural acceptance authority for ConvoEngine/runtime semantics (dialogue, knowledge, beats, behaviors, realizations, flows/actions and multi-turn outcomes); keep imperative tests for low-level compiler, fixture-engine, GUI, save/native, performance, protocol and static contracts, and migrate behavioural Python orchestration only after fixture parity is proven.
- Keep active semantic tests self-describing and domain-first: fixture paths/suites/case IDs and retained imperative test filenames must describe the current semantic or implementation contract, not historical phase/migration labels such as `C0A`, `R6`, `A6R2`, `PartNN`, or `batch1`; Git history is the provenance archive, and duplicate behavioral fixture authorities are not allowed.

## Runtime and publication

- A Git commit or push is not Steam Workshop publication.
- Do not publish Workshop content or drive native Project Zomboid unless the user explicitly authorizes it.
- When live SP/MP testing belongs to the user, finish all developer-side implementation and validation before handoff.
