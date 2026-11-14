#!/usr/bin/env python3
"""Headless CodeBuilder ConvoEngine create/edit/move/shard/write CLI."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

if __package__ in {None, ""}:
    from tools.semantic_harness.codebuilder.convo_engine_authoring import load_json_document
    from tools.semantic_harness.codebuilder.errors import CompileError
    from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
else:
    from .convo_engine_authoring import load_json_document
    from .errors import CompileError
    from .service import SemanticLabAuthoringService


def _read_json_arg(path_or_json: str) -> Any:
    text = path_or_json.strip()
    if text.startswith("{") or text.startswith("["):
        return json.loads(text)
    return json.loads(Path(path_or_json).expanduser().resolve().read_text(encoding="utf-8"))


def _service(args: argparse.Namespace) -> SemanticLabAuthoringService:
    repo = Path(args.repository).expanduser().resolve()
    core = Path(args.core_repository).expanduser().resolve() if args.core_repository else None
    hoomans = Path(args.hoomans_repository).expanduser().resolve() if args.hoomans_repository else None
    dt = Path(args.dynamic_trading_repository).expanduser().resolve() if args.dynamic_trading_repository else None
    return SemanticLabAuthoringService(
        repository=repo,
        core_repository=core,
        hoomans_repository=hoomans,
        dynamic_trading_repository=dt,
    )


def _add_repo_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--repository", type=Path, default=ROOT)
    parser.add_argument("--core-repository", type=Path, default=None)
    parser.add_argument("--hoomans-repository", type=Path, default=None)
    parser.add_argument("--dynamic-trading-repository", type=Path, default=None)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_validate = sub.add_parser("validate", help="Validate a ConvoEngine/PSDL JSON file")
    _add_repo_args(p_validate)
    p_validate.add_argument("--input", required=True, type=Path)
    p_validate.add_argument("--owner", default=None)
    p_validate.add_argument("--strict", action="store_true")

    p_preview = sub.add_parser("preview", help="Preview compiled IR and runtime plan")
    _add_repo_args(p_preview)
    p_preview.add_argument("--input", required=True, type=Path)
    p_preview.add_argument("--owner", default=None)
    p_preview.add_argument("--strict", action="store_true")

    p_create = sub.add_parser("create", help="Create and validate a ConvoEngine family")
    _add_repo_args(p_create)
    p_create.add_argument("--spec", required=True, help="JSON file or inline JSON object")
    p_create.add_argument("--output", type=Path, default=None)
    p_create.add_argument("--owner", default=None)
    p_create.add_argument("--write", action="store_true")
    p_create.add_argument("--overwrite", action="store_true")

    p_edit = sub.add_parser("edit", help="Edit and validate a ConvoEngine family")
    _add_repo_args(p_edit)
    p_edit.add_argument("--source", required=True, type=Path)
    p_edit.add_argument("--patch", required=True, help="JSON file or inline JSON patch")
    p_edit.add_argument("--owner", default=None)
    p_edit.add_argument("--expected-fingerprint", default=None)
    p_edit.add_argument("--write", action="store_true")

    p_move = sub.add_parser("move", help="Move/re-namespace a ConvoEngine source")
    _add_repo_args(p_move)
    p_move.add_argument("--source", required=True, type=Path)
    p_move.add_argument("--dest", required=True, type=Path)
    p_move.add_argument("--namespace", default=None)
    p_move.add_argument("--id", dest="family_id", default=None)
    p_move.add_argument("--keep-source", action="store_true")
    p_move.add_argument("--overwrite", action="store_true")
    p_move.add_argument("--write", action="store_true")

    p_shard = sub.add_parser("shard", help="Shard/migrate a source into canonical ConvoEngine families")
    _add_repo_args(p_shard)
    p_shard.add_argument("--source", required=True, type=Path)
    p_shard.add_argument("--plan", required=True, help="JSON file or inline JSON list")
    p_shard.add_argument("--owner", default=None)
    p_shard.add_argument("--overwrite", action="store_true")
    p_shard.add_argument("--prune-source", action="store_true")
    p_shard.add_argument("--write", action="store_true")

    p_migrate = sub.add_parser(
        "migrate-bucket",
        help="Accountably migrate a legacy PSDL bucket into coherent ConvoEngine family files",
    )
    _add_repo_args(p_migrate)
    p_migrate.add_argument("--source", required=True, type=Path)
    p_migrate.add_argument("--plan", required=True, help="JSON file or inline JSON list")
    p_migrate.add_argument("--owner", default=None)
    p_migrate.add_argument("--allow-partial", action="store_true")
    p_migrate.add_argument("--overwrite", action="store_true")
    p_migrate.add_argument("--prune-source", action="store_true")
    p_migrate.add_argument("--write", action="store_true")

    p_write = sub.add_parser("write", help="Validate and write a canonical ConvoEngine JSON file")
    _add_repo_args(p_write)
    p_write.add_argument("--input", required=True, help="JSON file or inline JSON object")
    p_write.add_argument("--output", required=True, type=Path)
    p_write.add_argument("--owner", default=None)
    p_write.add_argument("--expected-fingerprint", default=None)

    p_norm = sub.add_parser(
        "normalize",
        help="Fold style/legacy/numeric ConvoEngine sources into one canonical family",
    )
    _add_repo_args(p_norm)
    p_norm.add_argument("--sources", nargs="+", required=True, type=Path)
    p_norm.add_argument("--dest", type=Path, default=None)
    p_norm.add_argument("--owner", default=None)
    p_norm.add_argument("--no-strip-numeric", action="store_true")
    p_norm.add_argument("--force-style-bundle", action="store_true")
    p_norm.add_argument("--prune-sources", action="store_true")
    p_norm.add_argument("--write", action="store_true")

    p_audit = sub.add_parser(
        "audit-s6m8",
        help="Run the S6M8 ConvoEngine hygiene, compiler, layout, and determinism audit",
    )
    _add_repo_args(p_audit)
    p_audit.add_argument("--check-determinism", action="store_true")

    return parser


def main(arguments: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(arguments)
    svc = _service(args)
    try:
        if args.command in {"validate", "preview"}:
            input_path = args.input.expanduser().resolve()
            doc = load_json_document(input_path)
            if args.command == "validate":
                result = svc.validate_convo_engine_document(
                    doc,
                    source_path=input_path,
                    default_owner=args.owner,
                    allow_legacy_schema=not args.strict,
                )
            else:
                result = svc.preview_convo_engine_document(
                    doc,
                    source_path=input_path,
                    default_owner=args.owner,
                    allow_legacy_schema=not args.strict,
                )
        elif args.command == "create":
            spec = _read_json_arg(args.spec)
            result = svc.create_convo_engine_family(
                spec,
                source_path=args.output,
                default_owner=args.owner,
                write=args.write,
                overwrite=args.overwrite,
            )
        elif args.command == "edit":
            patch = _read_json_arg(args.patch)
            result = svc.edit_convo_engine_family(
                args.source,
                patch,
                default_owner=args.owner,
                expected_source_fingerprint=args.expected_fingerprint,
                write=args.write,
            )
        elif args.command == "move":
            result = svc.move_convo_engine_source(
                args.source,
                args.dest,
                namespace=args.namespace,
                family_id=args.family_id,
                remove_source=not args.keep_source,
                overwrite=args.overwrite,
                dry_run=not args.write,
            )
        elif args.command == "shard":
            plan = _read_json_arg(args.plan)
            result = svc.shard_convo_engine_source(
                args.source,
                plan,
                default_owner=args.owner,
                write=args.write,
                overwrite=args.overwrite,
                prune_source=args.prune_source,
            )
        elif args.command == "migrate-bucket":
            plan = _read_json_arg(args.plan)
            result = svc.migrate_convo_engine_bucket(
                args.source,
                plan,
                default_owner=args.owner,
                require_complete=not args.allow_partial,
                write=args.write,
                overwrite=args.overwrite,
                prune_source=args.prune_source,
            )
        elif args.command == "write":
            doc = _read_json_arg(args.input)
            result = svc.write_convo_engine_source(
                args.output,
                doc,
                expected_source_fingerprint=args.expected_fingerprint,
                default_owner=args.owner,
                allow_legacy_schema=False,
            )
        elif args.command == "normalize":
            result = svc.normalize_convo_engine_sources(
                args.sources,
                dest_path=args.dest,
                default_owner=args.owner,
                strip_numeric_suffix=not args.no_strip_numeric,
                force_style_bundle=args.force_style_bundle,
                write=args.write,
                prune_sources=args.prune_sources,
            )
        elif args.command == "audit-s6m8":
            result = svc.run_convo_engine_s6m8_audit(
                check_determinism=args.check_determinism,
            )
        else:
            parser.error(f"unknown command: {args.command}")
            return 2
    except (CompileError, OSError, ValueError, json.JSONDecodeError) as error:
        print(
            json.dumps(
                {
                    "ok": False,
                    "diagnostics": [{"severity": "error", "message": str(error)}],
                    "writes": [],
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return 2

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result.get("ok") is True else 2


if __name__ == "__main__":
    raise SystemExit(main())
