from __future__ import annotations

import json
import time
import urllib.parse
import urllib.request
import webbrowser
from dataclasses import dataclass


@dataclass(frozen=True)
class WorkshopItem:
    published_file_id: int
    title: str
    description: str
    tags: list[str]
    visibility: int
    preview_url: str = ""
    file_url: str = ""


_WORKSHOP_CACHE: dict[int, tuple[float, WorkshopItem]] = {}
_WORKSHOP_CACHE_TTL_SECONDS = 30.0


def workshop_url(workshopid: int) -> str:
    return f"https://steamcommunity.com/sharedfiles/filedetails/?id={workshopid}"


def open_workshop_page(workshopid: int) -> None:
    webbrowser.open(workshop_url(workshopid))


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
