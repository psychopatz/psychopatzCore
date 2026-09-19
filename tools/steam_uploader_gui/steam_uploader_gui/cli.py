from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Iterable

from .core.config import (
    SETTING_UPLOADER_PATH,
    SETTING_WORKSHOP_ROOT,
    default_database_path,
    default_log_dir,
    default_workshop_root,
    first_existing_uploader,
)
from .core.discovery import (
    VISIBILITY_NAMES,
    VISIBILITY_VALUES,
    discover_profiles,
    workshop_metadata_from_file,
    write_workshop_metadata,
)
from .core.models import ModProfile, UpdateSelection
from .persistence.database import SettingsDatabase
from .services.logging import EventLogger
from .services.uploader import BackendError, StockSteamUploader, validate
from .services.workshop import (
    SYNC_FIELDS,
    WorkshopItem,
    WorkshopSyncResult,
    fetch_workshop_item,
    sync_workshop_metadata,
)


FIELD_NAMES = ("content", "preview", "title", "description", "tags", "visibility")


class CliError(RuntimeError):
    """An expected terminal usage or Workshop-project error."""


def _add_scope_options(parser: argparse.ArgumentParser, *, defaults: bool) -> None:
    default = None if defaults else argparse.SUPPRESS
    parser.add_argument(
        "--workshop-root",
        type=Path,
        default=default,
        help="Workshop root (default: saved setting or ~/Zomboid/Workshop).",
    )
    parser.add_argument(
        "--database",
        type=Path,
        default=default,
        help="Settings database path (default: the GUI database).",
    )


def _add_json_option(parser: argparse.ArgumentParser, *, defaults: bool) -> None:
    parser.add_argument(
        "--json",
        action="store_true",
        default=False if defaults else argparse.SUPPRESS,
        help="Print machine-readable JSON.",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="steam-uploader-cli",
        description="Read, edit, synchronize, and upload Project Zomboid Workshop projects.",
    )
    _add_scope_options(parser, defaults=True)
    subparsers = parser.add_subparsers(dest="command", metavar="COMMAND")

    projects = subparsers.add_parser(
        "projects", aliases=["list"], help="List discovered Workshop projects."
    )
    _add_scope_options(projects, defaults=False)
    _add_json_option(projects, defaults=False)

    read = subparsers.add_parser("read", help="Read local metadata and identity information.")
    _add_scope_options(read, defaults=False)
    _add_json_option(read, defaults=False)
    read.add_argument("--project", required=True, help="Project key, folder name, title, or Workshop ID.")
    read.add_argument(
        "--steam",
        action="store_true",
        help="Also read current public Steam metadata without changing local files.",
    )

    edit = subparsers.add_parser("edit", help="Edit local Workshop metadata safely.")
    _add_scope_options(edit, defaults=False)
    _add_json_option(edit, defaults=False)
    edit.add_argument("--project", required=True, help="Project key, folder name, title, or Workshop ID.")
    edit.add_argument("--title", help="Replace the local Workshop title.")
    edit.add_argument(
        "--description",
        help="Replace the description. Use --description-file - for stdin.",
    )
    edit.add_argument(
        "--description-file",
        type=Path,
        help="Read the replacement description from a UTF-8 file, or '-' for stdin.",
    )
    edit.add_argument("--tags", help="Replace tags as a semicolon-separated list.")
    edit.add_argument(
        "--visibility",
        choices=("public", "friends", "private", "unlisted"),
        help="Replace local visibility.",
    )

    sync = subparsers.add_parser(
        "sync", help="Fetch Steam metadata and reconcile it into workshop.txt."
    )
    _add_scope_options(sync, defaults=False)
    _add_json_option(sync, defaults=False)
    sync.add_argument("--project", required=True, help="Project key, folder name, title, or Workshop ID.")

    push = subparsers.add_parser("push", help="Validate and upload selected Workshop fields.")
    _add_scope_options(push, defaults=False)
    _add_json_option(push, defaults=False)
    push.add_argument("--project", required=True, help="Project key, folder name, title, or Workshop ID.")
    push.add_argument(
        "--fields",
        default="all",
        help="Comma-separated fields: content, preview, title, description, tags, visibility (default: all).",
    )
    push.add_argument("--change-note", default="", help="Steam change note / patch note.")
    push.add_argument("--uploader", type=Path, help="SteamUploader executable path.")
    push.add_argument(
        "--sync-first",
        action="store_true",
        help="Fetch and reconcile Steam metadata before validating the upload.",
    )
    push.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and log the plan without starting SteamUploader.",
    )
    push.add_argument(
        "--yes",
        action="store_true",
        help="Approve the upload. Without this flag, push only prints the plan.",
    )
    return parser


