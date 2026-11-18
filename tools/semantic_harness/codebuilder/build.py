#!/usr/bin/env python3
"""Build owner-routed semantic Conversation and lexical artifacts."""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Mapping
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

if __package__ in {None, ""}:
    from tools.semantic_harness.codebuilder.lexicon_compiler import (  # noqa: E402
        CompileError,
        DEFAULT_ALLOWLIST,
        compile_wordnet,
        load_allowlist,
        render_lua_shards,
    )
    from tools.semantic_harness.codebuilder.translation_support import (
        normalize_language,
        pretty_json,
    )
    from tools.semantic_harness.codebuilder.generation_ownership import (
        CORE_OWNER,
        DT_COMMON_OWNER,
        HOOMANS_OWNER,
        generated_conversation_root,
        module_owner,
        module_target,
        normalize_owner,
        package_descriptor,
        resolve_core_repository,
        translation_root,
    )
    from tools.semantic_harness.codebuilder.conversation_compiler import (
        CONVERSATION_MANIFEST_RELATIVE,
        CONVERSATION_UI_RUNTIME_RELATIVE,
        compile_conversation_sources,
        conversation_context_health,
        conversation_translation_catalogs_by_owner,
        render_conversation_registry,
        render_conversation_manifest_lua,
        render_conversation_runtime_plan,
        render_conversation_ui_module,
    )
    from tools.semantic_harness.codebuilder.conversation_text_catalog import (
        write_runtime_text_catalogs,
    )
    from tools.semantic_harness.codebuilder.workspace_catalog import WorkspaceCatalog
else:
    from .lexicon_compiler import (  # noqa: E402
        CompileError,
        DEFAULT_ALLOWLIST,
        compile_wordnet,
        load_allowlist,
        render_lua_shards,
    )
    from tools.semantic_harness.codebuilder.translation_support import normalize_language, pretty_json
    from .generation_ownership import (
        CORE_OWNER,
        DT_COMMON_OWNER,
        HOOMANS_OWNER,
        generated_conversation_root,
        module_owner,
        module_target,
        normalize_owner,
        package_descriptor,
        resolve_core_repository,
        translation_root,
    )
    from .conversation_compiler import (
        CONVERSATION_MANIFEST_RELATIVE,
        CONVERSATION_UI_RUNTIME_RELATIVE,
        compile_conversation_sources,
        conversation_context_health,
        conversation_translation_catalogs_by_owner,
        render_conversation_registry,
        render_conversation_manifest_lua,
        render_conversation_runtime_plan,
        render_conversation_ui_module,
    )
    from .conversation_text_catalog import write_runtime_text_catalogs
    from .workspace_catalog import WorkspaceCatalog


def default_lexicon_output(core_repository: Path | None = None) -> Path:
    core = resolve_core_repository(ROOT, explicit=core_repository)
    return (
        core
        / "Contents/mods/PsychopatzCore/common/media/lua/shared/"
        / "PsychopatzCore/Semantics/Generated/Lexicon/Catalog.lua"
    )


DEFAULT_CORE_REPOSITORY = resolve_core_repository(ROOT)
DEFAULT_OUTPUT = default_lexicon_output()
CONVERSATION_SOURCE_ROOT = (
    ROOT / "tools" / "semantic_harness" / "codebuilder" / "sources"
    / "conversation"
)
CONVERSATION_TEXT_MANIFEST = CONVERSATION_SOURCE_ROOT / "text" / "manifest.json"
DEFAULT_CONVERSATION_MANIFEST = CONVERSATION_SOURCE_ROOT / "manifest.json"


def write_lexicon_output(output: Path, compiled) -> list[Path]:
    """Write the stable lexicon hub and bounded generated data shards."""
    output.parent.mkdir(parents=True, exist_ok=True)
    shared_root = _shared_lua_root(output)
    module_prefix = output.relative_to(shared_root).with_suffix("").as_posix()
    rendered = render_lua_shards(compiled, module_prefix)
    # Keep the catalog's hub sibling directory clean while preserving any
    # future generated catalogs beside it.
    _clean_generated_tree(output.with_suffix(""))
    return _write_modules(shared_root, rendered)


def _conversation_locale_directories(translation_root: Path) -> list[tuple[str, Path]]:
    """Discover locale directories from actual Conversation translation trees."""
    discovered: list[tuple[str, Path]] = []
    if not translation_root.is_dir():
        return discovered
    for directory in translation_root.iterdir():
        if not directory.is_dir() or not (directory / "Conversation").is_dir():
            continue
        try:
            language = normalize_language(directory.name, "translation directory")
        except CompileError:
            continue
        discovered.append((language, directory))
    return sorted(discovered, key=lambda item: item[0])


