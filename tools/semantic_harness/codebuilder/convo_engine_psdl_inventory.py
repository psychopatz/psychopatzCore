"""S8R1 PSDL/psdl reference inventory and active legacy-name leakage scanner."""

from __future__ import annotations

import json
import re
from collections import Counter
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any

from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    generated_conversation_root,
    translation_root,
)
from .semantic_dialogue_ir import LEGACY_PSDL_SCHEMA


CLASS_ACTIVE_IDENTITY_OR_OUTPUT = "active_convo_engine_identity_or_output"
CLASS_BOUNDED_MIGRATION_OR_FIXTURE = "bounded_migration_reader_or_test_fixture"
CLASS_GENERIC_SEMANTIC = "generic_semantic_infrastructure"
CLASS_OBSOLETE_ALIAS = "obsolete_compatibility_alias"

VALID_CLASSIFICATIONS = frozenset({
    CLASS_ACTIVE_IDENTITY_OR_OUTPUT,
    CLASS_BOUNDED_MIGRATION_OR_FIXTURE,
    CLASS_GENERIC_SEMANTIC,
    CLASS_OBSOLETE_ALIAS,
})

_SKIP_DIR_NAMES = frozenset({
    ".git",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".venv",
    ".architecture-refactor",
    ".codebase-memory",
    "Docs",
    "docs",
})

_TEXT_EXTENSIONS = frozenset({
    ".py",
    ".lua",
    ".json",
    ".md",
    ".txt",
    ".toml",
    ".yaml",
    ".yml",
    ".sh",
})

_PSDL_RE = re.compile(r"psdl", re.IGNORECASE)
_ACTIVE_CODE_TOKEN_RE = re.compile(
    r"""(?x)
    (?<!psychopatz\.)psdl\.[a-z0-9_.:-]+
    | pnc\.psdl\.[a-z0-9_.:-]+
    | Conversation/Text/psdl/
    | "psdl/[^"]*"
    | 'psdl/[^']*'
    | psdl_referral_plan_unavailable
    | \["kind"\]\s*=\s*"PSDL"
    | "kind"\s*:\s*"PSDL"
    | ==\s*"PSDL"
    | =='PSDL'
    """
)
_COMPILER_ACTIVE_EMITTER_RE = re.compile(
    r"""(?x)
    f"psdl\.\{
    | f'psdl\.\{
    | "kind"\s*:\s*"PSDL"
    | "textTarget"\s*:\s*"psdl/
    """
)

# Explicit bounded migration-reader / negative-audit fixtures allowed at steady state.
_BOUNDED_PYTHON_FIXTURE_TESTS = frozenset({
    "tools/semantic_harness/tests/test_convo_engine_authoring.py",
    "tools/semantic_harness/tests/test_convo_engine_compiler.py",
    "tools/semantic_harness/tests/test_convo_engine_ownership_inventory.py",
    "tools/semantic_harness/tests/test_convo_engine_psdl_inventory.py",
    "tools/semantic_harness/tests/test_convo_engine_s6m8_audit.py",
    "tools/semantic_harness/tests/test_psdl_authoring_audit.py",
    "tools/semantic_harness/tests/test_psdl_compiler.py",
    "tools/semantic_harness/tests/test_semantic_generation_lifecycle_g5.py",
})

_BOUNDED_LUA_FIXTURE_TESTS = frozenset({
    "tests/pnc_conversation_architecture_contract_smoke.lua",
})

