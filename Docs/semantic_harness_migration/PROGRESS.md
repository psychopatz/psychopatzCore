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

Verification:

- `PYTHONPATH=tools python3 -m unittest discover -s tools/semantic_harness/tests -q` — 13 passed;
- `python3 -W error -m py_compile tools/semantic_harness/*.py tools/semantic_harness/tests/*.py` — passed;
- standalone Lua Core semantic require smoke — passed;
- `git diff --check` — passed.

The existing Project Hoomans harness remains unchanged and is still the active
compatibility implementation. The next safe chunk is moving the generic Python
process client and wiring the Hoomans launcher to select the Core worker by
profile, without moving Hoomans production modules yet.
