"""Audit Conversation text catalog IDs without modifying source or runtime files."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path, PurePosixPath
from typing import Any

from conversation_text_catalog import _load_catalogs


DEFAULT_MANIFEST = (
    Path(__file__).resolve().parent
    / "sources"
    / "conversation"
    / "text"
    / "manifest.json"
)


def _parts(value: str) -> tuple[str, ...]:
    path = PurePosixPath(value)
    if path.suffix == ".json":
        path = path.with_suffix("")
    return tuple(path.parts)


def _target_base(target: str) -> str:
    return "conversation." + ".".join(_parts(target))


def _source_suffix(source_path: str, target: str) -> str:
    source_parts = _parts(source_path)
    target_parts = _parts(target)
    common = 0
    for source_part, target_part in zip(source_parts, target_parts):
        if source_part != target_part:
            break
        common += 1
    suffix = source_parts[common:]
    if not suffix:
        suffix = source_parts[-1:]
    return ".".join(suffix)


def _has_adjacent_repetition(catalog_id: str) -> bool:
    pieces = catalog_id.split(".")
    return any(left == right for left, right in zip(pieces, pieces[1:]))


def _load_rows(manifest_path: Path) -> list[dict[str, Any]]:
    catalogs = _load_catalogs(manifest_path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    source_by_catalog: dict[str, str] = {}
    for declaration in manifest["sources"]:
        source_path = manifest_path.parent / Path(
            *PurePosixPath(declaration["path"]).parts
        )
        source = json.loads(source_path.read_text(encoding="utf-8"))
        for catalog in source["catalogs"]:
            source_by_catalog[catalog["catalogId"]] = declaration["path"]

    target_counts = Counter(str(catalog["target"]) for catalog in catalogs)
    rows: list[dict[str, Any]] = []
    for catalog in catalogs:
        catalog_id = str(catalog["catalogId"])
        target = str(catalog["target"])
        source_path = source_by_catalog[catalog_id]
        canonical_id = _target_base(target)
        if target_counts[target] > 1:
            canonical_id += "." + _source_suffix(source_path, target)
        findings: list[str] = []
        if catalog_id.startswith("conversation.text."):
            findings.append("redundant_prefix")
        if _has_adjacent_repetition(catalog_id):
            findings.append("repeated_segment")
        if catalog_id != canonical_id:
            findings.append("canonical_mismatch")
        rows.append(
            {
                "owner": catalog["owner"],
                "source": source_path,
                "catalogId": catalog_id,
                "target": target,
                "entries": len(catalog.get("entries") or []),
                "canonicalId": canonical_id,
                "findings": findings,
            }
        )

    canonical_counts = Counter(row["canonicalId"] for row in rows)
    for row in rows:
        if canonical_counts[row["canonicalId"]] > 1:
            row["findings"].append("canonical_collision")
    return rows


def _summary(rows: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "catalogs": len(rows),
        "sources": len({row["source"] for row in rows}),
        "targets": len({row["target"] for row in rows}),
        "owners": dict(sorted(Counter(row["owner"] for row in rows).items())),
        "targetFanIn": dict(
            sorted(
                Counter(row["target"] for row in rows).items(),
                key=lambda item: (-item[1], item[0]),
            )
        ),
        "findings": dict(
            sorted(
                Counter(
                    finding
                    for row in rows
                    for finding in row["findings"]
                ).items()
            )
        ),
    }


def _print_table(rows: list[dict[str, Any]]) -> None:
    headers = ("owner", "source", "catalogId", "target", "canonicalId", "entries", "findings")
    print("\t".join(headers))
    for row in rows:
        values = [
            row["owner"],
            row["source"],
            row["catalogId"],
            row["target"],
            row["canonicalId"],
            str(row["entries"]),
            ",".join(row["findings"]) or "-",
        ]
        print("\t".join(values))


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help="Conversation text manifest to inspect",
    )
    parser.add_argument(
        "--owner",
        help="only list catalogs owned by this package owner",
    )
    parser.add_argument(
        "--format",
        choices=("table", "json"),
        default="table",
        dest="output_format",
    )
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="print only aggregate counts",
    )
    options = parser.parse_args(arguments)
    rows = _load_rows(options.manifest.expanduser().resolve())
    if options.owner:
        rows = [row for row in rows if row["owner"] == options.owner]
    summary = _summary(rows)

    if options.output_format == "json":
        payload: dict[str, Any] = {"summary": summary}
        if not options.summary_only:
            payload["catalogs"] = rows
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        if not options.summary_only:
            _print_table(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
