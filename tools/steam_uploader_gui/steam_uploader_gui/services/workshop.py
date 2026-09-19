from __future__ import annotations

import json
import time
import urllib.parse
import urllib.request
import webbrowser
from dataclasses import dataclass
from pathlib import Path

from ..core.discovery import workshop_metadata_from_file, write_workshop_metadata


@dataclass(frozen=True)
class WorkshopItem:
    published_file_id: int
    title: str
    description: str
    tags: list[str]
    visibility: int
    preview_url: str = ""
    file_url: str = ""


@dataclass(frozen=True)
class WorkshopSyncResult:
    item: WorkshopItem
    local_before: dict[str, object]
    local_after: dict[str, object]
    remote: dict[str, object]
    applied_fields: tuple[str, ...] = ()
    conflicts: dict[str, dict[str, object]] | None = None


SYNC_FIELDS = ("title", "description", "tags", "visibility")


_WORKSHOP_CACHE: dict[int, tuple[float, WorkshopItem]] = {}
_WORKSHOP_CACHE_TTL_SECONDS = 30.0


def workshop_url(workshopid: int) -> str:
    return f"https://steamcommunity.com/sharedfiles/filedetails/?id={workshopid}"


def open_workshop_page(workshopid: int) -> None:
    webbrowser.open(workshop_url(workshopid))


def _metadata_values(metadata: dict[str, object]) -> dict[str, object]:
    return {field: metadata.get(field) for field in SYNC_FIELDS}


def _metadata_equal(field: str, left: object, right: object) -> bool:
    if field == "tags":
        return [str(tag).strip() for tag in (left or [])] == [str(tag).strip() for tag in (right or [])]
    return left == right


def _remote_metadata(item: WorkshopItem) -> dict[str, object]:
    return {
        "title": item.title,
        "description": item.description,
        "tags": list(item.tags),
        "visibility": item.visibility,
    }


def sync_workshop_metadata(
    mod_root: Path,
    item: WorkshopItem,
    previous_snapshot: dict[str, object] | None = None,
) -> WorkshopSyncResult:
    """Reconcile Steam metadata into workshop.txt without clobbering local edits."""

    workshop_path = mod_root / "workshop.txt"
    local_document = workshop_metadata_from_file(workshop_path)
    local_before = _metadata_values(local_document)
    remote = _remote_metadata(item)
    previous_local = (previous_snapshot or {}).get("local", {})
    present = set(local_document.get("present", ()))
    updates: dict[str, object] = {}
    conflicts: dict[str, dict[str, object]] = {}

    for field in SYNC_FIELDS:
        local_value = local_before[field]
        remote_value = remote[field]
        if _metadata_equal(field, local_value, remote_value):
            continue

        missing_locally = field not in present or local_value in (None, "", [])
        unchanged_since_last_sync = (
            isinstance(previous_local, dict)
            and field in previous_local
            and _metadata_equal(field, local_value, previous_local[field])
        )
        if missing_locally or unchanged_since_last_sync:
            updates[field] = remote_value
        else:
            conflicts[field] = {"local": local_value, "steam": remote_value}

    applied_fields: tuple[str, ...] = ()
    if updates:
        write_workshop_metadata(workshop_path, updates)
        applied_fields = tuple(field for field in SYNC_FIELDS if field in updates)

    local_after = _metadata_values(workshop_metadata_from_file(workshop_path))
    return WorkshopSyncResult(
        item=item,
        local_before=local_before,
        local_after=local_after,
        remote=remote,
        applied_fields=applied_fields,
        conflicts=conflicts,
    )


def fetch_workshop_item(workshopid: int) -> WorkshopItem:
    """Fetch public Workshop metadata without mutating the local profile."""

    cached = _WORKSHOP_CACHE.get(workshopid)
    if cached and time.monotonic() - cached[0] < _WORKSHOP_CACHE_TTL_SECONDS:
        return cached[1]

    payload = urllib.parse.urlencode(
        {"itemcount": "1", "publishedfileids[0]": str(workshopid)}
    ).encode("ascii")
    request = urllib.request.Request(
        "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/",
        data=payload,
        headers={"User-Agent": "SteamUploaderGUI/0.1"},
    )
    with urllib.request.urlopen(request, timeout=6) as response:
        document = json.loads(response.read().decode("utf-8"))

    entries = document.get("response", {}).get("publishedfiledetails", [])
    if not entries:
        raise RuntimeError("Steam returned no Workshop item for that ID.")
    entry = entries[0]
    if int(entry.get("result", 0)) != 1:
        raise RuntimeError(f"Steam could not read Workshop item {workshopid} (result {entry.get('result')}).")
    item = WorkshopItem(
        published_file_id=int(entry.get("publishedfileid", workshopid)),
        title=str(entry.get("title", "")),
        description=str(entry.get("description", "")),
        tags=[str(tag.get("tag", "")) for tag in entry.get("tags", []) if tag.get("tag")],
        visibility=int(entry.get("visibility", 2)),
        preview_url=str(entry.get("preview_url", "")),
        file_url=str(entry.get("file_url", "")),
    )
    _WORKSHOP_CACHE[workshopid] = (time.monotonic(), item)
    return item
