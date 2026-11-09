# Core Semantic Harness

This is the Core-owned home of the provider-neutral semantic harness.

The first migration slice establishes the contract boundary only:

- `provider_registry.py` owns provider and profile composition;
  `ProviderDescriptor` also carries the bounded
  `semantic.harness_execution.v1` callback declaration, so adopters can
  register abstract and physical profiles without adding another worker;
- `repository_layout.py` discovers Core as required and adopters as optional;
- `protocol.py` and `lua/worker.lua` provide the Core-only bounded worker seam;
- `process.py` owns the bounded Python worker lifecycle and request correlation;
- `scenario.py` owns provider-neutral document merge, JSON persistence, and
  bounded actor identifier helpers;
- `worker_session.py` owns serialized worker queue lifecycle and shutdown;
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
document, and session mechanics delegate here. CodeBuilder and provider
adapters move in later slices. Each subsequent slice should move one coherent
boundary and retain a focused compatibility test.

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

Run the contract tests from the Core repository with:

```bash
PYTHONPATH=tools python3 -m unittest discover -s tools/semantic_harness/tests -q
```
