"""Bounded JSON-lines protocol for the Core semantic harness worker."""

from __future__ import annotations

import json
from typing import Any


PROTOCOL_VERSION = 1
DEFAULT_MAX_MESSAGE_BYTES = 1024 * 1024


class ProtocolError(ValueError):
    """Raised when a worker message is malformed or exceeds a bound."""


def encode_request(
    request_id: str,
    command: str,
    payload: Any = None,
    *,
    max_bytes: int = DEFAULT_MAX_MESSAGE_BYTES,
) -> bytes:
    if not isinstance(request_id, str) or not request_id:
        raise ProtocolError("request id must be a non-empty string")
    if not isinstance(command, str) or not command:
        raise ProtocolError("command must be a non-empty string")
    message: dict[str, Any] = {
        "protocolVersion": PROTOCOL_VERSION,
        "id": request_id,
        "command": command,
    }
    if payload is not None:
        message["payload"] = payload
    try:
        encoded = json.dumps(
            message,
            ensure_ascii=False,
            separators=(",", ":"),
            allow_nan=False,
        ).encode("utf-8")
    except (TypeError, ValueError) as error:
        raise ProtocolError(f"request is not JSON-compatible: {error}") from error
    result = encoded + b"\n"
    if len(result) > max_bytes:
        raise ProtocolError("worker request exceeds the message limit")
    return result


def decode_message(
    line: bytes | str,
    *,
    max_bytes: int = DEFAULT_MAX_MESSAGE_BYTES,
) -> dict[str, Any]:
    if isinstance(line, bytes):
        if len(line) > max_bytes:
            raise ProtocolError("worker response exceeds the message limit")
        try:
            text = line.decode("utf-8")
        except UnicodeDecodeError as error:
            raise ProtocolError("worker response is not UTF-8") from error
    elif isinstance(line, str):
        if len(line.encode("utf-8")) > max_bytes:
            raise ProtocolError("worker response exceeds the message limit")
        text = line
    else:
        raise ProtocolError("worker response must be bytes or text")
    try:
        value = json.loads(text)
    except json.JSONDecodeError as error:
        raise ProtocolError(
            f"worker response is not valid JSON: {text[:200]!r}"
        ) from error
    if not isinstance(value, dict):
        raise ProtocolError("worker response must be a JSON object")
    version = value.get("protocolVersion")
    if version is not None and version != PROTOCOL_VERSION:
        raise ProtocolError(f"unsupported worker protocol version: {version!r}")
    return value
