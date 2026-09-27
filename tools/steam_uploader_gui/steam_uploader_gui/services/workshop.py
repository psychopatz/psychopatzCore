from __future__ import annotations

import json
import time
import urllib.parse
import urllib.request
import webbrowser
from dataclasses import dataclass
from pathlib import Path

from ..core.discovery import (
    resolve_workshop_identity,
    workshop_metadata_from_file,
    write_workshop_metadata,
)


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


@dataclass(frozen=True)
class WorkshopFetchResult:
    item: WorkshopItem
    requested_workshopid: int
    identity_source: str = ""
    identity_repair: str = ""


class WorkshopItemLookupError(RuntimeError):
    def __init__(self, workshopid: int, result: int):
        self.workshopid = workshopid
        self.result = result
        super().__init__(
            f"Steam could not read Workshop item {workshopid} (result {result})."
        )


class WorkshopIdentityRecoveryError(WorkshopItemLookupError):
    def __init__(self, original: WorkshopItemLookupError, detail: str):
        self.workshopid = original.workshopid
        self.result = original.result
        RuntimeError.__init__(
            self,
            f"{original} Automatic Workshop ID recovery stopped: {detail}",
        )


SYNC_FIELDS = ("title", "description", "tags", "visibility")
WORKSHOP_LOOKUP_NOT_FOUND_RESULT = 9


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
    if field == "description":
        normalize = lambda value: str(value or "").replace("\r\n", "\n").replace("\r", "\n")
        return normalize(left) == normalize(right)
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
    """Make the latest Steam metadata authoritative in workshop.txt."""

    workshop_path = mod_root / "workshop.txt"
    local_document = workshop_metadata_from_file(workshop_path)
    local_before = _metadata_values(local_document)
    remote = _remote_metadata(item)
    present = set(local_document.get("present", ()))
    updates = {
        field: remote[field]
        for field in SYNC_FIELDS
        if field not in present or not _metadata_equal(field, local_before[field], remote[field])
    }

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
        conflicts={},
    )


def fetch_workshop_item(workshopid: int, *, force_refresh: bool = False) -> WorkshopItem:
    """Fetch public Workshop metadata without mutating the local profile."""

    cached = _WORKSHOP_CACHE.get(workshopid)
    if (
        not force_refresh
        and cached
        and time.monotonic() - cached[0] < _WORKSHOP_CACHE_TTL_SECONDS
    ):
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
    try:
        result = int(entry.get("result", 0))
    except (TypeError, ValueError) as exc:
        raise RuntimeError("Steam returned an invalid Workshop lookup result.") from exc
    if result != 1:
        raise WorkshopItemLookupError(workshopid, result)
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


def fetch_workshop_item_with_identity_repair(
    workshopid: int,
    mod_root: Path,
    *,
    force_refresh: bool = False,
) -> WorkshopFetchResult:
    """Fetch an item, retrying a not-found ID only from local Workshop ID sources."""

    lookup_error: WorkshopItemLookupError | None = None
    try:
        item = (
            fetch_workshop_item(workshopid, force_refresh=True)
            if force_refresh
            else fetch_workshop_item(workshopid)
        )
        return WorkshopFetchResult(item, workshopid)
    except WorkshopItemLookupError as exc:
        if exc.result != WORKSHOP_LOOKUP_NOT_FOUND_RESULT:
            raise
        lookup_error = exc

    assert lookup_error is not None

    candidate, source, conflicts, _repairs = resolve_workshop_identity(
        mod_root,
        cached_workshopid=workshopid,
        auto_repair=False,
    )
    if conflicts:
        raise WorkshopIdentityRecoveryError(
            lookup_error,
            "local Workshop ID sources disagree: " + " | ".join(conflicts),
        ) from lookup_error
    if candidate is None or candidate <= 0 or candidate == workshopid:
        raise WorkshopIdentityRecoveryError(
            lookup_error,
            "no different ID is recorded in workshop.txt or workshop_update.vdf; "
            "a Mod ID cannot be used as a Workshop ID.",
        ) from lookup_error

    try:
        item = (
            fetch_workshop_item(candidate, force_refresh=True)
            if force_refresh
            else fetch_workshop_item(candidate)
        )
    except Exception as retry_error:
        raise WorkshopIdentityRecoveryError(
            lookup_error,
            f"the local ID {candidate} from {source} could not be verified: {retry_error}",
        ) from retry_error

    verified_id, verified_source, verified_conflicts, _ = resolve_workshop_identity(
        mod_root,
        cached_workshopid=workshopid,
        auto_repair=False,
    )
    if verified_conflicts or verified_id != candidate:
        detail = "local Workshop ID sources changed while the replacement ID was being checked."
        if verified_conflicts:
            detail = "local Workshop ID sources now disagree: " + " | ".join(verified_conflicts)
        raise WorkshopIdentityRecoveryError(lookup_error, detail) from lookup_error

    # Persist only after Steam confirmed the metadata-sourced ID.
    resolve_workshop_identity(
        mod_root,
        cached_workshopid=workshopid,
        auto_repair=True,
    )
    repair = (
        f"Repaired stale Workshop ID {workshopid} to {candidate} from {verified_source}."
    )
    return WorkshopFetchResult(
        item=item,
        requested_workshopid=workshopid,
        identity_source=verified_source or source,
        identity_repair=repair,
    )
