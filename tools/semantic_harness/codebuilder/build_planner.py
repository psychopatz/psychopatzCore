"""Concurrency-safe ConvoEngine BuildPlanner with isolated determinism checks."""

from __future__ import annotations

import hashlib
import tempfile
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from . import build as _build_mod
from .conversation_compiler import (
    compile_conversation_sources,
    conversation_context_health,
    render_conversation_runtime_plan,
)
from .convo_transaction import workspace_generation_lock
from .errors import CompileError
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    generated_conversation_root,
    module_owner,
    normalize_owner,
    package_descriptor,
)
from .workspace_catalog import WorkspaceSnapshot


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(65536):
            digest.update(chunk)
    return digest.hexdigest()


def collect_generated_artifact_hashes(
    *,
    core_repository: Path,
    hoomans_repository: Path | None,
    dynamic_trading_repository: Path | None,
) -> dict[str, str]:
    """Collect deterministic content digests across owner-routed generated outputs."""
    hashes: dict[str, str] = {}
    runtime_base = hoomans_repository or core_repository
    pairs: list[tuple[str, Path]] = [(CORE_OWNER, core_repository)]
    if hoomans_repository is not None:
        pairs.append((HOOMANS_OWNER, hoomans_repository))
    if dynamic_trading_repository is not None:
        pairs.append((DT_COMMON_OWNER, dynamic_trading_repository))

    for owner, repo_root in pairs:
        conv_root = generated_conversation_root(
            runtime_base,
            owner,
            core_repository=core_repository,
            dynamic_trading_repository=dynamic_trading_repository,
            runtime_root=runtime_base,
        )
        if conv_root.is_dir():
            for lua_file in sorted(conv_root.rglob("*.lua")):
                hashes[f"lua:{owner}:{lua_file.relative_to(repo_root)}"] = sha256_file(lua_file)
        desc = package_descriptor(owner)
        trans_root = repo_root / desc.translation_relative
        for lang in ("EN", "TL"):
            lang_conv = trans_root / lang / "Conversation"
            if lang_conv.is_dir():
                for json_file in sorted(lang_conv.rglob("*.json")):
                    hashes[f"tr:{owner}:{json_file.relative_to(repo_root)}"] = sha256_file(json_file)
    return hashes


@dataclass(frozen=True)
class BuildPlan:
    """Cached, effect-free summary of a compiled ConvoEngine workspace build."""

    workspace_fingerprint: str
    model_fingerprint: str
    planned_modules: tuple[str, ...]
    report_count: int
    health_status: str


