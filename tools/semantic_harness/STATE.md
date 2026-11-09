# Semantic Harness Python state

`state.py` owns the provider-neutral Python source/working-world contract:

- `Provenance` origin labels;
- immutable `ImportedSourceSnapshot` records;
- mutable `HarnessWorkingWorld` projections;
- bounded deterministic patch and reset behavior.

The module stores provider payloads as opaque mappings. It does not parse saves,
rehydrate actors, normalize Project Hoomans records, or apply Dynamic Trading
policy. Adopters may keep compatibility import paths that re-export these
types while their provider-specific runtime remains local.
