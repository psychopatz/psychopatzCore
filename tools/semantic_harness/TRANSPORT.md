# Semantic harness transport evidence

`tools/semantic_harness/lua/worker/TransportEvidence.lua` owns the generic
partition and annotation mechanics for worker transport records. Unknown
commands remain dispatch evidence by default.

Adopters configure either a fact command or an `isFactCommand(command, event)`
callback. Core never imports PNC, DynamicTrading, or another provider namespace
to decide whether an event is a fact. Provider-specific command semantics stay
in the adapter bootstrap.
