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
- `codebuilder/` owns provider-neutral compiler errors, locale normalization,
  deterministic generated-module naming, typed dataset envelopes, and the
  callback-based dataset compiler;
- no Core harness module imports Project Hoomans or Dynamic Trading;
- `core_registry()` boots a standalone Core-only profile.

The existing Hoomans Semantic Lab remains the adopter-facing authoring
implementation. Its scenario defaults, health normalization, validation, and
PNC production worker remain Hoomans-owned; its generic process, protocol,
document, and session mechanics delegate here. CodeBuilder and provider
adapters move in later slices. Each subsequent slice should move one coherent
boundary and retain a focused compatibility test.

The CodeBuilder foundation and typed dataset compiler seam are Core-owned:
compiler errors, translation-locale normalization, deterministic generated-
module naming, provenance validation, bounded utterance normalization, and
deterministic pattern/response ordering. Adopters retain their source
manifests, semantic policy callbacks, package ownership, and output routing.

Run the contract tests from the Core repository with:

```bash
PYTHONPATH=tools python3 -m unittest discover -s tools/semantic_harness/tests -q
```
