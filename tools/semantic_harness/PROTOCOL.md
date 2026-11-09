# Semantic harness protocol ownership

The JSON-lines worker protocol is Core-owned and provider-neutral.

`tools/semantic_harness/lua/Protocol.lua` is the single Lua protocol adapter. It
owns the protocol version, bounded request decoding, response/error emission,
and the explicit `Protocol.NULL` marker used when a provider needs to encode a
JSON `null` value. The shared Core JSON codec is the only serializer used by
this boundary.

Provider repositories may add worker modules and command handlers, but they
must import `Protocol` from the Core semantic-harness Lua path. They must not
carry a second protocol implementation or change the JSON-lines envelope.

The compatibility contract is covered by:

- `tests/psychopatz_semantic_harness_protocol_smoke.lua`
- the Core JSON null-marker assertion in `tests/psychopatz_json_smoke.lua`
- each adopter's worker-module smoke test

This boundary migration does not yet move provider-specific worker state or
production semantic modules into Core; those remain separate migration slices.