def _path(value: Path | None, fallback: Path) -> Path:
    return (value or fallback).expanduser()


def _visibility_name(value: object) -> str:
    try:
        return VISIBILITY_VALUES.get(int(value), "private")
    except (TypeError, ValueError):
        return "private"


def _metadata_values(metadata: dict[str, object]) -> dict[str, object]:
    visibility = metadata.get("visibility")
    return {
        "title": str(metadata.get("title") or ""),
        "description": str(metadata.get("description") or ""),
        "tags": [str(tag) for tag in (metadata.get("tags") or [])],
        "visibility": int(visibility) if visibility is not None else None,
    }


def _profile_payload(profile: ModProfile) -> dict[str, object]:
    local = _metadata_values(workshop_metadata_from_file(profile.mod_root / "workshop.txt"))
    return {
        "key": profile.key,
        "name": profile.name,
        "mod_root": str(profile.mod_root),
        "appid": profile.appid,
        "workshopid": profile.workshopid,
        "workshopid_source": profile.workshopid_source,
        "mod_ids": list(profile.mod_ids),
        "identity_repairs": list(profile.identity_repairs),
        "identity_conflicts": list(profile.identity_conflicts),
        "content_path": str(profile.content_path) if profile.content_path else None,
        "preview_path": str(profile.preview_path) if profile.preview_path else None,
        "metadata": {**local, "visibility_name": _visibility_name(local["visibility"])},
    }


def _item_payload(item: WorkshopItem) -> dict[str, object]:
    return {
        "published_file_id": item.published_file_id,
        "title": item.title,
        "description": item.description,
        "tags": list(item.tags),
        "visibility": item.visibility,
        "visibility_name": _visibility_name(item.visibility),
        "preview_url": item.preview_url,
        "file_url": item.file_url,
    }


def _sync_payload(result: WorkshopSyncResult) -> dict[str, object]:
    return {
        "steam": _item_payload(result.item),
        "local_before": result.local_before,
        "local_after": result.local_after,
        "remote": result.remote,
        "applied_fields": list(result.applied_fields),
        "conflicts": result.conflicts or {},
    }


def _same_metadata(field: str, left: object, right: object) -> bool:
    if field == "tags":
        return [str(tag).strip() for tag in (left or [])] == [str(tag).strip() for tag in (right or [])]
    return left == right


def _diff(local: dict[str, object], remote: dict[str, object]) -> dict[str, dict[str, object]]:
    return {
        field: {"local": local.get(field), "steam": remote.get(field)}
        for field in SYNC_FIELDS
        if not _same_metadata(field, local.get(field), remote.get(field))
    }


def _find_profile(profiles: Iterable[ModProfile], selector: str) -> ModProfile:
    candidates = list(profiles)
    exact = [profile for profile in candidates if profile.key == selector]
    if not exact:
        folded = selector.casefold()
        exact = [
            profile
            for profile in candidates
            if profile.key.casefold() == folded
            or profile.mod_root.name.casefold() == folded
            or profile.name.casefold() == folded
            or str(profile.workshopid or "") == selector
        ]
    if len(exact) == 1:
        return exact[0]
    if len(exact) > 1:
        names = ", ".join(profile.key for profile in exact)
        raise CliError(f"Project selector {selector!r} is ambiguous: {names}")
    available = ", ".join(profile.key for profile in candidates) or "none"
    raise CliError(f"Project {selector!r} was not found. Available projects: {available}")