_BOUNDED_CODEBUILDER_MODULES = frozenset({
    "tools/semantic_harness/codebuilder/README.md",
    "tools/semantic_harness/codebuilder/__init__.py",
    "tools/semantic_harness/codebuilder/backend_registry.py",
    "tools/semantic_harness/codebuilder/build.py",
    "tools/semantic_harness/codebuilder/capability_abi.py",
    "tools/semantic_harness/codebuilder/catalog_naming.py",
    "tools/semantic_harness/codebuilder/conversation_assembly.py",
    "tools/semantic_harness/codebuilder/conversation_compiler.py",
    "tools/semantic_harness/codebuilder/conversation_discovery.py",
    "tools/semantic_harness/codebuilder/conversation_manifest.py",
    "tools/semantic_harness/codebuilder/conversation_registry.py",
    "tools/semantic_harness/codebuilder/convo_engine_authoring.py",
    "tools/semantic_harness/codebuilder/convo_engine_cli.py",
    "tools/semantic_harness/codebuilder/convo_engine_normalization.py",
    "tools/semantic_harness/codebuilder/convo_engine_ownership_inventory.py",
    "tools/semantic_harness/codebuilder/convo_engine_psdl_inventory.py",
    "tools/semantic_harness/codebuilder/convo_engine_s6m8_audit.py",
    "tools/semantic_harness/codebuilder/generation_recipe.json",
    "tools/semantic_harness/codebuilder/generation_recipe.py",
    "tools/semantic_harness/codebuilder/portable_runtime.py",
    "tools/semantic_harness/codebuilder/psdl_authoring_audit.py",
    "tools/semantic_harness/codebuilder/psdl_compact.py",
    "tools/semantic_harness/codebuilder/psdl_compiler.py",
    "tools/semantic_harness/codebuilder/psdl_inspect.py",
    "tools/semantic_harness/codebuilder/reconcile.py",
    "tools/semantic_harness/codebuilder/semantic_dialogue_ir.py",
    "tools/semantic_harness/codebuilder/semantic_trace.py",
    "tools/semantic_harness/codebuilder/service.py",
    "tools/semantic_harness/codebuilder/targets/pz_packages.json",
    "tools/semantic_harness/ui/studio_surface_builder.py",
})

_OBSOLETE_ALIAS_PATHS = frozenset({
    "tools/semantic_harness/studio/psdl_authoring_pane.py",
})


