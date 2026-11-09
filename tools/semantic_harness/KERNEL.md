# Semantic harness Lua kernel ownership

Core owns the bounded worker kernel in
`tools/semantic_harness/lua/worker/RuntimeState.lua` and
`tools/semantic_harness/lua/worker/Values.lua`.

These modules provide worker container lifecycle, bounded diagnostics, value
copying, and scalar normalization. Adopter-specific state remains opaque; Core
does not interpret Hoomans, DynamicTrading, or Project Zomboid gameplay policy.

Adopters may retain compatibility import paths while migrating callers, but
they must not carry a second implementation of this kernel.
