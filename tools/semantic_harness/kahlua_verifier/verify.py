"""Read-only Project Zomboid *Kahlua* syntax verification (not native PZ).

Uses the game's own Kahlua LuaCompiler class via temporary Java reflection.
No Java/Kahlua interpreter implementation, Lua execution, game launch, source
writes, media watcher staging or user saves involved.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

REPOSITORY = Path(__file__).resolve().parents[3]
MAX_LUA_FILES = 512


def semantic_sources(
    repository: Path,
    source_roots: list[Path] | None = None,
) -> list[Path]:
    roots = [repository / "tools/semantic_harness/lua"]
    roots.extend(source_roots or ())
    files: list[Path] = []
    for root in roots:
        if root.is_dir():
            files.extend(root.rglob("*.lua"))
    return sorted(set(files))


def run_check(game_root: Path, files: list[Path],
              *, repository: Path = REPOSITORY) -> dict:
    root = repository.resolve(strict=True)
    jar = (game_root / "projectzomboid.jar").resolve(strict=True)
    java = game_root / "jre64/bin/java"
    javac = shutil.which("javac")
    if not java.is_file() or javac is None:
        raise ValueError("requires installed PZ bundled Java and local javac")
    if not 1 <= len(files) <= MAX_LUA_FILES:
        raise ValueError("requires 1..512 existing Lua sources")
    checked: list[Path] = []
    for path in files:
        if not path.is_file():
            raise ValueError("invalid or missing existing Lua source")
        resolved = path.resolve(strict=True)
        if (not resolved.is_relative_to(root) or not resolved.is_file()
                or resolved.suffix.lower() != ".lua"
                or resolved.stat().st_size > 256 * 1024):
            raise ValueError("invalid or oversized repository Lua source")
        checked.append(resolved)
    if len(set(checked)) != len(checked):
        raise ValueError("duplicate Lua source")
    java_source = Path(__file__).with_name("KahluaSyntaxProbe.java")
    with tempfile.TemporaryDirectory(prefix="semantic-kahlua-compiler-") as tmp:
        compiled = subprocess.run(
            [javac, "-d", tmp, str(java_source)],
            text=True, capture_output=True, timeout=30,
        )
        if compiled.returncode:
            raise RuntimeError("local javac failed: " + compiled.stderr[-900:])
        check = subprocess.run(
            [str(java), "-cp", str(jar) + os.pathsep + tmp,
             "KahluaSyntaxProbe", *[str(file) for file in checked]],
            text=True, capture_output=True, timeout=120,
        )
    return {
        "schemaVersion": 1, "type": "kahlua_compile_verification",
        "compiler": "installed_project_zomboid_kahlua_luacompiler",
        "gameLaunched": False, "luaExecuted": False,
        "filesChecked": len(checked),
        "passed": check.returncode == 0
            and check.stdout.strip().endswith(f"KAHLUA_COMPILED {len(checked)}"),
        "failure": check.stderr[-1200:] if check.returncode else None,
        "sourceKind": "CHECKED_OUT_LUA", "writesToSource": 0,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-root", type=Path, required=True,
                        help="installed PZ directory containing projectzomboid.jar")
    parser.add_argument("--repository", type=Path, default=REPOSITORY)
    parser.add_argument("--source-root", type=Path, action="append", default=[])
    parser.add_argument("--file", type=Path, action="append", default=[],
                        help="repository-relative Lua file (repeatable)")
    options = parser.parse_args()
    try:
        repository = options.repository.expanduser().resolve()
        files = ([repository / file for file in options.file]
                 if options.file else semantic_sources(repository, options.source_root))
        report = run_check(options.game_root, files, repository=repository)
    except (ValueError, OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        report = {"schemaVersion": 1,
                  "type": "kahlua_compile_verification",
                  "passed": False, "error": str(error)[:900]}
    print(json.dumps(report, ensure_ascii=False, separators=(",", ":")))
    return 0 if report["passed"] else 3


if __name__ == "__main__":
    raise SystemExit(main())