def _posix(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _iter_first_party_files(repo_root: Path) -> Iterable[Path]:
    if not repo_root.is_dir():
        return
    for path in sorted(repo_root.rglob("*")):
        if not path.is_file():
            continue
        if path.suffix.lower() not in _TEXT_EXTENSIONS:
            continue
        parts = path.relative_to(repo_root).parts
        if any(part in _SKIP_DIR_NAMES or part.startswith(".venv") for part in parts):
            continue
        yield path


def _source_root_for_owner(owner: str, repo_root: Path) -> Path:
    if owner == CORE_OWNER:
        return repo_root / "tools/semantic_harness/codebuilder/sources/conversation"
    if owner == HOOMANS_OWNER:
        return repo_root / "tools/providers/pnc/codebuilder/sources/conversation"
    return repo_root / "tools/providers/dt/codebuilder/sources/conversation"


def _is_under_relative(rel: str, root: Path, target_dir: Path) -> bool:
    if not target_dir.is_dir():
        return False
    target_rel = target_dir.relative_to(root).as_posix().rstrip("/") + "/"
    return rel.startswith(target_rel)


def _strip_lua_comments(text: str) -> str:
    lines: list[str] = []
    for line in text.splitlines():
        trimmed = line.lstrip()
        if trimmed.startswith("--"):
            lines.append("")
        else:
            lines.append(line)
    return "\n".join(lines)


def _sample_lines(lines: list[str], predicate=None, *, limit: int = 3) -> list[dict[str, Any]]:
    samples: list[dict[str, Any]] = []
    for idx, line in enumerate(lines, 1):
        if not _PSDL_RE.search(line):
            continue
        if predicate is not None and not predicate(line):
            continue
        samples.append({"line": idx, "text": line.strip()[:140]})
        if len(samples) >= limit:
            break
    return samples


def _classify_source_json(
    owner: str,
    rel: str,
    text: str,
    lines: list[str],
) -> tuple[str, str, list[str], list[dict[str, Any]], str]:
    tokens: list[str] = []
    try:
        doc = json.loads(text)
    except json.JSONDecodeError:
        doc = {}
    if "/psdl/" in f"/{rel}":
        tokens.append("legacy_psdl_directory")
    if isinstance(doc, Mapping):
        if doc.get("schema") == LEGACY_PSDL_SCHEMA:
            tokens.append("legacy_psdl_schema")
        meta = doc.get("metadata")
        if isinstance(meta, Mapping):
            target = meta.get("textTarget")
            domain = meta.get("textDomain")
            if isinstance(target, str) and (target == "psdl" or target.startswith("psdl/")):
                tokens.append(f"textTarget:{target}")
            if isinstance(domain, str) and ("pnc.psdl." in domain or domain.startswith("psdl.")):
                tokens.append(f"textDomain:{domain}")
    for m in _ACTIVE_CODE_TOKEN_RE.findall(text):
        if m not in tokens:
            tokens.append(m)
    samples = _sample_lines(lines)
    if tokens:
        return (
            CLASS_ACTIVE_IDENTITY_OR_OUTPUT,
            "canonical_source_json",
            tokens,
            samples,
            f"{owner} canonical ConvoEngine source contains active PSDL identity/textTarget/textDomain",
        )
    return (
        CLASS_GENERIC_SEMANTIC,
        "canonical_source_json",
        [],
        samples,
        f"{owner} canonical ConvoEngine source without active PSDL identity",
    )


def _classify_entry(
    owner: str,
    repo_root: Path,
    file_path: Path,
    *,
    core_root: Path,
    dt_root: Path | None,
) -> dict[str, Any] | None:
    rel = _posix(file_path, repo_root)
    text = file_path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    path_has_psdl = bool(_PSDL_RE.search(rel))
    text_has_psdl = bool(_PSDL_RE.search(text))
    if not path_has_psdl and not text_has_psdl:
        return None

    src_root = _source_root_for_owner(owner, repo_root)
    gen_root = generated_conversation_root(
        repo_root,
        owner,
        core_repository=core_root,
        dynamic_trading_repository=dt_root,
        runtime_root=repo_root,
    )
    trans_root = translation_root(
        repo_root,
        owner,
        core_repository=core_root,
        dynamic_trading_repository=dt_root,
        runtime_root=repo_root,
    )

    classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
    surface = "other"
    tokens: list[str] = []
    samples = _sample_lines(lines)
    rationale = ""

    if rel in _OBSOLETE_ALIAS_PATHS:
        classification = CLASS_OBSOLETE_ALIAS
        surface = "obsolete_alias_module"
        tokens = ["PSDLAuthoringPane"]
        rationale = "Zero-caller compatibility alias wrapper; remove after caller-zero"
    elif _is_under_relative(rel, repo_root, src_root):
        classification, surface, tokens, samples, rationale = _classify_source_json(
            owner, rel, text, lines
        )
    elif _is_under_relative(rel, repo_root, gen_root):
        surface = "generated_convo_engine_lua"
        tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(text)))
        if tokens or path_has_psdl:
            classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
            rationale = "Generated ConvoEngine runtime Lua emits active psdl.*/pnc.psdl.*/PSDL kind identity"
        else:
            classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
            rationale = "Generated ConvoEngine Lua header/comment reference without active identity"
    elif _is_under_relative(rel, repo_root, trans_root) and "/Conversation/" in f"/{rel}":
        surface = "conversation_translation"
        tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(text)))
        if "/Conversation/Text/psdl/" in f"/{rel}" or path_has_psdl or tokens:
            classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
            if "/Conversation/Text/psdl/" in f"/{rel}":
                tokens = ["Conversation/Text/psdl/", *tokens]
            rationale = "Maintained/generated Conversation translation path or key still uses legacy psdl namespace"
        else:
            classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
            rationale = "Conversation translation file with incidental prose reference only"
    elif rel in _BOUNDED_PYTHON_FIXTURE_TESTS or rel in _BOUNDED_LUA_FIXTURE_TESTS:
        surface = "bounded_migration_or_audit_test"
        classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
        tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(text)))[:8]
        rationale = "Bounded migration-reader or negative-audit regression fixture"
    elif rel.startswith("tests/") or "/tests/" in rel:
        surface = "active_contract_or_smoke_test"
        tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(text)))
        if tokens:
            classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
            rationale = "First-party test asserts active PSDL template/domain/kind identity"
        else:
            classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
            rationale = "Test fixture referencing migration-era PSDL prose/name without active legacy identity tokens"
    elif rel in _BOUNDED_CODEBUILDER_MODULES:
        surface = "core_codebuilder_module"
        emitter_hits = sorted(set(_COMPILER_ACTIVE_EMITTER_RE.findall(text)))
        if emitter_hits:
            classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
            tokens = emitter_hits
            rationale = "Core compiler/emitter still constructs active psdl.*/PSDL runtime output"
        else:
            classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
            tokens = ["LEGACY_PSDL_SCHEMA"] if LEGACY_PSDL_SCHEMA in text else []
            rationale = "Core CodeBuilder bounded migration reader, compatibility normalizer, or audit module"
    elif rel.startswith("Contents/mods/") and file_path.suffix.lower() == ".lua":
        if "/Semantics/" in f"/{rel}":
            surface = "generic_semantic_runtime_lua"
            code_only = _strip_lua_comments(text)
            tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(code_only)))
            if tokens:
                classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
                rationale = "Generic semantic Lua unexpectedly references active PSDL identity"
            else:
                classification = CLASS_GENERIC_SEMANTIC
                rationale = "Generic Core/adopter Semantic IR/NLU infrastructure"
        else:
            surface = "first_party_runtime_lua"
            code_only = _strip_lua_comments(text)
            tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(code_only)))
            if tokens:
                classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
                rationale = "First-party runtime Lua directly consumes active Conversation/Text/psdl, pnc.psdl.*, or psdl_* identity"
            else:
                classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
                rationale = "Host runtime/conversation Lua comment referencing migration history only"
    elif file_path.name in {"provider.json", "manifest.json"}:
        surface = "provider_or_manifest_config"
        tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(text)))
        if "sources/conversation/psdl/" in text or '"kind": "psdl"' in text or tokens:
            classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
            if "sources/conversation/psdl/" in text:
                tokens.append("sources/conversation/psdl/")
            rationale = "Provider or manifest configuration references stale PSDL path or kind"
        else:
            classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
            rationale = "Manifest configuration without active legacy path/kind"
    elif rel.startswith("tools/semantic_harness/studio/"):
        surface = "semantic_lab_studio"
        classification = (
            CLASS_ACTIVE_IDENTITY_OR_OUTPUT
            if _ACTIVE_CODE_TOKEN_RE.search(text)
            else CLASS_BOUNDED_MIGRATION_OR_FIXTURE
        )
        rationale = "Semantic Lab studio module"
    elif rel in {"tools/semantic_harness/codebuilder/convo_engine_authoring.py"}:
        surface = "core_codebuilder_module"
        classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
        rationale = "Core ConvoEngine authoring & bounded migration service"
    else:
        surface = "other_first_party"
        tokens = sorted(set(_ACTIVE_CODE_TOKEN_RE.findall(text)))
        if tokens or path_has_psdl:
            classification = CLASS_ACTIVE_IDENTITY_OR_OUTPUT
            rationale = "Unclassified first-party PSDL reference requiring inspection"
        else:
            classification = CLASS_BOUNDED_MIGRATION_OR_FIXTURE
            rationale = "Documentation/comment mention without active PSDL symbol"

    return {
        "owner": owner,
        "repository": repo_root.name,
        "path": rel,
        "surface": surface,
        "classification": classification,
        "tokens": tokens,
        "sampleLines": samples,
        "rationale": rationale,
    }


