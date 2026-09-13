from __future__ import annotations

from pathlib import Path

from .config import DEFAULT_APPID
from .models import ModProfile


VISIBILITY_NAMES = {
    "public": 0,
    "friends": 1,
    "friends-only": 1,
    "private": 2,
    "hidden": 2,
    "unlisted": 3,
}


def parse_workshop_txt(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        normalized_key = key.strip().lower()
        normalized_value = value.strip()
        if normalized_key == "description" and normalized_key in values:
            values[normalized_key] = f"{values[normalized_key]}\n{normalized_value}"
        else:
            values[normalized_key] = normalized_value
    return values


def _parse_int(value: str | None) -> int | None:
    try:
        return int(value) if value else None
    except ValueError:
        return None


def _visibility(value: str | None) -> int:
    if not value:
        return 2
    return VISIBILITY_NAMES.get(value.strip().lower(), 2)


def _tags(value: str | None) -> list[str]:
    if not value:
        return []
    return [tag.strip() for tag in value.split(";") if tag.strip()]


def _preview_for(root: Path) -> Path | None:
    candidates: list[Path] = []
    for name in ("preview.gif", "preview.png", "preview.jpg", "preview.jpeg", "poster.png"):
        candidate = root / name
        if candidate.is_file():
            candidates.append(candidate)
    if not candidates:
        return None
    # Steam's primary preview limit is strict. Prefer the first candidate that
    # can actually be uploaded, but retain an oversized candidate when it is
    # the only available file so validation can explain the problem.
    for candidate in candidates:
        try:
            if candidate.stat().st_size < 1_000_000:
                return candidate
        except OSError:
            continue
    return candidates[0]


def discover_profiles(workshop_root: Path, appid: int = DEFAULT_APPID) -> list[ModProfile]:
    """Discover any Workshop project folder without assuming a particular mod name."""

    if not workshop_root.is_dir():
        return []

    profiles: list[ModProfile] = []
    for root in sorted((item for item in workshop_root.iterdir() if item.is_dir()), key=lambda p: p.name.lower()):
        metadata = parse_workshop_txt(root / "workshop.txt")
        contents = root / "Contents"
        if not metadata and not contents.is_dir():
            continue

        relative_key = root.relative_to(workshop_root).as_posix()
        title = metadata.get("title") or root.name
        profile = ModProfile(
            key=relative_key,
            name=title,
            mod_root=root,
            appid=_parse_int(metadata.get("appid")) or appid,
            workshopid=_parse_int(metadata.get("id")) or _parse_int(metadata.get("workshopid")),
            content_path=contents if contents.is_dir() else root,
            preview_path=_preview_for(root),
            title=title,
            description=metadata.get("description", ""),
            visibility=_visibility(metadata.get("visibility")),
            tags=_tags(metadata.get("tags")),
        )
        profiles.append(profile)
    return profiles
