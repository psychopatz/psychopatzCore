# Psychopatz Asset Harness — Milestones H0–H9

**Current priority:** H0. Owner: PsychopatzCore developer tooling. **Do not confuse this with the older A0–A8 radio-art production stages** in `Docs/radio_os/CORE_RADIO_DEVICE_ASSETS.md` or the compositor C0–C6. H0–H9 builds the **agent-operated asset tool** that enables those tasks; implementation does not mean finished art.

| Phase | Scope | Acceptance |
|---|---|---|
| **H0 — NEXT** | Fresh Core source audit: profiler CLI/data/bridge, preview snapshots, radio builders, manifest/rendering and `common/media/ui`; existing tests + missing art inventory | Baseline map, verified interfaces and constraints, safe MVP interfaces, source provenance; no runtime changes |
| H1 | Small package/CLI skeleton, command discovery, JSON envelopes, error codes, token budgets, project JSON and golden fixtures | Command invocation works offline on Windows/Linux, deterministic JSON, no GUI imports, tests for failures/truncation |
| H2 | Read-only source inspection and sprite-region detection (alpha/bounds/connected components) + manual rectangle editor via CLI | Exact dimension and source hash; quality-preserving extracts; proposed vs verified distinction; no destructive writes |
| H3 | JSON layer assembler and deterministic Pillow compositor, debug overlay and full-res PNG outputs | Opaque LCD matte, accurate transparent exterior, adjustable named layers, pixel-perfect anchor/scale/re-run equality |
| H4 | LCD alpha/aperture/hitbox and LED timeline+state engine; optional condition overlays | Every sample state and zoom aligns and validates; animation frames/contact sheet reproducible, no fake gameplay state |
| H5 | Authoring project persistence, batch operations, copy/diff/inspection, bounded result artifacts | LLM can run import -> slice -> adjust -> render -> inspect -> validate without mouse, state is resumable |
| H6 | Versioned Core export, safe staged/approved apply, rollback/conflict guard, skin-manifest v1 compatibility | Correct Core `common/media/ui` paths, alpha tests, no overwrite by default, export round-trip, six legacy skins unaffected |
| H7 | US Army walkie end-to-end pilot using **approved** high-res PZ-faithful art; scripted CLI recipes and documentation | Art source provenance; rendered/validated shell/LED/wear; visual approval and explicit native pending if game unavailable |
| H8 | Additional walkies, verified HAM and manpack authoring workflows using same engine; extension SDK | Variable proportions/control counts, distinct vanilla silhouettes, no consumer/mod-specific fork, regressions intact |
| H9 | Optional bridge-driven **read-only** native render diagnostics, performance/budget measurements and manual PZ acceptance handoff | Implement only after capability review; normal Build42 SP/MP verifies game paths/renderer; no headless harness |

## Dependency order

- H0 -> H1 -> H2 -> H3 gives the first autonomous **image-to-preview** vertical slice. Prioritize actual CLI visibility; do not spend early milestones on Flask, Qt, Konva or a fancy browser.
- H4/H5 add dynamic states and resumable agent work. H6 is the first **game-runtime export** milestone; no production PNG substitutions before export safety and model approval.
- H7 requires genuine accepted source art. If missing, report blocker and continue H8 fixtures and safe modular tooling; don't stretch the legacy 341px compact sheet to pretend it is high resolution.
- H8 includes HAM/manpack and is not optional. Verify B42 items before binding a `fullType`.
- H9 native testing is not automatically available. A CLI mock, Pillow composite and profiler report **cannot** prove what PZ renders in game.

## Safe delivery gates

For each completed phase, provide: owning files, exact CLI usage, tests (new + relevant existing), output JSON/artifact hashes, compatibility findings, commit SHA/push status, current blockers and next H#. Maintain `Docs/asset_harness/ASSET_HARNESS_PROGRESS.md`. Work in small commits; execute safe stages unattended and don't ask for recurring approval.

No PZ Headless Harness. No forced branches or destructive resets, saves modification, bulk copying generated sheets into runtime dirs, arbitrary external code execution, or consumer gameplay refactor. No rewrites of already working profiler or bridge subsystems.
