"""Dynamic static-graph test detecting top-level Lua require() cycles.

Project Zomboid's Kahlua2 loader guards against recursive require() by returning
nil instead of the module table, which surfaces later as cryptic
"attempted index of non-table: null" crashes. This test scans all Lua modules
across psychopatzCore, ProjectHoomans, and DynamicTrading to catch any
top-level require() cycle immediately.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

WORKSHOP_ROOT = Path(__file__).resolve().parents[2]
SCAN_REPOS = ("psychopatzCore", "ProjectHoomans", "DynamicTrading")

# Matches top-level require "foo/bar" or require("foo/bar") / require('foo/bar')
REQUIRE_RE = re.compile(r"""\brequire\s*(?:\(\s*)?["']([^"']+)["']""")
BLOCK_OPEN_RE = re.compile(r"\b(?:function|if|for|while|repeat|do)\b")
BLOCK_CLOSE_RE = re.compile(r"\b(?:end|until)\b")


def _strip_line_comment(line: str) -> str:
    in_single = False
    in_double = False
    i = 0
    n = len(line)
    while i < n:
        ch = line[i]
        if ch == "\\" and (in_single or in_double):
            i += 2
            continue
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "-" and not in_single and not in_double and i + 1 < n and line[i + 1] == "-":
            return line[:i]
        i += 1
    return line


def extract_top_level_requires(source: str) -> list[tuple[int, str]]:
    """Return (line_no, module_name) for top-level require() calls (not inside functions)."""
    results: list[tuple[int, str]] = []
    func_depth = 0
    block_stack: list[str] = []
    in_long_comment = False

    for line_no, raw_line in enumerate(source.splitlines(), start=1):
        line = raw_line
        if in_long_comment:
            end_idx = line.find("]]")
            if end_idx == -1:
                continue
            line = line[end_idx + 2 :]
            in_long_comment = False

        if "--[[" in line:
            start_idx = line.find("--[[")
            end_idx = line.find("]]", start_idx + 4)
            if end_idx == -1:
                line = line[:start_idx]
                in_long_comment = True
            else:
                line = line[:start_idx] + line[end_idx + 2 :]

        code = _strip_line_comment(line)
        if not code.strip():
            continue

        if func_depth == 0:
            for match in REQUIRE_RE.finditer(code):
                mod = match.group(1).strip()
                if mod.endswith(".lua"):
                    mod = mod[:-4]
                results.append((line_no, mod))

        # Track function nesting so lazy requires inside function bodies are ignored.
        # Strip string literals before counting keywords.
        no_strings = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', " ", code)
        tokens = re.findall(r"\b(?:function|if|for|while|repeat|do|end|until|elseif)\b", no_strings)
        for tok in tokens:
            if tok == "function":
                block_stack.append("function")
                func_depth += 1
            elif tok in ("if", "for", "while", "repeat"):
                block_stack.append(tok)
            elif tok == "do":
                # `for ... do` and `while ... do` already pushed for/while.
                if not block_stack or block_stack[-1] not in ("for", "while"):
                    block_stack.append("do")
            elif tok in ("end", "until"):
                if block_stack:
                    popped = block_stack.pop()
                    if popped == "function":
                        func_depth = max(0, func_depth - 1)

    return results


def module_id_from_path(lua_path: Path) -> str | None:
    parts = lua_path.parts
    for idx, part in enumerate(parts):
        if part == "lua" and idx + 2 < len(parts) and parts[idx + 1] in ("shared", "server", "client"):
            rel = Path(*parts[idx + 2 :]).with_suffix("")
            return rel.as_posix()
    return None


def find_cycles(graph: dict[str, list[tuple[int, str]]]) -> list[list[str]]:
    """Return all elementary top-level require cycles in `graph`."""
    state: dict[str, int] = {}  # 0=unvisited, 1=visiting, 2=done
    path: list[str] = []
    cycles: list[list[str]] = []
    seen_sigs: set[tuple[str, ...]] = set()

    def dfs(node: str) -> None:
        state[node] = 1
        path.append(node)
        for _, dep in graph.get(node, ()):
            if dep not in graph:
                continue
            dep_state = state.get(dep, 0)
            if dep_state == 1:
                idx = path.index(dep)
                cycle = path[idx:] + [dep]
                # Canonicalize rotation to deduplicate the same cycle.
                core = cycle[:-1]
                min_i = core.index(min(core))
                sig = tuple(core[min_i:] + core[:min_i])
                if sig not in seen_sigs:
                    seen_sigs.add(sig)
                    cycles.append(cycle)
            elif dep_state == 0:
                dfs(dep)
        path.pop()
        state[node] = 2

    for node in sorted(graph):
        if state.get(node, 0) == 0:
            dfs(node)
    return cycles


def build_workspace_require_graph(repos: tuple[str, ...] = SCAN_REPOS) -> dict[str, list[tuple[int, str]]]:
    graph: dict[str, list[tuple[int, str]]] = {}
    for repo in repos:
        contents_dir = WORKSHOP_ROOT / repo / "Contents" / "mods"
        if not contents_dir.exists():
            continue
        for lua_file in sorted(contents_dir.rglob("*.lua")):
            mod_id = module_id_from_path(lua_file)
            if not mod_id:
                continue
            text = lua_file.read_text(encoding="utf-8", errors="ignore")
            deps = extract_top_level_requires(text)
            if mod_id in graph:
                graph[mod_id].extend(deps)
            else:
                graph[mod_id] = deps
    return graph


class LuaRequireCycleTests(unittest.TestCase):
    def test_detector_catches_synthetic_cycle_and_ignores_lazy_function_require(self) -> None:
        src_a = 'local B = require "mod/B"\nreturn {}\n'
        src_b = 'local A = require "mod/A"\nreturn {}\n'
        src_lazy = 'local function helper()\n    local A = require "mod/A"\n    return A\nend\nreturn {}\n'

        graph_bad = {
            "mod/A": extract_top_level_requires(src_a),
            "mod/B": extract_top_level_requires(src_b),
        }
        cycles_bad = find_cycles(graph_bad)
        self.assertEqual(len(cycles_bad), 1)
        self.assertEqual(cycles_bad[0], ["mod/A", "mod/B", "mod/A"])

        graph_ok = {
            "mod/A": extract_top_level_requires(src_a),
            "mod/B": extract_top_level_requires(src_lazy),
        }
        self.assertEqual(find_cycles(graph_ok), [])

    def test_no_top_level_lua_require_cycles_across_workspace(self) -> None:
        graph = build_workspace_require_graph()
        self.assertGreater(len(graph), 100, "Expected to discover Lua modules across Workshop repos")
        cycles = find_cycles(graph)
        if cycles:
            formatted = "\n".join("  - " + " -> ".join(c) for c in cycles)
            self.fail(
                f"Detected {len(cycles)} top-level Lua require() cycle(s) that will "
                f"cause Kahlua2 recursive require() nil bugs:\n{formatted}"
            )


if __name__ == "__main__":
    unittest.main()
