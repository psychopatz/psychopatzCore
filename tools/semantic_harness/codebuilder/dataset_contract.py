"""Provider-neutral typed dataset document validation."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from .errors import CompileError


DATASET_UTTERANCE = re.compile(r"^[a-z0-9']+(?: [a-z0-9']+)*$")


def load_dataset_document(
    path: str | Path,
    *,
    label: str = "dataset",
) -> dict[str, Any]:
    """Load one bounded JSON object used as a compiler input."""
    document_path = Path(path)
    try:
        document = json.loads(document_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(
            f"cannot read {label} {document_path}: {error}"
        ) from error
    if not isinstance(document, dict):
        raise CompileError(f"{label} root must be an object")
    return document


def normalize_utterance(
    value: Any,
    *,
    max_tokens: int = 16,
    label: str = "dataset pattern utterance",
    invalid_label: str = "dataset utterance",
) -> tuple[str, tuple[str, ...]]:
    """Normalize one bounded utterance without assigning semantic meaning."""
    if not isinstance(value, str):
        raise CompileError(f"{label} must be a string")
    text = value.lower()
    text = re.sub(r"[\x00-\x1f\x7f]", " ", text)
    text = re.sub(r'[, .!?;:()\[\]{}"]', " ", text)
    normalized = re.sub(r"\s+", " ", text).strip()
    if not normalized or not DATASET_UTTERANCE.fullmatch(normalized):
        raise CompileError(
            f"{invalid_label} is empty or unsupported after normalization: {value!r}"
        )
    tokens = tuple(normalized.split(" "))
    if len(tokens) > max_tokens:
        raise CompileError(f"{invalid_label} is too long: {value!r}")
    return normalized, tokens


def validate_source_metadata(
    value: Any,
    *,
    label: str = "dataset",
    max_references: int = 8,
    source_label: str | None = None,
    reference_label: str | None = None,
) -> dict[str, Any]:
    """Validate bounded provenance metadata without owning a corpus policy."""
    source_label = source_label or f"{label} source"
    reference_label = reference_label or f"{label} reference"
    if not isinstance(value, dict):
        raise CompileError(f"{label} requires source metadata")
    name = value.get("name")
    version = value.get("version")
    content_license = value.get("contentLicense")
    references = value.get("references")
    if not all(
        isinstance(item, str) and item.strip()
        for item in (name, version, content_license)
    ):
        raise CompileError(
            f"{source_label} requires non-empty name, version, and contentLicense"
        )
    if len(name) > 128 or len(version) > 32 or len(content_license) > 128:
        raise CompileError(f"{source_label} metadata exceeds its length limit")
    if (
        not isinstance(references, list)
        or not references
        or len(references) > max_references
    ):
        raise CompileError(
            f"{label} requires 1 to {max_references} dataset references"
        )
    normalized_references = []
    for reference in references:
        if not isinstance(reference, dict):
            raise CompileError(f"{label} references must be objects")
        reference_name = reference.get("name")
        url = reference.get("url")
        use = reference.get("use")
        license_name = reference.get("license")
        reviewed_on = reference.get("reviewedOn")
        if not all(
            isinstance(item, str) and item.strip()
            for item in (
                reference_name,
                url,
                use,
                license_name,
                reviewed_on,
            )
        ):
            raise CompileError(
                f"each {reference_label} requires name, url, use, license, and reviewedOn"
            )
        if (
            len(reference_name) > 128
            or len(url) > 512
            or len(use) > 256
            or len(license_name) > 128
            or len(reviewed_on) > 32
        ):
            raise CompileError(f"{label} reference exceeds its length limit")
        normalized_references.append({
            "name": reference_name.strip(),
            "url": url.strip(),
            "use": use.strip(),
            "license": license_name.strip(),
            "reviewedOn": reviewed_on.strip(),
        })
    return {
        "name": name.strip(),
        "version": version.strip(),
        "contentLicense": content_license.strip(),
        "references": normalized_references,
    }


__all__ = [
    "DATASET_UTTERANCE",
    "load_dataset_document",
    "normalize_utterance",
    "validate_source_metadata",
]
