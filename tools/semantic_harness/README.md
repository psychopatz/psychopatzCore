# Core Semantic Harness

This is the Core-owned home of the provider-neutral semantic harness.

The first migration slice establishes the contract boundary only:

- `provider_registry.py` owns provider and profile composition;
- `repository_layout.py` discovers Core as required and adopters as optional;
- no Core harness module imports Project Hoomans or Dynamic Trading;
- `core_registry()` boots a standalone Core-only profile.

The existing Hoomans Semantic Lab remains the compatibility implementation
until the worker, CodeBuilder, and provider adapters move in later slices. It
must not be copied into this package wholesale. Each subsequent slice should
move one coherent boundary and retain a focused compatibility test.

Run the contract tests from the Core repository with:

```bash
PYTHONPATH=tools python3 -m unittest discover -s tools/semantic_harness/tests -q
```
