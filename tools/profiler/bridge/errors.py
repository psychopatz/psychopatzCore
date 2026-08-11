"""Stable bridge exceptions and protocol error codes."""

ERROR_CODES = frozenset({
    "INVALID_REQUEST", "UNSUPPORTED_PROTOCOL", "UNKNOWN_NAMESPACE",
    "UNKNOWN_COMMAND", "INVALID_ARGUMENTS", "NOT_AVAILABLE",
    "NOT_AUTHORIZED", "BUSY", "TIMEOUT", "INTERNAL_ERROR",
    "STALE_RUNTIME", "MALFORMED_RESPONSE",
})


class BridgeError(Exception):
    """Base error for bridge client and transport failures."""


class BridgeProtocolError(BridgeError):
    """A payload violated protocol v1."""


class BridgeBusyError(BridgeError):
    """All bounded transport slots are occupied."""
