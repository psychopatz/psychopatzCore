# Semantic Harness Migration Progress

## Phase 0/1 — Core contract and worker seam

Status: complete for the first bounded implementation slice.

Implemented in commit `0c336dc`:

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

Verification:

- `PYTHONPATH=tools python3 -W error -m unittest discover -s tools/semantic_harness/tests -q` — 16 passed;
- Hoomans runtime/config/profile tests — 6 passed;
- Hoomans process correlation/timeout tests — passed;
- Hoomans production worker startup and restart compatibility — passed;
- `python3 -W error -m py_compile tools/semantic_harness/*.py tools/semantic_harness/tests/*.py` — passed;
- standalone Lua Core semantic require smoke — passed;
- `git diff --check` — passed.

The Project Hoomans production worker remains the default compatibility
profile. Its process lifecycle is now delegated to Core, while its production
module loader remains Hoomans-owned. The next safe chunk is moving generic
scenario/worker session contracts and then extracting CodeBuilder ownership.
