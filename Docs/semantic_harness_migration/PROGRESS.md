# Semantic Harness Migration Progress

## Phase 0/1 — Core contract and worker seam

Status: complete for the first two bounded implementation slices.

Implemented in commits `7364cab`, `ebd7844a`, and `0115bddc`:

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

Verification:

- `PYTHONPATH=tools python3 -W error -m unittest discover -s tools/semantic_harness/tests -q` — 21 passed;
- Hoomans runtime/config/profile tests — 6 passed;
- Hoomans Core-ownership/session/scenario compatibility tests — 7 passed;
- Hoomans process correlation/timeout tests — passed;
- Hoomans production worker startup and restart compatibility — passed;
- `python3 -W error -m py_compile tools/semantic_harness/*.py tools/semantic_harness/tests/*.py` — passed;
- standalone Lua Core semantic require smoke — passed;
- `git diff --check` — passed.

The Project Hoomans production worker remains the default compatibility
profile. Its process lifecycle, protocol, generic document mechanics, and
serialized session lifecycle are delegated to Core, while its production
module loader, scenario defaults, health normalization, and validation remain
Hoomans-owned. The next safe chunk is extracting the provider-neutral
CodeBuilder contract and compiler seam.
