# Core Semantic Harness

This is the Core-owned home of the provider-neutral semantic harness.

The first migration slice establishes the contract boundary only:

- `provider_registry.py` owns provider and profile composition;
- `repository_layout.py` discovers Core as required and adopters as optional;
- `protocol.py` and `lua/worker.lua` provide the Core-only bounded worker seam;
- `process.py` owns the bounded Python worker lifecycle and request correlation;
- `scenario.py` owns provider-neutral document merge, JSON persistence, and
  bounded actor identifier helpers;
- `worker_session.py` owns serialized worker queue lifecycle and shutdown;
- no Core harness module imports Project Hoomans or Dynamic Trading;
- `core_registry()` boots a standalone Core-only profile.

The existing Hoomans Semantic Lab remains the adopter-facing authoring
implementation. Its scenario defaults, health normalization, validation, and
PNC production worker remain Hoomans-owned; its generic process, protocol,
document, and session mechanics delegate here. CodeBuilder and provider
adapters move in later slices. Each subsequent slice should move one coherent
boundary and retain a focused compatibility test.

Run the contract tests from the Core repository with:

```bash
PYTHONPATH=tools python3 -m unittest discover -s tools/semantic_harness/tests -q
```
