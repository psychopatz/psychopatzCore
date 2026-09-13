from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class ModProfile:
    """A Workshop item profile discovered from, or saved for, a mod folder."""

    key: str
    name: str
    mod_root: Path
    appid: int = 108600
    workshopid: int | None = None
    content_path: Path | None = None
    preview_path: Path | None = None
    title: str = ""
    description: str = ""
    visibility: int = 2
    tags: list[str] = field(default_factory=list)

    def as_dict(self) -> dict[str, Any]:
        return {
            "key": self.key,
            "name": self.name,
            "mod_root": str(self.mod_root),
            "appid": self.appid,
            "workshopid": self.workshopid,
            "content_path": str(self.content_path) if self.content_path else "",
            "preview_path": str(self.preview_path) if self.preview_path else "",
            "title": self.title,
            "description": self.description,
            "visibility": self.visibility,
            "tags": list(self.tags),
        }


@dataclass
class UpdateSelection:
    """The fields the user explicitly selected for a Workshop update."""

    content: bool = True
    preview: bool = True
    title: bool = True
    description: bool = True
    tags: bool = True
    visibility: bool = True
    change_note: str = ""

    @property
    def fields(self) -> list[str]:
        values: list[str] = []
        for name in ("content", "preview", "title", "description", "tags", "visibility"):
            if getattr(self, name):
                values.append(name)
        return values

    @property
    def is_full_update(self) -> bool:
        return len(self.fields) == 6


@dataclass
class ValidationResult:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.errors


@dataclass
class BackendResult:
    exit_code: int
    started: bool
    message: str = ""
