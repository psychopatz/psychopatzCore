"""Command-line client for the real-Lua semantic dialogue harness."""

from __future__ import annotations

import argparse
import json
from copy import deepcopy
from pathlib import Path
import sys

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.translation_support import normalize_language
from tools.semantic_harness.inspection.rendering import print_result as _print_result
from ..inspection.response_candidate import preview_authored_variant
from ..inspection.response_turn_trace import inspect_response_turn
from ..inspection.response_selection_coverage import selection_coverage
from ..inspection.response_source_lineage import inspect_codebuilder_lineage
from ..inspection.response_translation_coverage import translation_coverage
from ..inspection.response_observatory import (
    run_quality_matrix, source_evidence, source_evidence_from_paths,
    review_variant_proposal, compare_quality_reports,
)
from tools.semantic_harness.testing.runner import ConflictLedger, load_case, run_case
from tools.semantic_harness.providers.mod_manager import ModManagerError
from tools.semantic_harness.runtime.config import ConfigurationError
from tools.semantic_harness.runtime.config import HarnessConfig, discover_mod_manager
from tools.semantic_harness.runtime.scenario import load_scenario
from tools.semantic_harness.runtime.save_browser import SavedWorldBrowser
from tools.semantic_harness.runtime.save_catalog import SaveCatalog
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.transport.process import HarnessError
from tools.semantic_harness.core.activity import (
    ActivityLog,
    default_activity_path,
    format_activity_event,
)

PARSER_DESCRIPTION = "Tkinter chat UI and CLI for the real-Lua semantic dialogue harness."
AUTHORING_OPERATIONS = (
    "list_datasets",
    "search_datasets",
    "show_dataset",
    "validate_dataset",
    "list_blocks",
    "search_blocks",
    "validate_blocks",
    "validate_codeblocks",
    "workflow_preview",
    "workflow_generate",
    "adapt_dataset",
)
CLI_OPERATIONS = (
    "discover_saves",
    "inspect_save",
    "save",
    "list_players",
    "list_factions",
    "list_communities",
    "search_npcs",
    "load_saved_pair",
    "inspect_player",
    "inspect_npc",
    "inspect_inventories",
    "inspect_relationship",
    "inspect_dossier",
    "inspect_interaction_history",
    "gift",
    "recruit",
    "propose",
    "working_world_diff",
    "reset_world",
    "reset_turn",
    "reset_conversation",
    "reset_actor",
    "reload_save",
    "run_semantic_tests",
    "semantic_test_files",
    "sweep_plan",
    "sweep_run",
    "sweep_status",
    "sweep_report",
    "sweep_replay",
    "variation_audit",
    "input",
    "ping",
    "capabilities",
)


def _selected_mods(arguments: argparse.Namespace) -> tuple[str, ...] | None:
    values = getattr(arguments, "mods", None) or ()
    selected = tuple(
        item.strip()
        for value in values
        for item in str(value).split(",")
        if item.strip()
    )
    return selected or None


def _selection_manager(arguments: argparse.Namespace):
    return discover_mod_manager(
        repository=getattr(arguments, "repository", None),
        core_repository=getattr(arguments, "core_repository", None),
        dynamic_trading_repository=getattr(
            arguments, "dynamic_trading_repository", None
        ),
        provider_roots=tuple(getattr(arguments, "provider_root", None) or ()),
        cwd=Path.cwd(),
    )


def _save_file(value: str | Path) -> Path:
    path = Path(value).expanduser()
    if path.is_dir():
        path = path / "global_mod_data.bin"
    return path.resolve()


def _actor_row(row: dict) -> dict:
    return {
        key: row.get(key)
        for key in (
            "id", "label", "source", "factionID", "communityID", "role",
            "isFollower", "isHostile", "isTrader", "provider",
        )
        if row.get(key) not in (None, "")
    }


def _group_row(row: dict) -> dict:
    output = {
        key: row.get(key)
        for key in (
            "id", "label", "source", "membershipSource", "status",
            "leaderNPCID", "ownerPlayerKey", "factionID", "communityID",
            "archetypeID", "roles", "memberRoles", "roleByMemberID",
            "standing", "diplomacy", "provider", "providerID",
            "providerOverlay",
        )
        if row.get(key) not in (None, "", {}, [])
    }
    output["memberIDs"] = list(row.get("memberIDs") or [])
    return output


def _browser_summary(browser: dict, *, query: str = "") -> dict:
    actors = browser.get("categories", {}).get("All NPCs", [])
    if query:
        needle = query.casefold()
        actors = [
            row for row in actors
            if needle in str(row.get("label") or row.get("id") or "").casefold()
        ]
    return {
        "schema": "semantic.cli.saved_world_projection.v1",
        "source": browser.get("source", "MISSING"),
        "sourceID": browser.get("sourceID"),
        "saveName": browser.get("saveName"),
        "worldVersion": browser.get("worldVersion"),
        "counts": browser.get("counts", {}),
        "players": [
            _actor_row(row) for row in browser.get("players", [])
            if isinstance(row, dict)
        ],
        "factions": [
            _group_row(row) for row in browser.get("factions", [])
            if isinstance(row, dict)
        ],
        "communities": [
            _group_row(row) for row in browser.get("communities", [])
            if isinstance(row, dict)
        ],
        "npcs": [_actor_row(row) for row in actors if isinstance(row, dict)],
        "providerActors": [
            _actor_row(row) for row in browser.get("providerActors", [])
            if isinstance(row, dict)
        ],
    }


