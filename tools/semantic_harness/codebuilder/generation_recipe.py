"""Compact CodeBuilder generation recipe and effect-free desired-artifact ledger."""

from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping
from dataclasses import dataclass, field
from pathlib import Path, PurePosixPath
from typing import Any

from .conversation_compiler import (
    CONVERSATION_UI_RUNTIME_RELATIVE,
    compile_conversation_sources,
    conversation_context_health,
    conversation_languages,
    conversation_translation_catalogs_by_owner,
    render_conversation_manifest_lua,
    render_conversation_registry,
    render_conversation_runtime_plan,
    render_conversation_ui_module,
)
from .conversation_text_catalog import plan_runtime_text_catalogs
from .errors import CompileError
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    OwnerConfigurationError,
    generated_conversation_root,
    module_owner,
    module_target,
    normalize_owner,
    package_descriptor,
    resolve_core_repository,
    translation_root,
)
from .lexicon_compiler import (
    DEFAULT_ALLOWLIST,
    compile_wordnet,
    load_allowlist,
    render_lua_shards,
)
from .translation_support import pretty_json
from .workspace_catalog import WorkspaceCatalog


GENERATION_RECIPE_SCHEMA = "psychopatz.semantic-generation-recipe.v1"
DESIRED_LEDGER_SCHEMA = "psychopatz.semantic-generation-ledger.v1"

DEFAULT_RECIPE_PATH = Path(__file__).resolve().parent / "generation_recipe.json"

SUPPORTED_GENERATORS = frozenset({
    "conversation",
    "conversation_text",
    "lexicon",
})

SUPPORTED_POLICIES = frozenset({
    "owned_fileset",
    "mixed_key_catalog",
    "must_not_exist",
    "preserve",
})

SUPPORTED_SURFACE_IDS = frozenset({
    "conversation_lua",
    "conversation_translations",
    "conversation_ui",
    "conversation_text",
    "lexicon_lua",
})

SUPPORTED_RETIREMENT_KINDS = frozenset({
    "file",
    "file_list",
    "directory_glob",
    "mixed_keys",
})


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _validate_rel_posix(raw: Any, *, field_label: str) -> str:
    if not isinstance(raw, str) or not raw.strip():
        raise CompileError(f"{field_label} must be a non-empty relative path")
    norm = raw.strip().replace("\\", "/")
    posix = PurePosixPath(norm)
    if posix.is_absolute() or ".." in posix.parts or "." in posix.parts:
        raise CompileError(f"{field_label} must be a normalized relative path: {raw!r}")
    return posix.as_posix()


@dataclass(frozen=True)
class SurfaceRecipe:
    """Validated recipe declaration for one CodeBuilder generation surface."""

    id: str
    generator: str
    owners: tuple[str, ...]
    policy: str
    generated_marker: str | None = None
    preserved_by_owner: Mapping[str, tuple[str, ...]] = field(default_factory=dict)

    def preserved_for(self, owner: str) -> tuple[str, ...]:
        canonical = normalize_owner(owner)
        return tuple(self.preserved_by_owner.get(canonical, ()))

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "id": self.id,
            "generator": self.generator,
            "owners": list(self.owners),
            "policy": self.policy,
        }
        if self.generated_marker is not None:
            payload["generatedMarker"] = self.generated_marker
        if self.preserved_by_owner:
            payload["preserved"] = {
                owner: list(paths)
                for owner, paths in sorted(self.preserved_by_owner.items())
            }
        return payload


@dataclass(frozen=True)
class RetiredEntry:
    """Validated tombstone/retirement entry in the generation recipe."""

    id: str
    surface: str
    kind: str
    owners: tuple[str, ...]
    policy: str = "must_not_exist"
    paths: tuple[str, ...] = ()
    pattern: str | None = None
    keys: tuple[str, ...] = ()
    sha256: str | None = None
    generated_marker: str | None = None
    reason: str = ""
    evidence: str = ""

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "id": self.id,
            "surface": self.surface,
            "kind": self.kind,
            "owners": list(self.owners),
            "policy": self.policy,
        }
        if self.paths:
            payload["paths"] = list(self.paths)
        if self.pattern:
            payload["pattern"] = self.pattern
        if self.keys:
            payload["keys"] = list(self.keys)
        if self.sha256:
            payload["sha256"] = self.sha256
        if self.generated_marker:
            payload["generatedMarker"] = self.generated_marker
        if self.reason:
            payload["reason"] = self.reason
        if self.evidence:
            payload["evidence"] = self.evidence
        return payload


