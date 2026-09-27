from __future__ import annotations

import os
import re
import tempfile
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

VISIBILITY_VALUES = {
    0: "public",
    1: "friends",
    2: "private",
    3: "unlisted",
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


def workshop_metadata_from_file(path: Path) -> dict[str, object]:
    """Return normalized editable Workshop metadata from a local workshop.txt."""

    values = parse_workshop_txt(path)
    visibility = values.get("visibility")
    return {
        "title": values.get("title", ""),
        "description": values.get("description", ""),
        "tags": _tags(values.get("tags")),
        "visibility": _visibility(visibility) if visibility is not None else None,
        "present": tuple(values),
    }


def write_workshop_metadata(path: Path, updates: dict[str, object]) -> bool:
    """Update editable workshop fields while preserving unrelated file content."""

    supported = {"title", "description", "tags", "visibility"}
    unknown = set(updates) - supported
    if unknown:
        raise ValueError(f"Unsupported Workshop metadata field(s): {', '.join(sorted(unknown))}")

    original = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    newline = "\r\n" if "\r\n" in original else "\n"
    lines = original.splitlines()
    rendered: list[str] = []
    emitted: set[str] = set()

    def values_for(key: str) -> list[str]:
        value = updates[key]
        if key == "description":
            description = str(value or "").replace("\r\n", "\n").replace("\r", "\n")
            return [f"description={line}" for line in description.split("\n")]
        if key == "tags":
            tags = value if isinstance(value, (list, tuple)) else str(value or "").split(";")
            return [f"tags={';'.join(str(tag).strip() for tag in tags if str(tag).strip())}"]
        if key == "visibility":
            try:
                visibility = int(value) if value is not None else 2
            except (TypeError, ValueError):
                visibility = 2
            return [f"visibility={VISIBILITY_VALUES.get(visibility, 'private')}"]
        return [f"{key}={str(value or '')}"]

    for line in lines:
        existing_key = line.split("=", 1)[0].strip().lower() if "=" in line else ""
        if existing_key not in updates:
            rendered.append(line)
            continue
        if existing_key not in emitted:
            rendered.extend(values_for(existing_key))
            emitted.add(existing_key)

    for key in ("title", "description", "tags", "visibility"):
        if key in updates and key not in emitted:
            rendered.extend(values_for(key))

    updated = newline.join(rendered) + (newline if rendered else "")
    if updated == original:
        return False
    _atomic_write(path, updated)
    return True


def _parse_int(value: str | None) -> int | None:
    try:
        return int(value) if value else None
    except ValueError:
        return None


def _positive_int(value: str | int | None) -> int | None:
    parsed = _parse_int(str(value).strip() if value is not None else None)
    return parsed if parsed and parsed > 0 else None


def _atomic_write(path: Path, text: str) -> None:
    """Replace a metadata file atomically so an interrupted repair cannot truncate it."""

    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode if path.exists() else None
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
        if mode is not None:
            os.chmod(temporary, mode)
        os.replace(temporary, path)
    except Exception:
        try:
            temporary.unlink(missing_ok=True)
        finally:
            raise


def _upsert_key(path: Path, key: str, value: str, *, insert_after: str | None = None) -> bool:
    """Update or append one simple ``key=value`` metadata entry."""

    original = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    newline = "\r\n" if "\r\n" in original else "\n"
    lines = original.splitlines()
    key_lower = key.lower()
    for index, line in enumerate(lines):
        if "=" not in line or line.lstrip().startswith("#"):
            continue
        existing_key = line.split("=", 1)[0].strip().lower()
        if existing_key == key_lower:
            replacement = f"{key}={value}"
            if line == replacement:
                return False
            lines[index] = replacement
            _atomic_write(path, newline.join(lines) + newline)
            return True

    insert_at = len(lines)
    if insert_after:
        insert_after_lower = insert_after.lower()
        for index, line in enumerate(lines):
            if "=" in line and line.split("=", 1)[0].strip().lower() == insert_after_lower:
                insert_at = index + 1
                break
    lines.insert(insert_at, f"{key}={value}")
    _atomic_write(path, newline.join(lines) + newline)
    return True


def _read_workshop_vdf_id(path: Path) -> int | None:
    if not path.is_file():
        return None
    try:
        match = re.search(
            r'"publishedfileid"\s+"(\d+)"',
            path.read_text(encoding="utf-8", errors="replace"),
            flags=re.IGNORECASE,
        )
    except OSError:
        return None
    return _positive_int(match.group(1)) if match else None


def resolve_workshop_identity(
    root: Path,
    cached_workshopid: int | None = None,
    auto_repair: bool = True,
) -> tuple[int | None, str, list[str], list[str]]:
    """Resolve the Workshop ID and repair only missing or non-canonical values."""

    workshop_path = root / "workshop.txt"
    metadata = parse_workshop_txt(workshop_path)
    local_candidates: list[tuple[str, int]] = []
    for key in ("id", "workshopid"):
        value = _positive_int(metadata.get(key))
        if value:
            local_candidates.append((f"workshop.txt:{key}", value))

    vdf_id = _read_workshop_vdf_id(root / "workshop_update.vdf")
    candidates = list(local_candidates)
    if vdf_id:
        candidates.append(("workshop_update.vdf:publishedfileid", vdf_id))

    conflicts: list[str] = []
    distinct_values = {value for _, value in candidates}
    if len(distinct_values) > 1:
        conflicts.append(
            "Workshop ID sources disagree: "
            + ", ".join(f"{source}={value}" for source, value in candidates)
        )

    repairs: list[str] = []
    if candidates:
        source, workshopid = candidates[0]
    elif cached_workshopid and cached_workshopid > 0:
        source, workshopid = "cached profile", cached_workshopid
    else:
        return None, "", conflicts, repairs

    if candidates and cached_workshopid and cached_workshopid > 0 and cached_workshopid != workshopid:
        repairs.append(
            f"Replaced stale cached Workshop ID {cached_workshopid} with {workshopid} from {source}."
        )

    if auto_repair and not conflicts and source != "workshop.txt:id":
        if _upsert_key(workshop_path, "id", str(workshopid), insert_after="version"):
            repairs.append(f"Repaired Workshop ID to {workshopid} from {source}.")

    return workshopid, source, conflicts, repairs


def _mod_info_fields(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if "=" not in raw_line or raw_line.lstrip().startswith("#"):
                continue
            key, value = raw_line.split("=", 1)
            values[key.strip().lower()] = value.strip()
    except OSError:
        return values
    return values


def _discover_mod_ids(root: Path, auto_repair: bool = True) -> tuple[list[str], list[str], list[str]]:
    mods_root = root / "Contents" / "mods"
    if not mods_root.is_dir():
        return [], [], []

    mod_ids: list[str] = []
    repairs: list[str] = []
    conflicts: list[str] = []
    ids_by_mod_root: dict[str, tuple[str, Path]] = {}
    for mod_info_path in sorted(mods_root.rglob("mod.info")):
        try:
            relative = mod_info_path.relative_to(mods_root)
        except ValueError:
            continue
        if not relative.parts:
            continue
        logical_mod_root = relative.parts[0]
        fields = _mod_info_fields(mod_info_path)
        mod_id = fields.get("id", "").strip()
        if not mod_id and auto_repair:
            if _upsert_key(mod_info_path, "id", logical_mod_root, insert_after="name"):
                repairs.append(
                    f"Repaired Mod ID in {mod_info_path.name} to {logical_mod_root}."
                )
            mod_id = logical_mod_root
        if not mod_id:
            conflicts.append(f"Missing Mod ID in {mod_info_path}.")
            continue

        previous = ids_by_mod_root.get(logical_mod_root)
        if previous and previous[0] != mod_id:
            conflicts.append(
                f"Mod ID sources disagree for {logical_mod_root}: "
                f"{previous[1]}={previous[0]}, {mod_info_path}={mod_id}."
            )
        else:
            ids_by_mod_root[logical_mod_root] = (mod_id, mod_info_path)
        if mod_id not in mod_ids:
            mod_ids.append(mod_id)

    return mod_ids, repairs, conflicts


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


def discover_profiles(
    workshop_root: Path,
    appid: int = DEFAULT_APPID,
    *,
    cached_workshop_ids: dict[str, int | None] | None = None,
    auto_repair: bool = True,
) -> list[ModProfile]:
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
        workshopid, workshopid_source, identity_conflicts, identity_repairs = resolve_workshop_identity(
            root,
            (cached_workshop_ids or {}).get(relative_key),
            auto_repair,
        )
        mod_ids, mod_repairs, mod_conflicts = _discover_mod_ids(root, auto_repair)
        identity_repairs.extend(mod_repairs)
        identity_conflicts.extend(mod_conflicts)
        profile = ModProfile(
            key=relative_key,
            name=title,
            mod_root=root,
            appid=_parse_int(metadata.get("appid")) or appid,
            workshopid=workshopid,
            content_path=contents if contents.is_dir() else root,
            preview_path=_preview_for(root),
            title=title,
            description=metadata.get("description", ""),
            visibility=_visibility(metadata.get("visibility")),
            tags=_tags(metadata.get("tags")),
            workshopid_source=workshopid_source,
            mod_ids=mod_ids,
            identity_repairs=identity_repairs,
            identity_conflicts=identity_conflicts,
        )
        profiles.append(profile)
    return profiles