def _apply_local_metadata(profile: ModProfile, metadata: dict[str, object]) -> None:
    values = _metadata_values(metadata)
    profile.title = str(values["title"] or "")
    profile.description = str(values["description"] or "")
    profile.tags = [str(tag) for tag in (values["tags"] or [])]
    profile.visibility = int(values["visibility"]) if values["visibility"] is not None else 2
    profile.name = profile.title or profile.mod_root.name


def _load_context(args: argparse.Namespace) -> tuple[SettingsDatabase, Path, list[ModProfile]]:
    database = SettingsDatabase(_path(args.database, default_database_path()))
    configured_root = database.get_setting(SETTING_WORKSHOP_ROOT, str(default_workshop_root()))
    root = _path(args.workshop_root, Path(configured_root))
    saved_profiles = database.load_profiles()
    profiles = discover_profiles(
        root,
        cached_workshop_ids={key: profile.workshopid for key, profile in saved_profiles.items()},
    )
    for profile in profiles:
        if profile.identity_repairs:
            database.save_profile(profile)
    return database, root, profiles


def _print(value: object, *, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(value, ensure_ascii=False, indent=2, default=str))
    else:
        print(value)


def _projects(args: argparse.Namespace, profiles: list[ModProfile]) -> int:
    payload = [_profile_payload(profile) for profile in profiles]
    if args.json:
        _print({"workshop_root": str(args._workshop_root), "projects": payload}, json_mode=True)
        return 0
    print(f"Workshop root: {args._workshop_root}")
    if not profiles:
        print("No Workshop projects found.")
        return 0
    for profile in profiles:
        workshopid = str(profile.workshopid) if profile.workshopid else "missing"
        modids = ", ".join(profile.mod_ids) or "missing"
        suffix = " [IDENTITY CONFLICT]" if profile.identity_conflicts else ""
        print(f"{profile.key}: {profile.name} | Workshop ID {workshopid} | Mod ID {modids}{suffix}")
    return 0


def _read(args: argparse.Namespace, profiles: list[ModProfile]) -> int:
    profile = _find_profile(profiles, args.project)
    local = _metadata_values(workshop_metadata_from_file(profile.mod_root / "workshop.txt"))
    payload: dict[str, object] = {"project": _profile_payload(profile), "local": local}
    if args.steam:
        if profile.identity_conflicts:
            raise CliError("Cannot read Steam metadata while identity conflicts exist: " + "; ".join(profile.identity_conflicts))
        if profile.workshopid is None or profile.workshopid <= 0:
            raise CliError("This project has no valid Workshop ID.")
        item = fetch_workshop_item(profile.workshopid)
        remote = _item_payload(item)
        payload["steam"] = remote
        payload["diff"] = _diff(local, {field: remote[field] for field in SYNC_FIELDS})
    if args.json:
        _print(payload, json_mode=True)
        return 0

    print(f"Project: {profile.name} [{profile.key}]")
    print(f"Root: {profile.mod_root}")
    print(f"App ID: {profile.appid}")
    print(f"Workshop ID: {profile.workshopid or 'missing'} ({profile.workshopid_source or 'unresolved'})")
    print(f"Mod ID(s): {', '.join(profile.mod_ids) or 'missing'}")
    if profile.identity_repairs:
        print("Identity repairs: " + "; ".join(profile.identity_repairs))
    if profile.identity_conflicts:
        print("Identity conflicts: " + "; ".join(profile.identity_conflicts))
    print(f"Title: {local['title']}")
    print(f"Tags: {';'.join(local['tags'])}")
    print(f"Visibility: {_visibility_name(local['visibility'])}")
    print("Description:")
    print(local["description"] or "(empty)")
    if args.steam:
        steam = payload["steam"]
        assert isinstance(steam, dict)
        print("\nSteam metadata:")
        print(f"Title: {steam['title']}")
        print(f"Tags: {';'.join(steam['tags'])}")
        print(f"Visibility: {steam['visibility_name']}")
        print("Description:")
        print(steam["description"] or "(empty)")
        differences = payload["diff"]
        print("\nDifferences: " + (", ".join(differences) if differences else "none"))
    return 0


