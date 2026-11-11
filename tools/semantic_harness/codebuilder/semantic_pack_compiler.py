"""Validation for static, provider-neutral semantic-pack source shards."""

from __future__ import annotations

import copy
import re
from typing import Any


_ID = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_PACK_ID = re.compile(r"^[A-Za-z][A-Za-z0-9_.:-]{0,127}$")


class SemanticPackCompileError(ValueError):
    """Raised when a semantic-pack shard cannot be generated safely."""


def _require_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not _ID.fullmatch(value):
        raise SemanticPackCompileError(
            f"{label} must be a bounded canonical semantic-pack ID"
        )
    return value


def _require_list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise SemanticPackCompileError(f"{label} must be a list")
    return value


def _require_pack_id(value: Any, label: str) -> str:
    if not isinstance(value, str) or not _PACK_ID.fullmatch(value):
        raise SemanticPackCompileError(
            f"{label} must be a bounded semantic-pack ID"
        )
    return value


def _validate_id_records(
    records: Any,
    label: str,
    *,
    require_aliases: bool = False,
) -> list[dict[str, Any]]:
    output: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, raw in enumerate(_require_list(records, label)):
        item_label = f"{label}[{index}]"
        if not isinstance(raw, dict):
            raise SemanticPackCompileError(f"{item_label} must be an object")
        item = copy.deepcopy(raw)
        item_id = _require_id(item.get("id"), f"{item_label}.id")
        if item_id in seen:
            raise SemanticPackCompileError(
                f"duplicate semantic-pack record ID: {item_id}"
            )
        seen.add(item_id)
        if require_aliases:
            aliases = item.get("aliases")
            if not isinstance(aliases, list) or not aliases:
                raise SemanticPackCompileError(
                    f"{item_label}.aliases must be a non-empty list"
                )
            if any(not isinstance(alias, str) or not alias.strip() for alias in aliases):
                raise SemanticPackCompileError(
                    f"{item_label}.aliases must contain non-empty strings"
                )
        output.append(item)
    return output


def compile_semantic_pack_shard(
    document: dict[str, Any],
    path: str,
) -> dict[str, Any]:
    """Validate static pack data while leaving runtime callbacks to adopters."""
    if document.get("schema") != "pnc.conversation.shard.v1":
        raise SemanticPackCompileError(
            f"Conversation pack shard {path} requires schema pnc.conversation.shard.v1"
        )
    if document.get("kind") != "packs":
        raise SemanticPackCompileError(
            f"Conversation pack shard {path} must declare kind packs"
        )
    source = document.get("source")
    if not isinstance(source, dict):
        raise SemanticPackCompileError(
            f"Conversation pack shard {path} requires source metadata"
        )
    packs: list[dict[str, Any]] = []
    seen_packs: set[str] = set()
    for index, raw in enumerate(_require_list(document.get("packs"), "packs")):
        label = f"packs[{index}]"
        if not isinstance(raw, dict):
            raise SemanticPackCompileError(f"{label} must be an object")
        pack = copy.deepcopy(raw)
        pack_id = _require_pack_id(pack.get("id"), f"{label}.id")
        if pack_id in seen_packs:
            raise SemanticPackCompileError(f"duplicate semantic-pack ID: {pack_id}")
        seen_packs.add(pack_id)
        version = pack.get("version", 1)
        if isinstance(version, bool) or not isinstance(version, int) or version < 1:
            raise SemanticPackCompileError(f"{label}.version must be a positive integer")
        pack["concepts"] = _validate_id_records(
            pack.get("concepts", []), f"{label}.concepts", require_aliases=True
        )
        pack["speechActs"] = _validate_id_records(
            pack.get("speechActs", []), f"{label}.speechActs"
        )
        patterns = _validate_id_records(pack.get("patterns", []), f"{label}.patterns")
        for pattern_index, pattern in enumerate(patterns):
            pattern_label = f"{label}.patterns[{pattern_index}]"
            if not isinstance(pattern.get("match"), list) or not pattern["match"]:
                raise SemanticPackCompileError(
                    f"{pattern_label}.match must be a non-empty list"
                )
            if not isinstance(pattern.get("emit"), dict):
                raise SemanticPackCompileError(
                    f"{pattern_label}.emit must be an object"
                )
        pack["patterns"] = patterns
        for field in ("actionProviders", "dialogueBlocks"):
            value = pack.get(field)
            if value is not None and not isinstance(value, (list, dict)):
                raise SemanticPackCompileError(f"{label}.{field} must be a list or object")
        packs.append(pack)
    return {"packs": packs, "source": copy.deepcopy(source)}