@dataclass(frozen=True)
class GenerationRecipe:
    """Validated CodeBuilder generation recipe."""

    schema: str
    version: int
    surfaces: tuple[SurfaceRecipe, ...]
    retired: tuple[RetiredEntry, ...] = ()
    canonical_cli: Mapping[str, str] = field(default_factory=dict)
    source_path: Path | None = None

    def surface(self, surface_id: str) -> SurfaceRecipe:
        for item in self.surfaces:
            if item.id == surface_id:
                return item
        raise CompileError(f"Unknown generation recipe surface: {surface_id!r}")

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": self.schema,
            "version": self.version,
            "canonicalCli": dict(self.canonical_cli),
            "surfaces": [item.to_dict() for item in self.surfaces],
            "retired": [item.to_dict() for item in self.retired],
        }


def validate_generation_recipe(
    document: Mapping[str, Any],
    *,
    source_path: Path | None = None,
) -> GenerationRecipe:
    """Validate a generation recipe document and fail closed on unknown fields/owners/policies."""
    if not isinstance(document, Mapping):
        raise CompileError("Generation recipe must be a JSON object")
    allowed_top = {"schema", "version", "canonicalCli", "surfaces", "retired"}
    extra_top = set(document) - allowed_top
    if extra_top:
        raise CompileError(
            "Generation recipe contains unsupported top-level fields: "
            + ", ".join(sorted(str(k) for k in extra_top))
        )
    schema = document.get("schema")
    if schema != GENERATION_RECIPE_SCHEMA:
        raise CompileError(
            f"Invalid generation recipe schema {schema!r}; expected {GENERATION_RECIPE_SCHEMA!r}"
        )
    version = document.get("version", 1)
    if isinstance(version, bool) or not isinstance(version, int) or version < 1:
        raise CompileError("Generation recipe version must be a positive integer")

    raw_cli = document.get("canonicalCli") or {}
    if not isinstance(raw_cli, Mapping) or any(
        not isinstance(k, str) or not isinstance(v, str)
        for k, v in raw_cli.items()
    ):
        raise CompileError("Generation recipe canonicalCli must be a string map")

    raw_surfaces = document.get("surfaces")
    if not isinstance(raw_surfaces, list) or not raw_surfaces:
        raise CompileError("Generation recipe requires a non-empty surfaces list")

    surfaces: list[SurfaceRecipe] = []
    seen_surface_ids: set[str] = set()
    for idx, raw_surface in enumerate(raw_surfaces):
        label = f"surfaces[{idx}]"
        if not isinstance(raw_surface, Mapping):
            raise CompileError(f"{label} must be an object")
        allowed_surface_keys = {
            "id", "generator", "owners", "policy", "generatedMarker", "preserved",
        }
        extra_keys = set(raw_surface) - allowed_surface_keys
        if extra_keys:
            raise CompileError(
                f"{label} contains unsupported fields: "
                + ", ".join(sorted(str(k) for k in extra_keys))
            )
        surface_id = raw_surface.get("id")
        if not isinstance(surface_id, str) or surface_id not in SUPPORTED_SURFACE_IDS:
            raise CompileError(f"{label}.id is unsupported: {surface_id!r}")
        if surface_id in seen_surface_ids:
            raise CompileError(f"Duplicate generation recipe surface id: {surface_id!r}")
        seen_surface_ids.add(surface_id)

        generator = raw_surface.get("generator")
        if not isinstance(generator, str) or generator not in SUPPORTED_GENERATORS:
            raise CompileError(f"{label}.generator is unsupported: {generator!r}")

        policy = raw_surface.get("policy")
        if not isinstance(policy, str) or policy not in SUPPORTED_POLICIES:
            raise CompileError(f"{label}.policy is unsupported: {policy!r}")

        raw_owners = raw_surface.get("owners")
        if not isinstance(raw_owners, list) or not raw_owners:
            raise CompileError(f"{label}.owners must be a non-empty list")
        owners: list[str] = []
        for raw_owner in raw_owners:
            try:
                norm_owner = normalize_owner(raw_owner)
            except OwnerConfigurationError as error:
                raise CompileError(f"{label}.owners: {error}") from error
            if norm_owner not in owners:
                owners.append(norm_owner)

        marker = raw_surface.get("generatedMarker")
        if marker is not None and (not isinstance(marker, str) or not marker.strip()):
            raise CompileError(f"{label}.generatedMarker must be a non-empty string")

        raw_preserved = raw_surface.get("preserved") or {}
        if not isinstance(raw_preserved, Mapping):
            raise CompileError(f"{label}.preserved must be an owner-keyed map")
        preserved_by_owner: dict[str, tuple[str, ...]] = {}
        for raw_owner, raw_paths in raw_preserved.items():
            try:
                norm_owner = normalize_owner(raw_owner)
            except OwnerConfigurationError as error:
                raise CompileError(f"{label}.preserved owner: {error}") from error
            if not isinstance(raw_paths, list):
                raise CompileError(f"{label}.preserved[{norm_owner}] must be a list of paths")
            validated_paths = tuple(
                sorted({
                    _validate_rel_posix(p, field_label=f"{label}.preserved[{norm_owner}]")
                    for p in raw_paths
                })
            )
            preserved_by_owner[norm_owner] = validated_paths

        surfaces.append(
            SurfaceRecipe(
                id=surface_id,
                generator=generator,
                owners=tuple(owners),
                policy=policy,
                generated_marker=marker,
                preserved_by_owner=preserved_by_owner,
            )
        )

    raw_retired = document.get("retired") or []
    if not isinstance(raw_retired, list):
        raise CompileError("Generation recipe retired must be a list")
    retired_entries: list[RetiredEntry] = []
    seen_retired_ids: set[str] = set()
    for idx, raw_item in enumerate(raw_retired):
        label = f"retired[{idx}]"
        if not isinstance(raw_item, Mapping):
            raise CompileError(f"{label} must be an object")
        allowed_ret_keys = {
            "id", "surface", "kind", "owner", "owners", "policy",
            "path", "paths", "pattern", "keys", "sha256", "generatedMarker",
            "reason", "evidence",
        }
        extra_ret = set(raw_item) - allowed_ret_keys
        if extra_ret:
            raise CompileError(
                f"{label} contains unsupported fields: "
                + ", ".join(sorted(str(k) for k in extra_ret))
            )
        ret_id = raw_item.get("id")
        if not isinstance(ret_id, str) or not ret_id.strip():
            raise CompileError(f"{label}.id must be a non-empty string")
        if ret_id in seen_retired_ids:
            raise CompileError(f"Duplicate retired entry id: {ret_id!r}")
        seen_retired_ids.add(ret_id)

        surface_id = raw_item.get("surface")
        if not isinstance(surface_id, str) or surface_id not in seen_surface_ids:
            raise CompileError(f"{label}.surface must reference a declared surface: {surface_id!r}")

        kind = raw_item.get("kind", "file")
        if not isinstance(kind, str) or kind not in SUPPORTED_RETIREMENT_KINDS:
            raise CompileError(f"{label}.kind is unsupported: {kind!r}")

        policy = raw_item.get("policy", "must_not_exist")
        if policy != "must_not_exist":
            raise CompileError(f"{label}.policy must be 'must_not_exist'")

        raw_owners_field = raw_item.get("owners")
        if raw_owners_field is None and "owner" in raw_item:
            raw_owners_field = [raw_item["owner"]]
        if not isinstance(raw_owners_field, list) or not raw_owners_field:
            raise CompileError(f"{label} requires owner or owners")
        ret_owners: list[str] = []
        for raw_owner in raw_owners_field:
            try:
                norm_owner = normalize_owner(raw_owner)
            except OwnerConfigurationError as error:
                raise CompileError(f"{label}.owners: {error}") from error
            if norm_owner not in ret_owners:
                ret_owners.append(norm_owner)

        paths_list: list[str] = []
        if "path" in raw_item and raw_item["path"] is not None:
            paths_list.append(_validate_rel_posix(raw_item["path"], field_label=f"{label}.path"))
        if "paths" in raw_item and raw_item["paths"] is not None:
            if not isinstance(raw_item["paths"], list):
                raise CompileError(f"{label}.paths must be a list")
            for p in raw_item["paths"]:
                paths_list.append(_validate_rel_posix(p, field_label=f"{label}.paths"))

        pattern = raw_item.get("pattern")
        if pattern is not None:
            pattern = _validate_rel_posix(pattern, field_label=f"{label}.pattern")

        keys_tuple: tuple[str, ...] = ()
        if "keys" in raw_item and raw_item["keys"] is not None:
            if not isinstance(raw_item["keys"], list) or not raw_item["keys"] or any(
                not isinstance(k, str) or not k.strip() for k in raw_item["keys"]
            ):
                raise CompileError(f"{label}.keys must be a non-empty list of strings")
            keys_tuple = tuple(sorted({k.strip() for k in raw_item["keys"]}))

        if kind in {"file", "file_list"} and not paths_list:
            raise CompileError(f"{label} of kind {kind!r} requires path or paths")
        if kind == "directory_glob" and not pattern:
            raise CompileError(f"{label} of kind 'directory_glob' requires pattern")
        if kind == "mixed_keys" and (not paths_list or not keys_tuple):
            raise CompileError(f"{label} of kind 'mixed_keys' requires paths and keys")

        sha256_val = raw_item.get("sha256")
        if sha256_val is not None and (not isinstance(sha256_val, str) or len(sha256_val) != 64):
            raise CompileError(f"{label}.sha256 must be a 64-character hex digest")

        ret_marker = raw_item.get("generatedMarker")
        if ret_marker is not None and (not isinstance(ret_marker, str) or not ret_marker.strip()):
            raise CompileError(f"{label}.generatedMarker must be a non-empty string")

        retired_entries.append(
            RetiredEntry(
                id=ret_id,
                surface=surface_id,
                kind=kind,
                owners=tuple(ret_owners),
                policy=policy,
                paths=tuple(sorted(set(paths_list))),
                pattern=pattern,
                keys=keys_tuple,
                sha256=sha256_val,
                generated_marker=ret_marker,
                reason=str(raw_item.get("reason") or ""),
                evidence=str(raw_item.get("evidence") or ""),
            )
        )

    return GenerationRecipe(
        schema=GENERATION_RECIPE_SCHEMA,
        version=version,
        surfaces=tuple(surfaces),
        retired=tuple(retired_entries),
        canonical_cli=dict(raw_cli),
        source_path=source_path,
    )


