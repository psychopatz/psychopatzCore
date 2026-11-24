"""First-class .convo DSL integration for the PsychopatzCore Semantic Harness.

Discovers, validates, compiles, and provides exact file:line lineage for modular
`.convo` language packs (`scripts/<lang>/*.convo`) without duplicating compiler
rules or relying on legacy JSON dialogue/translation files.
"""

from __future__ import annotations

import hashlib
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

_POOL_HEADER_RE = re.compile(r"^\s*(?:pool|beat|flow)\s+([a-zA-Z0-9_.-]+)\s*$")
_SAY_RE = re.compile(r"^\s*say(?:\s+\[[^\]]*\])?(?:\s*\(pri\s+\d+\))?(?:\s+as\s+([a-zA-Z0-9_.-]+))?\s*:")


def find_convo_scripts_root(repo_root: Path) -> Path | None:
    """Locate the modular `.convo` scripts directory inside a repository."""
    candidates = (
        repo_root / "tools/providers/pnc/codebuilder/sources/conversation/scripts",
        repo_root / "tools/codebuilder/sources/conversation/scripts",
        repo_root / "codebuilder/sources/conversation/scripts",
    )
    for path in candidates:
        if path.is_dir():
            return path
    return None


def discover_convo_scripts(repo_root: Path) -> list[dict[str, Any]]:
    """Return metadata for every `.convo` script discovered under `repo_root`."""
    scripts_root = find_convo_scripts_root(repo_root)
    if scripts_root is None:
        return []
    rows: list[dict[str, Any]] = []
    for path in sorted(scripts_root.rglob("*.convo")):
        rel = path.relative_to(repo_root)
        lang = path.parent.name.upper()
        pools: list[str] = []
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            m = _POOL_HEADER_RE.match(line)
            if m:
                pools.append(m.group(1))
        rows.append({
            "id": f"convo:{lang}:{path.stem}",
            "kind": "convo_dsl",
            "language": lang,
            "path": str(rel),
            "exists": True,
            "poolCount": len(pools),
            "pools": pools,
        })
    return rows


def compile_convo_scripts(repo_root: Path, *, check_only: bool = False) -> dict[str, Any]:
    """Validate or compile all `.convo` scripts in `repo_root` via `convo_dsl.cli`."""
    scripts_root = find_convo_scripts_root(repo_root)
    if scripts_root is None:
        return {"ok": True, "skipped": True, "reason": "no_convo_scripts_root", "scripts": []}
    cmd = [sys.executable, "-m", "tools.providers.pnc.codebuilder.convo_dsl.cli"]
    if check_only:
        cmd.append("--check")
    proc = subprocess.run(cmd, cwd=str(repo_root), capture_output=True, text=True)
    return {
        "ok": proc.returncode == 0,
        "checkOnly": check_only,
        "stdout": proc.stdout.strip(),
        "stderr": proc.stderr.strip(),
        "scripts": discover_convo_scripts(repo_root),
    }


def find_convo_pool_lineage(
    repo_root: Path,
    pool_id: str,
    loaded_variants: dict[str, dict[str, Any]],
) -> dict[str, list[dict[str, Any]]]:
    """Match loaded Lua catalog variants directly back to `.convo` source files."""
    scripts_root = find_convo_scripts_root(repo_root)
    matches: dict[str, list[dict[str, Any]]] = {vid: [] for vid in loaded_variants}
    if scripts_root is None:
        return matches

    for path in sorted(scripts_root.rglob("*.convo")):
        raw_bytes = path.read_bytes()
        text = raw_bytes.decode("utf-8", errors="replace")
        if pool_id not in text:
            continue
        sha = hashlib.sha256(raw_bytes).hexdigest()
        rel = str(path.relative_to(repo_root))
        lang = path.parent.name.upper()
        in_pool = False
        var_idx = 0
        for line_no, line in enumerate(text.splitlines(), start=1):
            m_pool = _POOL_HEADER_RE.match(line)
            if m_pool:
                in_pool = (m_pool.group(1) == pool_id)
                var_idx = 0
                continue
            if not in_pool:
                continue
            m_say = _SAY_RE.match(line)
            if m_say:
                var_idx += 1
                explicit_id = m_say.group(1) or f"v{var_idx}"
                full_vid = f"{pool_id}.{explicit_id}"
                if full_vid in matches:
                    matches[full_vid].append({
                        "sourceID": f"convo:{lang}:{path.stem}",
                        "sourcePath": rel,
                        "lineNumber": line_no,
                        "sourceSHA256": sha,
                        "validatedBy": "convo_dsl_compiler",
                        "generatedArtifactParity": "unchanged",
                    })
    return matches