def _edit(args: argparse.Namespace, database: SettingsDatabase, profiles: list[ModProfile]) -> int:
    profile = _find_profile(profiles, args.project)
    if args.description is not None and args.description_file is not None:
        raise CliError("Use either --description or --description-file, not both.")
    if args.description_file is not None:
        if str(args.description_file) == "-":
            description = sys.stdin.read()
        else:
            try:
                description = args.description_file.expanduser().read_text(encoding="utf-8")
            except OSError as exc:
                raise CliError(f"Could not read description file: {exc}") from exc
    else:
        description = args.description

    updates: dict[str, object] = {}
    if args.title is not None:
        updates["title"] = args.title
    if description is not None:
        updates["description"] = description
    if args.tags is not None:
        updates["tags"] = args.tags
    if args.visibility is not None:
        updates["visibility"] = VISIBILITY_NAMES[args.visibility]
    if not updates:
        raise CliError("Specify at least one of --title, --description, --description-file, --tags, or --visibility.")

    changed = write_workshop_metadata(profile.mod_root / "workshop.txt", updates)
    metadata = workshop_metadata_from_file(profile.mod_root / "workshop.txt")
    _apply_local_metadata(profile, metadata)
    database.save_profile(profile)
    payload = {
        "project": profile.key,
        "changed": changed,
        "fields": list(updates),
        "metadata": _metadata_values(metadata),
    }
    if args.json:
        _print(payload, json_mode=True)
    else:
        state = "updated" if changed else "already matched"
        print(f"{profile.key}: local Workshop metadata {state} ({', '.join(updates)}).")
    return 0


def _sync_profile(database: SettingsDatabase, profile: ModProfile) -> WorkshopSyncResult:
    if profile.identity_conflicts:
        raise CliError("Cannot sync while identity conflicts exist: " + "; ".join(profile.identity_conflicts))
    if profile.workshopid is None or profile.workshopid <= 0:
        raise CliError("This project has no valid Workshop ID.")
    item = fetch_workshop_item(profile.workshopid)
    result = sync_workshop_metadata(
        profile.mod_root,
        item,
        database.load_workshop_sync(profile.key),
    )
    database.save_workshop_sync(profile.key, result.remote, result.local_after)
    _apply_local_metadata(profile, result.local_after)
    database.save_profile(profile)
    return result


def _sync(args: argparse.Namespace, database: SettingsDatabase, profiles: list[ModProfile]) -> int:
    profile = _find_profile(profiles, args.project)
    result = _sync_profile(database, profile)
    payload = {"project": profile.key, **_sync_payload(result)}
    if args.json:
        _print(payload, json_mode=True)
    else:
        if result.applied_fields:
            print("Applied from Steam: " + ", ".join(result.applied_fields))
        else:
            print("Local Workshop metadata is already synchronized with Steam.")
        if result.conflicts:
            print("Conflicts preserved locally: " + ", ".join(result.conflicts))
        print(f"Workshop ID: {result.item.published_file_id}")
    return 2 if result.conflicts else 0


def _selection(fields: str, change_note: str) -> UpdateSelection:
    normalized = fields.strip().lower()
    if normalized in {"all", "*"}:
        selected = set(FIELD_NAMES)
    else:
        selected = {field.strip() for field in normalized.replace(";", ",").split(",") if field.strip()}
        unknown = selected - set(FIELD_NAMES)
        if unknown:
            raise CliError("Unknown upload field(s): " + ", ".join(sorted(unknown)))
    return UpdateSelection(
        **{field: field in selected for field in FIELD_NAMES},
        change_note=change_note,
    )


