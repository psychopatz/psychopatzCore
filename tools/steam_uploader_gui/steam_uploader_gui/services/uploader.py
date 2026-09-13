from __future__ import annotations

import json
import os
import subprocess
import tempfile
from pathlib import Path

from ..core.limits import (
    MAX_CHANGE_NOTE_LENGTH,
    MAX_DESCRIPTION_LENGTH,
    MAX_PRIMARY_PREVIEW_BYTES,
    MAX_TAG_LENGTH,
    MAX_TITLE_LENGTH,
)
from ..core.models import BackendResult, ModProfile, UpdateSelection, ValidationResult
from .logging import EventLogger


class BackendError(RuntimeError):
    pass


class SelectiveBackendUnavailable(BackendError):
    pass


def image_kind(path: Path) -> str | None:
    try:
        header = path.read_bytes()[:12]
    except OSError:
        return None
    if header.startswith((b"GIF87a", b"GIF89a")):
        return "GIF"
    if header.startswith(b"\x89PNG\r\n\x1a\n"):
        return "PNG"
    if header[:3] == b"\xff\xd8\xff":
        return "JPEG"
    return None


def validate(profile: ModProfile, selection: UpdateSelection) -> ValidationResult:
    result = ValidationResult()
    if profile.appid <= 0:
        result.errors.append("App ID must be a positive integer.")
    if profile.workshopid is None or profile.workshopid <= 0:
        result.errors.append("Workshop ID is required for an existing item update.")

    if selection.content:
        if not profile.content_path or not profile.content_path.is_dir():
            result.errors.append("Selected content path does not exist or is not a directory.")
    if selection.preview:
        if not profile.preview_path or not profile.preview_path.is_file():
            result.errors.append("Selected preview path does not exist or is not a file.")
        elif profile.preview_path.stat().st_size >= MAX_PRIMARY_PREVIEW_BYTES:
            result.errors.append(
                f"Primary preview must be under {MAX_PRIMARY_PREVIEW_BYTES:,} bytes "
                f"({profile.preview_path.stat().st_size:,} bytes selected)."
            )
        elif image_kind(profile.preview_path) is None:
            result.errors.append("Primary preview is not recognized as GIF, PNG, or JPEG data.")
    if selection.title and not profile.title.strip():
        result.errors.append("Title cannot be empty when title updates are selected.")
    if selection.title and len(profile.title) > MAX_TITLE_LENGTH:
        result.errors.append(f"Title must be {MAX_TITLE_LENGTH} characters or fewer.")
    if selection.description and not profile.description.strip():
        result.warnings.append("Description is empty; Steam may reject or clear it.")
    if selection.description and len(profile.description) > MAX_DESCRIPTION_LENGTH:
        result.errors.append(
            f"Description must be {MAX_DESCRIPTION_LENGTH:,} characters or fewer."
        )
    if len(selection.change_note) > MAX_CHANGE_NOTE_LENGTH:
        result.errors.append(
            f"Change note must be {MAX_CHANGE_NOTE_LENGTH:,} characters or fewer."
        )
    if selection.tags:
        for tag in profile.tags:
            if not tag.strip():
                result.errors.append("Tags cannot contain empty values.")
            if len(tag) > MAX_TAG_LENGTH:
                result.errors.append(f"Tag is longer than {MAX_TAG_LENGTH} characters: {tag[:40]!r}.")
            if "'" in tag:
                result.errors.append(f"Tag contains an unsupported apostrophe: {tag!r}.")
    if not selection.fields:
        result.errors.append("Select at least one field to update.")
    return result


def manifest_for(profile: ModProfile) -> dict[str, object]:
    """Build a stock SteamUploader manifest for a full update."""

    if not profile.content_path or not profile.preview_path:
        raise BackendError("A full update requires both content and preview paths.")
    if profile.workshopid is None:
        raise BackendError("A full update requires an existing Workshop ID.")
    return {
        "$schema": "https://raw.githubusercontent.com/SimKDT/Steam-Uploader-rs/refs/heads/main/manifest_schema/mod-manifest-schema.json",
        "appid": profile.appid,
        "workshopid": profile.workshopid,
        "content": str(profile.content_path),
        "preview": str(profile.preview_path),
        "title": profile.title,
        "description": profile.description,
        "visibility": profile.visibility,
        "tags": profile.tags,
    }


