"""Protocol-v1 request and response models."""

from __future__ import annotations

from dataclasses import dataclass, field
import time
import uuid
from typing import Any, Mapping, Optional

from .errors import BridgeProtocolError, ERROR_CODES

PROTOCOL_VERSION = 1
MAX_REQUEST_ID = 64
MAX_NAME = 96


def _valid_identifier(value: str, *, dotted: bool) -> bool:
    if not value or len(value) > MAX_NAME:
        return False
    allowed = set("abcdefghijklmnopqrstuvwxyz0123456789_-" + ("." if dotted else ""))
    return all(character in allowed for character in value.casefold()) and \
        (not dotted or all(part for part in value.split(".")))


@dataclass(frozen=True)
class BridgeRequest:
    namespace: str
    command: str
    arguments: Mapping[str, Any] = field(default_factory=dict)
    target_runtime_id: Optional[str] = None
    request_id: str = field(default_factory=lambda: uuid.uuid4().hex)
    created_at: int = field(default_factory=lambda: int(time.time() * 1000))
    protocol_version: int = PROTOCOL_VERSION
    message_type: str = "request"

    def validate(self) -> None:
        if self.protocol_version != PROTOCOL_VERSION:
            raise BridgeProtocolError("unsupported protocol version")
        if not (8 <= len(self.request_id) <= MAX_REQUEST_ID) or not _valid_identifier(self.request_id, dotted=False):
            raise BridgeProtocolError("invalid request ID")
        if not _valid_identifier(self.namespace, dotted=True):
            raise BridgeProtocolError("invalid namespace")
        if not _valid_identifier(self.command, dotted=False):
            raise BridgeProtocolError("invalid command")
        if not isinstance(self.arguments, Mapping):
            raise BridgeProtocolError("arguments must be an object")
        if self.target_runtime_id is not None and (not isinstance(self.target_runtime_id, str)
                                                   or not self.target_runtime_id
                                                   or len(self.target_runtime_id) > 128):
            raise BridgeProtocolError("invalid target runtime ID")

    def to_dict(self) -> dict[str, Any]:
        self.validate()
        return {
            "message_type": self.message_type, "protocol_version": self.protocol_version,
            "request_id": self.request_id, "target_runtime_id": self.target_runtime_id,
            "namespace": self.namespace, "command": self.command,
            "arguments": dict(self.arguments), "created_at": self.created_at,
        }


@dataclass(frozen=True)
class BridgeResponse:
    request_id: str
    status: str
    runtime_id: Optional[str]
    result: Optional[Mapping[str, Any]] = None
    error: Optional[Mapping[str, Any]] = None
    protocol_version: int = PROTOCOL_VERSION
    message_type: str = "response"

    @classmethod
    def from_dict(cls, value: Any) -> "BridgeResponse":
        if not isinstance(value, dict):
            raise BridgeProtocolError("response must be an object")
        if value.get("message_type", "response") != "response":
            raise BridgeProtocolError("unexpected message type")
        if value.get("protocol_version") != PROTOCOL_VERSION:
            raise BridgeProtocolError("unsupported response protocol")
        request_id = value.get("request_id")
        if not isinstance(request_id, str) or not (8 <= len(request_id) <= MAX_REQUEST_ID):
            raise BridgeProtocolError("invalid response request ID")
        status = value.get("status")
        if status not in {"ok", "error"}:
            raise BridgeProtocolError("invalid response status")
        error = value.get("error")
        if status == "error":
            if not isinstance(error, dict) or error.get("code") not in ERROR_CODES:
                raise BridgeProtocolError("invalid response error")
        result = value.get("result")
        if result is not None and not isinstance(result, dict):
            raise BridgeProtocolError("response result must be an object")
        return cls(request_id=request_id, status=status,
                   runtime_id=value.get("runtime_id"), result=result, error=error)