def _push(
    args: argparse.Namespace,
    database: SettingsDatabase,
    profiles: list[ModProfile],
) -> int:
    profile = _find_profile(profiles, args.project)
    if args.sync_first:
        sync_result = _sync_profile(database, profile)
        if sync_result.conflicts:
            payload = {
                "project": profile.key,
                "error": "Steam sync found conflicts; upload was not started.",
                **_sync_payload(sync_result),
            }
            _print(payload, json_mode=args.json)
            return 2

    selection = _selection(args.fields, args.change_note)
    validation = validate(profile, selection)
    payload: dict[str, object] = {
        "project": profile.key,
        "workshopid": profile.workshopid,
        "fields": selection.fields,
        "warnings": validation.warnings,
        "errors": validation.errors,
        "dry_run": bool(args.dry_run),
        "started": False,
    }
    if not validation.ok:
        if args.json:
            _print(payload, json_mode=True)
        else:
            print(f"Upload validation failed for {profile.key}:")
            for warning in validation.warnings:
                print(f"WARNING: {warning}")
            for error in validation.errors:
                print(f"ERROR: {error}")
        return 2

    uploader_setting = database.get_setting(SETTING_UPLOADER_PATH, "").strip()
    uploader_path = _path(args.uploader, Path(uploader_setting) if uploader_setting else (first_existing_uploader() or Path("")))
    logger = EventLogger(database, default_log_dir())
    uploader = StockSteamUploader(uploader_path, logger)
    payload["uploader"] = str(uploader_path)

    if args.dry_run:
        uploader.dry_run(profile, selection)
        payload["message"] = "Dry run completed; no Steam process was started."
        if args.json:
            _print(payload, json_mode=True)
        else:
            print(f"Dry run for {profile.key}: {', '.join(selection.fields)}")
            print("No Steam process was started.")
        return 0

    if not args.yes:
        payload["message"] = "Upload not started. Re-run with --yes to approve this plan."
        if args.json:
            _print(payload, json_mode=True)
        else:
            print(f"Upload plan for {profile.key}: {', '.join(selection.fields)}")
            print("Upload not started. Re-run with --yes to approve this plan.")
        return 2

    database.save_profile(profile)
    result = uploader.upload(profile, selection)
    payload.update({"started": result.started, "exit_code": result.exit_code, "message": result.message})
    if args.json:
        _print(payload, json_mode=True)
    else:
        print(f"SteamUploader exited with code {result.exit_code}.")
    return result.exit_code


def _dispatch(args: argparse.Namespace, database: SettingsDatabase, profiles: list[ModProfile], root: Path) -> int:
    args._workshop_root = root
    if args.command in {"projects", "list"}:
        return _projects(args, profiles)
    if args.command == "read":
        return _read(args, profiles)
    if args.command == "edit":
        return _edit(args, database, profiles)
    if args.command == "sync":
        return _sync(args, database, profiles)
    if args.command == "push":
        return _push(args, database, profiles)
    raise CliError("Choose a command: projects, read, edit, sync, or push.")


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if not hasattr(args, "json"):
        args.json = False
    if not args.command:
        parser.print_help()
        return 2

    database: SettingsDatabase | None = None
    try:
        database, root, profiles = _load_context(args)
        return _dispatch(args, database, profiles, root)
    except (CliError, BackendError, OSError, RuntimeError, ValueError) as exc:
        if getattr(args, "json", False):
            _print({"error": str(exc)}, json_mode=True)
        else:
            print(f"error: {exc}", file=sys.stderr)
        return 2
    finally:
        if database is not None:
            database.close()


if __name__ == "__main__":
    raise SystemExit(main())
