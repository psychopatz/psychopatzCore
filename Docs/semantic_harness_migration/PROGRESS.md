# Semantic Harness Migration Progress

## Phase 0/1 — Core contract and worker seam

Status: complete for the first two bounded implementation slices.

Implemented in commits `7364cab`, `ebd7844a`, `0115bddc`, `846b943`,
`22c084aa`, `188487f`, and `1f3b4c0e`:

- Core-owned provider and profile descriptors;
- fail-closed profile resolution and dependency validation;
- Core-only registry that does not require adopter repositories;
- independent Core, Project Hoomans, and Dynamic Trading repository discovery;
- legacy `PNC_HARNESS_*` environment aliases reported as compatibility use;
- focused Python contract tests.
- Core-owned bounded JSON-lines protocol;
- Core-only real-Lua worker with `HELLO`, `PING`, `CAPABILITIES`, and `QUIT`;
- worker boot test proving no adopter repository is required.
- Core-owned bounded Python worker client and launch specification;
- Hoomans runtime process module reduced to a compatibility adapter;
- explicit Hoomans `core` profile selecting the Core worker without loading PNC.
- Core-owned provider-neutral scenario document utilities: deep merge, JSON
  load/save, and actor identifier derivation;
- Core-owned serialized worker session lifecycle with late-start cleanup and
  queue-drain shutdown behavior;
- Hoomans scenario and worker-session modules reduced to compatibility paths;
- Hoomans defaults, health normalization, validation, and PNC worker remain
  adopter-owned.
- Core-owned CodeBuilder foundation: shared `CompileError`, locale
  normalization, deterministic JSON formatting, and collision-safe generated
  module naming;
- Hoomans CodeBuilder import paths now delegate those generic helpers to Core;
- Hoomans lexicon compiler now uses the Core compiler-error contract while
  retaining its WordNet allowlist and Hoomans concept policy.
- Core-owned typed dataset contract/compiler: provenance validation, bounded
  utterance normalization, duplicate detection, deterministic ordering, and
  callback-based adopter policy;
- Hoomans dialogue dataset compilation now delegates envelope mechanics to
  Core while retaining its semantic pattern/response validators.

Verification:

- `PYTHONPATH=tools python3 -W error -m unittest discover -s tools/semantic_harness/tests -q` — 25 passed;
- Hoomans runtime/config/profile tests — 6 passed;
- Hoomans Core-ownership/session/scenario compatibility tests — 7 passed;
- Hoomans CodeBuilder boundary/compiler/dataset/conversation tests — passed;
- Core typed-dataset and Hoomans dialogue-adapter tests — passed;
- Hoomans process correlation/timeout tests — passed;
- Hoomans production worker startup and restart compatibility — passed;
- `python3 -W error -m py_compile tools/semantic_harness/*.py tools/semantic_harness/tests/*.py` — passed;
- standalone Lua Core semantic require smoke — passed;
- `git diff --check` — passed.

The Project Hoomans production worker remains the default compatibility
profile. Its process lifecycle, protocol, generic document mechanics,
serialized session lifecycle, and CodeBuilder foundation are delegated to
Core, while its production module loader, scenario defaults, health
normalization, validation, source manifests, package ownership, and output
routing remain Hoomans-owned. The next safe chunk is extracting the remaining
provider-neutral dialogue pattern/response validation primitives without
moving Hoomans semantic policy sets into Core.