class BuildPlanner:
    """Coordinate effect-free build previews, locked writes, and isolated determinism audits."""

    def __init__(self, workspace: WorkspaceSnapshot) -> None:
        self.workspace = workspace
        self._plan_cache: dict[tuple[str, str | None], BuildPlan] = {}

    @classmethod
    def from_workspace(cls, workspace: WorkspaceSnapshot) -> "BuildPlanner":
        return cls(workspace)

    def _runtime_roots(self) -> tuple[Path, Path | None, Path | None, dict[str, Path], Path]:
        ws = self.workspace
        hoomans_root = ws.repository_for(HOOMANS_OWNER)
        dt_root = ws.repository_for(DT_COMMON_OWNER)
        runtime_base = hoomans_root or ws.core_repository
        manifest_path = (
            ws.core_repository
            / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
        )
        package_repositories = {
            owner: path
            for owner, path in ws.repository_by_owner.items()
            if path is not None
        }
        package_repositories[CORE_OWNER] = ws.core_repository
        return runtime_base, hoomans_root, dt_root, package_repositories, manifest_path

    def compile_model(self) -> dict[str, Any]:
        runtime_base, _hoomans_root, _dt_root, package_repositories, manifest_path = (
            self._runtime_roots()
        )
        return compile_conversation_sources(
            runtime_base,
            manifest_path=None if len(package_repositories) > 1 else manifest_path,
            runtime_root=runtime_base,
            package_repositories=package_repositories,
        )

    def preview(
        self,
        *,
        owner: str | None = None,
        check_determinism: bool = False,
        limit: int = 64,
    ) -> dict[str, Any]:
        """Compile and validate a build plan without touching live ``media/`` files."""
        normalized_owner = normalize_owner(owner) if owner else None
        model = self.compile_model()
        model_fp = str(model.get("wholeModelFingerprint") or "")
        cache_key = (model_fp, normalized_owner)
        cached = self._plan_cache.get(cache_key)
        if cached is None:
            rendered, reports = render_conversation_runtime_plan(model)
            health = conversation_context_health(model, reports)
            if health.get("status") != "pass":
                errors = health.get("errors") or []
                summary = "; ".join(
                    str(item.get("type") or "context_health_error")
                    + ":"
                    + str(item.get("path") or item.get("module") or "")
                    for item in errors[:8]
                )
                raise CompileError(
                    "Conversation context-health hard violations"
                    + (": " + summary if summary else "")
                )
            modules = tuple(
                module
                for module, _source in rendered
                if normalized_owner is None or module_owner(module) == normalized_owner
            )
            cached = BuildPlan(
                workspace_fingerprint=self.workspace.workspace_fingerprint,
                model_fingerprint=model_fp,
                planned_modules=modules,
                report_count=len(reports),
                health_status=str(health.get("status") or "pass"),
            )
            self._plan_cache[cache_key] = cached

        max_items = max(1, min(int(limit), 200))
        payload: dict[str, Any] = {
            "ok": True,
            "previewOnly": True,
            "effectFree": True,
            "workspaceFingerprint": cached.workspace_fingerprint,
            "modelFingerprint": cached.model_fingerprint,
            "owner": normalized_owner,
            "healthStatus": cached.health_status,
            "plannedModuleCount": len(cached.planned_modules),
            "plannedModules": list(cached.planned_modules[:max_items]),
            "modulesTruncated": len(cached.planned_modules) > max_items,
            "reportCount": cached.report_count,
            "writes": [],
        }
        if check_determinism:
            det = self.verify_determinism(compiled_first=model)
            payload["determinism"] = det
            if det.get("diffs"):
                payload["ok"] = False
        return payload

    def apply(self, *, owner: str | None = None, limit: int = 64) -> dict[str, Any]:
        """Generate ConvoEngine outputs atomically under ``workspace_generation_lock``."""
        del owner  # Single-authority full output coherence keeps cross-owner registries consistent.
        runtime_base, _hoomans_root, dt_root, _pkg, _manifest = self._runtime_roots()
        with workspace_generation_lock(self.workspace):
            model = self.compile_model()
            paths = _build_mod.write_conversation_output(
                runtime_base,
                model,
                core_repository=self.workspace.core_repository,
                dynamic_trading_repository=dt_root,
            )
            self._plan_cache.clear()
        max_items = max(1, min(int(limit), 200))
        rel_or_abs = [str(item) for item in paths]
        return {
            "ok": True,
            "previewOnly": False,
            "effectFree": False,
            "workspaceFingerprint": self.workspace.workspace_fingerprint,
            "modelFingerprint": str(model.get("wholeModelFingerprint") or ""),
            "writtenCount": len(rel_or_abs),
            "writes": rel_or_abs[:max_items],
            "writesTruncated": len(rel_or_abs) > max_items,
        }

    def verify_determinism(
        self,
        compiled_first: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Verify two-pass deterministic output in isolated temporary directories.

        Live ``media/`` and ``Translate/`` directories are never written or
        deleted by this check. An exclusive ``workspace_generation_lock`` ensures
        canonical sources are not modified mid-comparison.
        """
        runtime_base, hoomans_root, dt_root, _pkg, _manifest = self._runtime_roots()
        with workspace_generation_lock(self.workspace):
            first_model = compiled_first if compiled_first is not None else self.compile_model()
            with tempfile.TemporaryDirectory(prefix="convo_det_") as tmp:
                stage_root = Path(tmp)

                def _render_stage(name: str, model: dict[str, Any]) -> dict[str, str]:
                    root = stage_root / name
                    stage_core = root / "core"
                    stage_hoomans = root / "hoomans" if hoomans_root is not None else None
                    stage_dt = root / "dt" if dt_root is not None else None
                    out_map: dict[str, Path] = {CORE_OWNER: stage_core}
                    if stage_hoomans is not None:
                        out_map[HOOMANS_OWNER] = stage_hoomans
                    if stage_dt is not None:
                        out_map[DT_COMMON_OWNER] = stage_dt
                    stage_core.mkdir(parents=True, exist_ok=True)
                    if stage_hoomans is not None:
                        stage_hoomans.mkdir(parents=True, exist_ok=True)
                    if stage_dt is not None:
                        stage_dt.mkdir(parents=True, exist_ok=True)
                    _build_mod.write_conversation_output(
                        runtime_base,
                        model,
                        core_repository=self.workspace.core_repository,
                        dynamic_trading_repository=dt_root,
                        output_repositories=out_map,
                    )
                    return collect_generated_artifact_hashes(
                        core_repository=stage_core,
                        hoomans_repository=stage_hoomans,
                        dynamic_trading_repository=stage_dt,
                    )

                first_hashes = _render_stage("pass1", first_model)
                second_model = self.compile_model()
                second_hashes = _render_stage("pass2", second_model)

        diff_keys = sorted(
            key
            for key in set(first_hashes) | set(second_hashes)
            if first_hashes.get(key) != second_hashes.get(key)
        )
        return {
            "checked": True,
            "isolated": True,
            "fileCount": len(second_hashes),
            "diffs": diff_keys,
        }


__all__ = [
    "BuildPlan",
    "BuildPlanner",
    "collect_generated_artifact_hashes",
    "sha256_file",
]