def _run_offline_cli_operation(
    arguments: argparse.Namespace,
    repository: Path,
) -> dict | None:
    offline_flags = (
        arguments.discover_saves,
        arguments.inspect_save,
        arguments.list_players,
        arguments.list_factions,
        arguments.list_communities,
        arguments.search_npcs is not None,
    )
    if not any(offline_flags):
        return None
    core_repository = (
        Path(arguments.core_repository).expanduser().resolve()
        if arguments.core_repository
        else repository.parent / "psychopatzCore"
    )
    catalog = SaveCatalog(core_repository=core_repository)
    if arguments.discover_saves:
        discovered = catalog.discover()
        entries = []
        for entry in discovered.get("saves", []):
            if not isinstance(entry, dict):
                continue
            entries.append(
                {
                    key: entry.get(key)
                    for key in (
                        "source", "sourceID", "path", "mode", "saveName",
                        "worldVersion", "formatCompatibility", "fileBytes",
                        "fileMtimeMs",
                    )
                    if entry.get(key) not in (None, "")
                }
            )
        return {
            "ok": True,
            "type": "saved_world_catalog",
            "catalog": entries,
            "rejected": discovered.get("rejected", []),
        }
    raw_path = arguments.inspect_save or arguments.save
    if not raw_path:
        raise ValueError("save path required for offline world operation")
    save_path = _save_file(raw_path)
    browser = SavedWorldBrowser(core_repository=core_repository).browse(save_path)
    if arguments.inspect_save:
        entry = catalog.inspect(save_path).to_dict()
        return {
            "ok": True,
            "type": "saved_world_inspection",
            "save": entry,
            "world": _browser_summary(browser),
        }
    summary = _browser_summary(
        browser,
        query=arguments.search_npcs or "",
    )
    if arguments.list_players:
        return {"ok": True, "type": "saved_players", "players": summary["players"], "saveName": summary["saveName"]}
    if arguments.list_factions:
        return {"ok": True, "type": "saved_factions", "factions": summary["factions"], "saveName": summary["saveName"]}
    if arguments.list_communities:
        return {"ok": True, "type": "saved_communities", "communities": summary["communities"], "saveName": summary["saveName"]}
    return {
        "ok": True,
        "type": "saved_npc_search",
        "query": arguments.search_npcs,
        "npcs": summary["npcs"],
        "saveName": summary["saveName"],
    }


def _bounded_actor_state(state: dict) -> dict:
    scenario = state.get("scenario") if isinstance(state, dict) else {}
    scenario = scenario if isinstance(scenario, dict) else {}
    return {
        "schema": "semantic.cli.actor_state.v1",
        "player": deepcopy(scenario.get("player") or {}),
        "npc": deepcopy(scenario.get("npc") or {}),
    }


def _inventory_items(value: dict | None) -> dict[str, dict]:
    inventory = value if isinstance(value, dict) else {}
    raw = inventory.get("items", {})
    if isinstance(raw, dict):
        return {str(key): item for key, item in raw.items() if isinstance(item, dict)}
    if isinstance(raw, list):
        output = {}
        for index, item in enumerate(raw):
            if not isinstance(item, dict):
                continue
            item_id = str(item.get("itemID") or item.get("id") or f"item-{index}")
            output[item_id] = item
        return output
    return {}


def _actor_state_diff(before: dict, after: dict, source_kind: str) -> dict:
    patches: list[dict] = []
    for actor in ("player", "npc"):
        left = before.get(actor) if isinstance(before.get(actor), dict) else {}
        right = after.get(actor) if isinstance(after.get(actor), dict) else {}
        if actor == "npc":
            fields = (
                "baselineApproval", "baselineRespect", "approval", "respect",
                "familiarity", "state", "previousState", "revision",
                "interactionRevision", "bond", "recruited", "ownedByPlayer",
                "factionID", "communityID",
            )
            for field in fields:
                if left.get(field) != right.get(field):
                    patches.append({
                        "path": f"npc.{field}",
                        "imported": deepcopy(left.get(field)),
                        "effective": deepcopy(right.get(field)),
                        "source": "HARNESS_MUTATION",
                        "baseSource": source_kind,
                    })
        before_items = _inventory_items(left.get("inventory"))
        after_items = _inventory_items(right.get("inventory"))
        for item_id in sorted(set(before_items) | set(after_items)):
            before_item = before_items.get(item_id)
            after_item = after_items.get(item_id)
            before_stack = before_item.get("stack") if isinstance(before_item, dict) else 0
            after_stack = after_item.get("stack") if isinstance(after_item, dict) else 0
            if before_stack != after_stack:
                patches.append({
                    "path": f"{actor}.inventory.items.{item_id}.stack",
                    "imported": before_stack,
                    "effective": after_stack,
                    "source": "HARNESS_MUTATION",
                    "baseSource": source_kind,
                })
    return {
        "schema": "semantic.harness_working_world.diff.v1",
        "source": source_kind,
        "scope": "bounded actor state",
        "patches": patches[:512],
        "changed": bool(patches),
    }


def _resolve_authoring_source(
    service: SemanticLabAuthoringService,
    value: str,
) -> Path:
    source = Path(value).expanduser()
    if not source.is_absolute():
        source = service.repository / source
    return source.resolve()


def _run_authoring_operation(
    arguments: argparse.Namespace,
    service: SemanticLabAuthoringService,
) -> dict | None:
    if arguments.list_datasets:
        return {
            "ok": True,
            "type": "dataset_library",
            "sources": service.list_dataset_sources(),
        }
    if arguments.search_datasets is not None:
        return {
            "ok": True,
            "type": "dataset_search",
            "query": arguments.search_datasets,
            "results": service.search_dataset(arguments.search_datasets),
        }
    if arguments.show_dataset:
        source_id = arguments.show_dataset
        source = next(
            (item for item in service.list_dataset_sources() if item["id"] == source_id),
            None,
        )
        if source is None:
            raise ValueError(f"unknown canonical dataset source: {source_id}")
        return {
            "ok": True,
            "type": "dataset",
            "source": source,
            "entries": service.search_dataset("", source_id=source_id, limit=64),
        }
    if arguments.validate_dataset:
        source_id = arguments.validate_dataset
        return service.preview_dataset_edit(
            source_id,
            service.load_dataset_document(source_id),
        )
    if arguments.list_blocks:
        return service.list_semantic_blocks()
    if arguments.search_blocks is not None:
        return {
            "ok": True,
            "type": "semantic_block_search",
            "query": arguments.search_blocks,
            "results": service.search_semantic_blocks(arguments.search_blocks),
        }
    if arguments.validate_blocks is not None:
        block_ids = [
            value.strip()
            for value in arguments.validate_blocks.split(",")
            if value.strip()
        ]
        return service.validate_semantic_blocks(block_ids)
    if arguments.validate_codeblocks:
        return service.validate_codeblock_source(
            _resolve_authoring_source(service, arguments.validate_codeblocks)
        )
    if arguments.workflow_preview or arguments.workflow_generate:
        if not arguments.workflow_blocks:
            raise ValueError("workflow operations require --workflow-blocks IDS")
        block_ids = [
            value.strip()
            for value in arguments.workflow_blocks.split(",")
            if value.strip()
        ]
        if arguments.workflow_preview:
            return service.preview_workflow(arguments.workflow_preview, block_ids)
        return service.generate_workflow(
            arguments.workflow_generate,
            block_ids,
            approved=arguments.approve_workflow,
        )
    if arguments.adapt_dataset:
        if not arguments.dataset_source or not arguments.dataset_manifest:
            raise ValueError("--adapt-dataset requires --dataset-source and --dataset-manifest")
        return service.preview_external_dataset(
            arguments.adapt_dataset,
            _resolve_authoring_source(service, arguments.dataset_source),
            _resolve_authoring_source(service, arguments.dataset_manifest),
        )
    return None


