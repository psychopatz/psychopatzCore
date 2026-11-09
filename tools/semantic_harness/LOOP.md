# Semantic Harness Worker Loop

`worker/WorkerLoop.lua` owns the provider-neutral JSON-lines lifecycle after a
worker-specific script has supplied the Core protocol module, a hello callback,
and a request dispatch callback.

It emits the handshake, reads requests, preserves request IDs, emits failures
or responses, and stops on the dispatch callback's quit signal. The optional
line iterator makes the lifecycle deterministic in smoke tests without
changing the production `io.lines()` path.

Provider scripts remain responsible for bootstrapping modules, constructing
their context, choosing handlers, and creating the hello/dispatch callbacks.
Core does not import Project Hoomans, DTAbstract, DTHoomans, or merchant
policy.
