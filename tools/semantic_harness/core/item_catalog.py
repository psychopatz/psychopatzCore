"""Bounded read-only item catalog sourced from installed PZ item scripts."""

from __future__ import annotations

import os
from pathlib import Path
import re
import threading
from typing import Any, Iterable


_MODULE = re.compile(r"^\s*module\s+([\w.-]+)", re.ASCII)
_ITEM = re.compile(r"^\s*item\s+([\w.-]+)(?:\s|$)", re.ASCII)
_DISPLAY_NAME = re.compile(r"^\s*DisplayName\s*=\s*(.*?)\s*,?\s*$", re.ASCII)
_CACHE: dict[str, tuple[dict[str, str], ...]] = {}
_CACHE_LOCK = threading.Lock()
MAX_SCRIPT_FILES = 5000
MAX_SCRIPT_BYTES = 160_000_000
MAX_ITEM_DEFINITIONS = 100_000
MAX_SEARCH_RESULTS = 100


def _steam_library_roots() -> list[Path]:
    home = Path.home()
    roots = [
        home / ".steam" / "steam",
        home / ".steam" / "debian-installation",
        home / ".local" / "share" / "Steam",
        home / "Steam",
    ]
    libraries: list[Path] = []
    for root in roots:
        libraries.append(root)
        steamapps = root / "steamapps"
        vdf = steamapps / "libraryfolders.vdf"
        try:
            content = vdf.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for raw_path in re.findall(r'"path"\s*"([^"]+)"', content):
            libraries.append(Path(raw_path.replace("\\\\", "\\")))
    return libraries


def discover_item_script_roots() -> list[Path]:
    """Find installed `media/scripts` roots without assuming one Steam path."""

    candidates: list[Path] = []
    for key in (
        "PZ_ITEM_SCRIPTS_DIR",
        "PZ_GAME_DIR",
        "PROJECT_ZOMBOID_DIR",
        "PROJECTZOMBOID_DIR",
    ):
        value = os.environ.get(key)
        if value:
            candidates.append(Path(value).expanduser())
    for library in _steam_library_roots():
        common = library / "steamapps" / "common"
        candidates.extend(
            (
                common / "ProjectZomboid",
                common / "projectzomboid",
                library / "ProjectZomboid",
                library / "projectzomboid",
            )
        )

    roots: list[Path] = []
    seen: set[str] = set()
    for candidate in candidates:
        options = (
            candidate,
            candidate / "media" / "scripts",
            candidate / "projectzomboid" / "media" / "scripts",
            candidate / "ProjectZomboid" / "media" / "scripts",
        )
        for option in options:
            if option.name != "scripts" or option.parent.name != "media":
                continue
            if not option.is_dir():
                continue
            resolved = str(option.resolve())
            if resolved not in seen:
                seen.add(resolved)
                roots.append(Path(resolved))
    return roots


def _strip_comments(line: str, in_block_comment: bool) -> tuple[str, bool]:
    output: list[str] = []
    quote: str | None = None
    escaped = False
    index = 0
    while index < len(line):
        if in_block_comment:
            end = line.find("*/", index)
            if end < 0:
                return "".join(output), True
            index = end + 2
            in_block_comment = False
            continue
        char = line[index]
        next_two = line[index : index + 2]
        if quote:
            output.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue
        if char in {'"', "'"}:
            quote = char
            output.append(char)
            index += 1
            continue
        if next_two == "//":
            break
        if next_two == "/*":
            in_block_comment = True
            index += 2
            continue
        output.append(char)
        index += 1
    return "".join(output), in_block_comment


def _brace_delta(line: str) -> int:
    delta = 0
    quote: str | None = None
    escaped = False
    for char in line:
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in {'"', "'"}:
            quote = char
        elif char == "{":
            delta += 1
        elif char == "}":
            delta -= 1
    return delta


def _display_name(value: str) -> str:
    value = value.strip().rstrip(",").strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        value = value[1:-1]
    return value