def load_generation_recipe(path: str | Path | None = None) -> GenerationRecipe:
    """Load and validate a CodeBuilder generation recipe from disk."""
    recipe_path = Path(path or DEFAULT_RECIPE_PATH).expanduser().resolve()
    try:
        raw = json.loads(recipe_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(f"Cannot load generation recipe {recipe_path}: {error}") from error
    return validate_generation_recipe(raw, source_path=recipe_path)


@dataclass(frozen=True)
class DesiredArtifactRow:
    """One planned output artifact in the desired-artifact ledger."""

    owner: str
    surface: str
    path: str
    artifact_kind: str
    source_lineage: tuple[str, ...]
    cleanup_policy: str
    content_fingerprint: str
    rendered_content: str
    generated_keys: tuple[str, ...] = ()
    generated_key_values: Mapping[str, str] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "owner": self.owner,
            "surface": self.surface,
            "path": self.path,
            "artifactKind": self.artifact_kind,
            "sourceLineage": list(self.source_lineage),
            "cleanupPolicy": self.cleanup_policy,
            "contentFingerprint": self.content_fingerprint,
        }
        if self.generated_keys:
            payload["generatedKeys"] = list(self.generated_keys)
        return payload


@dataclass(frozen=True)
class DesiredArtifactLedger:
    """Complete, validated in-memory artifact plan before any filesystem mutation."""

    schema: str
    recipe: GenerationRecipe
    enabled_owners: tuple[str, ...]
    model_fingerprint: str
    rows: tuple[DesiredArtifactRow, ...]
    output_repositories: Mapping[str, Path]

    def rows_for(
        self,
        *,
        owner: str | None = None,
        surface: str | None = None,
    ) -> list[DesiredArtifactRow]:
        norm_owner = normalize_owner(owner) if owner is not None else None
        return [
            row
            for row in self.rows
            if (norm_owner is None or row.owner == norm_owner)
            and (surface is None or row.surface == surface)
        ]

    def by_owner_and_path(self) -> dict[tuple[str, str], DesiredArtifactRow]:
        return {(row.owner, row.path): row for row in self.rows}

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": self.schema,
            "recipeSchema": self.recipe.schema,
            "enabledOwners": list(self.enabled_owners),
            "modelFingerprint": self.model_fingerprint,
            "artifactCount": len(self.rows),
            "rows": [row.to_dict() for row in self.rows],
        }