def selective_request_for(
    profile: ModProfile,
    selection: UpdateSelection,
) -> dict[str, object]:
    """Build the request consumed by the selective Rust backend."""

    if profile.workshopid is None:
        raise BackendError("A selective update requires an existing Workshop ID.")
    return {
        "appid": profile.appid,
        "workshopid": profile.workshopid,
        "fields": selection.fields,
        "content": str(profile.content_path) if profile.content_path else None,
        "preview": str(profile.preview_path) if profile.preview_path else None,
        "title": profile.title,
        "description": profile.description,
        "visibility": profile.visibility,
        "tags": profile.tags,
        "change_note": selection.change_note,
    }


class StockSteamUploader:
    """Adapter for stock full uploads and the selective Rust update command."""

    def __init__(self, executable: Path, logger: EventLogger):
        self.executable = executable
        self.logger = logger
        self._selective_capability: bool | None = None

    @property
    def selective_available(self) -> bool:
        """Return whether this installed executable exposes the selective command."""

        if self._selective_capability is not None:
            return self._selective_capability
        if not self.executable.is_file():
            self._selective_capability = False
            return False
        try:
            result = subprocess.run(
                [str(self.executable), "update", "--help"],
                cwd=self.executable.parent,
                env=self._environment(),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                timeout=5,
                check=False,
            )
            self._selective_capability = result.returncode == 0 and "--request" in result.stdout
        except (OSError, subprocess.SubprocessError):
            self._selective_capability = False
        return self._selective_capability

    def _environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        if os.name != "nt":
            library_path = str(self.executable.parent)
            existing = environment.get("LD_LIBRARY_PATH", "")
            environment["LD_LIBRARY_PATH"] = library_path + ((":" + existing) if existing else "")
        return environment

    def dry_run(self, profile: ModProfile, selection: UpdateSelection) -> None:
        self.logger.emit(
            "INFO", "plan", "Dry run completed locally; no Steam process was started.",
            mod=profile.name, workshopid=profile.workshopid, fields=selection.fields,
            content=str(profile.content_path) if selection.content else None,
            preview=str(profile.preview_path) if selection.preview else None,
        )

    def upload(self, profile: ModProfile, selection: UpdateSelection) -> BackendResult:
        if not self.executable.is_file():
            raise BackendError(f"SteamUploader executable not found: {self.executable}")
        if not selection.is_full_update and not self.selective_available:
            raise SelectiveBackendUnavailable(
                "The installed SteamUploader backend does not expose selective updates. "
                "Install the selective SteamUploader backend before starting a partial update."
            )

        with tempfile.TemporaryDirectory(prefix="steam-uploader-gui-") as temporary:
            if selection.is_full_update:
                manifest_path = Path(temporary) / "mod-manifest.json"
                manifest_path.write_text(
                    json.dumps(manifest_for(profile), indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8",
                )
                command = [str(self.executable), "upload", "--manifest-path", str(manifest_path)]
                if selection.change_note.strip():
                    command.extend(["--patchnote", selection.change_note.strip()])
            else:
                request_path = Path(temporary) / "update-request.json"
                request_path.write_text(
                    json.dumps(selective_request_for(profile, selection), indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8",
                )
                command = [str(self.executable), "update", "--request", str(request_path)]
            self.logger.emit("INFO", "process", "Starting SteamUploader.", command=command, cwd=str(self.executable.parent))
            process = subprocess.Popen(
                command,
                cwd=self.executable.parent,
                env=self._environment(),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            assert process.stdout is not None
            for line in process.stdout:
                self.logger.emit("INFO", "uploader", line.rstrip("\n"))
            exit_code = process.wait()
            if exit_code == 0:
                self.logger.emit(
                    "INFO", "process",
                    "SteamUploader exited successfully. Its installed version may finish the Steam callback asynchronously.",
                    exit_code=exit_code,
                )
            else:
                self.logger.emit("ERROR", "process", "SteamUploader exited with an error.", exit_code=exit_code)
            return BackendResult(exit_code=exit_code, started=True, message="Process completed.")
