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
    from tools.semantic_harness.codebuilder.convo_cli_ops import (
        add_repo_override_args,
        read_json_arg as _read_json_arg,
    )
    from tools.semantic_harness.codebuilder.convo_engine_authoring import load_json_document
    from tools.semantic_harness.codebuilder.errors import CompileError
    from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
else:
    from .convo_cli_ops import (
        add_repo_override_args,
        read_json_arg as _read_json_arg,
    )
    from .convo_engine_authoring import load_json_document
    from .errors import CompileError
    from .service import SemanticLabAuthoringService


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

    p_validate = sub.add_parser("validate", help="Validate a ConvoEngine JSON file")
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
        "audit-integrity",
        help="Run the ConvoEngine integrity, hygiene, compiler, layout, and determinism audit",
    )
    _add_repo_args(p_audit)
    p_audit.add_argument("--check-determinism", action="store_true")

    p_get = sub.add_parser("get", help="Progressive-disclosure ConvoEngine record inspection")
    _add_repo_args(p_get)
    p_get.add_argument("record_id", help="Canonical ConvoEngine record ID")
    mode_grp = p_get.add_mutually_exclusive_group()
    mode_grp.add_argument("--summary", action="store_true", help="Compact summary (default)")
    mode_grp.add_argument("--source", action="store_true", help="Targeted source document")
    mode_grp.add_argument("--ir", action="store_true", help="Expanded canonical IR")

    p_impact = sub.add_parser("impact", help="Show direct dependencies and consumers of a ConvoEngine record")
    _add_repo_args(p_impact)
    p_impact.add_argument("record_id", help="Canonical ConvoEngine record ID")

    p_inv = sub.add_parser(
        "modernization-inventory",
        help="Generate the ConvoEngine dataset modernization inventory and optional fail-closed closure gate",
    )
    _add_repo_args(p_inv)
    p_inv.add_argument("--summary", action="store_true", help="Print summary and groups only")
    p_inv.add_argument("--closure", action="store_true", help="Enforce fail-closed modernization closure gate")
    p_inv.add_argument("--out", type=Path, default=None, help="Optional JSON output file")

    p_locate = sub.add_parser("locate", help="Locate package, source path, capabilities, and generated modules for a ConvoEngine ID")
    _add_repo_args(p_locate)
    p_locate.add_argument("record_id", help="Canonical ConvoEngine record ID")

    p_loc_audit = sub.add_parser(
        "localization-audit",
        help="Run the fail-closed ConvoEngine localization audit across all owners",
    )
    _add_repo_args(p_loc_audit)
    p_loc_audit.add_argument("--summary", action="store_true", help="Print counters and shapeCounts only")

    p_dir_audit = sub.add_parser(
        "director-readiness",
        help="Run the fail-closed ConvoEngine S13D/S13E Director layout and readiness audit",
    )
    _add_repo_args(p_dir_audit)
    p_dir_audit.add_argument("--summary", action="store_true", help="Print counters and readinessChecks only")

    p_mig = sub.add_parser(
        "migrate-translations",
        help="Preview or apply canonical ConvoEngine translation migration",
    )
    _add_repo_args(p_mig)
    p_mig.add_argument("--owner", default=None, help="Filter to one owner (PsychopatzCore, ProjectHoomans, DTCommon)")
    p_mig.add_argument("--path-prefix", default=None, help="Filter relative path prefix under sources/conversation")
    p_mig.add_argument("--write", action="store_true", help="Apply migration writes atomically")
    p_mig.add_argument("--keep-legacy-sidecars", action="store_true", help="Do not delete old textSidecars files")

    p_hygiene = sub.add_parser(
        "hygiene-audit",
        help="Run deterministic ConvoEngine semantic family hygiene / anti-duplication / anti-overpacking audit",
    )
    _add_repo_args(p_hygiene)
    p_hygiene.add_argument(
        "--source-root",
        action="append",
        dest="source_roots",
        type=Path,
        default=None,
        help="Explicit ConvoEngine conversation source root(s) to audit (repeatable)",
    )
    p_hygiene.add_argument(
        "--variant-threshold",
        type=int,
        default=12,
        help="Flag variant pools with >= N variants (default: 12)",
    )
    p_hygiene.add_argument(
        "--dynamic-audit",
        action="store_true",
        help="Include static dynamic-token audit (EN/TL parity, stranger-name guard, coverage)",
    )
    p_hygiene.add_argument("--summary", action="store_true", help="Print summary stats only")

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
                result = svc.dispatch_operation(
                    "convo.validate",
                    {
                        "document": doc,
                        "sourcePath": str(input_path),
                        "owner": args.owner,
                    },
                )
            else:
                result = svc.preview_convo_engine_document(
                    doc,
                    source_path=input_path,
                    default_owner=args.owner,
                )
        elif args.command == "create":
            spec = _read_json_arg(args.spec)
            op_name = "convo.change.apply" if args.write else "convo.change.preview"
            result = svc.dispatch_operation(
                op_name,
                {
                    "operation": "create",
                    "document": spec,
                    "destPath": str(args.output) if args.output is not None else None,
                    "requestedOwner": args.owner,
                    "overwrite": bool(args.overwrite),
                },
            )
        elif args.command == "edit":
            patch = _read_json_arg(args.patch)
            op_name = "convo.change.apply" if args.write else "convo.change.preview"
            result = svc.dispatch_operation(
                op_name,
                {
                    "operation": "edit",
                    "target": str(args.source),
                    "patch": patch,
                    "requestedOwner": args.owner,
                    "expectedFingerprint": args.expected_fingerprint,
                },
            )
        elif args.command == "move":
            op_name = "convo.change.apply" if args.write else "convo.change.preview"
            identity = {}
            if args.namespace:
                identity["namespace"] = args.namespace
            if args.family_id:
                identity["id"] = args.family_id
            result = svc.dispatch_operation(
                op_name,
                {
                    "operation": "move",
                    "target": str(args.source),
                    "destPath": str(args.dest),
                    "requestedIdentity": identity or None,
                    "removeSource": not bool(args.keep_source),
                    "overwrite": bool(args.overwrite),
                },
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
        elif args.command == "write":
            doc = _read_json_arg(args.input)
            result = svc.dispatch_operation(
                "convo.change.apply",
                {
                    "operation": "write",
                    "target": str(args.output),
                    "destPath": str(args.output),
                    "document": doc,
                    "expectedFingerprint": args.expected_fingerprint,
                    "requestedOwner": args.owner,
                },
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
        elif args.command == "modernization-inventory":
            op_name = "convo.modernization_closure" if args.closure else "convo.modernization_inventory"
            result = svc.dispatch_operation(op_name, {"closure": bool(args.closure)})
            if args.out is not None:
                out_path = args.out.expanduser().resolve()
                out_path.parent.mkdir(parents=True, exist_ok=True)
                out_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            if args.summary:
                result = {
                    "ok": result.get("ok"),
                    "closureOk": result.get("closureOk"),
                    "schema": result.get("schema"),
                    "summary": result.get("summary"),
                    "groupCount": len(result.get("groups") or ()),
                    "groups": result.get("groups"),
                    "operation": result.get("operation"),
                }
        elif args.command == "audit-integrity":
            result = svc.dispatch_operation(
                "convo.audit",
                {"checkDeterminism": bool(args.check_determinism)},
            )
        elif args.command == "localization-audit":
            from tools.semantic_harness.codebuilder.convo_engine_localization_audit import (
                audit_convo_engine_localization,
            )

            result = audit_convo_engine_localization(
                svc.core_repository,
                hoomans_repository=svc.hoomans_repository,
                dynamic_trading_repository=svc.dynamic_trading_repository,
            )
            if args.summary:
                result = {
                    "schema": result.get("schema"),
                    "ok": result.get("ok"),
                    "counters": result.get("counters"),
                    "shapeCounts": result.get("shapeCounts"),
                }
        elif args.command == "director-readiness":
            from tools.semantic_harness.codebuilder.convo_engine_director_audit import (
                audit_convo_engine_director_readiness,
            )

            result = audit_convo_engine_director_readiness(
                svc.core_repository,
                hoomans_repository=svc.hoomans_repository,
                dynamic_trading_repository=svc.dynamic_trading_repository,
            )
            if args.summary:
                result = {
                    "schema": result.get("schema"),
                    "ok": result.get("ok"),
                    "counters": result.get("counters"),
                    "readinessChecks": result.get("readinessChecks"),
                    "stats": result.get("stats"),
                }
        elif args.command == "hygiene-audit":
            from tools.semantic_harness.codebuilder.convo_engine_hygiene_audit import (
                audit_convo_engine_family_hygiene,
            )

            if args.source_roots:
                roots = args.source_roots
            else:
                from tools.semantic_harness.codebuilder.convo_engine_integrity_audit import (
                    _source_roots_by_owner,
                )

                roots = list(
                    _source_roots_by_owner(
                        svc.core_repository,
                        svc.hoomans_repository,
                        svc.dynamic_trading_repository,
                    ).values()
                )
            result = audit_convo_engine_family_hygiene(
                roots,
                variant_threshold=args.variant_threshold,
                include_dynamic_audit=bool(args.dynamic_audit),
            )
            if args.summary:
                summary_result: dict[str, Any] = {
                    "ok": result.get("ok"),
                    "schema": result.get("schema"),
                    "sourceRoots": result.get("sourceRoots"),
                    "variantThreshold": result.get("variantThreshold"),
                    "stats": result.get("stats"),
                }
                if "dynamicAudit" in result:
                    dyn = result["dynamicAudit"]
                    summary_result["dynamicAudit"] = {
                        "ok": dyn.get("ok"),
                        "schema": dyn.get("schema"),
                        "stats": dyn.get("stats"),
                        "dynamic_coverage_summary": dyn.get("dynamic_coverage_summary"),
                    }
                result = summary_result
        elif args.command == "migrate-translations":
            from tools.semantic_harness.codebuilder.convo_engine_translation_migration import (
                run_translation_migration,
            )

            result = run_translation_migration(
                svc.core_repository,
                hoomans_repository=svc.hoomans_repository,
                dynamic_trading_repository=svc.dynamic_trading_repository,
                owner_filter=args.owner,
                path_prefix=args.path_prefix,
                apply=bool(args.write),
                delete_legacy_sidecars=not args.keep_legacy_sidecars,
            )
        elif args.command in {"get", "impact", "locate"}:
            from tools.semantic_harness.codebuilder.conversation_compiler import compile_conversation_sources
            from tools.semantic_harness.codebuilder.convo_engine_inspect import inspect_convo_engine, locate_convo_engine

            pkg_repos = {
                "PsychopatzCore": svc.core_repository,
                **({"ProjectHoomans": svc.hoomans_repository} if svc.hoomans_repository else {}),
                **({"DTCommon": svc.dynamic_trading_repository} if svc.dynamic_trading_repository else {}),
            }
            compiled = compile_conversation_sources(
                svc.core_repository,
                package_repositories=pkg_repos,
            )
            if args.command == "locate":
                result = {
                    "ok": True,
                    "mode": "locate",
                    "location": locate_convo_engine(
                        compiled,
                        record_id=args.record_id,
                        package_repositories=pkg_repos,
                    ),
                }
            else:
                mode = (
                    "impact"
                    if args.command == "impact"
                    else ("source" if args.source else ("ir" if args.ir else "summary"))
                )
                result = {
                    "ok": True,
                    "mode": mode,
                    "record": inspect_convo_engine(
                        compiled.get("convoRuntimePlans") or [],
                        compiled.get("_source_documents") or {},
                        record_id=args.record_id,
                        mode=mode,
                    ),
                }
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
