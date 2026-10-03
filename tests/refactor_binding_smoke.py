#!/usr/bin/env python3
"""Detect private Lua helper leaks introduced by module splits.

Lua ``local`` bindings are file-scoped.  When a split module calls a helper
without importing it, Lua compiles the name as an ``_ENV`` lookup; in-game
that later becomes an attempt to call a missing global.  This smoke test
compares bytecode ``_ENV`` reads with private ``local function`` declarations
in sibling files.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOD_ROOT = ROOT / "Contents/mods/PsychopatzCore"
VERSION = re.compile(r"^\d+\.\d+$")
LOCAL_FUNCTION = re.compile(
    r"^\s*local\s+function\s+([A-Za-z_]\w*)\s*\(",
    re.MULTILINE,
)
LOCAL_FUNCTION_ASSIGNMENT = re.compile(
    r"^\s*local\s+([A-Za-z_]\w*)\s*=\s*function\b",
    re.MULTILINE,
)
ENV_READ = re.compile(
    r"\[(\d+)\].*?GETTABUP\s+\d+\s+\d+\s+-?\d+"
    r".*?;\s*_ENV\s+\"([^\"]+)\""
)


@dataclass(frozen=True)
class SourceTree:
    label: str
    root: Path


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    name: str
    owner: Path


def newest_runtime() -> Path:
    runtimes = [
        child
        for child in MOD_ROOT.iterdir()
        if child.is_dir() and VERSION.fullmatch(child.name)
    ]
    if not runtimes:
        raise RuntimeError(f"no numeric runtime under {MOD_ROOT}")
    return max(runtimes, key=lambda path: tuple(map(int, path.name.split("."))))


def source_trees(runtime: Path) -> list[SourceTree]:
    candidates = [
        SourceTree("common", MOD_ROOT / "common/media/lua"),
        SourceTree(runtime.name, runtime / "media/lua"),
    ]
    return [tree for tree in candidates if tree.root.is_dir()]


def all_lua_files(trees: list[SourceTree]) -> set[Path]:
    return {
        path
        for tree in trees
        for path in tree.root.rglob("*.lua")
        if path.is_file()
    }


def git_paths(*arguments: str) -> set[Path]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), *arguments],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    if result.returncode != 0:
        return set()
    return {ROOT / line for line in result.stdout.splitlines() if line}


def changed_lua_files(files: set[Path]) -> set[Path]:
    changed: set[Path] = set()
    for arguments in (
        ("diff", "--name-only", "--diff-filter=ACMRTUXB"),
        ("diff", "--cached", "--name-only", "--diff-filter=ACMRTUXB"),
        ("ls-files", "--others", "--exclude-standard"),
    ):
        changed.update(git_paths(*arguments))
    return {
        path
        for path in changed
        if path in files and path.suffix == ".lua"
    }


def logical_path(path: Path, trees: list[SourceTree]) -> Path:
    for tree in trees:
        try:
            return path.relative_to(tree.root)
        except ValueError:
            continue
    raise ValueError(f"{path} is not under a Core Lua source tree")


def local_functions(path: Path) -> set[str]:
    source = path.read_text(encoding="utf-8", errors="replace")
    return set(LOCAL_FUNCTION.findall(source)) | set(
        LOCAL_FUNCTION_ASSIGNMENT.findall(source)
    )


def bytecode_reads(path: Path, luac: str) -> tuple[list[tuple[int, str]], str | None]:
    result = subprocess.run(
        [luac, "-l", "-p", str(path)],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        return [], result.stderr.strip() or f"{luac} returned {result.returncode}"
    return [(int(line), name) for line, name in ENV_READ.findall(result.stdout)], None


def display_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def scan(
    files: set[Path],
    trees: list[SourceTree],
    focus: set[Path],
    luac: str,
) -> tuple[list[Finding], list[str]]:
    ordered_files = sorted(files)
    helpers = {path: local_functions(path) for path in ordered_files}
    owners: dict[tuple[Path, str], list[Path]] = defaultdict(list)
    for path, names in helpers.items():
        parent = logical_path(path, trees).parent
        for name in names:
            owners[(parent, name)].append(path)

    findings: set[Finding] = set()
    compile_errors: list[str] = []
    for path in sorted(focus):
        reads, error = bytecode_reads(path, luac)
        if error:
            compile_errors.append(f"{display_path(path)}: {error}")
            continue
        for line, name in reads:
            if name in helpers[path]:
                continue
            sibling_owners = [
                owner
                for owner in owners[(logical_path(path, trees).parent, name)]
                if owner != path
            ]
            for owner in sibling_owners:
                findings.add(Finding(path, line, name, owner))

    return sorted(
        findings,
        key=lambda finding: (display_path(finding.path), finding.line, finding.name),
    ), compile_errors


def parse_args(arguments: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--all",
        action="store_true",
        help="scan every Core Lua file instead of only Git-changed files",
    )
    parser.add_argument("--luac", default="luac", help="Lua compiler executable")
    return parser.parse_args(arguments)


def main(arguments: list[str] | None = None) -> int:
    options = parse_args(arguments or sys.argv[1:])
    try:
        runtime = newest_runtime()
        trees = source_trees(runtime)
    except (OSError, RuntimeError) as error:
        print(f"refactor smoke setup failed: {error}", file=sys.stderr)
        return 2

    files = all_lua_files(trees)
    focus = files if options.all else changed_lua_files(files)
    tree_labels = ", ".join(tree.label for tree in trees)

    if not options.all and not focus:
        print(f"PASS cross-file binding smoke: no changed Lua files ({tree_labels})")
        return 0

    findings, compile_errors = scan(files, trees, focus, options.luac)
    mode = "full" if options.all else "changed"
    print(
        f"Scanned {len(focus)} {mode} Lua files across {tree_labels}; "
        f"indexed {len(files)} source files"
    )

    if compile_errors:
        print(f"\nFAIL: {len(compile_errors)} Lua files did not compile")
        for error in compile_errors:
            print(f"- {error}")

    if findings:
        print(f"\nFAIL: {len(findings)} cross-file private-helper binding(s)")
        for finding in findings:
            print(
                f"- {display_path(finding.path)}:{finding.line}: "
                f"`{finding.name}` is owned by sibling {display_path(finding.owner)}"
            )
    else:
        print("PASS: no cross-file private-helper bindings found")

    return 1 if compile_errors or findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
