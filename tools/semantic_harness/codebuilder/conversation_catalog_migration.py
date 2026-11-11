"""One-shot conversion from inline Conversation wording to locale catalogs."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


INLINE_FIELDS = frozenset({
    "translations", "labelTranslations", "choiceTranslations",
    "fallback", "labelFallback", "utteranceFallback",
})


def strip_inline_translations(value: Any) -> tuple[Any, int]:
    """Return a JSON value without inline locale wording and the removal count."""

    if isinstance(value, dict):
        result: dict[str, Any] = {}
        removed = 0
        for key, child in value.items():
            if key in INLINE_FIELDS:
                removed += 1
                continue
            normalized, child_removed = strip_inline_translations(child)
            result[key] = normalized
            removed += child_removed
        return result, removed
    if isinstance(value, list):
        result = []
        removed = 0
        for child in value:
            normalized, child_removed = strip_inline_translations(child)
            result.append(normalized)
            removed += child_removed
        return result, removed
    return value, 0


def migrate_tree(root: str | Path, *, apply: bool = False) -> dict[str, Any]:
    """Audit or migrate semantic JSON below one source root."""

    source_root = Path(root).expanduser().resolve()
    changed: list[dict[str, Any]] = []
    for path in sorted(source_root.rglob("*.json")):
        relative = path.relative_to(source_root)
        if path.name == "manifest.json" or "translations" in relative.parts:
            continue
        document = json.loads(path.read_text(encoding="utf-8"))
        normalized, removed = strip_inline_translations(document)
        if not removed:
            continue
        if apply:
            path.write_text(
                json.dumps(normalized, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        changed.append({"path": relative.as_posix(), "removedFields": removed})
    return {
        "root": str(source_root),
        "apply": apply,
        "changedFileCount": len(changed),
        "removedFieldCount": sum(item["removedFields"] for item in changed),
        "files": changed,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--apply", action="store_true")
    options = parser.parse_args(argv)
    print(json.dumps(migrate_tree(options.root, apply=options.apply), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