def _write_conversation_translation_manifest(
    translation_root: Path,
    manifest_relative: Path = Path("manifests/Conversation.json"),
    catalogs: dict[str, dict[str, dict[str, str]]] | None = None,
) -> Path:
    """Generate a package manifest from canonical text or locale files."""
    if catalogs is None:
        languages: dict[str, list[str]] = {}
        for language, directory in _conversation_locale_directories(translation_root):
            entries: list[str] = []
            for path in sorted((directory / "Conversation").rglob("*.json")):
                relative_from_language = path.relative_to(directory).as_posix()
                if relative_from_language.startswith("Conversation/Text/"):
                    continue
                entries.append(path.relative_to(translation_root).as_posix())
            if entries:
                languages[language] = entries
    else:
        languages = {
            language: [
                f"{language}/Conversation/{domain}.json"
                for domain in sorted(domains)
            ]
            for language, domains in sorted(catalogs.items())
            if domains
        }
    manifest_path = translation_root / manifest_relative
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        pretty_json({"version": 1, "languages": languages}),
        encoding="utf-8",
        newline="\n",
    )
    return manifest_path


def merge_translation_catalog(
    path: Path,
    generated: dict[str, str],
) -> dict[str, str]:
    """Merge generated entries without deleting package-owned translations.

    Conversation UI catalogs are package assets, not disposable CodeBuilder
    output.  CodeBuilder may add generated suggestion text to them, but it
    must preserve shared Core UI text authored directly in the owning mod.
    Generated keys win when the same key is intentionally regenerated.
    """
    if not path.is_file():
        return dict(generated)
    try:
        existing = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(
            "cannot merge existing translation catalog "
            + str(path)
            + ": "
            + str(error)
        ) from error
    if not isinstance(existing, dict) or any(
        not isinstance(key, str) or not isinstance(value, str)
        for key, value in existing.items()
    ):
        raise CompileError(
            "translation catalog must be a flat string map: " + str(path)
        )
    merged = dict(existing)
    merged.update(generated)
    return merged

def _shared_lua_root(path: Path) -> Path:
    parts = path.parts
    for index in range(len(parts) - 2):
        if parts[index:index + 3] == ("media", "lua", "shared"):
            return Path(*parts[:index + 3])
    raise ValueError("generated output must be under a media/lua/shared tree")


def _is_codebuilder_generated_lua(path: Path) -> bool:
    """Return True only when *path* carries the CodeBuilder generated header."""
    try:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            first_line = handle.readline()
    except OSError:
        return False
    return first_line.startswith("-- Generated") and "do not edit by hand." in first_line


def _clean_generated_tree(root: Path, *, generated_only: bool = False) -> None:
    """Remove CodeBuilder-owned generated Lua artifacts beneath *root*."""
    if root.exists():
        for path in sorted(root.rglob("*.lua"), reverse=True):
            if not generated_only or _is_codebuilder_generated_lua(path):
                path.unlink()
        for directory in sorted(
            (path for path in root.rglob("*") if path.is_dir()),
            key=lambda path: len(path.parts),
            reverse=True,
        ):
            try:
                directory.rmdir()
            except OSError:
                pass
    root.mkdir(parents=True, exist_ok=True)


