"""Shared ConvoEngine / workspace CLI subcommand definitions and dispatcher.

Used by both the main Semantic Harness CLI (``entrypoints/cli.py``) and the
headless authoring CLI (``codebuilder/convo_engine_cli.py``) so neither CLI
duplicates OperationRegistry contracts.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from .convo_engine_authoring import load_json_document
from .errors import CompileError


def read_json_arg(path_or_json: str) -> Any:
    text = path_or_json.strip()
    if text.startswith("{") or text.startswith("["):
        return json.loads(text)
    return json.loads(Path(path_or_json).expanduser().resolve().read_text(encoding="utf-8"))


def add_repo_override_args(parser: argparse.ArgumentParser, *, use_sub_dest: bool = True) -> None:
    prefix = "sub_" if use_sub_dest else ""
    default = argparse.SUPPRESS if use_sub_dest else None
    parser.add_argument("--repository", dest=f"{prefix}repository", type=Path, default=default)
    parser.add_argument("--core-repository", dest=f"{prefix}core_repository", type=Path, default=default)
    parser.add_argument("--hoomans-repository", dest=f"{prefix}hoomans_repository", type=Path, default=default)
    parser.add_argument(
        "--dynamic-trading-repository",
        dest=f"{prefix}dynamic_trading_repository",
        type=Path,
        default=default,
    )


def effective_repo_arg(args: argparse.Namespace, name: str) -> Path | None:
    sub_value = getattr(args, f"sub_{name}", None)
    root_value = getattr(args, name, None)
    chosen = sub_value if sub_value is not None else root_value
    return Path(chosen).expanduser().resolve() if chosen else None


def register_workspace_and_convo_subparsers(parser: argparse.ArgumentParser) -> None:
    """Attach optional ``workspace`` and ``convo`` subcommands to the main CLI parser."""
    repo_parent = argparse.ArgumentParser(add_help=False)
    add_repo_override_args(repo_parent, use_sub_dest=True)
    repo_parent.add_argument("--jsonl", dest="sub_jsonl", action="store_true", default=argparse.SUPPRESS)

    sub = parser.add_subparsers(dest="command")

    # workspace ...
    ws_parser = sub.add_parser("workspace", help="Inspect workspace providers, repos, and capabilities")
    ws_sub = ws_parser.add_subparsers(dest="workspace_command", required=True)
    ws_sub.add_parser("describe", parents=[repo_parent], help="Describe workspace manifest snapshot")

    # convo ...
    convo_parser = sub.add_parser("convo", help="Author, inspect, validate, simulate, and build ConvoEngine")
    convo_sub = convo_parser.add_subparsers(dest="convo_command", required=True)

    convo_sub.add_parser("operations", parents=[repo_parent], help="List registered OperationRegistry operations")

    p_cat = convo_sub.add_parser("catalog", parents=[repo_parent], help="Query compact ConvoCatalog summaries")
    p_cat.add_argument("--owner", default=None)
    p_cat.add_argument("--kind", default=None)
    p_cat.add_argument("--namespace", default=None)
    p_cat.add_argument("--query", default="")
    p_cat.add_argument("--limit", type=int, default=50)
    p_cat.add_argument("--offset", type=int, default=0)

    p_get = convo_sub.add_parser("get", parents=[repo_parent], help="Load one ConvoEngine family by ID or path")
    p_get.add_argument("target")
    p_get.add_argument("--include-compiled", action="store_true")

    p_impact = convo_sub.add_parser("impact", parents=[repo_parent], help="Inspect bounded reference impact closure")
    p_impact.add_argument("target")
    p_impact.add_argument("--depth", type=int, default=2)

    p_val = convo_sub.add_parser("validate", parents=[repo_parent], help="Validate a ConvoEngine family document")
    p_val.add_argument("target", nargs="?", default=None)
    p_val.add_argument("--input", type=Path, default=None)
    p_val.add_argument("--owner", default=None)
    p_val.add_argument("--strict", action="store_true")
    p_val.add_argument("--allow-legacy", action="store_true")

    p_sim = convo_sub.add_parser("simulate", parents=[repo_parent], help="Simulate one family via production Lua ConvoProbe")
    p_sim.add_argument("target")
    p_sim.add_argument("--speaker", default="player")
    p_sim.add_argument("--addressee", default="npc")
    p_sim.add_argument("--target-actor", dest="target_actor", default="companion")
    p_sim.add_argument("--style", default="neutral")
    p_sim.add_argument("--locale", default="EN")
    p_sim.add_argument("--outcome", default=None)
    p_sim.add_argument("--slots", default=None, help="JSON object or file path of slot values")

    p_chg = convo_sub.add_parser("change", parents=[repo_parent], help="Preview or apply a safe ConvoTransaction")
    p_chg.add_argument("action", choices=("preview", "apply"))
    p_chg.add_argument(
        "--operation",
        required=True,
        choices=("create", "write", "edit", "move", "delete", "shard", "normalize"),
    )
    p_chg.add_argument("--target", default=None)
    p_chg.add_argument("--dest", default=None)
    p_chg.add_argument("--spec", default=None, help="JSON object or file path for create")
    p_chg.add_argument("--document", default=None, help="JSON object or file path for write/create")
    p_chg.add_argument("--patch", default=None, help="JSON object or file path for edit")
    p_chg.add_argument("--plan", default=None, help="JSON list or file path for shard")
    p_chg.add_argument("--sources", nargs="*", default=None)
    p_chg.add_argument("--owner", default=None)
    p_chg.add_argument("--namespace", default=None)
    p_chg.add_argument("--family-id", dest="family_id", default=None)
    p_chg.add_argument("--expected-fingerprint", default=None)
    p_chg.add_argument("--overwrite", action="store_true")
    p_chg.add_argument("--keep-source", action="store_true")
    p_chg.add_argument("--prune-source", action="store_true")
    p_chg.add_argument("--allow-legacy", action="store_true")

    p_bld = convo_sub.add_parser("build", parents=[repo_parent], help="Preview or apply ConvoEngine build outputs")
    p_bld.add_argument("action", choices=("preview", "apply"))
    p_bld.add_argument("--owner", default=None)
    p_bld.add_argument("--check-determinism", action="store_true")

    p_aud = convo_sub.add_parser("audit", parents=[repo_parent], help="Run the S6M8 ConvoEngine audit")
    p_aud.add_argument("--check-determinism", action="store_true")
    p_aud.add_argument("--no-require-all-owners", action="store_true")


def _ok_result(payload: Any) -> dict[str, Any]:
    if not isinstance(payload, dict):
        return {"ok": True, "result": payload}
    if "ok" not in payload:
        return {**payload, "ok": True}
    return payload


def dispatch_convo_cli(args: argparse.Namespace, service: Any) -> dict[str, Any]:
    """Execute a ``workspace`` or ``convo`` CLI command through ``OperationRegistry``."""
    command = getattr(args, "command", None)
    try:
        if command == "workspace":
            ws_cmd = getattr(args, "workspace_command", None)
            if ws_cmd == "describe":
                return _ok_result(service.dispatch_operation("workspace.describe", {}))
            raise ValueError(f"unknown workspace command: {ws_cmd}")

        if command == "convo":
            subcmd = getattr(args, "convo_command", None)
            if subcmd == "operations":
                return {"ok": True, "operations": service.describe_operations()}
            if subcmd == "catalog":
                return _ok_result(service.dispatch_operation(
                    "convo.catalog",
                    {
                        "owner": args.owner,
                        "kind": args.kind,
                        "namespace": args.namespace,
                        "query": args.query,
                        "limit": args.limit,
                        "offset": args.offset,
                    },
                ))
            if subcmd == "get":
                return _ok_result(service.dispatch_operation(
                    "convo.get",
                    {"target": args.target, "includeCompiled": bool(args.include_compiled)},
                ))
            if subcmd == "impact":
                return _ok_result(service.dispatch_operation(
                    "convo.impact",
                    {"target": args.target, "depth": args.depth},
                ))
            if subcmd == "validate":
                allow_legacy = bool(args.allow_legacy and not args.strict)
                payload: dict[str, Any] = {
                    "owner": args.owner,
                    "allowLegacySchema": allow_legacy,
                }
                if args.input is not None:
                    input_path = args.input.expanduser().resolve()
                    payload["document"] = load_json_document(input_path)
                    payload["sourcePath"] = str(input_path)
                elif args.target is not None:
                    payload["target"] = args.target
                else:
                    raise ValueError("convo validate requires <target> or --input PATH")
                return service.dispatch_operation("convo.validate", payload)
            if subcmd == "simulate":
                slots = read_json_arg(args.slots) if args.slots else {}
                return service.dispatch_operation(
                    "convo.simulate",
                    {
                        "target": args.target,
                        "speakerKind": args.speaker,
                        "addresseeKind": args.addressee,
                        "targetKind": args.target_actor,
                        "style": args.style,
                        "locale": args.locale,
                        "resultOutcome": args.outcome,
                        "slotValues": slots,
                    },
                )
            if subcmd == "change":
                op_name = "convo.change.apply" if args.action == "apply" else "convo.change.preview"
                doc_arg = args.document or args.spec
                payload = {
                    "operation": args.operation,
                    "target": args.target,
                    "destPath": args.dest,
                    "document": read_json_arg(doc_arg) if doc_arg else None,
                    "patch": read_json_arg(args.patch) if args.patch else None,
                    "plan": read_json_arg(args.plan) if args.plan else None,
                    "sources": args.sources,
                    "requestedOwner": args.owner,
                    "requestedIdentity": (
                        {
                            **({"namespace": args.namespace} if args.namespace else {}),
                            **({"id": args.family_id} if args.family_id else {}),
                        }
                        or None
                    ),
                    "expectedFingerprint": args.expected_fingerprint,
                    "overwrite": bool(args.overwrite),
                    "removeSource": not bool(args.keep_source),
                    "pruneSource": bool(args.prune_source),
                    "allowLegacySchema": bool(args.allow_legacy),
                }
                return service.dispatch_operation(op_name, payload)
            if subcmd == "build":
                op_name = "convo.build.apply" if args.action == "apply" else "convo.build.preview"
                return service.dispatch_operation(
                    op_name,
                    {
                        "owner": args.owner,
                        "checkDeterminism": bool(args.check_determinism),
                    },
                )
            if subcmd == "audit":
                return service.dispatch_operation(
                    "convo.audit",
                    {
                        "checkDeterminism": bool(args.check_determinism),
                        "requireAllOwners": not bool(args.no_require_all_owners),
                    },
                )
            raise ValueError(f"unknown convo command: {subcmd}")
        raise ValueError(f"unsupported command: {command}")
    except (CompileError, OSError, ValueError, json.JSONDecodeError) as error:
        return {
            "ok": False,
            "diagnostics": [{"severity": "error", "message": str(error)}],
            "writes": [],
        }


__all__ = [
    "add_repo_override_args",
    "dispatch_convo_cli",
    "effective_repo_arg",
    "read_json_arg",
    "register_workspace_and_convo_subparsers",
]