def _parse_script_text(content: str) -> list[dict[str, str]]:
    records: dict[str, dict[str, str]] = {}
    module: str | None = None
    depth = 0
    in_block_comment = False
    current_type: str | None = None

    for raw_line in content.splitlines():
        line, in_block_comment = _strip_comments(raw_line, in_block_comment)
        module_match = _MODULE.match(line) if module is None else None
        if module_match:
            module = module_match.group(1)
            depth = 0
            line = line[module_match.end() :]
        if module is None:
            continue

        item_match = _ITEM.match(line) if depth == 1 else None
        if item_match:
            full_type = f"{module}.{item_match.group(1)}"
            current_type = full_type
            records[full_type] = {
                "fullType": full_type,
                "displayName": item_match.group(1),
            }

        if current_type is not None and depth >= 1:
            display_match = _DISPLAY_NAME.match(line)
            if display_match:
                display_name = _display_name(display_match.group(1))
                if display_name:
                    records[current_type]["displayName"] = display_name

        previous_depth = depth
        delta = _brace_delta(line)
        depth += delta
        if current_type is not None and previous_depth >= 2 and depth < 2:
            current_type = None
        has_brace = "{" in line or "}" in line
        if depth <= 0 and has_brace:
            module = None
            depth = 0
            current_type = None

    return list(records.values())


def _load_script_items(root: Path) -> tuple[dict[str, str], ...]:
    key = str(root.resolve())
    with _CACHE_LOCK:
        cached = _CACHE.get(key)
        if cached is not None:
            return cached

        output: dict[str, dict[str, str]] = {}
        files = sorted(root.rglob("*.txt"))[:MAX_SCRIPT_FILES]
        bytes_read = 0
        for path in files:
            try:
                size = path.stat().st_size
                if size <= 0 or size > 8_000_000:
                    continue
                if bytes_read + size > MAX_SCRIPT_BYTES:
                    break
                content = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            bytes_read += size
            for item in _parse_script_text(content):
                output[item["fullType"]] = item
                if len(output) >= MAX_ITEM_DEFINITIONS:
                    break
            if len(output) >= MAX_ITEM_DEFINITIONS:
                break

        cached = tuple(
            output[key]
            for key in sorted(output, key=str.casefold)
        )
        _CACHE[key] = cached
        return cached


def _existing_items(scenario: dict[str, Any]) -> Iterable[dict[str, Any]]:
    for owner_name in ("player", "npc"):
        owner = scenario.get(owner_name, {})
        if not isinstance(owner, dict):
            continue
        inventory = owner.get("inventory", {})
        if not isinstance(inventory, dict):
            continue
        items = inventory.get("items", {})
        if isinstance(items, dict):
            source = items.values()
        elif isinstance(items, list):
            source = items
        else:
            continue
        for item in source:
            if not isinstance(item, dict):
                continue
            full_type = str(item.get("fullType") or item.get("type") or "")
            if full_type:
                yield {
                    "fullType": full_type,
                    "displayName": str(
                        item.get("displayName") or item.get("customName") or full_type
                    ),
                }


def search_item_catalog(
    query: str = "",
    limit: int = 50,
    scenario: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Search the installed game's item definitions and current scenario items."""

    query = str(query or "").strip()[:128]
    normalized = query.casefold()
    limit = max(1, min(int(limit), MAX_SEARCH_RESULTS))
    roots = discover_item_script_roots()
    items: dict[str, dict[str, str]] = {}
    for root in roots:
        for item in _load_script_items(root):
            items[item["fullType"]] = item
    for item in _existing_items(scenario or {}):
        items.setdefault(item["fullType"], item)

    matches = [
        {
            "fullType": item["fullType"],
            "displayName": item.get("displayName") or item["fullType"],
        }
        for item in items.values()
        if not normalized
        or normalized in item["fullType"].casefold()
        or normalized in item.get("displayName", "").casefold()
    ]
    matches.sort(key=lambda item: (item["displayName"].casefold(), item["fullType"].casefold()))
    return {
        "schema": "semantic.item.catalog.v1",
        "schemaVersion": 1,
        "source": "Project Zomboid media/scripts",
        "sourceAvailable": bool(roots),
        "query": query,
        "totalMatches": len(matches),
        "hasMore": len(matches) > limit,
        "results": matches[:limit],
    }


def item_type_registry_fixture() -> dict[str, Any]:
    """Return the installed PZ item-type order as an engine fixture.

    PsychopatzCore persists item type IDs as a compact numeric registry.  The
    detached worker has no Java ScriptManager, so the installed game's script
    catalog is transported as an engine fixture.  The current save format is
    zero-based for this registry; the first sorted type is therefore omitted
    from the one-based Lua table passed to ``Registry.load``.
    """

    values: dict[str, dict[str, str]] = {}
    for root in discover_item_script_roots():
        for item in _load_script_items(root):
            values[item["fullType"]] = item
    full_types = sorted(values, key=str.casefold)
    return {
        "schema": "semantic.engine.item_type_registry.v1",
        "source": "Project Zomboid media/scripts",
        "sourceAvailable": bool(full_types),
        "idBase": 0,
        "types": full_types[1:] if full_types else [],
        "typeCount": len(full_types),
    }
