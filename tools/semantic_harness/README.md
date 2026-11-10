# Core Semantic Harness

This is the Core-owned home of the provider-neutral semantic harness.

The first migration slice establishes the contract boundary only:

- `provider_registry.py` owns provider and profile composition;
  `ProviderDescriptor` also carries the bounded
  `semantic.harness_execution.v1` callback declaration, so adopters can
  register abstract and physical profiles without adding another worker;
- `profile_loader.py` composes optional adopter registrars and emits neutral
  launch metadata for the Core worker;
- `repository_layout.py` discovers Core as required and adopters as optional;
- `protocol.py`, `lua/worker.lua`, and `lua/worker/ProviderLoader.lua` provide
  the bounded worker seam and optional-adopter loading contract;
- `process.py` owns the bounded Python worker lifecycle and request correlation;
- `scenario.py` owns provider-neutral document merge, JSON persistence, and
  bounded actor identifier helpers;
- `worker_session.py` owns serialized worker queue lifecycle and shutdown;
- `activity.py` owns the bounded cross-process activity stream used by
  harness clients;
- `runtime_discovery.py` owns numeric runtime selection and Lua executable
  probing without importing an adopter;
- `codebuilder/` owns provider-neutral compiler errors, locale normalization,
  deterministic generated-module naming, typed dataset envelopes, and the
  callback-based dataset compiler. Its `rule_contract.py` module also owns
  bounded source-reference lists, predicate AST validation, typed argument
  declarations, and scalar condition structure; adopters supply the field and
  type allowlists that carry their domain meaning;
- no Core harness module imports Project Hoomans or Dynamic Trading;
- `core_registry()` boots a standalone Core-only profile.

The existing Hoomans Semantic Lab remains the adopter-facing authoring
implementation. Its scenario defaults, health normalization, validation, and
PNC production worker remain Hoomans-owned; its generic process, protocol,
document, and session mechanics delegate here. Provider adapters are loaded
only when an adopter supplies neutral module-path and module-name metadata;
Core never names an adopter or makes an optional adapter a startup dependency.
Each subsequent slice should move one coherent boundary and retain a focused
compatibility test.

The CodeBuilder foundation, typed dataset compiler seam, and bounded rule
validation primitives are Core-owned:
compiler errors, translation-locale normalization, deterministic generated-
module naming, provenance validation, bounded utterance normalization, and
deterministic pattern/response ordering, plus reusable structural validation
for source references, predicates, typed arguments, and scalar conditions.
Adopters retain their source manifests, semantic allowlists, policy callbacks,
package ownership, and output routing.

Dynamic Trading's provider manifest is an adopter boundary: DTCommon owns
merchant policy and declares the shared conversation/identity/interaction
surface, DTAbstract composes the `abstract` profile, and DTHoomans composes
the `physical` profile. Core validates those declarations but never imports
Dynamic Trading or Project Hoomans.

## Optional provider worker loading

`WorkerLaunchSpec` can carry three provider-neutral values:

- `provider_module_paths`: Lua `package.path` templates;
- `provider_modules`: comma-separated adopter module names; and
- `execution_provider_id`: the selected provider that receives generic
  `SEMANTIC_PROVIDER` operations.

The worker exports these as `SEMANTIC_HARNESS_PROVIDER_MODULE_PATHS`,
`SEMANTIC_HARNESS_PROVIDER_MODULES`, and
`SEMANTIC_HARNESS_EXECUTION_PROVIDER_ID`. Each module must expose `New`,
`new`, or `create(SemanticExecution, context, callbacks)` and return the Core
execution contract. Missing or failed optional modules fail the selected
worker launch with a bounded diagnostic; leaving the metadata empty preserves
the standalone Core worker.

Dynamic Trading's `provider_worker_launch_values()` supplies these values for
DTAbstract and DTHoomans. The two profiles therefore use the same Core loader
and operation dispatch; only their declared materialization mode and provider
capabilities differ.

Run the contract tests from the Core repository with:

```bash
PYTHONPATH=tools python3 -m unittest discover -s tools/semantic_harness/tests -q
```
