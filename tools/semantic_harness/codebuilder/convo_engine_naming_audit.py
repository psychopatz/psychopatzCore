"""Legacy PSDL reference inventory and active legacy-name leakage audit."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter
from collections.abc import Iterable, Sequence
from pathlib import Path
from typing import Any

from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    generated_conversation_root,
    translation_root,
)

NAMING_AUDIT_SCHEMA = "psychopatz.convo-engine.naming-audit.v1"
LEGACY_PSDL_SCHEMA = "psychopatz.semantic.dialogue-language.v1"

CLASS_OBSOLETE_ALIAS = "obsolete_compatibility_alias"
CLASS_ACTIVE_SCHEMA_OR_CONTRACT = "active_schema_or_contract"
CLASS_ACTIVE_CANONICAL_CLAIM = "active_canonical_claim"
CLASS_ACTIVE_INTERNAL_IDENTIFIER = "active_internal_identifier"
CLASS_GENERIC_SEMANTIC = "generic_semantic_infrastructure"
CLASS_HISTORICAL_NEGATIVE_DETECTION = "historical_negative_detection"

ACTIVE_CLASSIFICATIONS = frozenset({
    CLASS_OBSOLETE_ALIAS,
    CLASS_ACTIVE_SCHEMA_OR_CONTRACT,
    CLASS_ACTIVE_CANONICAL_CLAIM,
    CLASS_ACTIVE_INTERNAL_IDENTIFIER,
})

VALID_CLASSIFICATIONS = ACTIVE_CLASSIFICATIONS | frozenset({
    CLASS_GENERIC_SEMANTIC,
    CLASS_HISTORICAL_NEGATIVE_DETECTION,
})

_SKIP_DIR_NAMES = frozenset({
    ".git",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
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

_OBSOLETE_ALIAS_PATHS = frozenset({
    "tools/semantic_harness/studio/psdl_authoring_pane.py",
    "tools/semantic_harness/codebuilder/psdl_compiler.py",
    "tools/semantic_harness/codebuilder/psdl_compact.py",
    "tools/semantic_harness/codebuilder/psdl_inspect.py",
    "tools/semantic_harness/codebuilder/psdl_authoring_audit.py",
})

_OBSOLETE_ALIAS_FILENAMES = frozenset({
    "psdl_authoring_pane.py",
    "psdl_compiler.py",
    "psdl_compact.py",
    "psdl_inspect.py",
    "psdl_authoring_audit.py",
})

_HISTORICAL_DETECTOR_FILES = frozenset({
    "tools/semantic_harness/codebuilder/convo_engine_naming_audit.py",
    "tools/semantic_harness/codebuilder/convo_engine_integrity_audit.py",
    "tools/semantic_harness/codebuilder/convo_engine_modernization_inventory.py",
    "tools/semantic_harness/codebuilder/convo_engine_ownership_inventory.py",
})

_PSDL_RE = re.compile(r"psdl", re.IGNORECASE)

_OBSOLETE_ALIAS_RE = re.compile(
    r"""(?x)
    \bpsdl_authoring_pane\b
    | \bPSDLAuthoringPane\b
    | \bapp\.psdl_authoring\b
    | \bpsdl_authoring_frame\b
    | \bmigrate_legacy_text_identity\b
    | \brender_convo_runtime_plan\b
    """
)

_ALLOWED_NAMING_AUDIT_FUNCS = frozenset({
    "_compute_python_method_spans",
    "_is_historical_detector_line",
    "_classify_active_line",
    "_surface_for_rel",
    "_parse_args",
    "audit_legacy_psdl_references",
    "scan_active_legacy_name_leakage",
    "write_naming_audit_report",
    "main",
})

_ACTIVE_SCHEMA_CONTRACT_RE = re.compile(
    r"""(?x)
    ["']schema["']\s*:\s*["'](?:psdl\.[^"']*|psychopatz\.psdl\.[^"']*|psychopatz\.semantic\.dialogue-language\.v1)["']
    | \bpsychopatz\.psdl\.[a-z0-9_.:-]+
    | \bpsychopatz\.semantic\.dialogue-language\.v1\b
    | ["']kind["']\s*:\s*["'](?:psdl|PSDL)["']
    | \["kind"\]\s*=\s*["'](?:psdl|PSDL)["']
    | ==\s*["'](?:psdl|PSDL)["']
    | \bin\s*\([^)]*["'](?:psdl|PSDL)["']
    | ["']psdl\.[a-z0-9_.:-]+
    | \bpnc\.psdl\.[a-z0-9_.:-]+
    | Conversation/Text/psdl/
    | Conversation/PSDL
    | Semantics/Generated/Conversation/PSDL
    | sources/conversation/psdl/
    | ["']textTarget["']\s*:\s*["']psdl(?:/[^"']*)?["']
    | f["']psdl\.\{
    | ["']psdl/[^"']*["']
    """
)

_ACTIVE_CANONICAL_CLAIM_RE = re.compile(
    r"""(?x)
    \bPSDL\s+is\s+(?:the\s+)?canonical\b
    | \b(?:Core-owned|Core|Compact|authored|canonical|compiled)\s+PSDL\b
    | \bConvoEngine\s*/\s*PSDL\b
    | \bPSDL\s*/\s*(?:ConvoEngine|runtime|canonical|dialogue)\b
    | \bOptimize\s+PSDL\b
    | \bdomain\s+PSDL\s+package\b
    | \bPSDL\s+(?:
        document|profile|package|provenance|runtime\s+plan|record|records|
        source|sources|UI\s+projection|locale|recognition|offer|offers|
        wellbeing|personal|territory|work-orders|needs|greeting|parley|
        variants|plans|corpus|authoring|compiler|validator|adapter|fixture|
        payload|IR|behavior|behaviors|beat|beats|response|responses|trigger|
        triggers|realization|text\s+target|text\s+targets|text\s+locale|
        semantic|inventory|adoption|bucket|envelope|inspection|parser|dialogue
    )\b
    """,
    re.IGNORECASE,
)

_ACTIVE_IDENTIFIER_RE = re.compile(r"\b[A-Za-z_]*psdl[A-Za-z0-9_]*\b", re.IGNORECASE)

_ALLOWED_AUDIT_IDENTIFIERS = frozenset({
    "LEGACY_PSDL_SCHEMA",
    "NAMING_AUDIT_SCHEMA",
    "audit_legacy_psdl_references",
    "write_naming_audit_report",
    "scan_active_legacy_name_leakage",
    "activeCurrentPsdlIdentityCount",
    "active_current_psdl_identity_count",
    "historicalNegativeDetectionCount",
    "historical_negative_detection_count",
    "historicalNegativeDetections",
    "activeSchemaOrContractCount",
    "activeCanonicalClaimCount",
    "activeInternalIdentifierCount",
    "obsoleteAliasOrReaderCount",
    "psdlDirectories",
    "legacy_psdl_directory",
    "obsolete_psdl_compatibility_alias",
    "active_legacy_psdl_identity",
    "adopter_psdl_adapter",
})

_HISTORICAL_PREFIX_IDENT_RE = re.compile(
    r"^(?:_?(?:LEGACY|RETIRED|FORBIDDEN|OBSOLETE|HISTORICAL)_[A-Z0-9_]*PSDL[A-Z0-9_]*|_?legacy_psdl_[a-z0-9_]*|_?obsolete_psdl_[a-z0-9_]*|_?retired_psdl_[a-z0-9_]*)$"
)

_NEGATIVE_ASSERTION_LINE_RE = re.compile(
    r"""(?x)
    assertFalse\s*\(\s*hasattr\s*\(
    | assertNotEqual\s*\(
    | assertNotIn\s*\(
    | assertRaises\s*\(
    | assertFalse\s*\([^)]*(?:\["ok"\]|\["clean"\]|leakage|report|check)
    | assertEqual\s*\([^)]*(?:psdlDirectories|legacyNameViolations|activeCurrentPsdlIdentityCount|legacyCheck)
    | T\.equal\s*\([^)]*,\s*""\s*,\s*[^)]*eliminated
    | assertIn\s*\(\s*["'](?:active_legacy_psdl_identity|obsolete_psdl_compatibility_alias|legacy_schema_present|legacy_psdl_directory)["']
    """
)

_NEG_TEST_NAME_RE = re.compile(
    r"(?:reject|quarantine|remove|eliminat|strip_stale_migration|retired_path_reintroduction|fails_check|audit_catches|audit_rejects|forbid|disallow|distinguishes_.*_classifications)",
    re.IGNORECASE,
)

_POS_TEST_NAME_RE = re.compile(
    r"(?:test_allows_psdl_|test_production_compact_psdl_|test_generated_apology_psdl_)",
    re.IGNORECASE,
)

_MAX_HISTORICAL_DETECTIONS = 250


def _posix(path: Path, root: Path, root_prefix: str | None = None) -> str:
    prefix = root_prefix if root_prefix is not None else (root.as_posix().rstrip("/") + "/")
    path_str = path.as_posix()
    if path_str.startswith(prefix):
        return path_str[len(prefix):]
    return path.relative_to(root).as_posix()


def _iter_first_party_files(repo_root: Path) -> Iterable[Path]:
    if not repo_root.is_dir():
        return
    collected: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(repo_root):
        dirnames[:] = [
            d for d in sorted(dirnames)
            if d not in _SKIP_DIR_NAMES and not d.startswith(".venv")
        ]
        base = Path(dirpath)
        for name in sorted(filenames):
            path = base / name
            if path.suffix.lower() in _TEXT_EXTENSIONS:
                collected.append(path)
    for path in sorted(collected):
        yield path


def _relative_prefix(root: Path, target_dir: Path) -> str | None:
    if not target_dir.is_dir():
        return None
    return target_dir.relative_to(root).as_posix().rstrip("/") + "/"


def _source_root_for_owner(owner: str, repo_root: Path) -> Path:
    if owner == CORE_OWNER:
        return repo_root / "tools/semantic_harness/codebuilder/sources/conversation"
    if owner == HOOMANS_OWNER:
        return repo_root / "tools/providers/pnc/codebuilder/sources/conversation"
    return repo_root / "tools/providers/dt/codebuilder/sources/conversation"


def _match_lua_long_bracket(text: str, pos: int) -> int | None:
    """If text[pos:] opens a Lua long bracket `[=*[`, return number of `=` signs."""
    if pos >= len(text) or text[pos] != "[":
        return None
    idx = pos + 1
    while idx < len(text) and text[idx] == "=":
        idx += 1
    if idx < len(text) and text[idx] == "[":
        return idx - (pos + 1)
    return None


def _find_lua_long_close(text: str, start: int, eq_count: int) -> int:
    """Return index right after matching `]=*]` or len(text) if unterminated."""
    closing = "]" + ("=" * eq_count) + "]"
    found = text.find(closing, start)
    if found == -1:
        return len(text)
    return found + len(closing)


def _strip_lua_comments(text: str) -> str:
    """Strip both `--` line comments and `--[[...]]` / `--[=[...]=]` block comments, preserving line count."""
    out: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch in ("'", '"'):
            quote = ch
            out.append(ch)
            i += 1
            while i < n:
                c = text[i]
                out.append(c)
                i += 1
                if c == "\\" and i < n:
                    out.append(text[i])
                    i += 1
                elif c == quote:
                    break
            continue
        if ch == "-" and i + 1 < n and text[i + 1] == "-":
            eq_count = _match_lua_long_bracket(text, i + 2)
            if eq_count is not None:
                end = _find_lua_long_close(text, i + 2 + eq_count + 2, eq_count)
                comment_slice = text[i:end]
                out.append("".join("\n" if c == "\n" else " " for c in comment_slice))
                i = end
                continue
            newline = text.find("\n", i + 2)
            if newline == -1:
                i = n
            else:
                i = newline
            continue
        if ch == "[":
            eq_count = _match_lua_long_bracket(text, i)
            if eq_count is not None:
                end = _find_lua_long_close(text, i + eq_count + 2, eq_count)
                out.append(text[i:end])
                i = end
                continue
        out.append(ch)
        i += 1
    return "".join(out)


def _compute_python_method_spans(lines: list[str]) -> list[tuple[int, int, str, bool]]:
    """Return (start_line_1based, end_line_1based, func_name, is_negative_test) for Python defs."""
    defs: list[tuple[int, int, str]] = []
    def_re = re.compile(r"^(\s*)def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
    for idx, line in enumerate(lines, 1):
        m = def_re.match(line)
        if m:
            defs.append((idx, len(m.group(1)), m.group(2)))
    spans: list[tuple[int, int, str, bool]] = []
    total = len(lines)
    for pos, (start, indent, name) in enumerate(defs):
        end = total
        for next_start, next_indent, _ in defs[pos + 1:]:
            if next_indent <= indent:
                end = next_start - 1
                break
        body = "\n".join(lines[start - 1:end])
        is_neg_name = bool(_NEG_TEST_NAME_RE.search(name)) and not bool(_POS_TEST_NAME_RE.search(name))
        has_neg_assert = bool(_NEGATIVE_ASSERTION_LINE_RE.search(body))
        is_neg = is_neg_name or (
            has_neg_assert
            and not bool(_POS_TEST_NAME_RE.search(name))
            and not _PSDL_RE.search(name)
        )
        spans.append((start, end, name, is_neg))
    return spans


def _is_in_shard_or_root_kinds(lines: list[str], idx_zero: int) -> bool:
    """Return True when a line sits inside SHARD_KINDS, CONVO_ENGINE_SHARD_KINDS, or SOURCE_ROOT_SEGMENTS."""
    start = max(0, idx_zero - 20)
    window = "\n".join(lines[start:idx_zero + 1])
    for marker in ("SHARD_KINDS", "CONVO_ENGINE_SHARD_KINDS", "SOURCE_ROOT_SEGMENTS"):
        pos = window.rfind(marker)
        if pos != -1:
            tail = window[pos:]
            if ")" not in tail and "}" not in tail:
                return True
            if idx_zero - start == len(lines[start:idx_zero + 1]) - 1 and marker in lines[idx_zero]:
                return True
    return marker_on_line(lines[idx_zero])


def marker_on_line(line: str) -> bool:
    return any(
        marker in line
        for marker in ("SHARD_KINDS", "CONVO_ENGINE_SHARD_KINDS", "SOURCE_ROOT_SEGMENTS")
    )


def _is_historical_detector_line(
    rel: str,
    raw_line: str,
    lines: list[str],
    idx_zero: int,
    *,
    owner: str,
    enclosing_func: str | None,
    in_retired_recipe_section: bool,
    in_negative_test_method: bool,
    is_test_file: bool,
) -> tuple[bool, str]:
    """Return (is_historical_negative_detection, category)."""
    lowered = raw_line.lower()

    if rel == "AGENTS.md" and owner == CORE_OWNER:
        if "do not" in lowered or "never" in lowered or "forbid" in lowered or "preserve" in lowered:
            return True, "normative_prohibition"

    if rel == "tools/semantic_harness/codebuilder/README.md":
        if any(
            phrase in lowered
            for phrase in (
                "previous name",
                "migration compatibility only",
                "should not be introduced",
                "converges from",
                "retired",
                "eliminated",
            )
        ):
            return True, "historical_documentation"

    if rel == "tools/semantic_harness/codebuilder/generation_recipe.json" and in_retired_recipe_section:
        return True, "retired_path_guard"

    if rel in _HISTORICAL_DETECTOR_FILES:
        if rel == "tools/semantic_harness/codebuilder/convo_engine_naming_audit.py":
            if enclosing_func in _ALLOWED_NAMING_AUDIT_FUNCS:
                return True, "naming_audit_detector"
            if enclosing_func is None:
                window_start = max(0, idx_zero - 35)
                window = "\n".join(lines[window_start:idx_zero + 1])
                if (
                    idx_zero < 5
                    or any(tok in raw_line for tok in _ALLOWED_AUDIT_IDENTIFIERS)
                    or _HISTORICAL_PREFIX_IDENT_RE.search(raw_line)
                    or re.search(
                        r"(?:_OBSOLETE_|_ACTIVE_|_HISTORICAL_|_NEGATIVE_|_PSDL_RE|_ALLOWED_AUDIT|_ALLOWED_NAMING|_HISTORICAL_DETECTOR|_NEG_TEST|_POS_TEST|LEGACY_PSDL|NAMING_AUDIT|CLASS_)",
                        window,
                    )
                ):
                    return True, "naming_audit_detector"

        if rel == "tools/semantic_harness/codebuilder/convo_engine_integrity_audit.py":
            if any(
                marker in raw_line
                for marker in (
                    "legacy_schema_present",
                    "psdlDirectories",
                    "legacy_psdl_directory",
                    "psdl_dirs",
                    "Legacy psdl directory still exists",
                    "Conversation/PSDL",
                    'rglob("psdl")',
                    "activeCurrentPsdlIdentityCount",
                    "historicalNegativeDetectionCount",
                    "psychopatz.semantic.dialogue-language.v1",
                    "psychopatz.psdl.v2",
                )
            ):
                return True, "integrity_audit_detector"

        if rel == "tools/semantic_harness/codebuilder/convo_engine_modernization_inventory.py":
            if enclosing_func == "_count_legacy_schema_readers" or any(
                marker in raw_line
                for marker in (
                    "activeCurrentPsdlIdentityCount",
                    "historicalNegativeDetectionCount",
                    "psdl_compiler.py",
                    "psdl_compact.py",
                    "psdl_inspect.py",
                    "psdl_authoring_audit.py",
                    "psdl_authoring_pane.py",
                )
            ):
                return True, "modernization_legacy_reader_detector"

        if rel == "tools/semantic_harness/codebuilder/convo_engine_ownership_inventory.py":
            window_start = max(0, idx_zero - 15)
            window = "\n".join(lines[window_start:idx_zero + 1])
            if any(
                marker in raw_line
                for marker in (
                    "PNC/Conversation/PSDL/",
                    "adopter_psdl_adapter",
                    "Remove redundant PSDL/Psdl",
                    'part.lower() == "psdl"',
                    "Conversation/PSDL",
                    "PNC_ConversationPSDLBlocks",
                    "PSDL_PLANS",
                    "PSDL_RESPONSE_TEMPLATES",
                    '"PSDL" in req',
                    "drops Psdl/Catalog wrapper segments",
                    "legacy ConvoEngine/PSDL references",
                )
            ) or "_HOOMANS_CONVO_PREFIXES" in window:
                return True, "ownership_legacy_path_detector"

    # Explicit historical/forbidden constants anywhere in Python code.
    idents = _ACTIVE_IDENTIFIER_RE.findall(raw_line)
    if idents and all(
        ident in _ALLOWED_AUDIT_IDENTIFIERS or bool(_HISTORICAL_PREFIX_IDENT_RE.match(ident))
        for ident in idents
    ) and not _ACTIVE_SCHEMA_CONTRACT_RE.search(raw_line) and not _OBSOLETE_ALIAS_RE.search(raw_line):
        return True, "historical_constant_or_metric"

    if is_test_file:
        if _NEGATIVE_ASSERTION_LINE_RE.search(raw_line):
            return True, "negative_rejection_assertion"
        if "legacy psdl crud removal" in lowered:
            return True, "negative_rejection_test_doc"
        if rel.endswith(".lua"):
            window = "\n".join(lines[max(0, idx_zero - 5):min(len(lines), idx_zero + 6)])
            if ("legacyPsdl" in raw_line or "/psdl" in raw_line or "psdl source bucket is eliminated" in lowered) and (
                "eliminated" in window.lower() or "2>/dev/null" in window
            ):
                return True, "negative_rejection_lua_contract"
        if in_negative_test_method:
            return True, "negative_rejection_test_fixture"

    return False, ""


def _classify_active_line(
    raw_line: str,
    code_line: str,
    *,
    is_lua: bool,
    is_generic_semantics_lua: bool,
    in_shard_or_root_kinds: bool,
) -> tuple[str, list[str], str] | None:
    """Return (classification, tokens, message) or None when generic semantic infra."""
    check_code = code_line if is_lua else raw_line

    # 1. Obsolete compatibility aliases
    alias_hits = _OBSOLETE_ALIAS_RE.findall(check_code)
    if alias_hits:
        return (
            CLASS_OBSOLETE_ALIAS,
            sorted(set(alias_hits)),
            "Active reference to obsolete PSDL compatibility alias",
        )

    # 2. Active schema or contract tokens
    contract_hits = _ACTIVE_SCHEMA_CONTRACT_RE.findall(check_code)
    if not contract_hits and in_shard_or_root_kinds and re.search(r"""["']psdl/?["']""", check_code):
        contract_hits = ['"psdl"']
    if contract_hits:
        return (
            CLASS_ACTIVE_SCHEMA_OR_CONTRACT,
            sorted(set(contract_hits)),
            "Active legacy PSDL schema, shard kind, text target/domain, or path contract",
        )

    # 3. Active canonical claim in prose/docstrings/comments/assertions
    claim_hits = _ACTIVE_CANONICAL_CLAIM_RE.findall(raw_line)
    if claim_hits:
        return (
            CLASS_ACTIVE_CANONICAL_CLAIM,
            sorted(set(claim_hits)),
            "Documentation, comment, or message claims PSDL is current/canonical surface",
        )

    # Generic Core Semantics/ Lua with comment-only incidental mention and no canonical claim
    if is_generic_semantics_lua and not _PSDL_RE.search(code_line):
        return None

    # 4. Active internal identifier
    raw_idents = _ACTIVE_IDENTIFIER_RE.findall(check_code)
    active_idents = [
        ident for ident in raw_idents
        if ident not in _ALLOWED_AUDIT_IDENTIFIERS and not _HISTORICAL_PREFIX_IDENT_RE.match(ident)
    ]
    if active_idents:
        return (
            CLASS_ACTIVE_INTERNAL_IDENTIFIER,
            sorted(set(active_idents)),
            "Active source/test identifier still embeds legacy PSDL naming",
        )

    # Fallback for any remaining unexempted PSDL token on a non-Lua-Semantics line
    if is_lua and not _PSDL_RE.search(code_line):
        return (
            CLASS_ACTIVE_CANONICAL_CLAIM,
            ["PSDL"],
            "Lua comment contains unretired PSDL reference",
        )
    return (
        CLASS_ACTIVE_CANONICAL_CLAIM,
        ["PSDL"],
        "Unretired PSDL prose or configuration reference",
    )


def _surface_for_rel(
    rel: str,
    file_path: Path,
    *,
    src_prefix: str,
    gen_prefix: str,
    trans_prefix: str,
) -> str:
    if rel in _OBSOLETE_ALIAS_PATHS or file_path.name in _OBSOLETE_ALIAS_FILENAMES:
        return "obsolete_alias_module"
    if src_prefix and rel.startswith(src_prefix):
        return "canonical_source_json"
    if gen_prefix and rel.startswith(gen_prefix):
        return "generated_convo_engine_lua"
    if trans_prefix and rel.startswith(trans_prefix) and "/Conversation/" in f"/{rel}":
        return "conversation_translation"
    if rel.startswith("tests/") or "/tests/" in rel:
        return "test_or_fixture"
    if rel.startswith("Contents/mods/") and file_path.suffix.lower() == ".lua":
        if "/Semantics/" in f"/{rel}":
            return "generic_semantic_runtime_lua"
        return "first_party_runtime_lua"
    if rel.startswith("tools/semantic_harness/codebuilder/"):
        return "core_codebuilder_module"
    if rel.startswith("tools/semantic_harness/studio/") or rel.startswith("tools/semantic_harness/ui/"):
        return "semantic_lab_studio"
    if rel.startswith("tools/"):
        return "first_party_tooling"
    if rel == "AGENTS.md":
        return "repository_instructions"
    return "other_first_party"


def _retired_line_flags(rel: str, lines: list[str]) -> list[bool]:
    """For generation_recipe.json, mark lines belonging to the top-level `"retired"` array."""
    flags = [False] * len(lines)
    if rel != "tools/semantic_harness/codebuilder/generation_recipe.json":
        return flags
    in_retired = False
    bracket_depth = 0
    for idx, line in enumerate(lines):
        if not in_retired:
            if '"retired"' in line and "[" in line:
                in_retired = True
                bracket_depth = line.count("[") - line.count("]")
                flags[idx] = True
                if bracket_depth <= 0:
                    in_retired = False
        else:
            flags[idx] = True
            bracket_depth += line.count("[") - line.count("]")
            if bracket_depth <= 0:
                in_retired = False
    return flags


def audit_legacy_psdl_references(
    *,
    core_repository: str | Path,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    """Audit every first-party PSDL/psdl reference across Core, ProjectHoomans, and DynamicTrading."""
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

    violations: list[dict[str, Any]] = []
    historical_detections: list[dict[str, Any]] = []
    by_classification: Counter[str] = Counter()
    by_owner: Counter[str] = Counter()
    by_surface: Counter[str] = Counter()
    matched_files: set[tuple[str, str]] = set()
    total_hits = 0
    historical_count = 0
    generic_semantic_count = 0

    for owner, root in repo_map:
        src_prefix = _relative_prefix(root, _source_root_for_owner(owner, root)) or ""
        gen_prefix = _relative_prefix(
            root,
            generated_conversation_root(
                root,
                owner,
                core_repository=core_root,
                dynamic_trading_repository=dt_root,
                runtime_root=root,
            ),
        ) or ""
        trans_prefix = _relative_prefix(
            root,
            translation_root(
                root,
                owner,
                core_repository=core_root,
                dynamic_trading_repository=dt_root,
                runtime_root=root,
            ),
        ) or ""
        root_prefix = root.as_posix().rstrip("/") + "/"

        for file_path in _iter_first_party_files(root):
            rel = _posix(file_path, root, root_prefix)
            path_has_psdl = "psdl" in rel.lower()
            text = file_path.read_text(encoding="utf-8", errors="replace")
            text_has_psdl = "psdl" in text.lower()
            if not path_has_psdl and not text_has_psdl:
                continue

            matched_files.add((owner, rel))
            surface = _surface_for_rel(
                rel,
                file_path,
                src_prefix=src_prefix,
                gen_prefix=gen_prefix,
                trans_prefix=trans_prefix,
            )
            is_lua = file_path.suffix.lower() == ".lua"
            is_py = file_path.suffix.lower() == ".py"
            is_test_file = rel.startswith("tests/") or "/tests/" in rel
            is_generic_semantics_lua = (
                is_lua
                and rel.startswith("Contents/mods/")
                and "/Semantics/" in f"/{rel}"
            )

            # 1. Path-level active checks
            if path_has_psdl:
                total_hits += 1
                if rel in _OBSOLETE_ALIAS_PATHS or file_path.name in _OBSOLETE_ALIAS_FILENAMES:
                    cls = CLASS_OBSOLETE_ALIAS
                    code = "obsolete_psdl_compatibility_alias"
                    tokens = [file_path.name]
                    msg = f"Obsolete PSDL compatibility alias path remains: {rel}"
                elif (
                    "/psdl/" in f"/{rel}"
                    or rel.endswith("/psdl")
                    or "Conversation/Text/psdl/" in rel
                    or "Conversation/PSDL/" in rel
                    or "Semantics/Generated/Conversation/PSDL/" in rel
                ):
                    cls = CLASS_ACTIVE_SCHEMA_OR_CONTRACT
                    code = "active_legacy_psdl_identity"
                    tokens = ["legacy_psdl_path"]
                    msg = f"Active path still uses retired PSDL directory/contract segment: {rel}"
                else:
                    cls = CLASS_ACTIVE_INTERNAL_IDENTIFIER
                    code = "active_legacy_psdl_identity"
                    tokens = [file_path.name]
                    msg = f"Active file path still carries legacy PSDL identifier: {rel}"
                by_classification[cls] += 1
                by_owner[owner] += 1
                by_surface[surface] += 1
                violations.append({
                    "code": code,
                    "classification": cls,
                    "owner": owner,
                    "path": rel,
                    "line": None,
                    "surface": surface,
                    "tokens": tokens,
                    "excerpt": rel,
                    "message": msg,
                })

            # 2. Line-level semantic classification (no file gets a blanket exemption)
            raw_lines = text.splitlines()
            stripped_lines = _strip_lua_comments(text).splitlines() if is_lua else raw_lines
            if len(stripped_lines) < len(raw_lines):
                stripped_lines = stripped_lines + [""] * (len(raw_lines) - len(stripped_lines))
            retired_flags = _retired_line_flags(rel, raw_lines)
            method_spans = _compute_python_method_spans(raw_lines) if is_py else []

            def _method_info(line_num: int) -> tuple[str | None, bool]:
                for start, end, name, is_neg in method_spans:
                    if start <= line_num <= end:
                        return name, is_neg
                return None, False

            for idx_zero, raw_line in enumerate(raw_lines):
                if not _PSDL_RE.search(raw_line):
                    continue
                line_num = idx_zero + 1
                code_line = stripped_lines[idx_zero]
                total_hits += 1
                excerpt = raw_line.strip()[:160]
                enclosing_func, in_neg_method = _method_info(line_num)

                is_hist, hist_cat = _is_historical_detector_line(
                    rel,
                    raw_line,
                    raw_lines,
                    idx_zero,
                    owner=owner,
                    enclosing_func=enclosing_func,
                    in_retired_recipe_section=retired_flags[idx_zero],
                    in_negative_test_method=in_neg_method,
                    is_test_file=is_test_file,
                )
                if is_hist:
                    historical_count += 1
                    by_classification[CLASS_HISTORICAL_NEGATIVE_DETECTION] += 1
                    by_owner[owner] += 1
                    by_surface[surface] += 1
                    if len(historical_detections) < _MAX_HISTORICAL_DETECTIONS:
                        historical_detections.append({
                            "owner": owner,
                            "path": rel,
                            "line": line_num,
                            "category": hist_cat,
                            "excerpt": excerpt,
                        })
                    continue

                active_result = _classify_active_line(
                    raw_line,
                    code_line,
                    is_lua=is_lua,
                    is_generic_semantics_lua=is_generic_semantics_lua,
                    in_shard_or_root_kinds=_is_in_shard_or_root_kinds(raw_lines, idx_zero),
                )
                if active_result is None:
                    generic_semantic_count += 1
                    by_classification[CLASS_GENERIC_SEMANTIC] += 1
                    by_owner[owner] += 1
                    by_surface[surface] += 1
                    continue

                cls, tokens, rationale = active_result
                code = (
                    "obsolete_psdl_compatibility_alias"
                    if cls == CLASS_OBSOLETE_ALIAS
                    else "active_legacy_psdl_identity"
                )
                by_classification[cls] += 1
                by_owner[owner] += 1
                by_surface[surface] += 1
                violations.append({
                    "code": code,
                    "classification": cls,
                    "owner": owner,
                    "path": rel,
                    "line": line_num,
                    "surface": surface,
                    "tokens": tokens,
                    "excerpt": excerpt,
                    "message": f"{rationale}: {rel}:{line_num} ({', '.join(tokens) or surface})",
                })

    active_schema_count = by_classification[CLASS_ACTIVE_SCHEMA_OR_CONTRACT]
    active_claim_count = by_classification[CLASS_ACTIVE_CANONICAL_CLAIM]
    active_ident_count = by_classification[CLASS_ACTIVE_INTERNAL_IDENTIFIER]
    obsolete_alias_count = by_classification[CLASS_OBSOLETE_ALIAS]
    active_total = (
        active_schema_count
        + active_claim_count
        + active_ident_count
        + obsolete_alias_count
    )

    counts = {
        "totalFiles": len(matched_files),
        "totalHits": total_hits,
        "activeCurrentPsdlIdentityCount": active_total,
        "activeSchemaOrContractCount": active_schema_count,
        "activeCanonicalClaimCount": active_claim_count,
        "activeInternalIdentifierCount": active_ident_count,
        "obsoleteAliasOrReaderCount": obsolete_alias_count,
        "historicalNegativeDetectionCount": historical_count,
        "genericSemanticInfrastructureCount": generic_semantic_count,
        "byClassification": dict(sorted(by_classification.items())),
        "byOwner": dict(sorted(by_owner.items())),
        "bySurface": dict(sorted(by_surface.items())),
    }

    return {
        "schema": NAMING_AUDIT_SCHEMA,
        "ok": active_total == 0,
        "activeCurrentPsdlIdentityCount": active_total,
        "historicalNegativeDetectionCount": historical_count,
        "counts": counts,
        "violations": violations,
        "historicalNegativeDetections": historical_detections,
    }


def scan_active_legacy_name_leakage(
    *,
    core_repository: str | Path,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    """Return active legacy-name leakage violations across all audited surfaces."""
    return audit_legacy_psdl_references(
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
    )


def write_naming_audit_report(
    output_path: str | Path,
    *,
    core_repository: str | Path,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    report = audit_legacy_psdl_references(
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


def _parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run line-level ConvoEngine legacy PSDL naming audit across repositories.",
    )
    parser.add_argument("--core-repository", default=".", help="Path to psychopatzCore repository")
    parser.add_argument("--hoomans-repository", default=None, help="Path to ProjectHoomans repository")
    parser.add_argument("--dynamic-trading-repository", default=None, help="Path to DynamicTrading repository")
    parser.add_argument("--summary", action="store_true", help="Print compact summary JSON")
    parser.add_argument("--json", action="store_true", help="Print full JSON report")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = _parse_args(argv)
    report = audit_legacy_psdl_references(
        core_repository=args.core_repository,
        hoomans_repository=args.hoomans_repository,
        dynamic_trading_repository=args.dynamic_trading_repository,
    )
    if args.summary and not args.json:
        by_file: dict[str, int] = Counter()
        for item in report["violations"]:
            by_file[f"{item['owner']}:{item['path']}"] += 1
        payload = {
            "schema": report["schema"],
            "ok": report["ok"],
            "activeCurrentPsdlIdentityCount": report["activeCurrentPsdlIdentityCount"],
            "historicalNegativeDetectionCount": report["historicalNegativeDetectionCount"],
            "counts": report["counts"],
            "violatingFiles": dict(sorted(by_file.items())),
            "sampleViolations": report["violations"][:20],
        }
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["ok"] else 1


__all__ = [
    "ACTIVE_CLASSIFICATIONS",
    "CLASS_ACTIVE_CANONICAL_CLAIM",
    "CLASS_ACTIVE_INTERNAL_IDENTIFIER",
    "CLASS_ACTIVE_SCHEMA_OR_CONTRACT",
    "CLASS_GENERIC_SEMANTIC",
    "CLASS_HISTORICAL_NEGATIVE_DETECTION",
    "CLASS_OBSOLETE_ALIAS",
    "LEGACY_PSDL_SCHEMA",
    "NAMING_AUDIT_SCHEMA",
    "VALID_CLASSIFICATIONS",
    "audit_legacy_psdl_references",
    "main",
    "scan_active_legacy_name_leakage",
    "write_naming_audit_report",
]


if __name__ == "__main__":
    sys.exit(main())