def _write_text_safe(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        path.write_text(text, encoding="utf-8", newline="\n")
    except PermissionError:
        import os
        import tempfile

        fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
        try:
            with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(text)
            os.replace(tmp_name, path)
        except Exception:
            try:
                os.unlink(tmp_name)
            except OSError:
                pass
            raise


def _write_modules(shared_root: Path, rendered: list[tuple[str, str]]) -> list[Path]:
    paths: list[Path] = []
    for module, source in rendered:
        path = shared_root / (module + ".lua")
        _write_text_safe(path, source)
        paths.append(path)
    return paths


def _write_routed_modules(
    project_repository: Path,
    core_repository: Path | None,
    dynamic_trading_repository: Path | None,
    rendered: list[tuple[str, str]],
) -> list[Path]:
    """Write each generated module into its owning package repository."""
    paths: list[Path] = []
    for module, source in rendered:
        _owner_repository, path = module_target(
            project_repository,
            module,
            core_repository=core_repository,
            dynamic_trading_repository=dynamic_trading_repository,
            runtime_root=project_repository,
        )
        _write_text_safe(path, source)
        paths.append(path)
    return paths


def write_conversation_output(
    repository: Path,
    model: dict | None = None,
    *,
    core_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    output_repositories: Mapping[str, Path] | None = None,
    receipt_root: Path | None = None,
    strict_closure: bool = False,
) -> list[Path]:
    """Write manifest-backed Conversation artifacts through the recipe-driven reconciler.

    When *output_repositories* is provided, sources are compiled from the
    workspace repositories while all generated Lua and translation writes are
    redirected into the isolated destination directories without touching live
    ``media/`` or ``Translate/`` trees.
    """
    if __package__ in {None, ""}:
        from tools.semantic_harness.codebuilder.reconcile import reconcile_apply
    else:
        from .reconcile import reconcile_apply

    report = reconcile_apply(
        repository,
        model=model,
        core_repository=core_repository,
        hoomans_repository=repository,
        dynamic_trading_repository=dynamic_trading_repository,
        output_repositories=output_repositories,
        receipt_root=receipt_root,
        strict_closure=strict_closure,
    )
    return [Path(p) for p in report.get("desiredPaths") or []]


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--wordnet-home",
        type=Path,
        default=None,
        help="extracted Princeton WordNet 3.0 package root (contains LICENSE and dict/)",
    )
    parser.add_argument(
        "--allowlist",
        type=Path,
        default=DEFAULT_ALLOWLIST,
        help="reviewed WordNet synset-to-Hoomans concept mapping",
    )
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument(
        "--conversation-manifest",
        type=Path,
        default=None,
        help="manifest-backed Conversation source tree to compile and generate",
    )
    parser.add_argument(
        "--conversation-output-root",
        type=Path,
        default=ROOT,
        help="Project Hoomans repository receiving adopter-owned Conversation artifacts",
    )
    parser.add_argument(
        "--core-repository",
        type=Path,
        default=None,
        help="PsychopatzCore repository receiving Core-owned generated artifacts",
    )
    parser.add_argument(
        "--dynamic-trading-repository",
        type=Path,
        default=None,
        help="DynamicTrading repository receiving DTCommon-owned generated artifacts",
    )
    options = parser.parse_args(arguments)

    if options.wordnet_home is None and options.conversation_manifest is None:
        parser.error("provide --wordnet-home and/or --conversation-manifest")

    compiled_lexicon = None
    compiled_conversation = None
    try:
        if options.wordnet_home is not None:
            compiled_lexicon = compile_wordnet(
                options.wordnet_home,
                load_allowlist(options.allowlist),
            )
        if options.conversation_manifest is not None:
            output_root = options.conversation_output_root.expanduser().resolve()
            manifest_path = options.conversation_manifest.expanduser().resolve()
            workspace = WorkspaceCatalog.discover(
                output_root,
                repository=output_root,
                core_repository=options.core_repository,
                dynamic_trading_repository=options.dynamic_trading_repository,
                allow_sibling_discovery=False,
                runtime_root=output_root,
            )
            package_repositories = dict(workspace.repository_by_owner)
            package_repositories.setdefault(HOOMANS_OWNER, output_root)
            package_repositories[CORE_OWNER] = workspace.core_repository
            if options.dynamic_trading_repository is not None:
                package_repositories[DT_COMMON_OWNER] = (
                    options.dynamic_trading_repository.expanduser().resolve()
                )
            compiled_conversation = compile_conversation_sources(
                output_root,
                manifest_path=manifest_path,
                runtime_root=output_root,
                package_repositories=package_repositories,
            )
    except CompileError as error:
        print(f"semantic compiler error: {error}", file=sys.stderr)
        return 2

    if compiled_lexicon is not None:
        output = (
            options.output.expanduser().resolve()
            if options.output is not None
            else default_lexicon_output(options.core_repository)
        )
        paths = write_lexicon_output(output, compiled_lexicon)
        alias_count = sum(
            len(aliases)
            for aliases in compiled_lexicon.aliases_by_concept.values()
        )
        form_count = len(compiled_lexicon.verb_forms_by_surface)
        print(
            f"wrote {output} plus {len(paths) - 1} data shards "
            f"({alias_count} aliases, {form_count} inflected forms "
            f"across {len(compiled_lexicon.aliases_by_concept)} concepts)"
        )

    if compiled_conversation is not None:
        output_root = options.conversation_output_root.expanduser().resolve()
        paths = write_conversation_output(
            output_root,
            compiled_conversation,
            core_repository=options.core_repository,
            dynamic_trading_repository=options.dynamic_trading_repository,
        )
        print(
            "wrote manifest-backed Conversation output and "
            f"{len(paths) - 1} generated files "
            f"({len(compiled_conversation['content']['phraseFamilies'])} "
            "phrase families, "
            f"{len(compiled_conversation['dialogue']['patterns'])} patterns, "
            f"{len(compiled_conversation['ui'])} UI definitions)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
