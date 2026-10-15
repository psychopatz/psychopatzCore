"""Stable, machine-readable Asset Harness failures."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Mapping, Sequence


@dataclass
class Diagnostic:
    code: str
    severity: str = "error"
    message: str = ""
    asset: str | None = None
    rect: list[int] | None = None
    path: str | None = None
    remediation: str | None = None

    def as_dict(self) -> dict[str, Any]:
        result: dict[str, Any] = {
            "code": self.code,
            "severity": self.severity,
            "message": self.message,
        }
        for key, value in (
            ("asset", self.asset),
            ("rect", self.rect),
            ("path", self.path),
            ("remediation", self.remediation),
        ):
            if value is not None:
                result[key] = value
        return result


class AssetHarnessError(Exception):
    """An expected failure that can be returned without a traceback."""

    def __init__(
        self,
        code: str,
        message: str,
        *,
        diagnostics: Sequence[Mapping[str, Any]] | None = None,
        exit_code: int = 1,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.diagnostics = [dict(item) for item in (diagnostics or ())]
        self.exit_code = exit_code


def diagnostic(
    code: str,
    message: str,
    *,
    severity: str = "error",
    asset: str | None = None,
    rect: Sequence[int] | None = None,
    path: str | None = None,
    remediation: str | None = None,
) -> dict[str, Any]:
    return Diagnostic(
        code=code,
        severity=severity,
        message=message,
        asset=asset,
        rect=list(rect) if rect is not None else None,
        path=path,
        remediation=remediation,
    ).as_dict()


def raise_error(code: str, message: str, **kwargs: Any) -> None:
    raise AssetHarnessError(code, message, **kwargs)