def build_desired_artifact_ledger(
    repository: str | Path,
    *,
    recipe: GenerationRecipe | None = None,
    model: dict[str, Any] | None = None,
    core_repository: str | Path | None = None,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    output_repositories: Mapping[str, str | Path] | None = None,
    wordnet_home: str | Path | None = None,
    allowlist_path: str | Path = DEFAULT_ALLOWLIST,
) -> DesiredArtifactLedger:
    """Compile and validate the complete desired artifact ledger without writing to disk."""
    active_recipe = recipe or load_generation_recipe()
    repo_path = Path(repository).expanduser().resolve()
    core_arg = Path(core_repository).expanduser().resolve() if core_repository is not None else None
    hoomans_arg = Path(hoomans_repository).expanduser().resolve() if hoomans_repository is not None else None
    dt_arg = (
        Path(dynamic_trading_repository).expanduser().resolve()
        if dynamic_trading_repository is not None
        else None
    )

    workspace = WorkspaceCatalog.discover(
        repo_path,
        repository=repo_path,
        core_repository=core_arg,
        hoomans_repository=hoomans_arg,
        dynamic_trading_repository=dt_arg,
        allow_sibling_discovery=False,
        runtime_root=hoomans_arg or repo_path,
    )
    resolved_core = workspace.core_repository
    resolved_hoomans = hoomans_arg or workspace.repository_for(HOOMANS_OWNER)
    if resolved_hoomans is None and repo_path != resolved_core:
        resolved_hoomans = repo_path
    resolved_dt = dt_arg or workspace.repository_for(DT_COMMON_OWNER)
    primary_compile_repo = resolved_hoomans or repo_path

    package_repositories: dict[str, Path] = dict(workspace.repository_by_owner)
    if resolved_hoomans is not None:
        package_repositories.setdefault(HOOMANS_OWNER, resolved_hoomans)
    else:
        package_repositories.setdefault(HOOMANS_OWNER, repo_path)
    package_repositories[CORE_OWNER] = resolved_core
    if resolved_dt is not None:
        package_repositories[DT_COMMON_OWNER] = resolved_dt

    compiled_model = model or compile_conversation_sources(
        primary_compile_repo,
        runtime_root=primary_compile_repo,
        package_repositories=package_repositories,
    )

    manifest = compiled_model.get("manifest") if isinstance(compiled_model, Mapping) else None
    registry_owner = normalize_owner(
        manifest.get("registryOwner") if isinstance(manifest, Mapping) else None
    )
    if resolved_hoomans is None and registry_owner == HOOMANS_OWNER:
        resolved_hoomans = repo_path

    out_overrides = (
        {
            normalize_owner(owner): Path(path).expanduser().resolve()
            for owner, path in output_repositories.items()
        }
        if output_repositories
        else {}
    )
    out_hoomans = (
        out_overrides.get(HOOMANS_OWNER, resolved_hoomans)
        if resolved_hoomans is not None or HOOMANS_OWNER in out_overrides
        else None
    )
    out_core = out_overrides.get(CORE_OWNER, resolved_core)
    out_dt = (
        out_overrides.get(DT_COMMON_OWNER, resolved_dt)
        if resolved_dt is not None or DT_COMMON_OWNER in out_overrides
        else None
    )
    runtime_out_base = out_hoomans or out_core

    out_repos_by_owner: dict[str, Path] = {
        CORE_OWNER: out_core,
    }
    if out_hoomans is not None:
        out_repos_by_owner[HOOMANS_OWNER] = out_hoomans
    if out_dt is not None:
        out_repos_by_owner[DT_COMMON_OWNER] = out_dt

    enabled_owners_list = [CORE_OWNER]
    if out_hoomans is not None:
        enabled_owners_list.append(HOOMANS_OWNER)
    if out_dt is not None:
        enabled_owners_list.append(DT_COMMON_OWNER)
    enabled_owners = tuple(enabled_owners_list)
    enabled_set = set(enabled_owners)

    rendered, reports = render_conversation_runtime_plan(compiled_model)
    health = conversation_context_health(compiled_model, reports)
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

    rows: list[DesiredArtifactRow] = []
    conv_lua_surface = active_recipe.surface("conversation_lua")
    conv_tr_surface = active_recipe.surface("conversation_translations")
    conv_ui_surface = active_recipe.surface("conversation_ui")
    conv_text_surface = active_recipe.surface("conversation_text")

    report_by_module = {str(r.get("module")): r for r in reports if isinstance(r, Mapping)}
    for module, source in rendered:
        owner = module_owner(module)
        if owner not in enabled_set:
            continue
        owner_repo, abs_path = module_target(
            runtime_out_base,
            module,
            core_repository=out_core,
            dynamic_trading_repository=out_dt,
            runtime_root=runtime_out_base,
        )
        rel_path = abs_path.relative_to(owner_repo).as_posix()
        rep = report_by_module.get(module) or {}
        src_shard = str(rep.get("sourceShard") or module)
        kind_label = str(rep.get("kind") or "ConvoEngine")
        rows.append(
            DesiredArtifactRow(
                owner=owner,
                surface=conv_lua_surface.id,
                path=rel_path,
                artifact_kind=f"lua:{kind_label}",
                source_lineage=(src_shard,),
                cleanup_policy=conv_lua_surface.policy,
                content_fingerprint=sha256_text(source),
                rendered_content=source,
            )
        )

    manifest = compiled_model.get("manifest") if isinstance(compiled_model, Mapping) else None
    registry_owner = normalize_owner(
        manifest.get("registryOwner") if isinstance(manifest, Mapping) else None
    )
    primary_registry_owners = (
        (CORE_OWNER, HOOMANS_OWNER)
        if registry_owner == HOOMANS_OWNER
        else (registry_owner,)
    )
    if registry_owner in enabled_set:
        registry_root = generated_conversation_root(
            runtime_out_base,
            registry_owner,
            core_repository=out_core,
            dynamic_trading_repository=out_dt,
            runtime_root=runtime_out_base,
        )
        reg_owner_repo = out_repos_by_owner[registry_owner]
        reg_source = render_conversation_registry(
            compiled_model,
            reports,
            include_owners=primary_registry_owners,
        )
        reg_rel = (registry_root / "Registry.lua").relative_to(reg_owner_repo).as_posix()
        rows.append(
            DesiredArtifactRow(
                owner=registry_owner,
                surface=conv_lua_surface.id,
                path=reg_rel,
                artifact_kind="lua:Registry",
                source_lineage=("manifest.json",),
                cleanup_policy=conv_lua_surface.policy,
                content_fingerprint=sha256_text(reg_source),
                rendered_content=reg_source,
            )
        )
        primary_report_owners = set(primary_registry_owners)
        manifest_reports = [
            report for report in reports if report.get("owner") in primary_report_owners
        ]
        manifest_lua_source = render_conversation_manifest_lua(compiled_model, manifest_reports)
        manifest_rel = (registry_root / "Manifest.lua").relative_to(reg_owner_repo).as_posix()
        rows.append(
            DesiredArtifactRow(
                owner=registry_owner,
                surface=conv_lua_surface.id,
                path=manifest_rel,
                artifact_kind="lua:Manifest",
                source_lineage=("manifest.json",),
                cleanup_policy=conv_lua_surface.policy,
                content_fingerprint=sha256_text(manifest_lua_source),
                rendered_content=manifest_lua_source,
            )
        )

    if CORE_OWNER in enabled_set:
        core_registry_root = generated_conversation_root(
            runtime_out_base,
            CORE_OWNER,
            core_repository=out_core,
            dynamic_trading_repository=out_dt,
            runtime_root=runtime_out_base,
        )
        core_reg_source = render_conversation_registry(
            compiled_model,
            reports,
            registry_owner=CORE_OWNER,
            include_owner=CORE_OWNER,
            registry_module="PsychopatzCore/ConvoEngine/FoundationRegistry",
        )
        core_reg_rel = (
            (core_registry_root / "FoundationRegistry.lua")
            .relative_to(out_core)
            .as_posix()
        )
        rows.append(
            DesiredArtifactRow(
                owner=CORE_OWNER,
                surface=conv_lua_surface.id,
                path=core_reg_rel,
                artifact_kind="lua:FoundationRegistry",
                source_lineage=("manifest.json",),
                cleanup_policy=conv_lua_surface.policy,
                content_fingerprint=sha256_text(core_reg_source),
                rendered_content=core_reg_source,
            )
        )

    if out_dt is not None and registry_owner != DT_COMMON_OWNER and DT_COMMON_OWNER in enabled_set:
        dt_registry_root = generated_conversation_root(
            runtime_out_base,
            DT_COMMON_OWNER,
            core_repository=out_core,
            dynamic_trading_repository=out_dt,
            runtime_root=runtime_out_base,
        )
        dt_reg_source = render_conversation_registry(
            compiled_model,
            reports,
            registry_owner=DT_COMMON_OWNER,
            include_owner=DT_COMMON_OWNER,
            registry_module="DTCommon/ConvoEngine/Registry",
        )
        dt_reg_rel = (dt_registry_root / "Registry.lua").relative_to(out_dt).as_posix()
        rows.append(
            DesiredArtifactRow(
                owner=DT_COMMON_OWNER,
                surface=conv_lua_surface.id,
                path=dt_reg_rel,
                artifact_kind="lua:Registry",
                source_lineage=("manifest.json",),
                cleanup_policy=conv_lua_surface.policy,
                content_fingerprint=sha256_text(dt_reg_source),
                rendered_content=dt_reg_source,
            )
        )
        dt_manifest_reports = [
            report for report in reports if report.get("owner") == DT_COMMON_OWNER
        ]
        dt_manifest_source = render_conversation_manifest_lua(
            compiled_model,
            dt_manifest_reports,
            registry_owner=DT_COMMON_OWNER,
        )
        dt_manifest_rel = (dt_registry_root / "Manifest.lua").relative_to(out_dt).as_posix()
        rows.append(
            DesiredArtifactRow(
                owner=DT_COMMON_OWNER,
                surface=conv_lua_surface.id,
                path=dt_manifest_rel,
                artifact_kind="lua:Manifest",
                source_lineage=("manifest.json",),
                cleanup_policy=conv_lua_surface.policy,
                content_fingerprint=sha256_text(dt_manifest_source),
                rendered_content=dt_manifest_source,
            )
        )

    if HOOMANS_OWNER in enabled_set:
        ui_owners = (
            (CORE_OWNER, HOOMANS_OWNER)
            if registry_owner == HOOMANS_OWNER
            else (registry_owner,)
        )
        ui_runtime_source = render_conversation_ui_module(
            compiled_model,
            include_owners=ui_owners,
        )
        ui_runtime_rel = CONVERSATION_UI_RUNTIME_RELATIVE.as_posix()
        rows.append(
            DesiredArtifactRow(
                owner=HOOMANS_OWNER,
                surface=conv_lua_surface.id,
                path=ui_runtime_rel,
                artifact_kind="lua:StaticSuggestions",
                source_lineage=("manifest.json",),
                cleanup_policy=conv_lua_surface.policy,
                content_fingerprint=sha256_text(ui_runtime_source),
                rendered_content=ui_runtime_source,
            )
        )

    # Plan Conversation/Text from text/manifest.json + inline ConvoEngine textTarget projections
    text_manifest_candidates = [
        primary_compile_repo / "tools/semantic_harness/codebuilder/sources/conversation/text/manifest.json",
        resolved_core / "tools/semantic_harness/codebuilder/sources/conversation/text/manifest.json",
    ]
    text_manifest_path = next(
        (cand for cand in text_manifest_candidates if cand.is_file()),
        text_manifest_candidates[-1],
    )
    catalogs_by_owner = conversation_translation_catalogs_by_owner(
        compiled_model,
        package_repositories=package_repositories,
    )
    languages = conversation_languages(compiled_model)

    for owner in enabled_owners:
        owner_repo = out_repos_by_owner[owner]
        pkg_tr_root = translation_root(
            runtime_out_base,
            owner,
            core_repository=out_core,
            dynamic_trading_repository=out_dt,
            runtime_root=runtime_out_base,
        )
        owner_catalogs = catalogs_by_owner.get(owner, {})

        # 1. Text catalogs (manifest-backed + inline textTarget)
        text_files_by_lang_rel: dict[tuple[str, str], dict[str, str]] = {}
        text_lineage_by_rel: dict[str, tuple[str, ...]] = {}
        if text_manifest_path.is_file():
            planned_text, text_lineage = plan_runtime_text_catalogs(
                text_manifest_path,
                owner=owner,
            )
            text_files_by_lang_rel.update(planned_text)
            text_lineage_by_rel.update(text_lineage)

        for language, domains in sorted(owner_catalogs.items()):
            for domain, values in sorted(domains.items()):
                if not domain.startswith("Text/"):
                    continue
                rel_from_lang = f"Conversation/{domain}.json"
                text_files_by_lang_rel[(language, rel_from_lang)] = dict(values)
                text_lineage_by_rel.setdefault(rel_from_lang, ("convo_engine:textTarget",))

        for (language, rel_from_lang), values in sorted(text_files_by_lang_rel.items()):
            abs_text_path = pkg_tr_root / language / Path(*PurePosixPath(rel_from_lang).parts)
            rel_repo_path = abs_text_path.relative_to(owner_repo).as_posix()
            rendered_json = pretty_json(values)
            rows.append(
                DesiredArtifactRow(
                    owner=owner,
                    surface=conv_text_surface.id,
                    path=rel_repo_path,
                    artifact_kind="json:ConversationText",
                    source_lineage=text_lineage_by_rel.get(rel_from_lang, ("text/manifest.json",)),
                    cleanup_policy=conv_text_surface.policy,
                    content_fingerprint=sha256_text(rendered_json),
                    rendered_content=rendered_json,
                    generated_keys=tuple(sorted(values)),
                    generated_key_values=dict(values),
                )
            )

        # 2. Non-Text Conversation domains and mixed UI.json catalogs
        manifest_entries_by_lang: dict[str, set[str]] = {lang: set() for lang in languages}
        for preserved_rel in conv_tr_surface.preserved_for(owner):
            preserved_abs = owner_repo / Path(*PurePosixPath(preserved_rel).parts)
            if preserved_abs.is_file():
                try:
                    rel_to_tr = preserved_abs.relative_to(pkg_tr_root).as_posix()
                    lang_code = rel_to_tr.split("/", 1)[0]
                    manifest_entries_by_lang.setdefault(lang_code, set()).add(rel_to_tr)
                except ValueError:
                    pass

        emitted_ui_langs: set[str] = set()
        for language, domains in sorted(owner_catalogs.items()):
            for domain, values in sorted(domains.items()):
                if domain.startswith("Text/"):
                    continue
                rel_from_tr = f"{language}/Conversation/{domain}.json"
                abs_domain_path = pkg_tr_root / Path(*PurePosixPath(rel_from_tr).parts)
                rel_repo_path = abs_domain_path.relative_to(owner_repo).as_posix()
                manifest_entries_by_lang.setdefault(language, set()).add(rel_from_tr)
                rendered_json = pretty_json(values)
                if domain == "UI":
                    emitted_ui_langs.add(language)
                    rows.append(
                        DesiredArtifactRow(
                            owner=owner,
                            surface=conv_ui_surface.id,
                            path=rel_repo_path,
                            artifact_kind="json:ConversationUICatalog",
                            source_lineage=("manifest.json#ui",),
                            cleanup_policy=conv_ui_surface.policy,
                            content_fingerprint=sha256_text(rendered_json),
                            rendered_content=rendered_json,
                            generated_keys=tuple(sorted(values)),
                            generated_key_values=dict(values),
                        )
                    )
                else:
                    rows.append(
                        DesiredArtifactRow(
                            owner=owner,
                            surface=conv_tr_surface.id,
                            path=rel_repo_path,
                            artifact_kind=f"json:ConversationDomain:{domain}",
                            source_lineage=(f"manifest.json#{domain}",),
                            cleanup_policy=conv_tr_surface.policy,
                            content_fingerprint=sha256_text(rendered_json),
                            rendered_content=rendered_json,
                            generated_keys=tuple(sorted(values)),
                            generated_key_values=dict(values),
                        )
                    )

        # Ensure an existing package-owned Conversation/UI.json is still reconciled under mixed_key_catalog
        # even when current compilation emits 0 generated UI keys for this owner.
        for language in languages:
            if language in emitted_ui_langs:
                continue
            rel_from_tr = f"{language}/Conversation/UI.json"
            abs_ui_path = pkg_tr_root / Path(*PurePosixPath(rel_from_tr).parts)
            if abs_ui_path.is_file():
                rel_repo_path = abs_ui_path.relative_to(owner_repo).as_posix()
                manifest_entries_by_lang.setdefault(language, set()).add(rel_from_tr)
                rendered_json = pretty_json({})
                rows.append(
                    DesiredArtifactRow(
                        owner=owner,
                        surface=conv_ui_surface.id,
                        path=rel_repo_path,
                        artifact_kind="json:ConversationUICatalog",
                        source_lineage=("manifest.json#ui",),
                        cleanup_policy=conv_ui_surface.policy,
                        content_fingerprint=sha256_text(rendered_json),
                        rendered_content=rendered_json,
                        generated_keys=(),
                        generated_key_values={},
                    )
                )

        # 3. Package translation manifest (manifests/Conversation.json)
        if any(manifest_entries_by_lang.values()) or owner_catalogs:
            manifest_rel_in_tr = package_descriptor(owner).translation_manifest_relative
            abs_tr_manifest = pkg_tr_root / manifest_rel_in_tr
            rel_tr_manifest = abs_tr_manifest.relative_to(owner_repo).as_posix()
            languages_payload = {
                lang: sorted(items)
                for lang, items in sorted(manifest_entries_by_lang.items())
                if items
            }
            rendered_manifest_json = pretty_json({"version": 1, "languages": languages_payload})
            rows.append(
                DesiredArtifactRow(
                    owner=owner,
                    surface=conv_tr_surface.id,
                    path=rel_tr_manifest,
                    artifact_kind="json:TranslationManifest",
                    source_lineage=("manifest.json#translations",),
                    cleanup_policy=conv_tr_surface.policy,
                    content_fingerprint=sha256_text(rendered_manifest_json),
                    rendered_content=rendered_manifest_json,
                )
            )

    if wordnet_home is not None and CORE_OWNER in enabled_set:
        lexicon_surface = active_recipe.surface("lexicon_lua")
        compiled_lexicon = compile_wordnet(
            Path(wordnet_home).expanduser().resolve(),
            load_allowlist(Path(allowlist_path).expanduser().resolve()),
        )
        lex_prefix = "PsychopatzCore/Semantics/Generated/Lexicon/Catalog"
        lex_rendered = render_lua_shards(compiled_lexicon, lex_prefix)
        shared_rel = package_descriptor(CORE_OWNER).shared_lua_relative.as_posix()
        for module, source in lex_rendered:
            rel_repo_path = f"{shared_rel}/{module}.lua"
            rows.append(
                DesiredArtifactRow(
                    owner=CORE_OWNER,
                    surface=lexicon_surface.id,
                    path=rel_repo_path,
                    artifact_kind="lua:Lexicon",
                    source_lineage=("sources/wordnet_concepts.json",),
                    cleanup_policy=lexicon_surface.policy,
                    content_fingerprint=sha256_text(source),
                    rendered_content=source,
                )
            )

    rows.sort(key=lambda item: (item.owner, item.surface, item.path))
    return DesiredArtifactLedger(
        schema=DESIRED_LEDGER_SCHEMA,
        recipe=active_recipe,
        enabled_owners=enabled_owners,
        model_fingerprint=str(compiled_model.get("wholeModelFingerprint") or ""),
        rows=tuple(rows),
        output_repositories=out_repos_by_owner,
    )


__all__ = [
    "DEFAULT_RECIPE_PATH",
    "DESIRED_LEDGER_SCHEMA",
    "DesiredArtifactLedger",
    "DesiredArtifactRow",
    "GENERATION_RECIPE_SCHEMA",
    "GenerationRecipe",
    "RetiredEntry",
    "SUPPORTED_GENERATORS",
    "SUPPORTED_POLICIES",
    "SUPPORTED_RETIREMENT_KINDS",
    "SUPPORTED_SURFACE_IDS",
    "SurfaceRecipe",
    "build_desired_artifact_ledger",
    "load_generation_recipe",
    "sha256_text",
    "validate_generation_recipe",
]