def cli(arguments: argparse.Namespace) -> int:
    try:
        if (
            getattr(arguments, "list_mods", False)
            or getattr(arguments, "list_presets", False)
        ):
            manager = _selection_manager(arguments)
            _print_result(
                manager.describe()
                if arguments.list_mods
                else {
                    "schema": "semantic.harness.selection_presets.v1",
                    "presets": list(manager.presets()),
                },
                arguments.jsonl,
            )
            return 0

        if getattr(arguments, "show_selection", False):
            config = HarnessConfig.discover(
                repository=getattr(arguments, "repository", None),
                core_repository=getattr(arguments, "core_repository", None),
                dynamic_trading_repository=getattr(
                    arguments, "dynamic_trading_repository", None
                ),
                provider_roots=tuple(getattr(arguments, "provider_root", None) or ()),
                mods=_selected_mods(arguments),
                preset=getattr(arguments, "preset", None),
                profile=getattr(arguments, "profile", "pnc"),
            )
            _print_result(config.activation_plan or {}, arguments.jsonl)
            return 0

        repository = Path(arguments.repository) if arguments.repository else None
        authoring_service = SemanticLabAuthoringService(
            repository=repository,
            runtime_root=repository,
            core_repository=(
                Path(arguments.core_repository)
                if getattr(arguments, "core_repository", None)
                else None
            ),
            dynamic_trading_repository=(
                Path(arguments.dynamic_trading_repository)
                if getattr(arguments, "dynamic_trading_repository", None)
                else None
            ),
        )
        activity_log = ActivityLog(
            path=default_activity_path(
                authoring_service.repository,
                getattr(arguments, "activity_log", None),
            ),
            client=getattr(arguments, "activity_client", None) or "cli",
        )
        activity_log.record(
            "cli",
            "command_start",
            mode=(
                "case"
                if arguments.case
                else "authoring"
                if any(
                    getattr(arguments, name, None)
                    for name in AUTHORING_OPERATIONS
                )
                else "semantic"
            ),
        )
        authoring_report = _run_authoring_operation(arguments, authoring_service)
        if authoring_report is not None:
            _print_result(authoring_report, arguments.jsonl)
            return 0 if authoring_report.get("ok") is True else 2
        offline_report = _run_offline_cli_operation(
            arguments, authoring_service.repository
        )
        if offline_report is not None:
            _print_result(offline_report, arguments.jsonl)
            return 0 if offline_report.get("ok") is True else 2
        worker_kwargs = {
            "lua_bin": arguments.lua,
            "repository": Path(arguments.repository) if arguments.repository else None,
            "core_repository": Path(arguments.core_repository) if arguments.core_repository else None,
            "profile": arguments.profile,
            "dynamic_trading_repository": (
                Path(arguments.dynamic_trading_repository)
                if getattr(arguments, "dynamic_trading_repository", None)
                else None
            ),
            "provider_roots": tuple(getattr(arguments, "provider_root", None) or ()),
            "mods": _selected_mods(arguments),
            "preset": getattr(arguments, "preset", None),
            "startup_timeout": arguments.startup_timeout,
            "request_timeout": arguments.timeout,
            "shutdown_timeout": arguments.shutdown_timeout,
            "activity_log": activity_log,
        }

        activity_seen = 0

        def emit_activity() -> None:
            nonlocal activity_seen
            if not arguments.trace:
                return
            records = activity_log.snapshot(activity_seen)
            for record in records:
                print(format_activity_event(record), file=sys.stderr)
            if records:
                activity_seen = int(records[-1].get("sequence", activity_seen))

        if arguments.compare_response_reports:
            reports = []
            for source in arguments.compare_response_reports:
                path = Path(source).expanduser()
                if path.stat().st_size > 64 * 1024:
                    raise ValueError("comparison report exceeds 64 KiB")
                reports.append(json.loads(path.read_text(encoding="utf-8")))
            report = compare_quality_reports(*reports)
            _print_result(report, arguments.jsonl)
            return 0 if report["ok"] else 3
        if arguments.response_quality_matrix:
            path = Path(arguments.response_quality_matrix).expanduser()
            if path.stat().st_size > 64 * 1024:
                raise ValueError("quality matrix file exceeds 64 KiB")
            loaded = json.loads(path.read_text(encoding="utf-8"))
            cases = loaded.get("cases") if isinstance(loaded, dict) else loaded
            report = run_quality_matrix(
                cases,
                worker_factory=lambda scenario: LuaSemanticWorker(
                    scenario, **worker_kwargs
                ),
            )
            report["sourceEvidence"] = source_evidence_from_paths(
                authoring_service.repository,
                worker_kwargs.get("core_repository")
                    or (authoring_service.repository.parent / "psychopatzCore"),
            )
            _print_result(report, arguments.jsonl)
            return 3 if report["failed"] or report["truncated"] else 0
        if arguments.case:
            report = run_case(load_case(Path(arguments.case)), **worker_kwargs)
            _print_result(report.as_dict(), arguments.jsonl)
            emit_activity()
            return 0 if report.conflicts == [] else 3
        if (
            getattr(arguments, "sweep_plan", False)
            or getattr(arguments, "sweep_run", False)
            or getattr(arguments, "sweep_status", False)
            or getattr(arguments, "sweep_report", False)
            or getattr(arguments, "sweep_replay", False)
        ):
            from tools.semantic_harness.testing.sweep_service import DialogueQualitySweepService

            service = DialogueQualitySweepService(
                worker_factory=lambda sc: LuaSemanticWorker(sc, **worker_kwargs)
            )
            sweep_id = getattr(arguments, "sweep_id", None) or "dialogue_sweep_v1"

            if arguments.sweep_plan:
                plan = service.plan_sweep(
                    strategy=getattr(arguments, "sweep_strategy", None) or "smoke",
                    sweep_id=sweep_id,
                    max_cases=getattr(arguments, "sweep_max_cases", 512) or 512,
                    surfaces=getattr(arguments, "sweep_surfaces", None),
                    languages=getattr(arguments, "sweep_languages", None) or ("EN", "TL"),
                )
                report = {
                    "ok": True,
                    "type": "sweep_plan",
                    "sweepID": plan.sweep_id,
                    "strategy": plan.strategy,
                    "planDigest": plan.plan_digest,
                    "totalCases": plan.total_cases,
                    "estimatedBatches": plan.estimated_batches,
                    "cases": [c.to_dict() for c in plan.cases[:32]],
                    "truncated": len(plan.cases) > 32,
                }
                _print_result(report, arguments.jsonl)
                emit_activity()
                return 0

            if arguments.sweep_run:
                plan = service.plan_sweep(
                    strategy=getattr(arguments, "sweep_strategy", None) or "smoke",
                    sweep_id=sweep_id,
                    max_cases=getattr(arguments, "sweep_max_cases", 512) or 512,
                    surfaces=getattr(arguments, "sweep_surfaces", None),
                    languages=getattr(arguments, "sweep_languages", None) or ("EN", "TL"),
                )
                manifest = service.run_sweep(
                    plan,
                    batch_size=getattr(arguments, "sweep_batch_size", 64) or 64,
                )
                report = manifest.to_dict()
                _print_result(report, arguments.jsonl)
                emit_activity()
                return 0 if manifest.status == "COMPLETED" else 3

            if arguments.sweep_status:
                manifest = service.load_manifest(sweep_id)
                _print_result(manifest.to_dict(), arguments.jsonl)
                emit_activity()
                return 0

            if arguments.sweep_report:
                if getattr(arguments, "sweep_bundle", False):
                    bundle = service.generate_review_bundle(sweep_id)
                    _print_result(bundle, arguments.jsonl)
                    emit_activity()
                    return 0
                if getattr(arguments, "sweep_reachability", False):
                    reachability = service.generate_reachability_report(sweep_id)
                    _print_result(reachability.to_dict(), arguments.jsonl)
                    emit_activity()
                    return 0
                if getattr(arguments, "sweep_sentences", False):
                    rows = service.load_evidence_rows(sweep_id)
                    service.quality_analyzer.analyze_run(rows)
                    lang_filter = getattr(arguments, "sweep_language", None)
                    if lang_filter:
                        rows = [
                            r for r in rows
                            if r.get("identity", {}).get("language", "").upper() == lang_filter.upper()
                        ]
                    flag_filter = getattr(arguments, "sweep_flag", None)
                    if flag_filter:
                        rows = [
                            r for r in rows
                            if any(f.get("name") == flag_filter for f in r.get("quality", {}).get("flags", []))
                        ]
                    _print_result({
                        "ok": True,
                        "type": "sweep_sentences",
                        "sweepID": sweep_id,
                        "count": len(rows),
                        "sentences": rows,
                    }, arguments.jsonl)
                    emit_activity()
                    return 0
                cluster_report = service.generate_cluster_report(sweep_id)
                filtered = cluster_report.filter_by(
                    severity=getattr(arguments, "sweep_severity", None),
                    flag=getattr(arguments, "sweep_flag", None),
                    pool=getattr(arguments, "sweep_pool", None),
                    source=getattr(arguments, "sweep_source", None),
                )
                if getattr(arguments, "sweep_language", None):
                    lang_req = arguments.sweep_language.upper()
                    filtered = [c for c in filtered if lang_req in c.languages]
                rep_dict = cluster_report.to_dict()
                rep_dict["clusters"] = [c.to_dict() for c in filtered]
                _print_result(rep_dict, arguments.jsonl)
                emit_activity()
                return 0 if cluster_report.flagged_rows == 0 else 1

            if arguments.sweep_replay:
                manifest = service.load_manifest(sweep_id)
                cluster_report = service.generate_cluster_report(sweep_id)
                case_id_arg = getattr(arguments, "sweep_case_id", None)
                cluster_id_arg = getattr(arguments, "sweep_cluster_id", None)
                if case_id_arg:
                    case_ids = [case_id_arg]
                elif cluster_id_arg:
                    case_ids = cluster_report.get_affected_case_ids([cluster_id_arg])
                else:
                    case_ids = cluster_report.get_affected_case_ids()
                plan = service.plan_sweep(
                    strategy=manifest.strategy,
                    sweep_id=sweep_id,
                    max_cases=manifest.total_cases,
                )
                replay_plan = service.plan_replay(plan, case_ids)
                replay_manifest = service.run_sweep(
                    replay_plan,
                    batch_size=getattr(arguments, "sweep_batch_size", 64) or 64,
                )
                _print_result(replay_manifest.to_dict(), arguments.jsonl)
                emit_activity()
                return 0 if replay_manifest.status == "COMPLETED" else 3
        if getattr(arguments, "variation_audit", False):
            from tools.semantic_harness.codebuilder.variation_auditor import (
                audit_corpus,
                render_markdown_ledger,
            )

            report = audit_corpus(repository=authoring_service.repository)
            if getattr(arguments, "variation_audit_shard", None):
                shard_filter = arguments.variation_audit_shard
                report.records = [
                    r for r in report.records if shard_filter in r.source_shard
                ]
            if getattr(arguments, "variation_audit_under_10", False):
                report.records = [
                    r for r in report.records if r.phrase_count < 10
                ]
            if getattr(arguments, "variation_audit_json", False) or arguments.jsonl:
                _print_result(report.to_dict(), arguments.jsonl)
            elif getattr(arguments, "variation_audit_ledger", False):
                print(render_markdown_ledger(report), end="")
            else:
                _print_result({
                    "total_families": report.total_families,
                    "total_styles": report.total_styles,
                    "under_10_count": report.under_10_count,
                    "eligible_under_10_count": report.eligible_under_10_count,
                    "classifications": report.classification_counts,
                    "phrase_distribution": report.phrase_distribution,
                }, False)
            emit_activity()
            return 0
        if arguments.run_semantic_tests or arguments.semantic_test_files:
            from tools.semantic_harness.testing.loader import discover_cases, load_cases_from_file
            from tools.semantic_harness.testing.executor import execute_case

            cases = []
            if arguments.semantic_test_files:
                for f in arguments.semantic_test_files:
                    cases.extend(load_cases_from_file(Path(f).resolve()))
            else:
                fixtures_dir = (
                    authoring_service.core_repository
                    / "tools/semantic_harness/fixtures/v1"
                )
                cases.extend(discover_cases([fixtures_dir]))

            filtered = [
                c for c in cases
                if c.matches_filter(
                    suite=arguments.semantic_test_suite,
                    pattern=arguments.semantic_test_filter,
                )
            ]
            results = [
                execute_case(
                    c,
                    worker_factory=lambda sc: LuaSemanticWorker(sc, **worker_kwargs),
                )
                for c in filtered
            ]
            passed = sum(1 for r in results if r.passed)
            failed = len(results) - passed
            report = {
                "ok": failed == 0,
                "passed": passed,
                "failed": failed,
                "total": len(results),
                "cases": [
                    {
                        "id": r.case.case_id,
                        "suite": r.case.suite,
                        "passed": r.passed,
                        "duration": round(r.duration, 3),
                        "failures": [str(f) for f in r.failures],
                        "error": r.error,
                    }
                    for r in results
                ],
            }
            _print_result(report, arguments.jsonl)
            emit_activity()
            return 0 if failed == 0 else 3
        scenario = load_scenario(Path(arguments.scenario) if arguments.scenario else None)
        if arguments.language:
            scenario.setdefault("runtime", {})["language"] = arguments.language.upper()
        with LuaSemanticWorker(
            scenario,
            **worker_kwargs,
        ) as worker:
            emit_activity()
            if arguments.ping:
                _print_result(worker.ping(), arguments.jsonl)
                return 0
            if arguments.capabilities:
                _print_result(worker.capabilities(), arguments.jsonl)
                return 0
            # Observatory uses the same production Lua worker as Studio and
            # conversation replay; never scans or reinterprets Lua in Python.
            if arguments.preview_response_proposal:
                path = Path(arguments.preview_response_proposal).expanduser()
                if path.stat().st_size > 16 * 1024:
                    raise ValueError("candidate proposal exceeds 16 KiB")
                proposal = json.loads(path.read_text(encoding="utf-8"))
                result = preview_authored_variant(
                    proposal, repository=authoring_service.repository,
                )
                _print_result(result, arguments.jsonl)
                return 0 if result["ok"] else 3
            if arguments.review_response_proposal:
                path = Path(arguments.review_response_proposal).expanduser()
                if path.stat().st_size > 16 * 1024:
                    raise ValueError("proposal file exceeds 16 KiB")
                proposal = json.loads(path.read_text(encoding="utf-8"))
                result = review_variant_proposal(worker, proposal)
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0 if result["ok"] else 3
            if arguments.response_translation_coverage:
                result = translation_coverage(
                    worker, arguments.response_translation_coverage,
                    repository=authoring_service.repository,
                )
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0 if result["ok"] else 3
            if arguments.response_codebuilder_lineage:
                result = inspect_codebuilder_lineage(
                    worker, arguments.response_codebuilder_lineage,
                    authoring_service=authoring_service,
                )
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0 if result["ok"] else 3
            if arguments.response_selection_coverage:
                path = Path(arguments.response_selection_coverage).expanduser()
                if path.stat().st_size > 16 * 1024:
                    raise ValueError("selection coverage file exceeds 16 KiB")
                request = json.loads(path.read_text(encoding="utf-8"))
                result = selection_coverage(worker, request)
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0
            if arguments.inspect_response_turn:
                if len(arguments.inspect_response_turn) > 200:
                    raise ValueError("observed utterance exceeds 200 characters")
                result = inspect_response_turn(
                    worker, worker.input(arguments.inspect_response_turn),
                )
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0
            if arguments.response_pools is not None:
                result = worker.response_pool_list(
                    filter=arguments.response_pools,
                    offset=arguments.response_offset,
                    limit=arguments.response_limit,
                )
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0
            if arguments.response_pool:
                result = worker.response_pool_detail(
                    arguments.response_pool,
                    offset=arguments.response_offset,
                    limit=arguments.response_limit,
                )
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0
            if arguments.explain_response_pool:
                projected = {}
                if arguments.response_context_file:
                    path = Path(arguments.response_context_file).expanduser()
                    if path.stat().st_size > 16 * 1024:
                        raise ValueError("response context file exceeds 16 KiB")
                    projected = json.loads(path.read_text(encoding="utf-8"))
                    if not isinstance(projected, dict):
                        raise ValueError("response context must be an object")
                result = worker.explain_response_selection(
                    arguments.explain_response_pool,
                    projected,
                    arguments.response_salt,
                )
                result["sourceEvidence"] = source_evidence(worker)
                _print_result(result, arguments.jsonl)
                return 0

            ledger = ConflictLedger() if arguments.audit else None
            if arguments.load_saved_pair and not arguments.save:
                raise ValueError("--load-saved-pair requires --save")
            baseline_actor_state: dict | None = None
            source_kind = "FIXTURE"
            if arguments.save or arguments.reload_save:
                if not arguments.save:
                    raise ValueError("--reload-save requires --save")
                save_path = _save_file(arguments.save)
                loaded = worker.import_saved_selection(
                    save_path,
                    player_uuid=arguments.player,
                    npc_id=arguments.npc,
                )
                source_kind = str(
                    loaded.get("sourceSnapshot", {})
                    .get("metadata", {})
                    .get("sourceKind", "SAVE")
                ).upper()
                loaded_state = _bounded_actor_state(
                    worker.inspect_actor_state()
                )
                baseline_actor_state = deepcopy(loaded_state)
                _print_result(
                    {
                        "ok": True,
                        "type": "saved_pair_loaded",
                        "source": source_kind,
                        "save": str(save_path),
                        "player": loaded_state.get("player", {}),
                        "npc": loaded_state.get("npc", {}),
                    },
                    arguments.jsonl,
                )
                emit_activity()
            if arguments.talk_start is not None:
                result = worker.talk_start(
                    arguments.talk_start, arguments.talk_utterance
                )
                _print_result(result, arguments.jsonl)
                emit_activity()
            if arguments.talk_matrix:
                result = worker.talk_matrix(text=arguments.talk_utterance)
                _print_result(result, arguments.jsonl)
                emit_activity()
            if arguments.snapshot:
                _print_result(worker.snapshot(), arguments.jsonl)
                emit_activity()
            for value in arguments.input:
                result = worker.input(value)
                if ledger is not None:
                    ledger.add(result)
                _print_result(result, arguments.jsonl)
                emit_activity()
            for item in arguments.gift or []:
                quantity = max(1, min(999, int(arguments.gift_quantity)))
                result = worker.input(
                    f"here's {quantity} {item} for you"
                )
                if ledger is not None:
                    ledger.add(result)
                _print_result(
                    {
                        "ok": True,
                        "type": "gift",
                        "item": item,
                        "quantity": quantity,
                        "response": result,
                    },
                    arguments.jsonl,
                )
                emit_activity()
            if arguments.recruit:
                result = worker.input("Would you like to join us?")
                if ledger is not None:
                    ledger.add(result)
                _print_result(
                    {"ok": True, "type": "recruitment", "response": result},
                    arguments.jsonl,
                )
                emit_activity()
            if arguments.propose:
                result = worker.relationship_proposal(arguments.npc)
                _print_result(
                    {"ok": True, "type": "relationship_proposal", "response": result},
                    arguments.jsonl,
                )
                emit_activity()
            reset_result = None
            if arguments.reset_world:
                reset_result = worker.reset_working_world()
            elif arguments.reset_turn:
                reset_result = worker.reset_turn()
            elif arguments.reset_conversation:
                reset_result = worker.reset_conversation()
            elif arguments.reset_actor:
                reset_result = worker.reset_selected_actor(arguments.reset_actor)
            if reset_result is not None:
                current = _bounded_actor_state(worker.inspect_actor_state())
                _print_result(
                    {
                        "ok": True,
                        "type": (
                            "reset_world" if arguments.reset_world
                            else "reset_turn" if arguments.reset_turn
                            else "reset_conversation" if arguments.reset_conversation
                            else "reset_actor"
                        ),
                        "actor": arguments.reset_actor,
                        "state": current,
                        "source": source_kind,
                    },
                    arguments.jsonl,
                )
                emit_activity()
            inspection_flags = (
                arguments.inspect_player,
                arguments.inspect_npc,
                arguments.inspect_inventories,
                arguments.inspect_relationship,
                arguments.inspect_social_context,
                arguments.inspect_dossier,
                arguments.inspect_interaction_history,
            )
            if any(inspection_flags):
                current = _bounded_actor_state(worker.inspect_actor_state())
                inspection = {
                    "ok": True,
                    "type": "actor_inspection",
                    "source": source_kind,
                }
                if arguments.inspect_player:
                    inspection["player"] = current["player"]
                if arguments.inspect_npc:
                    inspection["npc"] = current["npc"]
                if arguments.inspect_inventories:
                    inspection["inventories"] = {
                        "player": current["player"].get("inventory", {}),
                        "npc": current["npc"].get("inventory", {}),
                    }
                if arguments.inspect_relationship:
                    inspection["relationship"] = current["npc"].get(
                        "relationship", {}
                    )
                if arguments.inspect_social_context:
                    inspection["socialContext"] = current["npc"].get(
                        "socialContext", {}
                    )
                if arguments.inspect_dossier or arguments.inspect_interaction_history:
                    dossier_result = worker.inspect_npc_dossier()
                    if arguments.inspect_dossier:
                        inspection["dossier"] = dossier_result.get(
                            "npcDossier", {}
                        )
                    if arguments.inspect_interaction_history:
                        inspection["interactionHistory"] = dossier_result.get(
                            "relationshipHistory", {}
                        )
                _print_result(inspection, arguments.jsonl)
                emit_activity()
            if arguments.working_world_diff:
                current = _bounded_actor_state(worker.inspect_actor_state())
                if baseline_actor_state is None:
                    baseline_actor_state = deepcopy(current)
                _print_result(
                    _actor_state_diff(
                        baseline_actor_state,
                        current,
                        source_kind,
                    ),
                    arguments.jsonl,
                )
                emit_activity()
            if arguments.interactive:
                for line in sys.stdin:
                    value = line.strip()
                    if value:
                        result = worker.input(value)
                        if ledger is not None:
                            ledger.add(result)
                        _print_result(result, arguments.jsonl)
                        emit_activity()
            if arguments.audit:
                conflicts = ledger.report() if ledger is not None else []
                _print_result(
                    {"type": "audit", "ok": not conflicts, "conflicts": conflicts},
                    arguments.jsonl,
                )
                emit_activity()
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        print(f"semantic harness error: {error}", file=sys.stderr)
        return 2
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=PARSER_DESCRIPTION)
    parser.add_argument("--scenario", help="JSON scenario file")
    parser.add_argument("--case", help="JSON replay case with scenario and inputs")
    parser.add_argument("--lua", help="Lua executable; defaults to SEMANTIC_HARNESS_LUA, lua, or luajit")
    parser.add_argument("--repository", help="Project Hoomans repository")
    parser.add_argument("--core-repository", help="PsychopatzCore repository")
    parser.add_argument(
        "--profile",
        default="pnc",
        help="composition alias; use --preset or --mods for provider selection",
    )
    parser.add_argument("--preset", help="manifest-driven provider selection preset")
    parser.add_argument(
        "--mods",
        action="append",
        help="provider IDs to enable; repeat or provide a comma-separated list",
    )
    parser.add_argument(
        "--provider-root",
        action="append",
        type=Path,
        help="repository root to scan for provider manifests",
    )
    parser.add_argument("--list-mods", action="store_true")
    parser.add_argument("--list-presets", action="store_true")
    parser.add_argument("--show-selection", action="store_true")
    parser.add_argument(
        "--dynamic-trading-repository",
        help="DynamicTrading repository containing the DTCommon package",
    )
    parser.add_argument(
        "--ui-state",
        help="override the user-owned Semantic Lab window-state file",
    )
    parser.add_argument(
        "--reset-ui-state",
        action="store_true",
        help="ignore saved GUI layout state for this run and start from defaults",
    )
    parser.add_argument(
        "--activity-log",
        help="override the shared GUI/CLI activity JSONL file",
    )
    parser.add_argument(
        "--activity-client",
        default="cli",
        help="client label written to the shared activity timeline (default: cli)",
    )
    parser.add_argument(
        "--no-gui",
        "--cli",
        dest="no_gui",
        action="store_true",
        help="run inputs and print JSON",
    )
    parser.add_argument(
        "--gui",
        action="store_true",
        help="force the Tk GUI, including when a saved pair is supplied",
    )
    parser.add_argument("--interactive", action="store_true", help="read one conversation input per stdin line")
    parser.add_argument("--jsonl", action="store_true", help="emit compact one-record-per-line JSON")
    parser.add_argument("--audit", action="store_true", help="emit a bounded conflict audit after turns")
    observatory = parser.add_mutually_exclusive_group()
    observatory.add_argument(
        "--response-pools", nargs="?", const="", metavar="FILTER",
        help="page through actual registered Lua response pools, optionally filtering IDs",
    )
    observatory.add_argument(
        "--response-pool", metavar="POOL_ID",
        help="inspect one registered response pool's normalized variants",
    )
    observatory.add_argument(
        "--explain-response-pool", metavar="POOL_ID",
        help="read-only production selector explanation, without consuming history",
    )
    parser.add_argument(
        "--compare-response-reports", nargs=2, metavar=("BASELINE", "CANDIDATE"),
        help="compare bounded saved production-Lua fixture reports without replay",
    )
    parser.add_argument(
        "--response-quality-matrix", metavar="PATH",
        help="run up to eight isolated production-Lua fixture cases from JSON",
    )
    parser.add_argument(
        "--run-semantic-tests",
        action="store_true",
        help="run declarative semantic test fixtures through production Lua",
    )
    parser.add_argument(
        "--semantic-test-file",
        action="append",
        dest="semantic_test_files",
        help="specific declarative semantic test fixture file to run (repeatable)",
    )
    parser.add_argument(
        "--semantic-test-suite",
        help="filter declarative semantic tests by suite name",
    )
    parser.add_argument(
        "--semantic-test-filter",
        help="filter declarative semantic tests by substring pattern",
    )
    observatory.add_argument(
        "--response-translation-coverage", metavar="POOL_ID",
        help="inspect canonical locale-manifest membership of loaded Lua variants",
    )
    observatory.add_argument(
        "--response-codebuilder-lineage", metavar="POOL_ID",
        help="verify loaded Lua variants against canonical CodeBuilder preview",
    )
    observatory.add_argument(
        "--response-selection-coverage", metavar="PATH",
        help="actual Lua selector coverage for 1–16 explicit hypothetical contexts",
    )
    observatory.add_argument(
        "--inspect-response-turn", metavar="UTTERANCE",
        help="run one fixture turn; join real Lua text with verified registry provenance and effects",
    )
    observatory.add_argument(
        "--preview-response-proposal", metavar="PATH",
        help="isolated real-Lua localized candidate replay; no production edits",
    )
    observatory.add_argument(
        "--review-response-proposal", metavar="PATH",
        help="read-only localized variant proposal preflight; never writes source",
    )
    parser.add_argument("--response-offset", type=int, default=0)
    parser.add_argument("--response-limit", type=int, default=8)
    parser.add_argument(
        "--response-context-file", metavar="PATH",
        help="JSON object containing projected Lua response context for explanation",
    )
    parser.add_argument(
        "--response-salt", default="",
        help="deterministic selection seed; does not execute any gameplay action",
    )

    parser.add_argument(
        "--trace",
        action="store_true",
        help="write the shared harness activity timeline to stderr",
    )
    authoring = parser.add_mutually_exclusive_group()
    authoring.add_argument(
        "--list-datasets",
        action="store_true",
        help="list canonical datasets available in the Semantic Lab Dataset Library",
    )
    authoring.add_argument(
        "--search-datasets",
        metavar="QUERY",
        help="search canonical dataset entries through the Semantic Lab Dataset Library",
    )
    authoring.add_argument(
        "--show-dataset",
        metavar="SOURCE_ID",
        help="show bounded entries for a canonical Dataset Library source",
    )
    authoring.add_argument(
        "--validate-dataset",
        metavar="SOURCE_ID",
        help="validate the current canonical Dataset Library source without writing",
    )
    authoring.add_argument(
        "--list-blocks",
        action="store_true",
        help="list reusable Semantic Lab blocks and their production contracts",
    )
    authoring.add_argument(
        "--search-blocks",
        metavar="QUERY",
        help="search reusable Semantic Lab blocks",
    )
    authoring.add_argument(
        "--validate-blocks",
        metavar="IDS",
        help="validate comma-separated reusable block IDs without writing or dispatching",
    )
    authoring.add_argument(
        "--validate-codeblocks",
        metavar="PATH",
        help="validate a declarative semantic.codeblocks.v1 file without writing or dispatching",
    )
    authoring.add_argument(
        "--workflow-preview",
        metavar="SOURCE_ID",
        help="preview one canonical dataset plus a composed block selection",
    )
    authoring.add_argument(
        "--workflow-generate",
        metavar="SOURCE_ID",
        help="generate one approved workflow through the existing CodeBuilder writer",
    )
    authoring.add_argument(
        "--adapt-dataset",
        choices=("massive", "sgd"),
        metavar="ADAPTER",
        help="review one bounded external MASSIVE/SGD-style source through a build-time adapter",
    )
    parser.add_argument(
        "--dataset-source",
        metavar="PATH",
        help="external dataset source path for --adapt-dataset; never a runtime media path",
    )
    parser.add_argument(
        "--dataset-manifest",
        metavar="PATH",
        help="provenance/license manifest path for --adapt-dataset",
    )
    parser.add_argument(
        "--workflow-blocks",
        metavar="IDS",
        help="comma-separated reusable block IDs for a Semantic Lab workflow",
    )
    parser.add_argument(
        "--approve-workflow",
        action="store_true",
        help="explicitly approve --workflow-generate after its preview contract",
    )
    parser.add_argument("--doctor", action="store_true", help="run bounded headless runtime diagnostics")
    parser.add_argument("--doctor-json", action="store_true", help="emit doctor diagnostics as one JSON record")
    parser.add_argument("--snapshot", action="store_true")
    parser.add_argument(
        "--discover-saves",
        action="store_true",
        help="discover compatible offline saves and emit a bounded catalog",
    )
    parser.add_argument(
        "--inspect-save",
        metavar="PATH",
        help="inspect one save catalog entry and bounded world projection",
    )
    parser.add_argument(
        "--save",
        metavar="PATH",
        help="global_mod_data.bin or save directory for save-backed CLI work",
    )
    parser.add_argument("--player", help="saved Player UUID for --save")
    parser.add_argument("--npc", help="saved NPC ID for --save")
    parser.add_argument(
        "--load-saved-pair",
        action="store_true",
        help="load --save plus --player/--npc into the isolated worker",
    )
    parser.add_argument("--list-players", action="store_true")
    parser.add_argument("--list-factions", action="store_true")
    parser.add_argument("--list-communities", action="store_true")
    parser.add_argument("--search-npcs", metavar="QUERY")
    parser.add_argument("--inspect-player", action="store_true")
    parser.add_argument("--inspect-npc", action="store_true")
    parser.add_argument("--inspect-inventories", action="store_true")
    parser.add_argument("--inspect-relationship", action="store_true")
    parser.add_argument(
        "--inspect-dossier",
        action="store_true",
        help="show the production player-scoped NPC dossier and knowledge journal",
    )
    parser.add_argument(
        "--inspect-interaction-history",
        action="store_true",
        help="show production relationship memories and bounded interaction journal",
    )
    parser.add_argument(
        "--inspect-social-context",
        action="store_true",
        help="show production personal/faction/tactical/audience/bond/speech layers",
    )
    parser.add_argument(
        "--gift",
        action="append",
        metavar="ITEM",
        help="route one production gift by item display/full type; repeatable",
    )
    parser.add_argument("--gift-quantity", type=int, default=1)
    parser.add_argument(
        "--recruit",
        action="store_true",
        help="route the canonical production recruitment utterance",
    )
    parser.add_argument(
        "--propose",
        action="store_true",
        help="route the production relationship proposal service",
    )
    parser.add_argument("--working-world-diff", action="store_true")
    reset = parser.add_mutually_exclusive_group()
    reset.add_argument("--reset-world", action="store_true")
    reset.add_argument("--reset-turn", action="store_true")
    reset.add_argument("--reset-conversation", action="store_true")
    reset.add_argument("--reset-actor", metavar="ACTOR")
    parser.add_argument(
        "--reload-save",
        action="store_true",
        help="reread --save from disk into a fresh isolated source snapshot",
    )
    parser.add_argument("--language", type=lambda value: normalize_language(value, "--language"), help="production translation locale code")
    talk = parser.add_mutually_exclusive_group()
    talk.add_argument(
        "--talk-start",
        metavar="TARGET",
        help="start native Talk parity for current, colonist, follower, neutral, or hostile",
    )
    talk.add_argument(
        "--talk-matrix",
        action="store_true",
        help="compare native Talk startup across the production target catalog",
    )
    parser.add_argument("--talk-utterance", default="hello", help="first utterance used by --talk-start/--talk-matrix (default: hello)")
    sweep_ops = parser.add_mutually_exclusive_group()
    sweep_ops.add_argument("--sweep-plan", action="store_true", help="plan a deterministic dialogue quality sweep")
    sweep_ops.add_argument("--sweep-run", action="store_true", help="execute or resume planned sweep batches")
    sweep_ops.add_argument("--sweep-status", action="store_true", help="show manifest status of a sweep")
    sweep_ops.add_argument("--sweep-report", action="store_true", help="output defect cluster report")
    sweep_ops.add_argument("--sweep-replay", action="store_true", help="replay affected cases from clusters")
    parser.add_argument("--sweep-id", default="dialogue_sweep_v1", help="unique sweep ID")
    parser.add_argument("--sweep-strategy", default="smoke", choices=["smoke", "boundary", "pairwise", "persona", "full", "review"], help="sweep coverage strategy")
    parser.add_argument("--sweep-batch-size", type=int, default=64, help="cases per batch (<= 64)")
    parser.add_argument("--sweep-max-cases", type=int, default=512, help="maximum cases cap")
    parser.add_argument("--sweep-cluster-id", help="filter or replay specific cluster ID")
    parser.add_argument("--sweep-case-id", help="replay specific case ID")
    parser.add_argument("--sweep-severity", help="filter cluster report by severity")
    parser.add_argument("--sweep-flag", help="filter cluster report by flag name")
    parser.add_argument("--sweep-source", help="filter cluster report by canonical source owner")
    parser.add_argument("--sweep-pool", help="filter cluster report by pool ID")
    parser.add_argument("--sweep-language", help="filter cluster or sentence report by language (EN/TL)")
    parser.add_argument("--sweep-surfaces", nargs="*", help="interaction surfaces to target")
    parser.add_argument("--sweep-languages", nargs="*", help="languages to target (e.g. EN TL)")
    parser.add_argument("--sweep-bundle", action="store_true", help="emit LLM review bundle instead of cluster report")
    parser.add_argument("--sweep-reachability", action="store_true", help="emit variant reachability report")
    parser.add_argument("--sweep-sentences", action="store_true", help="output generated sentence rows instead of cluster report")
    parser.add_argument("--variation-audit", action="store_true", help="run comprehensive canonical conversation phrase variation audit")
    parser.add_argument("--variation-audit-json", action="store_true", help="emit machine-readable JSON for variation audit")
    parser.add_argument("--variation-audit-ledger", action="store_true", help="emit markdown classification ledger for variation audit")
    parser.add_argument("--variation-audit-shard", help="filter variation audit by canonical source shard")
    parser.add_argument("--variation-audit-under-10", action="store_true", help="filter variation audit to only under-10 style buckets")
    parser.add_argument("--input", action="append", default=[], help="chat input; repeatable")
    parser.add_argument("--ping", action="store_true")
    parser.add_argument("--capabilities", action="store_true")
    parser.add_argument("--timeout", type=float, default=5.0, help="per-request timeout in seconds")
    parser.add_argument("--startup-timeout", type=float, default=8.0, help="worker startup timeout in seconds")
    parser.add_argument("--shutdown-timeout", type=float, default=1.0, help="worker shutdown timeout in seconds")
    return parser