def classify_psdl_references(
    *,
    core_repository: str | Path,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    """Inventory and classify every first-party PSDL/psdl reference across all repos."""
    core_root = Path(core_repository).expanduser().resolve()
    hoomans_root = (
        Path(hoomans_repository).expanduser().resolve()
        if hoomans_repository is not None
        else None
    )
    dt_root = (
        Path(dynamic_trading_repository).expanduser().resolve()
        if dynamic_trading_repository is not None
        else None
    )

    repo_map: list[tuple[str, Path]] = [(CORE_OWNER, core_root)]
    if hoomans_root is not None:
        repo_map.append((HOOMANS_OWNER, hoomans_root))
    if dt_root is not None:
        repo_map.append((DT_COMMON_OWNER, dt_root))

    entries: list[dict[str, Any]] = []
    for owner, root in repo_map:
        for file_path in _iter_first_party_files(root):
            item = _classify_entry(
                owner,
                root,
                file_path,
                core_root=core_root,
                dt_root=dt_root,
            )
            if item is not None:
                entries.append(item)

    # Record verified generic semantic infrastructure preserved outside ConvoEngine.
    semantics_lua_count = len(list((core_root / "Contents/mods/PsychopatzCore").rglob("Semantics/**/*.lua")))
    generic_ir_present = False
    ir_module = core_root / "tools/semantic_harness/codebuilder/semantic_dialogue_ir.py"
    if ir_module.is_file():
        generic_ir_present = "psychopatz.semantic.dialogue-ir.v1" in ir_module.read_text(encoding="utf-8", errors="ignore")
    entries.append({
        "owner": CORE_OWNER,
        "repository": core_root.name,
        "path": "Contents/mods/PsychopatzCore/*/media/lua/**/Semantics/",
        "surface": "generic_semantic_infrastructure",
        "classification": CLASS_GENERIC_SEMANTIC,
        "tokens": ["psychopatz.semantic.dialogue-ir.v1"] if generic_ir_present else [],
        "sampleLines": [],
        "rationale": f"Generic Core Semantic IR/NLU/Predicate/Fuzzy infrastructure ({semantics_lua_count} Lua modules) preserved intact under Semantics/",
    })

    by_class = Counter(item["classification"] for item in entries)
    by_owner = Counter(item["owner"] for item in entries)
    by_surface = Counter(item["surface"] for item in entries)

    return {
        "schema": "psychopatz.convo-engine.s8r1-psdl-inventory.v1",
        "counts": {
            "total": len(entries),
            "byClassification": dict(sorted(by_class.items())),
            "byOwner": dict(sorted(by_owner.items())),
            "bySurface": dict(sorted(by_surface.items())),
        },
        "entries": entries,
    }


def scan_active_legacy_name_leakage(
    *,
    core_repository: str | Path,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    """Return S8R active legacy-name leakage violations across all audited surfaces."""
    inventory = classify_psdl_references(
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
    )
    violations: list[dict[str, Any]] = []
    for item in inventory["entries"]:
        cls = item["classification"]
        if cls not in {CLASS_ACTIVE_IDENTITY_OR_OUTPUT, CLASS_OBSOLETE_ALIAS}:
            continue
        code = (
            "obsolete_psdl_compatibility_alias"
            if cls == CLASS_OBSOLETE_ALIAS
            else "active_legacy_psdl_identity"
        )
        violations.append({
            "code": code,
            "owner": item["owner"],
            "path": item["path"],
            "surface": item["surface"],
            "tokens": item["tokens"],
            "message": f"{item['rationale']}: {item['path']} ({', '.join(item['tokens']) or item['surface']})",
        })
    return {
        "ok": len(violations) == 0,
        "inventoryCounts": inventory["counts"],
        "violations": violations,
    }


def write_psdl_inventory_report(
    output_path: str | Path,
    *,
    core_repository: str | Path,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    report = classify_psdl_references(
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
    )
    target = Path(output_path).expanduser().resolve()
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    return report
